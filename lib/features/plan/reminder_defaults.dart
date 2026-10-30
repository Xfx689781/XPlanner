import '../../core/utils/date_utils.dart';

/// "+ 添加提醒"时预填的提醒时间。
///
/// - 任务有日期和时间：任务时间 − [leadMinutes]。按绝对时间相减（夏令时当天也正确）；
///   减出来的时间已经过去、但任务时间还没到时，改为准时（任务时间本身）
/// - 只有日期 / 没有日期：提前量不起作用。日期是今天或没有日期 → 下一个整点；其他日期 → 当天 9:00
DateTime defaultReminderTime({
  DateTime? dueDate,
  int? dueHour,
  int? dueMinute,
  required DateTime now,
  required int leadMinutes,
}) {
  final today = startOfDay(now);
  if (dueDate != null && dueHour != null && dueMinute != null) {
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day, dueHour, dueMinute);
    final early = due.subtract(Duration(minutes: leadMinutes));
    if (!early.isAfter(now) && due.isAfter(now)) return due;
    return early;
  }
  final base = dueDate == null ? today : startOfDay(dueDate);
  if (base == today) return DateTime(base.year, base.month, base.day, now.hour + 1);
  return DateTime(base.year, base.month, base.day, 9);
}
