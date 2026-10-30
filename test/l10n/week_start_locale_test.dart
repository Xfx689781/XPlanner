import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/utils/week_start.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// 一周第一天"跟随语言"：App 自己的计算（localeFirstWeekday(intlLocale)，设置页显示、周视图用）
/// 必须和 App 里实际生效的 MaterialLocalizations.firstDayOfWeekIndex（日期选择器用）一致。
void main() {
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  Future<MaterialLocalizations> materialIn(
    WidgetTester tester,
    AppLanguage lang,
    WeekStart weekStart,
  ) async {
    final db = openTestDb();
    await tester.pumpWidget(
      testApp(
        db,
        clock: clock,
        settings: AppSettings(languageTag: lang.tag, weekStart: weekStart),
      ),
    );
    await tester.pumpAndSettle();
    final material = MaterialLocalizations.of(
      tester.element(find.byType(DayCircle)),
    );
    await tester.disposeApp();
    await tester.db(db.close);
    return material;
  }

  for (final lang in appLanguages) {
    testWidgets(
      '${lang.tag}：跟随语言时与 MaterialLocalizations.firstDayOfWeekIndex 一致',
      (tester) async {
        final material = await materialIn(tester, lang, WeekStart.locale);
        // Material：0 = 周日；DateTime：7 = 周日
        expect(
          localeFirstWeekday(lang.intlLocale) % 7,
          material.firstDayOfWeekIndex,
        );
        expect(
          effectiveFirstWeekday(WeekStart.locale, lang.intlLocale) % 7,
          material.firstDayOfWeekIndex,
        );
      },
    );
  }

  testWidgets(
    'zh-Hant：跟随语言时与 MaterialLocalizations.firstDayOfWeekIndex 一致',
    (tester) async {
      final lang = languageByTag('zh-Hant')!;
      final material = await materialIn(tester, lang, WeekStart.locale);
      // 实际：localeFirstWeekday('zh_TW') = 7（周日），而 App 里 zh-Hant 的 Material 本地化 firstDayOfWeekIndex = 1（周一）
      expect(
        localeFirstWeekday(lang.intlLocale) % 7,
        material.firstDayOfWeekIndex,
      );
    },
    // 回归：Flutter 对 Locale zh-Hant 会回退到简体数据（周一开始），现在按 AppLanguage.materialLocale（zh_TW）加载
  );

  testWidgets(
    'zh-Hant：日期选择器里的日期用繁体「週」',
    (tester) async {
      final material = await materialIn(
        tester,
        languageByTag('zh-Hant')!,
        WeekStart.locale,
      );
      expect(material.formatMediumDate(DateTime(2026, 11, 2)), contains('週'));
    },
    // 回归：日期选择器标题曾显示简体「11月2日周一」
  );

  for (final lang in appLanguages) {
    testWidgets('${lang.tag}：手动选周一 / 周日时 Material 跟着设置走', (tester) async {
      expect(
        (await materialIn(tester, lang, WeekStart.monday)).firstDayOfWeekIndex,
        1,
      );
      expect(
        (await materialIn(tester, lang, WeekStart.sunday)).firstDayOfWeekIndex,
        0,
      );
    });
  }
}
