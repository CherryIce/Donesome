import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingCareRepository extends CareRepository {
  _FailingCareRepository(super.preferences);

  @override
  Future<void> writeEncodedSnapshot(String snapshot) async {
    throw const FileSystemException('simulated persistence failure');
  }
}

class _BlockingCareRepository extends CareRepository {
  _BlockingCareRepository(super.preferences);

  final firstWriteStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  final snapshots = <String>[];
  var writeCount = 0;

  @override
  Future<void> writeEncodedSnapshot(String snapshot) async {
    CareDataEnvelope.decode(snapshot);
    writeCount += 1;
    if (writeCount == 1) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
    }
    snapshots.add(snapshot);
  }
}

class _BlockingLoadCareRepository extends CareRepository {
  _BlockingLoadCareRepository(super.preferences, this.loadedItem);

  final CareItem loadedItem;
  final loadStarted = Completer<void>();
  final releaseLoad = Completer<void>();
  final snapshots = <String>[];

  @override
  Future<CareDataLoadResult> load({
    required List<CareItem> initialItems,
  }) async {
    loadStarted.complete();
    await releaseLoad.future;
    return CareDataLoadResult(
      items: [loadedItem],
      spaces: const [],
      migratedLegacyData: false,
      seededInitialData: false,
    );
  }

  @override
  Future<void> writeEncodedSnapshot(String snapshot) async {
    CareDataEnvelope.decode(snapshot);
    snapshots.add(snapshot);
  }
}

CareItem _item({
  String id = 'purifier',
  String name = '净水器',
  List<String> photos = const [],
  bool isSample = false,
  DateTime? deferredUntil,
}) => CareItem(
  id: id,
  name: name,
  category: '家电',
  location: '厨房',
  brand: '',
  model: '',
  notes: '',
  photos: photos,
  plans: [
    MaintenancePlan(
      id: 'filter',
      title: '更换滤芯',
      intervalDays: 180,
      dueDate: maintenanceDateOnly(DateTime.now()),
      deferredUntil: deferredUntil,
    ),
  ],
  isSample: isSample,
);

