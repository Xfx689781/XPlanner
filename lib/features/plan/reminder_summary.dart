import '../../core/data/enums.dart';
import '../../core/data/reminder_spec.dart';
import '../../core/notifications/reminder_text.dart';
import '../../core/utils/format.dart';
import 'task_labels.dart';

/// 编辑页的一句话摘要，例如：
/// - "11月3日 14:00，提前 1 天和 15 分钟"
/// - "14:00 · 每天，准时和提前 15 分钟（闹钟）"
/// - "明天 9:00，准时"
String reminderSummary(
  AppDateFormat f,
  DateTime anchor,
  RepeatRule repeat,
  List<ReminderSpec> specs, {
  required DateTime today,
}) {
  final l10n = f.l10n;
  final when = repeat == RepeatRule.none
      ? l10n.dateWithTime(f.relative(anchor, today), f.time(anchor))
      : reminderLabel(f, anchor, repeat);

  String item(ReminderSpec s, String text) => s.kind == ReminderKind.alarm ? l10n.reminderAlarmSuffix(text) : text;

  final sorted = [...specs]..sort((a, b) => b.offsetMinutes.compareTo(a.offsetMinutes));
  final onTime = sorted.where((s) => s.offsetMinutes == 0).firstOrNull;
  final leads = [
    for (final s in sorted)
      if (s.offsetMinutes > 0) item(s, durationLabel(l10n, s.offsetMinutes)),
  ];

  if (leads.isEmpty) {
    final base = l10n.reminderSummaryOnTime(when);
    return onTime?.kind == ReminderKind.alarm ? l10n.reminderAlarmSuffix(base) : base;
  }
  final joined = joinList(l10n, leads);
  if (onTime == null) return l10n.reminderSummaryBefore(when, joined);
  final summary = l10n.reminderSummaryOnTimeAnd(when, joined);
  return onTime.kind == ReminderKind.alarm ? l10n.reminderAlarmSuffix(summary) : summary;
}
