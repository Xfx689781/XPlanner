import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'task_rules_test.dart' show task;

/// task_rules 的边界情况：零点前后、开始日之前、跨月跨年、闰年、整年数据。
void main() {
  final today = DateTime(2026, 10, 30); // 周五

  group('isDoneOn 零点边界', () {
    test('重复任务昨天 23:59 完成：今天未完成', () {
      final t = task(
        reminderAt: DateTime(2026, 10, 1, 9),
        repeat: RepeatRule.daily,
        completedAt: DateTime(2026, 10, 29, 23, 59, 59),
      );
      expect(t.isDoneOn(today), isFalse);
      expect(t.isDoneOn(DateTime(2026, 10, 29)), isTrue);
    });

    test('重复任务今天 00:00 完成：今天已完成', () {
      final t = task(
        reminderAt: DateTime(2026, 10, 1, 9),
        repeat: RepeatRule.daily,
        completedAt: DateTime(2026, 10, 30),
      );
      expect(t.isDoneOn(today), isTrue);
    });

    test('重复任务跨年：12/31 23:59 完成，元旦未完成', () {
      final t = task(
        reminderAt: DateTime(2026, 10, 1, 9),
        repeat: RepeatRule.daily,
        completedAt: DateTime(2026, 12, 31, 23, 59),
      );
      expect(t.isDoneOn(DateTime(2027, 1, 1)), isFalse);
    });

    test('参数 day 带时分也按日期比较', () {
      final t = task(
        reminderAt: DateTime(2026, 10, 1, 9),
        repeat: RepeatRule.weekly,
        completedAt: DateTime(2026, 10, 30, 7),
      );
      expect(t.isDoneOn(DateTime(2026, 10, 30, 23, 59)), isTrue);
    });

    test('有重复规则但没有提醒时按不重复处理（completedAt 非空即完成）', () {
      // 仓库层会把这种组合规范成 none；这里确认规则函数本身也稳妥
      final t = task(repeat: RepeatRule.daily, dueAt: today, completedAt: DateTime(2026, 10, 1));
      expect(t.isRepeating, isFalse);
      expect(t.isDoneOn(today), isTrue);
    });

    test('没有 completedAt 的任务任何一天都未完成', () {
      expect(task(dueAt: today).isDoneOn(today), isFalse);
      expect(task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily).isDoneOn(today), isFalse);
    });
  });

  group('isForDay 边界', () {
    test('每周重复：开始日之前同一个星期几不算', () {
      final t = task(reminderAt: DateTime(2026, 10, 30, 9), repeat: RepeatRule.weekly);
      expect(t.isForDay(DateTime(2026, 10, 23)), isFalse); // 上周五
      expect(t.isForDay(today), isTrue);
      expect(t.isForDay(DateTime(2026, 11, 6)), isTrue);
    });

    test('每周重复：开始日之后其他星期几都不算', () {
      final t = task(reminderAt: DateTime(2026, 10, 30, 9), repeat: RepeatRule.weekly);
      for (var i = 1; i < 7; i++) {
        expect(t.isForDay(DateTime(2026, 10, 30 + i)), isFalse, reason: '+$i 天');
      }
    });

    test('每天重复：开始日当天 23:59 的提醒也让当天算数', () {
      final t = task(reminderAt: DateTime(2026, 10, 30, 23, 59), repeat: RepeatRule.daily);
      expect(t.isForDay(today), isTrue);
      expect(t.isForDay(DateTime(2026, 10, 29)), isFalse);
    });

    test('dueAt 带时间，正好在今天 00:00 或 23:59：属于今天，不属于前后一天', () {
      for (final due in [DateTime(2026, 10, 30), DateTime(2026, 10, 30, 23, 59, 59)]) {
        final t = task(dueAt: due);
        expect(t.isForDay(today), isTrue, reason: '$due');
        expect(t.isForDay(DateTime(2026, 10, 29)), isFalse, reason: '$due');
        expect(t.isForDay(DateTime(2026, 10, 31)), isFalse, reason: '$due');
      }
    });

    test('dueAt 优先于一次性提醒：日期明天、提醒今天 → 属于明天', () {
      final t = task(dueAt: DateTime(2026, 10, 31), reminderAt: DateTime(2026, 10, 30, 9));
      expect(t.isForDay(today), isFalse);
      expect(t.isForDay(DateTime(2026, 10, 31)), isTrue);
    });

    test('每周重复跨夏令时切换日（11/1 是周日）照常属于周日', () {
      final t = task(reminderAt: DateTime(2026, 10, 4, 9), repeat: RepeatRule.weekly); // 周日
      expect(t.isForDay(DateTime(2026, 11, 1)), isTrue);
      expect(t.isForDay(DateTime(2026, 3, 8)), isFalse); // 开始日之前
      expect(t.isForDay(DateTime(2027, 3, 14)), isTrue); // 2027 年夏令时开始日，周日
    });

    test('闰年 2/29：日期任务和每天重复', () {
      expect(task(dueAt: DateTime(2028, 2, 29)).isForDay(DateTime(2028, 2, 29)), isTrue);
      expect(task(dueAt: DateTime(2028, 2, 29)).isForDay(DateTime(2028, 3, 1)), isFalse);
      final daily = task(reminderAt: DateTime(2028, 2, 28, 9), repeat: RepeatRule.daily);
      expect(daily.isForDay(DateTime(2028, 2, 29)), isTrue);
    });

    test('每周重复：开始于 2/29（周二），之后每个周二，含平年', () {
      final t = task(reminderAt: DateTime(2028, 2, 29, 9), repeat: RepeatRule.weekly);
      expect(t.isForDay(DateTime(2028, 3, 7)), isTrue);
      expect(t.isForDay(DateTime(2029, 2, 27)), isTrue); // 2029-02-27 周二
      expect(t.isForDay(DateTime(2029, 2, 28)), isFalse);
    });
  });

  group('isOverdue 边界', () {
    test('dueAt 是今天 00:00 或 23:59：都不逾期（按日期判断，不按时刻）', () {
      expect(task(dueAt: DateTime(2026, 10, 30)).isOverdue(today), isFalse);
      expect(task(dueAt: DateTime(2026, 10, 30, 23, 59)).isOverdue(today), isFalse);
    });

    test('跨月：10/31 的任务在 11/1 逾期', () {
      expect(task(dueAt: DateTime(2026, 10, 31, 23, 59)).isOverdue(DateTime(2026, 11, 1)), isTrue);
    });

    test('闰年：2/29 的任务在 3/1 逾期', () {
      expect(task(dueAt: DateTime(2028, 2, 29)).isOverdue(DateTime(2028, 3, 1)), isTrue);
    });

    test('日期在今天之前、提醒在今天之后：以日期为准算逾期', () {
      final t = task(dueAt: DateTime(2026, 10, 29), reminderAt: DateTime(2026, 10, 31, 9));
      expect(t.isOverdue(today), isTrue);
    });

    test('未来的日期不逾期', () {
      expect(task(dueAt: DateTime(2027, 1, 1)).isOverdue(today), isFalse);
    });

    test('每周重复从未完成：也不算逾期', () {
      expect(task(reminderAt: DateTime(2020, 1, 1, 9), repeat: RepeatRule.weekly).isOverdue(today), isFalse);
    });
  });

  group('DayProgress 边界', () {
    test('全部完成为 1，全部未完成为 0', () {
      final done = [task(id: 1, dueAt: today, completedAt: today), task(id: 2, dueAt: today, completedAt: today)];
      expect(DayProgress.of(done, today).ratio, 1);
      final open = [task(id: 1, dueAt: today), task(id: 2, dueAt: today)];
      expect(DayProgress.of(open, today).ratio, 0);
    });

    test('只有逾期任务和其他日子的任务：total 为 0，ratio 为 0', () {
      final p = DayProgress.of([task(dueAt: DateTime(2026, 10, 1)), task(dueAt: DateTime(2026, 11, 1))], today);
      expect((p.done, p.total, p.ratio), (0, 0, 0.0));
    });

    test('重复任务昨天 23:59 完成：今天算总数但不算完成', () {
      final p = DayProgress.of([
        task(
          reminderAt: DateTime(2026, 10, 1, 9),
          repeat: RepeatRule.daily,
          completedAt: DateTime(2026, 10, 29, 23, 59),
        ),
      ], today);
      expect((p.done, p.total), (0, 1));
    });

    test('大量数据：每天重复的任务在 2028 闰年 366 天里每天都计入，只在完成那天算完成', () {
      final t = task(
        reminderAt: DateTime(2027, 12, 1, 9),
        repeat: RepeatRule.daily,
        completedAt: DateTime(2028, 2, 29, 12),
      );
      var days = 0;
      var doneDays = 0;
      for (var d = DateTime(2028, 1, 1); d.year == 2028; d = DateTime(d.year, d.month, d.day + 1)) {
        final p = DayProgress.of([t], d);
        expect(p.total, 1, reason: '$d');
        days++;
        doneDays += p.done;
      }
      expect(days, 366);
      expect(doneDays, 1);
    });

    test('大量数据：每周重复一年里只有对应星期几计入（2026 年 52 个周五）', () {
      final t = task(reminderAt: DateTime(2026, 1, 2, 9), repeat: RepeatRule.weekly); // 周五
      var count = 0;
      for (var d = DateTime(2026, 1, 1); d.year == 2026; d = DateTime(d.year, d.month, d.day + 1)) {
        count += DayProgress.of([t], d).total;
      }
      expect(count, 52);
    });

    test('大量数据：1000 个任务混合', () {
      final tasks = [
        for (var i = 1; i <= 1000; i++)
          task(id: i, dueAt: i.isEven ? today : DateTime(2026, 10, 29), completedAt: i % 4 == 0 ? today : null),
      ];
      final p = DayProgress.of(tasks, today);
      expect((p.done, p.total), (250, 500));
      expect(p.ratio, 0.5);
    });
  });
}
