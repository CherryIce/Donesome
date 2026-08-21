import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/care_item.dart';

const currentCareSchemaVersion = 2;

class CareDataEnvelope {
  const CareDataEnvelope({
    required this.items,
    this.schemaVersion = currentCareSchemaVersion,
  });

  final int schemaVersion;
  final List<CareItem> items;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'items': items.map((item) => item.toJson()).toList(),
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
    if (schemaVersion != currentCareSchemaVersion) {
      throw FormatException('Unsupported schema version: $schemaVersion');
    }
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Envelope items are missing');
    }
    final items = rawItems
        .map(
          (value) => CareItem.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false);
    _validate(items);
    return CareDataEnvelope(items: items);
  }

  factory CareDataEnvelope.fromLegacyDecoded(dynamic decoded) {
    if (decoded is! List) {
      throw const FormatException('Legacy item list is invalid');
    }
    final items = decoded
        .map(
          (value) =>
              CareItem.fromLegacyJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false);
    _validate(items);
    return CareDataEnvelope(items: items);
  }

  static void _validate(List<CareItem> items) {
    final itemIds = <String>{};
    for (final item in items) {
      if (!itemIds.add(item.id)) {
        throw FormatException('Duplicate item id: ${item.id}');
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
    required this.migratedLegacyData,
    required this.seededInitialData,
  });

  final List<CareItem> items;
  final bool migratedLegacyData;
  final bool seededInitialData;
}

class CareRepository {
  CareRepository(this._preferences);

  static const storageKey = 'care_data_v2';
  static const legacyStorageKey = 'care_items';

  final SharedPreferences _preferences;

  static Future<CareRepository> open() async =>
      CareRepository(await SharedPreferences.getInstance());

  Future<CareDataLoadResult> load({
    required List<CareItem> initialItems,
  }) async {
    final current = _preferences.getString(storageKey);
    if (current != null) {
      final envelope = CareDataEnvelope.decode(current);
      return CareDataLoadResult(
        items: envelope.items,
        migratedLegacyData: false,
        seededInitialData: false,
      );
    }

    final legacy = _preferences.getString(legacyStorageKey);
    if (legacy != null) {
      final envelope = CareDataEnvelope.fromLegacyDecoded(jsonDecode(legacy));
      await _write(envelope.encode());
      return CareDataLoadResult(
        items: envelope.items,
        migratedLegacyData: true,
        seededInitialData: false,
      );
    }

    final envelope = CareDataEnvelope(items: initialItems);
    await _write(envelope.encode());
    return CareDataLoadResult(
      items: envelope.items,
      migratedLegacyData: false,
      seededInitialData: true,
    );
  }

  String encodeSnapshot(List<CareItem> items) =>
      CareDataEnvelope(items: items).encode();

  Future<void> save(List<CareItem> items) =>
      writeEncodedSnapshot(encodeSnapshot(items));

  Future<void> writeEncodedSnapshot(String snapshot) async {
    // Re-parse before switching the active value so a partial or invalid
    // serialization can never replace the last readable snapshot.
    CareDataEnvelope.decode(snapshot);
    await _write(snapshot);
  }

  Future<void> _write(String snapshot) async {
    final saved = await _preferences.setString(storageKey, snapshot);
    if (!saved) throw const FileSystemException('Unable to persist care data');
  }
}
