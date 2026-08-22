import 'maintenance_calendar.dart';
import 'maintenance_plan.dart';

enum MaintenanceTaskState {
  planned,
  dueSoon,
  dueToday,
  overdue,
  deferred,
  completed,
  disabled,
}

DateTime? validMaintenanceDeferralDate(
  DateTime? deferredUntil, {
  DateTime? now,
}) {
  if (deferredUntil == null) return null;
  final today = maintenanceDateOnly(now ?? DateTime.now());
  final deferredDate = maintenanceDateOnly(deferredUntil);
  return deferredDate.isBefore(today) ? null : deferredDate;
}

DateTime? maintenanceReminderDateForPlan(
  MaintenancePlan plan, {
  DateTime? now,
}) {
  final dueDate = plan.dueDate;
  if (dueDate == null) return null;
  return validMaintenanceDeferralDate(plan.deferredUntil, now: now) ??
      addMaintenanceDays(dueDate, -plan.reminderLeadDays);
}

bool shouldScheduleMaintenanceNotification(
  MaintenancePlan plan, {
  DateTime? now,
}) {
  final dueDate = plan.dueDate;
  if (dueDate == null ||
      maintenanceReminderDateForPlan(plan, now: now) == null) {
    return false;
  }
  final today = maintenanceDateOnly(now ?? DateTime.now());
  final dueDay = maintenanceDateOnly(dueDate);
  if (!dueDay.isBefore(today)) return true;

  // An overdue plan normally should not create a fresh notification on every
  // app launch. A still-active one-off deferral is different: when its chosen
  // day arrives, it must be delivered even though the original due date passed.
  return validMaintenanceDeferralDate(plan.deferredUntil, now: today) != null;
}

MaintenancePlan clearExpiredMaintenanceDeferral(
  MaintenancePlan plan, {
  DateTime? now,
}) {
  if (plan.deferredUntil == null ||
      validMaintenanceDeferralDate(plan.deferredUntil, now: now) != null) {
    return plan;
  }
  return plan.copyWith(clearDeferredUntil: true);
}

class MaintenancePlanStatus {
  const MaintenancePlanStatus({
    required this.state,
    required this.dueState,
    required this.today,
    required this.dueDate,
    required this.deferredUntil,
    required this.daysUntilDue,
  });

  factory MaintenancePlanStatus.evaluate(
    MaintenancePlan plan, {
    DateTime? now,
  }) {
    final today = maintenanceDateOnly(now ?? DateTime.now());
    final dueDate = plan.dueDate == null
        ? null
        : maintenanceDateOnly(plan.dueDate!);
    final deferredUntil = validMaintenanceDeferralDate(
      plan.deferredUntil,
      now: today,
    );
    final daysUntilDue = dueDate == null
        ? null
        : maintenanceDayDifference(dueDate, today);

    if (!plan.enabled || plan.archived) {
      return MaintenancePlanStatus(
        state: MaintenanceTaskState.disabled,
        dueState: MaintenanceTaskState.disabled,
        today: today,
        dueDate: dueDate,
        deferredUntil: deferredUntil,
        daysUntilDue: daysUntilDue,
      );
    }

    final dueState = switch (daysUntilDue) {
      null => MaintenanceTaskState.planned,
      < 0 => MaintenanceTaskState.overdue,
      0 => MaintenanceTaskState.dueToday,
      final days when days <= plan.reminderLeadDays =>
        MaintenanceTaskState.dueSoon,
      _ => MaintenanceTaskState.planned,
    };
    final hasActiveDeferral = deferredUntil != null;
    return MaintenancePlanStatus(
      state: hasActiveDeferral ? MaintenanceTaskState.deferred : dueState,
      dueState: dueState,
      today: today,
      dueDate: dueDate,
      deferredUntil: deferredUntil,
      daysUntilDue: daysUntilDue,
    );
  }

  final MaintenanceTaskState state;

  /// The state derived from the real due date. This remains visible when a
  /// reminder is deferred, so snoozing can never make an overdue task look
  /// current.
  final MaintenanceTaskState dueState;
  final DateTime today;
  final DateTime? dueDate;
  final DateTime? deferredUntil;
  final int? daysUntilDue;

  bool get hasActiveDeferral => state == MaintenanceTaskState.deferred;

  int get sortRank => switch (dueState) {
    MaintenanceTaskState.overdue => 0,
    MaintenanceTaskState.dueToday => 1,
    MaintenanceTaskState.dueSoon => 2,
    MaintenanceTaskState.planned => 3,
    MaintenanceTaskState.deferred => 3,
    MaintenanceTaskState.disabled => 4,
    MaintenanceTaskState.completed => 5,
  };

  String get label => switch (state) {
    MaintenanceTaskState.planned => '已计划',
    MaintenanceTaskState.dueSoon => '即将到期',
    MaintenanceTaskState.dueToday => '今日到期',
    MaintenanceTaskState.overdue => '已逾期',
    MaintenanceTaskState.deferred => '已稍后提醒',
    MaintenanceTaskState.completed => '已完成',
    MaintenanceTaskState.disabled => '已停用',
  };

  String get dueStateLabel => switch (dueState) {
    MaintenanceTaskState.planned => '已计划',
    MaintenanceTaskState.dueSoon => '即将到期',
    MaintenanceTaskState.dueToday => '今日到期',
    MaintenanceTaskState.overdue => '已逾期',
    MaintenanceTaskState.deferred => '已稍后提醒',
    MaintenanceTaskState.completed => '已完成',
    MaintenanceTaskState.disabled => '已停用',
  };

  String get timingLabel {
    final days = daysUntilDue;
    if (days == null) return '尚未设置到期日';
    if (days < 0) return '已逾期 ${-days} 天';
    if (days == 0) return '今天到期';
    return '还有 $days 天';
  }
}
