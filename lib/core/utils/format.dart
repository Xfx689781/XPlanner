import 'package:intl/intl.dart';

import 'date_utils.dart';

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

String weekdayLabel(DateTime d) => '周${_weekdays[d.weekday - 1]}';

/// 09:05
String formatTime(DateTime d) => DateFormat('HH:mm').format(d);

/// 10月30日 周五（跨年时带年份）
String formatDate(DateTime d, {DateTime? today}) {
  final ref = today ?? DateTime.now();
  final base = '${d.month}月${d.day}日 ${weekdayLabel(d)}';
  return d.year == ref.year ? base : '${d.year}年$base';
}

/// 今天 / 明天 / 昨天 / 10月30日 周五
String formatRelativeDate(DateTime d, DateTime today) {
  final diff = startOfDay(d).difference(startOfDay(today)).inHours;
  // 用小时数四舍五入到天，避开夏令时那天 23/25 小时
  final days = (diff / 24).round();
  return switch (days) {
    0 => '今天',
    1 => '明天',
    -1 => '昨天',
    _ => formatDate(d, today: today),
  };
}
