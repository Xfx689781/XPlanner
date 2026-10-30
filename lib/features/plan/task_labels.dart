import '../../core/data/app_database.dart';
import '../../core/data/enums.dart';
import '../../core/utils/format.dart';
import '../../design_system/metrics.dart';
import '../../l10n/generated/app_localizations.dart';

/// 优先级 → 方块描边粗细
double strokeForPriority(Priority p) => switch (p) {
  Priority.low => Stroke.thin,
  Priority.medium => Stroke.regular,
  Priority.high => Stroke.bold,
};

String priorityLabel(AppLocalizations l10n, Priority p) => switch (p) {
  Priority.low => l10n.priorityLow,
  Priority.medium => l10n.priorityMedium,
  Priority.high => l10n.priorityHigh,
};

/// 「09:00」「09:00 · 每天」「09:00 · 每周五」
String reminderLabel(AppDateFormat f, DateTime at, RepeatRule repeat) {
  final time = f.time(at);
  return switch (repeat) {
    RepeatRule.none => time,
    RepeatRule.daily => f.l10n.reminderLabelWithRepeat(time, f.l10n.repeatEveryDay),
    RepeatRule.weekly => f.l10n.reminderLabelWithRepeat(time, f.l10n.repeatEveryWeekday(weekdayKey(at))),
  };
}

/// 任务行里的日期说明，例如「明天 15:30」
String? dueLabel(AppDateFormat f, Task t, DateTime today) {
  final due = t.dueAt;
  if (due == null) return null;
  final day = f.relative(due, today);
  return t.dueHasTime ? f.l10n.dateWithTime(day, f.time(due)) : day;
}
