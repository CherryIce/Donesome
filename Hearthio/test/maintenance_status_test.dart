import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  MaintenancePlan plan({
    required String id,
    required DateTime dueDate,
    int reminderLeadDays = 3,
    bool enabled = true,
    DateTime? deferredUntil,
  }) => MaintenancePlan(
    id: id,
    title: id,
    intervalDays: 30,
    reminderLeadDays: reminderLeadDays,
    enabled: enabled,
    dueDate: dueDate,
    deferredUntil: deferredUntil,
  );

  test(
    'unified status covers planned, due soon, today, overdue and disabled',
    () {
      final now = DateTime(2026, 8, 19, 23, 59);

      expect(
        MaintenancePlanStatus.evaluate(
          plan(id: 'planned', dueDate: DateTime(2026, 9, 19)),
          now: now,
        ).state,
        MaintenanceTaskState.planned,
      );
      expect(
        MaintenancePlanStatus.evaluate(
          plan(id: 'soon', dueDate: DateTime(2026, 8, 22)),
          now: now,
        ).state,
        MaintenanceTaskState.dueSoon,
      );
      expect(
        MaintenancePlanStatus.evaluate(
          plan(id: 'today', dueDate: DateTime(2026, 8, 19)),
          now: now,
        ).state,
        MaintenanceTaskState.dueToday,
      );
      expect(
        MaintenancePlanStatus.evaluate(
          plan(id: 'overdue', dueDate: DateTime(2026, 8, 18)),
          now: now,
        ).state,
        MaintenanceTaskState.overdue,
      );
      expect(
        MaintenancePlanStatus.evaluate(
          plan(id: 'disabled', dueDate: DateTime(2026, 8, 19), enabled: false),
          now: now,
        ).state,
        MaintenanceTaskState.disabled,
      );
    },
  );

  test(
    'deferral keeps the original overdue state and sort priority visible',
    () {
      final status = MaintenancePlanStatus.evaluate(
        plan(
          id: 'filter',
          dueDate: DateTime(2026, 8, 10),
          deferredUntil: DateTime(2026, 8, 22),
        ),
        now: DateTime(2026, 8, 19),
      );

      expect(status.state, MaintenanceTaskState.deferred);
      expect(status.dueState, MaintenanceTaskState.overdue);
      expect(status.sortRank, 0);
      expect(status.timingLabel, '已逾期 9 天');
    },
  );

  test('expired deferral falls back to the normal reminder date', () {
    final source = plan(
      id: 'filter',
      dueDate: DateTime(2026, 8, 30),
      reminderLeadDays: 3,
      deferredUntil: DateTime(2026, 8, 18),
    );

    final status = MaintenancePlanStatus.evaluate(
      source,
      now: DateTime(2026, 8, 19),
    );

    expect(status.hasActiveDeferral, isFalse);
    expect(status.deferredUntil, isNull);
    expect(
      maintenanceReminderDateForPlan(source, now: DateTime(2026, 8, 19)),
      DateTime(2026, 8, 27),
    );
    expect(
      clearExpiredMaintenanceDeferral(
        source,
        now: DateTime(2026, 8, 19),
      ).deferredUntil,
      isNull,
    );
  });

  test('task ordering is overdue, today, due soon, then planned', () {
    final now = DateTime(2026, 8, 19);
    final item = CareItem(
      id: 'item',
      name: '设备',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [
        plan(id: 'planned', dueDate: DateTime(2026, 9, 19)),
        plan(id: 'soon', dueDate: DateTime(2026, 8, 21)),
        plan(id: 'overdue', dueDate: DateTime(2026, 8, 18)),
        plan(id: 'today', dueDate: DateTime(2026, 8, 19)),
      ],
    );

    final tasks = maintenanceTasksForItems([item], now: now);

    expect(tasks.map((task) => task.plan.id), [
      'overdue',
      'today',
      'soon',
      'planned',
    ]);
  });

  test('calendar-day math handles leap years and month boundaries', () {
    final leapPlan = plan(
      id: 'leap',
      dueDate: DateTime(2028, 3, 1),
      reminderLeadDays: 2,
    );

    expect(
      MaintenancePlanStatus.evaluate(
        leapPlan,
        now: DateTime(2028, 2, 28, 23, 59),
      ).daysUntilDue,
      2,
    );
    expect(
      MaintenancePlanStatus.evaluate(
        leapPlan,
        now: DateTime(2028, 2, 29),
      ).daysUntilDue,
      1,
    );
    expect(
      MaintenancePlanStatus.evaluate(leapPlan, now: DateTime(2028, 3, 1)).state,
      MaintenanceTaskState.dueToday,
    );
  });

  test('day boundary and zone metadata cannot move a civil due date', () {
    final localPlan = plan(id: 'boundary', dueDate: DateTime(2026, 8, 20));
    final utcPlan = plan(
      id: 'utc-boundary',
      dueDate: DateTime.utc(2026, 8, 20, 23, 30),
    );

    expect(
      MaintenancePlanStatus.evaluate(
        localPlan,
        now: DateTime(2026, 8, 19, 23, 59),
      ).state,
      MaintenanceTaskState.dueSoon,
    );
    expect(
      MaintenancePlanStatus.evaluate(
        localPlan,
        now: DateTime(2026, 8, 20),
      ).state,
      MaintenanceTaskState.dueToday,
    );
    expect(
      MaintenancePlanStatus.evaluate(
        utcPlan,
        now: DateTime.utc(2026, 8, 20, 0, 1),
      ).state,
      MaintenanceTaskState.dueToday,
    );
  });

  test(
    'deferring a plan changes no due date, completion, or history',
    () async {
      SharedPreferences.setMockInitialValues({});
      final dueDate = maintenanceDateOnly(
        DateTime.now().subtract(const Duration(days: 2)),
      );
      final completedAt = dueDate.subtract(const Duration(days: 30));
      final item = CareItem(
        id: 'purifier',
        name: '净水器',
        category: '家电',
        location: '',
        brand: '',
        model: '',
        notes: '',
        photos: const [],
        plans: [
          MaintenancePlan(
            id: 'filter',
            title: '更换滤芯',
            intervalDays: 180,
            dueDate: dueDate,
            lastCompletedAt: completedAt,
          ),
        ],
      );
      final store = CareStore()..items = [item];
      final tomorrow = maintenanceDateOnly(
        DateTime.now().add(const Duration(days: 1)),
      );

      await store.deferPlan(item, 'filter', tomorrow);

      final saved = store.items.single;
      expect(saved.plans.single.dueDate, dueDate);
      expect(saved.plans.single.lastCompletedAt, completedAt);
      expect(saved.plans.single.deferredUntil, tomorrow);
      expect(saved.records, isEmpty);
    },
  );
}
