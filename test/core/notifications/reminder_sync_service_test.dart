import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/reminder_scheduler.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late FakeScheduler scheduler;
  late ReminderSyncService sync;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
    scheduler = FakeScheduler();
    sync = ReminderSyncService(
      scheduler: scheduler,
      repository: repo,
      clock: clock,
      // 与 clock 的本地时间一致：用 UTC 位置避免依赖测试机时区
      location: () => tz.UTC,
    );
  });
  tearDown(() => db.close());

  // 测试机本地时间与 tz.UTC 不同，所以用 TZDateTime.from 换算后比较墙上时间不可靠；
  // 这里只断言是否安排、id、payload 和重复方式。
  Future<Task> make(TaskDraft d) => repo.create(d, now: clock.value);

  test('有提醒的任务：按任务 id 安排，payload 指向任务', () async {
    final t = await make(TaskDraft(title: '开会', note: '带电脑', reminderAt: DateTime(2026, 10, 31, 9)));
    final mode = await sync.syncTask(t);
    expect(mode, ScheduleMode.exact);
    final req = scheduler.pending[notificationIdForTask(t.id)]!;
    expect(req.title, '开会');
    expect(req.body, '带电脑');
    expect(parseTaskPayload(req.payload), t.id);
    expect(scheduler.log, ['cancel ${t.id}', 'schedule ${t.id}']);
  });

  test('没有精确闹钟权限：降级为不精确', () async {
    scheduler.exactAllowed = false;
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    expect(await sync.syncTask(t), ScheduleMode.inexact);
    expect(scheduler.pending, contains(t.id));
  });

  test('不重复任务完成后：取消且不再安排', () async {
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    await sync.syncTask(t);
    final done = await repo.setCompleted(t.id, clock.value, now: clock.value);
    expect(await sync.syncTask(done!), isNull);
    expect(scheduler.pending, isEmpty);
  });

  test('重复任务今天完成后：仍然安排（从下一次开始）', () async {
    final t = await make(TaskDraft(
      title: 'a',
      reminderAt: DateTime(2026, 10, 1, 9),
      reminderRepeat: RepeatRule.daily,
    ));
    final done = await repo.setCompleted(t.id, clock.value, now: clock.value);
    await sync.syncTask(done!);
    expect(scheduler.pending, contains(t.id));
  });

  test('删除任务：取消提醒', () async {
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    await sync.syncTask(t);
    await sync.cancelTask(t.id);
    expect(scheduler.pending, isEmpty);
  });

  test('去掉提醒后再同步：只取消', () async {
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    await sync.syncTask(t);
    final edited = await repo.update(t.id, const TaskDraft(title: 'a'), now: clock.value);
    await sync.syncTask(edited!);
    expect(scheduler.pending, isEmpty);
  });

  test('resyncAll：先清空，再只安排需要提醒的任务', () async {
    final a = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    await make(const TaskDraft(title: '无提醒'));
    final c = await make(TaskDraft(title: '已完成', reminderAt: DateTime(2026, 10, 31, 9)));
    await repo.setCompleted(c.id, clock.value, now: clock.value);
    scheduler.pending[999] = scheduler.pending[a.id] ??
        ReminderRequest(id: 999, title: '残留', at: tz.TZDateTime.now(tz.UTC));

    await sync.resyncAll();
    expect(scheduler.log.first, 'cancelAll');
    expect(scheduler.pending.keys, [a.id]);
  });

  test('平台不支持：什么都不做', () async {
    final unsupported = FakeScheduler(supported: false);
    final s = ReminderSyncService(scheduler: unsupported, repository: repo, clock: clock);
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    expect(await s.syncTask(t), isNull);
    await s.resyncAll();
    expect(unsupported.log, isEmpty);
  });

  test('调度抛异常：不向外抛，返回 null', () async {
    scheduler.throwOnSchedule = true;
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    expect(await sync.syncTask(t), isNull);
  });
}
