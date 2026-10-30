import '../../core/data/app_database.dart';
import '../../core/data/task_rules.dart';

enum TaskGroup { overdue, today, upcoming, repeating, undated, done }

String taskGroupLabel(TaskGroup g) => switch (g) {
  TaskGroup.overdue => '逾期',
  TaskGroup.today => '今天',
  TaskGroup.upcoming => '以后',
  TaskGroup.repeating => '重复',
  TaskGroup.undated => '无日期',
  TaskGroup.done => '已完成',
};

TaskGroup groupOf(Task t, DateTime today) {
  if (t.isOverdue(today)) return TaskGroup.overdue;
  if (t.isForDay(today)) return TaskGroup.today;
  if (!t.isRepeating && t.completedAt != null) return TaskGroup.done;
  if (t.isRepeating) return TaskGroup.repeating;
  if (t.dueAt != null || t.reminderAt != null) return TaskGroup.upcoming;
  return TaskGroup.undated;
}

/// 按分组顺序返回非空分组，组内保持输入顺序。
List<(TaskGroup, List<Task>)> groupTasks(Iterable<Task> tasks, DateTime today) {
  final map = {for (final g in TaskGroup.values) g: <Task>[]};
  for (final t in tasks) {
    map[groupOf(t, today)]!.add(t);
  }
  // 已完成：最近完成的在前
  map[TaskGroup.done]!.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  return [
    for (final g in TaskGroup.values)
      if (map[g]!.isNotEmpty) (g, map[g]!),
  ];
}
