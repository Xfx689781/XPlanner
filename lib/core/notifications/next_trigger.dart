import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../data/enums.dart';

/// 一次调度：首次触发时间 + 重复方式（交给系统按当地钟点重复）。
class TriggerPlan {
  const TriggerPlan(this.at, this.match);

  final tz.TZDateTime at;

  /// null = 只响一次；time = 每天；dayOfWeekAndTime = 每周
  final DateTimeComponents? match;

  @override
  String toString() => 'TriggerPlan($at, $match)';
}

/// 计算任务的下一次提醒。不需要提醒时返回 null。
///
/// reminderAt 是当地钟点（年月日时分），在 [now] 所在时区里解释，
/// 所以换了时区后重新计算，9:00 仍是当地 9:00。
/// [doneToday]：重复任务今天已完成时，从下一次开始（今天剩下的那次不再响）。
/// 夏令时跳过的钟点（如 02:30）由 TZDateTime 规范化到跳变之后。
TriggerPlan? nextTrigger(Task task, tz.TZDateTime now, {required bool doneToday}) {
  final r = task.reminderAt;
  if (r == null) return null;
  final loc = now.location;

  tz.TZDateTime at(int y, int m, int d) => tz.TZDateTime(loc, y, m, d, r.hour, r.minute);

  switch (task.reminderRepeat) {
    case RepeatRule.none:
      if (task.completedAt != null) return null;
      final t = at(r.year, r.month, r.day);
      return t.isAfter(now) ? TriggerPlan(t, null) : null;

    case RepeatRule.daily:
    case RepeatRule.weekly:
      final weekly = task.reminderRepeat == RepeatRule.weekly;
      // 从"今天"和"开始那天"中较晚的一天起找
      final today = DateTime(now.year, now.month, now.day);
      final startDay = DateTime(r.year, r.month, r.day);
      var day = startDay.isAfter(today) ? startDay : today;
      // 每周最坏情况：今天是那个星期几但已过或已完成 → 7 天后。留足余量
      for (var i = 0; i < 15; i++) {
        final candidate = DateTime(day.year, day.month, day.day);
        final isToday = candidate == today;
        final weekdayOk = !weekly || candidate.weekday == r.weekday;
        if (weekdayOk && !(isToday && doneToday)) {
          final t = at(candidate.year, candidate.month, candidate.day);
          if (t.isAfter(now)) {
            return TriggerPlan(
              t,
              weekly ? DateTimeComponents.dayOfWeekAndTime : DateTimeComponents.time,
            );
          }
        }
        day = DateTime(day.year, day.month, day.day + 1);
      }
      return null;
  }
}
