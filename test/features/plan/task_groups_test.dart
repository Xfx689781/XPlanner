import 'package:facet/core/data/enums.dart';
import 'package:facet/features/plan/task_groups.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/data/task_rules_test.dart' show task;

void main() {
  final today = DateTime(2026, 10, 30);

  test('分组顺序：逾期、今天、以后、重复、无日期、已完成', () {
    final tasks = [
      task(id: 1),
      task(id: 2, dueAt: DateTime(2026, 11, 2)),
      task(id: 3, dueAt: DateTime(2026, 10, 29)),
      task(id: 4, dueAt: today),
      task(id: 5, reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.weekly), // 周四
      task(id: 6, dueAt: DateTime(2026, 10, 1), completedAt: DateTime(2026, 10, 1)),
    ];
    final groups = groupTasks(tasks, today);
    expect(groups.map((g) => g.$1), [
      TaskGroup.overdue,
      TaskGroup.today,
      TaskGroup.upcoming,
      TaskGroup.repeating,
      TaskGroup.undated,
      TaskGroup.done,
    ]);
  });

  test('今天完成的任务仍在今天分组', () {
    final t = task(dueAt: today, completedAt: today);
    expect(groupOf(t, today), TaskGroup.today);
  });

  test('已完成按完成时间倒序', () {
    final groups = groupTasks([
      task(id: 1, dueAt: DateTime(2026, 9, 1), completedAt: DateTime(2026, 9, 1)),
      task(id: 2, dueAt: DateTime(2026, 9, 2), completedAt: DateTime(2026, 9, 5)),
    ], today);
    expect(groups.single.$2.map((t) => t.id), [2, 1]);
  });
}
