import '../../core/data/settings/settings_enums.dart';
import '../../core/utils/week_start.dart';
import '../../l10n/generated/app_localizations.dart';

String themeLabel(AppLocalizations l10n, ThemePreference t) => switch (t) {
  ThemePreference.system => l10n.themeSystem,
  ThemePreference.light => l10n.themeLight,
  ThemePreference.dark => l10n.themeDark,
};

String accentLabel(AppLocalizations l10n, AccentColor a) => switch (a) {
  AccentColor.vermilion => l10n.accentVermilion,
  AccentColor.amber => l10n.accentAmber,
  AccentColor.pine => l10n.accentPine,
  AccentColor.teal => l10n.accentTeal,
  AccentColor.indigo => l10n.accentIndigo,
  AccentColor.plum => l10n.accentPlum,
};

String weekStartLabel(AppLocalizations l10n, WeekStart w) => switch (w) {
  WeekStart.locale => l10n.weekStartLocale,
  WeekStart.monday => l10n.weekStartMonday,
  WeekStart.sunday => l10n.weekStartSunday,
};

String weekdayName(AppLocalizations l10n, int weekday) =>
    weekday == DateTime.sunday ? l10n.weekStartSunday : l10n.weekStartMonday;

/// 设置主页摘要：显示实际生效的那天
String weekStartSummary(AppLocalizations l10n, WeekStart w, String intlLocale) =>
    l10n.weekStartSummary(weekdayName(l10n, effectiveFirstWeekday(w, intlLocale)));

String reminderLeadLabel(AppLocalizations l10n, ReminderLead l) =>
    l == ReminderLead.onTime ? l10n.reminderLeadOnTime : l10n.reminderLeadBefore(l.minutes);
