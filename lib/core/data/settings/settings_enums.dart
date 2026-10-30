/// 主题偏好。core 不依赖 Flutter 的 ThemeMode，到 app.dart 再转换。
enum ThemePreference { system, light, dark }

/// 一周从哪天开始。locale = 跟随语言习惯
enum WeekStart { locale, monday, sunday }

/// 新建提醒时的默认提前量
enum ReminderLead {
  onTime(0),
  min5(5),
  min15(15);

  const ReminderLead(this.minutes);

  final int minutes;
}
