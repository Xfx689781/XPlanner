import 'package:intl/date_symbol_data_local.dart';

import '../data/settings/settings_enums.dart';

/// 某个语言习惯上的一周第一天（DateTime.monday … DateTime.sunday）。
/// 与 GlobalMaterialLocalizations.firstDayOfWeekIndex 用同一份 intl 数据。
int localeFirstWeekday(String intlLocale) {
  final symbols = dateTimeSymbolMap();
  final data = symbols[intlLocale] ?? symbols[intlLocale.split(RegExp('[_-]')).first] ?? symbols['en'];
  // intl 的 FIRSTDAYOFWEEK：0 = 周一 … 6 = 周日
  return (data?.FIRSTDAYOFWEEK ?? 0) + 1;
}

/// 设置生效后的一周第一天
int effectiveFirstWeekday(WeekStart setting, String intlLocale) => switch (setting) {
  WeekStart.monday => DateTime.monday,
  WeekStart.sunday => DateTime.sunday,
  WeekStart.locale => localeFirstWeekday(intlLocale),
};
