import 'package:facet/app/theme.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/features/settings/settings_page.dart';
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
  setUp(() => db = openTestDb());

  Widget app(FakeScheduler scheduler) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      reminderSchedulerProvider.overrideWithValue(scheduler),
    ],
    child: MaterialApp(theme: buildFacetTheme(Brightness.light), home: const SettingsPage()),
  );

  Future<void> setWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  Future<void> openSection(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  testWidgets('手机：主页显示各分组当前值，没有"数据"分组', (tester) async {
    await setWidth(tester, 390);
    await tester.pumpWidget(app(FakeScheduler()));
    await tester.pumpAndSettle();

    for (final t in ['通用', '外观', '提醒', '关于']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('数据'), findsNothing);
    expect(find.text('跟随系统'), findsOneWidget); // 外观的当前值
    expect(find.text('准时'), findsOneWidget); // 提醒的当前值
    await finish(tester);
  });

  testWidgets('手机：进入外观选深色，返回后主页显示深色，并已写入数据库', (tester) async {
    await setWidth(tester, 390);
    await tester.pumpWidget(app(FakeScheduler()));
    await tester.pumpAndSettle();

    await openSection(tester, '外观');
    await tester.tap(find.text('深色'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('返回').first);
    await tester.pumpAndSettle();

    expect(find.text('深色'), findsOneWidget);
    final saved = await tester.db(() => SettingsRepository(db).load());
    expect(saved.theme, ThemePreference.dark);
    await finish(tester);
  });

  testWidgets('宽窗口：左右两栏，点左侧分组切换右侧内容', (tester) async {
    await setWidth(tester, 1100);
    await tester.pumpWidget(app(FakeScheduler()));
    await tester.pumpAndSettle();

    // 默认选中"通用"，右侧直接可见
    expect(find.text('一周从哪天开始'), findsOneWidget);
    await tester.tap(find.text('关于'));
    await tester.pumpAndSettle();
    expect(find.text('一周从哪天开始'), findsNothing);
    expect(find.textContaining('只保存在这台设备上'), findsOneWidget);
    // 没有进入子页面（没有发生路由跳转）
    expect(find.byType(SettingsSectionPage), findsNothing);
    await finish(tester);
  });

  testWidgets('通知或闹钟权限没开：主页提醒一项显示警示', (tester) async {
    await setWidth(tester, 390);
    await tester.pumpWidget(app(FakeScheduler(exactAllowed: false)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('提醒.*需要处理')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('权限都开着、或平台不支持提醒：不显示警示', (tester) async {
    await setWidth(tester, 390);
    await tester.pumpWidget(app(FakeScheduler()));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('需要处理')), findsNothing);

    await tester.pumpWidget(app(FakeScheduler(supported: false, exactAllowed: false)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('需要处理')), findsNothing);
    await finish(tester);
  });

  testWidgets('提醒分组：没有精确闹钟权限时能跳去开启', (tester) async {
    await setWidth(tester, 390);
    final scheduler = FakeScheduler(exactAllowed: false);
    await tester.pumpWidget(app(scheduler));
    await tester.pumpAndSettle();
    await openSection(tester, '提醒');

    expect(find.text('未开启，提醒可能晚几分钟到十几分钟'), findsOneWidget);
    await tester.tap(find.text('去开启'));
    expect(scheduler.log, contains('requestExactAlarmPermission'));
    await finish(tester);
  });

  testWidgets('提醒分组：通知权限未开启时点开启会申请', (tester) async {
    await setWidth(tester, 390);
    final scheduler = FakeScheduler()..notificationsOn = false;
    await tester.pumpWidget(app(scheduler));
    await tester.pumpAndSettle();
    await openSection(tester, '提醒');

    await tester.tap(find.text('开启'));
    await tester.pumpAndSettle();
    expect(scheduler.log, contains('requestNotificationPermission'));
    await finish(tester);
  });

  testWidgets('提醒分组：测试通知安排在 5 秒后，使用保留 id', (tester) async {
    await setWidth(tester, 390);
    final scheduler = FakeScheduler();
    await tester.pumpWidget(app(scheduler));
    await tester.pumpAndSettle();
    await openSection(tester, '提醒');

    await tester.scrollUntilVisible(find.text('5 秒后发一条测试通知'), 200);
    await tester.tap(find.text('5 秒后发一条测试通知'));
    await tester.pumpAndSettle();
    expect(scheduler.pending.keys, [testNotificationId]);
    expect(find.text('5 秒后会弹出一条通知，可以先锁屏'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('提醒分组：默认提前时间可选并保存', (tester) async {
    await setWidth(tester, 390);
    await tester.pumpWidget(app(FakeScheduler()));
    await tester.pumpAndSettle();
    await openSection(tester, '提醒');

    await tester.tap(find.text('提前 15 分钟'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    final saved = await tester.db(() => SettingsRepository(db).load());
    expect(saved.reminderLead, ReminderLead.min15);
    await finish(tester);
  });

  testWidgets('提醒分组：三星省电说明可见；平台不支持时给出说明', (tester) async {
    await setWidth(tester, 390);
    await tester.pumpWidget(app(FakeScheduler()));
    await tester.pumpAndSettle();
    await openSection(tester, '提醒');
    expect(find.text('三星手机：防止提醒被拦截'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('返回').first);
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(FakeScheduler(supported: false)));
    await tester.pumpAndSettle();
    await openSection(tester, '提醒');
    expect(find.textContaining('这个平台暂不支持提醒'), findsOneWidget);
    await finish(tester);
  });
}
