import 'maintenance_plan.dart';

class MaintenanceStepSnapshot {
  const MaintenanceStepSnapshot({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.completed,
  });

  factory MaintenanceStepSnapshot.fromStep(
    MaintenanceStep step, {
    required bool completed,
  }) => MaintenanceStepSnapshot(
    id: step.id,
    title: step.title,
    sortOrder: step.sortOrder,
    completed: completed,
  );

  final String id;
  final String title;
  final int sortOrder;
  final bool completed;

  MaintenanceStepSnapshot copyWith({bool? completed}) =>
      MaintenanceStepSnapshot(
        id: id,
        title: title,
        sortOrder: sortOrder,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sortOrder': sortOrder,
    'completed': completed,
  };

  factory MaintenanceStepSnapshot.fromJson(Map<String, dynamic> json) =>
      MaintenanceStepSnapshot(
        id: json['id'] as String,
        title: json['title'] as String,
        sortOrder: json['sortOrder'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}

List<MaintenanceStepSnapshot> captureMaintenanceStepSnapshots(
  MaintenancePlan? plan,
  Iterable<String> completedStepIds,
) {
  final completedIds = completedStepIds.toSet();
  final snapshots = <MaintenanceStepSnapshot>[];
  final knownIds = <String>{};
  final checklist = [...?plan?.checklist]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  for (final step in checklist) {
    knownIds.add(step.id);
    snapshots.add(
      MaintenanceStepSnapshot.fromStep(
        step,
        completed: completedIds.contains(step.id),
      ),
    );
  }
  var fallbackOrder = snapshots.isEmpty
      ? 0
      : snapshots
                .map((step) => step.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1;
  for (final id in completedIds.where((id) => !knownIds.contains(id))) {
    snapshots.add(
      MaintenanceStepSnapshot(
        id: id,
        title: '原步骤内容不可用',
        sortOrder: fallbackOrder++,
        completed: true,
      ),
    );
  }
  return List.unmodifiable(snapshots);
}

class MaintenanceRecord {
  MaintenanceRecord({
    String? id,
    this.planId,
    DateTime? completedAt,
    this.plannedDueDate,
    DateTime? date,
    String? kind,
    required this.cost,
    this.materialName = '',
    required this.note,
    List<String> completedStepIds = const [],
    List<MaintenanceStepSnapshot>? stepSnapshots,
    List<String> photos = const [],
    List<String>? beforePhotos,
    List<String>? afterPhotos,
  }) : completedAt = completedAt ?? date ?? DateTime.now(),
       kind = kind?.trim().isNotEmpty == true ? kind!.trim() : '保养',
       stepSnapshots = stepSnapshots == null
           ? null
           : List.unmodifiable(stepSnapshots),
       completedStepIds = List.unmodifiable(
         stepSnapshots == null
             ? completedStepIds
             : stepSnapshots
                   .where((step) => step.completed)
                   .map((step) => step.id),
       ),
       beforePhotos = List.unmodifiable(beforePhotos ?? const []),
       afterPhotos = List.unmodifiable(afterPhotos ?? photos),
       photos = List.unmodifiable([
         ...?beforePhotos,
         ...(afterPhotos ?? photos),
       ]),
       id =
           id ??
           'record-${(completedAt ?? date ?? DateTime.now()).microsecondsSinceEpoch}';

  final String id;
  final String? planId;
  final DateTime completedAt;
  final DateTime? plannedDueDate;
  final double cost;
  final String materialName;
  final String note;
  final List<String> completedStepIds;
  final List<MaintenanceStepSnapshot>? stepSnapshots;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final List<String> photos;

  // Immutable task-title fact captured when the record is completed. The
  // legacy name is retained for backward-compatible storage.
  final String kind;

  DateTime get date => completedAt;

  MaintenanceRecord copyWith({
    String? planId,
    DateTime? completedAt,
    DateTime? plannedDueDate,
    double? cost,
    String? materialName,
    String? note,
    List<String>? completedStepIds,
    List<MaintenanceStepSnapshot>? stepSnapshots,
    List<String>? photos,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    String? kind,
    bool clearPlanId = false,
    bool clearPlannedDueDate = false,
  }) => MaintenanceRecord(
    id: id,
    planId: clearPlanId ? null : planId ?? this.planId,
    completedAt: completedAt ?? this.completedAt,
    plannedDueDate: clearPlannedDueDate
        ? null
        : plannedDueDate ?? this.plannedDueDate,
    cost: cost ?? this.cost,
    materialName: materialName ?? this.materialName,
    note: note ?? this.note,
    completedStepIds: completedStepIds ?? this.completedStepIds,
    stepSnapshots:
        stepSnapshots ??
        (completedStepIds == null || this.stepSnapshots == null
            ? this.stepSnapshots
            : this.stepSnapshots!
                  .map(
                    (step) => step.copyWith(
                      completed: completedStepIds.contains(step.id),
                    ),
                  )
                  .toList(growable: false)),
    beforePhotos: beforePhotos ?? (photos == null ? this.beforePhotos : null),
    afterPhotos: afterPhotos ?? photos ?? this.afterPhotos,
    kind: kind ?? this.kind,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'completedAt': completedAt.toIso8601String(),
    'plannedDueDate': plannedDueDate?.toIso8601String(),
    'cost': cost,
    'materialName': materialName,
    'note': note,
    'completedStepIds': completedStepIds,
    if (stepSnapshots != null)
      'stepSnapshots': stepSnapshots!.map((step) => step.toJson()).toList(),
    'photos': photos,
    'beforePhotos': beforePhotos,
    'afterPhotos': afterPhotos,
    'kind': kind,
  };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    final dateValue = json['completedAt'] ?? json['date'];
    if (dateValue is! String) {
      throw const FormatException('Maintenance record date is missing');
    }
    final completedAt = DateTime.tryParse(dateValue);
    if (completedAt == null) {
      throw const FormatException('Invalid maintenance record date');
    }
    final legacyPhotos = List<String>.from(json['photos'] as List? ?? const []);
    return MaintenanceRecord(
      id:
          json['id'] as String? ??
          'record-${completedAt.microsecondsSinceEpoch}',
      planId: json['planId'] as String?,
      completedAt: completedAt,
      plannedDueDate: _parseOptionalDate(json['plannedDueDate']),
      cost: (json['cost'] as num? ?? 0).toDouble(),
      materialName: json['materialName'] as String? ?? '',
      note: json['note'] as String? ?? '',
      completedStepIds: List<String>.from(
        json['completedStepIds'] as List? ?? const [],
      ),
      stepSnapshots: json.containsKey('stepSnapshots')
          ? (json['stepSnapshots'] as List? ?? const [])
                .map(
                  (value) => MaintenanceStepSnapshot.fromJson(
                    Map<String, dynamic>.from(value as Map),
                  ),
                )
                .toList(growable: false)
          : null,
      beforePhotos: List<String>.from(
        json['beforePhotos'] as List? ?? const [],
      ),
      afterPhotos: json.containsKey('afterPhotos')
          ? List<String>.from(json['afterPhotos'] as List? ?? const [])
          : legacyPhotos,
      kind: json['kind'] as String? ?? '保养',
    );
  }

  factory MaintenanceRecord.fromLegacyJson(
    Map<String, dynamic> json, {
    required String itemId,
    required int index,
    String? defaultPlanId,
  }) {
    final record = MaintenanceRecord.fromJson(json);
    return record
        .copyWith(planId: record.planId ?? defaultPlanId)
        ._withId('legacy-record-$itemId-$index');
  }

  MaintenanceRecord _withId(String value) => MaintenanceRecord(
    id: value,
    planId: planId,
    completedAt: completedAt,
    plannedDueDate: plannedDueDate,
    cost: cost,
    materialName: materialName,
    note: note,
    completedStepIds: completedStepIds,
    stepSnapshots: stepSnapshots,
    beforePhotos: beforePhotos,
    afterPhotos: afterPhotos,
    kind: kind,
  );
}

DateTime? _parseOptionalDate(dynamic value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Invalid planned maintenance date');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const FormatException('Invalid planned maintenance date');
  }
  return parsed;
}
