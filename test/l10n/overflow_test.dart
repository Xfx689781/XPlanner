import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/log_repository.dart';
import 'package:facet/core/data/settings/app_settings.dart';
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

/// 每种语言 × 手机 / 宽窗口 × 正常 / 放大字号，依次打开所有页面，不能有溢出（RenderFlex overflow 会让测试失败）。
/// 新增语言后自动覆盖。测试字体每个字都按字号等宽绘制，比真实字体更宽，结果偏保守。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  final clock = FixedClock(DateTime(2026, 12, 30, 8));

  for (final lang in appLanguages) {
    for (final width in [320.0, 390.0, 1024.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('${lang.tag} 宽 ${width.toInt()} 字号 ×$scale：所有页面无溢出', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 760);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final db = openTestDb();
          await tester.db(() async {
            final repo = TaskRepository(db);
            // 最难的数据：长标题、逾期、跨年日期、周三的每周提醒（各语言里较长的星期名）
            await repo.create(
              TaskDraft(
                title: 'A rather long task title that keeps going and going to test wrapping behaviour',
                dueAt: DateTime(2026, 12, 20, 18),
                dueHasTime: true,
                priority: Priority.high,
              ),
              now: clock.value,
            );
            await repo.create(
              TaskDraft(
                title: 'Weekly sync',
                reminderAt: DateTime(2026, 12, 2, 9, 30),
                reminderRepeat: RepeatRule.weekly,
              ),
              now: clock.value,
            );
            await repo.create(
              TaskDraft(title: 'Next year', dueAt: DateTime(2027, 1, 2)),
              now: clock.value,
            );
            await LogRepository(db).add(
              'A fairly long quick log entry to see how lines wrap here',
              now: clock.value,
            );
          });

          final scheduler = FakeScheduler(exactAllowed: false)
            ..notificationsOn = false;
          await tester.pumpWidget(
            testApp(
              db,
              clock: clock,
              settings: AppSettings(languageTag: lang.tag),
              overrides: [
                reminderSchedulerProvider.overrideWithValue(scheduler),
              ],
            ),
          );
          await tester.pumpAndSettle();
          final l10n = lookupAppLocalizations(lang.locale);

          Future<void> tapNav(String label) async {
            await tester.tap(
              find.descendant(
                of: find.byType(GeoNavBar),
                matching: find.text(label),
              ),
            );
            await tester.pumpAndSettle();
          }

          // 今天页（已渲染）→ 任务页 → 日志页
          await tapNav(l10n.navTasks);
          await tapNav(l10n.navLog);
          await tapNav(l10n.navTasks);

          // 编辑弹层：打开每周提醒的任务（显示长的"每周三"按钮和权限提示）
          await tester.tap(find.text('Weekly sync'));
          await tester.pumpAndSettle();
          // 选一个具体日期，让日期分段显示完整日期
          await tester.tap(find.text(l10n.taskEditorDatePick));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(
              MaterialLocalizations.of(tester.element(find.byType(Dialog)))
                  .okButtonLabel,
            ),
          );
          await tester.pumpAndSettle();
          // 删除确认框
          await tester.ensureVisible(find.text(l10n.commonDelete).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.commonDelete).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.commonCancel));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.bySemanticsLabel(l10n.commonClose));
          await tester.pumpAndSettle();
          await tester.tap(find.bySemanticsLabel(l10n.commonClose));
          await tester.pumpAndSettle();

          // 设置中心各分组（权限都未开启，所有操作按钮都显示出来）
          await tapNav(l10n.navToday);
          await tester.tap(find.bySemanticsLabel(l10n.todaySettings));
          await tester.pumpAndSettle();
          final wide = width >= Sizes.wideBreakpoint;
          for (final title in [
            l10n.settingsSectionGeneral,
            l10n.settingsSectionAppearance,
            l10n.settingsSectionReminders,
            l10n.settingsSectionAbout,
          ]) {
            await tester.tap(find.text(title).first);
            await tester.pumpAndSettle();
            if (!wide) {
              await tester.tap(find.bySemanticsLabel(l10n.commonBack).last);
              await tester.pumpAndSettle();
            }
          }

          expect(tester.takeException(), isNull);
          await tester.disposeApp();
          await tester.db(db.close);
        });
      }
    }
  }
}
