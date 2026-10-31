import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 编辑弹层：多个提前量、通知 / 闹钟、基准时间、一句话摘要。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  late TaskRepository repo;
  final clock = FixedClock(DateTime(2026, 11, 2, 8));

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  Future<void> openTask(WidgetTester tester, String title, {AppSettings settings = AppSettings.defaults}) async {
    await tester.pumpWidget(testApp(db, clock: clock, settings: settings));
    await tester.pumpAndSettle();
    await tester.tapNav('任务');
    await tester.tap(find.text(title));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tapVisible(tester, find.text('保存'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('任务有时间时添加提醒：以任务时间为基准，默认选中设置里的提前量和方式', (tester) async {
    phone(tester);
    final t = await tester.db(() => repo.create(
          TaskDraft(title: '交房租', dueAt: DateTime(2026, 11, 3, 14), dueHasTime: true),
          now: clock.value,
        ));
    await openTask(
      tester,
      '交房租',
      settings: const AppSettings(reminderOffsets: [1440, 15], reminderKind: ReminderKind.alarm),
    );

    await tapVisible(tester, find.text('+ 添加提醒'));
    expect(find.text('任务时间'), findsOneWidget);
    expect(find.textContaining('明天 14:00，提前 1 天（闹钟）和15 分钟（闹钟）'), findsOneWidget);

    await save(tester);
    final specs = await tester.db(() => repo.remindersFor(t.id));
    expect(specs, const [ReminderSpec(1440, ReminderKind.alarm), ReminderSpec(15, ReminderKind.alarm)]);
    expect((await tester.db(() => repo.getById(t.id)))!.reminderAt, DateTime(2026, 11, 3, 14));
    await finish(tester);
  });

  testWidgets('多选提前量（最多 5 个）、切换通知 / 闹钟，摘要随之更新并保存', (tester) async {
    phone(tester);
    final t = await tester.db(() => repo.create(
          TaskDraft(
            title: '开会',
            dueAt: DateTime(2026, 11, 3, 14),
            dueHasTime: true,
            reminderAt: DateTime(2026, 11, 3, 14),
            reminders: const [ReminderSpec(0)],
          ),
          now: clock.value,
        ));
    await openTask(tester, '开会');

    await tapVisible(tester, find.text('提前 15 分钟'));
    await tapVisible(tester, find.text('提前 1 天'));
    expect(find.textContaining('提前 1 天和15 分钟'), findsWidgets);

    // 15 分钟那条改成闹钟
    await tapVisible(tester, find.bySemanticsLabel('提前 15 分钟：通知，点按切换'));
    expect(find.textContaining('15 分钟（闹钟）'), findsWidgets);

    // 准时 + 15 分钟 + 1 天，再选 2 个就满 5 个；第 6 个点不动
    for (final label in ['提前 5 分钟', '提前 30 分钟']) {
      await tapVisible(tester, find.text(label));
    }
    expect(find.text('最多 5 个提醒'), findsOneWidget);
    await tapVisible(tester, find.text('提前 1 小时'));

    await save(tester);
    final specs = await tester.db(() => repo.remindersFor(t.id));
    expect(specs.map((s) => s.offsetMinutes), [1440, 30, 15, 5, 0]);
    expect(specs.firstWhere((s) => s.offsetMinutes == 15).kind, ReminderKind.alarm);
    await finish(tester);
  });

  testWidgets('改任务时间后提醒跟着更新（锚点跟随任务时间）', (tester) async {
    phone(tester);
    final t = await tester.db(() => repo.create(
          TaskDraft(
            title: '看牙',
            dueAt: DateTime(2026, 11, 3, 14),
            dueHasTime: true,
            reminderAt: DateTime(2026, 11, 3, 14),
            reminders: const [ReminderSpec(15)],
          ),
          now: clock.value,
        ));
    await openTask(tester, '看牙');
    expect(find.text('任务时间'), findsOneWidget);

    // 把日期改成"今天"（时间不变）
    await tapVisible(tester, find.bySemanticsLabel('今天').last);
    await save(tester);
    final saved = await tester.db(() => repo.getById(t.id));
    expect(saved!.reminderAt, DateTime(2026, 11, 2, 14));
    expect(await tester.db(() => repo.remindersFor(t.id)), const [ReminderSpec(15)]);
    await finish(tester);
  });

  testWidgets('清掉任务时间：提醒保留在原来的时间（不再跟随）；之后改日期不影响提醒', (tester) async {
    phone(tester);
    final t = await tester.db(() => repo.create(
          TaskDraft(
            title: '看牙',
            dueAt: DateTime(2026, 11, 3, 14),
            dueHasTime: true,
            reminderAt: DateTime(2026, 11, 3, 14),
            reminders: const [ReminderSpec(15)],
          ),
          now: clock.value,
        ));
    await openTask(tester, '看牙');
    await tapVisible(tester, find.bySemanticsLabel('清除时间'));
    expect(find.text('任务时间'), findsNothing);
    await tapVisible(tester, find.bySemanticsLabel('今天').last);
    await save(tester);
    final saved = await tester.db(() => repo.getById(t.id));
    expect(saved!.dueHasTime, isFalse);
    expect(saved.reminderAt, DateTime(2026, 11, 3, 14));
    await finish(tester);
  });

  testWidgets('每天重复：提前 ≥1 天的选项置灰，已选的被去掉', (tester) async {
    phone(tester);
    await tester.db(() => repo.create(
          TaskDraft(
            title: '吃药',
            dueAt: DateTime(2026, 11, 3, 9),
            dueHasTime: true,
            reminderAt: DateTime(2026, 11, 3, 9),
            reminders: const [ReminderSpec(1440), ReminderSpec(15)],
          ),
          now: clock.value,
        ));
    await openTask(tester, '吃药');
    await tapVisible(tester, find.bySemanticsLabel('每天'));
    expect(find.text('09:00 · 每天，提前 15 分钟'), findsOneWidget);
    final oneDay = tester
        .widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>))
        .items
        .firstWhere((i) => i.value == 1440);
    expect(oneDay.enabled, isFalse);
    await finish(tester);
  });

  testWidgets('取消最后一个提前量 = 去掉提醒', (tester) async {
    phone(tester);
    final t = await tester.db(() => repo.create(
          TaskDraft(
            title: '跑步',
            dueAt: DateTime(2026, 11, 3, 7),
            dueHasTime: true,
            reminderAt: DateTime(2026, 11, 3, 7),
            reminders: const [ReminderSpec(0)],
          ),
          now: clock.value,
        ));
    await openTask(tester, '跑步');
    await tapVisible(tester, find.text('准时'));
    expect(find.text('+ 添加提醒'), findsOneWidget);
    await save(tester);
    expect(await tester.db(() => repo.remindersFor(t.id)), isEmpty);
    expect((await tester.db(() => repo.getById(t.id)))!.reminderAt, isNull);
    await finish(tester);
  });
}
