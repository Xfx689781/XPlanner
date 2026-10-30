import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/setting_keys.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/settings/settings_labels.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// 主题色：数据库里有非法值、写库失败、读屏操作。
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

  Future<void> openAppearance(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('外观').first);
    await tester.pumpAndSettle();
  }

  SettingsTile tile(WidgetTester tester, String title) =>
      tester.widget<SettingsTile>(find.byWidgetPredicate((w) => w is SettingsTile && w.title == title));

  AccentColor pickerValue(WidgetTester tester) =>
      tester.widget<GeoSwatchPicker<AccentColor>>(find.byType(GeoSwatchPicker<AccentColor>)).value;

  Color appAccent(WidgetTester tester) => tester.element(find.byType(PageFrame).first).colors.accent;

  group('数据库里 accentColor 是非法值', () {
    for (final raw in ['neon', '', 'Pine', ' pine', 'vermilion ', '0', 'AccentColor.teal']) {
      testWidgets('accentColor = "$raw"：读出朱红，App 正常启动，设置页显示朱红', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.db(() => db.into(db.settingEntries).insert(
          SettingEntriesCompanion.insert(key: 'accentColor', value: raw),
        ));
        expect(SettingKeys.accent.name, 'accentColor');

        final loaded = await tester.db(() => SettingsRepository(db).load());
        expect(loaded.accent, AccentColor.vermilion);
        expect(loaded, AppSettings.defaults);

        await tester.pumpWidget(testApp(db, clock: clock, settings: loaded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(appAccent(tester), AccentPalette.vermilion.light);

        await openAppearance(tester);
        expect(pickerValue(tester), AccentColor.vermilion);
        expect(tile(tester, '外观').value, '跟随系统 · 朱红');

        // 之后从界面选颜色会覆盖掉非法值
        await tester.tap(find.bySemanticsLabel('琥珀'));
        await settleWrite(tester);
        expect(await tester.db(() => SettingsRepository(db).raw('accentColor')), 'amber');
        await finish(tester);
      });
    }

    testWidgets('非法主题色和其他合法设置并存：只有主题色回退，其他设置保留', (tester) async {
      await tester.db(() async {
        for (final (k, v) in [('accentColor', 'neon'), ('theme', 'dark')]) {
          await db.into(db.settingEntries).insert(SettingEntriesCompanion.insert(key: k, value: v));
        }
      });
      final loaded = await tester.db(() => SettingsRepository(db).load());
      expect((loaded.accent, loaded.theme), (AccentColor.vermilion, ThemePreference.dark));
      await tester.pumpWidget(testApp(db, clock: clock, settings: loaded));
      await tester.pumpAndSettle();
      expect(appAccent(tester), AccentPalette.vermilion.dark);
      await finish(tester);
    });
  });

  group('写库失败', () {
    for (final (start, startLabel) in [(AccentColor.vermilion, '朱红'), (AccentColor.indigo, '靛蓝')]) {
      testWidgets('从$startLabel选松绿写库失败：选中项、App 颜色、主页摘要都恢复为$startLabel，并提示', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final repo = _FailingRepo(db);
        await tester.pumpWidget(testApp(
          db,
          clock: clock,
          settings: AppSettings(accent: start),
          overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        ));
        await tester.pumpAndSettle();
        final startColor = AccentPalette.values.byName(start.name).light;
        expect(appAccent(tester), startColor);
        await openAppearance(tester);

        await tester.tap(find.bySemanticsLabel('松绿'));
        await settleWrite(tester);

        expect(repo.attempts, 1);
        expect(find.text('设置保存失败，请重试'), findsOneWidget);
        expect(pickerValue(tester), start);
        expect(tester.element(find.byType(GeoSwatchPicker<AccentColor>)).colors.accent, startColor);
        expect(appAccent(tester), startColor);
        expect(tile(tester, '外观').value, '跟随系统 · $startLabel');
        expect(await tester.db(() => SettingsRepository(db).raw('accentColor')), isNull);
        await finish(tester);
      });
    }

    testWidgets('写库失败后再点一次（仓库恢复正常）：可以成功保存', (tester) async {
      final repo = _FailingRepo(db);
      await tester.pumpWidget(testApp(db, clock: clock, overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
      ]));
      await tester.pumpAndSettle();
      await openAppearance(tester);
      await tester.tap(find.bySemanticsLabel('松绿'));
      await settleWrite(tester);
      expect(pickerValue(tester), AccentColor.vermilion);

      repo.fail = false;
      // 等上一条提示消失，避免干扰
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('松绿'));
      await settleWrite(tester);
      expect(pickerValue(tester), AccentColor.pine);
      expect(appAccent(tester), AccentPalette.pine.light);
      expect(await tester.db(() => SettingsRepository(db).raw('accentColor')), 'pine');
      await finish(tester);
    });
  });

  group('读屏', () {
    testWidgets('每个色块 label = 颜色名，只有选中项 checked；读屏 tap 切换后选中状态跟着变并保存', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp(db, clock: clock));
      await tester.pumpAndSettle();
      await openAppearance(tester);

      // 颜色名本身的文案在 test/l10n/accent_color_l10n_test.dart 里逐个核对；这里只要求读屏 label = 当前语言的颜色名
      final l10n = lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
      final names = {for (final a in AccentColor.values) a: accentLabel(l10n, a)};
      expect(names.values.toSet(), hasLength(AccentColor.values.length), reason: '颜色名不能重复');
      final picker = tester.widget<GeoSwatchPicker<AccentColor>>(find.byType(GeoSwatchPicker<AccentColor>));
      expect({for (final s in picker.swatches) s.value: s.label}, names);

      void expectChecked(AccentColor selected) {
        for (final e in names.entries) {
          final node = find.semantics.byLabel(e.value).evaluate().single;
          expect(node.label, e.value);
          expect(
            node,
            isSemantics(
              label: e.value,
              hasCheckedState: true,
              isChecked: e.key == selected,
              isInMutuallyExclusiveGroup: true,
              hasTapAction: true,
            ),
            reason: e.value,
          );
        }
      }

      expectChecked(AccentColor.vermilion);

      tester.semantics.tap(find.semantics.byLabel('靛蓝'));
      await settleWrite(tester);
      expectChecked(AccentColor.indigo);
      expect(pickerValue(tester), AccentColor.indigo);
      expect(appAccent(tester), AccentPalette.indigo.light);
      expect(await tester.db(() => SettingsRepository(db).raw('accentColor')), 'indigo');

      // 读屏点回默认：数据库里删掉该行
      tester.semantics.tap(find.semantics.byLabel('朱红'));
      await settleWrite(tester);
      expectChecked(AccentColor.vermilion);
      expect(await tester.db(() => SettingsRepository(db).raw('accentColor')), isNull);

      handle.dispose();
      await finish(tester);
    });
  });
}

class _FailingRepo extends SettingsRepository {
  _FailingRepo(super.db);

  int attempts = 0;
  bool fail = true;

  @override
  Future<void> write<T>(SettingKey<T> key, T value) async {
    attempts++;
    if (fail) throw StateError('disk full');
    await super.write(key, value);
  }
}
