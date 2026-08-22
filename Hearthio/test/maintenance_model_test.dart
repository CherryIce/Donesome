import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('completion advances due date and clears a deferral', () {
    final plan = MaintenancePlan(
      id: 'filter',
      title: '清洗滤网',
      intervalDays: 90,
      dueDate: DateTime(2026, 4, 1),
      deferredUntil: DateTime(2026, 4, 8),
    );

    final completed = plan.completedAt(DateTime(2026, 4, 10));

    expect(completed.lastCompletedAt, DateTime(2026, 4, 10));
    expect(completed.dueDate, DateTime(2026, 7, 9));
    expect(completed.deferredUntil, isNull);
  });

  test(
    'deferral changes reminder timing without changing the true due date',
    () {
      final due = DateTime(2026, 4, 1);
      final plan = MaintenancePlan(
        id: 'filter',
        title: '清洗滤网',
        intervalDays: 90,
        dueDate: due,
      );

      final deferred = plan.deferredTo(DateTime(2026, 4, 5));

      expect(deferred.dueDate, due);
      expect(deferred.effectiveReminderDate, DateTime(2026, 4, 5));
    },
  );

  test('plan edits keep deferral only when schedule facts are unchanged', () {
    final plan = MaintenancePlan(
      id: 'filter',
      title: '清洗滤网',
      intervalDays: 90,
      reminderLeadDays: 3,
      enabled: true,
      lastCompletedAt: DateTime(2026, 5, 1),
      dueDate: DateTime(2026, 8, 22),
      deferredUntil: DateTime(2026, 8, 29),
    );

    DateTime? edited({
      int intervalDays = 90,
      int reminderLeadDays = 3,
      bool enabled = true,
      DateTime? lastCompletedAt,
      DateTime? dueDate,
    }) => plan.deferredUntilAfterScheduleEdit(
      intervalDays: intervalDays,
      reminderLeadDays: reminderLeadDays,
      enabled: enabled,
      lastCompletedAt: lastCompletedAt ?? DateTime(2026, 5, 1),
      dueDate: dueDate ?? DateTime(2026, 8, 22),
    );

    expect(edited(), DateTime(2026, 8, 29));
    expect(edited(intervalDays: 120), isNull);
    expect(edited(reminderLeadDays: 7), isNull);
    expect(edited(enabled: false), isNull);
    expect(edited(lastCompletedAt: DateTime(2026, 5, 2)), isNull);
    expect(edited(dueDate: DateTime(2026, 9, 30)), isNull);
  });

  test('v2 item round-trip preserves multiple plans and rich records', () {
    final item = CareItem(
      id: 'air-conditioner',
      name: '空调',
      category: '家电',
      location: '客厅',
      brand: '',
      model: '',
      notes: '',
      photos: const ['/photos/device.jpg'],
      plans: [
        MaintenancePlan(
          id: 'filter',
          title: '清洗滤网',
          intervalDays: 90,
          dueDate: DateTime(2026, 4, 1),
          checklist: const [
            MaintenanceStep(
              id: 'power',
              title: '断电',
              description: '关闭设备电源并确认停止运行',
              sortOrder: 0,
            ),
          ],
        ),
        MaintenancePlan(
          id: 'deep-clean',
          title: '深度清洗',
          intervalDays: 365,
          dueDate: DateTime(2027, 1, 1),
        ),
      ],
      records: [
        MaintenanceRecord(
          id: 'record-1',
          planId: 'filter',
          completedAt: DateTime(2026, 1, 1),
          cost: 38.5,
          materialName: '滤网清洁剂',
          note: '已晾干',
          completedStepIds: const ['power'],
          stepSnapshots: const [
            MaintenanceStepSnapshot(
              id: 'power',
              title: '断电',
              sortOrder: 0,
              completed: true,
            ),
          ],
          photos: const ['/photos/result.jpg'],
          kind: '清洗滤网',
        ),
      ],
    );

    final restored = CareDataEnvelope.decode(
      CareDataEnvelope(items: [item]).encode(),
    ).items.single;

    expect(restored.plans, hasLength(2));
    expect(restored.plans.first.checklist.single.title, '断电');
    expect(restored.plans.first.checklist.single.description, '关闭设备电源并确认停止运行');
    expect(restored.records.single.planId, 'filter');
    expect(restored.records.single.materialName, '滤网清洁剂');
    expect(restored.records.single.completedStepIds, ['power']);
    expect(restored.records.single.stepSnapshots?.single.title, '断电');
    expect(restored.records.single.stepSnapshots?.single.completed, isTrue);
    expect(restored.records.single.photos, ['/photos/result.jpg']);
  });

  test(
    'clearing the legacy interval disables its plan without re-showing it',
    () {
      final item = CareItem(
        id: 'washer',
        name: '洗衣机',
        category: '家电',
        location: '',
        brand: '',
        model: '',
        notes: '',
        photos: const [],
        lastCareDate: DateTime(2026, 1, 1),
        intervalDays: 30,
      );

      final cleared = item.copyWith(clearInterval: true);

      expect(cleared.intervalDays, isNull);
      expect(cleared.nextCareDate, isNull);
      expect(cleared.plans.single.enabled, isFalse);
      expect(cleared.plans.single.lastCompletedAt, DateTime(2026, 1, 1));
    },
  );

  test('removing a plan archives it when linked history exists', () {
    final plan = MaintenancePlan(
      id: 'filter',
      title: '更换滤芯',
      intervalDays: 180,
      dueDate: DateTime(2026, 9, 1),
    );
    final item = CareItem(
      id: 'purifier',
      name: '净水器',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [plan],
      records: [
        MaintenanceRecord(
          id: 'record-1',
          planId: 'filter',
          completedAt: DateTime(2026, 3, 1),
          cost: 0,
          note: '',
        ),
      ],
    );

    final archived = item.removeOrArchivePlan('filter');

    expect(archived.plans.single.archived, isTrue);
    expect(archived.plans.single.enabled, isFalse);
    expect(archived.records.single.planId, 'filter');
    expect(archived.nextCareDate, isNull);
  });

  test('explicitly deleting the last migrated plan does not recreate it', () {
    final item = CareItem(
      id: 'legacy-item',
      name: '旧物品',
      category: '其他',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      lastCareDate: DateTime(2026, 1, 1),
      intervalDays: 30,
    );

    final deleted = item.copyWith(plans: const []);
    final renamed = deleted.copyWith(name: '仍为空');

    expect(deleted.plans, isEmpty);
    expect(deleted.nextCareDate, isNull);
    expect(renamed.plans, isEmpty);
  });

  test('built-in purifier template creates an editable complete plan', () {
    final template = maintenanceTemplates.firstWhere(
      (entry) => entry.id == 'water-purifier-filter',
    );

    final plan = template.createPlan(
      planId: 'plan-1',
      referenceDate: DateTime(2026, 1, 1),
    );

    expect(plan.title, '更换滤芯');
    expect(plan.intervalDays, 180);
    expect(plan.dueDate, DateTime(2026, 6, 30));
    expect(plan.checklist.map((step) => step.title), [
      '核对型号',
      '关闭水源',
      '更换',
      '冲洗',
    ]);
    expect(plan.checklist.map((step) => step.description), [
      '请确认净水器型号与适配滤芯',
      '关闭进水阀，确保停止进水',
      '拆卸旧滤芯，安装新滤芯',
      '打开水源，冲洗滤芯至出水清澈',
    ]);
  });

  test('legacy built-in plans gain instructions without changing step ids', () {
    final legacy = MaintenancePlan(
      id: 'legacy-filter',
      title: '更换滤芯',
      intervalDays: 180,
      checklist: const [
        MaintenanceStep(id: 'legacy-0', title: '核对型号', sortOrder: 0),
        MaintenanceStep(id: 'legacy-1', title: '关闭水源', sortOrder: 1),
        MaintenanceStep(id: 'legacy-2', title: '更换', sortOrder: 2),
        MaintenanceStep(id: 'legacy-3', title: '冲洗', sortOrder: 3),
      ],
    );

    final enriched = enrichMaintenanceTemplateStepDescriptions(legacy);

    expect(enriched.checklist.map((step) => step.id), [
      'legacy-0',
      'legacy-1',
      'legacy-2',
      'legacy-3',
    ]);
    expect(enriched.checklist.map((step) => step.description), [
      '请确认净水器型号与适配滤芯',
      '关闭进水阀，确保停止进水',
      '拆卸旧滤芯，安装新滤芯',
      '打开水源，冲洗滤芯至出水清澈',
    ]);
  });

  test('plan validation enforces interval, reminder, and date boundaries', () {
    expect(MaintenancePlanValidator.title('  '), isNotNull);
    expect(MaintenancePlanValidator.interval('0'), isNotNull);
    expect(MaintenancePlanValidator.interval('3651'), isNotNull);
    expect(MaintenancePlanValidator.interval('180'), isNull);
    expect(
      MaintenancePlanValidator.reminderLead('181', intervalDays: 180),
      isNotNull,
    );
    expect(
      MaintenancePlanValidator.reminderLead('3', intervalDays: 180),
      isNull,
    );
    expect(MaintenancePlanValidator.dates(null, null), isNotNull);
    expect(
      MaintenancePlanValidator.dates(
        DateTime(2026, 2, 1),
        DateTime(2026, 1, 1),
      ),
      isNotNull,
    );
    expect(MaintenancePlanValidator.dates(null, DateTime(2026, 1, 1)), isNull);
  });

  test('plan notification ids are stable and do not overwrite siblings', () {
    final first = notificationIdForPlan('item-1', 'filter');
    final second = notificationIdForPlan('item-1', 'deep-clean');

    expect(notificationIdForPlan('item-1', 'filter'), first);
    expect(second, isNot(first));
    expect(first, greaterThan(0));
  });

  test('adding a linked record advances only its selected plan', () async {
    SharedPreferences.setMockInitialValues({});
    final filter = MaintenancePlan(
      id: 'filter',
      title: '清洗滤网',
      intervalDays: 90,
      dueDate: DateTime(2026, 4, 1),
    );
    final deepClean = MaintenancePlan(
      id: 'deep-clean',
      title: '深度清洗',
      intervalDays: 365,
      dueDate: DateTime(2027, 1, 1),
    );
    final item = CareItem(
      id: 'air-conditioner',
      name: '空调',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [filter, deepClean],
    );
    final store = CareStore()..items = [item];

    await store.addRecord(
      item,
      MaintenanceRecord(
        id: 'record-1',
        planId: 'filter',
        completedAt: DateTime(2026, 4, 10),
        cost: 0,
        note: '',
      ),
    );

    final saved = store.items.single;
    expect(saved.records.single.planId, 'filter');
    expect(
      saved.plans.firstWhere((plan) => plan.id == 'filter').dueDate,
      DateTime(2026, 7, 9),
    );
    expect(
      saved.plans.firstWhere((plan) => plan.id == 'deep-clean').dueDate,
      DateTime(2027, 1, 1),
    );
  });

  test('adding an unlinked history record does not advance any plan', () async {
    SharedPreferences.setMockInitialValues({});
    final dueDate = DateTime(2026, 4, 1);
    final item = CareItem(
      id: 'air-conditioner',
      name: '空调',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [
        MaintenancePlan(
          id: 'filter',
          title: '清洗滤网',
          intervalDays: 90,
          dueDate: dueDate,
        ),
      ],
    );
    final store = CareStore()..items = [item];

    await store.addRecord(
      item,
      MaintenanceRecord(
        id: 'record-1',
        completedAt: DateTime(2026, 4, 10),
        cost: 0,
        note: '',
      ),
    );

    final saved = store.items.single;
    expect(saved.records.single.planId, isNull);
    expect(saved.plans.single.dueDate, dueDate);
  });
}
