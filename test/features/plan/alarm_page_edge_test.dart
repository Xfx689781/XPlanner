import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/notification_tap_handler.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/plan/alarm_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 闹钟页：从锁屏拉起时处理完回到锁屏（SystemNavigator.pop）、锁屏显示开关的平台通道。
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
      reminderAt: DateTime(2026, 11, 3, 14),
      reminders: const [ReminderSpec(15, ReminderKind.alarm)],
    ),
    now: clock.value,
  ));

  Future<void> showAlarm(WidgetTester tester, FakeScheduler scheduler, AlarmRequest request) async {
    await tester.pumpWidget(testApp(db, clock: clock, overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)]));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(DayCircle)));
    container.read(pendingAlarmProvider.notifier).open(request);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  /// 记录 SystemChannels.platform 上的调用
  List<String> mockPlatform(WidgetTester tester) {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    return calls;
  }

  for (final (label, action) in [('完成', 'done'), ('稍后 10 分钟', 'snooze')]) {
    testWidgets('从锁屏拉起（fromLockScreen）：点「$label」停止响铃、处理任务，然后 SystemNavigator.pop 回到锁屏', (tester) async {
      final calls = mockPlatform(tester);
      final t = await seed(tester);
      final scheduler = FakeScheduler();
      final id = notificationIdForReminder(t.id, 0, 0);
      scheduler.showing.add(id);
      await showAlarm(tester, scheduler, AlarmRequest(taskId: t.id, notificationId: id, fromLockScreen: true));

      await tester.tap(find.text(label));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      expect(calls, contains('SystemNavigator.pop'));
      expect(scheduler.showing, isNot(contains(id)));
      final saved = (await tester.db(() => repo.getById(t.id)))!;
      if (action == 'done') {
        expect(saved.completedAt, clock.value);
      } else {
        expect(saved.snoozedUntil, clock.value.add(const Duration(minutes: 10)));
      }
      await finish(tester);
    });
  }

  testWidgets('不是从锁屏拉起：关闭闹钟页，不调用 SystemNavigator.pop', (tester) async {
    final calls = mockPlatform(tester);
    final t = await seed(tester);
    final id = notificationIdForReminder(t.id, 0, 0);
    await showAlarm(tester, FakeScheduler(), AlarmRequest(taskId: t.id, notificationId: id));
    await tester.tap(find.text('完成'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(calls, isNot(contains('SystemNavigator.pop')));
    expect(find.byType(AlarmPage), findsNothing);
    await finish(tester);
  });

  testWidgets('连点两次「完成」：只处理一次（第二次时按钮已禁用）', (tester) async {
    mockPlatform(tester);
    final t = await seed(tester);
    final scheduler = FakeScheduler();
    final id = notificationIdForReminder(t.id, 0, 0);
    await showAlarm(tester, scheduler, AlarmRequest(taskId: t.id, notificationId: id, fromLockScreen: true));
    await tester.tap(find.text('完成'));
    await tester.pump();
    final done = tester.widget<GeoButton>(find.widgetWithText(GeoButton, '完成'));
    expect(done.onPressed, isNull);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(scheduler.log.where((l) => l == 'cancel $id').length, greaterThanOrEqualTo(1));
    await finish(tester);
  });

  // setShowOnLockScreen 只在 Android（dart:io Platform.isAndroid）上走 'facet/system_settings' 通道，
  // 而且它是 extension 方法、无法通过替换 systemSettingsProvider 打桩，测试主机（Windows）上验证不到 true/false 两次调用。
  // 这里只验证非 Android 平台优雅降级：进入 / 离开闹钟页都不访问通道、不报错。
  testWidgets('非 Android：进入 / 离开闹钟页不调用 facet/system_settings，不报错', (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('facet/system_settings');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    final t = await seed(tester);
    await showAlarm(tester, FakeScheduler(), AlarmRequest(taskId: t.id, notificationId: notificationIdForReminder(t.id, 0, 0)));
    expect(find.byType(AlarmPage), findsOneWidget);
    await tester.tap(find.text('稍后 10 分钟'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmPage), findsNothing);
    expect(calls.where((c) => c.method == 'setShowOnLockScreen'), isEmpty);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('任务已被删除：闹钟页只显示按钮，点「完成」不报错并关闭', (tester) async {
    final t = await seed(tester);
    await tester.db(() => repo.delete(t.id));
    final scheduler = FakeScheduler();
    await showAlarm(tester, scheduler, AlarmRequest(taskId: t.id, notificationId: notificationIdForReminder(t.id, 0, 0)));
    expect(find.text('交房租'), findsNothing);
    await tester.tap(find.text('完成'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmPage), findsNothing);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
