import 'care_item.dart';
import 'maintenance_plan.dart';
import 'maintenance_status.dart';

class MaintenanceTask {
  const MaintenanceTask({
    required this.item,
    required this.plan,
    required this.status,
  });

  final CareItem item;
  final MaintenancePlan plan;
  final MaintenancePlanStatus status;

  String get id => '${item.id}:${plan.id}';
  DateTime get dueDate => status.dueDate!;
}

List<MaintenanceTask> maintenanceTasksForItems(
  Iterable<CareItem> items, {
  DateTime? now,
}) {
  final tasks = <MaintenanceTask>[];
  for (final item in items) {
    for (final plan in item.plans) {
      final status = MaintenancePlanStatus.evaluate(plan, now: now);
      if (status.state == MaintenanceTaskState.disabled ||
          status.dueDate == null) {
        continue;
      }
      tasks.add(MaintenanceTask(item: item, plan: plan, status: status));
    }
  }
  tasks.sort(compareMaintenanceTasks);
  return tasks;
}

int compareMaintenanceTasks(MaintenanceTask a, MaintenanceTask b) {
  final stateOrder = a.status.sortRank.compareTo(b.status.sortRank);
  if (stateOrder != 0) return stateOrder;
  final dateOrder = a.dueDate.compareTo(b.dueDate);
  if (dateOrder != 0) return dateOrder;
  final itemOrder = a.item.name.compareTo(b.item.name);
  if (itemOrder != 0) return itemOrder;
  return a.plan.title.compareTo(b.plan.title);
}
