import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 同步服务交给系统的触发时间（墙上钟点、时区、重复方式）。
/// 时钟用 UTC 时刻，避免依赖测试机所在时区。
void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late FakeScheduler scheduler;
  late tz.Location location;
  late FixedClock clock;
  late ReminderSyncService sync;

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
    scheduler = FakeScheduler();
    location = tz.getLocation('America/New_York');
    clock = FixedClock(DateTime.utc(2026, 10, 30, 12)); // 纽约 08:00（EDT）
    sync = ReminderSyncService(scheduler: scheduler, repository: repo, clock: clock, location: () => location);
  });
  tearDown(() => db.close());

  Future<Task> make(TaskDraft d) => repo.create(d, now: clock.value);

  test('每天 9:00：今天纽约 08:00 → 今天纽约 09:00，按 time 重复', () async {
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily));
    await sync.syncTask(t);
    final req = scheduler.requestsFor(t.id).first;
    expect(req.at.location.name, 'America/New_York');
    expect((req.at.month, req.at.day, req.at.hour, req.at.minute), (10, 30, 9, 0));
    expect(req.match, DateTimeComponents.time);
  });

  test('每周：按 dayOfWeekAndTime 重复，星期几正确', () async {
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 7, 9), reminderRepeat: RepeatRule.weekly)); // 周三
    await sync.syncTask(t);
    final req = scheduler.requestsFor(t.id).first;
    expect(req.match, DateTimeComponents.dayOfWeekAndTime);
    expect((req.at.month, req.at.day, req.at.weekday), (11, 4, DateTime.wednesday));
  });

  test('夏令时结束前一天同步：明天 9:00 用 -5 偏移', () async {
    clock.value = DateTime.utc(2026, 10, 31, 15); // 纽约 11:00 EDT
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily));
    await sync.syncTask(t);
    final at = scheduler.requestsFor(t.id).first.at;
    expect((at.month, at.day, at.hour), (11, 1, 9));
    expect(at.timeZoneOffset, const Duration(hours: -5));
    expect(at.toUtc(), DateTime.utc(2026, 11, 1, 14));
  });

  test('重复任务刚刚完成（同一时刻）：从明天开始', () async {
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily));
    final done = await repo.setCompleted(t.id, clock.value, now: clock.value);
    await sync.syncTask(done!);
    final at = scheduler.requestsFor(t.id).first.at;
    expect((at.month, at.day, at.hour), (10, 31, 9));
  });

  test('换时区后 resyncAll：同一任务改为新时区的当地 9:00', () async {
    final t = await make(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily));
    await sync.resyncAll();
    final inNy = scheduler.requestsFor(t.id).first.at;

    location = tz.getLocation('Asia/Tokyo'); // 此刻东京 21:00，今天的 9:00 已过
    await sync.resyncAll();
    final inTokyo = scheduler.requestsFor(t.id).first.at;
    expect(inTokyo.location.name, 'Asia/Tokyo');
    expect((inTokyo.month, inTokyo.day, inTokyo.hour), (10, 31, 9));
    expect(inTokyo.toUtc(), isNot(inNy.toUtc()));
    expect(scheduler.log.where((l) => l == 'cancelAllPending').length, 2);
  });

  test('resyncAll 大量数据：300 个任务，只安排需要的那些', () async {
    final expected = <int>{};
    for (var i = 0; i < 300; i++) {
      final kind = i % 3;
      final t = await make(TaskDraft(
        title: 't$i',
        reminderAt: switch (kind) {
          0 => DateTime(2026, 11, 1, 9), // 未来一次性
          1 => DateTime(2026, 10, 1, 9), // 已过的一次性
          _ => DateTime(2026, 10, 1, 7, 30), // 每天重复
        },
        reminderRepeat: kind == 2 ? RepeatRule.daily : RepeatRule.none,
      ));
      if (kind != 1) expected.add(t.id);
    }
    await sync.resyncAll();
    expect(scheduler.taskIds.toSet(), expected);
    expect(scheduler.pending.length, 200);
  });
}
