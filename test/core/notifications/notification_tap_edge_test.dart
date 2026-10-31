import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/background_actions.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/notification_tap_handler.dart';
import 'package:facet/core/notifications/reminder_scheduler.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 与本机在 [at] 这一天的 UTC 偏移相同的固定偏移时区（Etc/GMT+5 表示 UTC-5）
tz.Location deviceLocation(DateTime at) {
  final hours = at.timeZoneOffset.inHours;
  if (hours == 0) return tz.UTC;
  return tz.getLocation('Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}');
}

/// 通知点按 / 按钮的边界：payload 格式错误、未知按钮、重复完成。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  late TaskRepository repo;
  late FakeScheduler scheduler;
  late ReminderSyncService sync;
  late ProviderContainer container;
  final clock = FixedClock(DateTime(2026, 11, 3, 13));

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
    scheduler = FakeScheduler();
    sync = ReminderSyncService(scheduler: scheduler, repository: repo, clock: clock, location: () => deviceLocation(clock.value));
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
      reminderSchedulerProvider.overrideWithValue(scheduler),
      reminderSyncProvider.overrideWithValue(sync),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<Task> alarmTask({RepeatRule repeat = RepeatRule.none, DateTime? at, List<ReminderSpec>? reminders}) => repo.create(
    TaskDraft(
      title: '交房租',
      reminderAt: at ?? DateTime(2026, 11, 3, 14),
      reminderRepeat: repeat,
      reminders: reminders ?? const [ReminderSpec(15, ReminderKind.alarm)],
    ),
    now: clock.value,
  );

  group('payload 格式错误：什么都不做', () {
    for (final payload in [null, '', 'task:', 'task:abc', 'alarm:1x', 'foo:12', '12', 'TASK:1']) {
      test('payload = ${payload == null ? 'null' : "'$payload'"}', () async {
        final t = await alarmTask();
        await handleNotificationTap(
          container,
          NotificationTap(payload: payload, actionId: actionDone, notificationId: notificationIdForReminder(t.id, 0, 0)),
        );
        await handleNotificationTap(container, NotificationTap(payload: payload, notificationId: 1));
        expect((await repo.getById(t.id))!.completedAt, isNull);
        expect(container.read(pendingAlarmProvider), isNull);
        expect(container.read(pendingNavigationProvider), isNull);
        expect(scheduler.log, isEmpty);
      });
    }
  });

  group('未知 actionId：按普通点按处理', () {
    test('普通提醒 + 未知按钮：打开任务，不改任务', () async {
      final t = await alarmTask();
      await handleNotificationTap(container, NotificationTap(payload: taskPayload(t.id), actionId: 'dismiss', notificationId: 3));
      expect(container.read(pendingNavigationProvider), t.id);
      expect(container.read(pendingAlarmProvider), isNull);
      final saved = (await repo.getById(t.id))!;
      expect((saved.completedAt, saved.snoozedUntil), (null, null));
    });

    test('闹钟还在响 + 未知按钮：显示闹钟页（不是冷启动 → 不从锁屏回去）', () async {
      final t = await alarmTask();
      final id = notificationIdForReminder(t.id, 0, 0);
      scheduler.showing.add(id);
      await handleNotificationTap(container, NotificationTap(payload: alarmPayload(t.id), actionId: 'unknown', notificationId: id));
      final alarm = container.read(pendingAlarmProvider)!;
      expect((alarm.taskId, alarm.notificationId, alarm.fromLockScreen), (t.id, id, false));
      expect((await repo.getById(t.id))!.completedAt, isNull);
    });

    test('闹钟 payload 但没有通知 id：打开任务', () async {
      final t = await alarmTask();
      await handleNotificationTap(container, NotificationTap(payload: alarmPayload(t.id)));
      expect(container.read(pendingAlarmProvider), isNull);
      expect(container.read(pendingNavigationProvider), t.id);
    });

    test('applyNotificationAction 收到未知 actionId：不改任务、不重排', () async {
      final t = await alarmTask();
      await applyNotificationAction(actionId: 'bogus', taskId: t.id, repository: repo, sync: sync, clock: clock);
      final saved = (await repo.getById(t.id))!;
      expect((saved.completedAt, saved.snoozedUntil), (null, null));
      expect(scheduler.log, isEmpty);
    });
  });

  group('重复点「完成」', () {
    test('已完成的不重复任务再点完成：completedAt 不变', () async {
      final t = await alarmTask();
      final earlier = DateTime(2026, 11, 1, 9);
      await repo.setCompleted(t.id, earlier, now: earlier);
      await applyNotificationAction(actionId: actionDone, taskId: t.id, repository: repo, sync: sync, clock: clock);
      expect((await repo.getById(t.id))!.completedAt, earlier);
      expect(scheduler.requestsFor(t.id), isEmpty);
    });

    test('今天已完成的重复任务再点完成：completedAt 不变；昨天完成的：更新为现在', () async {
      final t = await alarmTask(repeat: RepeatRule.daily);
      final morning = DateTime(2026, 11, 3, 8);
      await repo.setCompleted(t.id, morning, now: morning);
      await applyNotificationAction(actionId: actionDone, taskId: t.id, repository: repo, sync: sync, clock: clock);
      expect((await repo.getById(t.id))!.completedAt, morning);

      final yesterday = DateTime(2026, 11, 2, 8);
      await repo.setCompleted(t.id, yesterday, now: yesterday);
      await applyNotificationAction(actionId: actionDone, taskId: t.id, repository: repo, sync: sync, clock: clock);
      expect((await repo.getById(t.id))!.completedAt, clock.value);
    });

    test('已完成的不重复任务点「稍后」：记下稍后时刻但不排（完成后不再响）', () async {
      final t = await alarmTask();
      await repo.setCompleted(t.id, clock.value, now: clock.value);
      await applyNotificationAction(actionId: actionSnooze, taskId: t.id, repository: repo, sync: sync, clock: clock);
      expect(scheduler.pending[notificationIdForTask(t.id, snoozeSlot)], isNull);
    });
  });

  // 可疑行为：提前量跨零点的重复任务，在前一天晚上的闹钟上点「完成」，记成的是"今天"完成，
  // 而这个闹钟属于明天 00:10 那次；15 分钟后（明天 00:10）准时提醒照样响，明天的任务也仍显示未完成。
  // 复现：每天 00:10、提醒 [提前 15 分钟（闹钟）, 准时]；11/3 23:55 在闹钟上点「完成」→ 11/4 00:10 的准时提醒仍在排。
  test('跨零点：前一晚 23:55 的闹钟点「完成」后，明天 00:10 的准时提醒不再响', () async {
    clock.value = DateTime(2026, 11, 3, 23, 55);
    addTearDown(() => clock.value = DateTime(2026, 11, 3, 13));
    final t = await alarmTask(
      repeat: RepeatRule.daily,
      at: DateTime(2026, 11, 1, 0, 10),
      reminders: const [ReminderSpec(15, ReminderKind.alarm), ReminderSpec(0)],
    );
    await applyNotificationAction(actionId: actionDone, taskId: t.id, repository: repo, sync: sync, clock: clock);
    final onTime = scheduler.requestsFor(t.id).where((r) => (r.id - t.id * slotsPerTask) ~/ slotsPerReminder == 1);
    final tomorrow0010 = tz.TZDateTime.from(DateTime(2026, 11, 4, 0, 10), deviceLocation(clock.value));
    expect(onTime.any((r) => r.at.isAtSameMomentAs(tomorrow0010)), isFalse);
  }, skip: true);
}
