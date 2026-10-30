import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 任务编辑弹层"+ 添加提醒"按设置里的"新建提醒时默认提前"预填时间。
void main() {
  late AppDatabase db;
  late TaskRepository repo;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
  });

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<Task> seedTask(WidgetTester tester, {required int hour, int minute = 0, bool hasTime = true}) {
    return tester.db(() => repo.create(
          TaskDraft(title: '看牙', dueAt: DateTime(2026, 10, 30, hour, minute), dueHasTime: hasTime),
          now: clock.value,
        ));
  }

  Future<void> openEditorAndAddReminder(WidgetTester tester) async {
    await tester.tap(find.text('看牙'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ 添加提醒'));
    await tester.pumpAndSettle();
  }

  TimeOfDay pickerInitial(WidgetTester tester) =>
      tester.widget<TimePickerDialog>(find.byType(TimePickerDialog)).initialTime;

  MaterialLocalizations l10n(WidgetTester tester) =>
      MaterialLocalizations.of(tester.element(find.byType(TimePickerDialog)));

  testWidgets('设置页选"提前 15 分钟" → 任务今天 10:00 → 添加提醒的时间选择器初始是 09:45，确定后保存为 9:45',
      (tester) async {
    phone(tester);
    final task = await seedTask(tester, hour: 10);
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.pumpAndSettle();

    // 通过界面改设置
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提醒'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提前 15 分钟'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    await openEditorAndAddReminder(tester);
    expect(pickerInitial(tester), const TimeOfDay(hour: 9, minute: 45));

    await tester.tap(find.text(l10n(tester).okButtonLabel));
    await tester.pumpAndSettle();
    expect(find.text('+ 添加提醒'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('提醒 09:45')), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    final saved = await tester.db(() => repo.getById(task.id));
    expect(saved!.reminderAt, DateTime(2026, 10, 30, 9, 45));
    await finish(tester);
  });

  testWidgets('取消时间选择：不添加提醒', (tester) async {
    phone(tester);
    await seedTask(tester, hour: 10);
    await tester.pumpWidget(testApp(db, clock: clock, settings: const AppSettings(reminderLead: ReminderLead.min15)));
    await tester.pumpAndSettle();

    await openEditorAndAddReminder(tester);
    expect(pickerInitial(tester), const TimeOfDay(hour: 9, minute: 45));
    await tester.tap(find.text(l10n(tester).cancelButtonLabel));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(find.text('+ 添加提醒'), findsOneWidget);
    await finish(tester);
  });

  for (final (lead, expected) in [
    (ReminderLead.onTime, const TimeOfDay(hour: 10, minute: 0)),
    (ReminderLead.min5, const TimeOfDay(hour: 9, minute: 55)),
    (ReminderLead.min15, const TimeOfDay(hour: 9, minute: 45)),
  ]) {
    testWidgets('预读设置 ${lead.name}：任务 10:00 → 初始 ${expected.hour}:${expected.minute.toString().padLeft(2, '0')}', (tester) async {
      phone(tester);
      await seedTask(tester, hour: 10);
      await tester.pumpWidget(testApp(db, clock: clock, settings: AppSettings(reminderLead: lead)));
      await tester.pumpAndSettle();
      await openEditorAndAddReminder(tester);
      expect(pickerInitial(tester), expected);
      await finish(tester);
    });
  }

  testWidgets('提前后已过去但任务时间未到（现在 8:00，任务 8:10，提前 15）：初始为任务时间 8:10', (tester) async {
    phone(tester);
    await seedTask(tester, hour: 8, minute: 10);
    await tester.pumpWidget(testApp(db, clock: clock, settings: const AppSettings(reminderLead: ReminderLead.min15)));
    await tester.pumpAndSettle();
    await openEditorAndAddReminder(tester);
    expect(pickerInitial(tester), const TimeOfDay(hour: 8, minute: 10));
    await finish(tester);
  });

  testWidgets('任务只有日期没有时间：提前量不起作用，初始为下一个整点 9:00', (tester) async {
    phone(tester);
    await seedTask(tester, hour: 0, hasTime: false);
    await tester.pumpWidget(testApp(db, clock: clock, settings: const AppSettings(reminderLead: ReminderLead.min15)));
    await tester.pumpAndSettle();
    await openEditorAndAddReminder(tester);
    expect(pickerInitial(tester), const TimeOfDay(hour: 9, minute: 0));
    await finish(tester);
  });

  testWidgets('任务 0:10（今天零点后），提前 15 分钟落到前一天 23:55：确定后提醒日期是前一天', (tester) async {
    phone(tester);
    // 现在是 10-29 20:00，任务 10-30 0:10
    final night = FixedClock(DateTime(2026, 10, 29, 20));
    final task = await tester.db(() => repo.create(
          TaskDraft(title: '看牙', dueAt: DateTime(2026, 10, 30, 0, 10), dueHasTime: true),
          now: night.value,
        ));
    await tester.pumpWidget(testApp(db, clock: night, settings: const AppSettings(reminderLead: ReminderLead.min15)));
    await tester.pumpAndSettle();
    await tester.tapNav('任务');

    await openEditorAndAddReminder(tester);
    expect(pickerInitial(tester), const TimeOfDay(hour: 23, minute: 55));
    await tester.tap(find.text(l10n(tester).okButtonLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    final saved = await tester.db(() => repo.getById(task.id));
    expect(saved!.reminderAt, DateTime(2026, 10, 29, 23, 55));
    await finish(tester);
  });
}
