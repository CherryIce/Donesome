import '../models/maintenance_status.dart';
import '../models/maintenance_calendar.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_template.dart';
import 'app_localizations.dart';

extension HearthioMaintenanceLocalizations on AppLocalizations {
  String maintenanceStateLabel(MaintenanceTaskState state) => switch (state) {
    MaintenanceTaskState.planned => maintenanceStatePlanned,
    MaintenanceTaskState.dueSoon => maintenanceStateDueSoon,
    MaintenanceTaskState.dueToday => maintenanceStateDueToday,
    MaintenanceTaskState.overdue => maintenanceStateOverdue,
    MaintenanceTaskState.deferred => maintenanceStateDeferred,
    MaintenanceTaskState.completed => maintenanceStateCompleted,
    MaintenanceTaskState.disabled => maintenanceStateDisabled,
  };

  String maintenanceTimingLabel(MaintenancePlanStatus status) {
    final days = status.daysUntilDue;
    if (days == null) return maintenanceDueDateUnset;
    if (days < 0) return maintenanceOverdueDays(-days);
    if (days == 0) return maintenanceStateDueToday;
    return maintenanceDueInDays(days);
  }

  String formatDate(DateTime value) =>
      dateYmd(value.year, value.month, value.day);

  String maintenancePlanTitleLabel(String title) => switch (title) {
    '保养' => maintenanceGeneric,
    '清洗滤网' => templateTitleCleanFilter,
    '更换滤芯' => templateTitleReplaceFilter,
    '内筒清洁' => templateTitleCleanDrum,
    '清洁冷凝区域' => templateTitleCleanCondenser,
    '测试电池' => templateTitleTestBattery,
    '自定义任务' => templateTitleCustomTask,
    _ => title,
  };

  String maintenanceStepTitleLabel(String title) => switch (title) {
    '原步骤内容不可用' => historicalStepUnavailable,
    '断电' => stepPowerOff,
    '拆卸' => stepDisassemble,
    '清洗' => stepClean,
    '晾干' => stepDry,
    '复装' => stepReassemble,
    '核对型号' => stepVerifyModel,
    '关闭水源' => stepShutOffWater,
    '更换' => stepReplace,
    '冲洗' => stepFlush,
    '清空' => stepEmpty,
    '加入清洁剂' => stepAddCleaner,
    '运行' => stepRun,
    '擦干' => stepWipeDry,
    '清灰' => stepRemoveDust,
    '检查散热' => stepCheckVentilation,
    '复位' => stepReset,
    '测试报警' => stepTestAlarm,
    '检查电量' => stepCheckBattery,
    '记录结果' => stepRecordResult,
    _ => title,
  };

  String maintenanceStepDescriptionLabel(String description) =>
      switch (description) {
        '请确认净水器型号与适配滤芯' => stepDescriptionVerifyFilter,
        '关闭进水阀，确保停止进水' => stepDescriptionShutOffWater,
        '拆卸旧滤芯，安装新滤芯' => stepDescriptionReplaceFilter,
        '打开水源，冲洗滤芯至出水清澈' => stepDescriptionFlushFilter,
        _ => description,
      };
}

class LocalizedMaintenanceTemplate {
  const LocalizedMaintenanceTemplate({
    required this.source,
    required this.scene,
    required this.title,
    required this.steps,
    this.stepDescriptions = const [],
  });

  final MaintenanceTemplate source;
  final String scene;
  final String title;
  final List<String> steps;
  final List<String> stepDescriptions;

  MaintenancePlan createPlan({
    required String planId,
    DateTime? referenceDate,
  }) {
    final start = maintenanceDateOnly(referenceDate ?? DateTime.now());
    return MaintenancePlan(
      id: planId,
      title: title,
      intervalDays: source.intervalDays,
      reminderLeadDays: 3,
      dueDate: addMaintenanceDays(start, source.intervalDays),
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

extension HearthioMaintenanceTemplateLocalizations on AppLocalizations {
  LocalizedMaintenanceTemplate localizedTemplate(MaintenanceTemplate source) {
    final values = switch (source.id) {
      'air-conditioner-filter' => (
        scene: templateSceneAirConditioner,
        title: templateTitleCleanFilter,
        steps: [
          stepPowerOff,
          stepDisassemble,
          stepClean,
          stepDry,
          stepReassemble,
        ],
        descriptions: <String>[],
      ),
      'water-purifier-filter' => (
        scene: templateSceneWaterPurifier,
        title: templateTitleReplaceFilter,
        steps: [stepVerifyModel, stepShutOffWater, stepReplace, stepFlush],
        descriptions: [
          stepDescriptionVerifyFilter,
          stepDescriptionShutOffWater,
          stepDescriptionReplaceFilter,
          stepDescriptionFlushFilter,
        ],
      ),
      'washer-drum' => (
        scene: templateSceneWasher,
        title: templateTitleCleanDrum,
        steps: [stepEmpty, stepAddCleaner, stepRun, stepWipeDry],
        descriptions: <String>[],
      ),
      'fridge-condenser' => (
        scene: templateSceneFridge,
        title: templateTitleCleanCondenser,
        steps: [stepPowerOff, stepRemoveDust, stepCheckVentilation, stepReset],
        descriptions: <String>[],
      ),
      'smoke-alarm-battery' => (
        scene: templateSceneSmokeAlarm,
        title: templateTitleTestBattery,
        steps: [stepTestAlarm, stepCheckBattery, stepRecordResult],
        descriptions: <String>[],
      ),
      _ => (
        scene: templateSceneCustom,
        title: templateTitleCustomTask,
        steps: <String>[],
        descriptions: <String>[],
      ),
    };
    return LocalizedMaintenanceTemplate(
      source: source,
      scene: values.scene,
      title: values.title,
      steps: values.steps,
      stepDescriptions: values.descriptions,
    );
  }
}
