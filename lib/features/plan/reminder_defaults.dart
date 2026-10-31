import '../../core/data/enums.dart';
import '../../core/data/reminder_spec.dart';
import '../../core/notifications/next_trigger.dart';
import '../../core/utils/date_utils.dart';

/// "+ 添加提醒"时的锚点（提醒基准时间）。
///
/// - 任务有日期和时间：就是任务时间
/// - 只有日期 / 没有日期：日期是今天或没有日期 → 下一个整点；其他日期 → 当天 9:00
DateTime defaultReminderTime({
  DateTime? dueDate,
  int? dueHour,
  int? dueMinute,
  required DateTime now,
}) {
  if (dueDate != null && dueHour != null && dueMinute != null) {
    return DateTime(dueDate.year, dueDate.month, dueDate.day, dueHour, dueMinute);
  }
  final today = startOfDay(now);
  final base = dueDate == null ? today : startOfDay(dueDate);
  if (base == today) return DateTime(base.year, base.month, base.day, now.hour + 1);
  return DateTime(base.year, base.month, base.day, 9);
}

/// 新建提醒时默认选中的提醒：设置里的默认提前量和方式，去掉与重复周期冲突的；
/// 不重复的任务再去掉已经过去的（锚点 − 提前量 ≤ 现在）。全部去掉时保留"准时"。
List<ReminderSpec> defaultReminderSpecs({
  required DateTime anchor,
  required DateTime now,
  required List<int> offsets,
  required ReminderKind kind,
  RepeatRule repeat = RepeatRule.none,
}) {
  final specs = [
    for (final m in offsets)
      if (ReminderSpec.allowedFor(m, repeat) && (repeat != RepeatRule.none || shiftBack(anchor, m).isAfter(now)))
        ReminderSpec(m, kind),
  ];
  return specs.isEmpty ? [ReminderSpec(0, kind)] : ReminderSpec.normalize(specs, repeat);
}
