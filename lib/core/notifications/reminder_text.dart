import '../../l10n/generated/app_localizations.dart';
import '../data/app_database.dart';
import '../data/reminder_spec.dart';
import '../utils/format.dart';

/// 提前量的文字："15 分钟" / "1 hour" / "2 天"（不含"提前"）
String durationLabel(AppLocalizations l10n, int minutes) {
  final (n, unit) = splitOffset(minutes);
  return switch (unit) {
    OffsetUnit.minutes => l10n.durationMinutes(n),
    OffsetUnit.hours => l10n.durationHours(n),
    OffsetUnit.days => l10n.durationDays(n),
    OffsetUnit.weeks => l10n.durationWeeks(n),
  };
}

/// 选项文字："准时" / "提前 15 分钟" / "15 minutes before"
String leadOptionLabel(AppLocalizations l10n, int minutes) =>
    minutes == 0 ? l10n.reminderLeadOnTime : l10n.reminderLeadBeforeText(durationLabel(l10n, minutes));

/// 通知标题："15 分钟后：交房租（14:00）"；准时："交房租（14:00）"。
/// 提前 ≥1 天时括号里带日期（"明天 14:00" 之类），否则只有时间。
String reminderNotificationTitle(AppDateFormat f, Task task, ReminderSpec spec, {required DateTime today}) {
  final anchor = task.reminderAt!;
  if (spec.offsetMinutes == 0) return f.l10n.reminderNotifyNow(task.title, f.time(anchor));
  final time = spec.offsetMinutes >= ReminderSpec.minutesPerDay
      ? f.l10n.dateWithTime(f.relative(anchor, today), f.time(anchor))
      : f.time(anchor);
  return f.l10n.reminderNotifyBefore(durationLabel(f.l10n, spec.offsetMinutes), task.title, time);
}

/// 按语言把多个项目连成一句："A和B" / "A、B和C" / "A, B, and C"
String joinList(AppLocalizations l10n, List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.single;
  if (items.length == 2) return l10n.listPair(items[0], items[1]);
  var rest = items.first;
  for (final s in items.sublist(1, items.length - 1)) {
    rest = l10n.listJoin(rest, s);
  }
  return l10n.listLast(rest, items.last);
}
