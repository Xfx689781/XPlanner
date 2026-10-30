import 'package:drift/drift.dart' show Value;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../data/enums.dart';
import '../data/reminder_spec.dart';

/// 一次调度：触发时间 + 重复方式。
///
/// match 非空时交给系统按当地钟点无限重复。注意 flutter_local_notifications 在 Android 上
/// 会丢掉 [at] 的日期、从"现在"起重新找下一个匹配的钟点（每周还匹配星期几），
/// 所以这种情况下 [at] 只用来携带"时:分"和星期几。
class TriggerPlan {
  const TriggerPlan(this.at, this.match);

  final tz.TZDateTime at;

  /// null = 只响一次；time = 每天；dayOfWeekAndTime = 每周
  final DateTimeComponents? match;

  @override
  String toString() => 'TriggerPlan($at, $match)';
}

/// 需要跳过今天或延后开始时，用连续的一次性提醒代替系统重复，提前排这么多次。
/// App 每次启动 / 回到前台都会重新补满。
/// 每个任务最多 5 个提醒，窗口取小一些，避免碰到 Android 每个 App 约 500 个闹钟的上限。
const dailyWindow = 3;
const weeklyWindow = 2;

/// 计算任务的下一次提醒。不需要提醒时返回 null。
///
/// reminderAt 是当地钟点（年月日时分），在 [now] 所在时区里解释，
/// 所以换了时区后重新计算，9:00 仍是当地 9:00。
/// [doneToday]：重复任务今天已完成时，从下一次开始（今天剩下的那次不再响）。
/// 一次性提醒落在夏令时跳过的钟点（如 02:30）时规范化到跳变之后。
TriggerPlan? nextTrigger(Task task, tz.TZDateTime now, {required bool doneToday}) {
  final r = task.reminderAt;
  if (r == null) return null;

  switch (task.reminderRepeat) {
    case RepeatRule.none:
      if (task.completedAt != null) return null;
      final t = tz.TZDateTime(now.location, r.year, r.month, r.day, r.hour, r.minute);
      return t.isAfter(now) ? TriggerPlan(t, null) : null;

    case RepeatRule.daily:
    case RepeatRule.weekly:
      final first = _nextOccurrence(task, now, skipToday: doneToday, respectStart: true);
      if (first == null) return null;
      final weekly = task.reminderRepeat == RepeatRule.weekly;
      return TriggerPlan(
        _anchorWithWallTime(first, r),
        weekly ? DateTimeComponents.dayOfWeekAndTime : DateTimeComponents.time,
      );
  }
}

/// 实际要交给系统的调度列表。
///
/// - 不重复：0 或 1 条
/// - 重复，且第一次就是"从现在起下一个匹配的钟点"：1 条，交给系统无限重复
/// - 重复，但要跳过今天（今天已完成）或开始日期在以后：系统重复做不到，
///   改为连续 [dailyWindow] / [weeklyWindow] 条一次性提醒
List<TriggerPlan> planReminders(Task task, tz.TZDateTime now, {required bool doneToday}) {
  final plan = nextTrigger(task, now, doneToday: doneToday);
  if (plan == null) return const [];
  if (plan.match == null) return [plan];

  final first = _nextOccurrence(task, now, skipToday: doneToday, respectStart: true)!;
  final systemWouldPick = _nextOccurrence(task, now, skipToday: false, respectStart: false);
  if (first == systemWouldPick) return [plan];

  final weekly = task.reminderRepeat == RepeatRule.weekly;
  final count = weekly ? weeklyWindow : dailyWindow;
  final result = <TriggerPlan>[];
  var cursor = first;
  while (result.length < count) {
    result.add(TriggerPlan(cursor, null));
    final next = _nextOccurrence(task, cursor, skipToday: false, respectStart: true);
    if (next == null) break;
    cursor = next;
  }
  return result;
}

/// 严格晚于 [now] 的下一次重复。
/// [respectStart]：不早于 reminderAt 的日期；[skipToday]：跳过 [now] 所在的那天。
tz.TZDateTime? _nextOccurrence(
  Task task,
  tz.TZDateTime now, {
  required bool skipToday,
  required bool respectStart,
}) {
  final r = task.reminderAt!;
  final weekly = task.reminderRepeat == RepeatRule.weekly;
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(r.year, r.month, r.day);
  var day = respectStart && startDay.isAfter(today) ? startDay : today;
  // 每周最坏情况：今天是那个星期几但已过或已完成 → 7 天后。留足余量
  for (var i = 0; i < 15; i++) {
    final isToday = day == today;
    final weekdayOk = !weekly || day.weekday == r.weekday;
    if (weekdayOk && !(isToday && skipToday)) {
      final t = tz.TZDateTime(now.location, day.year, day.month, day.day, r.hour, r.minute);
      if (t.isAfter(now)) return t;
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return null;
}

/// 交给系统重复时，插件用 at 的"时:分"作为以后每次的钟点。
/// 如果 [at] 那天这个钟点被夏令时跳过（02:30 被规范化成 03:30），
/// 换成一周后同一星期几（钟点一定存在）作为锚点；插件会自己从现在起找第一次触发。
tz.TZDateTime _anchorWithWallTime(tz.TZDateTime at, DateTime wall) {
  if (at.hour == wall.hour && at.minute == wall.minute) return at;
  return tz.TZDateTime(at.location, at.year, at.month, at.day + 7, wall.hour, wall.minute);
}

/// 锚点往前推 [minutes] 分钟，按"当地钟点"计算（14:00 提前 15 分钟永远是 13:45，提前 1 天是前一天 14:00）。
DateTime shiftBack(DateTime anchor, int minutes) {
  final u = DateTime.utc(anchor.year, anchor.month, anchor.day, anchor.hour, anchor.minute)
      .subtract(Duration(minutes: minutes));
  return DateTime(u.year, u.month, u.day, u.hour, u.minute);
}

/// 一个提醒（提前量）要交给系统的调度列表。
///
/// "今天已完成就跳过"按锚点那天判断：提前量跨过零点时（锚点 00:10 提前 15 分钟 → 前一天 23:55），
/// 今天 23:55 那条属于明天的锚点，不跳过。
List<TriggerPlan> planSpec(Task task, ReminderSpec spec, tz.TZDateTime now, {required bool doneToday}) {
  final anchor = task.reminderAt;
  if (anchor == null) return const [];
  if (!ReminderSpec.allowedFor(spec.offsetMinutes, task.reminderRepeat)) return const [];
  final fire = shiftBack(anchor, spec.offsetMinutes);
  final sameDay = fire.year == anchor.year && fire.month == anchor.month && fire.day == anchor.day;
  return planReminders(task.copyWith(reminderAt: Value(fire)), now, doneToday: doneToday && sameDay);
}
