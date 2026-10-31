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

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  late TaskRepository repo;
  late FakeScheduler scheduler;
  late ReminderSyncService sync;
  final clock = FixedClock(DateTime(2026, 11, 3, 13));

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
    scheduler = FakeScheduler();
    // 与本机在这一天的 UTC 偏移一致的时区：测试时钟是本机时间，同步服务按这个时区解释当地钟点
    sync = ReminderSyncService(scheduler: scheduler, repository: repo, clock: clock, location: () => deviceLocation(clock.value));
  });
  tearDown(() => db.close());

  Future<Task> alarmTask({RepeatRule repeat = RepeatRule.none}) => repo.create(
    TaskDraft(
      title: '交房租',
      reminderAt: DateTime(2026, 11, 3, 14),
      reminderRepeat: repeat,
      reminders: const [ReminderSpec(15, ReminderKind.alarm), ReminderSpec(0)],
    ),
    now: clock.value,
  );

  Future<void> act(String action, int taskId) =>
      applyNotificationAction(actionId: action, taskId: taskId, repository: repo, sync: sync, clock: clock);

  group('「完成 / 稍后」', () {
    test('完成：任务记为完成，这个任务的所有提醒（包括正在响的）都取消', () async {
      final t = await alarmTask();
      await sync.syncTask(t);
      final ringing = notificationIdForReminder(t.id, 0, 0);
      scheduler.showing.add(ringing);

      await act(actionDone, t.id);
      expect((await repo.getById(t.id))!.completedAt, clock.value);
      expect(scheduler.requestsFor(t.id), isEmpty);
      expect(scheduler.showing, isNot(contains(ringing)));
    });

    test('完成重复任务：只完成今天，之后的提醒照常', () async {
      final t = await alarmTask(repeat: RepeatRule.daily);
      await act(actionDone, t.id);
      final reqs = scheduler.requestsFor(t.id);
      expect(reqs, isNotEmpty);
      // 今天的 14:00 不再响，最早是明天
      expect(reqs.every((r) => r.at.isAfter(DateTime(2026, 11, 4))), isTrue);
    });

    test('稍后：10 分钟后再响一次（闹钟方式），写进数据库，全量重建后仍在', () async {
      final t = await alarmTask();
      await act(actionSnooze, t.id);
      expect((await repo.getById(t.id))!.snoozedUntil, clock.value.add(const Duration(minutes: 10)));
      final snooze = scheduler.pending[notificationIdForTask(t.id, snoozeSlot)];
      expect(snooze, isNotNull);
      expect(snooze!.alarm, isTrue);
      expect(snooze.at.millisecondsSinceEpoch, clock.value.add(const Duration(minutes: 10)).millisecondsSinceEpoch);

      await sync.resyncAll();
      expect(scheduler.pending[notificationIdForTask(t.id, snoozeSlot)], isNotNull);
    });

    test('稍后之后又完成：稍后提醒也取消', () async {
      final t = await alarmTask();
      await act(actionSnooze, t.id);
      await act(actionDone, t.id);
      expect(scheduler.pending[notificationIdForTask(t.id, snoozeSlot)], isNull);
      expect((await repo.getById(t.id))!.snoozedUntil, isNull);
    });

    test('任务已删除：只取消它的通知，不报错', () async {
      final t = await alarmTask();
      await sync.syncTask(t);
      await repo.delete(t.id);
      await act(actionDone, t.id);
      expect(scheduler.requestsFor(t.id), isEmpty);
    });

    test('闹钟提醒的 payload 能被识别为闹钟', () async {
      final t = await alarmTask();
      await sync.syncTask(t);
      final reqs = scheduler.requestsFor(t.id);
      expect(isAlarmPayload(reqs.firstWhere((r) => r.alarm).payload), isTrue);
      expect(isAlarmPayload(reqs.firstWhere((r) => !r.alarm).payload), isFalse);
      expect(parseTaskPayload(alarmPayload(t.id)), t.id);
    });
  });

  group('通知点按分流', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        reminderSyncProvider.overrideWithValue(sync),
      ]);
    });
    tearDown(() => container.dispose());

    test('点「完成」按钮：直接处理，不打开任何页面', () async {
      final t = await alarmTask();
      await handleNotificationTap(container, NotificationTap(payload: alarmPayload(t.id), actionId: actionDone, notificationId: 1));
      expect((await repo.getById(t.id))!.completedAt, isNotNull);
      expect(container.read(pendingAlarmProvider), isNull);
      expect(container.read(pendingNavigationProvider), isNull);
    });

    test('闹钟还在响（全屏拉起）：显示闹钟页；冷启动时标记从锁屏来', () async {
      final t = await alarmTask();
      final id = notificationIdForReminder(t.id, 0, 0);
      scheduler.showing.add(id);
      await handleNotificationTap(container, NotificationTap(payload: alarmPayload(t.id), notificationId: id), coldStart: true);
      final alarm = container.read(pendingAlarmProvider)!;
      expect((alarm.taskId, alarm.notificationId, alarm.fromLockScreen), (t.id, id, true));
    });

    test('闹钟已经不在通知栏 / 普通提醒：打开任务', () async {
      final t = await alarmTask();
      await handleNotificationTap(container, NotificationTap(payload: alarmPayload(t.id), notificationId: 99));
      expect(container.read(pendingAlarmProvider), isNull);
      expect(container.read(pendingNavigationProvider), t.id);

      container.read(pendingNavigationProvider.notifier).clear();
      await handleNotificationTap(container, NotificationTap(payload: taskPayload(t.id), notificationId: 5));
      expect(container.read(pendingNavigationProvider), t.id);
    });
  });
}
