import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 设置页「提醒」分组：默认提前量多选（最多 5 个、不能全部取消）、自定义对话框、默认方式。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  setUp(() => db = openTestDb());

  Widget app() => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      reminderSchedulerProvider.overrideWithValue(FakeScheduler()),
    ],
    child: localizedApp(const SettingsPage()),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await settle(tester);
  }

  Future<void> openReminders(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('提醒'));
    await tester.pumpAndSettle();
  }

  Future<List<int>> saved(WidgetTester tester) async => (await tester.db(() => SettingsRepository(db).load())).reminderOffsets;

  Set<int> selected(WidgetTester tester) => tester.widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>)).selected;

  GeoButton customButton(WidgetTester tester) => tester.widget<GeoButton>(find.widgetWithText(GeoButton, '自定义…'));

  testWidgets('最多选 5 个：满了之后其余项和"自定义…"都置灰，点不动；取消一个后又能选', (tester) async {
    phone(tester);
    await openReminders(tester);
    for (final label in ['提前 5 分钟', '提前 10 分钟', '提前 15 分钟', '提前 30 分钟']) {
      await tapVisible(tester, find.text(label));
    }
    expect(await saved(tester), [30, 15, 10, 5, 0]);
    expect(find.text('最多 5 个提醒'), findsOneWidget);
    expect(customButton(tester).onPressed, isNull);

    await tapVisible(tester, find.text('提前 1 小时'));
    expect(selected(tester), {0, 5, 10, 15, 30});
    expect(await saved(tester), [30, 15, 10, 5, 0]);

    // 已选的项仍可取消
    await tapVisible(tester, find.text('提前 10 分钟'));
    expect(await saved(tester), [30, 15, 5, 0]);
    expect(find.text('最多 5 个提醒'), findsNothing);
    await tapVisible(tester, find.text('提前 1 小时'));
    expect(await saved(tester), [60, 30, 15, 5, 0]);
    await finish(tester);
  });

  testWidgets('全部取消不保存：只剩"准时"时点它，仍是选中、数据库不变', (tester) async {
    phone(tester);
    await openReminders(tester);
    await tapVisible(tester, find.text('提前 15 分钟'));
    await tapVisible(tester, find.text('准时'));
    expect(await saved(tester), [15]);

    await tapVisible(tester, find.text('提前 15 分钟'));
    expect(selected(tester), {15});
    expect(await saved(tester), [15]);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  group('自定义对话框', () {
    Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);

    Future<void> openCustom(WidgetTester tester) async {
      await tapVisible(tester, find.text('自定义…'));
      expect(find.text('自定义提醒'), findsOneWidget);
    }

    Future<void> submit(WidgetTester tester, String amount, {String? unit}) async {
      await tester.enterText(inDialog(find.byType(TextField)), amount);
      await tester.pump();
      if (unit != null) {
        await tester.tap(inDialog(find.text(unit)));
        await tester.pump();
      }
      await tester.tap(inDialog(find.text('确定')));
      await settle(tester);
    }

    testWidgets('输入 90 分钟：加入列表并保存', (tester) async {
      phone(tester);
      await openReminders(tester);
      await openCustom(tester);
      await submit(tester, '90');
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('提前 90 分钟'), findsOneWidget);
      expect(await saved(tester), [90, 0]);
      await finish(tester);
    });

    testWidgets('输入 2 小时：等于预设"提前 2 小时"，选中它', (tester) async {
      phone(tester);
      await openReminders(tester);
      await openCustom(tester);
      await submit(tester, '2', unit: '小时');
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('提前 2 小时'), findsOneWidget); // 不会多出一行重复的
      expect(await saved(tester), [120, 0]);
      await finish(tester);
    });

    testWidgets('输入 30 天合法；31 天、0、非数字都提示非法、对话框不关', (tester) async {
      phone(tester);
      await openReminders(tester);
      await openCustom(tester);
      for (final (amount, unit) in [('31', '天'), ('0', null), ('abc', null), ('-3', null)]) {
        await submit(tester, amount, unit: unit);
        expect(find.byType(Dialog), findsOneWidget, reason: amount);
        expect(find.text('请输入 1 分钟到 30 天之间的值'), findsOneWidget, reason: amount);
      }
      // 改输入后提示消失
      await tester.enterText(inDialog(find.byType(TextField)), '30');
      await tester.pump();
      expect(find.text('请输入 1 分钟到 30 天之间的值'), findsNothing);
      await tester.tap(inDialog(find.text('确定')));
      await settle(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('提前 30 天'), findsOneWidget);
      expect(await saved(tester), [ReminderSpec.maxOffsetMinutes, 0]);
      await finish(tester);
    });

    testWidgets('取消：什么都不加', (tester) async {
      phone(tester);
      await openReminders(tester);
      await openCustom(tester);
      await tester.enterText(inDialog(find.byType(TextField)), '45');
      await tester.tap(inDialog(find.text('取消')));
      await settle(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('提前 45 分钟'), findsNothing);
      expect(await saved(tester), [0]);
      await finish(tester);
    });

    testWidgets('自定义项可取消选中：取消后从列表中消失', (tester) async {
      phone(tester);
      await openReminders(tester);
      await openCustom(tester);
      await submit(tester, '90');
      await tapVisible(tester, find.text('提前 90 分钟'));
      expect(await saved(tester), [0]);
      expect(find.text('提前 90 分钟'), findsNothing);
      await finish(tester);
    });
  });

  testWidgets('默认方式切换为闹钟后，编辑页新建的提醒默认是闹钟', (tester) async {
    phone(tester);
    final clock = FixedClock(DateTime(2026, 11, 2, 8));
    final repo = TaskRepository(db);
    final t = await tester.db(() => repo.create(
      TaskDraft(title: '交房租', dueAt: DateTime(2026, 11, 3, 14), dueHasTime: true),
      now: clock.value,
    ));
    await tester.pumpWidget(testApp(db, clock: clock, overrides: [reminderSchedulerProvider.overrideWithValue(FakeScheduler())]));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提醒').first);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('闹钟'));
    expect((await tester.db(() => SettingsRepository(db).load())).reminderKind, ReminderKind.alarm);

    // 手机：分组页 → 设置主页 → 回到 App
    while (find.bySemanticsLabel('返回').evaluate().isNotEmpty) {
      await tester.tap(find.bySemanticsLabel('返回').last);
      await tester.pumpAndSettle();
    }
    await tester.tapNav('任务');
    await tester.tap(find.text('交房租'));
    await settle(tester);
    await tapVisible(tester, find.text('+ 添加提醒'));
    expect(find.textContaining('准时（闹钟）'), findsOneWidget);
    expect(find.bySemanticsLabel('准时：闹钟，点按切换'), findsOneWidget);

    // 编辑页里新勾选的提前量也用默认方式
    await tapVisible(tester, find.text('提前 15 分钟'));
    await tapVisible(tester, find.text('保存'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(await tester.db(() => repo.remindersFor(t.id)), const [
      ReminderSpec(15, ReminderKind.alarm),
      ReminderSpec(0, ReminderKind.alarm),
    ]);
    await finish(tester);
  });
}
