// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonBack => '返回';

  @override
  String get commonClose => '关闭';

  @override
  String get commonTurnOn => '开启';

  @override
  String get navToday => '今天';

  @override
  String get navTasks => '任务';

  @override
  String get navLog => '日志';

  @override
  String get taskDeletedNotice => '这个任务已经删除';

  @override
  String get notificationChannelName => '任务提醒';

  @override
  String get notificationChannelDescription => '任务到点时的提醒';

  @override
  String get notificationTestTitle => 'Facet 测试提醒';

  @override
  String get notificationTestBody => '能看到这条，说明提醒正常';

  @override
  String get dateToday => '今天';

  @override
  String get dateTomorrow => '明天';

  @override
  String get dateYesterday => '昨天';

  @override
  String dateWithTime(String date, String time) {
    return '$date $time';
  }

  @override
  String get priorityLow => '低';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityHigh => '高';

  @override
  String get repeatNone => '不重复';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekly => '每周';

  @override
  String get repeatEveryDay => '每天';

  @override
  String repeatEveryWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': '每周一',
      'tue': '每周二',
      'wed': '每周三',
      'thu': '每周四',
      'fri': '每周五',
      'sat': '每周六',
      'sun': '每周日',
      'other': '每周',
    });
    return '$_temp0';
  }

  @override
  String reminderLabelWithRepeat(String time, String repeat) {
    return '$time · $repeat';
  }

  @override
  String get taskGroupOverdue => '逾期';

  @override
  String get taskGroupToday => '今天';

  @override
  String get taskGroupUpcoming => '以后';

  @override
  String get taskGroupRepeating => '重复';

  @override
  String get taskGroupUndated => '无日期';

  @override
  String get taskGroupDone => '已完成';

  @override
  String taskSquareSemantics(String title, String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'low': '低优先级',
      'medium': '中优先级',
      'high': '高优先级',
      'other': '',
    });
    return '$title，$_temp0';
  }

  @override
  String taskSquareSemanticsOverdue(String title, String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'low': '低优先级',
      'medium': '中优先级',
      'high': '高优先级',
      'other': '',
    });
    return '$title，$_temp0，逾期';
  }

  @override
  String get taskTileEditHint => '编辑';

  @override
  String get tasksTitle => '任务';

  @override
  String get tasksNewTask => '新建任务';

  @override
  String get tasksEmpty => '还没有任务';

  @override
  String get tasksLoadError => '读取任务失败';

  @override
  String get todayTitle => '今天';

  @override
  String get todaySettings => '设置';

  @override
  String todayProgressCount(int done, int total) {
    return '$done / $total';
  }

  @override
  String todayProgressSemantics(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '今天完成 $done / $total',
    );
    return '$_temp0';
  }

  @override
  String get todayNothingPlanned => '今天没有安排';

  @override
  String get todayOverdueHeader => '逾期';

  @override
  String get todayTasksHeader => '任务';

  @override
  String get todayNewTask => '新建任务';

  @override
  String get todayNoTasksHint => '今天还没有任务，点 + 添加';

  @override
  String get todayLogHeader => '日志';

  @override
  String get logTitle => '日志';

  @override
  String get logEmpty => '还没有记录';

  @override
  String get logLoadError => '读取记录失败';

  @override
  String get logInputHint => '记一句…';

  @override
  String get logAddSemantics => '记录';

  @override
  String get logDeleteConfirm => '删除这条记录？';

  @override
  String logEntrySemantics(String time, String content) {
    return '$time $content';
  }

  @override
  String get taskEditorNewTitle => '新任务';

  @override
  String get taskEditorEditTitle => '编辑任务';

  @override
  String get taskEditorTitleHint => '要做什么';

  @override
  String get taskEditorNoteHint => '备注（可选）';

  @override
  String get taskEditorPriorityLabel => '优先级';

  @override
  String get taskEditorDateLabel => '日期';

  @override
  String get taskEditorDateNone => '无';

  @override
  String get taskEditorDateToday => '今天';

  @override
  String get taskEditorDateTomorrow => '明天';

  @override
  String get taskEditorDatePick => '选日期';

  @override
  String get taskEditorAddTime => '+ 时间';

  @override
  String get taskEditorClearTime => '清除时间';

  @override
  String get taskEditorReminderLabel => '提醒';

  @override
  String get taskEditorAddReminder => '+ 添加提醒';

  @override
  String get taskEditorRemoveReminder => '取消提醒';

  @override
  String get taskEditorHintPast => '这个时间已经过去，不会提醒';

  @override
  String get taskEditorHintCompleted => '这个任务已完成，不会提醒；取消完成后才会提醒';

  @override
  String get taskEditorHintUnsupported => '这个平台暂不支持提醒，会在手机上生效';

  @override
  String get taskEditorHintNoExact => '没有「闹钟和提醒」权限，提醒可能晚几分钟';

  @override
  String get taskEditorSave => '保存';

  @override
  String get taskEditorSaveFailed => '保存失败，请重试';

  @override
  String taskEditorDeleteConfirm(String title) {
    return '删除「$title」？它的提醒也会取消。';
  }

  @override
  String get reminderPermissionDenied => '通知权限未开启，提醒不会弹出。可以在「设置」里开启。';

  @override
  String get reminderInexactNotice => '没有「闹钟和提醒」权限，提醒可能晚几分钟。';

  @override
  String reminderSemantics(String label) {
    return '提醒 $label';
  }

  @override
  String reminderSemanticsInactive(String label) {
    return '提醒 $label，已不会响';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSaveFailed => '设置保存失败，请重试';

  @override
  String get settingsSectionGeneral => '通用';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionReminders => '提醒';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsRemindersAttention => '通知或闹钟权限未开启';

  @override
  String settingsGeneralSummary(String language, String weekStart) {
    return '$language · $weekStart';
  }

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String languageCurrent(String language) {
    return '当前：$language';
  }

  @override
  String get settingsWeekStart => '一周从哪天开始';

  @override
  String get weekStartLocale => '跟随语言';

  @override
  String get weekStartMonday => '周一';

  @override
  String get weekStartSunday => '周日';

  @override
  String weekStartCurrent(String day) {
    return '当前：$day';
  }

  @override
  String weekStartSummary(String day) {
    return '$day开始';
  }

  @override
  String get settingsTheme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsReminderLead => '新建提醒时默认';

  @override
  String get reminderLeadOnTime => '准时';

  @override
  String reminderLeadBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '提前 $minutes 分钟',
    );
    return '$_temp0';
  }

  @override
  String get settingsPermissionsHeader => '权限与状态';

  @override
  String get settingsUnsupported => '这个平台暂不支持提醒。任务和提醒时间会正常保存，在手机上会按时弹出。';

  @override
  String get settingsNotifications => '通知权限';

  @override
  String get settingsNotificationsOn => '已开启';

  @override
  String get settingsNotificationsOff => '未开启，提醒不会弹出';

  @override
  String get settingsExactAlarms => '闹钟和提醒';

  @override
  String get settingsExactOn => '已开启，提醒准时';

  @override
  String get settingsExactOff => '未开启，提醒可能晚几分钟到十几分钟';

  @override
  String get settingsBattery => '电池';

  @override
  String get settingsBatteryOk => '不受限制';

  @override
  String get settingsBatteryBad => '可能被省电策略拦截';

  @override
  String get settingsOpenAppSettings => '打开应用设置';

  @override
  String get settingsTimezone => '时区';

  @override
  String settingsTimezoneGuessed(String zone) {
    return '$zone（没取到系统时区，按时差推测，提醒可能差一小时）';
  }

  @override
  String get settingsTimezoneNote => '提醒按当地钟点：换了时区后请打开一次 Facet，提醒会改按新时区的钟点响。';

  @override
  String get settingsCannotDetect => '无法检测';

  @override
  String get settingsTestButton => '5 秒后发一条测试通知';

  @override
  String get settingsTestScheduledExact => '5 秒后会弹出一条通知，可以先锁屏';

  @override
  String get settingsTestScheduledInexact => '已安排（不精确模式，可能晚一些才弹出）';

  @override
  String settingsTestFailed(String error) {
    return '安排失败：$error';
  }

  @override
  String get settingsNotificationsManual => '请在系统设置 → 应用 → Facet → 通知 中开启';

  @override
  String get settingsOpenAppManual => '请手动打开 设置 → 应用 → Facet';

  @override
  String get settingsSamsungHeader => '三星手机：防止提醒被拦截';

  @override
  String get settingsSamsungIntro => '三星的省电策略可能在后台拦截提醒。建议按下面设置一次：';

  @override
  String get settingsSamsungStep1 =>
      '设置 → 应用 → Facet → 电池 → 选「不受限制」。上面「打开应用设置」可以直接跳到这里。';

  @override
  String get settingsSamsungStep2 =>
      '设置 → 电池 → 后台使用限制：确认 Facet 不在「休眠应用」或「深度休眠应用」里；可以把它加入「永不休眠的应用」。';

  @override
  String get settingsSamsungStep3 => '设置 → 应用 → Facet → 通知：允许通知，并打开「锁定屏幕」上的显示。';

  @override
  String get settingsSamsungStep4 =>
      '长时间不打开的 App 可能被系统自动放进休眠列表，如果某天提醒不响了，回来检查第 2 步。';

  @override
  String get settingsAppInfo => '应用信息';

  @override
  String get settingsAppName => '应用';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsPrivacy => '隐私';

  @override
  String get settingsPrivacyText =>
      '你的任务、日志和设置保存在本机。Facet 没有账号，不收集使用数据，也不会把数据发送到任何服务器。';
}
