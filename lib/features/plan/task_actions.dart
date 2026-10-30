import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/data_providers.dart';
import '../../core/data/task_repository.dart';
import '../../core/data/task_rules.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/reminder_scheduler.dart';
import '../../core/notifications/reminder_sync_service.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/current_day.dart';

/// 任务的写操作。界面只通过这里改任务，保证"先写库、再同步提醒"。
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  TaskRepository get _repo => _ref.read(taskRepositoryProvider);
  ReminderSyncService get _sync => _ref.read(reminderSyncProvider);
  DateTime get _now => _ref.read(clockProvider).now();

  /// 返回新任务和提醒的调度方式（没有提醒时为 null）
  Future<(Task, ScheduleMode?)> create(TaskDraft draft) async {
    final task = await _repo.create(draft, now: _now);
    return (task, await _sync.syncTask(task));
  }

  Future<(Task?, ScheduleMode?)> update(int id, TaskDraft draft) async {
    final task = await _repo.update(id, draft, now: _now);
    if (task == null) {
      await _sync.cancelTask(id);
      return (null, null);
    }
    return (task, await _sync.syncTask(task));
  }

  /// 切换"今天"的完成状态。
  /// 不重复任务完成后取消提醒；重复任务完成后从下一次开始提醒。
  Future<Task?> toggleDone(Task task) async {
    final today = _ref.read(currentDayProvider);
    final now = _now;
    final done = task.isDoneOn(today);
    final updated = await _repo.setCompleted(task.id, done ? null : now, now: now);
    if (updated != null) await _sync.syncTask(updated);
    return updated;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _sync.cancelTask(id);
  }
}

final taskActionsProvider = Provider<TaskActions>(TaskActions.new);
