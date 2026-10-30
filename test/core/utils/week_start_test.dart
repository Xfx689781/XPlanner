import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/utils/week_start.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('与 Flutter 日期选择器使用的一周第一天一致', () async {
    for (final (intl, locale) in [
      ('zh_CN', const Locale('zh', 'CN')),
      ('zh_TW', const Locale('zh', 'TW')),
      ('en', const Locale('en')),
      ('en_GB', const Locale('en', 'GB')),
      ('de', const Locale('de')),
    ]) {
      final material = await GlobalMaterialLocalizations.delegate.load(locale);
      // Material：0 = 周日；DateTime：7 = 周日
      expect(localeFirstWeekday(intl) % 7, material.firstDayOfWeekIndex, reason: intl);
    }
  });

  test('未知语言回退到语言码，再回退到 en', () {
    expect(localeFirstWeekday('de_XX'), localeFirstWeekday('de'));
    expect(localeFirstWeekday('xx'), localeFirstWeekday('en'));
  });

  test('设置为周一 / 周日时忽略语言', () {
    expect(effectiveFirstWeekday(WeekStart.monday, 'en'), DateTime.monday);
    expect(effectiveFirstWeekday(WeekStart.sunday, 'de'), DateTime.sunday);
    expect(effectiveFirstWeekday(WeekStart.locale, 'zh_CN'), localeFirstWeekday('zh_CN'));
  });
}
