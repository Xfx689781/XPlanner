import 'package:facet/app/theme.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/fake_scheduler.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  Widget app(FakeScheduler scheduler) => ProviderScope(
    overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
    child: MaterialApp(theme: buildFacetTheme(Brightness.light), home: const SettingsPage()),
  );

  testWidgets('没有精确闹钟权限：显示提示并能跳去开启', (tester) async {
    final scheduler = FakeScheduler(exactAllowed: false);
    await tester.pumpWidget(app(scheduler));
    await tester.pumpAndSettle();

    expect(find.text('未开启，提醒可能晚几分钟到十几分钟'), findsOneWidget);
    await tester.tap(find.text('去开启'));
    expect(scheduler.log, contains('requestExactAlarmPermission'));
  });

  testWidgets('通知权限未开启：点开启会申请', (tester) async {
    final scheduler = FakeScheduler()..notificationsOn = false;
    await tester.pumpWidget(app(scheduler));
    await tester.pumpAndSettle();

    await tester.tap(find.text('开启'));
    await tester.pumpAndSettle();
    expect(scheduler.log, contains('requestNotificationPermission'));
  });

  testWidgets('测试通知：安排在 5 秒后，使用保留 id', (tester) async {
    final scheduler = FakeScheduler();
    await tester.pumpWidget(app(scheduler));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5 秒后发一条测试通知'));
    await tester.pumpAndSettle();
    expect(scheduler.pending.keys, [testNotificationId]);
    expect(find.text('5 秒后会弹出一条通知，可以先锁屏'), findsOneWidget);
  });

  testWidgets('三星省电说明可见', (tester) async {
    await tester.pumpWidget(app(FakeScheduler()));
    await tester.pumpAndSettle();
    expect(find.text('三星手机：防止提醒被拦截'), findsOneWidget);
    expect(find.textContaining('不受限制'), findsWidgets);
  });

  testWidgets('平台不支持提醒时给出说明，不崩溃', (tester) async {
    await tester.pumpWidget(app(FakeScheduler(supported: false)));
    await tester.pumpAndSettle();
    expect(find.textContaining('这个平台暂不支持提醒'), findsOneWidget);
  });
}
