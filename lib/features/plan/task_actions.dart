import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/data_providers.dart';
import '../../core/data/task_repository.dart';
import '../../core/data/task_rules.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/current_day.dart';

/// 任务的写操作。界面只通过这里改任务，保证"先写库、再同步提醒"。
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  TaskRepository get _repo => _ref.read(taskRepositoryProvider);
  DateTime get _now => _ref.read(clockProvider).now();

  Future<Task> create(TaskDraft draft) async {
    return _repo.create(draft, now: _now);
  }

  Future<Task?> update(int id, TaskDraft draft) async {
    return _repo.update(id, draft, now: _now);
  }

  /// 切换"今天"的完成状态。重复任务只影响今天。
  Future<Task?> toggleDone(Task task) async {
    final today = _ref.read(currentDayProvider);
    final now = _now;
    final done = task.isDoneOn(today);
    return _repo.setCompleted(task.id, done ? null : now, now: now);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
  }
}

final taskActionsProvider = Provider<TaskActions>(TaskActions.new);
