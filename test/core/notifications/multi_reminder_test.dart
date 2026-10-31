import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/next_trigger.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:facet/core/notifications/reminder_text.dart';
import 'package:facet/core/utils/format.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';
import '../data/task_rules_test.dart' show task;

AppDateFormat zh() => AppDateFormat(lookupAppLocalizations(const Locale('zh')), 'zh_CN', use24h: true);
AppDateFormat en() => AppDateFormat(lookupAppLocalizations(const Locale('en')), 'en', use24h: true);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('提前量文字', () {
    test('按最大整单位显示，中英文复数', () {
      final l = en().l10n;
      expect(durationLabel(l, 5), '5 minutes');
      expect(durationLabel(l, 60), '1 hour');
      expect(durationLabel(l, 90), '90 minutes');
      expect(durationLabel(l, 1440), '1 day');
      expect(durationLabel(l, 2880), '2 days');
      expect(durationLabel(l, 10080), '1 week');
      expect(durationLabel(zh().l10n, 120), '2 小时');
      expect(leadOptionLabel(zh().l10n, 0), '准时');
      expect(leadOptionLabel(zh().l10n, 15), '提前 15 分钟');
      expect(leadOptionLabel(l, 1440), '1 day before');
    });

    test('列表连接：中文"和/、"，英文牛津逗号', () {
      expect(joinList(zh().l10n, ['1 天', '15 分钟']), '1 天和15 分钟');
      expect(joinList(zh().l10n, ['A', 'B', 'C']), 'A、B和C');
      expect(joinList(en().l10n, ['A', 'B', 'C']), 'A, B, and C');
      expect(joinList(en().l10n, ['A']), 'A');
    });

    test('通知标题："15 分钟后：交房租（14:00）"；准时只有任务名和时间；≥1 天带日期', () {
      final t = task(reminderAt: DateTime(2026, 11, 3, 14)).copyWith(title: '交房租');
      final today = DateTime(2026, 11, 2);
      expect(reminderNotificationTitle(zh(), t, const ReminderSpec(15), today: today), '15 分钟后：交房租（14:00）');
      expect(reminderNotificationTitle(zh(), t, const ReminderSpec(0), today: today), '交房租（14:00）');
      expect(reminderNotificationTitle(zh(), t, const ReminderSpec(1440), today: today), '1 天后：交房租（明天 14:00）');
      expect(reminderNotificationTitle(en(), t, const ReminderSpec(60), today: today), 'In 1 hour: 交房租 (14:00)');
    });

    test('标题里的日期按触发那天算，与排程那天无关；跨零点也写"明天"', () {
      final t = task(reminderAt: DateTime(2026, 11, 3, 14)).copyWith(title: '交房租');
      // 一周前排程：触发在 11-02，对那天来说锚点是"明天"
      expect(reminderNotificationTitle(zh(), t, const ReminderSpec(1440), today: DateTime(2026, 10, 27)), '1 天后：交房租（明天 14:00）');
      // 今晚 23:55 提醒明早 00:10
      final night = task(reminderAt: DateTime(2026, 11, 4, 0, 10)).copyWith(title: '交房租');
      expect(reminderNotificationTitle(zh(), night, const ReminderSpec(15), today: DateTime(2026, 11, 3)), '15 分钟后：交房租（明天 00:10）');
      final daily = night.copyWith(reminderRepeat: RepeatRule.daily);
      expect(reminderNotificationTitle(zh(), daily, const ReminderSpec(15), today: DateTime(2026, 11, 3)), '15 分钟后：交房租（明天 00:10）');
    });

    test('每周重复提前 ≥1 天：系统每周重复同一标题，只写星期几', () {
      // 2026-11-03 是周二
      final t = task(reminderAt: DateTime(2026, 11, 3, 14), repeat: RepeatRule.weekly).copyWith(title: '交房租');
      final today = DateTime(2026, 11, 2);
      expect(reminderNotificationTitle(zh(), t, const ReminderSpec(1440), today: today), '1 天后：交房租（周二 14:00）');
      expect(reminderNotificationTitle(en(), t, const ReminderSpec(2880), today: today), 'In 2 days: 交房租 (Tue 14:00)');
    });
  });

  group('ReminderSpec', () {
    test('去重、过滤与重复周期冲突的、先响的在前、最多 5 个', () {
      final specs = ReminderSpec.normalize([
        const ReminderSpec(15),
        const ReminderSpec(15, ReminderKind.alarm),
        const ReminderSpec(1440),
        const ReminderSpec(0),
        const ReminderSpec(-5),
        const ReminderSpec(ReminderSpec.maxOffsetMinutes + 1),
      ], RepeatRule.daily);
      expect(specs.map((s) => s.offsetMinutes), [15, 0]); // 1 天被每天重复过滤
      expect(ReminderSpec.normalize([for (var i = 0; i < 8; i++) ReminderSpec(i * 10)], RepeatRule.none), hasLength(5));
    });

    test('shiftBack 按当地钟点：提前 15 分钟跨零点、提前 1 天跨月、夏令时当天钟点不变', () {
      expect(shiftBack(DateTime(2026, 11, 3, 0, 10), 15), DateTime(2026, 11, 2, 23, 55));
      expect(shiftBack(DateTime(2026, 12, 1, 14), 1440), DateTime(2026, 11, 30, 14));
      expect(shiftBack(DateTime(2026, 3, 8, 9), 60), DateTime(2026, 3, 8, 8));
      expect(shiftBack(DateTime(2027, 1, 1, 9), 10080), DateTime(2026, 12, 25, 9));
    });
  });

  group('完成的是哪一天的那次', () {
    test('payload 带提前量；旧格式仍能解析；格式不对返回 null', () {
      expect(alarmPayload(12, 15), 'alarm:12:15');
      expect((parseTaskPayload('alarm:12:15'), parseReminderOffset('alarm:12:15')), (12, 15));
      expect((parseTaskPayload('task:12'), parseReminderOffset('task:12')), (12, null));
      expect(parseTaskPayload('alarm:12:x'), isNull);
      expect(parseTaskPayload('task:12:1:2'), isNull);
    });

    test('每天 00:10、提前 15 分钟：今晚 23:55 之后点完成 → 明天；只看准时那条 → 今天', () {
      final t = task(reminderAt: DateTime(2026, 11, 1, 0, 10), repeat: RepeatRule.daily);
      const specs = [ReminderSpec(15), ReminderSpec(0)];
      expect(occurrenceDayForAction(t, specs, DateTime(2026, 11, 3, 23, 56)), DateTime(2026, 11, 4));
      expect(occurrenceDayForAction(t, specs, DateTime(2026, 11, 3, 23, 56), offsetMinutes: 0), DateTime(2026, 11, 3));
      expect(occurrenceDayForAction(t, specs, DateTime(2026, 11, 4, 0, 12)), DateTime(2026, 11, 4));
    });

    test('今天的提醒还没响（点的是以前的旧通知）：按今天', () {
      final t = task(reminderAt: DateTime(2026, 11, 1, 14), repeat: RepeatRule.daily);
      expect(occurrenceDayForAction(t, const [ReminderSpec(0)], DateTime(2026, 11, 3, 13)), DateTime(2026, 11, 3));
    });

    test('每周二 14:00 提前 1 天：周一的提醒上点完成 → 周二；跨月', () {
      // 2026-11-03 是周二
      final t = task(reminderAt: DateTime(2026, 11, 3, 14), repeat: RepeatRule.weekly);
      const specs = [ReminderSpec(1440)];
      expect(occurrenceDayForAction(t, specs, DateTime(2026, 11, 30, 14, 1)), DateTime(2026, 12, 1));
      expect(occurrenceDayForAction(t, specs, DateTime(2026, 11, 2, 14, 1), offsetMinutes: 1440), DateTime(2026, 11, 3));
    });

    test('不重复任务：总是今天', () {
      final t = task(reminderAt: DateTime(2026, 11, 10, 14));
      expect(occurrenceDayForAction(t, const [ReminderSpec(1440)], DateTime(2026, 11, 9, 14, 1)), DateTime(2026, 11, 9));
    });
  });

  group('planSpec', () {
    late tz.Location ny;
    setUpAll(() => ny = tz.getLocation('America/New_York'));
    tz.TZDateTime at(int y, int m, int d, [int h = 0, int min = 0]) => tz.TZDateTime(ny, y, m, d, h, min);

    test('每天 9:00 提前 15 分钟 → 每天 8:45 交给系统重复', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      final plans = planSpec(t, const ReminderSpec(15), at(2026, 10, 30, 7), doneToday: false);
      expect(plans.single.at, at(2026, 10, 30, 8, 45));
      expect(plans.single.match, isNotNull);
    });

    test('今天已完成：今天 8:45 那条跳过', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      final plans = planSpec(t, const ReminderSpec(15), at(2026, 10, 30, 7), doneToday: true);
      expect(plans.first.at, at(2026, 10, 31, 8, 45));
    });

    test('跨零点：锚点 00:10 提前 15 分钟，今天已完成时今晚 23:55（属于明天的锚点）不跳过', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 0, 10), repeat: RepeatRule.daily);
      final plans = planSpec(t, const ReminderSpec(15), at(2026, 10, 30, 12), doneToday: true);
      expect(plans.first.at, at(2026, 10, 30, 23, 55));
    });

    test('每周五 9:00 提前 1 天 → 每周四 9:00', () {
      final t = task(reminderAt: DateTime(2026, 10, 2, 9), repeat: RepeatRule.weekly); // 周五
      final plans = planSpec(t, const ReminderSpec(1440), at(2026, 10, 27, 7), doneToday: false);
      expect(plans.first.at.weekday, DateTime.thursday);
      expect(plans.first.at, at(2026, 10, 29, 9));
    });

    test('与重复周期冲突的提前量不排', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      expect(planSpec(t, const ReminderSpec(1440), at(2026, 10, 30, 7), doneToday: false), isEmpty);
    });
  });

  group('同步服务', () {
    late AppDatabase db;
    late TaskRepository repo;
    late FakeScheduler scheduler;
    late ReminderSyncService sync;
    final clock = FixedClock(DateTime(2026, 11, 2, 8));

    setUp(() {
      db = openTestDb();
      repo = TaskRepository(db);
      scheduler = FakeScheduler();
      sync = ReminderSyncService(
        scheduler: scheduler,
        repository: repo,
        clock: clock,
        location: () => tz.UTC,
        dates: zh,
      );
    });
    tearDown(() => db.close());

    test('一个任务三个提醒：各占自己的槽位，标题写明还有多久，闹钟那条带闹钟标记', () async {
      final t = await repo.create(
        TaskDraft(
          title: '交房租',
          reminderAt: DateTime(2026, 11, 3, 14),
          reminders: const [ReminderSpec(1440), ReminderSpec(15, ReminderKind.alarm), ReminderSpec(0)],
        ),
        now: clock.value,
      );
      await sync.syncTask(t);
      final reqs = scheduler.requestsFor(t.id);
      expect(reqs.map((r) => r.title), ['1 天后：交房租（明天 14:00）', '15 分钟后：交房租（14:00）', '交房租（14:00）']);
      expect(reqs.map((r) => r.alarm), [false, true, false]);
      expect(isAlarmPayload(reqs[1].payload), isTrue);
      expect(reqs.map((r) => r.id), [
        notificationIdForReminder(t.id, 0, 0),
        notificationIdForReminder(t.id, 1, 0),
        notificationIdForReminder(t.id, 2, 0),
      ]);
    });

    test('改任务时间后提醒跟着更新；完成后全部取消；删除后全部取消', () async {
      final t = await repo.create(
        TaskDraft(title: 'a', reminderAt: DateTime(2026, 11, 3, 14), reminders: const [ReminderSpec(15), ReminderSpec(0)]),
        now: clock.value,
      );
      await sync.syncTask(t);
      final updated = await repo.update(
        t.id,
        TaskDraft(title: 'a', reminderAt: DateTime(2026, 11, 3, 16), reminders: const [ReminderSpec(15), ReminderSpec(0)]),
        now: clock.value,
      );
      await sync.syncTask(updated!);
      expect(scheduler.requestsFor(t.id).map((r) => r.at.hour), [15, 16]);

      final done = await repo.setCompleted(t.id, clock.value, now: clock.value);
      await sync.syncTask(done!);
      expect(scheduler.requestsFor(t.id), isEmpty);

      final undone = await repo.setCompleted(t.id, null, now: clock.value);
      await sync.syncTask(undone!);
      expect(scheduler.requestsFor(t.id), hasLength(2));
      await repo.delete(t.id);
      await sync.cancelTask(t.id);
      expect(scheduler.requestsFor(t.id), isEmpty);
      expect(await repo.remindersFor(t.id), isEmpty);
    });

    test('稍后提醒：排在专用槽位，全量重建后仍在；完成后取消', () async {
      final t = await repo.create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 11, 2, 7)), now: clock.value);
      await repo.setSnoozed(t.id, clock.value.add(ReminderSyncService.snoozeDuration));
      await sync.resyncAll();
      final snooze = scheduler.pending[notificationIdForTask(t.id, snoozeSlot)];
      expect(snooze, isNotNull);
      expect(snooze!.alarm, isTrue);

      final done = await repo.setCompleted(t.id, clock.value, now: clock.value);
      await sync.syncTask(done!);
      expect(scheduler.pending[notificationIdForTask(t.id, snoozeSlot)], isNull);
    });

    test('旧数据（v2 迁移来的、没有提醒行）按准时处理', () async {
      final t = await repo.create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 11, 3, 9)), now: clock.value);
      await (db.delete(db.taskReminders)..where((r) => r.taskId.equals(t.id))).go();
      await sync.syncTask(t);
      expect(scheduler.requestsFor(t.id).single.at.hour, 9);
    });

    test('全量重建只排最早的 400 条', () async {
      for (var i = 0; i < 90; i++) {
        await repo.create(
          TaskDraft(
            title: 't$i',
            reminderAt: DateTime(2026, 11, 10, 9).add(Duration(hours: i)),
            reminders: const [ReminderSpec(0), ReminderSpec(5), ReminderSpec(10), ReminderSpec(15), ReminderSpec(30)],
          ),
          now: clock.value,
        );
      }
      await sync.resyncAll();
      expect(scheduler.pending, hasLength(ReminderSyncService.maxScheduled));
      // 排上的是最早的那些
      final latestScheduled = scheduler.pending.values.map((r) => r.at).reduce((a, b) => a.isAfter(b) ? a : b);
      expect(latestScheduled.isBefore(tz.TZDateTime.utc(2026, 11, 14)), isTrue);
    });
  });
}
