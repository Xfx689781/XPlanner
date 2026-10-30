import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:facet/features/settings/settings_labels.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

/// 主题色在三种界面语言下的文案：标题、6 个颜色名（读屏 label）、外观分组摘要；以及长英文 + 窄屏 + 大字号不溢出。
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

  const cases = <String, _Expected>{
    'en': _Expected(
      settings: 'Settings',
      appearance: 'Appearance',
      accentTitle: 'Accent color',
      system: 'Follow system',
      dark: 'Dark',
      names: {
        AccentColor.vermilion: 'Vermilion',
        AccentColor.amber: 'Amber',
        AccentColor.pine: 'Pine',
        AccentColor.teal: 'Teal',
        AccentColor.indigo: 'Indigo',
        AccentColor.plum: 'Violet',
      },
    ),
    'zh-Hans': _Expected(
      settings: '设置',
      appearance: '外观',
      accentTitle: '主题色',
      system: '跟随系统',
      dark: '深色',
      names: {
        AccentColor.vermilion: '朱红',
        AccentColor.amber: '琥珀',
        AccentColor.pine: '松绿',
        AccentColor.teal: '湖蓝',
        AccentColor.indigo: '靛蓝',
        AccentColor.plum: '紫',
      },
    ),
    'zh-Hant': _Expected(
      settings: '設定',
      appearance: '外觀',
      accentTitle: '主題色',
      system: '跟隨系統',
      dark: '深色',
      names: {
        AccentColor.vermilion: '朱紅',
        AccentColor.amber: '琥珀',
        AccentColor.pine: '松綠',
        AccentColor.teal: '湖藍',
        AccentColor.indigo: '靛藍',
        AccentColor.plum: '紫',
      },
    ),
  };

  test('三种语言都有对应用例（新增语言时提醒补上）', () {
    expect(cases.keys.toSet(), {for (final l in appLanguages) l.tag});
  });

  test('各语言里 6 个颜色名两两不同', () {
    for (final e in cases.entries) {
      expect(e.value.names.values.toSet(), hasLength(AccentColor.values.length), reason: e.key);
    }
  });

  for (final lang in appLanguages) {
    final x = cases[lang.tag]!;
    testWidgets('${lang.tag}：主题色标题、颜色名、外观摘要；选色 / 改主题后摘要跟着变', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp(db, clock: clock, settings: AppSettings(languageTag: lang.tag)));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(x.settings));
      await tester.pumpAndSettle();

      SettingsTile tile() => tester.widget<SettingsTile>(
        find.byWidgetPredicate((w) => w is SettingsTile && w.title == x.appearance),
      );
      expect(tile().value, '${x.system} · ${x.names[AccentColor.vermilion]}');

      await tester.tap(find.text(x.appearance).first);
      await tester.pumpAndSettle();
      expect(find.text(x.accentTitle), findsOneWidget);

      // 色块 label 与当前语言的颜色名逐个一致，并能用读屏找到
      final picker = tester.widget<GeoSwatchPicker<AccentColor>>(find.byType(GeoSwatchPicker<AccentColor>));
      expect({for (final s in picker.swatches) s.value: s.label}, x.names);
      for (final name in x.names.values) {
        expect(find.semantics.byLabel(name), findsOne, reason: name);
      }
      final l10n = AppLocalizations.of(tester.element(find.byType(GeoSwatchPicker<AccentColor>)));
      for (final a in AccentColor.values) {
        expect(accentLabel(l10n, a), x.names[a]);
      }

      await tester.tap(find.bySemanticsLabel(x.names[AccentColor.teal]!));
      await settleWrite(tester);
      expect(tile().value, '${x.system} · ${x.names[AccentColor.teal]}');

      await tester.tap(find.text(x.dark));
      await settleWrite(tester);
      expect(tile().value, '${x.dark} · ${x.names[AccentColor.teal]}');

      handle.dispose();
      await finish(tester);
    });
  }

  for (final theme in [ThemePreference.system, ThemePreference.dark]) {
    testWidgets('en 320 宽 × 字号 1.3（主题 ${theme.name}，最长颜色名 Vermilion）：设置主页摘要和外观分组都不溢出', (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(testApp(
        db,
        clock: clock,
        settings: AppSettings(languageTag: 'en', theme: theme),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(theme == ThemePreference.system ? 'Follow system · Vermilion' : 'Dark · Vermilion'), findsOneWidget);

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Accent color'), findsOneWidget);

      // 每个色块都完整落在屏幕宽度内（放不下时换行，而不是被裁掉）
      final picker = find.byType(GeoSwatchPicker<AccentColor>);
      final swatchTargets = find.descendant(of: picker, matching: find.byType(GestureDetector));
      expect(swatchTargets, findsNWidgets(AccentColor.values.length));
      for (var i = 0; i < AccentColor.values.length; i++) {
        final r = tester.getRect(swatchTargets.at(i));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(320));
      }

      // 选一个颜色后摘要变化，也不溢出
      await tester.tap(find.bySemanticsLabel('Indigo'));
      await settleWrite(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('· Indigo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  }
}

class _Expected {
  const _Expected({
    required this.settings,
    required this.appearance,
    required this.accentTitle,
    required this.system,
    required this.dark,
    required this.names,
  });

  final String settings;
  final String appearance;
  final String accentTitle;
  final String system;
  final String dark;
  final Map<AccentColor, String> names;
}