void main() {
  test('startup load and edits share the same data mutation queue', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = _BlockingLoadCareRepository(
      preferences,
      _item(id: 'from-disk', name: '已有物品'),
    );
    final store = CareStore(
      repository: repository,
      notificationScheduler: (_, __) async {},
    );

    final load = store.load();
    await repository.loadStarted.future;
    var saveCompleted = false;
    final save = store
        .save(_item(id: 'during-load', name: '加载时新增'))
        .then((_) => saveCompleted = true);
    await Future<void>.delayed(Duration.zero);

    expect(saveCompleted, isFalse);
    repository.releaseLoad.complete();
    await Future.wait([load, save]);

    expect(
      store.items.map((item) => item.id),
      unorderedEquals(['from-disk', 'during-load']),
    );
    final persisted = CareDataEnvelope.decode(repository.snapshots.last);
    expect(
      persisted.items.map((item) => item.id),
      unorderedEquals(['from-disk', 'during-load']),
    );
  });

  test(
    'ordinary save publishes and cleans photos only after persistence',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final photo = File(
        '${Directory.systemTemp.path}/hearthio-save-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await photo.writeAsBytes([1, 2, 3]);
      final original = _item(photos: [photo.path]);
      var notificationCalls = 0;
      final store = CareStore(
        repository: _FailingCareRepository(preferences),
        notificationScheduler: (_, __) async => notificationCalls++,
      )..items = [original];

      await expectLater(
        store.save(original.copyWith(name: '新名称', photos: const [])),
        throwsA(isA<FileSystemException>()),
      );

      expect(store.items.single.name, '净水器');
      expect(store.items.single.photos, [photo.path]);
      expect(await photo.exists(), isTrue);
      expect(notificationCalls, 0);
      await photo.delete();
    },
  );

  test(
    'delete and example reset keep visible state when persistence fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final userItem = _item();
      final sample = _item(
        id: 'sample-filter',
        name: '示例 · 厨房净水器',
        isSample: true,
      );
      final store = CareStore(
        repository: _FailingCareRepository(preferences),
        notificationScheduler: (_, __) async {},
      )..items = [userItem, sample];

      await expectLater(
        store.remove(userItem),
        throwsA(isA<FileSystemException>()),
      );
      expect(store.items.map((item) => item.id), ['purifier', 'sample-filter']);

      await expectLater(
        store.resetExampleData(),
        throwsA(isA<FileSystemException>()),
      );
      expect(store.items[1].name, '示例 · 厨房净水器');

      await expectLater(
        store.deleteExampleData(),
        throwsA(isA<FileSystemException>()),
      );
      expect(store.items.where((item) => item.isSample), hasLength(1));
    },
  );

  test('failed deferral does not publish the new reminder date', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final original = _item();
    final store = CareStore(
      repository: _FailingCareRepository(preferences),
      notificationScheduler: (_, __) async {},
    )..items = [original];
    final tomorrow = addMaintenanceDays(DateTime.now(), 1);

    await expectLater(
      store.deferPlan(original, 'filter', tomorrow),
      throwsA(isA<FileSystemException>()),
    );

    expect(store.items.single.plans.single.deferredUntil, isNull);
  });

  test(
    'restore shares the mutation queue and coalesces duplicate submissions',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final root = await Directory.systemTemp.createTemp(
        'hearthio-restore-queue-',
      );
      try {
        final restored = _item(id: 'restored', name: '恢复物品');
        final archive = File('${root.path}/backup.zip');
        await archive.writeAsBytes(
          CareBackupCodec.encode(items: [restored], photoBytesByPath: const {}),
        );
        final repository = _BlockingCareRepository(preferences);
        var pickerCalls = 0;
        final store = CareStore(
          repository: repository,
          backupPicker: () async {
            pickerCalls += 1;
            return archive.path;
          },
          documentsDirectoryProvider: () async =>
              Directory('${root.path}/documents'),
          notificationScheduler: (_, __) async {},
        )..items = [_item(id: 'before', name: '恢复前')];

        final restore = store.restoreBackup();
        await repository.firstWriteStarted.future;
        final duplicate = store.restoreBackup();
        final reset = store.resetExampleData();

        expect(identical(restore, duplicate), isTrue);
        expect(store.isRestoringBackup, isTrue);
        repository.releaseFirstWrite.complete();

        expect(await restore, isTrue);
        expect(await duplicate, isTrue);
        await reset;

        expect(pickerCalls, 1);
        expect(repository.snapshots, hasLength(2));
        final persisted = CareDataEnvelope.decode(
          repository.snapshots.last,
        ).items;
        expect(
          persisted.map((item) => item.id),
          store.items.map((item) => item.id),
        );
        expect(
          store.items.map((item) => item.id),
          unorderedEquals(['restored', 'sample-filter']),
        );
        expect(store.isRestoringBackup, isFalse);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

  test('failed restore removes staged photos and keeps current data', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final root = await Directory.systemTemp.createTemp(
      'hearthio-restore-rollback-',
    );
    try {
      const archivedPhoto = '/export/receipt.jpg';
      final archive = File('${root.path}/backup.zip');
      await archive.writeAsBytes(
        CareBackupCodec.encode(
          items: [
            _item(id: 'restored', photos: const [archivedPhoto]),
          ],
          photoBytesByPath: const {
            archivedPhoto: [7, 8, 9],
          },
        ),
      );
      final original = _item(id: 'before', name: '恢复前');
      final documents = Directory('${root.path}/documents');
      final store = CareStore(
        repository: _FailingCareRepository(preferences),
        backupPicker: () async => archive.path,
        documentsDirectoryProvider: () async => documents,
        notificationScheduler: (_, __) async {},
      )..items = [original];

      expect(await store.restoreBackup(), isFalse);

      expect(store.items.single.id, 'before');
      final photoRoot = Directory('${documents.path}/item-photos');
      final stagedDirectories = await photoRoot.exists()
          ? await photoRoot
                .list(followLinks: false)
                .where((entry) => entry is Directory)
                .toList()
          : <FileSystemEntity>[];
      expect(stagedDirectories, isEmpty);
      expect(store.isRestoringBackup, isFalse);
    } finally {
      await root.delete(recursive: true);
    }
  });

  test(
    'successful restore keeps new photos and deletes old references',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final root = await Directory.systemTemp.createTemp(
        'hearthio-restore-cleanup-',
      );
      try {
        final documents = Directory('${root.path}/documents');
        final oldDirectory = Directory(
          '${documents.path}/item-photos/restore-old',
        );
        await oldDirectory.create(recursive: true);
        final oldPhoto = File('${oldDirectory.path}/old.jpg');
        await oldPhoto.writeAsBytes([1, 2, 3]);

        const archivedPhoto = '/export/new.jpg';
        final archive = File('${root.path}/backup.zip');
        await archive.writeAsBytes(
          CareBackupCodec.encode(
            items: [
              _item(id: 'restored', photos: const [archivedPhoto]),
            ],
            photoBytesByPath: const {
              archivedPhoto: [4, 5, 6],
            },
          ),
        );
        final store =
            CareStore(
                repository: CareRepository(preferences),
                backupPicker: () async => archive.path,
                documentsDirectoryProvider: () async => documents,
                notificationScheduler: (_, __) async {},
              )
              ..items = [
                _item(id: 'before', photos: [oldPhoto.path]),
              ];

        expect(await store.restoreBackup(), isTrue);

        expect(await oldPhoto.exists(), isFalse);
        expect(await oldDirectory.exists(), isFalse);
        final restoredPhoto = File(store.items.single.photos.single);
        expect(await restoredPhoto.readAsBytes(), [4, 5, 6]);
        final persisted = CareDataEnvelope.decode(
          preferences.getString(CareRepository.storageKey)!,
        ).items.single;
        expect(persisted.photos, [restoredPhoto.path]);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
