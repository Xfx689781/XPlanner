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
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Cancel button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Delete action (button, screen reader action)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Back button (screen reader label)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Close button (screen reader label)
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Button that turns on a missing permission
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get commonTurnOn;

  /// Bottom navigation: today page
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Bottom navigation: tasks page
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// Bottom navigation: quick log page
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get navLog;

  /// Shown when a tapped notification points to a deleted task
  ///
  /// In en, this message translates to:
  /// **'This task has been deleted'**
  String get taskDeletedNotice;

  /// Android notification channel name (shown in system settings)
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get notificationChannelName;

  /// Android notification channel description
  ///
  /// In en, this message translates to:
  /// **'Reminders when a task is due'**
  String get notificationChannelDescription;

  /// Title of the test notification
  ///
  /// In en, this message translates to:
  /// **'Facet test reminder'**
  String get notificationTestTitle;

  /// Body of the test notification
  ///
  /// In en, this message translates to:
  /// **'If you can see this, reminders are working'**
  String get notificationTestBody;

  /// Relative date label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Relative date label
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dateTomorrow;

  /// Relative date label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// A date followed by a time, e.g. "Tomorrow 15:30"
  ///
  /// In en, this message translates to:
  /// **'{date} {time}'**
  String dateWithTime(String date, String time);

  /// Task priority
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Task priority
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// Task priority
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Reminder repeat option
  ///
  /// In en, this message translates to:
  /// **'No repeat'**
  String get repeatNone;

  /// Reminder repeat option
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// Reminder repeat option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// Repeat description after a reminder time
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatEveryDay;

  /// Weekly repeat on a given weekday. weekday is mon/tue/wed/thu/fri/sat/sun
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, mon{Every Monday} tue{Every Tuesday} wed{Every Wednesday} thu{Every Thursday} fri{Every Friday} sat{Every Saturday} sun{Every Sunday} other{Weekly}}'**
  String repeatEveryWeekday(String weekday);

  /// Reminder time followed by its repeat rule
  ///
  /// In en, this message translates to:
  /// **'{time} · {repeat}'**
  String reminderLabelWithRepeat(String time, String repeat);

  /// Task list group
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskGroupOverdue;

  /// Task list group
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get taskGroupToday;

  /// Task list group: tasks with a future date
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get taskGroupUpcoming;

  /// Task list group: repeating tasks not due today
  ///
  /// In en, this message translates to:
  /// **'Repeating'**
  String get taskGroupRepeating;

  /// Task list group
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get taskGroupUndated;

  /// Task list group
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskGroupDone;

  /// Screen reader label of a task checkbox. priority is low/medium/high
  ///
  /// In en, this message translates to:
  /// **'{title}, {priority, select, low{low priority} medium{medium priority} high{high priority} other{}}'**
  String taskSquareSemantics(String title, String priority);

  /// Screen reader label of an overdue task checkbox
  ///
  /// In en, this message translates to:
  /// **'{title}, {priority, select, low{low priority} medium{medium priority} high{high priority} other{}}, overdue'**
  String taskSquareSemanticsOverdue(String title, String priority);

  /// Screen reader hint for opening a task
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get taskTileEditHint;

  /// Tasks page title
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Screen reader label of the add-task button
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksNewTask;

  /// Empty state of the tasks page
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmpty;

  /// Error state of the tasks page
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load tasks'**
  String get tasksLoadError;

  /// Today page title
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// Screen reader label of the settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get todaySettings;

  /// Screen reader label of the day circle
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{done} of 1 task done today} other{{done} of {total} tasks done today}}'**
  String todayProgressSemantics(int done, int total);

  /// Second line inside the day circle
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} done'**
  String todayProgressDone(int done, int total);

  /// Inside the empty day circle
  ///
  /// In en, this message translates to:
  /// **'No tasks today'**
  String get todayNoTasks;

  /// Button inside the empty day circle that adds a task for today
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get todayAddTask;

  /// Section header on the today page
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get todayOverdueHeader;

  /// Section header on the today page
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get todayTasksHeader;

  /// Screen reader label of the add-task button on the today page
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get todayNewTask;

  /// Section header on the today page
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get todayLogHeader;

  /// Log page title
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logTitle;

  /// Empty state of the log page
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get logEmpty;

  /// Error state of the log page
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load entries'**
  String get logLoadError;

  /// Placeholder of the quick log input
  ///
  /// In en, this message translates to:
  /// **'Jot something down…'**
  String get logInputHint;

  /// Screen reader label of the add-entry button
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get logAddSemantics;

  /// Confirmation before deleting a log entry
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get logDeleteConfirm;

  /// Screen reader label of a log entry
  ///
  /// In en, this message translates to:
  /// **'{time} {content}'**
  String logEntrySemantics(String time, String content);

  /// Editor header when creating a task
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskEditorNewTitle;

  /// Editor header when editing a task
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEditorEditTitle;

  /// Placeholder of the task title field
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get taskEditorTitleHint;

  /// Placeholder of the note field
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get taskEditorNoteHint;

  /// Editor field label
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskEditorPriorityLabel;

  /// Editor field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get taskEditorDateLabel;

  /// Date option: no date
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get taskEditorDateNone;

  /// Date option
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get taskEditorDateToday;

  /// Date option
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get taskEditorDateTomorrow;

  /// Date option that opens a date picker
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get taskEditorDatePick;

  /// Button that adds a time to the date
  ///
  /// In en, this message translates to:
  /// **'+ Time'**
  String get taskEditorAddTime;

  /// Screen reader label of the clear-time button
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get taskEditorClearTime;

  /// Editor field label
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get taskEditorReminderLabel;

  /// Button that adds a reminder
  ///
  /// In en, this message translates to:
  /// **'+ Add reminder'**
  String get taskEditorAddReminder;

  /// Screen reader label of the remove-reminder button
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get taskEditorRemoveReminder;

  /// Editor hint
  ///
  /// In en, this message translates to:
  /// **'This time has already passed, so there won\'t be a reminder'**
  String get taskEditorHintPast;

  /// Editor hint
  ///
  /// In en, this message translates to:
  /// **'This task is done, so it won\'t remind you. Mark it as not done to get reminders again.'**
  String get taskEditorHintCompleted;

  /// Editor hint on platforms without notifications
  ///
  /// In en, this message translates to:
  /// **'Reminders aren\'t supported on this platform. They\'ll work on your phone.'**
  String get taskEditorHintUnsupported;

  /// Editor hint when exact alarms are not allowed
  ///
  /// In en, this message translates to:
  /// **'Without the \"Alarms & reminders\" permission, reminders may be a few minutes late'**
  String get taskEditorHintNoExact;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get taskEditorSave;

  /// Snackbar when saving a task fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get taskEditorSaveFailed;

  /// Confirmation before deleting a task
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? Its reminder will be canceled too.'**
  String taskEditorDeleteConfirm(String title);

  /// Snackbar after saving a reminder without notification permission
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so reminders won\'t appear. You can turn them on in Settings.'**
  String get reminderPermissionDenied;

  /// Snackbar after saving a reminder without exact alarm permission
  ///
  /// In en, this message translates to:
  /// **'Without the \"Alarms & reminders\" permission, reminders may be a few minutes late.'**
  String get reminderInexactNotice;

  /// Screen reader label of a reminder mark
  ///
  /// In en, this message translates to:
  /// **'Reminder {label}'**
  String reminderSemantics(String label);

  /// Screen reader label of a reminder that will not ring
  ///
  /// In en, this message translates to:
  /// **'Reminder {label}, won\'t ring'**
  String reminderSemanticsInactive(String label);

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Snackbar when saving a setting fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the setting. Please try again.'**
  String get settingsSaveFailed;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsSectionReminders;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Screen reader text for the warning mark on the reminders section
  ///
  /// In en, this message translates to:
  /// **'Notification or alarm permission is off'**
  String get settingsRemindersAttention;

  /// Summary of the general section: language and week start
  ///
  /// In en, this message translates to:
  /// **'{language} · {weekStart}'**
  String settingsGeneralSummary(String language, String weekStart);

  /// Settings item
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language option that follows the phone language
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageFollowSystem;

  /// Shows which language "follow system" resolves to
  ///
  /// In en, this message translates to:
  /// **'Currently: {language}'**
  String languageCurrent(String language);

  /// Settings item
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get settingsWeekStart;

  /// Week start option that follows the language
  ///
  /// In en, this message translates to:
  /// **'Language default'**
  String get weekStartLocale;

  /// Week start option
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekStartMonday;

  /// Week start option
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekStartSunday;

  /// Shows which day "language default" resolves to
  ///
  /// In en, this message translates to:
  /// **'Currently: {day}'**
  String weekStartCurrent(String day);

  /// Short summary such as "Starts Monday"
  ///
  /// In en, this message translates to:
  /// **'Starts {day}'**
  String weekStartSummary(String day);

  /// Settings item
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Settings item: accent color
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccentColor;

  /// Summary of the appearance section: theme and accent color
  ///
  /// In en, this message translates to:
  /// **'{theme} · {accent}'**
  String settingsAppearanceSummary(String theme, String accent);

  /// Accent color name
  ///
  /// In en, this message translates to:
  /// **'Vermilion'**
  String get accentVermilion;

  /// Accent color name
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// Accent color name
  ///
  /// In en, this message translates to:
  /// **'Pine'**
  String get accentPine;

  /// Accent color name
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// Accent color name
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get accentIndigo;

  /// Accent color name
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get accentPlum;

  /// Settings item: default reminder lead time
  ///
  /// In en, this message translates to:
  /// **'Default for new reminders'**
  String get settingsReminderLead;

  /// Reminder lead option
  ///
  /// In en, this message translates to:
  /// **'At the time'**
  String get reminderLeadOnTime;

  /// Settings header
  ///
  /// In en, this message translates to:
  /// **'Permissions & status'**
  String get settingsPermissionsHeader;

  /// Shown on platforms without notifications
  ///
  /// In en, this message translates to:
  /// **'Reminders aren\'t supported on this platform. Tasks and reminder times are saved and will ring on your phone.'**
  String get settingsUnsupported;

  /// Permission row
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Permission status
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsNotificationsOn;

  /// Permission status
  ///
  /// In en, this message translates to:
  /// **'Off — reminders won\'t appear'**
  String get settingsNotificationsOff;

  /// Permission row (Android "Alarms & reminders")
  ///
  /// In en, this message translates to:
  /// **'Alarms & reminders'**
  String get settingsExactAlarms;

  /// Permission status
  ///
  /// In en, this message translates to:
  /// **'On — reminders are on time'**
  String get settingsExactOn;

  /// Permission status
  ///
  /// In en, this message translates to:
  /// **'Off — reminders may be several minutes late'**
  String get settingsExactOff;

  /// Status row
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get settingsBattery;

  /// Battery status
  ///
  /// In en, this message translates to:
  /// **'Unrestricted'**
  String get settingsBatteryOk;

  /// Battery status
  ///
  /// In en, this message translates to:
  /// **'May be blocked by battery saving'**
  String get settingsBatteryBad;

  /// Button that opens system app settings
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get settingsOpenAppSettings;

  /// Status row
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingsTimezone;

  /// Time zone status when guessed
  ///
  /// In en, this message translates to:
  /// **'{zone} (couldn\'t read the system time zone; guessed from the time difference, so reminders may be off by an hour)'**
  String settingsTimezoneGuessed(String zone);

  /// Explanation about time zone changes
  ///
  /// In en, this message translates to:
  /// **'Reminders follow local time: after changing time zones, open Facet once and reminders will ring at the same local time.'**
  String get settingsTimezoneNote;

  /// Status that cannot be detected
  ///
  /// In en, this message translates to:
  /// **'Can\'t detect'**
  String get settingsCannotDetect;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Send a test notification in 5 seconds'**
  String get settingsTestButton;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'A notification will appear in 5 seconds. You can lock your screen now.'**
  String get settingsTestScheduledExact;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Scheduled (inexact mode, it may arrive a bit later)'**
  String get settingsTestScheduledInexact;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t schedule: {error}'**
  String settingsTestFailed(String error);

  /// Snackbar when the permission dialog cannot be shown
  ///
  /// In en, this message translates to:
  /// **'Turn them on in Settings → Apps → Facet → Notifications'**
  String get settingsNotificationsManual;

  /// Snackbar when app settings cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Open Settings → Apps → Facet manually'**
  String get settingsOpenAppManual;

  /// Header. Menu names must match Samsung One UI in this language
  ///
  /// In en, this message translates to:
  /// **'Samsung phones: keep reminders from being blocked'**
  String get settingsSamsungHeader;

  /// Intro
  ///
  /// In en, this message translates to:
  /// **'Samsung\'s battery saving may block reminders in the background. We recommend setting this once:'**
  String get settingsSamsungIntro;

  /// Step; One UI menu names
  ///
  /// In en, this message translates to:
  /// **'Settings → Apps → Facet → Battery → choose \"Unrestricted\". \"Open app settings\" above takes you there.'**
  String get settingsSamsungStep1;

  /// Step; One UI menu names
  ///
  /// In en, this message translates to:
  /// **'Settings → Battery → Background usage limits: make sure Facet isn\'t in \"Sleeping apps\" or \"Deep sleeping apps\". You can add it to \"Never sleeping apps\".'**
  String get settingsSamsungStep2;

  /// Step; One UI menu names
  ///
  /// In en, this message translates to:
  /// **'Settings → Apps → Facet → Notifications: allow notifications and turn on showing them on the lock screen.'**
  String get settingsSamsungStep3;

  /// Step
  ///
  /// In en, this message translates to:
  /// **'Apps you don\'t open for a long time may be put to sleep automatically. If reminders stop one day, check step 2 again.'**
  String get settingsSamsungStep4;

  /// About section header
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get settingsAppInfo;

  /// About row label
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppName;

  /// About row label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// About section header
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// Privacy statement
  ///
  /// In en, this message translates to:
  /// **'Your tasks, log and settings are stored on this device. Facet has no accounts, collects no usage data and doesn\'t send your data to any server. If Android backup is turned on, the system backs up your data, encrypted, to your own Google account; the developer can\'t access it.'**
  String get settingsPrivacyText;

  /// A duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute} other{{n} minutes}}'**
  String durationMinutes(int n);

  /// A duration in hours
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour} other{{n} hours}}'**
  String durationHours(int n);

  /// A duration in days
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String durationDays(int n);

  /// A duration in weeks
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 week} other{{n} weeks}}'**
  String durationWeeks(int n);

  /// Notification title for an early reminder, e.g. "In 15 minutes: Pay rent (14:00)"
  ///
  /// In en, this message translates to:
  /// **'In {lead}: {title} ({time})'**
  String reminderNotifyBefore(String lead, String title, String time);

  /// Notification title for an on-time reminder
  ///
  /// In en, this message translates to:
  /// **'{title} ({time})'**
  String reminderNotifyNow(String title, String time);

  /// Notification / alarm button that completes the task
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get notificationActionDone;

  /// Notification / alarm button that snoozes for 10 minutes
  ///
  /// In en, this message translates to:
  /// **'Snooze 10 min'**
  String get notificationActionSnooze;

  /// Android notification channel name for alarm-style reminders
  ///
  /// In en, this message translates to:
  /// **'Task alarms'**
  String get alarmChannelName;

  /// Android notification channel description for alarms
  ///
  /// In en, this message translates to:
  /// **'Keeps ringing until you tap Done or Snooze'**
  String get alarmChannelDescription;

  /// Reminder lead option, e.g. "15 minutes before" / "提前 15 分钟"
  ///
  /// In en, this message translates to:
  /// **'{lead} before'**
  String reminderLeadBeforeText(String lead);

  /// Opens a dialog to enter a custom reminder lead
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get reminderLeadCustom;

  /// Title of the custom lead dialog
  ///
  /// In en, this message translates to:
  /// **'Custom reminder'**
  String get reminderCustomTitle;

  /// Label of the number field in the custom lead dialog
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reminderCustomAmount;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a value between 1 minute and 30 days'**
  String get reminderCustomInvalid;

  /// Unit choice
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get unitMinutes;

  /// Unit choice
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get unitHours;

  /// Unit choice
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get unitDays;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Reminder style: normal notification
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get reminderKindNotification;

  /// Reminder style: alarm that keeps ringing
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get reminderKindAlarm;

  /// Screen reader label of the notification / alarm toggle
  ///
  /// In en, this message translates to:
  /// **'{lead}: {kind}. Tap to switch.'**
  String reminderKindToggle(String lead, String kind);

  /// Shown when 5 reminders are selected
  ///
  /// In en, this message translates to:
  /// **'Up to 5 reminders'**
  String get reminderMaxReached;

  /// Label of the reminder anchor date-time row
  ///
  /// In en, this message translates to:
  /// **'Remind relative to'**
  String get reminderAnchorLabel;

  /// Shown when reminders are relative to the task time
  ///
  /// In en, this message translates to:
  /// **'Task time'**
  String get reminderAnchorTaskTime;

  /// Button that picks the reminder date and time
  ///
  /// In en, this message translates to:
  /// **'Pick date & time'**
  String get reminderAnchorPick;

  /// Hint on platforms without alarm support
  ///
  /// In en, this message translates to:
  /// **'Alarms ring on your phone only'**
  String get reminderAlarmOnlyPhone;

  /// Joins two list items
  ///
  /// In en, this message translates to:
  /// **'{a} and {b}'**
  String listPair(String a, String b);

  /// Joins list items (not the last)
  ///
  /// In en, this message translates to:
  /// **'{a}, {b}'**
  String listJoin(String a, String b);

  /// Joins the last item of a list of 3+
  ///
  /// In en, this message translates to:
  /// **'{rest}, and {last}'**
  String listLast(String rest, String last);

  /// Summary: anchor time and leads, e.g. "Nov 3 14:00, 1 day and 15 minutes before"
  ///
  /// In en, this message translates to:
  /// **'{when}, {leads} before'**
  String reminderSummaryBefore(String when, String leads);

  /// Summary when only on-time
  ///
  /// In en, this message translates to:
  /// **'{when}, on time'**
  String reminderSummaryOnTime(String when);

  /// Summary with on-time plus leads
  ///
  /// In en, this message translates to:
  /// **'{when}, on time and {leads} before'**
  String reminderSummaryOnTimeAnd(String when, String leads);

  /// Marks a lead that rings as an alarm
  ///
  /// In en, this message translates to:
  /// **'{lead} (alarm)'**
  String reminderAlarmSuffix(String lead);

  /// Settings item
  ///
  /// In en, this message translates to:
  /// **'Default style for new reminders'**
  String get settingsReminderKindDefault;

  /// Permission row: full-screen intent
  ///
  /// In en, this message translates to:
  /// **'Full-screen alarms'**
  String get settingsFullScreen;

  /// Permission status
  ///
  /// In en, this message translates to:
  /// **'On — alarms show full screen on the lock screen'**
  String get settingsFullScreenOn;

  /// Permission status
  ///
  /// In en, this message translates to:
  /// **'Off — alarms still ring and show a banner'**
  String get settingsFullScreenOff;

  /// Screen reader label of the alarm page
  ///
  /// In en, this message translates to:
  /// **'Alarm: {title} at {time}'**
  String alarmPageSemantics(String title, String time);
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
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

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
