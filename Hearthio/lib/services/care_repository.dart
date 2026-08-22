import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/care_item.dart';
import '../models/care_space.dart';

const currentCareSchemaVersion = 3;

class CareDataEnvelope {
  const CareDataEnvelope({
    required this.items,
    this.spaces = const [],
    this.schemaVersion = currentCareSchemaVersion,
    this.migratedFromOlderSchema = false,
  });

  final int schemaVersion;
  final List<CareItem> items;
  final List<CareSpace> spaces;
  final bool migratedFromOlderSchema;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'items': items.map((item) => item.toJson()).toList(),
    'spaces': spaces.map((space) => space.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory CareDataEnvelope.decode(String raw) =>
      CareDataEnvelope.fromDecoded(jsonDecode(raw));

  factory CareDataEnvelope.fromDecoded(dynamic decoded) {
    if (decoded is! Map) {
      throw const FormatException('Expected a versioned data envelope');
    }
    final json = Map<String, dynamic>.from(decoded);
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 2 && schemaVersion != currentCareSchemaVersion) {
      throw FormatException('Unsupported schema version: $schemaVersion');
    }
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Envelope items are missing');
    }
    var items = rawItems
        .map(
          (value) => CareItem.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false);
    List<CareSpace> spaces;
    if (schemaVersion == 2) {
      final migrated = migrateLegacyItemLocations(items);
      items = migrated.items;
      spaces = migrated.spaces;
    } else {
      final rawSpaces = json['spaces'] as List? ?? const [];
      spaces = rawSpaces
          .map(
            (value) =>
                CareSpace.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(growable: false);
    }
    _validate(items, spaces);
    return CareDataEnvelope(
      items: items,
      spaces: spaces,
      migratedFromOlderSchema: schemaVersion != currentCareSchemaVersion,
    );
  }

  factory CareDataEnvelope.fromLegacyDecoded(dynamic decoded) {
    if (decoded is! List) {
      throw const FormatException('Legacy item list is invalid');
    }
    final legacyItems = decoded
        .map(
          (value) =>
              CareItem.fromLegacyJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false);
    final migrated = migrateLegacyItemLocations(legacyItems);
    _validate(migrated.items, migrated.spaces);
    return CareDataEnvelope(
      items: migrated.items,
      spaces: migrated.spaces,
      migratedFromOlderSchema: true,
    );
  }

  static void _validate(List<CareItem> items, List<CareSpace> spaces) {
    final spaceIds = <String>{};
    for (final space in spaces) {
      if (!spaceIds.add(space.id)) {
        throw FormatException('Duplicate space id: ${space.id}');
      }
    }
    final itemIds = <String>{};
    for (final item in items) {
      if (!itemIds.add(item.id)) {
        throw FormatException('Duplicate item id: ${item.id}');
      }
      if (item.spaceId case final spaceId?) {
        if (!spaceIds.contains(spaceId)) {
          throw FormatException('Unknown space id in item ${item.id}');
        }
      }
      final planIds = <String>{};
      for (final plan in item.plans) {
        if (plan.id.trim().isEmpty || !planIds.add(plan.id)) {
          throw FormatException('Invalid plan id in ${item.id}');
        }
      }
      final recordIds = <String>{};
      for (final record in item.records) {
        if (record.id.trim().isEmpty || !recordIds.add(record.id)) {
          throw FormatException('Invalid record id in ${item.id}');
        }
        if (record.planId != null && !planIds.contains(record.planId)) {
          throw FormatException('Unknown plan id in record ${record.id}');
        }
        if (!record.cost.isFinite || record.cost < 0) {
          throw FormatException('Invalid record cost in ${record.id}');
        }
      }
    }
  }
}

class CareDataLoadResult {
  const CareDataLoadResult({
    required this.items,
    required this.spaces,
    required this.migratedLegacyData,
    required this.seededInitialData,
  });

  final List<CareItem> items;
  final List<CareSpace> spaces;
  final bool migratedLegacyData;
  final bool seededInitialData;
}

class CareRepository {
  @visibleForTesting
  CareRepository(this._preferences) : _snapshotFile = null;

  CareRepository._file(this._preferences, this._snapshotFile);

  static const storageKey = 'care_data_v2';
  static const legacyStorageKey = 'care_items';
  static const snapshotFileName = 'care-data.json';
  static const maxSnapshotBytes = 5 * 1024 * 1024;

  final SharedPreferences _preferences;
  final File? _snapshotFile;

  static Future<CareRepository> open({File? snapshotFile}) async {
    final preferences = await SharedPreferences.getInstance();
    final file =
        snapshotFile ??
        File(
          '${(await getApplicationSupportDirectory()).path}/$snapshotFileName',
        );
    return CareRepository._file(preferences, file);
  }

