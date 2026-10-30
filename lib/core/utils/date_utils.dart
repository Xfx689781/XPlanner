/// 日期工具。一律按本地时间计算。
///
/// 跨天用 DateTime(y, m, d + 1) 而不是 add(Duration(days: 1))：
/// 夏令时切换那天一天不是 24 小时，后者会落到 23:00 或 01:00。
library;

DateTime startOfDay(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

DateTime nextDay(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day + 1);
}

DateTime addDays(DateTime d, int days) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day + days, l.hour, l.minute, l.second);
}

bool isSameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// a 所在的那一天是否早于 b 所在的那一天
bool isBeforeDay(DateTime a, DateTime b) => startOfDay(a).isBefore(startOfDay(b));

/// 按天分组，保持输入顺序；每组的 key 是当天 00:00。
List<(DateTime day, List<T> items)> groupByDay<T>(
  Iterable<T> items,
  DateTime Function(T) dateOf,
) {
  final groups = <(DateTime, List<T>)>[];
  for (final item in items) {
    final day = startOfDay(dateOf(item));
    if (groups.isNotEmpty && groups.last.$1 == day) {
      groups.last.$2.add(item);
    } else {
      groups.add((day, [item]));
    }
  }
  return groups;
}
