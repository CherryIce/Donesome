import 'care_item.dart';
import 'maintenance_calendar.dart';
import 'maintenance_plan.dart';
import 'maintenance_record.dart';

class MaintenanceCompletionDraft {
  MaintenanceCompletionDraft({
    required this.operationId,
    required this.itemId,
    required this.planId,
    required DateTime completedAt,
    required this.cost,
    this.materialName = '',
    this.note = '',
    List<String> completedStepIds = const [],
    List<String> beforePhotos = const [],
    List<String> afterPhotos = const [],
  }) : completedAt = maintenanceDateOnly(completedAt),
       completedStepIds = List.unmodifiable(completedStepIds),
       beforePhotos = List.unmodifiable(beforePhotos),
       afterPhotos = List.unmodifiable(afterPhotos);

  final String operationId;
  final String itemId;
  final String planId;
  final DateTime completedAt;
  final double cost;
  final String materialName;
  final String note;
  final List<String> completedStepIds;
  final List<String> beforePhotos;
  final List<String> afterPhotos;

  String get recordId => 'record-$itemId-$planId-$operationId';
}

class MaintenanceCompletionResult {
  const MaintenanceCompletionResult({
    required this.item,
    required this.plan,
    required this.record,
    required this.notificationScheduled,
    this.alreadyCompleted = false,
  });

  final CareItem item;
  final MaintenancePlan plan;
  final MaintenanceRecord record;
  final bool notificationScheduled;
  final bool alreadyCompleted;
}

class MaintenanceCompletionException implements Exception {
  const MaintenanceCompletionException(this.message);

  final String message;

  @override
  String toString() => 'MaintenanceCompletionException: $message';
}

void validateMaintenanceCompletion(
  MaintenanceCompletionDraft draft,
  MaintenancePlan plan, {
  DateTime? now,
}) {
  if (draft.operationId.trim().isEmpty || draft.operationId.length > 120) {
    throw const MaintenanceCompletionException('完成操作标识无效，请重试。');
  }
  if (!draft.cost.isFinite || draft.cost < 0) {
    throw const MaintenanceCompletionException('本次费用必须为大于或等于 0 的有限数。');
  }
  final completedAt = maintenanceDateOnly(draft.completedAt);
  final today = maintenanceDateOnly(now ?? DateTime.now());
  if (completedAt.isBefore(DateTime(2000)) || completedAt.isAfter(today)) {
    throw const MaintenanceCompletionException('完成日期需在 2000 年至今天之间。');
  }
  final previousCompletion = plan.lastCompletedAt;
  if (previousCompletion != null &&
      completedAt.isBefore(maintenanceDateOnly(previousCompletion))) {
    throw const MaintenanceCompletionException('完成日期不能早于该计划上次完成日期。');
  }
  final stepIds = plan.checklist.map((step) => step.id).toSet();
  final completedIds = draft.completedStepIds.toSet();
  if (completedIds.length != draft.completedStepIds.length ||
      !stepIds.containsAll(completedIds)) {
    throw const MaintenanceCompletionException('步骤完成结果与当前计划不一致，请重新确认。');
  }
}
