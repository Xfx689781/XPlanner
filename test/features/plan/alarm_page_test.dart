import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/notification_tap_handler.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/plan/alarm_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  late TaskRepository repo;
  final clock = FixedClock(DateTime(2026, 11, 3, 13, 45));

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
  });

  Future<Task> seed(WidgetTester tester) => tester.db(() => repo.create(
    TaskDraft(
      title: '交房租',
      priority: Priority.high,
      reminderAt: DateTime(2026, 11, 3, 14),
      reminders: const [ReminderSpec(15, ReminderKind.alarm)],
    ),
    now: clock.value,
  ));

  Future<ProviderContainer> showAlarm(WidgetTester tester, FakeScheduler scheduler, Task t, int notificationId) async {
    await tester.pumpWidget(testApp(db, clock: clock, overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)]));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(DayCircle)));
    container.read(pendingAlarmProvider.notifier).open(AlarmRequest(taskId: t.id, notificationId: notificationId));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  testWidgets('闹钟页：任务方块（高优先级粗描边）、时间、标题、两个大按钮', (tester) async {
    final t = await seed(tester);
    await showAlarm(tester, FakeScheduler(), t, notificationIdForReminder(t.id, 0, 0));

    expect(find.byType(AlarmPage), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('交房租'), findsWidgets);
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('稍后 10 分钟'), findsOneWidget);
    final square = tester.widget<TaskSquare>(find.descendant(of: find.byType(AlarmPage), matching: find.byType(TaskSquare)));
    expect(square.strokeWidth, Stroke.bold);
    expect(tester.getSize(find.widgetWithText(GeoButton, '完成')).height, greaterThanOrEqualTo(Sizes.largeButton));
    await finish(tester);
  });

  testWidgets('点「完成」：停止响铃、任务完成、关闭闹钟页', (tester) async {
    final t = await seed(tester);
    final scheduler = FakeScheduler();
    final id = notificationIdForReminder(t.id, 0, 0);
    scheduler.showing.add(id);
    await showAlarm(tester, scheduler, t, id);

    await tester.tap(find.text('完成'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(scheduler.showing, isNot(contains(id)));
    expect((await tester.db(() => repo.getById(t.id)))!.completedAt, isNotNull);
    expect(find.byType(AlarmPage), findsNothing);
    await finish(tester);
  });

  testWidgets('点「稍后 10 分钟」：停止响铃，10 分钟后再响', (tester) async {
    final t = await seed(tester);
    final scheduler = FakeScheduler();
    final id = notificationIdForReminder(t.id, 0, 0);
    scheduler.showing.add(id);
    await showAlarm(tester, scheduler, t, id);

    await tester.tap(find.text('稍后 10 分钟'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(scheduler.showing, isNot(contains(id)));
    expect((await tester.db(() => repo.getById(t.id)))!.snoozedUntil, clock.value.add(const Duration(minutes: 10)));
    expect(scheduler.pending[notificationIdForTask(t.id, snoozeSlot)], isNotNull);
    expect(find.byType(AlarmPage), findsNothing);
    await finish(tester);
  });

  testWidgets('设置页显示全屏闹钟状态（测试环境无法检测 → 灰色"无法检测"，不显示开启按钮）', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(db, clock: clock, overrides: [reminderSchedulerProvider.overrideWithValue(FakeScheduler())]));
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提醒').first);
    await tester.pumpAndSettle();
    expect(find.text('全屏闹钟'), findsOneWidget);
    expect(find.text('新建提醒的默认方式'), findsOneWidget);
    await finish(tester);
  });
}