  Future<CareDataLoadResult> load({
    required List<CareItem> initialItems,
  }) async {
    final snapshotFile = _snapshotFile;
    if (snapshotFile != null && await snapshotFile.exists()) {
      final envelope = CareDataEnvelope.decode(
        await _readSnapshot(snapshotFile),
      );
      if (envelope.migratedFromOlderSchema) {
        await _write(envelope.encode());
      }
      return CareDataLoadResult(
        items: envelope.items,
        spaces: envelope.spaces,
        migratedLegacyData: false,
        seededInitialData: false,
      );
    }

    // These preference keys are migration inputs only. Production writes use
    // the application-support snapshot file above.
    final current = _preferences.getString(storageKey);
    if (current != null) {
      final envelope = CareDataEnvelope.decode(current);
      await _write(envelope.encode());
      await _removeMigratedPreferenceSnapshots();
      return CareDataLoadResult(
        items: envelope.items,
        spaces: envelope.spaces,
        migratedLegacyData: false,
        seededInitialData: false,
      );
    }

    final legacy = _preferences.getString(legacyStorageKey);
    if (legacy != null) {
      final envelope = CareDataEnvelope.fromLegacyDecoded(jsonDecode(legacy));
      await _write(envelope.encode());
      await _removeMigratedPreferenceSnapshots();
      return CareDataLoadResult(
        items: envelope.items,
        spaces: envelope.spaces,
        migratedLegacyData: true,
        seededInitialData: false,
      );
    }

    final migrated = migrateLegacyItemLocations(initialItems);
    final envelope = CareDataEnvelope(
      items: migrated.items,
      spaces: migrated.spaces,
    );
    await _write(envelope.encode());
    return CareDataLoadResult(
      items: envelope.items,
      spaces: envelope.spaces,
      migratedLegacyData: false,
      seededInitialData: true,
    );
  }

  String encodeSnapshot(
    List<CareItem> items, {
    List<CareSpace> spaces = const [],
  }) => CareDataEnvelope(items: items, spaces: spaces).encode();

  Future<void> save(
    List<CareItem> items, {
    List<CareSpace> spaces = const [],
  }) => writeEncodedSnapshot(encodeSnapshot(items, spaces: spaces));

  Future<void> writeEncodedSnapshot(String snapshot) async {
    // Re-parse before switching the active value so a partial or invalid
    // serialization can never replace the last readable snapshot.
    CareDataEnvelope.decode(snapshot);
    await _write(snapshot);
  }

  Future<void> _write(String snapshot) async {
    final encoded = utf8.encode(snapshot);
    if (encoded.length > maxSnapshotBytes) {
      throw const FileSystemException('Care data exceeds the snapshot limit');
    }

    final snapshotFile = _snapshotFile;
    if (snapshotFile == null) {
      // Kept only as a lightweight test seam. CareRepository.open(), used by
      // the app, always resolves a file in Application Support.
      final saved = await _preferences.setString(storageKey, snapshot);
      if (!saved) {
        throw const FileSystemException('Unable to persist care data');
      }
      return;
    }

    await snapshotFile.parent.create(recursive: true);
    final temporary = File('${snapshotFile.path}.tmp');
    try {
      await temporary.writeAsBytes(encoded, flush: true);
      if (await temporary.length() != encoded.length) {
        throw const FileSystemException('Incomplete care data snapshot');
      }
      // On iOS/macOS this rename atomically replaces the prior snapshot, so a
      // crash cannot expose a partially written JSON document.
      await temporary.rename(snapshotFile.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<String> _readSnapshot(File file) async {
    final length = await file.length();
    if (length < 0 || length > maxSnapshotBytes) {
      throw const FileSystemException('Care data snapshot has an invalid size');
    }
    return file.readAsString();
  }

  Future<void> _removeMigratedPreferenceSnapshots() async {
    if (_snapshotFile == null) return;
    try {
      await _preferences.remove(storageKey);
      await _preferences.remove(legacyStorageKey);
    } catch (_) {
      // The durable file is authoritative after migration. A stale preference
      // value is ignored on every later load and can be cleaned up next time.
    }
  }
}

({List<CareItem> items, List<CareSpace> spaces}) migrateLegacyItemLocations(
  List<CareItem> items, {
  List<CareSpace> existingSpaces = const [],
}) {
  final spaces = [...existingSpaces];
  final spaceByName = <String, CareSpace>{
    for (final space in existingSpaces) space.name: space,
  };
  final spaceIds = existingSpaces.map((space) => space.id).toSet();
  final migratedItems = <CareItem>[];
  const knownNames = <String>[
    '客厅',
    '卧室',
    '厨房',
    '卫生间',
    '阳台',
    '书房',
    '餐厅',
    '储物间',
    '玄关',
    '浴室',
    '洗手间',
  ];
  const separators = <String>[' · ', '·', '-', '—', '/'];

  for (final item in items) {
    final raw = item.location.trim();
    if (raw.isEmpty || item.spaceId != null) {
      migratedItems.add(item);
      continue;
    }

    var roomName = raw;
    var detail = '';
    for (final candidate in knownNames) {
      if (raw == candidate) {
        roomName = candidate;
        break;
      }
      var matched = false;
      for (final separator in separators) {
        final prefix = '$candidate$separator';
        if (!raw.startsWith(prefix)) continue;
        roomName = candidate;
        detail = raw.substring(prefix.length).trim();
        matched = true;
        break;
      }
      if (matched) break;
    }

    final space = spaceByName.putIfAbsent(roomName, () {
      var suffix = spaces.length + 1;
      while (spaceIds.contains('legacy-space-$suffix')) {
        suffix++;
      }
      final created = CareSpace(
        id: 'legacy-space-$suffix',
        type: careSpaceTypeForLegacyName(roomName),
        name: roomName,
      );
      spaces.add(created);
      spaceIds.add(created.id);
      return created;
    });
    migratedItems.add(item.copyWith(spaceId: space.id, locationDetail: detail));
  }

  return (
    items: List.unmodifiable(migratedItems),
    spaces: List.unmodifiable(spaces),
  );
}
