import '../../core/data/settings/settings_enums.dart';
import '../../core/utils/week_start.dart';

String themeLabel(ThemePreference t) => switch (t) {
  ThemePreference.system => '跟随系统',
  ThemePreference.light => '浅色',
  ThemePreference.dark => '深色',
};

String weekStartLabel(WeekStart w) => switch (w) {
  WeekStart.locale => '跟随语言',
  WeekStart.monday => '周一',
  WeekStart.sunday => '周日',
};

String weekdayName(int weekday) => weekday == DateTime.sunday ? '周日' : '周一';

/// 设置主页摘要：显示实际生效的那天
String weekStartSummary(WeekStart w, String intlLocale) =>
    '${weekdayName(effectiveFirstWeekday(w, intlLocale))}开始';

String reminderLeadLabel(ReminderLead l) => switch (l) {
  ReminderLead.onTime => '准时',
  ReminderLead.min5 => '提前 5 分钟',
  ReminderLead.min15 => '提前 15 分钟',
};
