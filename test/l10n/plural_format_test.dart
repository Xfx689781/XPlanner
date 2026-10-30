import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/utils/format.dart';
import 'package:facet/features/settings/settings_labels.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

AppLanguage lang(String tag) => languageByTag(tag)!;
AppLocalizations l10nOf(String tag) => lookupAppLocalizations(lang(tag).locale);
AppDateFormat fmt(String tag, {bool use24h = true}) =>
    AppDateFormat(l10nOf(tag), lang(tag).intlLocale, use24h: use24h);

void main() {
  // App 里 GlobalMaterialLocalizations 加载时会用 Flutter 自带的日期数据覆盖 intl 包的数据（zh_TW 的 MMMEd 带空格），
  // 先加载一次，让纯单元测试和真实 App 的输出一致，也不受测试执行顺序影响
  setUpAll(() => GlobalMaterialLocalizations.delegate.load(const Locale('en')));

  group('复数', () {
    test('English：=1 用单数，其余（含 0）用复数', () {
      final l = l10nOf('en');
      expect(l.todayProgressSemantics(0, 1), '0 of 1 task done today');
      expect(l.todayProgressSemantics(1, 1), '1 of 1 task done today');
      expect(l.todayProgressSemantics(0, 2), '0 of 2 tasks done today');
      expect(l.todayProgressSemantics(2, 3), '2 of 3 tasks done today');
      expect(l.todayProgressSemantics(0, 0), '0 of 0 tasks done today');
      expect(l.todayProgressSemantics(365, 365), '365 of 365 tasks done today');
      expect(l.reminderLeadBefore(1), '1 minute before');
      expect(l.reminderLeadBefore(0), '0 minutes before');
      expect(l.reminderLeadBefore(5), '5 minutes before');
      expect(l.reminderLeadBefore(15), '15 minutes before');
    });

    test('简体中文：没有单复数区别', () {
      final l = l10nOf('zh-Hans');
      expect(l.todayProgressSemantics(0, 1), '今天完成 0 / 1');
      expect(l.todayProgressSemantics(2, 3), '今天完成 2 / 3');
      expect(l.reminderLeadBefore(1), '提前 1 分钟');
      expect(l.reminderLeadBefore(15), '提前 15 分钟');
    });

    test('繁體中文：没有单复数区别，用繁体字', () {
      final l = l10nOf('zh-Hant');
      expect(l.todayProgressSemantics(0, 1), '今天完成 0 / 1');
      expect(l.todayProgressSemantics(2, 3), '今天完成 2 / 3');
      expect(l.reminderLeadBefore(1), '提前 1 分鐘');
      expect(l.reminderLeadBefore(15), '提前 15 分鐘');
    });

    test('设置里提前量选项的文字（每种语言）', () {
      final expected = {
        'en': ['At the time', '5 minutes before', '15 minutes before'],
        'zh-Hans': ['准时', '提前 5 分钟', '提前 15 分钟'],
        'zh-Hant': ['準時', '提前 5 分鐘', '提前 15 分鐘'],
      };
      expect(expected.keys.toSet(), {for (final l in appLanguages) l.tag});
      for (final MapEntry(:key, :value) in expected.entries) {
        expect(
          [
            for (final r in ReminderLead.values)
              reminderLeadLabel(l10nOf(key), r),
          ],
          value,
          reason: key,
        );
      }
    });
  });

  group('繁體中文日期（intl zh_TW 数据）', () {
    test(
      'intlLocale 是 zh_TW',
      () => expect(lang('zh-Hant').intlLocale, 'zh_TW'),
    );

    test('同一年 / 跨年，星期用「週」', () {
      final f = fmt('zh-Hant');
      expect(
        f.date(DateTime(2026, 11, 2), today: DateTime(2026, 10, 30)),
        '11月2日 週一',
      );
      expect(
        f.date(DateTime(2026, 11, 8), today: DateTime(2026, 10, 30)),
        '11月8日 週日',
      );
      expect(
        f.date(DateTime(2027, 1, 2), today: DateTime(2026, 12, 31)),
        '2027年1月2日 週六',
      );
      expect(
        f.date(DateTime(2026, 11, 2), today: DateTime(2026, 10, 30)),
        isNot(contains('周')),
      );
    });

    test('闰年 2 月 29 日', () {
      expect(
        fmt('zh-Hant').date(DateTime(2028, 2, 29), today: DateTime(2028, 1, 1)),
        '2月29日 週二',
      );
      expect(
        fmt('zh-Hans').date(DateTime(2028, 2, 29), today: DateTime(2028, 1, 1)),
        '2月29日周二',
      );
      expect(
        fmt('en').date(DateTime(2028, 2, 29), today: DateTime(2028, 1, 1)),
        'Tue, Feb 29',
      );
    });

    test('相对日期用繁体文字，跨年时带年份', () {
      final f = fmt('zh-Hant');
      final today = DateTime(2026, 12, 31);
      expect(f.relative(DateTime(2026, 12, 31, 23, 59), today), '今天');
      expect(f.relative(DateTime(2027, 1, 1), today), '明天');
      expect(f.relative(DateTime(2026, 12, 30), today), '昨天');
      expect(f.relative(DateTime(2027, 1, 2), today), '2027年1月2日 週六');
    });

    test('时间：24 小时制 / 12 小时制（上午 / 下午）', () {
      expect(fmt('zh-Hant').time(DateTime(2026, 1, 1, 9, 5)), '09:05');
      expect(fmt('zh-Hant').time(DateTime(2026, 1, 1, 21, 5)), '21:05');
      expect(
        fmt('zh-Hant', use24h: false).time(DateTime(2026, 1, 1, 9, 5)),
        '上午9:05',
      );
      expect(
        fmt('zh-Hant', use24h: false).time(DateTime(2026, 1, 1, 21, 5)),
        '下午9:05',
      );
    });
  });

  group('English 12 小时制', () {
    final am = RegExp(r'^(\d{1,2}:\d{2})\s(AM|PM)$');

    test('上午 / 下午 / 午夜 / 中午', () {
      final f = fmt('en', use24h: false);
      String norm(String s) => am.firstMatch(s)!.groups([1, 2]).join(' ');
      expect(norm(f.time(DateTime(2026, 1, 1, 9, 5))), '9:05 AM');
      expect(norm(f.time(DateTime(2026, 1, 1, 21, 5))), '9:05 PM');
      expect(norm(f.time(DateTime(2026, 1, 1, 0, 0))), '12:00 AM');
      expect(norm(f.time(DateTime(2026, 1, 1, 12, 0))), '12:00 PM');
    });

    test('24 小时制时没有 AM/PM', () {
      expect(fmt('en').time(DateTime(2026, 1, 1, 0, 0)), '00:00');
      expect(
        fmt('en').time(DateTime(2026, 1, 1, 21, 5)),
        isNot(contains('PM')),
      );
    });
  });

  group('AppDateFormat.of 从 widget 树取语言和 24 小时制', () {
    Future<AppDateFormat> formatIn(
      WidgetTester tester,
      Locale locale, {
      required bool use24h,
    }) async {
      late AppDateFormat f;
      await tester.pumpWidget(
        localizedApp(
          locale: locale,
          Builder(
            builder: (context) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: use24h),
                child: Builder(
                  builder: (context) {
                    f = AppDateFormat.of(context);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      return f;
    }

    testWidgets('每种语言用自己的 intlLocale', (tester) async {
      for (final l in appLanguages) {
        final f = await formatIn(tester, l.locale, use24h: true);
        expect(f.intlLocale, l.intlLocale, reason: l.tag);
        expect(f.use24h, isTrue);
      }
    });

    testWidgets('繁体 12 小时制 → 下午9:05；English 12 小时制 → PM', (tester) async {
      final hant = await formatIn(
        tester,
        lang('zh-Hant').locale,
        use24h: false,
      );
      expect(hant.time(DateTime(2026, 1, 1, 21, 5)), '下午9:05');
      expect(
        hant.date(DateTime(2026, 11, 2), today: DateTime(2026, 10, 30)),
        '11月2日 週一',
      );
      final en = await formatIn(tester, lang('en').locale, use24h: false);
      expect(
        en.time(DateTime(2026, 1, 1, 21, 5)),
        matches(RegExp(r'^9:05\sPM$')),
      );
    });
  });
}
