import 'package:facet/app/week_start_localizations.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  Brightness brightnessOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(PageFrame).first)).brightness;

  testWidgets('主题：深色设置在第一帧就生效', (tester) async {
    await tester.pumpWidget(testApp(db, settings: const AppSettings(theme: ThemePreference.dark)));
    expect(brightnessOf(tester), Brightness.dark);
    await finish(tester);
  });

  testWidgets('主题：切换后立即生效；跟随系统时随系统明暗变化', (tester) async {
    await tester.pumpWidget(testApp(db));
    final container = ProviderScope.containerOf(tester.element(find.byType(PageFrame).first));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.dark);

    await tester.runAsync(() => container.read(settingsProvider.notifier).setTheme(ThemePreference.light));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.light);
    await finish(tester);
  });

  Future<int> firstDayIndex(WidgetTester tester, WeekStart ws) async {
    await tester.pumpWidget(testApp(db, settings: AppSettings(weekStart: ws)));
    await tester.pumpAndSettle();
    return MaterialLocalizations.of(tester.element(find.byType(PageFrame).first)).firstDayOfWeekIndex;
  }

  testWidgets('一周开始日：周一 / 周日 / 跟随语言', (tester) async {
    expect(await firstDayIndex(tester, WeekStart.monday), 1);
    expect(await firstDayIndex(tester, WeekStart.sunday), 0);
    final zh = await GlobalMaterialLocalizations.delegate.load(const Locale('zh', 'CN'));
    expect(await firstDayIndex(tester, WeekStart.locale), zh.firstDayOfWeekIndex);
    await finish(tester);
  });

  testWidgets('一周从周一开始时，日期选择器第一列是周一', (tester) async {
    await tester.pumpWidget(testApp(db, settings: const AppSettings(weekStart: WeekStart.monday)));
    final ctx = tester.element(find.byType(PageFrame).first);
    showDatePicker(context: ctx, initialDate: DateTime(2026, 10, 30), firstDate: DateTime(2026), lastDate: DateTime(2027));
    await tester.pumpAndSettle();
    final headers = MaterialLocalizations.of(ctx).narrowWeekdays;
    final first = tester.getTopLeft(find.text(headers[1]).first);
    final sunday = tester.getTopLeft(find.text(headers[0]).first);
    expect(first.dx, lessThan(sunday.dx));
    await finish(tester);
  });

  test('包装类只改一周第一天，其他成员原样转发', () async {
    final base = await GlobalMaterialLocalizations.delegate.load(const Locale('zh', 'CN'));
    final wrapped = WeekStartMaterialLocalizations(base, 1);
    expect(wrapped.firstDayOfWeekIndex, 1);
    expect(wrapped.cancelButtonLabel, base.cancelButtonLabel);
    expect(wrapped.formatMediumDate(DateTime(2026, 10, 30)), base.formatMediumDate(DateTime(2026, 10, 30)));
    expect(wrapped.tabLabel(tabIndex: 2, tabCount: 3), base.tabLabel(tabIndex: 2, tabCount: 3));
    expect(wrapped.narrowWeekdays, base.narrowWeekdays);
  });

  test('delegate 只在设置变化时重新加载', () {
    const a = WeekStartMaterialDelegate(WeekStart.monday);
    expect(a.shouldReload(const WeekStartMaterialDelegate(WeekStart.monday)), isFalse);
    expect(a.shouldReload(const WeekStartMaterialDelegate(WeekStart.sunday)), isTrue);
  });
}
