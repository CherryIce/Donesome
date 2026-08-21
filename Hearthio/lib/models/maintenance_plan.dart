import 'maintenance_calendar.dart';

class MaintenanceStep {
  const MaintenanceStep({
    required this.id,
    required this.title,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sortOrder': sortOrder,
  };

  factory MaintenanceStep.fromJson(Map<String, dynamic> json) =>
      MaintenanceStep(
        id: json['id'] as String,
        title: json['title'] as String,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

class MaintenancePlan {
  MaintenancePlan({
    required this.id,
    required this.title,
    required this.intervalDays,
    this.reminderLeadDays = 3,
    List<MaintenanceStep> checklist = const [],
    this.enabled = true,
    this.lastCompletedAt,
    this.dueDate,
    this.deferredUntil,
    this.archived = false,
  }) : checklist = List.unmodifiable(checklist),
       assert(intervalDays > 0),
       assert(reminderLeadDays >= 0);

  final String id;
  final String title;
  final int intervalDays;
  final int reminderLeadDays;
  final List<MaintenanceStep> checklist;
  final bool enabled;
  final DateTime? lastCompletedAt;
  final DateTime? dueDate;
  final DateTime? deferredUntil;
  final bool archived;

  DateTime? get effectiveReminderDate => deferredUntil ?? dueDate;

  MaintenancePlan completedAt(DateTime completedAt) => copyWith(
    lastCompletedAt: maintenanceDateOnly(completedAt),
    dueDate: addMaintenanceDays(completedAt, intervalDays),
    clearDeferredUntil: true,
  );

  MaintenancePlan deferredTo(DateTime date) => copyWith(deferredUntil: date);

  /// Keeps a one-off deferral only while the plan's reminder schedule is
  /// unchanged. Title and checklist edits do not participate in this check.
  DateTime? deferredUntilAfterScheduleEdit({
    required int intervalDays,
    required int reminderLeadDays,
    required bool enabled,
    required DateTime? lastCompletedAt,
    required DateTime? dueDate,
  }) {
    final scheduleUnchanged =
        intervalDays == this.intervalDays &&
        reminderLeadDays == this.reminderLeadDays &&
        enabled == this.enabled &&
        _isSameMaintenanceDate(lastCompletedAt, this.lastCompletedAt) &&
        _isSameMaintenanceDate(dueDate, this.dueDate);
    return scheduleUnchanged ? deferredUntil : null;
  }

  MaintenancePlan copyWith({
    String? title,
    int? intervalDays,
    int? reminderLeadDays,
    List<MaintenanceStep>? checklist,
    bool? enabled,
    DateTime? lastCompletedAt,
    DateTime? dueDate,
    DateTime? deferredUntil,
    bool? archived,
    bool clearLastCompletedAt = false,
    bool clearDueDate = false,
    bool clearDeferredUntil = false,
  }) => MaintenancePlan(
    id: id,
    title: title ?? this.title,
    intervalDays: intervalDays ?? this.intervalDays,
    reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
    checklist: checklist ?? this.checklist,
    enabled: enabled ?? this.enabled,
    lastCompletedAt: clearLastCompletedAt
        ? null
        : lastCompletedAt ?? this.lastCompletedAt,
    dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    deferredUntil: clearDeferredUntil
        ? null
        : deferredUntil ?? this.deferredUntil,
    archived: archived ?? this.archived,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'intervalDays': intervalDays,
    'reminderLeadDays': reminderLeadDays,
    'checklist': checklist.map((step) => step.toJson()).toList(),
    'enabled': enabled,
    'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'deferredUntil': deferredUntil?.toIso8601String(),
    'archived': archived,
  };

  factory MaintenancePlan.fromJson(Map<String, dynamic> json) {
    final intervalDays = json['intervalDays'] as int;
    final reminderLeadDays = json['reminderLeadDays'] as int? ?? 3;
    if (intervalDays <= 0 || reminderLeadDays < 0) {
      throw const FormatException('Invalid maintenance plan interval');
    }
    return MaintenancePlan(
      id: json['id'] as String,
      title: json['title'] as String,
      intervalDays: intervalDays,
      reminderLeadDays: reminderLeadDays,
      checklist: (json['checklist'] as List? ?? const [])
          .map(
            (value) => MaintenanceStep.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
      enabled: json['enabled'] as bool? ?? true,
      lastCompletedAt: _parseDate(json['lastCompletedAt']),
      dueDate: _parseDate(json['dueDate']),
      deferredUntil: _parseDate(json['deferredUntil']),
      archived: json['archived'] as bool? ?? false,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid date');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed;
}

bool _isSameMaintenanceDate(DateTime? first, DateTime? second) {
  if (first == null || second == null) return first == second;
  return maintenanceDateOnly(first) == maintenanceDateOnly(second);
}
