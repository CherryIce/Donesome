import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> legacyItem({
  String id = 'washer',
  String name = '洗衣机',
  DateTime? lastCareDate,
  int? intervalDays,
  List<Map<String, dynamic>> records = const [],
}) => {
  'id': id,
  'name': name,
  'category': '家电',
  'location': '阳台',
  'brand': '',
  'model': '',
  'notes': '',
  'photos': <String>[],
  'lastCareDate': lastCareDate?.toIso8601String(),
  'intervalDays': intervalDays,
  'records': records,
};

void main() {
  test(
    'legacy schedule and records migrate once while old key is retained',
    () async {
      final legacyJson = jsonEncode([
        legacyItem(
          lastCareDate: DateTime(2026, 1, 1),
          intervalDays: 90,
          records: [
            {
              'date': DateTime(2026, 1, 1).toIso8601String(),
              'kind': '内筒清洁',
              'cost': 20,
              'note': '完成',
            },
          ],
        ),
      ]);
      SharedPreferences.setMockInitialValues({
        CareRepository.legacyStorageKey: legacyJson,
      });
      final repository = await CareRepository.open();

      final result = await repository.load(initialItems: const []);

      expect(result.migratedLegacyData, isTrue);
      final item = result.items.single;
      expect(item.plans, hasLength(1));
      expect(item.plans.single.title, '定期保养');
      expect(item.plans.single.dueDate, DateTime(2026, 4, 1));
      expect(item.records.single.planId, item.plans.single.id);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(CareRepository.legacyStorageKey),
        legacyJson,
      );
      final current = CareDataEnvelope.decode(
        preferences.getString(CareRepository.storageKey)!,
      );
      expect(current.schemaVersion, currentCareSchemaVersion);
      expect(current.items.single.records.single.id, 'legacy-record-washer-0');
    },
  );

  test(
    'an empty legacy list migrates as empty instead of seeding examples',
    () async {
      SharedPreferences.setMockInitialValues({
        CareRepository.legacyStorageKey: '[]',
      });
      final repository = await CareRepository.open();

      final result = await repository.load(
        initialItems: [
          CareItem(
            id: 'sample',
            name: '示例',
            category: '其他',
            location: '',
            brand: '',
            model: '',
            notes: '',
            photos: const [],
          ),
        ],
      );

      expect(result.items, isEmpty);
      expect(result.seededInitialData, isFalse);
    },
  );

  test(
    'damaged legacy data is preserved and does not create a v2 key',
    () async {
      const damaged = '[{"id":"broken"}]';
      SharedPreferences.setMockInitialValues({
        CareRepository.legacyStorageKey: damaged,
      });
      final repository = await CareRepository.open();

      await expectLater(
        repository.load(initialItems: const []),
        throwsA(anything),
      );

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(CareRepository.legacyStorageKey), damaged);
      expect(preferences.getString(CareRepository.storageKey), isNull);
    },
  );

  test('a damaged active snapshot fails closed and is not replaced', () async {
    const damaged = '{not-json';
    final legacyJson = jsonEncode([legacyItem()]);
    SharedPreferences.setMockInitialValues({
      CareRepository.storageKey: damaged,
      CareRepository.legacyStorageKey: legacyJson,
    });
    final store = CareStore();

    await store.load();

    expect(store.items, isEmpty);
    expect(store.loadError, isNotNull);
    await expectLater(
      store.save(
        CareItem(
          id: 'new-item',
          name: '不能覆盖原数据',
          category: '其他',
          location: '',
          brand: '',
          model: '',
          notes: '',
          photos: const [],
        ),
      ),
      throwsA(isA<FileSystemException>()),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(CareRepository.storageKey), damaged);
    expect(preferences.getString(CareRepository.legacyStorageKey), legacyJson);
  });

  test(
    'load freezes legacy history steps and clears expired deferrals',
    () async {
      final today = maintenanceDateOnly(DateTime.now());
      final item = CareItem(
        id: 'purifier',
        name: '净水器',
        category: '家电',
        location: '厨房',
        brand: '',
        model: '',
        notes: '',
        photos: const [],
        plans: [
          MaintenancePlan(
            id: 'filter',
            title: '更换滤芯',
            intervalDays: 180,
            dueDate: addMaintenanceDays(today, 30),
            deferredUntil: addMaintenanceDays(today, -1),
            checklist: const [
              MaintenanceStep(id: 'water-off', title: '关闭水源', sortOrder: 0),
            ],
          ),
        ],
        records: [
          MaintenanceRecord(
            id: 'record',
            planId: 'filter',
            completedAt: addMaintenanceDays(today, -10),
            kind: '更换滤芯',
            cost: 0,
            note: '',
            completedStepIds: const ['water-off'],
          ),
        ],
      );
      SharedPreferences.setMockInitialValues({
        CareRepository.storageKey: CareDataEnvelope(items: [item]).encode(),
      });
      final store = CareStore();

      await store.load();

      final loaded = store.items.single;
      expect(loaded.plans.single.deferredUntil, isNull);
      expect(loaded.records.single.stepSnapshots?.single.title, '关闭水源');
      final preferences = await SharedPreferences.getInstance();
      final persisted = CareDataEnvelope.decode(
        preferences.getString(CareRepository.storageKey)!,
      ).items.single;
      expect(persisted.plans.single.deferredUntil, isNull);
      expect(persisted.records.single.stepSnapshots?.single.completed, isTrue);
    },
  );
}
