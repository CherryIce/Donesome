// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hearthio';

  @override
  String get languageTitle => 'Language';

  @override
  String get systemLanguage => 'System default';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get generalSection => 'General';

  @override
  String get languageSettingSubtitle =>
      'Choose system default, Simplified Chinese, or English';

  @override
  String get featureIntroTitle => 'Feature guide';

  @override
  String get featureIntroSettingsSubtitle =>
      'Learn how to create item profiles, care plans, and maintenance records';

  @override
  String get featureIntroHeroEyebrow => 'Start with an item profile';

  @override
  String get featureIntroHeroTitle =>
      'Keep household items and care plans organized';

  @override
  String get featureIntroHeroBody =>
      'Hearthio starts with each item profile and keeps its care plans, completed work, and costs together for easy reference.';

  @override
  String get featureIntroStepsTitle => 'Get started in four steps';

  @override
  String get featureIntroArchiveTitle => 'Create an item profile';

  @override
  String get featureIntroArchiveBody =>
      'Open Items and add an appliance, consumable, or piece of furniture. Include its space, model, photos, and other useful details.';

  @override
  String get featureIntroPlanTitle => 'Create a care plan';

  @override
  String get featureIntroPlanBody =>
      'Open the item, choose Set plan, then add the interval, next date, reminder lead time, and checklist.';

  @override
  String get featureIntroCompleteTitle => 'Complete and record the work';

  @override
  String get featureIntroCompleteBody =>
      'Start care from Schedule or the item page, work through the checklist, and save photos, costs, and notes.';

  @override
  String get featureIntroReviewTitle => 'Review history and costs';

  @override
  String get featureIntroReviewBody =>
      'See completed care on each item and use Reports to understand maintenance activity and household-item spending.';

  @override
  String get featureIntroSampleTipTitle => 'Explore the sample first';

  @override
  String get featureIntroSampleTipBody =>
      'Hearthio creates one water-purifier sample the first time you enter. Open it to see how an item profile and care plan work together.';

  @override
  String get featureIntroBackupTitle => 'Back up regularly';

  @override
  String get featureIntroBackupBody =>
      'Your archive stays on this device by default. After adding important photos and records, export a full backup from Settings.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get onboardingArchiveTitle => 'Build a home inventory';

  @override
  String get onboardingArchiveBody =>
      'Add names, locations, and care schedules so every household item is easy to find.';

  @override
  String get onboardingEvidenceTitle => 'Keep the details with photos';

  @override
  String get onboardingEvidenceBody =>
      'Photograph or choose manuals, warranty cards, and repair photos. Everything stays on this device.';

  @override
  String get onboardingReminderTitle => 'Stay on schedule';

  @override
  String get onboardingReminderBody =>
      'See upcoming tasks on your care calendar and receive on-device reminders before they are due.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start organizing';

  @override
  String get homeTab => 'Home';

  @override
  String get itemsTab => 'Items';

  @override
  String get scheduleTab => 'Schedule';

  @override
  String get reportTab => 'Reports';

  @override
  String get settingsTab => 'Settings';

  @override
  String get addItem => 'Add item';

  @override
  String get selectDate => 'Select date';

  @override
  String get today => 'Today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get weekdaySunday => 'Sun';

  @override
  String get weekdayMonday => 'Mon';

  @override
  String get weekdayTuesday => 'Tue';

  @override
  String get weekdayWednesday => 'Wed';

  @override
  String get weekdayThursday => 'Thu';

  @override
  String get weekdayFriday => 'Fri';

  @override
  String get weekdaySaturday => 'Sat';

  @override
  String calendarMonthYear(int year, int month) {
    return '$month/$year';
  }

  @override
  String dateYmd(int year, int month, int day) {
    return '$month/$day/$year';
  }

  @override
  String dateMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String dateTodaySemantic(String date) {
    return '$date, today';
  }

  @override
  String get permissionCamera => 'Camera';

  @override
  String get permissionPhotos => 'Photos';

  @override
  String get permissionNotifications => 'Notifications';

  @override
  String permissionUnavailableTitle(String permission) {
    return '$permission access is unavailable';
  }

  @override
  String get permissionLater => 'Not now';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String permissionOpenSettingsManually(String permission) {
    return 'Open Settings manually and allow Hearthio to access $permission.';
  }

  @override
  String permissionStatusUnavailable(String permission) {
    return 'The current $permission permission status could not be read. Try again later, or check Settings if you previously disabled it.';
  }

  @override
  String permissionRequestIncomplete(String permission) {
    return 'The system could not complete the $permission permission request. Try again, or check Settings if it remains unavailable.';
  }

  @override
  String permissionDeniedGuidance(String permission) {
    return '$permission access is not enabled, so this feature is temporarily unavailable. Allow Hearthio to access $permission in Settings, then try again.';
  }

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPreparingTitle =>
      'The privacy policy page is being prepared';

  @override
  String get privacyPreparingMessage =>
      'The complete privacy policy will appear here after the production HTTPS address is configured.';

  @override
  String get privacyLoadFailedTitle => 'Unable to load the privacy policy';

  @override
  String privacyLoadFailedMessage(String error) {
    return 'Check your connection and try again.\n$error';
  }

  @override
  String get privacyReload => 'Reload';

  @override
  String get privacyLocalFirstSummary =>
      'Hearthio does not require an account. Item details, photos, maintenance records, and plans stay on this device by default. Files leave the app sandbox only when you choose to export, back up, or share them.';

  @override
  String get maintenanceStatePlanned => 'Planned';

  @override
  String get maintenanceStateDueSoon => 'Due soon';

  @override
  String get maintenanceStateDueToday => 'Due today';

  @override
  String get maintenanceStateOverdue => 'Overdue';

  @override
  String get maintenanceStateDeferred => 'Reminder deferred';

  @override
  String get maintenanceStateCompleted => 'Completed';

  @override
  String get maintenanceStateDisabled => 'Disabled';

  @override
  String get maintenanceDueDateUnset => 'No due date set';

  @override
  String maintenanceOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String maintenanceDueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Due in $_temp0';
  }

  @override
  String originalDueWithTiming(String date, String timing) {
    return 'Original due date $date · $timing';
  }

  @override
  String deferredReminderStatus(String date, String status) {
    return 'Remind on $date · Original status: $status';
  }

  @override
  String get deferReminder => 'Remind me later';

  @override
  String get editDeferredReminder => 'Change reminder';

  @override
  String get startMaintenance => 'Start maintenance';

  @override
  String get maintenancePlansTitle => 'Maintenance plans';

  @override
  String get addPlan => 'Add plan';

  @override
  String get planTemplateDisclaimer =>
      'Template intervals are references only. You can edit every field before saving; always follow the manufacturer\'s instructions first.';

  @override
  String archivedPlansCount(int count) {
    return 'Archived plans ($count)';
  }

  @override
  String get archivedPlansSubtitle =>
      'Linked history is preserved and reminders are stopped';

  @override
  String intervalEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'day',
    );
    return 'Every $_temp0';
  }

  @override
  String get archivePlanTitle => 'Archive this plan?';

  @override
  String get deletePlanTitle => 'Delete this plan?';

  @override
  String archivePlanMessage(String title) {
    return '“$title” has maintenance records. Archiving stops reminders but preserves the history.';
  }

  @override
  String deletePlanMessage(String title) {
    return '“$title” has no maintenance records. Deletion cannot be undone.';
  }

  @override
  String get confirmArchive => 'Archive';

  @override
  String get confirmDelete => 'Delete';

  @override
  String get noMaintenancePlans => 'No maintenance plans yet';

  @override
  String get noMaintenancePlansSubtitle =>
      'Start from a template or create a completely custom task.';

  @override
  String get planEnabled => 'Enabled';

  @override
  String get planDisabled => 'Disabled';

  @override
  String planScheduleSummary(String state, int interval, int lead) {
    return '$state · Every $interval days · Remind $lead days early';
  }

  @override
  String planNextSummary(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return 'Next: $date · $_temp0';
  }

  @override
  String editPlanTooltip(String title) {
    return 'Edit $title';
  }

  @override
  String removePlanTooltip(String title) {
    return 'Delete or archive $title';
  }

  @override
  String get selectMaintenanceTemplate => 'Choose a maintenance template';

  @override
  String get templatePickerDisclaimer =>
      'Templates are editable starting points, not mandatory safety intervals. Follow the manufacturer\'s instructions.';

  @override
  String get customTemplateDescription =>
      'Enter the name, interval, and steps yourself';

  @override
  String templateDefaultSummary(int days, String steps) {
    return 'Default: $days days · $steps';
  }

  @override
  String get editMaintenancePlan => 'Edit maintenance plan';

  @override
  String get savePlan => 'Save plan';

  @override
  String get planNameLabel => 'Plan name *';

  @override
  String get enablePlan => 'Enable plan';

  @override
  String get disablePlanSubtitle =>
      'Disabling preserves the plan and history but stops reminders';

  @override
  String get intervalDaysLabel => 'Interval (days) *';

  @override
  String get reminderLeadDaysLabel => 'Remind early (days) *';

  @override
  String get lastCompletedOptional => 'Last completed (optional)';

  @override
  String get firstOrNextDueDate => 'First / next due date';

  @override
  String get nextDatePreview => 'Next date preview';

  @override
  String get completeScheduleForPreview =>
      'Complete the interval and date to see a preview';

  @override
  String nextDateReminderPreview(String date, String days) {
    return '$date · Remind $days days early';
  }

  @override
  String get executionSteps => 'Steps';

  @override
  String get addStep => 'Add step';

  @override
  String get optionalStepsHint =>
      'Steps are optional. Add them one at a time and edit them before saving.';

  @override
  String get stepRequired => 'Enter step details';

  @override
  String get stepContentLabel => 'Step details';

  @override
  String deleteStepTooltip(int number) {
    return 'Delete step $number';
  }

  @override
  String get notSet => 'Not set';

  @override
  String get validationPlanNameRequired => 'Enter a plan name';

  @override
  String get validationPlanNameTooLong =>
      'Plan names cannot exceed 40 characters';

  @override
  String get validationIntervalInteger => 'Enter a whole-number interval';

  @override
  String validationIntervalRange(int min, int max) {
    return 'The interval must be between $min and $max days';
  }

  @override
  String get validationDaysInteger => 'Enter a whole number of days';

  @override
  String validationReminderRange(int max) {
    return 'Reminder lead time must be between 0 and $max days';
  }

  @override
  String get validationReminderAfterInterval =>
      'Reminder lead time cannot exceed the maintenance interval';

  @override
  String get validationPlanDateRequired =>
      'Choose the last completion date or first due date';

  @override
  String get validationPlanDateRange =>
      'The date must be between 2000 and 2100';

  @override
  String get validationDueBeforeCompletion =>
      'The due date cannot be earlier than the last completion date';

  @override
  String get templateSceneAirConditioner => 'Air conditioner';

  @override
  String get templateTitleCleanFilter => 'Clean filter';

  @override
  String get templateSceneWaterPurifier => 'Water purifier';

  @override
  String get templateTitleReplaceFilter => 'Replace filter';

  @override
  String get templateSceneWasher => 'Washing machine';

  @override
  String get templateTitleCleanDrum => 'Clean drum';

  @override
  String get templateSceneFridge => 'Refrigerator';

  @override
  String get templateTitleCleanCondenser => 'Clean condenser area';

  @override
  String get templateSceneSmokeAlarm => 'Smoke alarm';

  @override
  String get templateTitleTestBattery => 'Test battery';

  @override
  String get templateSceneCustom => 'Custom';

  @override
  String get templateTitleCustomTask => 'Custom task';

  @override
  String get stepPowerOff => 'Power off';

  @override
  String get stepDisassemble => 'Disassemble';

  @override
  String get stepClean => 'Clean';

  @override
  String get stepDry => 'Dry';

  @override
  String get stepReassemble => 'Reassemble';

  @override
  String get stepVerifyModel => 'Verify model';

  @override
  String get stepShutOffWater => 'Shut off water';

  @override
  String get stepReplace => 'Replace';

  @override
  String get stepFlush => 'Flush';

  @override
  String get stepEmpty => 'Empty';

  @override
  String get stepAddCleaner => 'Add cleaner';

  @override
  String get stepRun => 'Run';

  @override
  String get stepWipeDry => 'Wipe dry';

  @override
  String get stepRemoveDust => 'Remove dust';

  @override
  String get stepCheckVentilation => 'Check ventilation';

  @override
  String get stepReset => 'Reset';

  @override
  String get stepTestAlarm => 'Test alarm';

  @override
  String get stepCheckBattery => 'Check battery';

  @override
  String get stepRecordResult => 'Record result';

  @override
  String get stepDescriptionVerifyFilter =>
      'Confirm the water purifier model and compatible filter';

  @override
  String get stepDescriptionShutOffWater =>
      'Close the inlet valve and make sure the water has stopped';

  @override
  String get stepDescriptionReplaceFilter =>
      'Remove the old filter and install the new one';

  @override
  String get stepDescriptionFlushFilter =>
      'Open the water supply and flush until the water runs clear';

  @override
  String get editMaintenanceRecord => 'Edit maintenance record';

  @override
  String get linkedPlan => 'Linked plan';

  @override
  String get originalPlanUnavailableSuffix => ' (original plan unavailable)';

  @override
  String get recordPlanLinkImmutable =>
      'The record\'s link to its original plan cannot be changed while editing.';

  @override
  String get recordCostLabel => 'Cost (CNY)';

  @override
  String get optionalZeroCostHint => 'Optional; saved as CNY 0 when blank';

  @override
  String get materialNameLabel => 'Material name / model';

  @override
  String get notesLabel => 'Notes';

  @override
  String get recordHasNoSteps => 'This record has no step data.';

  @override
  String historicalStepIdsOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count historical step IDs were preserved, but their original details are unavailable.',
      one:
          '1 historical step ID was preserved, but its original details are unavailable.',
    );
    return '$_temp0';
  }

  @override
  String get beforePhotos => 'Before photos';

  @override
  String get afterPhotos => 'After photos';

  @override
  String get saving => 'Saving…';

  @override
  String get saveRecord => 'Save record';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromPhotos => 'Choose from Photos';

  @override
  String get cameraOpenFailed =>
      'Unable to open the camera. Check camera access and try again.';

  @override
  String get photoReadFailed =>
      'Unable to read the photo. Check photo access and try again.';

  @override
  String get maintenanceRecordSaveFailed =>
      'The maintenance record could not be saved. Try again.';

  @override
  String get actualCompletionDate => 'Actual completion date';

  @override
  String get noPhotosAdded => 'No photos added';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get validationNonNegativeAmount =>
      'Enter an amount greater than or equal to 0';

  @override
  String get executionNoPresetSteps =>
      'This plan has no preset steps. You can record the result directly.';

  @override
  String get optionalRecordSection => 'This record (optional)';

  @override
  String get dateLabel => 'Date';

  @override
  String get costLabel => 'Cost';

  @override
  String get optional => 'Optional';

  @override
  String get materialLabel => 'Material';

  @override
  String get modelOrName => 'Model/name';

  @override
  String get completedField => 'Completed';

  @override
  String get recordCostTitle => 'Record cost';

  @override
  String get recordMaterialTitle => 'Record material';

  @override
  String get materialExample => 'For example: PP filter A1';

  @override
  String get addNotesTitle => 'Add notes';

  @override
  String get notesHelper =>
      'Record issues, observations, or anything to remember next time';

  @override
  String get beforePhotoCaptureTitle => 'Before-maintenance photos';

  @override
  String get afterPhotoCaptureTitle => 'After-maintenance photos';

  @override
  String get beforePhotosLocked =>
      'Maintenance has started, so before photos are locked.';

  @override
  String get afterPhotosTemporarilyLocked =>
      'A step was reopened, so after photos are temporarily locked.';

  @override
  String get maintenanceCompletionSaveFailed =>
      'This maintenance record could not be saved. Try again.';

  @override
  String get maintenanceCompletedTitle => 'Maintenance complete';

  @override
  String get maintenanceArchived => 'This maintenance has been archived';

  @override
  String get completionTime => 'Completed';

  @override
  String get thisCost => 'Cost';

  @override
  String get nextPlan => 'Next plan';

  @override
  String get reminder => 'Reminder';

  @override
  String reminderDaysEarly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days early',
      one: '1 day early',
    );
    return '$_temp0';
  }

  @override
  String get completionLifecycleHint =>
      'Open this item\'s lifecycle to review this record, cumulative cost, and the next task.';

  @override
  String get notificationRescheduleFailed =>
      'The record and next date were saved, but the notification could not be rescheduled. Check notification access in Settings and try again.';

  @override
  String get viewLifecycle => 'View lifecycle';

  @override
  String originalPlanDate(String date) {
    return 'Original plan date $date';
  }

  @override
  String photosRecordedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos recorded',
      one: '1 photo recorded',
    );
    return '$_temp0';
  }

  @override
  String get noPhotosThisTime => 'No photos this time';

  @override
  String get beforePhotoPrompt =>
      'Record the current state for comparison after completion';

  @override
  String get beforePhotoOptional => 'Before photos (optional)';

  @override
  String beforePhotoSemantic(String status, String locked) {
    return 'Before-maintenance photos, optional, $status$locked';
  }

  @override
  String get beforePhotoLockedSemanticSuffix =>
      ', maintenance has started and before photos are locked';

  @override
  String get afterPhotoReadyHint =>
      'All steps are complete. Record the final state for comparison';

  @override
  String get afterPhotoReopenedHint =>
      'A step was reopened. Complete it to manage after photos again';

  @override
  String get afterPhotoWaitingHint => 'Complete all steps to add after photos';

  @override
  String get afterPhotoOptional => 'After photos (optional)';

  @override
  String afterPhotoSemantic(String status) {
    return 'After-maintenance photos, optional, $status';
  }

  @override
  String get beforeLabel => 'Before';

  @override
  String get afterLabel => 'After';

  @override
  String get notRecorded => 'Not recorded';

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get waitingForCompletion => 'Waiting for completion';

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String stepSemantic(
    int number,
    String title,
    String description,
    String state,
  ) {
    return 'Step $number: $title$description$state';
  }

  @override
  String stepDescriptionSemantic(String description) {
    return ', $description';
  }

  @override
  String get currentStepSemantic => ', current step';

  @override
  String get completedStepSemantic => ', completed';

  @override
  String get completeMaintenance => 'Complete maintenance';

  @override
  String get validationFiniteNonNegativeAmount =>
      'Enter a finite amount greater than or equal to 0';

  @override
  String get lifecycleOverviewTitle => 'Lifecycle overview';

  @override
  String get lifecycleUsageDuration => 'Time in use';

  @override
  String get lifecyclePurchaseDateMissing => 'Purchase date not entered';

  @override
  String get lifecyclePurchaseDateFuture => 'Purchase date is in the future';

  @override
  String lifecycleUsageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get lifecycleMaintenanceTotal => 'Maintenance completed';

  @override
  String lifecycleCompletionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get lifecycleActualCost => 'Actual cost';

  @override
  String get lifecycleCurrentOverdue => 'Currently overdue';

  @override
  String lifecycleOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get lifecycleNextTask => 'Next task';

  @override
  String get lifecycleNoNextTask => 'No enabled plan with a date';

  @override
  String lifecycleNextTaskSummary(String title, String date, String timing) {
    return '$title · $date · $timing';
  }

  @override
  String get lifecycleTimelineTitle => 'Lifecycle timeline';

  @override
  String get lifecycleTimelineSubtitle =>
      'Shows the purchase date and actual maintenance records you entered, newest first.';

  @override
  String get lifecycleTimelineEmpty =>
      'No lifecycle events yet. Enter a purchase date or complete maintenance to build a traceable history.';

  @override
  String get deleteRecordTitle => 'Delete this maintenance record?';

  @override
  String get deleteRecordMessageNoPlan =>
      'This cannot be undone. Photos in this record will also be removed from this device.';

  @override
  String deleteRecordMessageWithPlan(String title) {
    return 'This cannot be undone. The last completion date and next date will be recalculated from the remaining records for “$title”. Record photos will also be removed from this device.';
  }

  @override
  String get deleteRecordFailed =>
      'The maintenance record could not be deleted. Try again.';

  @override
  String get purchaseStartingPoint => 'Purchase starting point';

  @override
  String get purchaseStartingPointDescription =>
      'Based on the purchase date entered in the item details.';

  @override
  String get recordPlanUnlinked => 'Not linked to a plan';

  @override
  String get recordPlanUnavailable => 'Original plan unavailable';

  @override
  String recordTitleWithPlanState(String title, String state) {
    return '$title · $state';
  }

  @override
  String get editRecordTooltip => 'Edit record';

  @override
  String get deleteRecordTooltip => 'Delete record';

  @override
  String get recordExpense => 'Cost';

  @override
  String get recordMaterial => 'Material';

  @override
  String get recordNotes => 'Notes';

  @override
  String get recordStepsMissing => 'Steps: not recorded';

  @override
  String recordStepsProgress(int completed, int total) {
    return 'Steps: $completed of $total completed';
  }

  @override
  String get recordPhotosMissing => 'Photos: not recorded';

  @override
  String recordPhotoGroup(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$title · $_temp0';
  }

  @override
  String get reportPageTitle => 'Home care report';

  @override
  String get reportPageSubtitle =>
      'Based only on actual plans, completed records, and real costs';

  @override
  String get reportEmptyNotice =>
      'No completed records yet. Complete maintenance to see actual costs and completion details here; overdue and upcoming tasks are still counted from current plans.';

  @override
  String get reportCurrentTasks => 'Current tasks';

  @override
  String get reportCurrentTasksSubtitle =>
      'Calculated live by local calendar date';

  @override
  String get reportCurrentYearMaintenance => 'This year';

  @override
  String get reportTrailingYearMaintenance => 'Last 12 months';

  @override
  String get reportCurrentYearCostSubtitle =>
      'Actual costs from records completed in this calendar year';

  @override
  String get reportTrailingYearCostSubtitle =>
      'Cost and completion rate use the same calendar-month range';

  @override
  String get reportActualMaintenanceCost => 'Actual maintenance cost';

  @override
  String reportCostRangeDescription(String start, String end) {
    return '$start to $end; includes only actual costs from completed records.';
  }

  @override
  String reportIgnoredCostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invalid costs were excluded.',
      one: '1 invalid cost was excluded.',
    );
    return '$_temp0';
  }

  @override
  String get reportCostBreakdown => 'Where the money went';

  @override
  String get reportCostBreakdownSubtitle =>
      'Switch grouping without counting the total twice';

  @override
  String get reportItemBreakdown => 'Item details';

  @override
  String get reportCategoryBreakdown => 'Category summary';

  @override
  String get reportNoItemCosts => 'No maintenance records with costs';

  @override
  String get reportNoCategoryCosts => 'No category costs to summarize';

  @override
  String get reportRecentRecords => 'Recent maintenance records';

  @override
  String get reportRecentRecordsSubtitle =>
      'Every amount links back to an actual completion record';

  @override
  String get reportGroupingSemantic => 'Cost breakdown grouping';

  @override
  String get reportGroupByItem => 'By item';

  @override
  String get reportGroupByCategory => 'By category';

  @override
  String get reportScopeCurrentYear => 'This year';

  @override
  String get reportScopeTrailingYear => 'Last 12 months';

  @override
  String reportCurrentYearMethodology(String start, String end) {
    return 'Method: This month uses completion dates; overdue days are calendar days between today and the original due date; the next 30 days include today; this-year costs cover $start to $end.';
  }

  @override
  String reportTrailingYearMethodology(String start, String end) {
    return 'Method: This month uses completion dates; overdue days are calendar days between today and the original due date; the next 30 days include today; cost and on-time rate cover $start to $end.';
  }

  @override
  String get reportCompletedThisMonth => 'Completed this month';

  @override
  String get reportCurrentOverdue => 'Currently overdue';

  @override
  String get reportCumulativeOverdue => 'Total overdue days';

  @override
  String get reportDueNextThirtyDays => 'Due in the next 30 days';

  @override
  String reportItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String reportDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get reportNoEligibleOnTimeRecords =>
      'No on-time records can be recalculated. Older records or records without an original due date are not assumed to be on time.';

  @override
  String reportOnTimeExplanation(int onTime, int eligible) {
    return 'On time: $onTime / eligible: $eligible. A record is on time when its completion date is no later than its stored original due date.';
  }

  @override
  String get reportOnTimeRate => 'On-time completion rate';

  @override
  String reportExcludedCompletionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count records are missing their original due dates and were excluded from the completion rate.',
      one:
          '1 record is missing its original due date and was excluded from the completion rate.',
    );
    return '$_temp0';
  }

  @override
  String reportRecordSubtitle(String item, String date) {
    return '$item · $date';
  }

  @override
  String get notificationPrimerTitle => 'Turn on maintenance reminders?';

  @override
  String get notificationPrimerMessage =>
      'Hearthio can send on-device notifications using each plan’s reminder lead time.\n\nDeclining does not affect items or maintenance plans. You can enable notifications later in Settings.';

  @override
  String get notificationNotNow => 'Not now';

  @override
  String get notificationEnable => 'Enable notifications';

  @override
  String get dateNotSet => 'Not set';

  @override
  String get deferTitle => 'Remind me later';

  @override
  String deferTaskDescription(String item, String plan, String date) {
    return '$item · $plan\nOriginal due date: $date. Deferring the reminder does not change the actual due status.';
  }

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get inThreeDays => 'In 3 days';

  @override
  String get nextWeek => 'Next week';

  @override
  String get customDate => 'Custom date';

  @override
  String get deferFailed => 'The reminder could not be deferred. Try again.';

  @override
  String get notificationItemUnavailable =>
      'The item for this reminder was deleted. Showing the maintenance schedule instead.';

  @override
  String get notificationPlanUnavailable =>
      'The maintenance plan for this reminder was deleted or disabled. Showing the maintenance schedule instead.';

  @override
  String get notificationMalformed =>
      'This maintenance reminder is no longer valid. Showing the maintenance schedule instead.';

  @override
  String get gotIt => 'Got it';

  @override
  String get dashboardNextMaintenance => 'Next maintenance';

  @override
  String get dashboardHouseholdOverview => 'Home overview';

  @override
  String get dashboardTitle => 'Hearthio';

  @override
  String dashboardDate(String date, String weekday) {
    return '$date · $weekday';
  }

  @override
  String get dashboardNoDueTasks => 'No tasks due';

  @override
  String dashboardAttentionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks need attention',
      one: '1 task needs attention',
    );
    return '$_temp0';
  }

  @override
  String get dashboardAllOnTrack => 'Everything at home is on schedule';

  @override
  String get dashboardStartWithUrgent => 'Start with the most urgent task';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardViewSchedule => 'View schedule';

  @override
  String dashboardOriginalDueDate(String date) {
    return 'Original due date $date';
  }

  @override
  String dashboardDeferredStatus(String date, String status) {
    return 'Remind on $date · Original status: $status';
  }

  @override
  String get dashboardItems => 'Items';

  @override
  String get dashboardSpaces => 'Spaces';

  @override
  String get dashboardThisYearMaintenance => 'This-year care';

  @override
  String get dashboardAssets => 'Assets';

  @override
  String dashboardItemsSemantic(int count) {
    return 'Items, $count; view all items';
  }

  @override
  String dashboardSpacesSemantic(int count) {
    return 'Spaces, $count; view home spaces';
  }

  @override
  String dashboardAnnualCostSemantic(String amount) {
    return 'This-year care, CNY $amount; view the annual maintenance report';
  }

  @override
  String dashboardAssetsSemantic(String amount) {
    return 'Assets, CNY $amount; view asset valuations';
  }

  @override
  String get emptyMaintenanceTitle => 'Start with your first plan';

  @override
  String get emptyMaintenanceSubtitle =>
      'Add an item and a maintenance interval. Hearthio will remind you before it is due.';

  @override
  String get createMaintenancePlan => 'Create maintenance plan';

  @override
  String get spacesTitle => 'Home spaces';

  @override
  String get addSpace => 'Add space';

  @override
  String get spacesDescription =>
      'Organize item locations by actual room; add the precise position inside each room yourself.';

  @override
  String get spacesEmptyTitle => 'No home spaces yet';

  @override
  String get spacesEmptySubtitle =>
      'Add actual rooms such as a living room, bedroom, or kitchen, then select them when editing items.';

  @override
  String get unassignedSpace => 'Space not set';

  @override
  String get awaitingClassification => 'Uncategorized';

  @override
  String spaceItemCount(String type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$type · $_temp0';
  }

  @override
  String get manageSpace => 'Manage space';

  @override
  String get renameSpace => 'Rename space';

  @override
  String get deleteSpace => 'Delete space';

  @override
  String get spaceDeleted => 'Space deleted';

  @override
  String get addItemToSpace => 'Add an item to this space';

  @override
  String get noUnassignedItems => 'No unassigned items';

  @override
  String get spaceHasNoItems => 'No items in this space';

  @override
  String get editSpace => 'Edit space';

  @override
  String get spaceType => 'Space type';

  @override
  String get spaceActualName => 'Actual name';

  @override
  String get spaceNameHint =>
      'For example: Primary bedroom, guest room, kids’ room';

  @override
  String get spaceNameHelper =>
      'The type is used for grouping; the actual name appears as the item location.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get spaceNameRequired => 'Enter a space name';

  @override
  String get spaceNameAlreadyExists =>
      'A space with this actual name already exists. If you have more than one similar space, change the actual name to tell them apart.';

  @override
  String get spaceSaveFailed => 'The space could not be saved. Try again.';

  @override
  String get selectSpace => 'Choose a space';

  @override
  String get organizeLater => 'Organize later';

  @override
  String get deleteSpaceTitle => 'Delete this space?';

  @override
  String deleteEmptySpaceMessage(String name) {
    return '“$name” has no items and can be deleted directly.';
  }

  @override
  String relocateSpaceItemsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Relocate $_temp0 first';
  }

  @override
  String relocateSpaceItemsMessage(String name) {
    return 'After deleting “$name”, move these items to another space or leave their space unset.';
  }

  @override
  String get setUnassignedSpace => 'Leave space unset';

  @override
  String moveToSpace(String name) {
    return 'Move to $name';
  }

  @override
  String get spaceDeleteFailed =>
      'The space could not be deleted. Your data was not changed.';

  @override
  String get spaceTypeLivingRoom => 'Living room';

  @override
  String get spaceTypeBedroom => 'Bedroom';

  @override
  String get spaceTypeKitchen => 'Kitchen';

  @override
  String get spaceTypeBathroom => 'Bathroom';

  @override
  String get spaceTypeBalcony => 'Balcony';

  @override
  String get spaceTypeStudy => 'Study';

  @override
  String get spaceTypeDiningRoom => 'Dining room';

  @override
  String get spaceTypeStorage => 'Storage room';

  @override
  String get spaceTypeEntryway => 'Entryway';

  @override
  String get spaceTypeOther => 'Other';

  @override
  String get inventorySearchHint => 'Search items, spaces, or categories';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get inventoryAllItems => 'All items';

  @override
  String get inventoryPlannedItems => 'Items with plans';

  @override
  String get inventoryNeedsSetupItems => 'Items needing setup';

  @override
  String get sortByName => 'By name';

  @override
  String get sortByTime => 'By date';

  @override
  String get itemDeleteFailed =>
      'The item could not be deleted. Your data was not changed. Try again.';

  @override
  String get itemSortTitle => 'Sort items';

  @override
  String get sortByNextMaintenance => 'By next maintenance date';

  @override
  String get deleteItemTitle => 'Delete item?';

  @override
  String deleteItemMessage(String name) {
    return 'This will delete “$name” and its saved document photos.';
  }

  @override
  String get assetValuationTitle => 'Asset valuation';

  @override
  String get assetValuationSubtitle =>
      'Totals current item values, falling back to purchase price when missing';

  @override
  String get allItems => 'All items';

  @override
  String get householdTotalValuation => 'Total home-item valuation';

  @override
  String assetMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Missing for $_temp0';
  }

  @override
  String get itemValuationDetails => 'Item valuation details';

  @override
  String get assetNoItems =>
      'No items yet. Add one to start recording asset values.';

  @override
  String get assetCurrentValue => 'Current value';

  @override
  String get assetPurchasePriceFallback => 'Using purchase price';

  @override
  String get assetValueMissing => 'No valuation entered';

  @override
  String get assetAddValue => 'Add value';

  @override
  String get inventoryTitle => 'Item inventory';

  @override
  String get inventorySubtitle => 'Manage items and maintenance plans';

  @override
  String inventoryFilterAll(int count) {
    return 'All $count';
  }

  @override
  String inventoryFilterPlanned(int count) {
    return 'Planned $count';
  }

  @override
  String inventoryFilterNeedsSetup(int count) {
    return 'Needs setup $count';
  }

  @override
  String sortMethodSemantic(String label) {
    return 'Sort method: $label';
  }

  @override
  String get inventoryNoMatches => 'No matching items';

  @override
  String get inventoryEmpty => 'No items yet';

  @override
  String get inventoryAdjustSearch => 'Adjust the filters or search terms';

  @override
  String get inventoryStartFirstItem =>
      'Start with the first item that needs care';

  @override
  String get scheduleTitle => 'Maintenance schedule';

  @override
  String get scheduleEmptySubtitle => 'Keep care tasks at the right time';

  @override
  String get scheduleSubtitle => 'Select a date to view its maintenance tasks';

  @override
  String scheduleSelectedDateTitle(String date) {
    return 'Maintenance on $date';
  }

  @override
  String get scheduleNone => 'No tasks';

  @override
  String scheduleTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String get scheduleDayEmpty =>
      'Nothing is scheduled for this day. Enjoy the time.';

  @override
  String get ledgerTitle => 'Asset operations ledger';

  @override
  String get ledgerSubtitle => 'Tracks only spending related to home items';

  @override
  String ledgerAnnualHoldingCost(int year) {
    return '$year holding cost';
  }

  @override
  String get ledgerCostHistory => 'Cost history';

  @override
  String get ledgerEmpty =>
      'Add repair or material records from an item’s details';

  @override
  String ledgerRecordSummary(String item, String date, String note) {
    return '$item · $date$note';
  }

  @override
  String ledgerNoteSuffix(String note) {
    return ' · $note';
  }

  @override
  String get remindersEnabledToast =>
      'Maintenance reminders are on. Each plan uses its own reminder lead time.';

  @override
  String get remindersEnabledTitle => 'Maintenance reminders are on';

  @override
  String get remindersNoScheduledPlans =>
      'No enabled maintenance plans have due dates yet. After you create one, Hearthio can remind you using that plan’s lead time.';

  @override
  String remindersScheduledPlans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maintenance plans',
      one: '1 maintenance plan',
    );
    return 'On-device reminders are scheduled for $_temp0. Notifications arrive at 9:00 AM using each plan’s reminder lead time.';
  }

  @override
  String get testReminderScheduled =>
      'The test reminder will arrive in 5 seconds. Switch to the Home Screen or lock screen to check it.';

  @override
  String get testReminderFailed =>
      'The test reminder cannot be sent right now. Try again later.';

  @override
  String get sendTestReminder => 'Send test reminder';

  @override
  String get notificationSettingsManual =>
      'Open Settings → Notifications → Hearthio to manage reminders manually.';

  @override
  String get openSystemNotificationSettings =>
      'Open system notification settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Keep reminders, backups, and privacy under your control';

  @override
  String get dataAndRemindersSection => 'Data & reminders';

  @override
  String get remindersAndTesting => 'Reminders & testing';

  @override
  String get enableMaintenanceReminders => 'Enable maintenance reminders';

  @override
  String get remindersEnabledSubtitle =>
      'On · View rules or send a test reminder';

  @override
  String get remindersDisabledSubtitle =>
      'On-device reminders use each plan’s lead time';

  @override
  String get exportLocalData => 'Export local data';

  @override
  String get exportLocalDataSubtitle => 'Create a CSV to save or share';

  @override
  String get fullBackup => 'Full backup';

  @override
  String get fullBackupSubtitle =>
      'Export all items, records, and document photos';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get restoreInProgress => 'Restoring. Do not close the app.';

  @override
  String get restoreBackupSubtitle =>
      'Choose a previously exported Hearthio-backup.zip';

  @override
  String get privacySection => 'Privacy';

  @override
  String get privacyPolicySubtitle =>
      'Review data storage, permissions, and export details';

  @override
  String get restoreGuideTitle => 'How do I restore a full backup?';

  @override
  String get restoreConfirmTitle => 'Restore a full backup from a file?';

  @override
  String get restoreGuideMessage =>
      'The Files picker will open next.\n\n1. Find the Hearthio-backup.zip previously created with Full backup.\n2. Select it to restore items, maintenance records, and document photos together.\n3. The archive on this device will be replaced. Export a current full backup first if you need to keep it.';

  @override
  String get restoreConfirmMessage =>
      'The Files picker will open next. Choose a previously exported Hearthio-backup.zip.\n\nRestoring replaces the archive currently on this device.';

  @override
  String get restoreNotNow => 'Not now';

  @override
  String get chooseBackupFile => 'Choose backup file';

  @override
  String get restoreSuccess =>
      'Backup restored. Items, records, and photos were updated.';

  @override
  String get restoreInvalid =>
      'No valid Hearthio-backup.zip was selected. The current archive was not changed.';

  @override
  String get itemNoMaintenanceReminder => 'No maintenance reminder yet';

  @override
  String get itemPlanned => 'Planned';

  @override
  String itemNextMaintenance(String date) {
    return 'Next $date';
  }

  @override
  String setPlanForItemSemantic(String name) {
    return 'Set a plan for $name';
  }

  @override
  String get setPlan => 'Set plan';

  @override
  String get itemInformation => 'Item information';

  @override
  String get itemCategory => 'Category';

  @override
  String get itemLocation => 'Location';

  @override
  String get itemBrand => 'Brand';

  @override
  String get itemModel => 'Model';

  @override
  String get itemPurchaseDate => 'Purchase date';

  @override
  String get itemWarrantyEnd => 'Warranty end';

  @override
  String get itemPurchasePrice => 'Purchase price';

  @override
  String get itemCurrentValue => 'Current value';

  @override
  String get itemNotes => 'Notes';

  @override
  String get itemDescription => 'Description';

  @override
  String get startOneMaintenance => 'Start maintenance';

  @override
  String get deleteThisItem => 'Delete this item';

  @override
  String get detailMaintenancePlans => 'Maintenance plans';

  @override
  String detailArchivedPlans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archived',
      one: '1 archived',
    );
    return '$_temp0';
  }

  @override
  String get detailNoVisiblePlans => 'No enabled or disabled maintenance plans';

  @override
  String detailPlanSchedule(String state, int interval, int lead) {
    return '$state · Every $interval days · Remind $lead days early';
  }

  @override
  String detailPlanDueSummary(String date, String timing, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return 'Original due date $date · $timing · $_temp0';
  }

  @override
  String get planRequiredBeforeMaintenance =>
      'Create and enable a maintenance plan for this item first.';

  @override
  String get chooseMaintenanceTask => 'Choose a maintenance task';

  @override
  String get sampleItemName => 'Sample · Kitchen water purifier';

  @override
  String get sampleItemNotes =>
      'This is deletable sample data. After replacing the filter, record the date, model, and actual cost.';

  @override
  String get categoryFurniture => 'Furniture';

  @override
  String get categoryAppliances => 'Home appliances';

  @override
  String get categoryKitchen => 'Kitchen items';

  @override
  String get categoryPersonalBathroom => 'Personal & bathroom';

  @override
  String get categoryTextilesBedding => 'Textiles & bedding';

  @override
  String get categoryCleaningStorage => 'Cleaning & storage';

  @override
  String get categorySmallItemsTools => 'Small items & tools';

  @override
  String get categoryHealthcare => 'Healthcare';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryDecorHobbies => 'Decor & hobbies';

  @override
  String get categoryFiltersConsumables => 'Filters & consumables';

  @override
  String get categoryVehiclesTravel => 'Vehicles & travel';

  @override
  String get categoryPetSupplies => 'Pet supplies';

  @override
  String get categoryOtherItems => 'Other items';

  @override
  String get editItemTitle => 'Edit item';

  @override
  String get itemNameRequiredLabel => 'Item name *';

  @override
  String get specificLocationOptional => 'Specific location (optional)';

  @override
  String get assetInformation => 'Asset information';

  @override
  String get purchasePriceCny => 'Purchase price (CNY)';

  @override
  String get currentValueCny => 'Current value (CNY)';

  @override
  String get dateInformation => 'Dates';

  @override
  String get documentPhotos => 'Document photos';

  @override
  String get chooseItemTitle => 'Choose an item';

  @override
  String get searchCategoriesOrItems => 'Search categories or items';

  @override
  String get commonItems => 'Common items';

  @override
  String get allCategories => 'All categories';

  @override
  String get collapseAll => 'Collapse all';

  @override
  String get expandAll => 'Expand all';

  @override
  String get supplementInformation => 'Add details';

  @override
  String get optionalInformation => 'Optional information';

  @override
  String get finishLater => 'Finish later';

  @override
  String get finishAdding => 'Finish adding';

  @override
  String get searchNoItems => 'No related items found';

  @override
  String get searchResults => 'Search results';

  @override
  String addCustomItemHint(String query) {
    return 'Add “$query” as a custom name.';
  }

  @override
  String get addOtherItem => 'Add another item';

  @override
  String get changeSelection => 'Change';

  @override
  String get customItemNameLabel => 'Note or custom name';

  @override
  String get customItemNameHint => 'For example: Primary-bedroom AC';

  @override
  String get specificLocationHint =>
      'For example: Balcony, left side of TV stand';

  @override
  String get brandAndModel => 'Brand & model';

  @override
  String get canAddLater => 'You can add this later';

  @override
  String get spaceFieldLabel => 'Space';

  @override
  String get advancedItemInformation => 'Purchase, warranty & maintenance';

  @override
  String get fillWhenNeeded => 'Fill in when needed';

  @override
  String get itemNameRequired => 'Enter an item name';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get addDocumentPhoto => 'Add document photos';

  @override
  String get photoCameraSubtitle =>
      'Photograph the item, manual, or warranty card';

  @override
  String get photoLibrarySubtitle =>
      'Add document photos already saved on this device';

  @override
  String get itemSaveFailed => 'Could not save. Try again later.';

  @override
  String get notificationsNotEnabled => 'Notifications are not enabled yet';

  @override
  String get archiveLoadFailed =>
      'The local archive could not be read. Existing data remains on this device, and editing is paused. Do not uninstall the app; restart it or restore a valid backup.';

  @override
  String get csvHeaderName => 'Name';

  @override
  String get csvHeaderCategory => 'Category';

  @override
  String get csvHeaderLocation => 'Location';

  @override
  String get csvHeaderBrand => 'Brand';

  @override
  String get csvHeaderModel => 'Model';

  @override
  String get csvHeaderPurchaseDate => 'Purchase date';

  @override
  String get csvHeaderWarrantyEnd => 'Warranty end';

  @override
  String get csvHeaderNextMaintenance => 'Next maintenance';

  @override
  String get csvHeaderPurchasePrice => 'Purchase price';

  @override
  String get csvHeaderCurrentValue => 'Current value';

  @override
  String get csvHeaderMaintenanceRecords => 'Maintenance records';

  @override
  String get csvHeaderTotalMaintenanceCost => 'Total maintenance cost';

  @override
  String get csvHeaderNotes => 'Notes';

  @override
  String get csvExportShareTitle => 'Hearthio home-item data export';

  @override
  String get backupExportFailed =>
      'The full backup could not be exported. Check device storage and try again.';

  @override
  String get testNotificationTitle => 'Hearthio reminders are on';

  @override
  String get testNotificationBody =>
      'This is a test reminder. Future notifications will use each plan’s reminder lead time.';

  @override
  String get notificationChannelName => 'Maintenance reminders';

  @override
  String get notificationChannelDescription =>
      'Home-item maintenance reminders';

  @override
  String maintenanceNotificationBody(String item, String date) {
    return '$item · Due $date. Remember to take care of it.';
  }

  @override
  String get dashboardTimingDateUnset => 'Date not set';

  @override
  String dashboardTimingOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTimingDueToday => 'Due today';

  @override
  String dashboardTimingDueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'In $_temp0';
  }

  @override
  String get unnamedItem => 'Unnamed item';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get maintenanceGeneric => 'Maintenance';

  @override
  String get historicalStepUnavailable => 'Original step content unavailable';
}
