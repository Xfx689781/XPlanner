import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../helpers/fake_scheduler.dart';
import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// 与 overflow_test 互补：overflow_test 覆盖"有任务"状态的各尺寸 / 字号；
/// 这里覆盖每种语言 × 浅色 / 深色 × 今天页"没有任务""全部完成"、空任务页、空日志页、编辑弹层、设置各分组。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  Future<void> openAndCloseEditor(
    WidgetTester tester,
    AppLocalizations l10n,
    Finder opener,
  ) async {
    await tester.tap(opener);
    await tester.pumpAndSettle();
    expect(find.text(l10n.taskEditorNewTitle), findsOneWidget);
    expect(find.text(l10n.taskEditorSave), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel(l10n.commonClose));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(l10n.commonClose));
    await tester.pumpAndSettle();
  }

  Future<void> visitSettings(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.bySemanticsLabel(l10n.todaySettings));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsTitle), findsOneWidget);
    // 默认测试窗口 800 宽 = 两栏布局，点左侧分组切换右侧内容
    for (final (title, marker) in [
      (l10n.settingsSectionGeneral, l10n.settingsLanguage),
      (l10n.settingsSectionAppearance, l10n.settingsTheme),
      (l10n.settingsSectionReminders, l10n.settingsTestButton),
      (l10n.settingsSectionAbout, l10n.settingsPrivacy),
    ]) {
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
      expect(find.text(marker), findsWidgets, reason: title);
    }
    await tester.tap(find.bySemanticsLabel(l10n.commonBack).last);
    await tester.pumpAndSettle();
  }

  for (final lang in appLanguages) {
    for (final dark in [false, true]) {
      final themeName = dark ? '深色' : '浅色';
      final settings = AppSettings(
        languageTag: lang.tag,
        theme: dark ? ThemePreference.dark : ThemePreference.light,
      );

      testWidgets('${lang.tag} $themeName：没有任务 → 今天页空状态、空任务页、空日志页、编辑弹层、设置各分组', (
        tester,
      ) async {
        final db = openTestDb();
        final scheduler = FakeScheduler();
        await tester.pumpWidget(
          testApp(
            db,
            clock: clock,
            settings: settings,
            overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
          ),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(lang.locale);

        expect(
          Theme.of(tester.element(find.byType(DayCircle))).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        // 今天页：圆心"今天没有任务" + 添加入口；读屏能读到"今天没有任务"
        expect(find.text(l10n.todayTitle), findsWidgets);
        expect(find.text(l10n.todayNoTasks), findsOneWidget);
        expect(find.text(l10n.todayAddTask), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(l10n.todayNoTasks)}')),
          findsWidgets,
        );

        // 圆心的添加入口打开编辑弹层
        await openAndCloseEditor(tester, l10n, find.text(l10n.todayAddTask));

        await tester.tapNav(l10n.navTasks);
        expect(find.text(l10n.tasksEmpty), findsOneWidget);
        await tester.tapNav(l10n.navLog);
        expect(find.text(l10n.logEmpty), findsOneWidget);
        expect(find.text(l10n.logInputHint), findsOneWidget);
        await tester.tapNav(l10n.navToday);

        await visitSettings(tester, l10n);

        expect(tester.takeException(), isNull);
        await tester.disposeApp();
        await tester.db(db.close);
      });

      testWidgets('${lang.tag} $themeName：今天的任务全部完成 → 圆心对勾、完成数、读屏', (
        tester,
      ) async {
        final db = openTestDb();
        await tester.db(() async {
          final repo = TaskRepository(db);
          for (final title in ['Alpha', 'Beta']) {
            final t = await repo.create(
              TaskDraft(title: title, dueAt: DateTime(2026, 10, 30)),
              now: clock.value,
            );
            await repo.setCompleted(t.id, clock.value, now: clock.value);
          }
        });
        await tester.pumpWidget(
          testApp(
            db,
            clock: clock,
            settings: settings,
            overrides: [
              reminderSchedulerProvider.overrideWithValue(FakeScheduler()),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(lang.locale);

        final circle = tester.widget<DayCircle>(find.byType(DayCircle));
        expect(circle.done, 2);
        expect(circle.total, 2);
        expect(find.text(l10n.todayNoTasks), findsNothing);
        // 全部完成时圆心换成对勾（不显示百分比）
        expect(
          find.byWidgetPredicate(
            (w) => w is GeoIcon && w.glyph == GeoGlyph.check,
          ),
          findsWidgets,
        );
        expect(find.text(l10n.todayProgressDone(2, 2)), findsWidgets);
        expect(
          find.bySemanticsLabel(l10n.todayProgressSemantics(2, 2)),
          findsOneWidget,
        );
        expect(find.text('Alpha'), findsOneWidget);

        // 任务页：今天完成的任务仍留在"今天"分组
        await tester.tapNav(l10n.navTasks);
        expect(find.text(l10n.taskGroupToday), findsWidgets);
        expect(find.text('Beta'), findsOneWidget);
        expect(find.text(l10n.tasksEmpty), findsNothing);
        await tester.tapNav(l10n.navToday);
        await openAndCloseEditor(
          tester,
          l10n,
          find.bySemanticsLabel(l10n.todayNewTask),
        );

        await visitSettings(tester, l10n);
        expect(tester.takeException(), isNull);
        await tester.disposeApp();
        await tester.db(db.close);
      });
    }

    testWidgets('${lang.tag}：部分完成时大圆副标题和读屏用该语言', (tester) async {
      final db = openTestDb();
      await tester.db(() async {
        final repo = TaskRepository(db);
        final a = await repo.create(
          TaskDraft(title: 'A', dueAt: DateTime(2026, 10, 30)),
          now: clock.value,
        );
        await repo.create(
          TaskDraft(title: 'B', dueAt: DateTime(2026, 10, 30)),
          now: clock.value,
        );
        await repo.create(
          TaskDraft(title: 'C', dueAt: DateTime(2026, 10, 30)),
          now: clock.value,
        );
        await repo.setCompleted(a.id, clock.value, now: clock.value);
      });
      await tester.pumpWidget(
        testApp(
          db,
          clock: clock,
          settings: AppSettings(languageTag: lang.tag),
          overrides: [
            reminderSchedulerProvider.overrideWithValue(FakeScheduler()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(lang.locale);
      expect(find.text(l10n.todayProgressDone(1, 3)), findsWidgets);
      expect(
        find.bySemanticsLabel(l10n.todayProgressSemantics(1, 3)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.disposeApp();
      await tester.db(db.close);
    });
  }
}
