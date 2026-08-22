import 'maintenance_calendar.dart';
import 'maintenance_plan.dart';
import 'maintenance_record.dart';
import 'maintenance_status.dart';

class CareItem {
  CareItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.spaceId,
    this.locationDetail = '',
    required this.brand,
    required this.model,
    required this.notes,
    required List<String> photos,
    List<MaintenancePlan> plans = const [],
    List<MaintenanceRecord> records = const [],
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.warrantyDate,
    DateTime? lastCareDate,
    int? intervalDays,
    this.isSample = false,
    bool createPlanFromLegacySchedule = true,
  }) : photos = List.unmodifiable(photos),
       records = List.unmodifiable(records),
       _legacyLastCareDate = lastCareDate,
       _legacyIntervalDays = intervalDays,
       _createPlanFromLegacySchedule = createPlanFromLegacySchedule,
       plans = List.unmodifiable(
         plans.isNotEmpty || !createPlanFromLegacySchedule
             ? plans
             : _planFromLegacySchedule(id, lastCareDate, intervalDays),
       );

  final String id;
  final String name;
  final String category;
  // `location` is retained as a lossless compatibility fallback for v1/v2
  // archives. New UI resolves the actual room through `spaceId` and keeps the
  // optional within-room description in `locationDetail`.
  final String location;
  final String? spaceId;
  final String locationDetail;
  final String brand;
  final String model;
  final String notes;
  final List<String> photos;
  final List<MaintenancePlan> plans;
  final List<MaintenanceRecord> records;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final DateTime? warrantyDate;
  final DateTime? _legacyLastCareDate;
  final int? _legacyIntervalDays;
  final bool _createPlanFromLegacySchedule;
  final bool isSample;

  String get legacyPlanId => 'legacy-plan-$id';

  MaintenancePlan? get _primaryPlan {
    for (final plan in plans) {
      if (plan.id == legacyPlanId) return plan;
    }
    for (final plan in plans) {
      if (!plan.archived) return plan;
    }
    return null;
  }

  DateTime? get lastCareDate =>
      _primaryPlan?.lastCompletedAt ?? _legacyLastCareDate;

  int? get intervalDays {
    final plan = _primaryPlan;
    if (plan == null) return _legacyIntervalDays;
    return plan.enabled && !plan.archived ? plan.intervalDays : null;
  }

  DateTime? get nextCareDate => _earliestDate(
    plans
        .where((plan) => plan.enabled && !plan.archived)
        .map((plan) => plan.dueDate),
  );

  MaintenancePlan? get nextMaintenancePlan {
    MaintenancePlan? result;
    for (final plan in plans.where(
      (plan) => plan.enabled && !plan.archived && plan.dueDate != null,
    )) {
      if (result == null || plan.dueDate!.isBefore(result.dueDate!)) {
        result = plan;
      }
    }
    return result;
  }

  DateTime? get nextReminderDate => _earliestDate(
    plans
        .where((plan) => plan.enabled && !plan.archived)
        .map(maintenanceReminderDateForPlan),
  );

  String get status {
    final plan = nextMaintenancePlan;
    return plan == null ? '未设置' : MaintenancePlanStatus.evaluate(plan).label;
  }

  bool get isOverdue {
    final plan = nextMaintenancePlan;
    return plan != null &&
        MaintenancePlanStatus.evaluate(plan).dueState ==
            MaintenanceTaskState.overdue;
  }

  bool get isSoon {
    final plan = nextMaintenancePlan;
    if (plan == null) return false;
    final state = MaintenancePlanStatus.evaluate(plan).dueState;
    return state == MaintenanceTaskState.dueSoon ||
        state == MaintenanceTaskState.dueToday;
  }

  CareItem removeOrArchivePlan(String planId) {
    final index = plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) return this;
    final nextPlans = [...plans];
    if (records.any((record) => record.planId == planId)) {
      nextPlans[index] = nextPlans[index].copyWith(
        enabled: false,
        archived: true,
        clearDeferredUntil: true,
      );
    } else {
      nextPlans.removeAt(index);
    }
    return copyWith(plans: nextPlans);
  }

  CareItem copyWith({
    String? name,
    String? category,
    String? location,
    String? spaceId,
    String? locationDetail,
    String? brand,
    String? model,
    String? notes,
    List<String>? photos,
    List<MaintenancePlan>? plans,
    List<MaintenanceRecord>? records,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    DateTime? warrantyDate,
    DateTime? lastCareDate,
    int? intervalDays,
    bool clearPurchaseDate = false,
    bool clearPurchasePrice = false,
    bool clearCurrentValue = false,
    bool clearWarrantyDate = false,
    bool clearLastCareDate = false,
    bool clearInterval = false,
    bool clearSpaceId = false,
    bool? isSample,
  }) {
    final scheduleChanged =
        lastCareDate != null ||
        intervalDays != null ||
        clearLastCareDate ||
        clearInterval;
    final nextLastCareDate = clearLastCareDate
        ? null
        : lastCareDate ?? this.lastCareDate;
    final nextIntervalDays = clearInterval
        ? null
        : intervalDays ?? this.intervalDays;
    final nextPlans =
        plans ??
        (scheduleChanged
            ? _updatedLegacyPlan(nextLastCareDate, nextIntervalDays)
            : this.plans);

    return CareItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      spaceId: clearSpaceId ? null : spaceId ?? this.spaceId,
      locationDetail: locationDetail ?? this.locationDetail,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      plans: nextPlans,
      records: records ?? this.records,
      purchaseDate: clearPurchaseDate
          ? null
          : purchaseDate ?? this.purchaseDate,
      purchasePrice: clearPurchasePrice
          ? null
          : purchasePrice ?? this.purchasePrice,
      currentValue: clearCurrentValue
          ? null
          : currentValue ?? this.currentValue,
      warrantyDate: clearWarrantyDate
          ? null
          : warrantyDate ?? this.warrantyDate,
      lastCareDate: nextLastCareDate,
      intervalDays: nextIntervalDays,
      isSample: isSample ?? this.isSample,
      createPlanFromLegacySchedule: plans == null
          ? _createPlanFromLegacySchedule
          : false,
    );
  }

  List<MaintenancePlan> _updatedLegacyPlan(
    DateTime? lastCompletedAt,
    int? intervalDays,
  ) {
    final result = [...plans];
    final index = result.indexWhere((plan) => plan.id == legacyPlanId);
    if (intervalDays == null || intervalDays <= 0) {
      if (index != -1) {
        result[index] = result[index].copyWith(
          enabled: false,
          lastCompletedAt: lastCompletedAt,
          clearLastCompletedAt: lastCompletedAt == null,
          clearDueDate: true,
          clearDeferredUntil: true,
        );
      }
      return result;
    }

    final dueDate = lastCompletedAt == null
        ? null
        : addMaintenanceDays(lastCompletedAt, intervalDays);
    final updated = MaintenancePlan(
      id: legacyPlanId,
      title: '定期保养',
      intervalDays: intervalDays,
      lastCompletedAt: lastCompletedAt,
      dueDate: dueDate,
    );
    if (index == -1) {
      result.insert(0, updated);
    } else {
      result[index] = result[index].copyWith(
        intervalDays: intervalDays,
        enabled: true,
        lastCompletedAt: lastCompletedAt,
        clearLastCompletedAt: lastCompletedAt == null,
        dueDate: dueDate,
        clearDueDate: dueDate == null,
        clearDeferredUntil: true,
      );
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'location': location,
    'spaceId': spaceId,
    'locationDetail': locationDetail,
    'brand': brand,
    'model': model,
    'notes': notes,
    'photos': photos,
    'plans': plans.map((plan) => plan.toJson()).toList(),
    'records': records.map((record) => record.toJson()).toList(),
    'purchaseDate': purchaseDate?.toIso8601String(),
    'purchasePrice': purchasePrice,
    'currentValue': currentValue,
    'warrantyDate': warrantyDate?.toIso8601String(),
    // Transitional fields preserve an incomplete legacy schedule that did not
    // have enough information to become a plan.
    'lastCareDate': _legacyLastCareDate?.toIso8601String(),
    'intervalDays': _legacyIntervalDays,
    'isSample': isSample,
  };

  factory CareItem.fromJson(Map<String, dynamic> json) => CareItem(
    id: _requiredString(json, 'id'),
    name: _requiredString(json, 'name'),
    category: json['category'] as String? ?? '其他',
    location: json['location'] as String? ?? '',
    spaceId: json['spaceId'] as String?,
    locationDetail: json['locationDetail'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    model: json['model'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    photos: List<String>.from(json['photos'] as List? ?? const []),
    plans: (json['plans'] as List? ?? const [])
        .map(
          (value) =>
              MaintenancePlan.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false),
    records: (json['records'] as List? ?? const [])
        .map(
          (value) => MaintenanceRecord.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false),
    purchaseDate: _parseDate(json['purchaseDate']),
    purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
    currentValue: (json['currentValue'] as num?)?.toDouble(),
    warrantyDate: _parseDate(json['warrantyDate']),
    lastCareDate: _parseDate(json['lastCareDate']),
    intervalDays: json['intervalDays'] as int?,
    isSample: json['isSample'] as bool? ?? false,
    createPlanFromLegacySchedule: false,
  );

  factory CareItem.fromLegacyJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    final lastCareDate = _parseDate(json['lastCareDate']);
    final intervalDays = json['intervalDays'] as int?;
    final defaultPlanId = intervalDays != null && intervalDays > 0
        ? 'legacy-plan-$id'
        : null;
    final rawRecords = json['records'] as List? ?? const [];
    return CareItem(
      id: id,
      name: _requiredString(json, 'name'),
      category: json['category'] as String? ?? '其他',
      location: json['location'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      photos: List<String>.from(json['photos'] as List? ?? const []),
      records: List.generate(
        rawRecords.length,
        (index) => MaintenanceRecord.fromLegacyJson(
          Map<String, dynamic>.from(rawRecords[index] as Map),
          itemId: id,
          index: index,
          defaultPlanId: defaultPlanId,
        ),
        growable: false,
      ),
      purchaseDate: _parseDate(json['purchaseDate']),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      currentValue: (json['currentValue'] as num?)?.toDouble(),
      warrantyDate: _parseDate(json['warrantyDate']),
      lastCareDate: lastCareDate,
      intervalDays: intervalDays,
      isSample: json['isSample'] as bool? ?? false,
    );
  }
}

List<MaintenancePlan> _planFromLegacySchedule(
  String itemId,
  DateTime? lastCareDate,
  int? intervalDays,
) {
  if (intervalDays == null || intervalDays <= 0) return const [];
  return [
    MaintenancePlan(
      id: 'legacy-plan-$itemId',
      title: '定期保养',
      intervalDays: intervalDays,
      lastCompletedAt: lastCareDate,
      dueDate: lastCareDate == null
          ? null
          : addMaintenanceDays(lastCareDate, intervalDays),
    ),
  ];
}

DateTime? _earliestDate(Iterable<DateTime?> dates) {
  DateTime? earliest;
  for (final date in dates) {
    if (date != null && (earliest == null || date.isBefore(earliest))) {
      earliest = date;
    }
  }
  return earliest;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid date');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key');
  }
  return value;
}
