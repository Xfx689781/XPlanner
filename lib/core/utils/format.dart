import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/supported_locales.dart';
import 'date_utils.dart';

/// 按当前界面语言格式化日期和时间。界面上的日期时间只能用它（见 CLAUDE.md「多语言」）。
class AppDateFormat {
  AppDateFormat(this.l10n, this.intlLocale, {required this.use24h});

  /// widget 里用：语言取 App 当前 locale，24 小时制跟随手机系统设置
  factory AppDateFormat.of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = appLanguages.firstWhere(
      (l) => l.locale == locale,
      orElse: () => matchSystemLocale(locale) ?? fallbackLanguage,
    );
    return AppDateFormat(
      AppLocalizations.of(context),
      language.intlLocale,
      use24h: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  final AppLocalizations l10n;
  final String intlLocale;
  final bool use24h;

  /// 09:05 / 9:05 AM / 上午9:05
  String time(DateTime d) => (use24h ? DateFormat.Hm(intlLocale) : DateFormat.jm(intlLocale)).format(d);

  /// 同一年：10月30日周五 / Fri, Oct 30；跨年带年份
  String date(DateTime d, {required DateTime today}) {
    final f = d.year == today.year ? DateFormat.MMMEd(intlLocale) : DateFormat.yMMMEd(intlLocale);
    return f.format(d);
  }

  /// 今天 / 明天 / 昨天，其余同 [date]
  String relative(DateTime d, DateTime today) => switch (relativeDayOffset(d, today)) {
    0 => l10n.dateToday,
    1 => l10n.dateTomorrow,
    -1 => l10n.dateYesterday,
    _ => date(d, today: today),
  };
}

/// d 相对 today 差几天。按小时数四舍五入，避开夏令时那天 23 / 25 小时
int relativeDayOffset(DateTime d, DateTime today) =>
    (startOfDay(d).difference(startOfDay(today)).inHours / 24).round();

/// ARB 里 select 用的星期键：mon … sun
String weekdayKey(DateTime d) => const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][d.weekday - 1];
