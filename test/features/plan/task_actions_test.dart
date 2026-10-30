import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/reminder_scheduler.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:facet/features/plan/task_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late FakeScheduler scheduler;
  late ProviderContainer container;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    db = openTestDb();
    scheduler = FakeScheduler();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
      reminderSchedulerProvider.overrideWithValue(scheduler),
      reminderSyncProvider.overrideWith((ref) => ReminderSyncService(
        scheduler: scheduler,
        repository: ref.watch(taskRepositoryProvider),
        clock: clock,
        location: () => tz.UTC,
      )),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  TaskActions actions() => container.read(taskActionsProvider);

  test('新建带提醒的任务会安排通知', () async {
    final (t, _) = await actions().create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    expect(scheduler.pending, contains(t.id));
  });

  test('完成不重复任务会取消通知，取消完成会重新安排', () async {
    final (t, _) = await actions().create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    final done = await actions().toggleDone(t);
    expect(done!.completedAt, isNotNull);
    expect(scheduler.pending, isEmpty);

    final undone = await actions().toggleDone(done);
    expect(undone!.completedAt, isNull);
    expect(scheduler.pending, contains(t.id));
  });

  test('完成重复任务：提醒保留（下一次）', () async {
    final (t, _) = await actions().create(TaskDraft(
      title: 'a',
      reminderAt: DateTime(2026, 10, 1, 9),
      reminderRepeat: RepeatRule.daily,
    ));
    await actions().toggleDone(t);
    expect(scheduler.pending, contains(t.id));
  });

  test('删除任务会取消通知', () async {
    final (t, _) = await actions().create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    await actions().delete(t.id);
    expect(scheduler.pending, isEmpty);
  });

  test('更新不存在的任务：返回 (null, null) 并取消可能残留的提醒', () async {
    final (task, mode) = await actions().update(999, TaskDraft(title: 'x', reminderAt: DateTime(2026, 10, 31, 9)));
    expect(task, isNull);
    expect(mode, isNull);
    expect(scheduler.log, ['cancel 999']);
    expect(scheduler.pending, isEmpty);
  });

  test('更新：去掉提醒后只取消，不再安排', () async {
    final (t, _) = await actions().create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    scheduler.log.clear();
    final (updated, mode) = await actions().update(t.id, const TaskDraft(title: 'a'));
    expect(updated!.reminderAt, isNull);
    expect(mode, isNull);
    expect(scheduler.log, ['cancel ${t.id}']);
    expect(scheduler.pending, isEmpty);
  });

  test('更新：把提醒改到未来会重新安排并返回调度方式', () async {
    final (t, _) = await actions().create(const TaskDraft(title: 'a'));
    final (_, mode) = await actions().update(t.id, TaskDraft(title: 'a', reminderAt: DateTime(2026, 11, 2, 9)));
    expect(mode, ScheduleMode.exact);
    expect(scheduler.pending, contains(t.id));
  });

  test('新建：提醒已经过去的一次性任务不安排，返回 null', () async {
    final (t, mode) = await actions().create(TaskDraft(title: 'a', reminderAt: DateTime(2020, 1, 1, 9)));
    expect(mode, isNull);
    expect(scheduler.pending, isNot(contains(t.id)));
  });

  test('重复任务昨天完成过：今天点完成会把它标成今天完成', () async {
    final (t, _) = await actions().create(TaskDraft(
      title: 'a',
      reminderAt: DateTime(2026, 10, 1, 9),
      reminderRepeat: RepeatRule.daily,
    ));
    final repo = container.read(taskRepositoryProvider);
    final yesterday = await repo.setCompleted(t.id, DateTime(2026, 10, 29, 23, 59), now: clock.value);
    final toggled = await actions().toggleDone(yesterday!);
    expect(toggled!.completedAt, clock.value);
  });

  test('重复任务今天已完成：再点一次取消完成，提醒仍在', () async {
    final (t, _) = await actions().create(TaskDraft(
      title: 'a',
      reminderAt: DateTime(2026, 10, 1, 9),
      reminderRepeat: RepeatRule.weekly,
    ));
    final done = await actions().toggleDone(t);
    final undone = await actions().toggleDone(done!);
    expect(undone!.completedAt, isNull);
    expect(scheduler.pending, contains(t.id));
  });

  test('toggleDone 的任务已被删除：返回 null，不安排提醒', () async {
    final (t, _) = await actions().create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 31, 9)));
    await container.read(taskRepositoryProvider).delete(t.id);
    scheduler.log.clear();
    expect(await actions().toggleDone(t), isNull);
    expect(scheduler.log, isEmpty);
  });
}
