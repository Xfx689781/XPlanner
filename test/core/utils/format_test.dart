import 'package:facet/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatRelativeDate', () {
    test('今天 / 明天 / 昨天（忽略时分）', () {
      final today = DateTime(2026, 10, 30, 15);
      expect(formatRelativeDate(DateTime(2026, 10, 30, 0), today), '今天');
      expect(formatRelativeDate(DateTime(2026, 10, 30, 23, 59), today), '今天');
      expect(formatRelativeDate(DateTime(2026, 10, 31, 0, 1), today), '明天');
      expect(formatRelativeDate(DateTime(2026, 10, 29, 23, 59), today), '昨天');
    });

    test('明天跨月、昨天跨月', () {
      expect(formatRelativeDate(DateTime(2026, 11, 1), DateTime(2026, 10, 31)), '明天');
      expect(formatRelativeDate(DateTime(2026, 10, 31), DateTime(2026, 11, 1)), '昨天');
      expect(formatRelativeDate(DateTime(2026, 3, 1), DateTime(2026, 2, 28)), '明天'); // 平年
    });

    test('闰年 2 月：2/28 的明天是 2/29，3/1 的昨天是 2/29', () {
      expect(formatRelativeDate(DateTime(2028, 2, 29), DateTime(2028, 2, 28)), '明天');
      expect(formatRelativeDate(DateTime(2028, 2, 29), DateTime(2028, 3, 1)), '昨天');
      expect(formatRelativeDate(DateTime(2028, 3, 1), DateTime(2028, 2, 28)), '3月1日 周三');
    });

    test('明天 / 昨天跨年', () {
      expect(formatRelativeDate(DateTime(2027, 1, 1), DateTime(2026, 12, 31)), '明天');
      expect(formatRelativeDate(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), '昨天');
    });

    test('更远的日期：同年不带年份，跨年带年份', () {
      expect(formatRelativeDate(DateTime(2026, 11, 2), DateTime(2026, 10, 30)), '11月2日 周一');
      expect(formatRelativeDate(DateTime(2027, 1, 2), DateTime(2026, 12, 31)), '2027年1月2日 周六');
      expect(formatRelativeDate(DateTime(2025, 12, 30), DateTime(2026, 1, 1)), '2025年12月30日 周二');
    });

    test('夏令时切换日前后（日历分量构造）仍是明天 / 昨天', () {
      // 不论测试机是否有夏令时，这些天之间都只差一天
      expect(formatRelativeDate(DateTime(2026, 3, 9), DateTime(2026, 3, 8)), '明天');
      expect(formatRelativeDate(DateTime(2026, 3, 8), DateTime(2026, 3, 9)), '昨天');
      expect(formatRelativeDate(DateTime(2026, 11, 2), DateTime(2026, 11, 1)), '明天');
      expect(formatRelativeDate(DateTime(2026, 3, 30), DateTime(2026, 3, 29)), '明天');
      expect(formatRelativeDate(DateTime(2026, 10, 26), DateTime(2026, 10, 25)), '明天');
    });
  });

  group('formatDate', () {
    test('同年不带年份，跨年带年份', () {
      expect(formatDate(DateTime(2026, 10, 30), today: DateTime(2026, 1, 1)), '10月30日 周五');
      expect(formatDate(DateTime(2027, 1, 1), today: DateTime(2026, 12, 31)), '2027年1月1日 周五');
    });
  });

  test('weekdayLabel 覆盖一周七天', () {
    // 2026-10-26 是周一
    final labels = [for (var i = 0; i < 7; i++) weekdayLabel(DateTime(2026, 10, 26 + i))];
    expect(labels, ['周一', '周二', '周三', '周四', '周五', '周六', '周日']);
  });

  test('formatTime 两位补零，24 小时制', () {
    expect(formatTime(DateTime(2026, 1, 1, 0, 0)), '00:00');
    expect(formatTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
    expect(formatTime(DateTime(2026, 1, 1, 23, 59)), '23:59');
  });
}
