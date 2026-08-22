import 'maintenance_calendar.dart';
import 'maintenance_plan.dart';

class MaintenanceTemplate {
  const MaintenanceTemplate({
    required this.id,
    required this.scene,
    required this.title,
    required this.intervalDays,
    required this.steps,
    this.stepDescriptions = const [],
  });

  final String id;
  final String scene;
  final String title;
  final int intervalDays;
  final List<String> steps;
  final List<String> stepDescriptions;

  MaintenancePlan createPlan({
    required String planId,
    DateTime? referenceDate,
  }) {
    final start = _dateOnly(referenceDate ?? DateTime.now());
    return MaintenancePlan(
      id: planId,
      title: title,
      intervalDays: intervalDays,
      reminderLeadDays: 3,
      dueDate: addMaintenanceDays(start, intervalDays),
      checklist: List.generate(
        steps.length,
        (index) => MaintenanceStep(
          id: '$planId-step-$index',
          title: steps[index],
          sortOrder: index,
          description: index < stepDescriptions.length
              ? stepDescriptions[index]
              : '',
        ),
        growable: false,
      ),
    );
  }
}

const maintenanceTemplates = <MaintenanceTemplate>[
  MaintenanceTemplate(
    id: 'air-conditioner-filter',
    scene: '空调',
    title: '清洗滤网',
    intervalDays: 90,
    steps: ['断电', '拆卸', '清洗', '晾干', '复装'],
  ),
  MaintenanceTemplate(
    id: 'water-purifier-filter',
    scene: '净水器',
    title: '更换滤芯',
    intervalDays: 180,
    steps: ['核对型号', '关闭水源', '更换', '冲洗'],
    stepDescriptions: [
      '请确认净水器型号与适配滤芯',
      '关闭进水阀，确保停止进水',
      '拆卸旧滤芯，安装新滤芯',
      '打开水源，冲洗滤芯至出水清澈',
    ],
  ),
  MaintenanceTemplate(
    id: 'washer-drum',
    scene: '洗衣机',
    title: '内筒清洁',
    intervalDays: 30,
    steps: ['清空', '加入清洁剂', '运行', '擦干'],
  ),
  MaintenanceTemplate(
    id: 'fridge-condenser',
    scene: '冰箱',
    title: '清洁冷凝区域',
    intervalDays: 180,
    steps: ['断电', '清灰', '检查散热', '复位'],
  ),
  MaintenanceTemplate(
    id: 'smoke-alarm-battery',
    scene: '烟雾报警器',
    title: '测试电池',
    intervalDays: 30,
    steps: ['测试报警', '检查电量', '记录结果'],
  ),
  MaintenanceTemplate(
    id: 'custom',
    scene: '自定义',
    title: '自定义任务',
    intervalDays: 30,
    steps: [],
  ),
];

MaintenancePlan enrichMaintenanceTemplateStepDescriptions(
  MaintenancePlan plan,
) {
  MaintenanceTemplate? matchedTemplate;
  for (final template in maintenanceTemplates) {
    if (template.title != plan.title ||
        template.steps.length != plan.checklist.length ||
        template.stepDescriptions.isEmpty) {
      continue;
    }
    final sortedSteps = [...plan.checklist]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final titlesMatch = List.generate(
      sortedSteps.length,
      (index) => sortedSteps[index].title == template.steps[index],
      growable: false,
    ).every((matches) => matches);
    if (titlesMatch) {
      matchedTemplate = template;
      break;
    }
  }
  if (matchedTemplate == null) return plan;

  var changed = false;
  final checklist = plan.checklist
      .map((step) {
        if (step.description.isNotEmpty) return step;
        final templateIndex = matchedTemplate!.steps.indexOf(step.title);
        if (templateIndex == -1 ||
            templateIndex >= matchedTemplate.stepDescriptions.length) {
          return step;
        }
        final description = matchedTemplate.stepDescriptions[templateIndex];
        if (description.isEmpty) return step;
        changed = true;
        return MaintenanceStep(
          id: step.id,
          title: step.title,
          sortOrder: step.sortOrder,
          description: description,
        );
      })
      .toList(growable: false);

  return changed ? plan.copyWith(checklist: checklist) : plan;
}

class MaintenancePlanValidator {
  static const minIntervalDays = 1;
  static const maxIntervalDays = 3650;
  static const maxReminderLeadDays = 365;
  static final DateTime minDate = DateTime(2000);
  static final DateTime maxDate = DateTime(2100, 12, 31);

  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) return '请填写计划名称';
    if (value.trim().length > 40) return '计划名称不能超过 40 个字符';
    return null;
  }

  static String? interval(String? value) {
    final days = int.tryParse(value?.trim() ?? '');
    if (days == null) return '请输入整数周期';
    if (days < minIntervalDays || days > maxIntervalDays) {
      return '周期需为 $minIntervalDays–$maxIntervalDays 天';
    }
    return null;
  }

  static String? reminderLead(String? value, {required int? intervalDays}) {
    final days = int.tryParse(value?.trim() ?? '');
    if (days == null) return '请输入整数天数';
    if (days < 0 || days > maxReminderLeadDays) {
      return '提前天数需为 0–$maxReminderLeadDays 天';
    }
    if (intervalDays != null && days > intervalDays) {
      return '提前天数不能超过保养周期';
    }
    return null;
  }

  static String? dates(DateTime? lastCompletedAt, DateTime? dueDate) {
    if (lastCompletedAt == null && dueDate == null) {
      return '请选择上次完成日或首次到期日';
    }
    for (final date in [lastCompletedAt, dueDate]) {
      if (date != null && (date.isBefore(minDate) || date.isAfter(maxDate))) {
        return '日期需在 2000–2100 年之间';
      }
    }
    if (lastCompletedAt != null &&
        dueDate != null &&
        dueDate.isBefore(lastCompletedAt)) {
      return '到期日不能早于上次完成日';
    }
    return null;
  }

  static DateTime? previewDueDate({
    required DateTime? lastCompletedAt,
    required DateTime? dueDate,
    required int? intervalDays,
  }) {
    if (dueDate != null) return _dateOnly(dueDate);
    if (lastCompletedAt == null || intervalDays == null) return null;
    if (intervalDays < minIntervalDays || intervalDays > maxIntervalDays) {
      return null;
    }
    return addMaintenanceDays(lastCompletedAt, intervalDays);
  }
}

DateTime _dateOnly(DateTime date) => maintenanceDateOnly(date);
