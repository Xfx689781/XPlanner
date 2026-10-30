import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Task task({
  DateTime? dueAt,
  DateTime? reminderAt,
  RepeatRule repeat = RepeatRule.none,
  DateTime? completedAt,
  int id = 1,
}) {
  final t0 = DateTime(2026, 1, 1);
  return Task(
    id: id,
    title: 't$id',
    dueAt: dueAt,
    dueHasTime: false,
    priority: Priority.medium,
    reminderAt: reminderAt,
    reminderRepeat: repeat,
    completedAt: completedAt,
    createdAt: t0,
    updatedAt: t0,
  );
}

void main() {
  final today = DateTime(2026, 10, 30); // 周五

  group('isForDay', () {
    test('有日期：只在那一天', () {
      final t = task(dueAt: DateTime(2026, 10, 30, 18));
      expect(t.isForDay(today), isTrue);
      expect(t.isForDay(DateTime(2026, 10, 31)), isFalse);
    });

    test('无日期无提醒：不属于任何一天', () {
      expect(task().isForDay(today), isFalse);
    });

    test('无日期、一次性提醒在今天', () {
      expect(task(reminderAt: DateTime(2026, 10, 30, 9)).isForDay(today), isTrue);
    });

    test('每天重复：从开始那天起每天都算，之前不算', () {
      final t = task(reminderAt: DateTime(2026, 10, 30, 9), repeat: RepeatRule.daily);
      expect(t.isForDay(DateTime(2026, 10, 29)), isFalse);
      expect(t.isForDay(today), isTrue);
      expect(t.isForDay(DateTime(2027, 1, 1)), isTrue);
    });

    test('每周重复：同一个星期几，跨月跨年', () {
      final t = task(reminderAt: DateTime(2026, 10, 2, 9), repeat: RepeatRule.weekly); // 周五
      expect(t.isForDay(today), isTrue);
      expect(t.isForDay(DateTime(2026, 10, 31)), isFalse);
      expect(t.isForDay(DateTime(2026, 11, 6)), isTrue);
      expect(t.isForDay(DateTime(2027, 1, 1)), isTrue); // 2027-01-01 也是周五
    });

    test('重复规则优先于日期', () {
      final t = task(dueAt: DateTime(2026, 10, 1), reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      expect(t.isForDay(today), isTrue);
    });
  });

  group('isDoneOn', () {
    test('不重复：完成后任何一天都是完成', () {
      final t = task(dueAt: today, completedAt: DateTime(2026, 10, 29, 23));
      expect(t.isDoneOn(today), isTrue);
    });

    test('重复：只有今天完成才算今天完成，第二天自动回到未完成', () {
      final t = task(
        reminderAt: DateTime(2026, 10, 1, 9),
        repeat: RepeatRule.daily,
        completedAt: DateTime(2026, 10, 30, 23, 59),
      );
      expect(t.isDoneOn(today), isTrue);
      expect(t.isDoneOn(DateTime(2026, 10, 31)), isFalse);
    });
  });

  group('isOverdue', () {
    test('日期在今天之前且未完成', () {
      expect(task(dueAt: DateTime(2026, 10, 29, 23, 59)).isOverdue(today), isTrue);
      expect(task(dueAt: DateTime(2026, 10, 30, 0, 1)).isOverdue(today), isFalse);
    });

    test('跨年逾期', () {
      expect(task(dueAt: DateTime(2025, 12, 31)).isOverdue(DateTime(2026, 1, 1)), isTrue);
    });

    test('一次性提醒在之前也算逾期', () {
      expect(task(reminderAt: DateTime(2026, 10, 28, 9)).isOverdue(today), isTrue);
    });

    test('已完成、重复任务、无日期不算逾期', () {
      expect(task(dueAt: DateTime(2026, 10, 1), completedAt: DateTime(2026, 10, 2)).isOverdue(today), isFalse);
      expect(task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily).isOverdue(today), isFalse);
      expect(task().isOverdue(today), isFalse);
    });
  });

  group('DayProgress', () {
    test('没有任务时为 0', () {
      expect(DayProgress.of([], today).ratio, 0);
    });

    test('只统计今天的任务，逾期任务不算进去', () {
      final tasks = [
        task(id: 1, dueAt: today, completedAt: today),
        task(id: 2, dueAt: today),
        task(id: 3, dueAt: DateTime(2026, 10, 1)), // 逾期
        task(id: 4, reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily, completedAt: DateTime(2026, 10, 29)),
      ];
      final p = DayProgress.of(tasks, today);
      expect((p.done, p.total), (1, 3));
      expect(p.ratio, closeTo(1 / 3, 1e-9));
    });
  });
}
