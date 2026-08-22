// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '家务志 · Hearthio';

  @override
  String get languageTitle => '语言';

  @override
  String get systemLanguage => '跟随系统';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get generalSection => '通用';

  @override
  String get languageSettingSubtitle => '可选择跟随系统、简体中文或 English';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDone => '完成';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonAdd => '添加';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRefresh => '刷新';

  @override
  String get onboardingArchiveTitle => '先给家里的物品建档';

  @override
  String get onboardingArchiveBody => '添加名称、位置和保养周期，随时找到每一件物品。';

  @override
  String get onboardingEvidenceTitle => '拍下凭证，留住细节';

  @override
  String get onboardingEvidenceBody => '拍摄或选择说明书、保修卡和维修照片，都只保存在本机。';

  @override
  String get onboardingReminderTitle => '日历提醒，按时照料';

  @override
  String get onboardingReminderBody => '在保养日程中查看待办，到期前可收到本机提醒。';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingStart => '开始整理';

  @override
  String get homeTab => '首页';

  @override
  String get itemsTab => '物品';

  @override
  String get scheduleTab => '日程';

  @override
  String get reportTab => '报告';

  @override
  String get settingsTab => '设置';

  @override
  String get addItem => '添加物品';

  @override
  String get selectDate => '选择日期';

  @override
  String get today => '今天';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get weekdaySunday => '日';

  @override
  String get weekdayMonday => '一';

  @override
  String get weekdayTuesday => '二';

  @override
  String get weekdayWednesday => '三';

  @override
  String get weekdayThursday => '四';

  @override
  String get weekdayFriday => '五';

  @override
  String get weekdaySaturday => '六';

  @override
  String calendarMonthYear(int year, int month) {
    return '$year年$month月';
  }

  @override
  String dateYmd(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String dateMonthDay(int month, int day) {
    return '$month月$day日';
  }

  @override
  String dateTodaySemantic(String date) {
    return '$date，今天';
  }

  @override
  String get permissionCamera => '相机';

  @override
  String get permissionPhotos => '照片';

  @override
  String get permissionNotifications => '通知';

  @override
  String permissionUnavailableTitle(String permission) {
    return '$permission权限不可用';
  }

  @override
  String get permissionLater => '稍后处理';

  @override
  String get permissionOpenSettings => '前往系统设置';

  @override
  String permissionOpenSettingsManually(String permission) {
    return '请手动前往系统设置，为“家务志”开启$permission权限。';
  }

  @override
  String permissionStatusUnavailable(String permission) {
    return '当前无法读取$permission权限状态。请稍后重试；如果你曾关闭权限，也可以前往系统设置检查。';
  }

  @override
  String permissionRequestIncomplete(String permission) {
    return '系统未能完成$permission授权。请重试；如果仍不可用，请前往系统设置检查。';
  }

  @override
  String permissionDeniedGuidance(String permission) {
    return '$permission权限尚未开启，因此暂时无法使用此功能。请前往系统设置允许“家务志”访问$permission后再试。';
  }

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get privacyPreparingTitle => '隐私政策页面正在准备中';

  @override
  String get privacyPreparingMessage => '正式 HTTPS 地址接入后，这里将直接展示完整隐私政策。';

  @override
  String get privacyLoadFailedTitle => '暂时无法加载隐私政策';

  @override
  String privacyLoadFailedMessage(String error) {
    return '请检查网络后重试。\n$error';
  }

  @override
  String get privacyReload => '重新加载';

  @override
  String get privacyLocalFirstSummary =>
      '家务志无需注册。物品信息、照片、维护记录和计划默认保存在本机；只有在你主动导出、备份或分享时，相关文件才会离开 App 沙盒。';

  @override
  String get maintenanceStatePlanned => '已计划';

  @override
  String get maintenanceStateDueSoon => '即将到期';

  @override
  String get maintenanceStateDueToday => '今日到期';

  @override
  String get maintenanceStateOverdue => '已逾期';

  @override
  String get maintenanceStateDeferred => '已稍后提醒';

  @override
  String get maintenanceStateCompleted => '已完成';

  @override
  String get maintenanceStateDisabled => '已停用';

  @override
  String get maintenanceDueDateUnset => '尚未设置到期日';

  @override
  String maintenanceOverdueDays(int days) {
    return '已逾期 $days 天';
  }

  @override
  String maintenanceDueInDays(int days) {
    return '还有 $days 天';
  }

  @override
  String originalDueWithTiming(String date, String timing) {
    return '原到期日 $date · $timing';
  }

  @override
  String deferredReminderStatus(String date, String status) {
    return '稍后提醒 $date · 原状态 $status';
  }

  @override
  String get deferReminder => '稍后提醒';

  @override
  String get editDeferredReminder => '修改稍后提醒';

  @override
  String get startMaintenance => '开始保养';

  @override
  String get maintenancePlansTitle => '保养计划';

  @override
  String get addPlan => '添加计划';

  @override
  String get planTemplateDisclaimer => '模板中的周期仅供参考，保存前可修改全部字段；请优先遵循设备厂商说明书。';

  @override
  String archivedPlansCount(int count) {
    return '已归档计划（$count）';
  }

  @override
  String get archivedPlansSubtitle => '关联历史已保留，不再发送提醒';

  @override
  String intervalEveryDays(int days) {
    return '每 $days 天';
  }

  @override
  String get archivePlanTitle => '归档这个计划？';

  @override
  String get deletePlanTitle => '删除这个计划？';

  @override
  String archivePlanMessage(String title) {
    return '“$title”已有维护记录。归档后会停止提醒，但历史记录仍会保留。';
  }

  @override
  String deletePlanMessage(String title) {
    return '“$title”尚无维护记录，删除后无法恢复。';
  }

  @override
  String get confirmArchive => '确认归档';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get noMaintenancePlans => '还没有保养计划';

  @override
  String get noMaintenancePlansSubtitle => '可从模板开始，也可以创建完全自定义的任务。';

  @override
  String get planEnabled => '已启用';

  @override
  String get planDisabled => '已停用';

  @override
  String planScheduleSummary(String state, int interval, int lead) {
    return '$state · 每 $interval 天 · 提前 $lead 天';
  }

  @override
  String planNextSummary(String date, int count) {
    return '下次：$date · $count 个步骤';
  }

  @override
  String editPlanTooltip(String title) {
    return '编辑 $title';
  }

  @override
  String removePlanTooltip(String title) {
    return '删除或归档 $title';
  }

  @override
  String get selectMaintenanceTemplate => '选择保养模板';

  @override
  String get templatePickerDisclaimer => '模板只是可编辑起点，并非强制安全周期；请以厂商说明书为准。';

  @override
  String get customTemplateDescription => '名称、周期和步骤均由你填写';

  @override
  String templateDefaultSummary(int days, String steps) {
    return '默认 $days 天 · $steps';
  }

  @override
  String get editMaintenancePlan => '编辑保养计划';

  @override
  String get savePlan => '保存计划';

  @override
  String get planNameLabel => '计划名称 *';

  @override
  String get enablePlan => '启用计划';

  @override
  String get disablePlanSubtitle => '停用后保留计划和历史，但不再发送提醒';

  @override
  String get intervalDaysLabel => '周期（天）*';

  @override
  String get reminderLeadDaysLabel => '提前提醒（天）*';

  @override
  String get lastCompletedOptional => '上次完成日（可选）';

  @override
  String get firstOrNextDueDate => '首次 / 下次到期日';

  @override
  String get nextDatePreview => '下一次日期预览';

  @override
  String get completeScheduleForPreview => '补全周期和日期后显示';

  @override
  String nextDateReminderPreview(String date, String days) {
    return '$date · 提前 $days 天提醒';
  }

  @override
  String get executionSteps => '执行步骤';

  @override
  String get addStep => '添加步骤';

  @override
  String get optionalStepsHint => '步骤可选；需要时可逐条添加，并在保存前修改。';

  @override
  String get stepRequired => '请填写步骤内容';

  @override
  String get stepContentLabel => '步骤内容';

  @override
  String deleteStepTooltip(int number) {
    return '删除步骤 $number';
  }

  @override
  String get notSet => '未设置';

  @override
  String get validationPlanNameRequired => '请填写计划名称';

  @override
  String get validationPlanNameTooLong => '计划名称不能超过 40 个字符';

  @override
  String get validationIntervalInteger => '请输入整数周期';

  @override
  String validationIntervalRange(int min, int max) {
    return '周期需为 $min–$max 天';
  }

  @override
  String get validationDaysInteger => '请输入整数天数';

  @override
  String validationReminderRange(int max) {
    return '提前天数需为 0–$max 天';
  }

  @override
  String get validationReminderAfterInterval => '提前天数不能超过保养周期';

  @override
  String get validationPlanDateRequired => '请选择上次完成日或首次到期日';

  @override
  String get validationPlanDateRange => '日期需在 2000–2100 年之间';

  @override
  String get validationDueBeforeCompletion => '到期日不能早于上次完成日';

  @override
  String get templateSceneAirConditioner => '空调';

  @override
  String get templateTitleCleanFilter => '清洗滤网';

  @override
  String get templateSceneWaterPurifier => '净水器';

  @override
  String get templateTitleReplaceFilter => '更换滤芯';

  @override
  String get templateSceneWasher => '洗衣机';

  @override
  String get templateTitleCleanDrum => '内筒清洁';

  @override
  String get templateSceneFridge => '冰箱';

  @override
  String get templateTitleCleanCondenser => '清洁冷凝区域';

  @override
  String get templateSceneSmokeAlarm => '烟雾报警器';

  @override
  String get templateTitleTestBattery => '测试电池';

  @override
  String get templateSceneCustom => '自定义';

  @override
  String get templateTitleCustomTask => '自定义任务';

  @override
  String get stepPowerOff => '断电';

  @override
  String get stepDisassemble => '拆卸';

  @override
  String get stepClean => '清洗';

  @override
  String get stepDry => '晾干';

  @override
  String get stepReassemble => '复装';

  @override
  String get stepVerifyModel => '核对型号';

  @override
  String get stepShutOffWater => '关闭水源';

  @override
  String get stepReplace => '更换';

  @override
  String get stepFlush => '冲洗';

  @override
  String get stepEmpty => '清空';

  @override
  String get stepAddCleaner => '加入清洁剂';

  @override
  String get stepRun => '运行';

  @override
  String get stepWipeDry => '擦干';

  @override
  String get stepRemoveDust => '清灰';

  @override
  String get stepCheckVentilation => '检查散热';

  @override
  String get stepReset => '复位';

  @override
  String get stepTestAlarm => '测试报警';

  @override
  String get stepCheckBattery => '检查电量';

  @override
  String get stepRecordResult => '记录结果';

  @override
  String get stepDescriptionVerifyFilter => '请确认净水器型号与适配滤芯';

  @override
  String get stepDescriptionShutOffWater => '关闭进水阀，确保停止进水';

  @override
  String get stepDescriptionReplaceFilter => '拆卸旧滤芯，安装新滤芯';

  @override
  String get stepDescriptionFlushFilter => '打开水源，冲洗滤芯至出水清澈';

  @override
  String get editMaintenanceRecord => '编辑维护记录';

  @override
  String get linkedPlan => '所属计划';

  @override
  String get originalPlanUnavailableSuffix => '（原计划不可用）';

  @override
  String get recordPlanLinkImmutable => '记录与原计划的关联不会在编辑时改变。';

  @override
  String get recordCostLabel => '本次费用（元）';

  @override
  String get optionalZeroCostHint => '可留空，按 0 元记录';

  @override
  String get materialNameLabel => '耗材名称 / 型号';

  @override
  String get notesLabel => '备注';

  @override
  String get recordHasNoSteps => '这条记录没有步骤数据。';

  @override
  String historicalStepIdsOnly(int count) {
    return '已保留 $count 个历史步骤标识；原步骤内容不可用。';
  }

  @override
  String get beforePhotos => '保养前照片';

  @override
  String get afterPhotos => '保养后照片';

  @override
  String get saving => '正在保存…';

  @override
  String get saveRecord => '保存记录';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseFromPhotos => '从相册选择';

  @override
  String get cameraOpenFailed => '无法打开相机，请检查相机权限后重试。';

  @override
  String get photoReadFailed => '无法读取照片，请检查照片权限后重试。';

  @override
  String get maintenanceRecordSaveFailed => '维护记录未能保存，请重试。';

  @override
  String get actualCompletionDate => '实际完成日期';

  @override
  String get noPhotosAdded => '未添加照片';

  @override
  String get removePhoto => '移除照片';

  @override
  String get validationNonNegativeAmount => '请输入大于或等于 0 的金额';

  @override
  String get executionNoPresetSteps => '此计划没有预设步骤，可直接记录本次结果。';

  @override
  String get optionalRecordSection => '本次记录（可选）';

  @override
  String get dateLabel => '日期';

  @override
  String get costLabel => '费用';

  @override
  String get optional => '可留空';

  @override
  String get materialLabel => '耗材';

  @override
  String get modelOrName => '型号/名称';

  @override
  String get completedField => '已填写';

  @override
  String get recordCostTitle => '记录本次费用';

  @override
  String get recordMaterialTitle => '记录本次耗材';

  @override
  String get materialExample => '例如：PP 棉滤芯 A1';

  @override
  String get addNotesTitle => '添加备注';

  @override
  String get notesHelper => '记录异常、观察结果或下次注意事项';

  @override
  String get beforePhotoCaptureTitle => '保养前留照';

  @override
  String get afterPhotoCaptureTitle => '保养后留照';

  @override
  String get beforePhotosLocked => '执行已经开始，保养前照片已锁定。';

  @override
  String get afterPhotosTemporarilyLocked => '步骤重新打开，完成后照片暂时不可修改。';

  @override
  String get maintenanceCompletionSaveFailed => '本次保养保存失败，数据未更新，请重试。';

  @override
  String get maintenanceCompletedTitle => '保养完成';

  @override
  String get maintenanceArchived => '本次保养已归档';

  @override
  String get completionTime => '完成时间';

  @override
  String get thisCost => '本次费用';

  @override
  String get nextPlan => '下一次计划';

  @override
  String get reminder => '提醒';

  @override
  String reminderDaysEarly(int days) {
    return '提前 $days 天';
  }

  @override
  String get completionLifecycleHint => '继续查看这件物品的生命周期，可核对本次记录、累计费用和下一项任务。';

  @override
  String get notificationRescheduleFailed =>
      '记录和下一次日期已保存，但通知未能重新安排。可在“设置”中检查通知状态后重试。';

  @override
  String get viewLifecycle => '查看生命周期';

  @override
  String originalPlanDate(String date) {
    return '原计划日期 $date';
  }

  @override
  String photosRecordedCount(int count) {
    return '已记录 $count 张';
  }

  @override
  String get noPhotosThisTime => '本次未记录';

  @override
  String get beforePhotoPrompt => '记录当前状态，便于完成后对比';

  @override
  String get beforePhotoOptional => '保养前留照（可选）';

  @override
  String beforePhotoSemantic(String status, String locked) {
    return '保养前留照，可选，$status$locked';
  }

  @override
  String get beforePhotoLockedSemanticSuffix => '，执行已开始，前照已锁定';

  @override
  String get afterPhotoReadyHint => '步骤已完成，记录最终状态以便对比';

  @override
  String get afterPhotoReopenedHint => '步骤重新打开，完成后可继续管理照片';

  @override
  String get afterPhotoWaitingHint => '完成全部步骤后可添加保养后照片';

  @override
  String get afterPhotoOptional => '保养后留照（可选）';

  @override
  String afterPhotoSemantic(String status) {
    return '保养后留照，可选，$status';
  }

  @override
  String get beforeLabel => '保养前';

  @override
  String get afterLabel => '保养后';

  @override
  String get notRecorded => '未记录';

  @override
  String get tapToAdd => '点击添加';

  @override
  String get waitingForCompletion => '等待完成';

  @override
  String photoCount(int count) {
    return '$count 张';
  }

  @override
  String stepSemantic(
    int number,
    String title,
    String description,
    String state,
  ) {
    return '步骤 $number：$title$description$state';
  }

  @override
  String stepDescriptionSemantic(String description) {
    return '，$description';
  }

  @override
  String get currentStepSemantic => '，当前步骤';

  @override
  String get completedStepSemantic => '，已完成';

  @override
  String get completeMaintenance => '完成本次保养';

  @override
  String get validationFiniteNonNegativeAmount => '请输入大于或等于 0 的有限金额';

  @override
  String get lifecycleOverviewTitle => '生命周期概览';

  @override
  String get lifecycleUsageDuration => '使用时长';

  @override
  String get lifecyclePurchaseDateMissing => '未填写购买日期';

  @override
  String get lifecyclePurchaseDateFuture => '购买日期晚于今天';

  @override
  String lifecycleUsageDays(int count) {
    return '$count 天';
  }

  @override
  String get lifecycleMaintenanceTotal => '累计保养';

  @override
  String lifecycleCompletionCount(int count) {
    return '$count 次';
  }

  @override
  String get lifecycleActualCost => '实际费用';

  @override
  String get lifecycleCurrentOverdue => '当前逾期';

  @override
  String lifecycleOverdueCount(int count) {
    return '$count 项';
  }

  @override
  String get lifecycleNextTask => '下一项任务';

  @override
  String get lifecycleNoNextTask => '暂无已启用且设有日期的计划';

  @override
  String lifecycleNextTaskSummary(String title, String date, String timing) {
    return '$title · $date · $timing';
  }

  @override
  String get lifecycleTimelineTitle => '生命周期时间线';

  @override
  String get lifecycleTimelineSubtitle => '仅汇总你填写的购买日期和真实维护记录，按日期倒序排列。';

  @override
  String get lifecycleTimelineEmpty => '还没有生命周期事件。填写购买日期或完成一次保养后，这里会显示可追溯记录。';

  @override
  String get deleteRecordTitle => '删除这条维护记录？';

  @override
  String get deleteRecordMessageNoPlan => '删除后无法恢复。记录中的照片也会从本机移除。';

  @override
  String deleteRecordMessageWithPlan(String title) {
    return '删除后无法恢复，并会按“$title”剩余记录重新计算上次完成日和下一次日期。记录照片也会从本机移除。';
  }

  @override
  String get deleteRecordFailed => '维护记录未能删除，请重试。';

  @override
  String get purchaseStartingPoint => '购买起点';

  @override
  String get purchaseStartingPointDescription => '来自你在物品信息中填写的购买日期。';

  @override
  String get recordPlanUnlinked => '未关联计划';

  @override
  String get recordPlanUnavailable => '原计划不可用';

  @override
  String recordTitleWithPlanState(String title, String state) {
    return '$title · $state';
  }

  @override
  String get editRecordTooltip => '编辑记录';

  @override
  String get deleteRecordTooltip => '删除记录';

  @override
  String get recordExpense => '费用';

  @override
  String get recordMaterial => '耗材';

  @override
  String get recordNotes => '备注';

  @override
  String get recordStepsMissing => '步骤：未记录';

  @override
  String recordStepsProgress(int completed, int total) {
    return '步骤：已完成 $completed / $total';
  }

  @override
  String get recordPhotosMissing => '照片：未记录';

  @override
  String recordPhotoGroup(String title, int count) {
    return '$title照片 · $count 张';
  }

  @override
  String get reportPageTitle => '家庭保养报告';

  @override
  String get reportPageSubtitle => '只汇总真实计划、完成记录与实际费用';

  @override
  String get reportEmptyNotice =>
      '还没有完成记录。完成一次保养后，这里会显示真实费用与完成情况；当前计划的逾期和未来任务仍照常统计。';

  @override
  String get reportCurrentTasks => '当前任务';

  @override
  String get reportCurrentTasksSubtitle => '按本机日历日实时计算';

  @override
  String get reportCurrentYearMaintenance => '本年维护';

  @override
  String get reportTrailingYearMaintenance => '近 12 个月';

  @override
  String get reportCurrentYearCostSubtitle => '自然年内已完成记录的实际费用';

  @override
  String get reportTrailingYearCostSubtitle => '费用与完成率使用同一自然月范围';

  @override
  String get reportActualMaintenanceCost => '实际维护费用';

  @override
  String reportCostRangeDescription(String start, String end) {
    return '$start 至 $end；只相加完成记录中的实际费用。';
  }

  @override
  String reportIgnoredCostCount(int count) {
    return '$count 条异常费用未纳入汇总。';
  }

  @override
  String get reportCostBreakdown => '费用去向';

  @override
  String get reportCostBreakdownSubtitle => '切换查看维度，费用总额不重复计算';

  @override
  String get reportItemBreakdown => '物品明细';

  @override
  String get reportCategoryBreakdown => '类别汇总';

  @override
  String get reportNoItemCosts => '暂无有金额的维护记录';

  @override
  String get reportNoCategoryCosts => '暂无可汇总的类别费用';

  @override
  String get reportRecentRecords => '最近维护记录';

  @override
  String get reportRecentRecordsSubtitle => '每笔金额均可回到真实完成记录';

  @override
  String get reportGroupingSemantic => '费用去向查看方式';

  @override
  String get reportGroupByItem => '按物品';

  @override
  String get reportGroupByCategory => '按类别';

  @override
  String get reportScopeCurrentYear => '本年';

  @override
  String get reportScopeTrailingYear => '近 12 个月';

  @override
  String reportCurrentYearMethodology(String start, String end) {
    return '统计口径：本月按完成日；逾期按今天与原到期日的日历日差；未来 30 天含今天；本年费用统计 $start 至 $end。';
  }

  @override
  String reportTrailingYearMethodology(String start, String end) {
    return '统计口径：本月按完成日；逾期按今天与原到期日的日历日差；未来 30 天含今天；费用与按时率统计 $start 至 $end。';
  }

  @override
  String get reportCompletedThisMonth => '本月已完成';

  @override
  String get reportCurrentOverdue => '当前逾期';

  @override
  String get reportCumulativeOverdue => '累计逾期';

  @override
  String get reportDueNextThirtyDays => '未来 30 天待处理';

  @override
  String reportItemCount(int count) {
    return '$count 项';
  }

  @override
  String reportDayCount(int count) {
    return '$count 天';
  }

  @override
  String get reportNoEligibleOnTimeRecords =>
      '暂无可复算的按时记录。旧记录或无原计划日期的记录不会被猜测为按时。';

  @override
  String reportOnTimeExplanation(int onTime, int eligible) {
    return '按时 $onTime / 可复算 $eligible。完成日不晚于记录中的原计划到期日即为按时。';
  }

  @override
  String get reportOnTimeRate => '按时完成率';

  @override
  String reportExcludedCompletionCount(int count) {
    return '另有 $count 条记录缺少原计划日期，未纳入完成率。';
  }

  @override
  String reportRecordSubtitle(String item, String date) {
    return '$item · $date';
  }

  @override
  String get notificationPrimerTitle => '开启保养提醒？';

  @override
  String get notificationPrimerMessage =>
      '开启后，家务志会按每个计划设置的提前天数发送本地通知。\n\n不授权不会影响物品和保养计划保存，你也可以稍后在“设置”中开启。';

  @override
  String get notificationNotNow => '暂不开启';

  @override
  String get notificationEnable => '开启通知';

  @override
  String get dateNotSet => '未设置';

  @override
  String get deferTitle => '稍后提醒';

  @override
  String deferTaskDescription(String item, String plan, String date) {
    return '$item · $plan\n原到期日 $date，稍后提醒不会改变真实到期状态。';
  }

  @override
  String get tomorrow => '明天';

  @override
  String get inThreeDays => '3 天后';

  @override
  String get nextWeek => '下周';

  @override
  String get customDate => '自定义日期';

  @override
  String get deferFailed => '稍后提醒设置失败，请重试。';

  @override
  String get notificationItemUnavailable => '提醒对应的物品已删除，已返回待保养列表。';

  @override
  String get notificationPlanUnavailable => '提醒对应的保养计划已删除或停用，已返回待保养列表。';

  @override
  String get notificationMalformed => '这条保养提醒已失效，已返回待保养列表。';

  @override
  String get gotIt => '知道了';

  @override
  String get dashboardNextMaintenance => '下一项保养';

  @override
  String get dashboardHouseholdOverview => '家庭概览';

  @override
  String get dashboardTitle => '家务志';

  @override
  String dashboardDate(String date, String weekday) {
    return '$date · $weekday';
  }

  @override
  String get dashboardNoDueTasks => '没有到期任务';

  @override
  String dashboardAttentionCount(int count) {
    return '$count 项任务需要关注';
  }

  @override
  String get dashboardAllOnTrack => '家里一切按计划进行';

  @override
  String get dashboardStartWithUrgent => '先从最紧要的一项开始';

  @override
  String get dashboardToday => '今日';

  @override
  String get dashboardViewSchedule => '查看日程';

  @override
  String dashboardOriginalDueDate(String date) {
    return '原到期日 $date';
  }

  @override
  String dashboardDeferredStatus(String date, String status) {
    return '稍后提醒 $date · 原状态 $status';
  }

  @override
  String get dashboardItems => '物品';

  @override
  String get dashboardSpaces => '空间';

  @override
  String get dashboardThisYearMaintenance => '今年维护';

  @override
  String get dashboardAssets => '资产';

  @override
  String dashboardItemsSemantic(int count) {
    return '物品，$count件，查看全部物品';
  }

  @override
  String dashboardSpacesSemantic(int count) {
    return '空间，$count个，查看家庭空间';
  }

  @override
  String dashboardAnnualCostSemantic(String amount) {
    return '今年维护，$amount元，查看本年维护报告';
  }

  @override
  String dashboardAssetsSemantic(String amount) {
    return '资产，$amount元，查看资产估值';
  }

  @override
  String get emptyMaintenanceTitle => '从第一个计划开始';

  @override
  String get emptyMaintenanceSubtitle => '添加物品并设置保养周期，到期前会提醒你。';

  @override
  String get createMaintenancePlan => '创建保养计划';

  @override
  String get spacesTitle => '家庭空间';

  @override
  String get addSpace => '添加空间';

  @override
  String get spacesDescription => '按实际房间管理物品位置；房间内的具体位置仍由你补充。';

  @override
  String get spacesEmptyTitle => '还没有家庭空间';

  @override
  String get spacesEmptySubtitle => '添加客厅、卧室或厨房等实际房间，之后编辑物品时就可以直接选择。';

  @override
  String get unassignedSpace => '未设置空间';

  @override
  String get awaitingClassification => '等待归类';

  @override
  String spaceItemCount(String type, int count) {
    return '$type · $count 件物品';
  }

  @override
  String get manageSpace => '管理空间';

  @override
  String get renameSpace => '重命名空间';

  @override
  String get deleteSpace => '删除空间';

  @override
  String get spaceDeleted => '空间已删除';

  @override
  String get addItemToSpace => '在此空间添加物品';

  @override
  String get noUnassignedItems => '没有未归类的物品';

  @override
  String get spaceHasNoItems => '这个空间里还没有物品';

  @override
  String get editSpace => '编辑空间';

  @override
  String get spaceType => '空间类型';

  @override
  String get spaceActualName => '实际名称';

  @override
  String get spaceNameHint => '例如：主卧、次卧、儿童房';

  @override
  String get spaceNameHelper => '类型用于归类，实际名称用于物品位置显示。';

  @override
  String get saveChanges => '保存修改';

  @override
  String get spaceNameRequired => '请填写空间名称';

  @override
  String get spaceSaveFailed => '空间保存失败，请重试。';

  @override
  String get selectSpace => '选择所在空间';

  @override
  String get organizeLater => '稍后再整理';

  @override
  String get deleteSpaceTitle => '删除空间？';

  @override
  String deleteEmptySpaceMessage(String name) {
    return '“$name”中没有物品，可以直接删除。';
  }

  @override
  String relocateSpaceItemsTitle(int count) {
    return '先安置 $count 件物品';
  }

  @override
  String relocateSpaceItemsMessage(String name) {
    return '删除“$name”后，这些物品需要移到其他空间或设为未设置。';
  }

  @override
  String get setUnassignedSpace => '设为未设置空间';

  @override
  String moveToSpace(String name) {
    return '移到 $name';
  }

  @override
  String get spaceDeleteFailed => '空间删除失败，原数据未改变。';

  @override
  String get spaceTypeLivingRoom => '客厅';

  @override
  String get spaceTypeBedroom => '卧室';

  @override
  String get spaceTypeKitchen => '厨房';

  @override
  String get spaceTypeBathroom => '卫生间';

  @override
  String get spaceTypeBalcony => '阳台';

  @override
  String get spaceTypeStudy => '书房';

  @override
  String get spaceTypeDiningRoom => '餐厅';

  @override
  String get spaceTypeStorage => '储物间';

  @override
  String get spaceTypeEntryway => '玄关';

  @override
  String get spaceTypeOther => '其他';

  @override
  String get inventorySearchHint => '搜索物品、空间或类别';

  @override
  String get clearSearch => '清除搜索';

  @override
  String get inventoryAllItems => '全部物品';

  @override
  String get inventoryPlannedItems => '已计划物品';

  @override
  String get inventoryNeedsSetupItems => '待设置物品';

  @override
  String get sortByName => '按名称';

  @override
  String get sortByTime => '按时间';

  @override
  String get itemDeleteFailed => '物品删除失败，原数据未改变，请重试。';

  @override
  String get itemSortTitle => '物品排序';

  @override
  String get sortByNextMaintenance => '按下次保养时间';

  @override
  String get deleteItemTitle => '删除物品？';

  @override
  String deleteItemMessage(String name) {
    return '将删除“$name”以及已保存的凭证照片。';
  }

  @override
  String get assetValuationTitle => '资产估值';

  @override
  String get assetValuationSubtitle => '按物品当前估值汇总，缺失时回退到购买价';

  @override
  String get allItems => '全部物品';

  @override
  String get householdTotalValuation => '家庭物品总估值';

  @override
  String assetMissingCount(int count) {
    return '缺失 $count 件';
  }

  @override
  String get itemValuationDetails => '物品估值明细';

  @override
  String get assetNoItems => '还没有物品，添加后即可记录资产价值';

  @override
  String get assetCurrentValue => '当前估值';

  @override
  String get assetPurchasePriceFallback => '购买价回退';

  @override
  String get assetValueMissing => '尚未填写估值';

  @override
  String get assetAddValue => '去补充';

  @override
  String get inventoryTitle => '物品档案';

  @override
  String get inventorySubtitle => '管理物品与保养计划';

  @override
  String inventoryFilterAll(int count) {
    return '全部 $count';
  }

  @override
  String inventoryFilterPlanned(int count) {
    return '已计划 $count';
  }

  @override
  String inventoryFilterNeedsSetup(int count) {
    return '待设置 $count';
  }

  @override
  String sortMethodSemantic(String label) {
    return '排序方式：$label';
  }

  @override
  String get inventoryNoMatches => '没有符合条件的物品';

  @override
  String get inventoryEmpty => '还没有物品';

  @override
  String get inventoryAdjustSearch => '调整筛选或搜索关键词';

  @override
  String get inventoryStartFirstItem => '从第一件需要照料的物品开始';

  @override
  String get scheduleTitle => '保养日程';

  @override
  String get scheduleEmptySubtitle => '把需要照料的事情留给合适的时间';

  @override
  String get scheduleSubtitle => '点选日期，查看当天具体的保养任务';

  @override
  String scheduleSelectedDateTitle(String date) {
    return '$date的保养';
  }

  @override
  String get scheduleNone => '暂无安排';

  @override
  String scheduleTaskCount(int count) {
    return '$count 项';
  }

  @override
  String get scheduleDayEmpty => '这一天没有安排，慢慢享受生活吧。';

  @override
  String get ledgerTitle => '资产运营账本';

  @override
  String get ledgerSubtitle => '只记录与家庭物品有关的支出';

  @override
  String ledgerAnnualHoldingCost(int year) {
    return '$year 年持有成本';
  }

  @override
  String get ledgerCostHistory => '成本流水';

  @override
  String get ledgerEmpty => '在物品详情中添加维修或耗材记录';

  @override
  String ledgerRecordSummary(String item, String date, String note) {
    return '$item · $date$note';
  }

  @override
  String ledgerNoteSuffix(String note) {
    return ' · $note';
  }

  @override
  String get remindersEnabledToast => '保养提醒已开启，将按各计划设置的提前天数在本机提醒你。';

  @override
  String get remindersEnabledTitle => '保养提醒已开启';

  @override
  String get remindersNoScheduledPlans => '还没有启用且设置到期日的保养计划。建立计划后，可按计划的提前天数提醒。';

  @override
  String remindersScheduledPlans(int count) {
    return '已为 $count 个保养计划安排本机提醒，将按各计划的提前天数在上午 9:00 通知你。';
  }

  @override
  String get testReminderScheduled => '测试提醒将在 5 秒后送达，可切到桌面或锁屏查看';

  @override
  String get testReminderFailed => '测试提醒暂时无法发送，请稍后重试';

  @override
  String get sendTestReminder => '发送测试提醒';

  @override
  String get notificationSettingsManual => '请手动前往“设置 → 通知 → 家务志”管理提醒';

  @override
  String get openSystemNotificationSettings => '前往系统通知设置';

  @override
  String get sampleReadOnlyError => '档案读取失败时不能修改示例数据，请先重启或恢复有效备份';

  @override
  String get sampleDataTitle => '示例数据';

  @override
  String get sampleDataDescription => '重置只会恢复一条“示例 · 厨房净水器”，不会删除你自己创建的物品。';

  @override
  String get resetSamplePurifier => '重置示例净水器';

  @override
  String get deleteSampleData => '删除示例数据';

  @override
  String get sampleDataSaveFailed => '示例数据保存失败，原数据未改变，请重试。';

  @override
  String get samplePurifierReset => '示例净水器已重置';

  @override
  String get sampleDataDeleted => '示例数据已删除';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '提醒、备份与隐私都留在你的掌握中';

  @override
  String get dataAndRemindersSection => '数据与提醒';

  @override
  String get remindersAndTesting => '提醒与测试';

  @override
  String get enableMaintenanceReminders => '开启保养提醒';

  @override
  String get remindersEnabledSubtitle => '已开启 · 查看规则或发送测试提醒';

  @override
  String get remindersDisabledSubtitle => '按各计划设置的提前天数在本机提醒';

  @override
  String get exportLocalData => '导出本地数据';

  @override
  String get exportLocalDataSubtitle => '生成 CSV，可保存到文件或发送';

  @override
  String get fullBackup => '完整备份';

  @override
  String get fullBackupSubtitle => '导出全部档案、记录和凭证照片';

  @override
  String get restoreBackup => '恢复备份';

  @override
  String get restoreInProgress => '正在恢复，请勿关闭应用';

  @override
  String get restoreBackupSubtitle => '选择此前导出的 Hearthio-backup.zip';

  @override
  String get manageSampleData => '管理示例数据';

  @override
  String get manageSampleExistingSubtitle => '可删除或重置“示例 · 厨房净水器”';

  @override
  String get manageSampleMissingSubtitle => '恢复一条可删除的示例净水器';

  @override
  String get privacySection => '隐私';

  @override
  String get privacyPolicySubtitle => '查看数据保存、权限和导出说明';

  @override
  String get restoreGuideTitle => '如何恢复完整备份？';

  @override
  String get restoreConfirmTitle => '从文件恢复完整备份？';

  @override
  String get restoreGuideMessage =>
      '接下来会打开“文件”选择器。\n\n1. 找到此前通过“完整备份”导出的 Hearthio-backup.zip。\n2. 选择该文件后，物品、维护记录和凭证照片会一起恢复。\n3. 当前设备上的档案将被替换；如需保留，请先导出一次当前完整备份。';

  @override
  String get restoreConfirmMessage =>
      '接下来会打开“文件”选择器，请选择此前导出的 Hearthio-backup.zip。\n\n恢复会替换当前设备上的档案。';

  @override
  String get restoreNotNow => '暂不恢复';

  @override
  String get chooseBackupFile => '选择备份文件';

  @override
  String get restoreSuccess => '备份已恢复：物品、记录和照片已更新';

  @override
  String get restoreInvalid => '没有选择有效的 Hearthio-backup.zip，当前档案未发生变化';

  @override
  String get itemNoMaintenanceReminder => '还没有保养提醒';

  @override
  String get itemPlanned => '已计划';

  @override
  String itemNextMaintenance(String date) {
    return '下次 $date';
  }

  @override
  String setPlanForItemSemantic(String name) {
    return '为$name设置计划';
  }

  @override
  String get setPlan => '设置计划';

  @override
  String get itemInformation => '物品信息';

  @override
  String get itemCategory => '类别';

  @override
  String get itemLocation => '位置';

  @override
  String get itemBrand => '品牌';

  @override
  String get itemModel => '型号';

  @override
  String get itemPurchaseDate => '购买日期';

  @override
  String get itemWarrantyEnd => '保修截止';

  @override
  String get itemPurchasePrice => '购买价';

  @override
  String get itemCurrentValue => '当前估值';

  @override
  String get itemNotes => '备注';

  @override
  String get itemDescription => '说明';

  @override
  String get startOneMaintenance => '开始一次保养';

  @override
  String get deleteThisItem => '删除此物品';

  @override
  String get detailMaintenancePlans => '保养计划';

  @override
  String detailArchivedPlans(int count) {
    return '已归档 $count 项';
  }

  @override
  String get detailNoVisiblePlans => '暂无启用或停用的保养计划';

  @override
  String detailPlanSchedule(String state, int interval, int lead) {
    return '$state · 每 $interval 天 · 提前 $lead 天';
  }

  @override
  String detailPlanDueSummary(String date, String timing, int count) {
    return '原到期日 $date · $timing · $count 个步骤';
  }

  @override
  String get planRequiredBeforeMaintenance => '请先为物品建立并启用一个保养计划。';

  @override
  String get chooseMaintenanceTask => '选择保养任务';

  @override
  String get sampleItemName => '示例 · 厨房净水器';

  @override
  String get sampleItemNotes => '这是可删除的示例数据：完成更换滤芯后，可以记录日期、型号和实际费用。';

  @override
  String get categoryFurniture => '家具';

  @override
  String get categoryAppliances => '家用电器';

  @override
  String get categoryKitchen => '厨房用品';

  @override
  String get categoryPersonalBathroom => '个人与卫浴';

  @override
  String get categoryTextilesBedding => '织物与床品';

  @override
  String get categoryCleaningStorage => '清洁与收纳';

  @override
  String get categorySmallItemsTools => '小物品与工具';

  @override
  String get categoryHealthcare => '医疗保健';

  @override
  String get categoryDocuments => '文件证件';

  @override
  String get categoryDecorHobbies => '装饰与兴趣';

  @override
  String get categoryFiltersConsumables => '滤芯与耗材';

  @override
  String get categoryVehiclesTravel => '车辆与出行';

  @override
  String get categoryPetSupplies => '宠物用品';

  @override
  String get categoryOtherItems => '其他物品';

  @override
  String get editItemTitle => '编辑物品';

  @override
  String get itemNameRequiredLabel => '物品名称 *';

  @override
  String get specificLocationOptional => '具体位置（选填）';

  @override
  String get assetInformation => '资产信息';

  @override
  String get purchasePriceCny => '购买价（元）';

  @override
  String get currentValueCny => '当前估值（元）';

  @override
  String get dateInformation => '时间信息';

  @override
  String get documentPhotos => '凭证照片';

  @override
  String get chooseItemTitle => '选择物品';

  @override
  String get searchCategoriesOrItems => '搜索类别或物品';

  @override
  String get commonItems => '常用物品';

  @override
  String get allCategories => '全部分类';

  @override
  String get collapseAll => '全部收起';

  @override
  String get expandAll => '展开全部';

  @override
  String get supplementInformation => '补充信息';

  @override
  String get optionalInformation => '选填信息';

  @override
  String get finishLater => '稍后完善';

  @override
  String get finishAdding => '完成添加';

  @override
  String get searchNoItems => '没有找到相关物品';

  @override
  String get searchResults => '搜索结果';

  @override
  String addCustomItemHint(String query) {
    return '可以把“$query”作为自定义名称添加。';
  }

  @override
  String get addOtherItem => '添加其他物品';

  @override
  String get changeSelection => '更换';

  @override
  String get customItemNameLabel => '备注或自定义名称';

  @override
  String get customItemNameHint => '例如：主卧空调';

  @override
  String get specificLocationHint => '例如：阳台、电视柜左侧';

  @override
  String get brandAndModel => '品牌与型号';

  @override
  String get canAddLater => '以后也可以补充';

  @override
  String get spaceFieldLabel => '所在空间';

  @override
  String get advancedItemInformation => '购买、保修与保养信息';

  @override
  String get fillWhenNeeded => '需要时再填写';

  @override
  String get itemNameRequired => '请填写物品名称';

  @override
  String get chooseCategory => '选择类别';

  @override
  String get addDocumentPhoto => '添加凭证照片';

  @override
  String get photoCameraSubtitle => '直接拍摄物品、说明书或保修卡';

  @override
  String get photoLibrarySubtitle => '从已保存的照片中添加凭证';

  @override
  String get itemSaveFailed => '保存失败，请稍后重试。';

  @override
  String get notificationsNotEnabled => '暂未开启通知';

  @override
  String get archiveLoadFailed =>
      '本地档案读取失败，原数据仍保留在设备上，当前编辑已暂停。请勿卸载应用，可重启或从有效备份恢复。';

  @override
  String get csvHeaderName => '名称';

  @override
  String get csvHeaderCategory => '类别';

  @override
  String get csvHeaderLocation => '位置';

  @override
  String get csvHeaderBrand => '品牌';

  @override
  String get csvHeaderModel => '型号';

  @override
  String get csvHeaderPurchaseDate => '购买日期';

  @override
  String get csvHeaderWarrantyEnd => '保修截止';

  @override
  String get csvHeaderNextMaintenance => '下次保养';

  @override
  String get csvHeaderPurchasePrice => '购买价';

  @override
  String get csvHeaderCurrentValue => '当前估值';

  @override
  String get csvHeaderMaintenanceRecords => '维护记录数';

  @override
  String get csvHeaderTotalMaintenanceCost => '累计维护费用';

  @override
  String get csvHeaderNotes => '备注';

  @override
  String get csvExportShareTitle => '家庭物品保养册数据导出';

  @override
  String get backupExportFailed => '完整备份未导出，请检查设备存储后重试。';

  @override
  String get testNotificationTitle => '家务志提醒已开启';

  @override
  String get testNotificationBody => '这是一条测试提醒。之后会按每个计划设置的提前天数通知你。';

  @override
  String get notificationChannelName => '保养提醒';

  @override
  String get notificationChannelDescription => '家庭物品保养提醒';

  @override
  String maintenanceNotificationBody(String item, String date) {
    return '$item · $date 到期，记得安排处理。';
  }

  @override
  String get dashboardTimingDateUnset => '尚未设置日期';

  @override
  String dashboardTimingOverdue(int days) {
    return '已逾期 $days 天';
  }

  @override
  String get dashboardTimingDueToday => '今天到期';

  @override
  String dashboardTimingDueInDays(int days) {
    return '$days 天后';
  }

  @override
  String get unnamedItem => '未命名物品';

  @override
  String get uncategorized => '未分类';

  @override
  String get maintenanceGeneric => '保养';

  @override
  String get historicalStepUnavailable => '原步骤内容不可用';
}
