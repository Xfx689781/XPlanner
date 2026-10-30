import 'package:facet/core/utils/format.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

AppDateFormat zh({bool use24h = true}) =>
    AppDateFormat(lookupAppLocalizations(const Locale('zh')), 'zh_CN', use24h: use24h);
AppDateFormat en({bool use24h = true}) =>
    AppDateFormat(lookupAppLocalizations(const Locale('en')), 'en', use24h: use24h);

void main() {
  group('relativeDayOffset（与语言无关）', () {
    test('今天 / 明天 / 昨天的边界', () {
      final today = DateTime(2026, 10, 30);
      expect(relativeDayOffset(DateTime(2026, 10, 30, 0), today), 0);
      expect(relativeDayOffset(DateTime(2026, 10, 30, 23, 59), today), 0);
      expect(relativeDayOffset(DateTime(2026, 10, 31, 0, 1), today), 1);
      expect(relativeDayOffset(DateTime(2026, 10, 29, 23, 59), today), -1);
    });

    test('跨月、闰年、跨年', () {
      expect(relativeDayOffset(DateTime(2026, 11, 1), DateTime(2026, 10, 31)), 1);
      expect(relativeDayOffset(DateTime(2026, 3, 1), DateTime(2026, 2, 28)), 1);
      expect(relativeDayOffset(DateTime(2028, 2, 29), DateTime(2028, 3, 1)), -1);
      expect(relativeDayOffset(DateTime(2027, 1, 1), DateTime(2026, 12, 31)), 1);
    });

    test('夏令时切换日按日历天计算', () {
      expect(relativeDayOffset(DateTime(2026, 3, 9), DateTime(2026, 3, 8)), 1);
      expect(relativeDayOffset(DateTime(2026, 11, 2), DateTime(2026, 11, 1)), 1);
      expect(relativeDayOffset(DateTime(2026, 3, 30), DateTime(2026, 3, 29)), 1);
      expect(relativeDayOffset(DateTime(2026, 10, 26), DateTime(2026, 10, 25)), 1);
    });
  });

  group('简体中文', () {
    test('相对日期', () {
      final today = DateTime(2026, 10, 30);
      expect(zh().relative(DateTime(2026, 10, 30, 8), today), '今天');
      expect(zh().relative(DateTime(2026, 10, 31), today), '明天');
      expect(zh().relative(DateTime(2026, 10, 29), today), '昨天');
    });

    test('日期：同一年不带年份，跨年带年份', () {
      expect(zh().date(DateTime(2026, 11, 2), today: DateTime(2026, 10, 30)), '11月2日周一');
      expect(zh().date(DateTime(2027, 1, 2), today: DateTime(2026, 12, 31)), '2027年1月2日周六');
      expect(zh().relative(DateTime(2025, 12, 30), DateTime(2026, 1, 1)), '2025年12月30日周二');
    });

    test('时间：跟随系统 24 / 12 小时制', () {
      expect(zh().time(DateTime(2026, 1, 1, 9, 5)), '09:05');
      expect(zh().time(DateTime(2026, 1, 1, 0, 0)), '00:00');
      // 12 小时制时按语言习惯（中文 intl 默认也是 24 小时制）
      expect(zh(use24h: false).time(DateTime(2026, 1, 1, 21, 5)), isNotEmpty);
    });
  });

  group('English', () {
    test('相对日期', () {
      final today = DateTime(2026, 10, 30);
      expect(en().relative(DateTime(2026, 10, 30, 8), today), 'Today');
      expect(en().relative(DateTime(2026, 10, 31), today), 'Tomorrow');
      expect(en().relative(DateTime(2026, 10, 29), today), 'Yesterday');
    });

    test('日期', () {
      expect(en().date(DateTime(2026, 11, 2), today: DateTime(2026, 10, 30)), 'Mon, Nov 2');
      expect(en().date(DateTime(2027, 1, 2), today: DateTime(2026, 12, 31)), 'Sat, Jan 2, 2027');
    });

    test('时间：24 小时制 / 12 小时制', () {
      expect(en().time(DateTime(2026, 1, 1, 21, 5)), '21:05');
      expect(en(use24h: false).time(DateTime(2026, 1, 1, 21, 5)), matches(RegExp(r'^9:05\s?PM$')));
    });
  });

  test('weekdayKey 覆盖一周七天', () {
    final keys = [for (var i = 0; i < 7; i++) weekdayKey(DateTime(2026, 10, 26 + i))];
    expect(keys, ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']);
  });
}
