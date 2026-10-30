import 'package:facet/core/data/wall_time_converter.dart';
import 'package:facet/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextDay / addDays', () {
    test('跨月', () {
      expect(nextDay(DateTime(2026, 1, 31, 15)), DateTime(2026, 2, 1));
      expect(nextDay(DateTime(2026, 4, 30)), DateTime(2026, 5, 1));
    });

    test('跨年', () {
      expect(nextDay(DateTime(2026, 12, 31, 23, 59)), DateTime(2027, 1, 1));
      expect(addDays(DateTime(2026, 12, 28, 9), 7), DateTime(2027, 1, 4, 9));
    });

    test('闰年 2 月', () {
      expect(nextDay(DateTime(2028, 2, 28)), DateTime(2028, 2, 29));
      expect(nextDay(DateTime(2027, 2, 28)), DateTime(2027, 3, 1));
    });

    test('夏令时切换日（美国 3 月第二个周日、11 月第一个周日）仍落在 00:00', () {
      // 用日历分量构造，不依赖测试机所在时区是否有夏令时
      for (final d in [DateTime(2026, 3, 8), DateTime(2026, 11, 1), DateTime(2026, 3, 29), DateTime(2026, 10, 25)]) {
        final n = nextDay(d);
        expect(n.hour, 0);
        expect(n.day, d.day + 1);
      }
      expect(addDays(DateTime(2026, 3, 7, 9), 1), DateTime(2026, 3, 8, 9));
    });
  });

  test('startOfDay 去掉时分秒', () {
    expect(startOfDay(DateTime(2026, 10, 30, 23, 59, 59)), DateTime(2026, 10, 30));
  });

  test('isSameDay / isBeforeDay', () {
    expect(isSameDay(DateTime(2026, 10, 30, 0), DateTime(2026, 10, 30, 23, 59)), isTrue);
    expect(isSameDay(DateTime(2026, 10, 30, 23, 59), DateTime(2026, 10, 31)), isFalse);
    expect(isBeforeDay(DateTime(2026, 10, 30, 23, 59), DateTime(2026, 10, 31, 0, 1)), isTrue);
    expect(isBeforeDay(DateTime(2026, 10, 31, 8), DateTime(2026, 10, 31, 0)), isFalse);
    expect(isBeforeDay(DateTime(2025, 12, 31), DateTime(2026, 1, 1)), isTrue);
  });

  test('groupByDay 按天分组并保持顺序', () {
    final items = [
      DateTime(2026, 11, 1, 9),
      DateTime(2026, 11, 1, 8),
      DateTime(2026, 10, 31, 22),
      DateTime(2025, 12, 31, 23),
    ];
    final groups = groupByDay(items, (d) => d);
    expect(groups.map((g) => g.$1), [DateTime(2026, 11, 1), DateTime(2026, 10, 31), DateTime(2025, 12, 31)]);
    expect(groups.first.$2.length, 2);
  });

  group('WallTimeConverter（当地钟点）', () {
    const c = WallTimeConverter();

    test('写入值是 UTC 且钟点不变，与本机时区无关', () {
      final sql = c.toSql(DateTime(2026, 3, 8, 9, 0));
      expect(sql.isUtc, isTrue);
      expect((sql.year, sql.month, sql.day, sql.hour, sql.minute), (2026, 3, 8, 9, 0));
    });

    test('往返后钟点不变', () {
      final d = DateTime(2026, 12, 31, 23, 45);
      expect(c.fromSql(c.toSql(d)), d);
    });

    test('数据库返回本地表示的同一时刻时也能还原钟点', () {
      final sql = c.toSql(DateTime(2026, 7, 1, 9));
      expect(c.fromSql(sql.toLocal()), DateTime(2026, 7, 1, 9));
    });
  });
}
