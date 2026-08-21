import 'dart:convert';

import 'care_item.dart';
import 'maintenance_status.dart';
import 'maintenance_task.dart';

class MaintenanceNotificationPayload {
  const MaintenanceNotificationPayload({
    required this.itemId,
    required this.planId,
    this.version = currentVersion,
  });

  static const int currentVersion = 1;
  static const int maxPayloadBytes = 1024;
  static const int maxIdentityLength = 256;

  final int version;
  final String itemId;
  final String planId;

  String encode() =>
      jsonEncode({'version': version, 'itemId': itemId, 'planId': planId});

  static MaintenanceNotificationPayload? tryDecode(String? value) {
    if (value == null || value.isEmpty) return null;
    if (utf8.encode(value).length > maxPayloadBytes) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);
      final version = json['version'];
      final itemId = json['itemId'];
      final planId = json['planId'];
      if (version != currentVersion ||
          itemId is! String ||
          planId is! String ||
          !_isValidIdentity(itemId) ||
          !_isValidIdentity(planId)) {
        return null;
      }
      return MaintenanceNotificationPayload(
        version: version as int,
        itemId: itemId,
        planId: planId,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isValidIdentity(String value) =>
      value.trim().isNotEmpty && value.length <= maxIdentityLength;
}

enum MaintenanceNotificationResolutionType {
  ready,
  malformed,
  itemUnavailable,
  planUnavailable,
}

class MaintenanceNotificationResolution {
  const MaintenanceNotificationResolution._({required this.type, this.task});

  const MaintenanceNotificationResolution.ready(MaintenanceTask task)
    : this._(type: MaintenanceNotificationResolutionType.ready, task: task);

  const MaintenanceNotificationResolution.malformed()
    : this._(type: MaintenanceNotificationResolutionType.malformed);

  const MaintenanceNotificationResolution.itemUnavailable()
    : this._(type: MaintenanceNotificationResolutionType.itemUnavailable);

  const MaintenanceNotificationResolution.planUnavailable()
    : this._(type: MaintenanceNotificationResolutionType.planUnavailable);

  final MaintenanceNotificationResolutionType type;
  final MaintenanceTask? task;
}

MaintenanceNotificationResolution resolveMaintenanceNotification(
  String? value,
  Iterable<CareItem> items,
) {
  final payload = MaintenanceNotificationPayload.tryDecode(value);
  if (payload == null) {
    return const MaintenanceNotificationResolution.malformed();
  }

  CareItem? item;
  for (final candidate in items) {
    if (candidate.id == payload.itemId) {
      item = candidate;
      break;
    }
  }
  if (item == null) {
    return const MaintenanceNotificationResolution.itemUnavailable();
  }

  for (final plan in item.plans) {
    if (plan.id != payload.planId) continue;
    final status = MaintenancePlanStatus.evaluate(plan);
    if (status.state == MaintenanceTaskState.disabled ||
        status.dueDate == null) {
      return const MaintenanceNotificationResolution.planUnavailable();
    }
    return MaintenanceNotificationResolution.ready(
      MaintenanceTask(item: item, plan: plan, status: status),
    );
  }
  return const MaintenanceNotificationResolution.planUnavailable();
}
