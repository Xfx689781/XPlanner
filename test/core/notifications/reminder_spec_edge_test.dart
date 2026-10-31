import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/next_trigger.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:facet/core/utils/format.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';
import '../data/task_rules_test.dart' show task;

/// 与本机在 [at] 这一天的 UTC 偏移相同的固定偏移时区（Etc/GMT+5 表示 UTC-5）
tz.Location deviceLocation(DateTime at) {
  final hours = at.timeZoneOffset.inHours;
  if (hours == 0) return tz.UTC;
  return tz.getLocation('Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}');
}

AppDateFormat fmt(String lang, {bool use24h = true}) => switch (lang) {
  'en' => AppDateFormat(lookupAppLocalizations(const Locale('en')), 'en', use24h: use24h),
  'zh-Hant' => AppDateFormat(
    lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
    'zh_TW',
    use24h: use24h,
  ),
  _ => AppDateFormat(
    lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')),
    'zh_CN',
    use24h: use24h,
  ),
};

/// planSpec / shiftBack 的边界、同步服务的槽位 / 上限排序 / 语言。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('shiftBack', () {
    test('跨年、闰年 2/29、平年 3/1 提前 1 天', () {
      expect(shiftBack(DateTime(2027, 1, 1, 0, 10), 15), DateTime(2026, 12, 31, 23, 55));
      expect(shiftBack(DateTime(2028, 3, 1, 9), 1440), DateTime(2028, 2, 29, 9));
      expect(shiftBack(DateTime(2027, 3, 1, 9), 1440), DateTime(2027, 2, 28, 9));
      expect(shiftBack(DateTime(2027, 1, 2, 9), 2880), DateTime(2026, 12, 31, 9));
      expect(shiftBack(DateTime(2026, 12, 3, 14), ReminderSpec.maxOffsetMinutes), DateTime(2026, 11, 3, 14));
    });

    test('夏令时当天按钟点算：纽约 3/8 03:30 提前 60 → 02:30（这个钟点当地并不存在）', () {
      expect(shiftBack(DateTime(2026, 3, 8, 3, 30), 60), DateTime(2026, 3, 8, 2, 30));
      // 夏令时结束当天：01:30 出现两次，按钟点 02:30 提前 60 → 01:30
      expect(shiftBack(DateTime(2026, 11, 1, 2, 30), 60), DateTime(2026, 11, 1, 1, 30));
    });
  });

  group('planSpec 边界（America/New_York）', () {
    late tz.Location ny;
    setUpAll(() => ny = tz.getLocation('America/New_York'));
    tz.TZDateTime at(int y, int m, int d, [int h = 0, int min = 0]) => tz.TZDateTime(ny, y, m, d, h, min);

    test('每周五 9:00 提前 2 天跨年：2027-01-01（周五）→ 2026-12-30（周三）', () {
      final t = task(reminderAt: DateTime(2027, 1, 1, 9), repeat: RepeatRule.weekly);
      final plans = planSpec(t, const ReminderSpec(2880), at(2026, 12, 28, 10), doneToday: false);
      expect(plans, hasLength(1));
      expect(plans.single.at, at(2026, 12, 30, 9));
      expect(plans.single.at.weekday, DateTime.wednesday);
      expect(plans.single.match, DateTimeComponents.dayOfWeekAndTime);
    });

    test('每周二 9:00 提前 2 天跨月：12/1 开始 → 11/29（周日）起；开始日在以后时用窗口', () {
      final t = task(reminderAt: DateTime(2026, 12, 1, 9), repeat: RepeatRule.weekly);
      // 现在 11/20（周五）：系统重复会先在 11/22 响，早于开始日 → 改用 2 条一次性
      final plans = planSpec(t, const ReminderSpec(2880), at(2026, 11, 20, 10), doneToday: false);
      expect(plans.map((p) => p.at), [at(2026, 11, 29, 9), at(2026, 12, 6, 9)]);
      expect(plans.every((p) => p.match == null), isTrue);
    });

    test('不重复任务提前 1 周：一次，跨年', () {
      final t = task(reminderAt: DateTime(2027, 1, 5, 9));
      final plans = planSpec(t, const ReminderSpec(10080), at(2026, 12, 20), doneToday: false);
      expect(plans.single.at, at(2026, 12, 29, 9));
      expect(plans.single.match, isNull);
    });

    test('不重复任务提前 1 周但那一刻已过：不排', () {
      final t = task(reminderAt: DateTime(2027, 1, 5, 9));
      expect(planSpec(t, const ReminderSpec(10080), at(2026, 12, 30), doneToday: false), isEmpty);
    });

    test('每周任务不能提前 1 周（与周期冲突）', () {
      final t = task(reminderAt: DateTime(2027, 1, 5, 9), repeat: RepeatRule.weekly);
      expect(planSpec(t, const ReminderSpec(10080), at(2026, 12, 20), doneToday: false), isEmpty);
    });

    test('现状：夏令时开始当天 03:30 提前 60 分钟 → 02:30 不存在，规范化到 03:30，与任务时间同一时刻响', () {
      final t = task(reminderAt: DateTime(2026, 3, 8, 3, 30));
      final plans = planSpec(t, const ReminderSpec(60), at(2026, 3, 7, 12), doneToday: false);
      final onTime = planSpec(t, const ReminderSpec(0), at(2026, 3, 7, 12), doneToday: false);
      expect(plans.single.at.hour, 3);
      expect(plans.single.at.minute, 30);
      expect(plans.single.at.timeZoneOffset, const Duration(hours: -4));
      // "提前 1 小时"实际与"准时"同一时刻（真正的 1 小时前是 01:30 EST）
      expect(plans.single.at.isAtSameMomentAs(onTime.single.at), isTrue);
    });

    test('现状：每天 03:30 提前 60 → 每天 02:30；夏令时开始当天交给系统时锚点换成一周后的 02:30', () {
      final t = task(reminderAt: DateTime(2026, 3, 1, 3, 30), repeat: RepeatRule.daily);
      final plans = planSpec(t, const ReminderSpec(60), at(2026, 3, 8, 0, 30), doneToday: false);
      expect(plans, hasLength(1));
      expect(plans.single.match, DateTimeComponents.time);
      expect((plans.single.at.month, plans.single.at.day, plans.single.at.hour, plans.single.at.minute), (3, 15, 2, 30));
    });

    test('每周开始日在 2 天后，提前 6 天使第一次落在今天之前：从下一个匹配的星期几开始，交给系统重复', () {
      // 现在 2026-11-03（周二）；锚点 11-05（周四）9:00；提前 6 天 → 10-30（周五），已过
      final t = task(reminderAt: DateTime(2026, 11, 5, 9), repeat: RepeatRule.weekly);
      final plans = planSpec(t, const ReminderSpec(6 * 1440), at(2026, 11, 3, 10), doneToday: false);
      expect(plans.single.at, at(2026, 11, 6, 9));
      expect(plans.single.at.weekday, DateTime.friday);
      expect(plans.single.match, DateTimeComponents.dayOfWeekAndTime);
    });

    test('不重复任务开始日在 2 天后，提前 1 周：那一刻已在过去 → 不排', () {
      final t = task(reminderAt: DateTime(2026, 11, 5, 9));
      expect(planSpec(t, const ReminderSpec(10080), at(2026, 11, 3, 10), doneToday: false), isEmpty);
    });

    test('每天开始于明天 00:10，提前 15 分钟：今晚 23:55 就响（属于明天的锚点）', () {
      final t = task(reminderAt: DateTime(2026, 11, 4, 0, 10), repeat: RepeatRule.daily);
      final plans = planSpec(t, const ReminderSpec(15), at(2026, 11, 3, 12), doneToday: false);
      expect(plans.single.at, at(2026, 11, 3, 23, 55));
      expect(plans.single.match, DateTimeComponents.time);
      // 23:58 再算：明晚 23:55
      final later = planSpec(t, const ReminderSpec(15), at(2026, 11, 3, 23, 58), doneToday: false);
      expect(later.single.at, at(2026, 11, 4, 23, 55));
    });

    test('每天开始日在一周后、提前 15 分钟：3 条一次性，从开始日前起', () {
      final t = task(reminderAt: DateTime(2026, 11, 10, 9), repeat: RepeatRule.daily);
      final plans = planSpec(t, const ReminderSpec(15), at(2026, 11, 3, 10), doneToday: false);
      expect(plans.map((p) => p.at), [at(2026, 11, 10, 8, 45), at(2026, 11, 11, 8, 45), at(2026, 11, 12, 8, 45)]);
    });
  });

  group('同步服务', () {
    late AppDatabase db;
    late TaskRepository repo;
    late FakeScheduler scheduler;
    late ReminderSyncService sync;
    var lang = 'zh-Hans';
    var use24h = true;
    final clock = FixedClock(DateTime(2026, 11, 3, 8));

    setUp(() {
      db = openTestDb();
      repo = TaskRepository(db);
      scheduler = FakeScheduler();
      lang = 'zh-Hans';
      use24h = true;
      sync = ReminderSyncService(
        scheduler: scheduler,
        repository: repo,
        clock: clock,
        location: () => deviceLocation(clock.value),
        dates: () => fmt(lang, use24h: use24h),
      );
    });
    tearDown(() => db.close());

    const five = [ReminderSpec(0), ReminderSpec(5), ReminderSpec(10), ReminderSpec(15), ReminderSpec(30)];

    test('5 个提醒 × 每天重复 × 今天已完成（3 条窗口）+ 稍后：16 个槽位不越界、不冲突', () async {
      final t = await repo.create(
        TaskDraft(title: '吃药', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily, reminders: five),
        now: clock.value,
      );
      await repo.setCompleted(t.id, clock.value, now: clock.value);
      await repo.setSnoozed(t.id, clock.value.add(const Duration(minutes: 10)));
      await sync.syncTask(t);

      final reqs = scheduler.requestsFor(t.id);
      expect(reqs, hasLength(5 * dailyWindow + 1));
      final ids = reqs.map((r) => r.id).toSet();
      expect(ids, hasLength(reqs.length)); // 没有重复 id
      final base = t.id * slotsPerTask;
      expect(ids.every((id) => id >= base && id < base + slotsPerTask), isTrue);
      // 第 i 个提醒（先响的在前：30、15、10、5、0）只占 i*3..i*3+2
      final offsets = [30, 15, 10, 5, 0];
      for (var i = 0; i < 5; i++) {
        final mine = reqs.where((r) => r.id - base >= i * 3 && r.id - base < i * 3 + 3).toList();
        expect(mine, hasLength(3), reason: 'reminder $i');
        for (final r in mine) {
          final local = r.at;
          expect(local.isAfter(tz.TZDateTime(local.location, 2026, 11, 4)), isTrue); // 今天跳过
          expect(local.hour * 60 + local.minute, 9 * 60 - offsets[i], reason: 'reminder $i');
          expect(r.match, isNull);
        }
      }
      // 稍后槽只放稍后提醒
      final snooze = scheduler.pending[base + snoozeSlot]!;
      expect(snooze.at.millisecondsSinceEpoch, clock.value.add(const Duration(minutes: 10)).millisecondsSinceEpoch);
      // 没有落到下一个任务的槽位
      expect(scheduler.pending.keys.where((id) => id >= base + slotsPerTask), isEmpty);
    });

    test('5 个提醒 × 每周重复 × 今天已完成（2 条窗口）：每个提醒只用自己的前 2 个槽', () async {
      // 2026-11-03 是周二
      final t = await repo.create(
        TaskDraft(title: '周会', reminderAt: DateTime(2026, 10, 6, 9), reminderRepeat: RepeatRule.weekly, reminders: five),
        now: clock.value,
      );
      await repo.setCompleted(t.id, clock.value, now: clock.value);
      await sync.syncTask(t);
      final base = t.id * slotsPerTask;
      final slots = scheduler.requestsFor(t.id).map((r) => r.id - base).toList()..sort();
      expect(slots, [0, 1, 3, 4, 6, 7, 9, 10, 12, 13]);
    });

    test('两个相邻任务都排满：id 段互不重叠', () async {
      final a = await repo.create(
        TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily, reminders: five),
        now: clock.value,
      );
      final b = await repo.create(
        TaskDraft(title: 'b', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily, reminders: five),
        now: clock.value,
      );
      for (final t in [a, b]) {
        await repo.setCompleted(t.id, clock.value, now: clock.value);
        await repo.setSnoozed(t.id, clock.value.add(const Duration(minutes: 10)));
      }
      await sync.resyncAll();
      expect(scheduler.pending, hasLength(2 * 16));
      expect(scheduler.requestsFor(a.id), hasLength(16));
      expect(scheduler.requestsFor(b.id), hasLength(16));
    });

    test('400 上限按触发时间排序，不按任务 id：后建但更早响的任务优先', () async {
      final ids = <int>[];
      // 100 个任务 × 5 个提醒 = 500 条；任务越后建越早响
      for (var i = 0; i < 100; i++) {
        final t = await repo.create(
          TaskDraft(title: 't$i', reminderAt: DateTime(2026, 11, 10, 9).add(Duration(hours: 100 - i)), reminders: five),
          now: clock.value,
        );
        ids.add(t.id);
      }
      await sync.resyncAll();
      expect(scheduler.pending, hasLength(ReminderSyncService.maxScheduled));
      // 最后建的 80 个任务（最早响）全部排满；最先建的 20 个一个都没有
      for (final id in ids.sublist(20)) {
        expect(scheduler.requestsFor(id), hasLength(5), reason: 'task $id');
      }
      for (final id in ids.sublist(0, 20)) {
        expect(scheduler.requestsFor(id), isEmpty, reason: 'task $id');
      }
      // 排上的每一条都不晚于没排上的任何一条
      final scheduled = scheduler.pending.values.map((r) => r.at).toList()..sort();
      // 没排上的最早一条：第 19 个任务（锚点 +81 小时）提前 30 分钟
      final firstDropped = DateTime(2026, 11, 10, 9).add(const Duration(hours: 81, minutes: -30));
      expect(scheduled.last.isBefore(tz.TZDateTime.from(firstDropped, scheduled.last.location)), isTrue);
    });

    test('400 上限：系统重复的提醒只计 1 条，并按下一次触发时间参与排序', () async {
      // 一个每天重复的任务（下一次是明天 7:00），加 80 个一次性任务 × 5 = 400 条，都晚于明天 7:00
      final daily = await repo.create(
        TaskDraft(title: 'daily', reminderAt: DateTime(2026, 10, 1, 7), reminderRepeat: RepeatRule.daily),
        now: clock.value,
      );
      for (var i = 0; i < 80; i++) {
        await repo.create(
          TaskDraft(title: 't$i', reminderAt: DateTime(2026, 11, 5, 9).add(Duration(hours: i)), reminders: five),
          now: clock.value,
        );
      }
      await sync.resyncAll();
      expect(scheduler.pending, hasLength(400));
      final d = scheduler.requestsFor(daily.id).single;
      expect(d.match, DateTimeComponents.time);
    });

    test('切换语言后 resyncAll：标题换成新语言（简体 → 英文 → 繁体）', () async {
      final t = await repo.create(
        TaskDraft(
          title: '交房租',
          reminderAt: DateTime(2026, 11, 4, 14),
          reminders: const [ReminderSpec(1440), ReminderSpec(15), ReminderSpec(0)],
        ),
        now: clock.value,
      );
      List<String> titles() => scheduler.requestsFor(t.id).map((r) => r.title).toList();

      await sync.resyncAll();
      expect(titles(), ['1 天后：交房租（明天 14:00）', '15 分钟后：交房租（14:00）', '交房租（14:00）']);

      lang = 'en';
      await sync.resyncAll();
      expect(titles(), ['In 1 day: 交房租 (Tomorrow 14:00)', 'In 15 minutes: 交房租 (14:00)', '交房租 (14:00)']);

      lang = 'zh-Hant';
      await sync.resyncAll();
      expect(titles(), ['1 天後：交房租（明天 14:00）', '15 分鐘後：交房租（14:00）', '交房租（14:00）']);
    });

    test('12 小时制：标题里的时间按 12 小时制（英文 2:00 PM，繁体 下午2:00；简体按 intl 习惯仍是 24 小时制）', () async {
      final t = await repo.create(
        TaskDraft(title: 'Rent', reminderAt: DateTime(2026, 11, 3, 14), reminders: const [ReminderSpec(60), ReminderSpec(0)]),
        now: clock.value,
      );
      use24h = false;
      lang = 'en';
      await sync.syncTask(t);
      final en = scheduler.requestsFor(t.id).map((r) => r.title).toList();
      expect(en[0], matches(RegExp(r'^In 1 hour: Rent \(2:00\sPM\)$')));
      expect(en[1], matches(RegExp(r'^Rent \(2:00\sPM\)$')));

      lang = 'zh-Hant';
      await sync.syncTask(t);
      expect(scheduler.requestsFor(t.id).first.title, '1 小時後：Rent（下午2:00）');

      // 现状（format_test 已记录）：简体中文 intl 的 jm 也是 24 小时制
      lang = 'zh-Hans';
      await sync.syncTask(t);
      expect(scheduler.requestsFor(t.id).first.title, '1 小时后：Rent（14:00）');
    });

    test('稍后提醒的标题用准时格式、带锚点时间', () async {
      final t = await repo.create(
        TaskDraft(title: '交房租', reminderAt: DateTime(2026, 11, 3, 14), reminders: const [ReminderSpec(15)]),
        now: clock.value,
      );
      await repo.setSnoozed(t.id, clock.value.add(const Duration(minutes: 10)));
      await sync.syncTask(t);
      expect(scheduler.pending[notificationIdForTask(t.id, snoozeSlot)]!.title, '交房租（14:00）');
    });
  });
}
