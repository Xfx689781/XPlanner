import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/utils/format.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/plan/reminder_summary.dart';
import 'package:facet/features/plan/task_editor_sheet.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 编辑弹层的边界：没有时间时两步选择、锚点跟随 / 不再跟随、自定义提前量、重复规则切换、旧数据、多语言摘要。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  late TaskRepository repo;
  final clock = FixedClock(DateTime(2026, 11, 2, 8)); // 周一

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
  });

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

  Future<void> openTask(
    WidgetTester tester,
    String title, {
    AppSettings settings = AppSettings.defaults,
    String nav = '任务',
  }) async {
    await tester.pumpWidget(testApp(
      db,
      clock: clock,
      settings: settings,
      overrides: [reminderSchedulerProvider.overrideWithValue(FakeScheduler())],
    ));
    await tester.pumpAndSettle();
    await tester.tapNav(nav);
    await tester.tap(find.text(title));
    await settle(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, {String label = '保存'}) async {
    await tapVisible(tester, find.text(label));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder f) => find.descendant(of: find.byType(TaskEditorSheet), matching: f);
  Finder inDate(Finder f) => find.descendant(of: find.byType(DatePickerDialog), matching: f);
  Finder inTime(Finder f) => find.descendant(of: find.byType(TimePickerDialog), matching: f);

  /// 桌面端时间选择器是输入框：输入时、分后确定
  Future<void> typeTime(WidgetTester tester, int hour, int minute) async {
    final fields = inTime(find.byType(TextField));
    await tester.enterText(fields.at(0), '$hour');
    await tester.enterText(fields.at(1), minute.toString().padLeft(2, '0'));
    await tester.pump();
    await tester.tap(inTime(find.text('确定')));
    await tester.pumpAndSettle();
  }

  Future<Task> seed(WidgetTester tester, TaskDraft d) => tester.db(() => repo.create(d, now: clock.value));

  group('没有时间的任务：添加提醒走"日期 → 时间"两步', () {
    testWidgets('取消日期：不添加；取消时间：不添加；两步都确定：添加，基准时间显示具体日期时间', (tester) async {
      phone(tester);
      final t = await seed(tester, TaskDraft(title: '体检', dueAt: DateTime(2026, 11, 5)));
      await openTask(tester, '体检');

      // 第一步就取消
      await tapVisible(tester, find.text('+ 添加提醒'));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(inDate(find.text('取消')));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(find.text('+ 添加提醒'), findsOneWidget);

      // 日期确定、时间取消
      await tapVisible(tester, find.text('+ 添加提醒'));
      await tester.tap(inDate(find.text('确定')));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(inTime(find.text('取消')));
      await tester.pumpAndSettle();
      expect(find.text('+ 添加提醒'), findsOneWidget);

      // 两步都确定：默认是任务那天 9:00
      await tapVisible(tester, find.text('+ 添加提醒'));
      await tester.tap(inDate(find.text('确定')));
      await tester.pumpAndSettle();
      await tester.tap(inTime(find.text('确定')));
      await tester.pumpAndSettle();
      expect(find.text('+ 添加提醒'), findsNothing);
      expect(find.text('任务时间'), findsNothing);
      expect(find.textContaining('09:00，准时'), findsWidgets);

      await save(tester);
      expect((await tester.db(() => repo.getById(t.id)))!.reminderAt, DateTime(2026, 11, 5, 9));
      expect(await tester.db(() => repo.remindersFor(t.id)), const [ReminderSpec(0)]);
      await finish(tester);
    });

    testWidgets('没有日期也没有时间：初始为下一个整点（今天 9:00），选另一天', (tester) async {
      phone(tester);
      final t = await seed(tester, const TaskDraft(title: '买菜'));
      await openTask(tester, '买菜');
      await tapVisible(tester, find.text('+ 添加提醒'));
      await tester.tap(inDate(find.text('7')));
      await tester.pumpAndSettle();
      await tester.tap(inDate(find.text('确定')));
      await tester.pumpAndSettle();
      await tester.tap(inTime(find.text('确定')));
      await tester.pumpAndSettle();
      await save(tester);
      expect((await tester.db(() => repo.getById(t.id)))!.reminderAt, DateTime(2026, 11, 7, 9));
      await finish(tester);
    });
  });

  group('锚点跟随任务时间', () {
    testWidgets('改任务时间（14:00 → 16:30）：提醒跟着变', (tester) async {
      phone(tester);
      final t = await seed(tester, TaskDraft(
        title: '看牙',
        dueAt: DateTime(2026, 11, 3, 14),
        dueHasTime: true,
        reminderAt: DateTime(2026, 11, 3, 14),
        reminders: const [ReminderSpec(15)],
      ));
      await openTask(tester, '看牙');
      await tapVisible(tester, inSheet(find.text('14:00')));
      await typeTime(tester, 16, 30);
      expect(find.text('任务时间'), findsOneWidget);
      expect(find.textContaining('明天 16:30，提前 15 分钟'), findsWidgets);
      await save(tester);
      expect((await tester.db(() => repo.getById(t.id)))!.reminderAt, DateTime(2026, 11, 3, 16, 30));
      await finish(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('去掉任务时间：锚点保留原值（14:00）并保存', (tester) async {
      phone(tester);
      final t = await seed(tester, TaskDraft(
        title: '看牙',
        dueAt: DateTime(2026, 11, 3, 14),
        dueHasTime: true,
        reminderAt: DateTime(2026, 11, 3, 14),
        reminders: const [ReminderSpec(15)],
      ));
      await openTask(tester, '看牙');
      await tapVisible(tester, find.bySemanticsLabel('清除时间'));
      expect(find.textContaining('明天 14:00，提前 15 分钟'), findsWidgets);
      await save(tester);
      final saved = (await tester.db(() => repo.getById(t.id)))!;
      expect(saved.dueHasTime, isFalse);
      expect(saved.reminderAt, DateTime(2026, 11, 3, 14));
      expect(await tester.db(() => repo.remindersFor(t.id)), const [ReminderSpec(15)]);
      await finish(tester);
    });

    // 回归（efeaf14 已修）：去掉任务时间后 _anchorFollowsDue 仍为 true——
    // 基准时间按钮仍显示"任务时间"（任务已经没有时间了），之后再给任务加时间，锚点又会悄悄跟过去。
    // 复现：有时间的任务 + 跟随任务时间的提醒 → 清除时间 → 基准时间仍显示"任务时间"；再设 16:30 → 保存后 reminderAt = 16:30。
    testWidgets('去掉任务时间后不再跟随：基准时间显示具体日期时间；再加时间，锚点不变', (tester) async {
      phone(tester);
      final t = await seed(tester, TaskDraft(
        title: '看牙',
        dueAt: DateTime(2026, 11, 3, 14),
        dueHasTime: true,
        reminderAt: DateTime(2026, 11, 3, 14),
        reminders: const [ReminderSpec(15)],
      ));
      await openTask(tester, '看牙');
      await tapVisible(tester, find.bySemanticsLabel('清除时间'));
      expect(find.text('任务时间'), findsNothing);
      expect(inSheet(find.text('明天 14:00')), findsOneWidget);

      await tapVisible(tester, find.text('+ 时间'));
      await typeTime(tester, 16, 30);
      await save(tester);
      expect((await tester.db(() => repo.getById(t.id)))!.reminderAt, DateTime(2026, 11, 3, 14));
      await finish(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    // 回归（efeaf14 已修）：跟随任务时间时改了时间（14:00 → 16:30），再清除任务时间，锚点退回最初的 14:00，
    // 而不是用户最后看到的 16:30（_reminderAt 只在添加提醒时赋值，跟随期间不更新）。
    // 复现：任务 14:00 + 跟随的提醒 → 把任务时间改成 16:30（摘要显示 16:30）→ 清除时间 → 摘要变回 14:00，保存后 reminderAt = 14:00。
    testWidgets('改过任务时间再去掉时间：锚点保留最后的任务时间（16:30）', (tester) async {
      phone(tester);
      final t = await seed(tester, TaskDraft(
        title: '看牙',
        dueAt: DateTime(2026, 11, 3, 14),
        dueHasTime: true,
        reminderAt: DateTime(2026, 11, 3, 14),
        reminders: const [ReminderSpec(15)],
      ));
      await openTask(tester, '看牙');
      await tapVisible(tester, inSheet(find.text('14:00')));
      await typeTime(tester, 16, 30);
      await tapVisible(tester, find.bySemanticsLabel('清除时间'));
      expect(find.textContaining('明天 16:30，提前 15 分钟'), findsWidgets);
      await save(tester);
      expect((await tester.db(() => repo.getById(t.id)))!.reminderAt, DateTime(2026, 11, 3, 16, 30));
      await finish(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('改提醒基准时间为别的时间：不再跟随；改回任务时间：重新跟随', (tester) async {
      phone(tester);
      await seed(tester, TaskDraft(
        title: '看牙',
        dueAt: DateTime(2026, 11, 3, 14),
        dueHasTime: true,
        reminderAt: DateTime(2026, 11, 3, 14),
        reminders: const [ReminderSpec(0)],
      ));
      await openTask(tester, '看牙');
      await tapVisible(tester, find.text('任务时间'));
      await tester.tap(inDate(find.text('确定')));
      await tester.pumpAndSettle();
      await typeTime(tester, 10, 0);
      expect(find.text('任务时间'), findsNothing);
      expect(inSheet(find.text('明天 10:00')), findsOneWidget);

      await tapVisible(tester, inSheet(find.text('明天 10:00')));
      await tester.tap(inDate(find.text('确定')));
      await tester.pumpAndSettle();
      await typeTime(tester, 14, 0);
      expect(find.text('任务时间'), findsOneWidget);
      await finish(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  testWidgets('自定义提前量：加入后出现在列表并选中，取消选中后消失，保存不含它', (tester) async {
    phone(tester);
    final t = await seed(tester, TaskDraft(
      title: '开会',
      dueAt: DateTime(2026, 11, 3, 14),
      dueHasTime: true,
      reminderAt: DateTime(2026, 11, 3, 14),
      reminders: const [ReminderSpec(0)],
    ));
    await openTask(tester, '开会');
    await tapVisible(tester, find.text('自定义…'));
    final dialog = find.byType(Dialog);
    await tester.enterText(find.descendant(of: dialog, matching: find.byType(TextField)), '3');
    await tester.tap(find.descendant(of: dialog, matching: find.text('天')));
    await tester.pump();
    await tester.tap(find.descendant(of: dialog, matching: find.text('确定')));
    await tester.pumpAndSettle();

    expect(find.text('提前 3 天'), findsOneWidget);
    expect(tester.widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>)).selected, {0, 4320});
    expect(find.textContaining('准时和提前 3 天'), findsWidgets);

    await tapVisible(tester, find.text('提前 3 天'));
    expect(find.text('提前 3 天'), findsNothing);
    await tapVisible(tester, find.text('自定义…'));
    await tester.enterText(find.descendant(of: dialog, matching: find.byType(TextField)), '45');
    await tester.tap(find.descendant(of: dialog, matching: find.text('确定')));
    await tester.pumpAndSettle();
    await save(tester);
    expect((await tester.db(() => repo.remindersFor(t.id))).map((s) => s.offsetMinutes), [45, 0]);
    await finish(tester);
  });

  group('切换重复规则', () {
    testWidgets('每周去掉 ≥1 周的，每天再去掉 ≥1 天的；换回不重复，被去掉的不会回来', (tester) async {
      phone(tester);
      final t = await seed(tester, TaskDraft(
        title: '周报',
        dueAt: DateTime(2026, 11, 13, 17),
        dueHasTime: true,
        reminderAt: DateTime(2026, 11, 13, 17),
        reminders: const [ReminderSpec(10080), ReminderSpec(2880), ReminderSpec(60, ReminderKind.alarm), ReminderSpec(0)],
      ));
      await openTask(tester, '周报');
      await tapVisible(tester, find.bySemanticsLabel('每周'));
      expect(tester.widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>)).selected, {2880, 60, 0});
      await tapVisible(tester, find.bySemanticsLabel('每天'));
      expect(tester.widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>)).selected, {60, 0});
      await tapVisible(tester, find.bySemanticsLabel('不重复'));
      expect(tester.widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>)).selected, {60, 0});
      await save(tester);
      expect(await tester.db(() => repo.remindersFor(t.id)), const [ReminderSpec(60, ReminderKind.alarm), ReminderSpec(0)]);
      await finish(tester);
    });

    testWidgets('全部冲突：只剩"准时"，保留原来的方式（闹钟）', (tester) async {
      phone(tester);
      final t = await seed(tester, TaskDraft(
        title: '吃药',
        dueAt: DateTime(2026, 11, 3, 9),
        dueHasTime: true,
        reminderAt: DateTime(2026, 11, 3, 9),
        reminders: const [ReminderSpec(1440, ReminderKind.alarm)],
      ));
      await openTask(tester, '吃药');
      await tapVisible(tester, find.bySemanticsLabel('每天'));
      expect(find.text('09:00 · 每天，准时（闹钟）'), findsOneWidget);
      await save(tester);
      final saved = (await tester.db(() => repo.getById(t.id)))!;
      expect(saved.reminderRepeat, RepeatRule.daily);
      expect(await tester.db(() => repo.remindersFor(t.id)), const [ReminderSpec(0, ReminderKind.alarm)]);
      await finish(tester);
    });
  });

  testWidgets('旧数据（有 reminderAt、没有提醒行）：打开显示"准时"并选中，保存后补上一行', (tester) async {
    phone(tester);
    final t = await seed(tester, TaskDraft(
      title: '旧任务',
      dueAt: DateTime(2026, 11, 3, 14),
      dueHasTime: true,
      reminderAt: DateTime(2026, 11, 3, 14),
    ));
    await tester.db(() => (db.delete(db.taskReminders)..where((r) => r.taskId.equals(t.id))).go());
    await openTask(tester, '旧任务');
    expect(find.text('明天 14:00，准时'), findsOneWidget);
    expect(tester.widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>)).selected, {0});
    expect(find.text('任务时间'), findsOneWidget);
    await save(tester);
    expect(await tester.db(() => repo.remindersFor(t.id)), const [ReminderSpec(0)]);
    await finish(tester);
  });

  group('摘要文字：English / 繁體中文', () {
    final draft = TaskDraft(
      title: 'Rent',
      dueAt: DateTime(2026, 11, 3, 14),
      dueHasTime: true,
      reminderAt: DateTime(2026, 11, 3, 14),
      reminders: const [ReminderSpec(1440, ReminderKind.alarm), ReminderSpec(15), ReminderSpec(0)],
    );

    testWidgets('en：Tomorrow 14:00, on time and 1 day (alarm) and 15 minutes before', (tester) async {
      phone(tester);
      await seed(tester, draft);
      await openTask(tester, 'Rent', settings: const AppSettings(languageTag: 'en'), nav: 'Tasks');
      expect(find.text('Tomorrow 14:00, on time and 1 day (alarm) and 15 minutes before'), findsOneWidget);
      expect(find.text('Task time'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('zh-Hant：明天 14:00，準時和提前 1 天（鬧鐘）和15 分鐘', (tester) async {
      phone(tester);
      await seed(tester, draft);
      await openTask(tester, 'Rent', settings: const AppSettings(languageTag: 'zh-Hant'), nav: '任務');
      expect(find.text('明天 14:00，準時和提前 1 天（鬧鐘）和15 分鐘'), findsOneWidget);
      expect(find.text('任務時間'), findsOneWidget);
      await finish(tester);
    });

    test('reminderSummary：三项牛津逗号、准时为闹钟、每周重复', () {
      final en = AppDateFormat(lookupAppLocalizations(const Locale('en')), 'en', use24h: true);
      final hant = AppDateFormat(
        lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
        'zh_TW',
        use24h: true,
      );
      final today = DateTime(2026, 11, 2);
      final anchor = DateTime(2026, 11, 3, 14); // 周二
      const three = [ReminderSpec(1440), ReminderSpec(60), ReminderSpec(5)];
      expect(reminderSummary(en, anchor, RepeatRule.none, three, today: today),
          'Tomorrow 14:00, 1 day, 1 hour, and 5 minutes before');
      expect(reminderSummary(hant, anchor, RepeatRule.none, three, today: today), '明天 14:00，提前 1 天、1 小時和5 分鐘');
      expect(reminderSummary(en, anchor, RepeatRule.none, const [ReminderSpec(0, ReminderKind.alarm)], today: today),
          'Tomorrow 14:00, on time (alarm)');
      expect(reminderSummary(hant, anchor, RepeatRule.weekly, const [ReminderSpec(0), ReminderSpec(1440)], today: today),
          '14:00 · 每週二，準時和提前 1 天');
      expect(reminderSummary(en, anchor, RepeatRule.daily, const [ReminderSpec(30)], today: today),
          '14:00 · Every day, 30 minutes before');
      expect(reminderSummary(en, DateTime(2026, 11, 20, 9), RepeatRule.none, const [ReminderSpec(10080)], today: today),
          'Fri, Nov 20 09:00, 1 week before');
    });
  });
}
