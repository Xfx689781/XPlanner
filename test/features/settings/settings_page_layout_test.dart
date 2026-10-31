import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/setting_keys.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 设置页：宽窄布局切换、写库失败时的提示和回滚。
void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));
  setUp(() => db = openTestDb());

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  void setWidth(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
  }

  SettingsTile tile(WidgetTester tester, String title) =>
      tester.widget<SettingsTile>(find.byWidgetPredicate((w) => w is SettingsTile && w.title == title));

  Map<String, bool?> selection(WidgetTester tester) {
    final result = <String, bool?>{};
    for (final t in tester.widgetList<SettingsTile>(find.byType(SettingsTile))) {
      result[t.title] = t.selected;
    }
    return result;
  }

  group('宽窗口两栏', () {
    testWidgets('选中项 selected 为 true、不显示箭头；点别的分组后选中跟着变', (tester) async {
      setWidth(tester, 1100);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(db, clock: clock, overrides: [
        reminderSchedulerProvider.overrideWithValue(FakeScheduler()),
      ]));
      await tester.pumpAndSettle();
      await openSettings(tester);

      expect(selection(tester), {'通用': true, '外观': false, '提醒': false, '关于': false});
      for (final t in tester.widgetList<SettingsTile>(find.byType(SettingsTile))) {
        expect(t.showChevron, isFalse, reason: t.title);
      }

      await tester.tap(find.text('外观'));
      await tester.pumpAndSettle();
      expect(selection(tester), {'通用': false, '外观': true, '提醒': false, '关于': false});
      expect(find.byType(GeoOptionList<ThemePreference>), findsOneWidget);
      await finish(tester);
    });

    testWidgets('宽 → 窄：变为单栏列表（selected 为 null、有箭头、右侧内容消失），不报错；再变宽恢复之前的选中', (tester) async {
      setWidth(tester, 1100);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tester.tap(find.text('提醒'));
      await tester.pumpAndSettle();
      expect(tile(tester, '提醒').selected, isTrue);

      setWidth(tester, 390);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(SettingsTile), findsNWidgets(4));
      // 单栏不暴露"选中"状态（selected 为 null）
      expect(selection(tester).values, everyElement(isNull));
      for (final t in tester.widgetList<SettingsTile>(find.byType(SettingsTile))) {
        expect(t.showChevron, isTrue, reason: t.title);
      }
      expect(find.text('新建提醒时默认'), findsNothing);

      // 窄屏下点分组进入子页面
      await tester.tap(find.text('外观'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsSectionPage), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('返回'));
      await tester.pumpAndSettle();

      setWidth(tester, 1100);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tile(tester, '提醒').selected, isTrue);
      expect(find.text('新建提醒时默认'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('窄屏在子页面里时窗口变宽：不报错，子页面仍可返回', (tester) async {
      setWidth(tester, 390);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tester.tap(find.text('外观'));
      await tester.pumpAndSettle();

      setWidth(tester, 1100);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsSectionPage), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('返回'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsSectionPage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
      await finish(tester);
    });
  });

  group('写库失败', () {
    testWidgets('选深色写库失败：提示"设置保存失败，请重试"，选中项、主页摘要、App 主题都恢复原值', (tester) async {
      setWidth(tester, 1100);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final repo = _FailingRepo(db);
      await tester.pumpWidget(testApp(db, clock: clock, overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
      ]));
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tester.tap(find.text('外观'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('深色'));
      await tester.pumpAndSettle();

      expect(repo.attempts, 1);
      expect(find.text('设置保存失败，请重试'), findsOneWidget);
      expect(
        tester.widget<GeoOptionList<ThemePreference>>(find.byType(GeoOptionList<ThemePreference>)).value,
        ThemePreference.system,
      );
      expect(tile(tester, '外观').value, '跟随系统 · 朱红');
      expect(Theme.of(tester.element(find.byType(SettingsTile).first)).brightness, Brightness.light);
      expect(await tester.db(() => SettingsRepository(db).raw('theme')), isNull);
      await finish(tester);
    });

    testWidgets('窄屏子页面里改提前时间写库失败：提示并恢复为准时', (tester) async {
      setWidth(tester, 390);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(db, clock: clock, overrides: [
        settingsRepositoryProvider.overrideWithValue(_FailingRepo(db)),
      ]));
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tester.tap(find.text('提醒'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('提前 15 分钟'));
      await tester.pumpAndSettle();
      expect(find.text('设置保存失败，请重试'), findsOneWidget);
      expect(
        tester.widget<GeoCheckList<int>>(find.byType(GeoCheckList<int>)).selected,
        {0},
      );

      await tester.tap(find.bySemanticsLabel('返回'));
      await tester.pumpAndSettle();
      expect(tile(tester, '提醒').value, '准时');
      await finish(tester);
    });
  });
}

class _FailingRepo extends SettingsRepository {
  _FailingRepo(super.db);

  int attempts = 0;

  @override
  Future<void> write<T>(SettingKey<T> key, T value) async {
    attempts++;
    throw StateError('disk full');
  }
}
