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

CareItem _item({DateTime? lastCompletedAt}) {
  final today = maintenanceDateOnly(DateTime.now());
  return CareItem(
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
        reminderLeadDays: 5,
        lastCompletedAt: lastCompletedAt,
        dueDate: addMaintenanceDays(today, -2),
        deferredUntil: addMaintenanceDays(today, 3),
        checklist: const [
          MaintenanceStep(id: 'water-off', title: '关闭水源', sortOrder: 0),
          MaintenanceStep(id: 'flush', title: '冲洗', sortOrder: 1),
        ],
      ),
    ],
  );
}

MaintenanceCompletionDraft _draft({
  String operationId = 'operation-1',
  double cost = 129,
  DateTime? completedAt,
}) => MaintenanceCompletionDraft(
  operationId: operationId,
  itemId: 'purifier',
  planId: 'filter',
  completedAt: completedAt ?? DateTime.now(),
  cost: cost,
  materialName: 'PP 棉滤芯 A1',
  note: '已冲洗',
  completedStepIds: const ['water-off'],
  beforePhotos: const ['/photos/before.jpg'],
  afterPhotos: const ['/photos/after.jpg'],
);

void main() {
  test(
    'completion persists record and next plan before publishing UI state',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var scheduleCalls = 0;
      final store = CareStore(
        repository: CareRepository(preferences),
        notificationScheduler: (_, __) async => scheduleCalls++,
      )..items = [_item()];
      final completedAt = maintenanceDateOnly(DateTime.now());

      final result = await store.completeMaintenance(
        _draft(completedAt: completedAt),
      );

      final saved = store.items.single;
      expect(saved.records, hasLength(1));
      expect(saved.records.single.planId, 'filter');
      expect(
        saved.records.single.plannedDueDate,
        addMaintenanceDays(completedAt, -2),
      );
      expect(saved.records.single.completedStepIds, ['water-off']);
      expect(saved.records.single.kind, '更换滤芯');
      expect(saved.records.single.stepSnapshots?.map((step) => step.title), [
        '关闭水源',
        '冲洗',
      ]);
      expect(
        saved.records.single.stepSnapshots?.map((step) => step.completed),
        [true, false],
      );
      expect(saved.records.single.beforePhotos, ['/photos/before.jpg']);
      expect(saved.records.single.afterPhotos, ['/photos/after.jpg']);
      expect(saved.records.single.materialName, 'PP 棉滤芯 A1');
      expect(saved.plans.single.lastCompletedAt, completedAt);
      expect(saved.plans.single.dueDate, addMaintenanceDays(completedAt, 180));
      expect(saved.plans.single.deferredUntil, isNull);
      expect(result.notificationScheduled, isTrue);
      expect(scheduleCalls, 1);

      final persisted = CareDataEnvelope.decode(
        preferences.getString(CareRepository.storageKey)!,
      ).items.single;
      expect(persisted.records.single.id, result.record.id);
      expect(
        persisted.plans.single.dueDate,
        addMaintenanceDays(completedAt, 180),
      );
    },
  );

  test(
    'same completion operation is idempotent, including concurrent taps',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = CareStore(
        repository: CareRepository(preferences),
        notificationScheduler: (_, __) async {},
      )..items = [_item()];
      final draft = _draft(operationId: 'same-operation');

      final firstFuture = store.completeMaintenance(draft);
      final secondFuture = store.completeMaintenance(draft);
      expect(identical(firstFuture, secondFuture), isTrue);
      final first = await firstFuture;
      final retried = await store.completeMaintenance(draft);

      expect(store.items.single.records, hasLength(1));
      expect(retried.record.id, first.record.id);
      expect(retried.alreadyCompleted, isTrue);
    },
  );

  test(
    'different plan completions are serialized without lost records',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final firstItem = _item();
      final item = firstItem.copyWith(
        plans: [
          ...firstItem.plans,
          MaintenancePlan(
            id: 'pipe-clean',
            title: '清洗管路',
            intervalDays: 365,
            dueDate: maintenanceDateOnly(DateTime.now()),
          ),
        ],
      );
      final store = CareStore(
        repository: CareRepository(preferences),
        notificationScheduler: (_, __) async {},
      )..items = [item];

      final first = store.completeMaintenance(_draft(operationId: 'first'));
      final second = store.completeMaintenance(
        MaintenanceCompletionDraft(
          operationId: 'second',
          itemId: 'purifier',
          planId: 'pipe-clean',
          completedAt: DateTime.now(),
          cost: 0,
        ),
      );
      await Future.wait([first, second]);

      final saved = store.items.single;
      expect(saved.records, hasLength(2));
      expect(saved.records.map((record) => record.planId).toSet(), {
        'filter',
        'pipe-clean',
      });
      expect(saved.plans.every((plan) => plan.lastCompletedAt != null), isTrue);
      final persisted = CareDataEnvelope.decode(
        preferences.getString(CareRepository.storageKey)!,
      ).items.single;
      expect(persisted.records, hasLength(2));
    },
  );

  test(
    'persistence failure leaves plan, records, and UI source unchanged',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var scheduleCalls = 0;
      final original = _item();
      final store = CareStore(
        repository: _FailingCareRepository(preferences),
        notificationScheduler: (_, __) async => scheduleCalls++,
      )..items = [original];

      await expectLater(
        store.completeMaintenance(_draft()),
        throwsA(
          isA<MaintenanceCompletionException>().having(
            (error) => error.message,
            'message',
            contains('数据未更新'),
          ),
        ),
      );

      expect(store.items.single.records, isEmpty);
      expect(
        store.items.single.plans.single.dueDate,
        original.plans.single.dueDate,
      );
      expect(store.items.single.plans.single.deferredUntil, isNotNull);
      expect(preferences.getString(CareRepository.storageKey), isNull);
      expect(scheduleCalls, 0);
    },
  );

  test(
    'notification failure remains a successful persisted completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = CareStore(
        repository: CareRepository(preferences),
        notificationScheduler: (_, __) async => throw StateError('offline'),
      )..items = [_item()];

      final result = await store.completeMaintenance(_draft());

      expect(result.notificationScheduled, isFalse);
      expect(store.items.single.records, hasLength(1));
      expect(preferences.getString(CareRepository.storageKey), isNotNull);
    },
  );

  test(
    'completion rejects invalid money and dates before prior completion',
    () {
      final today = maintenanceDateOnly(DateTime.now());
      final plan = _item(
        lastCompletedAt: addMaintenanceDays(today, -2),
      ).plans.single;

      expect(
        () =>
            validateMaintenanceCompletion(_draft(cost: double.infinity), plan),
        throwsA(isA<MaintenanceCompletionException>()),
      );
      expect(
        () => validateMaintenanceCompletion(
          _draft(completedAt: addMaintenanceDays(today, -3)),
          plan,
        ),
        throwsA(isA<MaintenanceCompletionException>()),
      );
    },
  );
}
