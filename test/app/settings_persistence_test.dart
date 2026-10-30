import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/setting_keys.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// 设置中心端到端：从界面改设置 → 重启（同一个数据库预读）后仍在；主题切换在整个 App 生效；
/// 一周开始日影响任务编辑弹层里的日期选择器；数据库里有非法值时正常启动。
void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUp(() => db = openTestDb());

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// 等界面触发的写库真正完成
  Future<void> settleWrite(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  }

  /// 今天页（或设置页）当前使用的主题明暗
  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(PageFrame).first)).brightness;

  int firstDayOfWeek(WidgetTester tester) =>
      MaterialLocalizations.of(tester.element(find.byType(PageFrame).first)).firstDayOfWeekIndex;

  group('重启后还在', () {
    testWidgets('界面里改主题 / 一周开始日 / 默认提前时间 → 卸载 → 预读后重新启动，界面和 Theme 都是保存的值',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      // 第一次启动：默认设置
      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.light);
      await openSettings(tester);

      await tapText(tester, '外观');
      await tester.tap(find.text('深色'));
      await settleWrite(tester);
      await back(tester);

      await tapText(tester, '通用');
      await tester.tap(find.text('周一'));
      await settleWrite(tester);
      await back(tester);

      await tapText(tester, '提醒');
      await tester.tap(find.text('提前 15 分钟'));
      await settleWrite(tester);
      await back(tester);

      // 关闭 App
      await tester.disposeApp();

      // 模拟 main：runApp 之前从同一个数据库预读
      final loaded = await tester.db(() => SettingsRepository(db).load());
      expect(
        loaded,
        const AppSettings(
          theme: ThemePreference.dark,
          weekStart: WeekStart.monday,
          reminderLead: ReminderLead.min15,
        ),
      );

      await tester.pumpWidget(testApp(db, clock: clock, settings: loaded));
      // 第一帧就是深色（不闪烁），系统仍是浅色
      expect(brightness(tester), Brightness.dark);
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);
      expect(firstDayOfWeek(tester), 1);

      await openSettings(tester);
      expect(find.text('深色 · 朱红'), findsOneWidget);
      expect(find.textContaining('周一开始'), findsOneWidget);
      expect(find.text('提前 15 分钟'), findsOneWidget);

      await tapText(tester, '外观');
      // 选中项是"深色"
      final list = tester.widget<GeoOptionList<ThemePreference>>(find.byType(GeoOptionList<ThemePreference>));
      expect(list.value, ThemePreference.dark);
      await finish(tester);
    });

    testWidgets('改回默认值后重启：数据库里不留行，读出默认设置', (tester) async {
      phone(tester);
      await tester.db(() async {
        final repo = SettingsRepository(db);
        await repo.write(SettingKeys.theme, ThemePreference.dark);
      });
      final first = await tester.db(() => SettingsRepository(db).load());
      await tester.pumpWidget(testApp(db, clock: clock, settings: first));
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tapText(tester, '外观');
      await tester.tap(find.text('跟随系统'));
      await settleWrite(tester);
      await tester.disposeApp();

      expect(await tester.db(() => SettingsRepository(db).raw('theme')), isNull);
      expect(await tester.db(() => SettingsRepository(db).load()), AppSettings.defaults);
      await tester.db(db.close);
    });
  });

  group('主题切换端到端', () {
    testWidgets('今天页 → 设置 → 外观 → 深色 → 返回今天页，整个 App 是深色；跟随系统随系统明暗变化',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.light);

      await openSettings(tester);
      await tapText(tester, '外观');
      await tester.tap(find.text('深色'));
      await settleWrite(tester);
      // 设置子页面自己也立即变深色
      expect(brightness(tester), Brightness.dark);
      await back(tester);
      await back(tester);

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text('今天'), findsWidgets);
      expect(brightness(tester), Brightness.dark);

      // 系统改为浅色也不影响"深色"
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);

      // 改回跟随系统：系统是浅色 → 浅色
      await openSettings(tester);
      await tapText(tester, '外观');
      await tester.tap(find.text('跟随系统'));
      await settleWrite(tester);
      await back(tester);
      await back(tester);
      expect(brightness(tester), Brightness.light);

      // 系统切到深色 → App 跟着变深色；再切回浅色
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.light);

      // 选"浅色"时系统深色也保持浅色
      await openSettings(tester);
      await tapText(tester, '外观');
      await tester.tap(find.text('浅色'));
      await settleWrite(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.light);
      await finish(tester);
    });

    testWidgets('深色主题下今天页用的是深色配色（不只是 brightness 变了）', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp(db, clock: clock, settings: const AppSettings(theme: ThemePreference.light)));
      await tester.pumpAndSettle();
      final lightBg = Theme.of(tester.element(find.byType(PageFrame).first)).scaffoldBackgroundColor;

      await openSettings(tester);
      await tapText(tester, '外观');
      await tester.tap(find.text('深色'));
      await settleWrite(tester);
      await back(tester);
      await back(tester);

      final darkBg = Theme.of(tester.element(find.byType(PageFrame).first)).scaffoldBackgroundColor;
      expect(darkBg, isNot(lightBg));
      expect(darkBg.computeLuminance(), lessThan(lightBg.computeLuminance()));
      await finish(tester);
    });
  });

  group('一周开始日', () {
    Future<List<double>> weekdayHeaderX(WidgetTester tester) async {
      final dialog = find.byType(DatePickerDialog);
      expect(dialog, findsOneWidget);
      final headers = MaterialLocalizations.of(tester.element(dialog)).narrowWeekdays;
      return [
        for (final h in headers)
          tester.getTopLeft(find.descendant(of: dialog, matching: find.text(h)).first).dx,
      ];
    }

    Future<void> openNewTaskDatePicker(WidgetTester tester) async {
      // 今天页"任务"小标题右侧的 +（读屏标签和小标题合并了，按组件找）
      await tester.tap(find
          .byWidgetPredicate((w) => w is GeoIconButton && w.semanticLabel == '新建任务')
          .hitTestable()
          .first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('选日期'));
      await tester.pumpAndSettle();
    }

    testWidgets('设置页选周一 → 任务编辑弹层的日期选择器第一列是周一；改周日后第一列是周日', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();

      await openSettings(tester);
      await tapText(tester, '通用');
      await tester.tap(find.text('周一'));
      await settleWrite(tester);
      await back(tester);
      await back(tester);

      await openNewTaskDatePicker(tester);
      var xs = await weekdayHeaderX(tester);
      // narrowWeekdays 从周日开始：下标 1 = 周一应在最左列，周日在最右列
      expect(xs[1], lessThan(xs[0]));
      for (var i = 2; i < 7; i++) {
        expect(xs[1], lessThan(xs[i]), reason: '周一应是第一列（对比下标 $i）');
      }
      expect(xs[0], greaterThan(xs[6]));

      // 关掉选择器和弹层，改为周日
      await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).cancelButtonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('关闭'));
      await tester.pumpAndSettle();

      await openSettings(tester);
      await tapText(tester, '通用');
      await tester.tap(find.text('周日'));
      await settleWrite(tester);
      await back(tester);
      await back(tester);

      await openNewTaskDatePicker(tester);
      xs = await weekdayHeaderX(tester);
      for (var i = 1; i < 7; i++) {
        expect(xs[0], lessThan(xs[i]), reason: '周日应是第一列（对比下标 $i）');
      }
      await finish(tester);
    });
  });

  group('数据库里有非法值', () {
    testWidgets('手动写入非法值：预读得到默认设置，App 正常启动，设置页显示默认值', (tester) async {
      phone(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.db(() async {
        for (final (k, v) in [
          ('theme', 'purple'),
          ('weekStart', 'MONDAY'),
          ('reminderLeadMinutes', '-15'),
          ('unknownFutureKey', 'whatever'),
        ]) {
          await db.into(db.settingEntries).insert(SettingEntriesCompanion.insert(key: k, value: v));
        }
      });

      final loaded = await tester.db(() => SettingsRepository(db).load());
      expect(loaded, AppSettings.defaults);

      await tester.pumpWidget(testApp(db, clock: clock, settings: loaded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(brightness(tester), Brightness.light);

      await openSettings(tester);
      expect(find.text('跟随系统 · 朱红'), findsOneWidget); // 外观
      expect(find.textContaining(RegExp('跟随系统 · .*开始')), findsOneWidget); // 通用
      expect(find.text('准时'), findsOneWidget); // 提醒

      // 之后从界面改设置会覆盖掉非法值
      await tapText(tester, '外观');
      await tester.tap(find.text('深色'));
      await settleWrite(tester);
      expect(await tester.db(() => SettingsRepository(db).raw('theme')), 'dark');
      await finish(tester);
    });

    testWidgets('提前量是非数字 / 小数 / 空串：都按准时处理', (tester) async {
      for (final raw in ['abc', '15.0', '']) {
        await tester.db(() async {
          await db.into(db.settingEntries).insertOnConflictUpdate(
            SettingEntriesCompanion.insert(key: 'reminderLeadMinutes', value: raw),
          );
        });
        final loaded = await tester.db(() => SettingsRepository(db).load());
        expect(loaded.reminderLead, ReminderLead.onTime, reason: '"$raw"');
      }
      await tester.db(db.close);
    });
  });
}
