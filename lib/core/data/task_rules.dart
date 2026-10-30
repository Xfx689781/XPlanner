import '../utils/date_utils.dart';
import 'app_database.dart';
import 'enums.dart';

/// 任务的日期语义。纯函数，所有判断按本地日期。
extension TaskRules on Task {
  bool get isRepeating => reminderAt != null && reminderRepeat != RepeatRule.none;

  /// 不重复任务：completedAt 非空即完成。
  /// 重复任务：只有 completedAt 落在 [day] 当天才算这一天完成。
  bool isDoneOn(DateTime day) {
    final c = completedAt;
    if (c == null) return false;
    return isRepeating ? isSameDay(c, day) : true;
  }

  /// 这个任务是否属于 [day] 这一天：
  /// - 重复任务：从提醒的那天起，每天重复的每天都算；每周重复的在同一个星期几算
  /// - 有日期：日期是这一天
  /// - 无日期但有一次性提醒：提醒在这一天
  bool isForDay(DateTime day) {
    if (isRepeating) {
      final start = reminderAt!;
      if (isBeforeDay(day, start)) return false;
      return switch (reminderRepeat) {
        RepeatRule.daily => true,
        RepeatRule.weekly => day.weekday == start.weekday,
        RepeatRule.none => false,
      };
    }
    final due = dueAt;
    if (due != null) return isSameDay(due, day);
    final r = reminderAt;
    return r != null && isSameDay(r, day);
  }

  /// 逾期：不重复、未完成，且日期（或一次性提醒）在 [today] 之前。
  bool isOverdue(DateTime today) {
    if (isRepeating || completedAt != null) return false;
    final anchor = dueAt ?? reminderAt;
    return anchor != null && isBeforeDay(anchor, today);
  }
}

/// 一天的完成情况：大圆的水位 = done / total。
class DayProgress {
  const DayProgress(this.done, this.total);

  final int done;
  final int total;

  double get ratio => total == 0 ? 0 : done / total;

  static DayProgress of(Iterable<Task> tasks, DateTime day) {
    var done = 0;
    var total = 0;
    for (final t in tasks) {
      if (!t.isForDay(day)) continue;
      total++;
      if (t.isDoneOn(day)) done++;
    }
    return DayProgress(done, total);
  }
}
