import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
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
}
