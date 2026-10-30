// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get commonTurnOn => 'Turn on';

  @override
  String get navToday => 'Today';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navLog => 'Log';

  @override
  String get taskDeletedNotice => 'This task has been deleted';

  @override
  String get notificationChannelName => 'Task reminders';

  @override
  String get notificationChannelDescription => 'Reminders when a task is due';

  @override
  String get notificationTestTitle => 'Facet test reminder';

  @override
  String get notificationTestBody =>
      'If you can see this, reminders are working';

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateWithTime(String date, String time) {
    return '$date $time';
  }

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get repeatNone => 'No repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatEveryDay => 'Every day';

  @override
  String repeatEveryWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': 'Every Monday',
      'tue': 'Every Tuesday',
      'wed': 'Every Wednesday',
      'thu': 'Every Thursday',
      'fri': 'Every Friday',
      'sat': 'Every Saturday',
      'sun': 'Every Sunday',
      'other': 'Weekly',
    });
    return '$_temp0';
  }

  @override
  String reminderLabelWithRepeat(String time, String repeat) {
    return '$time · $repeat';
  }

  @override
  String get taskGroupOverdue => 'Overdue';

  @override
  String get taskGroupToday => 'Today';

  @override
  String get taskGroupUpcoming => 'Later';

  @override
  String get taskGroupRepeating => 'Repeating';

  @override
  String get taskGroupUndated => 'No date';

  @override
  String get taskGroupDone => 'Done';

  @override
  String taskSquareSemantics(String title, String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'low': 'low priority',
      'medium': 'medium priority',
      'high': 'high priority',
      'other': '',
    });
    return '$title, $_temp0';
  }

  @override
  String taskSquareSemanticsOverdue(String title, String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'low': 'low priority',
      'medium': 'medium priority',
      'high': 'high priority',
      'other': '',
    });
    return '$title, $_temp0, overdue';
  }

  @override
  String get taskTileEditHint => 'Edit';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksNewTask => 'New task';

  @override
  String get tasksEmpty => 'No tasks yet';

  @override
  String get tasksLoadError => 'Couldn\'t load tasks';

  @override
  String get todayTitle => 'Today';

  @override
  String get todaySettings => 'Settings';

  @override
  String todayProgressCount(int done, int total) {
    return '$done / $total';
  }

  @override
  String todayProgressSemantics(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done of $total tasks done today',
      one: '$done of 1 task done today',
    );
    return '$_temp0';
  }

  @override
  String get todayNothingPlanned => 'Nothing planned today';

  @override
  String get todayOverdueHeader => 'Overdue';

  @override
  String get todayTasksHeader => 'Tasks';

  @override
  String get todayNewTask => 'New task';

  @override
  String get todayNoTasksHint => 'No tasks for today yet. Tap + to add one.';

  @override
  String get todayLogHeader => 'Log';

  @override
  String get logTitle => 'Log';

  @override
  String get logEmpty => 'No entries yet';

  @override
  String get logLoadError => 'Couldn\'t load entries';

  @override
  String get logInputHint => 'Jot something down…';

  @override
  String get logAddSemantics => 'Add entry';

  @override
  String get logDeleteConfirm => 'Delete this entry?';

  @override
  String logEntrySemantics(String time, String content) {
    return '$time $content';
  }

  @override
  String get taskEditorNewTitle => 'New task';

  @override
  String get taskEditorEditTitle => 'Edit task';

  @override
  String get taskEditorTitleHint => 'What needs doing?';

  @override
  String get taskEditorNoteHint => 'Note (optional)';

  @override
  String get taskEditorPriorityLabel => 'Priority';

  @override
  String get taskEditorDateLabel => 'Date';

  @override
  String get taskEditorDateNone => 'None';

  @override
  String get taskEditorDateToday => 'Today';

  @override
  String get taskEditorDateTomorrow => 'Tomorrow';

  @override
  String get taskEditorDatePick => 'Pick date';

  @override
  String get taskEditorAddTime => '+ Time';

  @override
  String get taskEditorClearTime => 'Clear time';

  @override
  String get taskEditorReminderLabel => 'Reminder';

  @override
  String get taskEditorAddReminder => '+ Add reminder';

  @override
  String get taskEditorRemoveReminder => 'Remove reminder';

  @override
  String get taskEditorHintPast =>
      'This time has already passed, so there won\'t be a reminder';

  @override
  String get taskEditorHintCompleted =>
      'This task is done, so it won\'t remind you. Mark it as not done to get reminders again.';

  @override
  String get taskEditorHintUnsupported =>
      'Reminders aren\'t supported on this platform. They\'ll work on your phone.';

  @override
  String get taskEditorHintNoExact =>
      'Without the \"Alarms & reminders\" permission, reminders may be a few minutes late';

  @override
  String get taskEditorSave => 'Save';

  @override
  String get taskEditorSaveFailed => 'Couldn\'t save. Please try again.';

  @override
  String taskEditorDeleteConfirm(String title) {
    return 'Delete \"$title\"? Its reminder will be canceled too.';
  }

  @override
  String get reminderPermissionDenied =>
      'Notifications are off, so reminders won\'t appear. You can turn them on in Settings.';

  @override
  String get reminderInexactNotice =>
      'Without the \"Alarms & reminders\" permission, reminders may be a few minutes late.';

  @override
  String reminderSemantics(String label) {
    return 'Reminder $label';
  }

  @override
  String reminderSemanticsInactive(String label) {
    return 'Reminder $label, won\'t ring';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSaveFailed =>
      'Couldn\'t save the setting. Please try again.';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionReminders => 'Reminders';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsRemindersAttention =>
      'Notification or alarm permission is off';

  @override
  String settingsGeneralSummary(String language, String weekStart) {
    return '$language · $weekStart';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String languageCurrent(String language) {
    return 'Currently: $language';
  }

  @override
  String get settingsWeekStart => 'Week starts on';

  @override
  String get weekStartLocale => 'Language default';

  @override
  String get weekStartMonday => 'Monday';

  @override
  String get weekStartSunday => 'Sunday';

  @override
  String weekStartCurrent(String day) {
    return 'Currently: $day';
  }

  @override
  String weekStartSummary(String day) {
    return 'Starts $day';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsReminderLead => 'Default for new reminders';

  @override
  String get reminderLeadOnTime => 'At the time';

  @override
  String reminderLeadBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String get settingsPermissionsHeader => 'Permissions & status';

  @override
  String get settingsUnsupported =>
      'Reminders aren\'t supported on this platform. Tasks and reminder times are saved and will ring on your phone.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsOn => 'On';

  @override
  String get settingsNotificationsOff => 'Off — reminders won\'t appear';

  @override
  String get settingsExactAlarms => 'Alarms & reminders';

  @override
  String get settingsExactOn => 'On — reminders are on time';

  @override
  String get settingsExactOff => 'Off — reminders may be several minutes late';

  @override
  String get settingsBattery => 'Battery';

  @override
  String get settingsBatteryOk => 'Unrestricted';

  @override
  String get settingsBatteryBad => 'May be blocked by battery saving';

  @override
  String get settingsOpenAppSettings => 'Open app settings';

  @override
  String get settingsTimezone => 'Time zone';

  @override
  String settingsTimezoneGuessed(String zone) {
    return '$zone (couldn\'t read the system time zone; guessed from the time difference, so reminders may be off by an hour)';
  }

  @override
  String get settingsTimezoneNote =>
      'Reminders follow local time: after changing time zones, open Facet once and reminders will ring at the same local time.';

  @override
  String get settingsCannotDetect => 'Can\'t detect';

  @override
  String get settingsTestButton => 'Send a test notification in 5 seconds';

  @override
  String get settingsTestScheduledExact =>
      'A notification will appear in 5 seconds. You can lock your screen now.';

  @override
  String get settingsTestScheduledInexact =>
      'Scheduled (inexact mode, it may arrive a bit later)';

  @override
  String settingsTestFailed(String error) {
    return 'Couldn\'t schedule: $error';
  }

  @override
  String get settingsNotificationsManual =>
      'Turn them on in Settings → Apps → Facet → Notifications';

  @override
  String get settingsOpenAppManual => 'Open Settings → Apps → Facet manually';

  @override
  String get settingsSamsungHeader =>
      'Samsung phones: keep reminders from being blocked';

  @override
  String get settingsSamsungIntro =>
      'Samsung\'s battery saving may block reminders in the background. We recommend setting this once:';

  @override
  String get settingsSamsungStep1 =>
      'Settings → Apps → Facet → Battery → choose \"Unrestricted\". \"Open app settings\" above takes you there.';

  @override
  String get settingsSamsungStep2 =>
      'Settings → Battery → Background usage limits: make sure Facet isn\'t in \"Sleeping apps\" or \"Deep sleeping apps\". You can add it to \"Never sleeping apps\".';

  @override
  String get settingsSamsungStep3 =>
      'Settings → Apps → Facet → Notifications: allow notifications and turn on showing them on the lock screen.';

  @override
  String get settingsSamsungStep4 =>
      'Apps you don\'t open for a long time may be put to sleep automatically. If reminders stop one day, check step 2 again.';

  @override
  String get settingsAppInfo => 'App info';

  @override
  String get settingsAppName => 'App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyText =>
      'Your tasks, log and settings are stored on this device. Facet has no accounts, collects no usage data and doesn\'t send your data to any server.';
}
