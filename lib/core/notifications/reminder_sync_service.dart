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
/// 所有方法都不抛异常：调度失败只记日志，下次启动时的 [resyncAll] 会修复。
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

  /// 先取消，再按需重新安排。返回实际调度方式；没有安排时返回 null。
  Future<ScheduleMode?> syncTask(Task task) async {
    if (!_scheduler.supported) return null;
    try {
      final id = notificationIdForTask(task.id);
      await _scheduler.cancel(id);

      final nowLocal = _clock.now();
      final now = tz.TZDateTime.from(nowLocal, _location());
      final plan = nextTrigger(task, now, doneToday: task.isDoneOn(startOfDay(nowLocal)));
      if (plan == null) return null;

      return await _scheduler.schedule(
        ReminderRequest(
          id: id,
          title: task.title,
          body: task.note,
          at: plan.at,
          match: plan.match,
          payload: taskPayload(task.id),
        ),
      );
    } catch (e, s) {
      debugPrint('同步提醒失败（任务 ${task.id}）：$e\n$s');
      return null;
    }
  }

  Future<void> cancelTask(int taskId) async {
    if (!_scheduler.supported) return;
    try {
      await _scheduler.cancel(notificationIdForTask(taskId));
    } catch (e) {
      debugPrint('取消提醒失败（任务 $taskId）：$e');
    }
  }

  /// 全量重建：清空系统里的所有提醒，再按数据库重新安排。
  /// 启动时、时区变化、精确闹钟权限变化时调用。
  Future<void> resyncAll() async {
    if (!_scheduler.supported) return;
    try {
      await _scheduler.cancelAll();
      for (final t in await _repo.getWithReminder()) {
        await syncTask(t);
      }
    } catch (e, s) {
      debugPrint('全量同步提醒失败：$e\n$s');
    }
  }
}
