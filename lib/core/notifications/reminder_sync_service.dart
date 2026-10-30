import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/generated/app_localizations.dart';
import '../data/app_database.dart';
import '../data/enums.dart';
import '../data/reminder_spec.dart';
import '../data/task_repository.dart';
import '../data/task_rules.dart';
import '../utils/clock.dart';
import '../utils/date_utils.dart';
import '../utils/format.dart';
import 'next_trigger.dart';
import 'notification_ids.dart';
import 'reminder_scheduler.dart';
import 'reminder_text.dart';

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
    AppDateFormat Function()? dates,
  }) : _repo = repository,
       _location = location ?? (() => tz.local),
       _dates = dates ?? _defaultDates;

  /// 全量重建时最多排多少条（Android 每个 App 约 500 个闹钟上限，留余量）；系统重复的计 1 条
  static const maxScheduled = 400;

  /// "稍后提醒"的时长
  static const snoozeDuration = Duration(minutes: 10);

  final ReminderScheduler _scheduler;
  final TaskRepository _repo;
  final Clock _clock;
  final tz.Location Function() _location;

  /// 生成通知文字用的语言和时间格式；每次调度时取，切换语言后 resyncAll 自然用新语言
  final AppDateFormat Function() _dates;

  static AppDateFormat _defaultDates() =>
      AppDateFormat(lookupAppLocalizations(const Locale('en')), 'en', use24h: true);

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
        return await _scheduleAll(await _requestsFor(fresh));
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
  /// 启动时（包括从备份恢复后的第一次启动）、回到前台发现变化、切换语言时调用。
  /// 所有任务的提醒按首次触发时间排序，只排最早的 [maxScheduled] 条，其余等下次重建。
  Future<void> resyncAll() {
    if (!_scheduler.supported) return Future.value();
    return _serial(() async {
      try {
        await _scheduler.cancelAllPending();
        final all = <ReminderRequest>[];
        for (final t in await _repo.getWithReminder()) {
          try {
            all.addAll(await _requestsFor(t));
          } catch (e) {
            debugPrint('计算提醒失败（任务 ${t.id}）：$e');
          }
        }
        all.sort((a, b) => a.at.compareTo(b.at));
        await _scheduleAll(all.take(maxScheduled).toList());
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

  /// 一个任务要排的全部通知：每个提前量最多 [slotsPerReminder] 条，加上"稍后提醒"
  Future<List<ReminderRequest>> _requestsFor(Task task) async {
    final nowLocal = _clock.now();
    final today = startOfDay(nowLocal);
    final now = tz.TZDateTime.from(nowLocal, _location());
    final dates = _dates();
    final requests = <ReminderRequest>[];

    if (task.reminderAt != null) {
      var specs = await _repo.remindersFor(task.id);
      if (specs.isEmpty) specs = const [ReminderSpec(0)];
      final doneToday = task.isDoneOn(today);
      for (var i = 0; i < specs.length && i < ReminderSpec.maxPerTask; i++) {
        final spec = specs[i];
        final plans = planSpec(task, spec, now, doneToday: doneToday);
        for (var k = 0; k < plans.length && k < slotsPerReminder; k++) {
          requests.add(ReminderRequest(
            id: notificationIdForReminder(task.id, i, k),
            title: reminderNotificationTitle(dates, task, spec, today: today),
            body: task.note,
            at: plans[k].at,
            match: plans[k].match,
            payload: spec.kind == ReminderKind.alarm ? alarmPayload(task.id) : taskPayload(task.id),
            alarm: spec.kind == ReminderKind.alarm,
          ));
        }
      }
    }

    // 稍后提醒：完成后（不重复的任务）不再响
    final snooze = task.snoozedUntil;
    final finished = !task.isRepeating && task.completedAt != null;
    if (snooze != null && !finished) {
      final at = tz.TZDateTime.from(snooze, _location());
      if (at.isAfter(now)) {
        requests.add(ReminderRequest(
          id: notificationIdForTask(task.id, snoozeSlot),
          title: dates.l10n.reminderNotifyNow(task.title, dates.time(task.reminderAt ?? snooze)),
          body: task.note,
          at: at,
          payload: alarmPayload(task.id),
          alarm: true,
        ));
      }
    }
    return requests;
  }

  Future<ScheduleMode?> _scheduleAll(List<ReminderRequest> requests) async {
    ScheduleMode? mode;
    for (final r in requests) {
      try {
        final m = await _scheduler.schedule(r);
        if (mode != ScheduleMode.inexact) mode = m;
      } catch (e) {
        debugPrint('安排提醒失败（通知 ${r.id}）：$e');
      }
    }
    return mode;
  }
}
