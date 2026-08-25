import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hearthio'**
  String get appTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemLanguage;

  /// No description provided for @simplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @languageSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose system default, Simplified Chinese, or English'**
  String get languageSettingSubtitle;

  /// No description provided for @featureIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature guide'**
  String get featureIntroTitle;

  /// No description provided for @featureIntroSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how to create item profiles, care plans, and maintenance records'**
  String get featureIntroSettingsSubtitle;

  /// No description provided for @featureIntroHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Start with an item profile'**
  String get featureIntroHeroEyebrow;

  /// No description provided for @featureIntroHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep household items and care plans organized'**
  String get featureIntroHeroTitle;

  /// No description provided for @featureIntroHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Hearthio starts with each item profile and keeps its care plans, completed work, and costs together for easy reference.'**
  String get featureIntroHeroBody;

  /// No description provided for @featureIntroStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started in four steps'**
  String get featureIntroStepsTitle;

  /// No description provided for @featureIntroArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an item profile'**
  String get featureIntroArchiveTitle;

  /// No description provided for @featureIntroArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'Open Items and add an appliance, consumable, or piece of furniture. Include its space, model, photos, and other useful details.'**
  String get featureIntroArchiveBody;

  /// No description provided for @featureIntroPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a care plan'**
  String get featureIntroPlanTitle;

  /// No description provided for @featureIntroPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Open the item, choose Set plan, then add the interval, next date, reminder lead time, and checklist.'**
  String get featureIntroPlanBody;

  /// No description provided for @featureIntroCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete and record the work'**
  String get featureIntroCompleteTitle;

  /// No description provided for @featureIntroCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Start care from Schedule or the item page, work through the checklist, and save photos, costs, and notes.'**
  String get featureIntroCompleteBody;

  /// No description provided for @featureIntroReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review history and costs'**
  String get featureIntroReviewTitle;

  /// No description provided for @featureIntroReviewBody.
  ///
  /// In en, this message translates to:
  /// **'See completed care on each item and use Reports to understand maintenance activity and household-item spending.'**
  String get featureIntroReviewBody;

  /// No description provided for @featureIntroSampleTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the sample first'**
  String get featureIntroSampleTipTitle;

  /// No description provided for @featureIntroSampleTipBody.
  ///
  /// In en, this message translates to:
  /// **'Hearthio creates one water-purifier sample the first time you enter. Open it to see how an item profile and care plan work together; there is nothing to manage later in Settings.'**
  String get featureIntroSampleTipBody;

  /// No description provided for @featureIntroBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up regularly'**
  String get featureIntroBackupTitle;

  /// No description provided for @featureIntroBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Your archive stays on this device by default. After adding important photos and records, export a full backup from Settings.'**
  String get featureIntroBackupBody;

  /// No description provided for @featureGuideLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The feature guide could not be opened'**
  String get featureGuideLoadFailedTitle;

  /// No description provided for @featureGuideLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The local guide did not load correctly. Please try again.'**
  String get featureGuideLoadFailedBody;

  /// No description provided for @featureGuideRetry.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get featureGuideRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @onboardingArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Build a home inventory'**
  String get onboardingArchiveTitle;

  /// No description provided for @onboardingArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'Add names, locations, and care schedules so every household item is easy to find.'**
  String get onboardingArchiveBody;

  /// No description provided for @onboardingEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the details with photos'**
  String get onboardingEvidenceTitle;

  /// No description provided for @onboardingEvidenceBody.
  ///
  /// In en, this message translates to:
  /// **'Photograph or choose manuals, warranty cards, and repair photos. Everything stays on this device.'**
  String get onboardingEvidenceBody;

  /// No description provided for @onboardingReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on schedule'**
  String get onboardingReminderTitle;

  /// No description provided for @onboardingReminderBody.
  ///
  /// In en, this message translates to:
  /// **'See upcoming tasks on your care calendar and receive on-device reminders before they are due.'**
  String get onboardingReminderBody;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start organizing'**
  String get onboardingStart;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @itemsTab.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsTab;

  /// No description provided for @scheduleTab.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTab;

  /// No description provided for @reportTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySaturday;

  /// No description provided for @calendarMonthYear.
  ///
  /// In en, this message translates to:
  /// **'{month}/{year}'**
  String calendarMonthYear(int year, int month);

  /// No description provided for @dateYmd.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}/{year}'**
  String dateYmd(int year, int month, int day);

  /// No description provided for @dateMonthDay.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String dateMonthDay(int month, int day);

  /// No description provided for @dateTodaySemantic.
  ///
  /// In en, this message translates to:
  /// **'{date}, today'**
  String dateTodaySemantic(String date);

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCamera;

  /// No description provided for @permissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionNotifications;

  /// No description provided for @permissionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'{permission} access is unavailable'**
  String permissionUnavailableTitle(String permission);

  /// No description provided for @permissionLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permissionLater;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// No description provided for @permissionOpenSettingsManually.
  ///
  /// In en, this message translates to:
  /// **'Open Settings manually and allow Hearthio to access {permission}.'**
  String permissionOpenSettingsManually(String permission);

  /// No description provided for @permissionStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The current {permission} permission status could not be read. Try again later, or check Settings if you previously disabled it.'**
  String permissionStatusUnavailable(String permission);

  /// No description provided for @permissionRequestIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The system could not complete the {permission} permission request. Try again, or check Settings if it remains unavailable.'**
  String permissionRequestIncomplete(String permission);

  /// No description provided for @permissionDeniedGuidance.
  ///
  /// In en, this message translates to:
  /// **'{permission} access is not enabled, so this feature is temporarily unavailable. Allow Hearthio to access {permission} in Settings, then try again.'**
  String permissionDeniedGuidance(String permission);

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'The privacy policy page is being prepared'**
  String get privacyPreparingTitle;

  /// No description provided for @privacyPreparingMessage.
  ///
  /// In en, this message translates to:
  /// **'The complete privacy policy will appear here after the production HTTPS address is configured.'**
  String get privacyPreparingMessage;

  /// No description provided for @privacyLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the privacy policy'**
  String get privacyLoadFailedTitle;

  /// No description provided for @privacyLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.\n{error}'**
  String privacyLoadFailedMessage(String error);

  /// No description provided for @privacyReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get privacyReload;

  /// No description provided for @privacyLocalFirstSummary.
  ///
  /// In en, this message translates to:
  /// **'Hearthio does not require an account. Item details, photos, maintenance records, and plans stay on this device by default. Files leave the app sandbox only when you choose to export, back up, or share them.'**
  String get privacyLocalFirstSummary;

  /// No description provided for @maintenanceStatePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get maintenanceStatePlanned;

  /// No description provided for @maintenanceStateDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get maintenanceStateDueSoon;

  /// No description provided for @maintenanceStateDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get maintenanceStateDueToday;

  /// No description provided for @maintenanceStateOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get maintenanceStateOverdue;

  /// No description provided for @maintenanceStateDeferred.
  ///
  /// In en, this message translates to:
  /// **'Reminder deferred'**
  String get maintenanceStateDeferred;

  /// No description provided for @maintenanceStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get maintenanceStateCompleted;

  /// No description provided for @maintenanceStateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get maintenanceStateDisabled;

  /// No description provided for @maintenanceDueDateUnset.
  ///
  /// In en, this message translates to:
  /// **'No due date set'**
  String get maintenanceDueDateUnset;

  /// No description provided for @maintenanceOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day overdue} other{{days} days overdue}}'**
  String maintenanceOverdueDays(int days);

  /// No description provided for @maintenanceDueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {days, plural, =1{1 day} other{{days} days}}'**
  String maintenanceDueInDays(int days);

  /// No description provided for @originalDueWithTiming.
  ///
  /// In en, this message translates to:
  /// **'Original due date {date} · {timing}'**
  String originalDueWithTiming(String date, String timing);

  /// No description provided for @deferredReminderStatus.
  ///
  /// In en, this message translates to:
  /// **'Remind on {date} · Original status: {status}'**
  String deferredReminderStatus(String date, String status);

  /// No description provided for @deferReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get deferReminder;

  /// No description provided for @editDeferredReminder.
  ///
  /// In en, this message translates to:
  /// **'Change reminder'**
  String get editDeferredReminder;

  /// No description provided for @startMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Start maintenance'**
  String get startMaintenance;

  /// No description provided for @maintenancePlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plans'**
  String get maintenancePlansTitle;

  /// No description provided for @addPlan.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get addPlan;

  /// No description provided for @planTemplateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Template intervals are references only. You can edit every field before saving; always follow the manufacturer\'s instructions first.'**
  String get planTemplateDisclaimer;

  /// No description provided for @archivedPlansCount.
  ///
  /// In en, this message translates to:
  /// **'Archived plans ({count})'**
  String archivedPlansCount(int count);

  /// No description provided for @archivedPlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Linked history is preserved and reminders are stopped'**
  String get archivedPlansSubtitle;

  /// No description provided for @intervalEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Every {days, plural, =1{day} other{{days} days}}'**
  String intervalEveryDays(int days);

  /// No description provided for @archivePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this plan?'**
  String get archivePlanTitle;

  /// No description provided for @deletePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this plan?'**
  String get deletePlanTitle;

  /// No description provided for @archivePlanMessage.
  ///
  /// In en, this message translates to:
  /// **'“{title}” has maintenance records. Archiving stops reminders but preserves the history.'**
  String archivePlanMessage(String title);

  /// No description provided for @deletePlanMessage.
  ///
  /// In en, this message translates to:
  /// **'“{title}” has no maintenance records. Deletion cannot be undone.'**
  String deletePlanMessage(String title);

  /// No description provided for @confirmArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get confirmArchive;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDelete;

  /// No description provided for @noMaintenancePlans.
  ///
  /// In en, this message translates to:
  /// **'No maintenance plans yet'**
  String get noMaintenancePlans;

  /// No description provided for @noMaintenancePlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start from a template or create a completely custom task.'**
  String get noMaintenancePlansSubtitle;

  /// No description provided for @planEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get planEnabled;

  /// No description provided for @planDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get planDisabled;

  /// No description provided for @planScheduleSummary.
  ///
  /// In en, this message translates to:
  /// **'{state} · Every {interval} days · Remind {lead} days early'**
  String planScheduleSummary(String state, int interval, int lead);

  /// No description provided for @planNextSummary.
  ///
  /// In en, this message translates to:
  /// **'Next: {date} · {count, plural, =1{1 step} other{{count} steps}}'**
  String planNextSummary(String date, int count);

  /// No description provided for @editPlanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit {title}'**
  String editPlanTooltip(String title);

  /// No description provided for @removePlanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete or archive {title}'**
  String removePlanTooltip(String title);

  /// No description provided for @selectMaintenanceTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose a maintenance template'**
  String get selectMaintenanceTemplate;

  /// No description provided for @templatePickerDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Templates are editable starting points, not mandatory safety intervals. Follow the manufacturer\'s instructions.'**
  String get templatePickerDisclaimer;

  /// No description provided for @customTemplateDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the name, interval, and steps yourself'**
  String get customTemplateDescription;

  /// No description provided for @templateDefaultSummary.
  ///
  /// In en, this message translates to:
  /// **'Default: {days} days · {steps}'**
  String templateDefaultSummary(int days, String steps);

  /// No description provided for @editMaintenancePlan.
  ///
  /// In en, this message translates to:
  /// **'Edit maintenance plan'**
  String get editMaintenancePlan;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get savePlan;

  /// No description provided for @planNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan name *'**
  String get planNameLabel;

  /// No description provided for @enablePlan.
  ///
  /// In en, this message translates to:
  /// **'Enable plan'**
  String get enablePlan;

  /// No description provided for @disablePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disabling preserves the plan and history but stops reminders'**
  String get disablePlanSubtitle;

  /// No description provided for @intervalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval (days) *'**
  String get intervalDaysLabel;

  /// No description provided for @reminderLeadDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind early (days) *'**
  String get reminderLeadDaysLabel;

  /// No description provided for @lastCompletedOptional.
  ///
  /// In en, this message translates to:
  /// **'Last completed (optional)'**
  String get lastCompletedOptional;

  /// No description provided for @firstOrNextDueDate.
  ///
  /// In en, this message translates to:
  /// **'First / next due date'**
  String get firstOrNextDueDate;

  /// No description provided for @nextDatePreview.
  ///
  /// In en, this message translates to:
  /// **'Next date preview'**
  String get nextDatePreview;

  /// No description provided for @completeScheduleForPreview.
  ///
  /// In en, this message translates to:
  /// **'Complete the interval and date to see a preview'**
  String get completeScheduleForPreview;

  /// No description provided for @nextDateReminderPreview.
  ///
  /// In en, this message translates to:
  /// **'{date} · Remind {days} days early'**
  String nextDateReminderPreview(String date, String days);

  /// No description provided for @executionSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get executionSteps;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @optionalStepsHint.
  ///
  /// In en, this message translates to:
  /// **'Steps are optional. Add them one at a time and edit them before saving.'**
  String get optionalStepsHint;

  /// No description provided for @stepRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter step details'**
  String get stepRequired;

  /// No description provided for @stepContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Step details'**
  String get stepContentLabel;

  /// No description provided for @deleteStepTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete step {number}'**
  String deleteStepTooltip(int number);

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @validationPlanNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a plan name'**
  String get validationPlanNameRequired;

  /// No description provided for @validationPlanNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Plan names cannot exceed 40 characters'**
  String get validationPlanNameTooLong;

  /// No description provided for @validationIntervalInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole-number interval'**
  String get validationIntervalInteger;

  /// No description provided for @validationIntervalRange.
  ///
  /// In en, this message translates to:
  /// **'The interval must be between {min} and {max} days'**
  String validationIntervalRange(int min, int max);

  /// No description provided for @validationDaysInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of days'**
  String get validationDaysInteger;

  /// No description provided for @validationReminderRange.
  ///
  /// In en, this message translates to:
  /// **'Reminder lead time must be between 0 and {max} days'**
  String validationReminderRange(int max);

  /// No description provided for @validationReminderAfterInterval.
  ///
  /// In en, this message translates to:
  /// **'Reminder lead time cannot exceed the maintenance interval'**
  String get validationReminderAfterInterval;

  /// No description provided for @validationPlanDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the last completion date or first due date'**
  String get validationPlanDateRequired;

  /// No description provided for @validationPlanDateRange.
  ///
  /// In en, this message translates to:
  /// **'The date must be between 2000 and 2100'**
  String get validationPlanDateRange;

  /// No description provided for @validationDueBeforeCompletion.
  ///
  /// In en, this message translates to:
  /// **'The due date cannot be earlier than the last completion date'**
  String get validationDueBeforeCompletion;

  /// No description provided for @templateSceneAirConditioner.
  ///
  /// In en, this message translates to:
  /// **'Air conditioner'**
  String get templateSceneAirConditioner;

  /// No description provided for @templateTitleCleanFilter.
  ///
  /// In en, this message translates to:
  /// **'Clean filter'**
  String get templateTitleCleanFilter;

  /// No description provided for @templateSceneWaterPurifier.
  ///
  /// In en, this message translates to:
  /// **'Water purifier'**
  String get templateSceneWaterPurifier;

  /// No description provided for @templateTitleReplaceFilter.
  ///
  /// In en, this message translates to:
  /// **'Replace filter'**
  String get templateTitleReplaceFilter;

  /// No description provided for @templateSceneWasher.
  ///
  /// In en, this message translates to:
  /// **'Washing machine'**
  String get templateSceneWasher;

  /// No description provided for @templateTitleCleanDrum.
  ///
  /// In en, this message translates to:
  /// **'Clean drum'**
  String get templateTitleCleanDrum;

  /// No description provided for @templateSceneFridge.
  ///
  /// In en, this message translates to:
  /// **'Refrigerator'**
  String get templateSceneFridge;

  /// No description provided for @templateTitleCleanCondenser.
  ///
  /// In en, this message translates to:
  /// **'Clean condenser area'**
  String get templateTitleCleanCondenser;

  /// No description provided for @templateSceneSmokeAlarm.
  ///
  /// In en, this message translates to:
  /// **'Smoke alarm'**
  String get templateSceneSmokeAlarm;

  /// No description provided for @templateTitleTestBattery.
  ///
  /// In en, this message translates to:
  /// **'Test battery'**
  String get templateTitleTestBattery;

  /// No description provided for @templateSceneCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get templateSceneCustom;

  /// No description provided for @templateTitleCustomTask.
  ///
  /// In en, this message translates to:
  /// **'Custom task'**
  String get templateTitleCustomTask;

  /// No description provided for @stepPowerOff.
  ///
  /// In en, this message translates to:
  /// **'Power off'**
  String get stepPowerOff;

  /// No description provided for @stepDisassemble.
  ///
  /// In en, this message translates to:
  /// **'Disassemble'**
  String get stepDisassemble;

  /// No description provided for @stepClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get stepClean;

  /// No description provided for @stepDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get stepDry;

  /// No description provided for @stepReassemble.
  ///
  /// In en, this message translates to:
  /// **'Reassemble'**
  String get stepReassemble;

  /// No description provided for @stepVerifyModel.
  ///
  /// In en, this message translates to:
  /// **'Verify model'**
  String get stepVerifyModel;

  /// No description provided for @stepShutOffWater.
  ///
  /// In en, this message translates to:
  /// **'Shut off water'**
  String get stepShutOffWater;

  /// No description provided for @stepReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get stepReplace;

  /// No description provided for @stepFlush.
  ///
  /// In en, this message translates to:
  /// **'Flush'**
  String get stepFlush;

  /// No description provided for @stepEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get stepEmpty;

  /// No description provided for @stepAddCleaner.
  ///
  /// In en, this message translates to:
  /// **'Add cleaner'**
  String get stepAddCleaner;

  /// No description provided for @stepRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get stepRun;

  /// No description provided for @stepWipeDry.
  ///
  /// In en, this message translates to:
  /// **'Wipe dry'**
  String get stepWipeDry;

  /// No description provided for @stepRemoveDust.
  ///
  /// In en, this message translates to:
  /// **'Remove dust'**
  String get stepRemoveDust;

  /// No description provided for @stepCheckVentilation.
  ///
  /// In en, this message translates to:
  /// **'Check ventilation'**
  String get stepCheckVentilation;

  /// No description provided for @stepReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get stepReset;

  /// No description provided for @stepTestAlarm.
  ///
  /// In en, this message translates to:
  /// **'Test alarm'**
  String get stepTestAlarm;

  /// No description provided for @stepCheckBattery.
  ///
  /// In en, this message translates to:
  /// **'Check battery'**
  String get stepCheckBattery;

  /// No description provided for @stepRecordResult.
  ///
  /// In en, this message translates to:
  /// **'Record result'**
  String get stepRecordResult;

  /// No description provided for @stepDescriptionVerifyFilter.
  ///
  /// In en, this message translates to:
  /// **'Confirm the water purifier model and compatible filter'**
  String get stepDescriptionVerifyFilter;

  /// No description provided for @stepDescriptionShutOffWater.
  ///
  /// In en, this message translates to:
  /// **'Close the inlet valve and make sure the water has stopped'**
  String get stepDescriptionShutOffWater;

  /// No description provided for @stepDescriptionReplaceFilter.
  ///
  /// In en, this message translates to:
  /// **'Remove the old filter and install the new one'**
  String get stepDescriptionReplaceFilter;

  /// No description provided for @stepDescriptionFlushFilter.
  ///
  /// In en, this message translates to:
  /// **'Open the water supply and flush until the water runs clear'**
  String get stepDescriptionFlushFilter;

  /// No description provided for @editMaintenanceRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit maintenance record'**
  String get editMaintenanceRecord;

  /// No description provided for @linkedPlan.
  ///
  /// In en, this message translates to:
  /// **'Linked plan'**
  String get linkedPlan;

  /// No description provided for @originalPlanUnavailableSuffix.
  ///
  /// In en, this message translates to:
  /// **' (original plan unavailable)'**
  String get originalPlanUnavailableSuffix;

  /// No description provided for @recordPlanLinkImmutable.
  ///
  /// In en, this message translates to:
  /// **'The record\'s link to its original plan cannot be changed while editing.'**
  String get recordPlanLinkImmutable;

  /// No description provided for @recordCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost (CNY)'**
  String get recordCostLabel;

  /// No description provided for @optionalZeroCostHint.
  ///
  /// In en, this message translates to:
  /// **'Optional; saved as CNY 0 when blank'**
  String get optionalZeroCostHint;

  /// No description provided for @materialNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Material name / model'**
  String get materialNameLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @recordHasNoSteps.
  ///
  /// In en, this message translates to:
  /// **'This record has no step data.'**
  String get recordHasNoSteps;

  /// No description provided for @historicalStepIdsOnly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 historical step ID was preserved, but its original details are unavailable.} other{{count} historical step IDs were preserved, but their original details are unavailable.}}'**
  String historicalStepIdsOnly(int count);

  /// No description provided for @beforePhotos.
  ///
  /// In en, this message translates to:
  /// **'Before photos'**
  String get beforePhotos;

  /// No description provided for @afterPhotos.
  ///
  /// In en, this message translates to:
  /// **'After photos'**
  String get afterPhotos;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get saveRecord;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get chooseFromPhotos;

  /// No description provided for @cameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the camera. Check camera access and try again.'**
  String get cameraOpenFailed;

  /// No description provided for @photoReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to read the photo. Check photo access and try again.'**
  String get photoReadFailed;

  /// No description provided for @maintenanceRecordSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The maintenance record could not be saved. Try again.'**
  String get maintenanceRecordSaveFailed;

  /// No description provided for @actualCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'Actual completion date'**
  String get actualCompletionDate;

  /// No description provided for @noPhotosAdded.
  ///
  /// In en, this message translates to:
  /// **'No photos added'**
  String get noPhotosAdded;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @validationNonNegativeAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than or equal to 0'**
  String get validationNonNegativeAmount;

  /// No description provided for @executionNoPresetSteps.
  ///
  /// In en, this message translates to:
  /// **'This plan has no preset steps. You can record the result directly.'**
  String get executionNoPresetSteps;

  /// No description provided for @optionalRecordSection.
  ///
  /// In en, this message translates to:
  /// **'This record (optional)'**
  String get optionalRecordSection;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @materialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get materialLabel;

  /// No description provided for @modelOrName.
  ///
  /// In en, this message translates to:
  /// **'Model/name'**
  String get modelOrName;

  /// No description provided for @completedField.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedField;

  /// No description provided for @recordCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Record cost'**
  String get recordCostTitle;

  /// No description provided for @recordMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Record material'**
  String get recordMaterialTitle;

  /// No description provided for @materialExample.
  ///
  /// In en, this message translates to:
  /// **'For example: PP filter A1'**
  String get materialExample;

  /// No description provided for @addNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add notes'**
  String get addNotesTitle;

  /// No description provided for @notesHelper.
  ///
  /// In en, this message translates to:
  /// **'Record issues, observations, or anything to remember next time'**
  String get notesHelper;

  /// No description provided for @beforePhotoCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Before-maintenance photos'**
  String get beforePhotoCaptureTitle;

  /// No description provided for @afterPhotoCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'After-maintenance photos'**
  String get afterPhotoCaptureTitle;

  /// No description provided for @beforePhotosLocked.
  ///
  /// In en, this message translates to:
  /// **'Maintenance has started, so before photos are locked.'**
  String get beforePhotosLocked;

  /// No description provided for @afterPhotosTemporarilyLocked.
  ///
  /// In en, this message translates to:
  /// **'A step was reopened, so after photos are temporarily locked.'**
  String get afterPhotosTemporarilyLocked;

  /// No description provided for @maintenanceCompletionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'This maintenance record could not be saved. Try again.'**
  String get maintenanceCompletionSaveFailed;

  /// No description provided for @maintenanceCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance complete'**
  String get maintenanceCompletedTitle;

  /// No description provided for @maintenanceArchived.
  ///
  /// In en, this message translates to:
  /// **'This maintenance has been archived'**
  String get maintenanceArchived;

  /// No description provided for @completionTime.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completionTime;

  /// No description provided for @thisCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get thisCost;

  /// No description provided for @nextPlan.
  ///
  /// In en, this message translates to:
  /// **'Next plan'**
  String get nextPlan;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderDaysEarly.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day early} other{{days} days early}}'**
  String reminderDaysEarly(int days);

  /// No description provided for @completionLifecycleHint.
  ///
  /// In en, this message translates to:
  /// **'Open this item\'s lifecycle to review this record, cumulative cost, and the next task.'**
  String get completionLifecycleHint;

  /// No description provided for @notificationRescheduleFailed.
  ///
  /// In en, this message translates to:
  /// **'The record and next date were saved, but the notification could not be rescheduled. Check notification access in Settings and try again.'**
  String get notificationRescheduleFailed;

  /// No description provided for @viewLifecycle.
  ///
  /// In en, this message translates to:
  /// **'View lifecycle'**
  String get viewLifecycle;

  /// No description provided for @originalPlanDate.
  ///
  /// In en, this message translates to:
  /// **'Original plan date {date}'**
  String originalPlanDate(String date);

  /// No description provided for @photosRecordedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo recorded} other{{count} photos recorded}}'**
  String photosRecordedCount(int count);

  /// No description provided for @noPhotosThisTime.
  ///
  /// In en, this message translates to:
  /// **'No photos this time'**
  String get noPhotosThisTime;

  /// No description provided for @beforePhotoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Record the current state for comparison after completion'**
  String get beforePhotoPrompt;

  /// No description provided for @beforePhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Before photos (optional)'**
  String get beforePhotoOptional;

  /// No description provided for @beforePhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Before-maintenance photos, optional, {status}{locked}'**
  String beforePhotoSemantic(String status, String locked);

  /// No description provided for @beforePhotoLockedSemanticSuffix.
  ///
  /// In en, this message translates to:
  /// **', maintenance has started and before photos are locked'**
  String get beforePhotoLockedSemanticSuffix;

  /// No description provided for @afterPhotoReadyHint.
  ///
  /// In en, this message translates to:
  /// **'All steps are complete. Record the final state for comparison'**
  String get afterPhotoReadyHint;

  /// No description provided for @afterPhotoReopenedHint.
  ///
  /// In en, this message translates to:
  /// **'A step was reopened. Complete it to manage after photos again'**
  String get afterPhotoReopenedHint;

  /// No description provided for @afterPhotoWaitingHint.
  ///
  /// In en, this message translates to:
  /// **'Complete all steps to add after photos'**
  String get afterPhotoWaitingHint;

  /// No description provided for @afterPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'After photos (optional)'**
  String get afterPhotoOptional;

  /// No description provided for @afterPhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'After-maintenance photos, optional, {status}'**
  String afterPhotoSemantic(String status);

  /// No description provided for @beforeLabel.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get beforeLabel;

  /// No description provided for @afterLabel.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get afterLabel;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @waitingForCompletion.
  ///
  /// In en, this message translates to:
  /// **'Waiting for completion'**
  String get waitingForCompletion;

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String photoCount(int count);

  /// No description provided for @stepSemantic.
  ///
  /// In en, this message translates to:
  /// **'Step {number}: {title}{description}{state}'**
  String stepSemantic(
    int number,
    String title,
    String description,
    String state,
  );

  /// No description provided for @stepDescriptionSemantic.
  ///
  /// In en, this message translates to:
  /// **', {description}'**
  String stepDescriptionSemantic(String description);

  /// No description provided for @currentStepSemantic.
  ///
  /// In en, this message translates to:
  /// **', current step'**
  String get currentStepSemantic;

  /// No description provided for @completedStepSemantic.
  ///
  /// In en, this message translates to:
  /// **', completed'**
  String get completedStepSemantic;

  /// No description provided for @completeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Complete maintenance'**
  String get completeMaintenance;

  /// No description provided for @validationFiniteNonNegativeAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a finite amount greater than or equal to 0'**
  String get validationFiniteNonNegativeAmount;

  /// No description provided for @lifecycleOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle overview'**
  String get lifecycleOverviewTitle;

  /// No description provided for @lifecycleUsageDuration.
  ///
  /// In en, this message translates to:
  /// **'Time in use'**
  String get lifecycleUsageDuration;

  /// No description provided for @lifecyclePurchaseDateMissing.
  ///
  /// In en, this message translates to:
  /// **'Purchase date not entered'**
  String get lifecyclePurchaseDateMissing;

  /// No description provided for @lifecyclePurchaseDateFuture.
  ///
  /// In en, this message translates to:
  /// **'Purchase date is in the future'**
  String get lifecyclePurchaseDateFuture;

  /// No description provided for @lifecycleUsageDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String lifecycleUsageDays(int count);

  /// No description provided for @lifecycleMaintenanceTotal.
  ///
  /// In en, this message translates to:
  /// **'Maintenance completed'**
  String get lifecycleMaintenanceTotal;

  /// No description provided for @lifecycleCompletionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String lifecycleCompletionCount(int count);

  /// No description provided for @lifecycleActualCost.
  ///
  /// In en, this message translates to:
  /// **'Actual cost'**
  String get lifecycleActualCost;

  /// No description provided for @lifecycleCurrentOverdue.
  ///
  /// In en, this message translates to:
  /// **'Currently overdue'**
  String get lifecycleCurrentOverdue;

  /// No description provided for @lifecycleOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String lifecycleOverdueCount(int count);

  /// No description provided for @lifecycleNextTask.
  ///
  /// In en, this message translates to:
  /// **'Next task'**
  String get lifecycleNextTask;

  /// No description provided for @lifecycleNoNextTask.
  ///
  /// In en, this message translates to:
  /// **'No enabled plan with a date'**
  String get lifecycleNoNextTask;

  /// No description provided for @lifecycleNextTaskSummary.
  ///
  /// In en, this message translates to:
  /// **'{title} · {date} · {timing}'**
  String lifecycleNextTaskSummary(String title, String date, String timing);

  /// No description provided for @lifecycleTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle timeline'**
  String get lifecycleTimelineTitle;

  /// No description provided for @lifecycleTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows the purchase date and actual maintenance records you entered, newest first.'**
  String get lifecycleTimelineSubtitle;

  /// No description provided for @lifecycleTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lifecycle events yet. Enter a purchase date or complete maintenance to build a traceable history.'**
  String get lifecycleTimelineEmpty;

  /// No description provided for @deleteRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this maintenance record?'**
  String get deleteRecordTitle;

  /// No description provided for @deleteRecordMessageNoPlan.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Photos in this record will also be removed from this device.'**
  String get deleteRecordMessageNoPlan;

  /// No description provided for @deleteRecordMessageWithPlan.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. The last completion date and next date will be recalculated from the remaining records for “{title}”. Record photos will also be removed from this device.'**
  String deleteRecordMessageWithPlan(String title);

  /// No description provided for @deleteRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'The maintenance record could not be deleted. Try again.'**
  String get deleteRecordFailed;

  /// No description provided for @purchaseStartingPoint.
  ///
  /// In en, this message translates to:
  /// **'Purchase starting point'**
  String get purchaseStartingPoint;

  /// No description provided for @purchaseStartingPointDescription.
  ///
  /// In en, this message translates to:
  /// **'Based on the purchase date entered in the item details.'**
  String get purchaseStartingPointDescription;

  /// No description provided for @recordPlanUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked to a plan'**
  String get recordPlanUnlinked;

  /// No description provided for @recordPlanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original plan unavailable'**
  String get recordPlanUnavailable;

  /// No description provided for @recordTitleWithPlanState.
  ///
  /// In en, this message translates to:
  /// **'{title} · {state}'**
  String recordTitleWithPlanState(String title, String state);

  /// No description provided for @editRecordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get editRecordTooltip;

  /// No description provided for @deleteRecordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get deleteRecordTooltip;

  /// No description provided for @recordExpense.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get recordExpense;

  /// No description provided for @recordMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get recordMaterial;

  /// No description provided for @recordNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get recordNotes;

  /// No description provided for @recordStepsMissing.
  ///
  /// In en, this message translates to:
  /// **'Steps: not recorded'**
  String get recordStepsMissing;

  /// No description provided for @recordStepsProgress.
  ///
  /// In en, this message translates to:
  /// **'Steps: {completed} of {total} completed'**
  String recordStepsProgress(int completed, int total);

  /// No description provided for @recordPhotosMissing.
  ///
  /// In en, this message translates to:
  /// **'Photos: not recorded'**
  String get recordPhotosMissing;

  /// No description provided for @recordPhotoGroup.
  ///
  /// In en, this message translates to:
  /// **'{title} · {count, plural, =1{1 photo} other{{count} photos}}'**
  String recordPhotoGroup(String title, int count);

  /// No description provided for @reportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Home care report'**
  String get reportPageTitle;

  /// No description provided for @reportPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based only on actual plans, completed records, and real costs'**
  String get reportPageSubtitle;

  /// No description provided for @reportEmptyNotice.
  ///
  /// In en, this message translates to:
  /// **'No completed records yet. Complete maintenance to see actual costs and completion details here; overdue and upcoming tasks are still counted from current plans.'**
  String get reportEmptyNotice;

  /// No description provided for @reportCurrentTasks.
  ///
  /// In en, this message translates to:
  /// **'Current tasks'**
  String get reportCurrentTasks;

  /// No description provided for @reportCurrentTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculated live by local calendar date'**
  String get reportCurrentTasksSubtitle;

  /// No description provided for @reportCurrentYearMaintenance.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get reportCurrentYearMaintenance;

  /// No description provided for @reportTrailingYearMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get reportTrailingYearMaintenance;

  /// No description provided for @reportCurrentYearCostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Actual costs from records completed in this calendar year'**
  String get reportCurrentYearCostSubtitle;

  /// No description provided for @reportTrailingYearCostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cost and completion rate use the same calendar-month range'**
  String get reportTrailingYearCostSubtitle;

  /// No description provided for @reportActualMaintenanceCost.
  ///
  /// In en, this message translates to:
  /// **'Actual maintenance cost'**
  String get reportActualMaintenanceCost;

  /// No description provided for @reportCostRangeDescription.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}; includes only actual costs from completed records.'**
  String reportCostRangeDescription(String start, String end);

  /// No description provided for @reportIgnoredCostCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invalid cost was excluded.} other{{count} invalid costs were excluded.}}'**
  String reportIgnoredCostCount(int count);

  /// No description provided for @reportCostBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Where the money went'**
  String get reportCostBreakdown;

  /// No description provided for @reportCostBreakdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch grouping without counting the total twice'**
  String get reportCostBreakdownSubtitle;

  /// No description provided for @reportItemBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Item details'**
  String get reportItemBreakdown;

  /// No description provided for @reportCategoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category summary'**
  String get reportCategoryBreakdown;

  /// No description provided for @reportNoItemCosts.
  ///
  /// In en, this message translates to:
  /// **'No maintenance records with costs'**
  String get reportNoItemCosts;

  /// No description provided for @reportNoCategoryCosts.
  ///
  /// In en, this message translates to:
  /// **'No category costs to summarize'**
  String get reportNoCategoryCosts;

  /// No description provided for @reportRecentRecords.
  ///
  /// In en, this message translates to:
  /// **'Recent maintenance records'**
  String get reportRecentRecords;

  /// No description provided for @reportRecentRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every amount links back to an actual completion record'**
  String get reportRecentRecordsSubtitle;

  /// No description provided for @reportGroupingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Cost breakdown grouping'**
  String get reportGroupingSemantic;

  /// No description provided for @reportGroupByItem.
  ///
  /// In en, this message translates to:
  /// **'By item'**
  String get reportGroupByItem;

  /// No description provided for @reportGroupByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get reportGroupByCategory;

  /// No description provided for @reportScopeCurrentYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get reportScopeCurrentYear;

  /// No description provided for @reportScopeTrailingYear.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get reportScopeTrailingYear;

  /// No description provided for @reportCurrentYearMethodology.
  ///
  /// In en, this message translates to:
  /// **'Method: This month uses completion dates; overdue days are calendar days between today and the original due date; the next 30 days include today; this-year costs cover {start} to {end}.'**
  String reportCurrentYearMethodology(String start, String end);

  /// No description provided for @reportTrailingYearMethodology.
  ///
  /// In en, this message translates to:
  /// **'Method: This month uses completion dates; overdue days are calendar days between today and the original due date; the next 30 days include today; cost and on-time rate cover {start} to {end}.'**
  String reportTrailingYearMethodology(String start, String end);

  /// No description provided for @reportCompletedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Completed this month'**
  String get reportCompletedThisMonth;

  /// No description provided for @reportCurrentOverdue.
  ///
  /// In en, this message translates to:
  /// **'Currently overdue'**
  String get reportCurrentOverdue;

  /// No description provided for @reportCumulativeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Total overdue days'**
  String get reportCumulativeOverdue;

  /// No description provided for @reportDueNextThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'Due in the next 30 days'**
  String get reportDueNextThirtyDays;

  /// No description provided for @reportItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String reportItemCount(int count);

  /// No description provided for @reportDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String reportDayCount(int count);

  /// No description provided for @reportNoEligibleOnTimeRecords.
  ///
  /// In en, this message translates to:
  /// **'No on-time records can be recalculated. Older records or records without an original due date are not assumed to be on time.'**
  String get reportNoEligibleOnTimeRecords;

  /// No description provided for @reportOnTimeExplanation.
  ///
  /// In en, this message translates to:
  /// **'On time: {onTime} / eligible: {eligible}. A record is on time when its completion date is no later than its stored original due date.'**
  String reportOnTimeExplanation(int onTime, int eligible);

  /// No description provided for @reportOnTimeRate.
  ///
  /// In en, this message translates to:
  /// **'On-time completion rate'**
  String get reportOnTimeRate;

  /// No description provided for @reportExcludedCompletionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record is missing its original due date and was excluded from the completion rate.} other{{count} records are missing their original due dates and were excluded from the completion rate.}}'**
  String reportExcludedCompletionCount(int count);

  /// No description provided for @reportRecordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{item} · {date}'**
  String reportRecordSubtitle(String item, String date);

  /// No description provided for @notificationPrimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on maintenance reminders?'**
  String get notificationPrimerTitle;

  /// No description provided for @notificationPrimerMessage.
  ///
  /// In en, this message translates to:
  /// **'Hearthio can send on-device notifications using each plan’s reminder lead time.\n\nDeclining does not affect items or maintenance plans. You can enable notifications later in Settings.'**
  String get notificationPrimerMessage;

  /// No description provided for @notificationNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notificationNotNow;

  /// No description provided for @notificationEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationEnable;

  /// No description provided for @dateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get dateNotSet;

  /// No description provided for @deferTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get deferTitle;

  /// No description provided for @deferTaskDescription.
  ///
  /// In en, this message translates to:
  /// **'{item} · {plan}\nOriginal due date: {date}. Deferring the reminder does not change the actual due status.'**
  String deferTaskDescription(String item, String plan, String date);

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @inThreeDays.
  ///
  /// In en, this message translates to:
  /// **'In 3 days'**
  String get inThreeDays;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @customDate.
  ///
  /// In en, this message translates to:
  /// **'Custom date'**
  String get customDate;

  /// No description provided for @deferFailed.
  ///
  /// In en, this message translates to:
  /// **'The reminder could not be deferred. Try again.'**
  String get deferFailed;

  /// No description provided for @notificationItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The item for this reminder was deleted. Showing the maintenance schedule instead.'**
  String get notificationItemUnavailable;

  /// No description provided for @notificationPlanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The maintenance plan for this reminder was deleted or disabled. Showing the maintenance schedule instead.'**
  String get notificationPlanUnavailable;

  /// No description provided for @notificationMalformed.
  ///
  /// In en, this message translates to:
  /// **'This maintenance reminder is no longer valid. Showing the maintenance schedule instead.'**
  String get notificationMalformed;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @dashboardNextMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Next maintenance'**
  String get dashboardNextMaintenance;

  /// No description provided for @dashboardHouseholdOverview.
  ///
  /// In en, this message translates to:
  /// **'Home overview'**
  String get dashboardHouseholdOverview;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Hearthio'**
  String get dashboardTitle;

  /// No description provided for @dashboardDate.
  ///
  /// In en, this message translates to:
  /// **'{date} · {weekday}'**
  String dashboardDate(String date, String weekday);

  /// No description provided for @dashboardNoDueTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks due'**
  String get dashboardNoDueTasks;

  /// No description provided for @dashboardAttentionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task needs attention} other{{count} tasks need attention}}'**
  String dashboardAttentionCount(int count);

  /// No description provided for @dashboardAllOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Everything at home is on schedule'**
  String get dashboardAllOnTrack;

  /// No description provided for @dashboardStartWithUrgent.
  ///
  /// In en, this message translates to:
  /// **'Start with the most urgent task'**
  String get dashboardStartWithUrgent;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardViewSchedule.
  ///
  /// In en, this message translates to:
  /// **'View schedule'**
  String get dashboardViewSchedule;

  /// No description provided for @dashboardOriginalDueDate.
  ///
  /// In en, this message translates to:
  /// **'Original due date {date}'**
  String dashboardOriginalDueDate(String date);

  /// No description provided for @dashboardDeferredStatus.
  ///
  /// In en, this message translates to:
  /// **'Remind on {date} · Original status: {status}'**
  String dashboardDeferredStatus(String date, String status);

  /// No description provided for @dashboardItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get dashboardItems;

  /// No description provided for @dashboardSpaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get dashboardSpaces;

  /// No description provided for @dashboardThisYearMaintenance.
  ///
  /// In en, this message translates to:
  /// **'This-year care'**
  String get dashboardThisYearMaintenance;

  /// No description provided for @dashboardAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get dashboardAssets;

  /// No description provided for @dashboardItemsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Items, {count}; view all items'**
  String dashboardItemsSemantic(int count);

  /// No description provided for @dashboardSpacesSemantic.
  ///
  /// In en, this message translates to:
  /// **'Spaces, {count}; view home spaces'**
  String dashboardSpacesSemantic(int count);

  /// No description provided for @dashboardAnnualCostSemantic.
  ///
  /// In en, this message translates to:
  /// **'This-year care, CNY {amount}; view the annual maintenance report'**
  String dashboardAnnualCostSemantic(String amount);

  /// No description provided for @dashboardAssetsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Assets, CNY {amount}; view asset valuations'**
  String dashboardAssetsSemantic(String amount);

  /// No description provided for @emptyMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with your first plan'**
  String get emptyMaintenanceTitle;

  /// No description provided for @emptyMaintenanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an item and a maintenance interval. Hearthio will remind you before it is due.'**
  String get emptyMaintenanceSubtitle;

  /// No description provided for @createMaintenancePlan.
  ///
  /// In en, this message translates to:
  /// **'Create maintenance plan'**
  String get createMaintenancePlan;

  /// No description provided for @spacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Home spaces'**
  String get spacesTitle;

  /// No description provided for @addSpace.
  ///
  /// In en, this message translates to:
  /// **'Add space'**
  String get addSpace;

  /// No description provided for @spacesDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize item locations by actual room; add the precise position inside each room yourself.'**
  String get spacesDescription;

  /// No description provided for @spacesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No home spaces yet'**
  String get spacesEmptyTitle;

  /// No description provided for @spacesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add actual rooms such as a living room, bedroom, or kitchen, then select them when editing items.'**
  String get spacesEmptySubtitle;

  /// No description provided for @unassignedSpace.
  ///
  /// In en, this message translates to:
  /// **'Space not set'**
  String get unassignedSpace;

  /// No description provided for @awaitingClassification.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get awaitingClassification;

  /// No description provided for @spaceItemCount.
  ///
  /// In en, this message translates to:
  /// **'{type} · {count, plural, =1{1 item} other{{count} items}}'**
  String spaceItemCount(String type, int count);

  /// No description provided for @manageSpace.
  ///
  /// In en, this message translates to:
  /// **'Manage space'**
  String get manageSpace;

  /// No description provided for @renameSpace.
  ///
  /// In en, this message translates to:
  /// **'Rename space'**
  String get renameSpace;

  /// No description provided for @deleteSpace.
  ///
  /// In en, this message translates to:
  /// **'Delete space'**
  String get deleteSpace;

  /// No description provided for @spaceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Space deleted'**
  String get spaceDeleted;

  /// No description provided for @addItemToSpace.
  ///
  /// In en, this message translates to:
  /// **'Add an item to this space'**
  String get addItemToSpace;

  /// No description provided for @noUnassignedItems.
  ///
  /// In en, this message translates to:
  /// **'No unassigned items'**
  String get noUnassignedItems;

  /// No description provided for @spaceHasNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items in this space'**
  String get spaceHasNoItems;

  /// No description provided for @editSpace.
  ///
  /// In en, this message translates to:
  /// **'Edit space'**
  String get editSpace;

  /// No description provided for @spaceType.
  ///
  /// In en, this message translates to:
  /// **'Space type'**
  String get spaceType;

  /// No description provided for @spaceActualName.
  ///
  /// In en, this message translates to:
  /// **'Actual name'**
  String get spaceActualName;

  /// No description provided for @spaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Primary bedroom, guest room, kids’ room'**
  String get spaceNameHint;

  /// No description provided for @spaceNameHelper.
  ///
  /// In en, this message translates to:
  /// **'The type is used for grouping; the actual name appears as the item location.'**
  String get spaceNameHelper;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @spaceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a space name'**
  String get spaceNameRequired;

  /// No description provided for @spaceNameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A space with this actual name already exists. If you have more than one similar space, change the actual name to tell them apart.'**
  String get spaceNameAlreadyExists;

  /// No description provided for @spaceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The space could not be saved. Try again.'**
  String get spaceSaveFailed;

  /// No description provided for @selectSpace.
  ///
  /// In en, this message translates to:
  /// **'Choose a space'**
  String get selectSpace;

  /// No description provided for @organizeLater.
  ///
  /// In en, this message translates to:
  /// **'Organize later'**
  String get organizeLater;

  /// No description provided for @deleteSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this space?'**
  String get deleteSpaceTitle;

  /// No description provided for @deleteEmptySpaceMessage.
  ///
  /// In en, this message translates to:
  /// **'“{name}” has no items and can be deleted directly.'**
  String deleteEmptySpaceMessage(String name);

  /// No description provided for @relocateSpaceItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Relocate {count, plural, =1{1 item} other{{count} items}} first'**
  String relocateSpaceItemsTitle(int count);

  /// No description provided for @relocateSpaceItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'After deleting “{name}”, move these items to another space or leave their space unset.'**
  String relocateSpaceItemsMessage(String name);

  /// No description provided for @setUnassignedSpace.
  ///
  /// In en, this message translates to:
  /// **'Leave space unset'**
  String get setUnassignedSpace;

  /// No description provided for @moveToSpace.
  ///
  /// In en, this message translates to:
  /// **'Move to {name}'**
  String moveToSpace(String name);

  /// No description provided for @spaceDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The space could not be deleted. Your data was not changed.'**
  String get spaceDeleteFailed;

  /// No description provided for @spaceTypeLivingRoom.
  ///
  /// In en, this message translates to:
  /// **'Living room'**
  String get spaceTypeLivingRoom;

  /// No description provided for @spaceTypeBedroom.
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get spaceTypeBedroom;

  /// No description provided for @spaceTypeKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get spaceTypeKitchen;

  /// No description provided for @spaceTypeBathroom.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get spaceTypeBathroom;

  /// No description provided for @spaceTypeBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get spaceTypeBalcony;

  /// No description provided for @spaceTypeStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get spaceTypeStudy;

  /// No description provided for @spaceTypeDiningRoom.
  ///
  /// In en, this message translates to:
  /// **'Dining room'**
  String get spaceTypeDiningRoom;

  /// No description provided for @spaceTypeStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage room'**
  String get spaceTypeStorage;

  /// No description provided for @spaceTypeEntryway.
  ///
  /// In en, this message translates to:
  /// **'Entryway'**
  String get spaceTypeEntryway;

  /// No description provided for @spaceTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get spaceTypeOther;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items, spaces, or categories'**
  String get inventorySearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @inventoryAllItems.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get inventoryAllItems;

  /// No description provided for @inventoryPlannedItems.
  ///
  /// In en, this message translates to:
  /// **'Items with plans'**
  String get inventoryPlannedItems;

  /// No description provided for @inventoryNeedsSetupItems.
  ///
  /// In en, this message translates to:
  /// **'Items needing setup'**
  String get inventoryNeedsSetupItems;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get sortByName;

  /// No description provided for @sortByTime.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get sortByTime;

  /// No description provided for @itemDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The item could not be deleted. Your data was not changed. Try again.'**
  String get itemDeleteFailed;

  /// No description provided for @itemSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort items'**
  String get itemSortTitle;

  /// No description provided for @sortByNextMaintenance.
  ///
  /// In en, this message translates to:
  /// **'By next maintenance date'**
  String get sortByNextMaintenance;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get deleteItemTitle;

  /// No description provided for @deleteItemMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete “{name}” and its saved document photos.'**
  String deleteItemMessage(String name);

  /// No description provided for @assetValuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset valuation'**
  String get assetValuationTitle;

  /// No description provided for @assetValuationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Totals current item values, falling back to purchase price when missing'**
  String get assetValuationSubtitle;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get allItems;

  /// No description provided for @householdTotalValuation.
  ///
  /// In en, this message translates to:
  /// **'Total home-item valuation'**
  String get householdTotalValuation;

  /// No description provided for @assetMissingCount.
  ///
  /// In en, this message translates to:
  /// **'Missing for {count, plural, =1{1 item} other{{count} items}}'**
  String assetMissingCount(int count);

  /// No description provided for @itemValuationDetails.
  ///
  /// In en, this message translates to:
  /// **'Item valuation details'**
  String get itemValuationDetails;

  /// No description provided for @assetNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Add one to start recording asset values.'**
  String get assetNoItems;

  /// No description provided for @assetCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current value'**
  String get assetCurrentValue;

  /// No description provided for @assetPurchasePriceFallback.
  ///
  /// In en, this message translates to:
  /// **'Using purchase price'**
  String get assetPurchasePriceFallback;

  /// No description provided for @assetValueMissing.
  ///
  /// In en, this message translates to:
  /// **'No valuation entered'**
  String get assetValueMissing;

  /// No description provided for @assetAddValue.
  ///
  /// In en, this message translates to:
  /// **'Add value'**
  String get assetAddValue;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Item inventory'**
  String get inventoryTitle;

  /// No description provided for @inventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage items and maintenance plans'**
  String get inventorySubtitle;

  /// No description provided for @inventoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String inventoryFilterAll(int count);

  /// No description provided for @inventoryFilterPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned {count}'**
  String inventoryFilterPlanned(int count);

  /// No description provided for @inventoryFilterNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup {count}'**
  String inventoryFilterNeedsSetup(int count);

  /// No description provided for @sortMethodSemantic.
  ///
  /// In en, this message translates to:
  /// **'Sort method: {label}'**
  String sortMethodSemantic(String label);

  /// No description provided for @inventoryNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get inventoryNoMatches;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get inventoryEmpty;

  /// No description provided for @inventoryAdjustSearch.
  ///
  /// In en, this message translates to:
  /// **'Adjust the filters or search terms'**
  String get inventoryAdjustSearch;

  /// No description provided for @inventoryStartFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Start with the first item that needs care'**
  String get inventoryStartFirstItem;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep care tasks at the right time'**
  String get scheduleEmptySubtitle;

  /// No description provided for @scheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a date to view its maintenance tasks'**
  String get scheduleSubtitle;

  /// No description provided for @scheduleSelectedDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance on {date}'**
  String scheduleSelectedDateTitle(String date);

  /// No description provided for @scheduleNone.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get scheduleNone;

  /// No description provided for @scheduleTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String scheduleTaskCount(int count);

  /// No description provided for @scheduleDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is scheduled for this day. Enjoy the time.'**
  String get scheduleDayEmpty;

  /// No description provided for @ledgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset operations ledger'**
  String get ledgerTitle;

  /// No description provided for @ledgerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks only spending related to home items'**
  String get ledgerSubtitle;

  /// No description provided for @ledgerAnnualHoldingCost.
  ///
  /// In en, this message translates to:
  /// **'{year} holding cost'**
  String ledgerAnnualHoldingCost(int year);

  /// No description provided for @ledgerCostHistory.
  ///
  /// In en, this message translates to:
  /// **'Cost history'**
  String get ledgerCostHistory;

  /// No description provided for @ledgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add repair or material records from an item’s details'**
  String get ledgerEmpty;

  /// No description provided for @ledgerRecordSummary.
  ///
  /// In en, this message translates to:
  /// **'{item} · {date}{note}'**
  String ledgerRecordSummary(String item, String date, String note);

  /// No description provided for @ledgerNoteSuffix.
  ///
  /// In en, this message translates to:
  /// **' · {note}'**
  String ledgerNoteSuffix(String note);

  /// No description provided for @remindersEnabledToast.
  ///
  /// In en, this message translates to:
  /// **'Maintenance reminders are on. Each plan uses its own reminder lead time.'**
  String get remindersEnabledToast;

  /// No description provided for @remindersEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance reminders are on'**
  String get remindersEnabledTitle;

  /// No description provided for @remindersNoScheduledPlans.
  ///
  /// In en, this message translates to:
  /// **'No enabled maintenance plans have due dates yet. After you create one, Hearthio can remind you using that plan’s lead time.'**
  String get remindersNoScheduledPlans;

  /// No description provided for @remindersScheduledPlans.
  ///
  /// In en, this message translates to:
  /// **'On-device reminders are scheduled for {count, plural, =1{1 maintenance plan} other{{count} maintenance plans}}. Notifications arrive at 9:00 AM using each plan’s reminder lead time.'**
  String remindersScheduledPlans(int count);

  /// No description provided for @testReminderScheduled.
  ///
  /// In en, this message translates to:
  /// **'The test reminder will arrive in 5 seconds. Switch to the Home Screen or lock screen to check it.'**
  String get testReminderScheduled;

  /// No description provided for @testReminderFailed.
  ///
  /// In en, this message translates to:
  /// **'The test reminder cannot be sent right now. Try again later.'**
  String get testReminderFailed;

  /// No description provided for @sendTestReminder.
  ///
  /// In en, this message translates to:
  /// **'Send test reminder'**
  String get sendTestReminder;

  /// No description provided for @notificationSettingsManual.
  ///
  /// In en, this message translates to:
  /// **'Open Settings → Notifications → Hearthio to manage reminders manually.'**
  String get notificationSettingsManual;

  /// No description provided for @openSystemNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system notification settings'**
  String get openSystemNotificationSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep reminders, backups, and privacy under your control'**
  String get settingsSubtitle;

  /// No description provided for @dataAndRemindersSection.
  ///
  /// In en, this message translates to:
  /// **'Data & reminders'**
  String get dataAndRemindersSection;

  /// No description provided for @remindersAndTesting.
  ///
  /// In en, this message translates to:
  /// **'Reminders & testing'**
  String get remindersAndTesting;

  /// No description provided for @enableMaintenanceReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable maintenance reminders'**
  String get enableMaintenanceReminders;

  /// No description provided for @remindersEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On · View rules or send a test reminder'**
  String get remindersEnabledSubtitle;

  /// No description provided for @remindersDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On-device reminders use each plan’s lead time'**
  String get remindersDisabledSubtitle;

  /// No description provided for @exportLocalData.
  ///
  /// In en, this message translates to:
  /// **'Export local data'**
  String get exportLocalData;

  /// No description provided for @exportLocalDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a CSV to save or share'**
  String get exportLocalDataSubtitle;

  /// No description provided for @fullBackup.
  ///
  /// In en, this message translates to:
  /// **'Full backup'**
  String get fullBackup;

  /// No description provided for @fullBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export all items, records, and document photos'**
  String get fullBackupSubtitle;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @restoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'Restoring. Do not close the app.'**
  String get restoreInProgress;

  /// No description provided for @restoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a previously exported Hearthio-backup.zip'**
  String get restoreBackupSubtitle;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySection;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review data storage, permissions, and export details'**
  String get privacyPolicySubtitle;

  /// No description provided for @restoreGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I restore a full backup?'**
  String get restoreGuideTitle;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a full backup from a file?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreGuideMessage.
  ///
  /// In en, this message translates to:
  /// **'The Files picker will open next.\n\n1. Find the Hearthio-backup.zip previously created with Full backup.\n2. Select it to restore items, maintenance records, and document photos together.\n3. The archive on this device will be replaced. Export a current full backup first if you need to keep it.'**
  String get restoreGuideMessage;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The Files picker will open next. Choose a previously exported Hearthio-backup.zip.\n\nRestoring replaces the archive currently on this device.'**
  String get restoreConfirmMessage;

  /// No description provided for @restoreNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get restoreNotNow;

  /// No description provided for @chooseBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get chooseBackupFile;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Items, records, and photos were updated.'**
  String get restoreSuccess;

  /// No description provided for @restoreInvalid.
  ///
  /// In en, this message translates to:
  /// **'No valid Hearthio-backup.zip was selected. The current archive was not changed.'**
  String get restoreInvalid;

  /// No description provided for @itemNoMaintenanceReminder.
  ///
  /// In en, this message translates to:
  /// **'No maintenance reminder yet'**
  String get itemNoMaintenanceReminder;

  /// No description provided for @itemPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get itemPlanned;

  /// No description provided for @itemNextMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String itemNextMaintenance(String date);

  /// No description provided for @setPlanForItemSemantic.
  ///
  /// In en, this message translates to:
  /// **'Set a plan for {name}'**
  String setPlanForItemSemantic(String name);

  /// No description provided for @setPlan.
  ///
  /// In en, this message translates to:
  /// **'Set plan'**
  String get setPlan;

  /// No description provided for @itemInformation.
  ///
  /// In en, this message translates to:
  /// **'Item information'**
  String get itemInformation;

  /// No description provided for @itemCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get itemCategory;

  /// No description provided for @itemLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get itemLocation;

  /// No description provided for @itemBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get itemBrand;

  /// No description provided for @itemModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get itemModel;

  /// No description provided for @itemPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get itemPurchaseDate;

  /// No description provided for @itemWarrantyEnd.
  ///
  /// In en, this message translates to:
  /// **'Warranty end'**
  String get itemWarrantyEnd;

  /// No description provided for @itemPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get itemPurchasePrice;

  /// No description provided for @itemCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current value'**
  String get itemCurrentValue;

  /// No description provided for @itemNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get itemNotes;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get itemDescription;

  /// No description provided for @startOneMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Start maintenance'**
  String get startOneMaintenance;

  /// No description provided for @deleteThisItem.
  ///
  /// In en, this message translates to:
  /// **'Delete this item'**
  String get deleteThisItem;

  /// No description provided for @detailMaintenancePlans.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plans'**
  String get detailMaintenancePlans;

  /// No description provided for @detailArchivedPlans.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 archived} other{{count} archived}}'**
  String detailArchivedPlans(int count);

  /// No description provided for @detailNoVisiblePlans.
  ///
  /// In en, this message translates to:
  /// **'No enabled or disabled maintenance plans'**
  String get detailNoVisiblePlans;

  /// No description provided for @detailPlanSchedule.
  ///
  /// In en, this message translates to:
  /// **'{state} · Every {interval} days · Remind {lead} days early'**
  String detailPlanSchedule(String state, int interval, int lead);

  /// No description provided for @detailPlanDueSummary.
  ///
  /// In en, this message translates to:
  /// **'Original due date {date} · {timing} · {count, plural, =1{1 step} other{{count} steps}}'**
  String detailPlanDueSummary(String date, String timing, int count);

  /// No description provided for @planRequiredBeforeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Create and enable a maintenance plan for this item first.'**
  String get planRequiredBeforeMaintenance;

  /// No description provided for @chooseMaintenanceTask.
  ///
  /// In en, this message translates to:
  /// **'Choose a maintenance task'**
  String get chooseMaintenanceTask;

  /// No description provided for @sampleItemName.
  ///
  /// In en, this message translates to:
  /// **'Sample · Kitchen water purifier'**
  String get sampleItemName;

  /// No description provided for @sampleItemNotes.
  ///
  /// In en, this message translates to:
  /// **'This is sample data. After replacing the filter, record the date, model, and actual cost.'**
  String get sampleItemNotes;

  /// No description provided for @categoryFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get categoryFurniture;

  /// No description provided for @categoryAppliances.
  ///
  /// In en, this message translates to:
  /// **'Home appliances'**
  String get categoryAppliances;

  /// No description provided for @categoryKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen items'**
  String get categoryKitchen;

  /// No description provided for @categoryPersonalBathroom.
  ///
  /// In en, this message translates to:
  /// **'Personal & bathroom'**
  String get categoryPersonalBathroom;

  /// No description provided for @categoryTextilesBedding.
  ///
  /// In en, this message translates to:
  /// **'Textiles & bedding'**
  String get categoryTextilesBedding;

  /// No description provided for @categoryCleaningStorage.
  ///
  /// In en, this message translates to:
  /// **'Cleaning & storage'**
  String get categoryCleaningStorage;

  /// No description provided for @categorySmallItemsTools.
  ///
  /// In en, this message translates to:
  /// **'Small items & tools'**
  String get categorySmallItemsTools;

  /// No description provided for @categoryHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get categoryHealthcare;

  /// No description provided for @categoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// No description provided for @categoryDecorHobbies.
  ///
  /// In en, this message translates to:
  /// **'Decor & hobbies'**
  String get categoryDecorHobbies;

  /// No description provided for @categoryFiltersConsumables.
  ///
  /// In en, this message translates to:
  /// **'Filters & consumables'**
  String get categoryFiltersConsumables;

  /// No description provided for @categoryVehiclesTravel.
  ///
  /// In en, this message translates to:
  /// **'Vehicles & travel'**
  String get categoryVehiclesTravel;

  /// No description provided for @categoryPetSupplies.
  ///
  /// In en, this message translates to:
  /// **'Pet supplies'**
  String get categoryPetSupplies;

  /// No description provided for @categoryOtherItems.
  ///
  /// In en, this message translates to:
  /// **'Other items'**
  String get categoryOtherItems;

  /// No description provided for @editItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItemTitle;

  /// No description provided for @itemNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name *'**
  String get itemNameRequiredLabel;

  /// No description provided for @specificLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Specific location (optional)'**
  String get specificLocationOptional;

  /// No description provided for @assetInformation.
  ///
  /// In en, this message translates to:
  /// **'Asset information'**
  String get assetInformation;

  /// No description provided for @purchasePriceCny.
  ///
  /// In en, this message translates to:
  /// **'Purchase price (CNY)'**
  String get purchasePriceCny;

  /// No description provided for @currentValueCny.
  ///
  /// In en, this message translates to:
  /// **'Current value (CNY)'**
  String get currentValueCny;

  /// No description provided for @dateInformation.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dateInformation;

  /// No description provided for @documentPhotos.
  ///
  /// In en, this message translates to:
  /// **'Document photos'**
  String get documentPhotos;

  /// No description provided for @chooseItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an item'**
  String get chooseItemTitle;

  /// No description provided for @searchCategoriesOrItems.
  ///
  /// In en, this message translates to:
  /// **'Search categories or items'**
  String get searchCategoriesOrItems;

  /// No description provided for @commonItems.
  ///
  /// In en, this message translates to:
  /// **'Common items'**
  String get commonItems;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get collapseAll;

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get expandAll;

  /// No description provided for @supplementInformation.
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get supplementInformation;

  /// No description provided for @optionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Optional information'**
  String get optionalInformation;

  /// No description provided for @finishLater.
  ///
  /// In en, this message translates to:
  /// **'Finish later'**
  String get finishLater;

  /// No description provided for @finishAdding.
  ///
  /// In en, this message translates to:
  /// **'Finish adding'**
  String get finishAdding;

  /// No description provided for @searchNoItems.
  ///
  /// In en, this message translates to:
  /// **'No related items found'**
  String get searchNoItems;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @addCustomItemHint.
  ///
  /// In en, this message translates to:
  /// **'Add “{query}” as a custom name.'**
  String addCustomItemHint(String query);

  /// No description provided for @addOtherItem.
  ///
  /// In en, this message translates to:
  /// **'Add another item'**
  String get addOtherItem;

  /// No description provided for @changeSelection.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeSelection;

  /// No description provided for @customItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Note or custom name'**
  String get customItemNameLabel;

  /// No description provided for @customItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Primary-bedroom AC'**
  String get customItemNameHint;

  /// No description provided for @specificLocationHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Balcony, left side of TV stand'**
  String get specificLocationHint;

  /// No description provided for @brandAndModel.
  ///
  /// In en, this message translates to:
  /// **'Brand & model'**
  String get brandAndModel;

  /// No description provided for @canAddLater.
  ///
  /// In en, this message translates to:
  /// **'You can add this later'**
  String get canAddLater;

  /// No description provided for @spaceFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get spaceFieldLabel;

  /// No description provided for @advancedItemInformation.
  ///
  /// In en, this message translates to:
  /// **'Purchase, warranty & maintenance'**
  String get advancedItemInformation;

  /// No description provided for @fillWhenNeeded.
  ///
  /// In en, this message translates to:
  /// **'Fill in when needed'**
  String get fillWhenNeeded;

  /// No description provided for @itemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an item name'**
  String get itemNameRequired;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @addDocumentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add document photos'**
  String get addDocumentPhoto;

  /// No description provided for @photoCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph the item, manual, or warranty card'**
  String get photoCameraSubtitle;

  /// No description provided for @photoLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add document photos already saved on this device'**
  String get photoLibrarySubtitle;

  /// No description provided for @itemSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Try again later.'**
  String get itemSaveFailed;

  /// No description provided for @notificationsNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not enabled yet'**
  String get notificationsNotEnabled;

  /// No description provided for @archiveLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The local archive could not be read. Existing data remains on this device, and editing is paused. Do not uninstall the app; restart it or restore a valid backup.'**
  String get archiveLoadFailed;

  /// No description provided for @csvHeaderName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get csvHeaderName;

  /// No description provided for @csvHeaderCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get csvHeaderCategory;

  /// No description provided for @csvHeaderLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get csvHeaderLocation;

  /// No description provided for @csvHeaderBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get csvHeaderBrand;

  /// No description provided for @csvHeaderModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get csvHeaderModel;

  /// No description provided for @csvHeaderPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get csvHeaderPurchaseDate;

  /// No description provided for @csvHeaderWarrantyEnd.
  ///
  /// In en, this message translates to:
  /// **'Warranty end'**
  String get csvHeaderWarrantyEnd;

  /// No description provided for @csvHeaderNextMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Next maintenance'**
  String get csvHeaderNextMaintenance;

  /// No description provided for @csvHeaderPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get csvHeaderPurchasePrice;

  /// No description provided for @csvHeaderCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current value'**
  String get csvHeaderCurrentValue;

  /// No description provided for @csvHeaderMaintenanceRecords.
  ///
  /// In en, this message translates to:
  /// **'Maintenance records'**
  String get csvHeaderMaintenanceRecords;

  /// No description provided for @csvHeaderTotalMaintenanceCost.
  ///
  /// In en, this message translates to:
  /// **'Total maintenance cost'**
  String get csvHeaderTotalMaintenanceCost;

  /// No description provided for @csvHeaderNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get csvHeaderNotes;

  /// No description provided for @csvExportShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Hearthio home-item data export'**
  String get csvExportShareTitle;

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'The full backup could not be exported. Check device storage and try again.'**
  String get backupExportFailed;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hearthio reminders are on'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'This is a test reminder. Future notifications will use each plan’s reminder lead time.'**
  String get testNotificationBody;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Maintenance reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Home-item maintenance reminders'**
  String get notificationChannelDescription;

  /// No description provided for @maintenanceNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{item} · Due {date}. Remember to take care of it.'**
  String maintenanceNotificationBody(String item, String date);

  /// No description provided for @dashboardTimingDateUnset.
  ///
  /// In en, this message translates to:
  /// **'Date not set'**
  String get dashboardTimingDateUnset;

  /// No description provided for @dashboardTimingOverdue.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day overdue} other{{days} days overdue}}'**
  String dashboardTimingOverdue(int days);

  /// No description provided for @dashboardTimingDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dashboardTimingDueToday;

  /// No description provided for @dashboardTimingDueInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days, plural, =1{1 day} other{{days} days}}'**
  String dashboardTimingDueInDays(int days);

  /// No description provided for @unnamedItem.
  ///
  /// In en, this message translates to:
  /// **'Unnamed item'**
  String get unnamedItem;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @maintenanceGeneric.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceGeneric;

  /// No description provided for @historicalStepUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original step content unavailable'**
  String get historicalStepUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
