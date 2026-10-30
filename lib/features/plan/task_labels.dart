import '../../core/data/app_database.dart';
import '../../core/data/enums.dart';
import '../../core/utils/format.dart';
import '../../design_system/metrics.dart';

/// 优先级 → 方块描边粗细
double strokeForPriority(Priority p) => switch (p) {
  Priority.low => Stroke.thin,
  Priority.medium => Stroke.regular,
  Priority.high => Stroke.bold,
};

String priorityLabel(Priority p) => switch (p) {
  Priority.low => '低',
  Priority.medium => '中',
  Priority.high => '高',
};

/// 「09:00」「09:00 · 每天」「09:00 · 每周五」
String reminderLabel(DateTime at, RepeatRule repeat) {
  final time = formatTime(at);
  return switch (repeat) {
    RepeatRule.none => time,
    RepeatRule.daily => '$time · 每天',
    RepeatRule.weekly => '$time · 每${weekdayLabel(at)}',
  };
}

/// 任务行里的日期说明，例如「明天 15:30」
String? dueLabel(Task t, DateTime today) {
  final due = t.dueAt;
  if (due == null) return null;
  final day = formatRelativeDate(due, today);
  return t.dueHasTime ? '$day ${formatTime(due)}' : day;
}
