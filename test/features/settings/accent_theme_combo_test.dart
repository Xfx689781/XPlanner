import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 主题色 × 主题（跟随系统 / 浅 / 深）任意顺序组合切换，最终颜色正确；
/// 系统明暗变化时 App 和设置页色块都切到对应明暗版本。
void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));
  setUp(() => db = openTestDb());

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  Future<void> settleWrite(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(PageFrame).first));

  FacetColors appColors(WidgetTester tester) => tester.element(find.byType(PageFrame).first).colors;

  Brightness effective(ThemePreference t, Brightness platform) => switch (t) {
    ThemePreference.system => platform,
    ThemePreference.light => Brightness.light,
    ThemePreference.dark => Brightness.dark,
  };

  /// 设置页色块实际画出来的颜色（按色块顺序）
  List<Color> renderedSwatches(WidgetTester tester) => [
    for (final d in tester.widgetList<DecoratedBox>(
      find.descendant(of: find.byType(GeoSwatchPicker<AccentColor>), matching: find.byType(DecoratedBox)),
    ))
      if (d.decoration case BoxDecoration(color: final c?, shape: BoxShape.circle)) c,
  ];

  testWidgets('18 种主题色 × 主题组合，两种切换顺序、两种系统明暗下最终颜色都正确，并都写进了数据库', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    // 起点故意不是默认值
    await tester.pumpWidget(testApp(
      db,
      clock: clock,
      settings: const AppSettings(theme: ThemePreference.dark, accent: AccentColor.plum),
    ));
    await tester.pumpAndSettle();
    final ctrl = container(tester).read(settingsProvider.notifier);

    for (final accent in AccentColor.values) {
      for (final theme in ThemePreference.values) {
        for (final accentFirst in [true, false]) {
          // 先切到一个"别的"状态，确保两步都真的发生了变化
          final otherAccent = AccentColor.values[(accent.index + 1) % AccentColor.values.length];
          final otherTheme = ThemePreference.values[(theme.index + 1) % ThemePreference.values.length];
          await tester.runAsync(() async {
            await ctrl.setAccent(otherAccent);
            await ctrl.setTheme(otherTheme);
          });
          await tester.pumpAndSettle();

          await tester.runAsync(() async {
            if (accentFirst) {
              await ctrl.setAccent(accent);
              await ctrl.setTheme(theme);
            } else {
              await ctrl.setTheme(theme);
              await ctrl.setAccent(accent);
            }
          });
          await tester.pumpAndSettle();

          final palette = AccentPalette.values.byName(accent.name);
          for (final platform in Brightness.values) {
            tester.platformDispatcher.platformBrightnessTestValue = platform;
            await tester.pumpAndSettle();
            final b = effective(theme, platform);
            final reason = '${accent.name} / ${theme.name} / 系统 ${platform.name} / accentFirst=$accentFirst';
            expect(Theme.of(tester.element(find.byType(PageFrame).first)).brightness, b, reason: reason);
            expect(appColors(tester).accent, palette.forBrightness(b), reason: reason);
            expect(Theme.of(tester.element(find.byType(PageFrame).first)).colorScheme.primary, palette.forBrightness(b),
                reason: reason);
          }
          tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
          await tester.pumpAndSettle();

          final saved = await tester.db(() => SettingsRepository(db).load());
          expect((saved.accent, saved.theme), (accent, theme));
        }
      }
    }
    await finish(tester);
  });

  testWidgets('界面里交替点主题和色块：跟随系统时系统明暗变化，色块和 App 一起切到对应版本', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('外观').first);
    await tester.pumpAndSettle();

    void expectAll(Brightness b, AccentColor selected, String reason) {
      final picker = tester.widget<GeoSwatchPicker<AccentColor>>(find.byType(GeoSwatchPicker<AccentColor>));
      expect(picker.value, selected, reason: reason);
      final expected = [for (final p in AccentPalette.values) p.forBrightness(b)];
      expect([for (final s in picker.swatches) s.color], expected, reason: reason);
      expect(renderedSwatches(tester), expected, reason: reason);
      expect(tester.element(find.byType(GeoSwatchPicker<AccentColor>)).colors.accent,
          AccentPalette.values.byName(selected.name).forBrightness(b), reason: reason);
    }

    expectAll(Brightness.light, AccentColor.vermilion, '初始');

    // 色块 → 深色 → 色块 → 跟随系统 → 系统变暗 → 色块 → 系统变亮 → 浅色（系统暗）
    await tester.tap(find.bySemanticsLabel('湖蓝'));
    await settleWrite(tester);
    expectAll(Brightness.light, AccentColor.teal, '选湖蓝');

    await tester.tap(find.text('深色'));
    await settleWrite(tester);
    expectAll(Brightness.dark, AccentColor.teal, '湖蓝 + 深色');

    await tester.tap(find.bySemanticsLabel('琥珀'));
    await settleWrite(tester);
    expectAll(Brightness.dark, AccentColor.amber, '深色下选琥珀');

    await tester.tap(find.text('跟随系统'));
    await settleWrite(tester);
    expectAll(Brightness.light, AccentColor.amber, '跟随系统（系统浅色）');

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expectAll(Brightness.dark, AccentColor.amber, '系统变暗');

    await tester.tap(find.bySemanticsLabel('靛蓝'));
    await settleWrite(tester);
    expectAll(Brightness.dark, AccentColor.indigo, '系统暗时选靛蓝');

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expectAll(Brightness.light, AccentColor.indigo, '系统变亮');

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    await tester.tap(find.text('浅色'));
    await settleWrite(tester);
    expectAll(Brightness.light, AccentColor.indigo, '系统暗、手动选浅色');

    // 手动浅色时系统明暗变化不影响
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expectAll(Brightness.light, AccentColor.indigo, '手动浅色、系统变亮');

    final saved = await tester.db(() => SettingsRepository(db).load());
    expect((saved.accent, saved.theme), (AccentColor.indigo, ThemePreference.light));

    // 回到今天页，整个 App 都是靛蓝浅色版
    while (find.byType(DayCircle).evaluate().isEmpty) {
      await tester.tap(find.bySemanticsLabel('返回').first);
      await tester.pumpAndSettle();
    }
    expect(tester.element(find.byType(DayCircle)).colors.accent, AccentPalette.indigo.light);
    await finish(tester);
  });
}
