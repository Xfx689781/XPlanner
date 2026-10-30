import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../data/task_repository.dart';
import '../data/task_rules.dart';
import '../utils/clock.dart';
import '../utils/date_utils.dart';
import 'next_trigger.dart';
import 'notification_ids.dart';
import 'reminder_scheduler.dart';

/// 让系统里挂着的提醒与数据库保持一致。
///
/// - 所有操作排队串行执行，避免启动时的全量重建与用户操作交错（例如刚完成的任务又被排上）。
/// - 每次同步前从数据库重新读任务，以数据库为准。
/// - 所有方法都不抛异常：调度失败只记日志，下次启动时的 [resyncAll] 会修复。
class ReminderSyncService {
  ReminderSyncService({
    required this._scheduler,
    required TaskRepository repository,
    required this._clock,
    tz.Location Function()? location,
  }) : _repo = repository,
       _location = location ?? (() => tz.local);

  final ReminderScheduler _scheduler;
  final TaskRepository _repo;
  final Clock _clock;
  final tz.Location Function() _location;

  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// 任务被新建 / 编辑 / 完成后调用：取消它的旧提醒（含通知栏里已弹出的），再按需重新安排。
  /// 返回调度方式（任一条不精确即为不精确）；没有安排时返回 null。
  Future<ScheduleMode?> syncTask(Task task) {
    if (!_scheduler.supported) return Future.value();
    return _serial(() async {
      try {
        await _cancelSlots(task.id);
        final fresh = await _repo.getById(task.id);
        if (fresh == null) return null;
        return await _schedule(fresh);
      } catch (e, s) {
        debugPrint('同步提醒失败（任务 ${task.id}）：$e\n$s');
        return null;
      }
    });
  }

  Future<void> cancelTask(int taskId) {
    if (!_scheduler.supported) return Future.value();
    return _serial(() async {
      try {
        await _cancelSlots(taskId);
      } catch (e) {
        debugPrint('取消提醒失败（任务 $taskId）：$e');
      }
    });
  }

  /// 全量重建：取消所有待触发的提醒，再按数据库重新安排。
  /// 不移除通知栏里已经弹出、用户还没处理的通知。
  /// 启动时、回到前台发现时区或精确闹钟权限变化时调用。
  Future<void> resyncAll() {
    if (!_scheduler.supported) return Future.value();
    return _serial(() async {
      try {
        await _scheduler.cancelAllPending();
        for (final t in await _repo.getWithReminder()) {
          try {
            await _schedule(t);
          } catch (e) {
            debugPrint('重建提醒失败（任务 ${t.id}）：$e');
          }
        }
      } catch (e, s) {
        debugPrint('全量同步提醒失败：$e\n$s');
      }
    });
  }

  Future<void> _cancelSlots(int taskId) async {
    for (final id in notificationIdsForTask(taskId)) {
      await _scheduler.cancel(id);
    }
  }

  Future<ScheduleMode?> _schedule(Task task) async {
    final nowLocal = _clock.now();
    final now = tz.TZDateTime.from(nowLocal, _location());
    final plans = planReminders(task, now, doneToday: task.isDoneOn(startOfDay(nowLocal)));
    ScheduleMode? mode;
    for (var i = 0; i < plans.length; i++) {
      final m = await _scheduler.schedule(
        ReminderRequest(
          id: notificationIdForTask(task.id, i),
          title: task.title,
          body: task.note,
          at: plans[i].at,
          match: plans[i].match,
          payload: taskPayload(task.id),
        ),
      );
      if (mode != ScheduleMode.inexact) mode = m;
    }
    return mode;
  }
}
