import '../../core/data/app_database.dart';
import '../../core/data/task_rules.dart';
import '../../l10n/generated/app_localizations.dart';

enum TaskGroup { overdue, today, upcoming, repeating, undated, done }

String taskGroupLabel(AppLocalizations l10n, TaskGroup g) => switch (g) {
  TaskGroup.overdue => l10n.taskGroupOverdue,
  TaskGroup.today => l10n.taskGroupToday,
  TaskGroup.upcoming => l10n.taskGroupUpcoming,
  TaskGroup.repeating => l10n.taskGroupRepeating,
  TaskGroup.undated => l10n.taskGroupUndated,
  TaskGroup.done => l10n.taskGroupDone,
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
