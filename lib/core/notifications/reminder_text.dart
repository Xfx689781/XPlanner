import '../../l10n/generated/app_localizations.dart';
import '../data/app_database.dart';
import '../data/reminder_spec.dart';
import '../data/enums.dart';
import '../utils/date_utils.dart';
import '../utils/format.dart';
import 'next_trigger.dart';

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
///
/// 提醒和锚点不在同一天时，括号里要写明是哪天。标题在排程时生成一次、到点原样显示：
/// - 不重复：相对"触发那天"来说（提前 1 天 → "明天 14:00"；今晚 20:00 提醒明早 8:00 → "明天 08:00"）
/// - 每周重复：系统每周重复同一个标题，只能写星期几（"周一 14:00"）
/// - 每天重复：提前量 < 1 天，跨零点写"明天"
String reminderNotificationTitle(AppDateFormat f, Task task, ReminderSpec spec, {required DateTime today}) {
  final anchor = task.reminderAt!;
  if (spec.offsetMinutes == 0) return f.l10n.reminderNotifyNow(task.title, f.time(anchor));
  final fire = shiftBack(anchor, spec.offsetMinutes);
  final String day;
  if (isSameDay(fire, anchor)) {
    return f.l10n.reminderNotifyBefore(durationLabel(f.l10n, spec.offsetMinutes), task.title, f.time(anchor));
  } else if (task.reminderRepeat == RepeatRule.weekly) {
    day = f.weekday(anchor);
  } else if (task.reminderRepeat == RepeatRule.daily) {
    day = f.l10n.dateTomorrow;
  } else {
    day = f.relative(anchor, startOfDay(fire));
  }
  final time = f.l10n.dateWithTime(day, f.time(anchor));
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
