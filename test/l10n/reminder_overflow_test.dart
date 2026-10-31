import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/notifications/notification_tap_handler.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/plan/alarm_page.dart';
import 'package:facet/features/plan/task_editor_sheet.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../helpers/fake_scheduler.dart';
import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// 三种语言 × 320 宽 × 字号 1.3：编辑页（5 个提醒都选中、带通知 / 闹钟切换）、设置「提醒」分组、闹钟页都不溢出。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  final clock = FixedClock(DateTime(2026, 11, 2, 8));
  const longTitle = 'Pay the rent and the electricity bill before the end of the month 交房租和电费';

  void small(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final lang in appLanguages) {
    final l10n = lookupAppLocalizations(lang.locale);
    final settings = AppSettings(languageTag: lang.tag);

    testWidgets('${lang.tag}：编辑页 5 个提醒（含闹钟切换）不溢出', (tester) async {
      small(tester);
      final db = openTestDb();
      await tester.db(() => TaskRepository(db).create(
        TaskDraft(
          title: longTitle,
          dueAt: DateTime(2026, 11, 3, 14),
          dueHasTime: true,
          reminderAt: DateTime(2026, 11, 3, 14),
          reminders: const [
            ReminderSpec(10080, ReminderKind.alarm),
            ReminderSpec(2880),
            ReminderSpec(1440, ReminderKind.alarm),
            ReminderSpec(90),
            ReminderSpec(0, ReminderKind.alarm),
          ],
        ),
        now: clock.value,
      ));
      await tester.pumpWidget(testApp(
        db,
        clock: clock,
        settings: settings,
        overrides: [reminderSchedulerProvider.overrideWithValue(FakeScheduler())],
      ));
      await tester.pumpAndSettle();
      await tester.tapNav(l10n.navTasks);
      await tester.tap(find.text(longTitle).first);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.byType(TaskEditorSheet), findsOneWidget);
      expect(find.text(l10n.reminderMaxReached), findsOneWidget);
      // 5 个选中项各有一个切换按钮
      expect(find.bySemanticsLabel(RegExp(RegExp.escape(l10n.reminderKindAlarm))), findsWidgets);
      expect(
        find.descendant(of: find.byType(GeoCheckList<int>), matching: find.byType(GeoButton)),
        findsNWidgets(5),
      );
      for (final f in [find.text(l10n.reminderMaxReached), find.text(l10n.taskEditorSave)]) {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      // 切换按钮完整落在屏幕宽度内
      for (final e in find.descendant(of: find.byType(GeoCheckList<int>), matching: find.byType(GeoButton)).evaluate()) {
        final r = tester.getRect(find.byWidget(e.widget));
        expect(r.right, lessThanOrEqualTo(320.5));
      }
      expect(tester.takeException(), isNull);
      await tester.disposeApp();
      await tester.db(db.close);
    });

    testWidgets('${lang.tag}：设置「提醒」分组（满 5 个默认提前量 + 闹钟默认方式）不溢出', (tester) async {
      small(tester);
      final db = openTestDb();
      await tester.pumpWidget(testApp(
        db,
        clock: clock,
        settings: AppSettings(
          languageTag: lang.tag,
          reminderOffsets: const [10080, 2880, 1440, 120, 0],
          reminderKind: ReminderKind.alarm,
        ),
        overrides: [reminderSchedulerProvider.overrideWithValue(FakeScheduler())],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.todaySettings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l10n.settingsSectionReminders).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.reminderMaxReached), findsOneWidget);
      for (final f in [
        find.text(l10n.settingsReminderKindDefault),
        find.text(l10n.settingsTestButton),
        find.text(l10n.settingsSamsungStep4),
      ]) {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.disposeApp();
      await tester.db(db.close);
    });

    testWidgets('${lang.tag}：闹钟页（长标题）不溢出，两个按钮都在屏幕内', (tester) async {
      small(tester);
      final db = openTestDb();
      final t = await tester.db(() => TaskRepository(db).create(
        TaskDraft(
          title: longTitle,
          priority: Priority.high,
          reminderAt: DateTime(2026, 11, 2, 9),
          reminders: const [ReminderSpec(0, ReminderKind.alarm)],
        ),
        now: clock.value,
      ));
      await tester.pumpWidget(testApp(
        db,
        clock: clock,
        settings: settings,
        overrides: [reminderSchedulerProvider.overrideWithValue(FakeScheduler())],
      ));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(DayCircle)));
      container
          .read(pendingAlarmProvider.notifier)
          .open(AlarmRequest(taskId: t.id, notificationId: notificationIdForReminder(t.id, 0, 0), fromLockScreen: true));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.byType(AlarmPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final label in [l10n.notificationActionDone, l10n.notificationActionSnooze]) {
        final r = tester.getRect(find.widgetWithText(GeoButton, label));
        expect(r.left, greaterThanOrEqualTo(0), reason: label);
        expect(r.right, lessThanOrEqualTo(320), reason: label);
        expect(r.bottom, lessThanOrEqualTo(700), reason: label);
      }
      await tester.disposeApp();
      await tester.db(db.close);
    });
  }
}
