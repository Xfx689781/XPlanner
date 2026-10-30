import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));
  setUp(() => db = openTestDb());

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  Color accentOf(WidgetTester tester) => tester.element(find.byType(DayCircle)).colors.accent;

  testWidgets('外观里选松绿：整个 App 立即换色、写入设置表；重启后仍是松绿', (tester) async {
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.pumpAndSettle();
    expect(accentOf(tester), AccentPalette.vermilion.light);

    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('外观').first);
    await tester.pumpAndSettle();
    expect(find.text('主题色'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('松绿'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    // 设置页本身已经换色
    expect(tester.element(find.text('主题色')).colors.accent, AccentPalette.pine.light);
    final saved = await tester.db(() => SettingsRepository(db).load());
    expect(saved.accent, AccentColor.pine);

    await tester.disposeApp();
    await tester.pumpWidget(testApp(db, clock: clock, settings: saved));
    await tester.pumpAndSettle();
    expect(accentOf(tester), AccentPalette.pine.light);
    await finish(tester);
  });

  testWidgets('深色模式用深色版主题色', (tester) async {
    await tester.pumpWidget(testApp(
      db,
      clock: clock,
      settings: const AppSettings(theme: ThemePreference.dark, accent: AccentColor.indigo),
    ));
    await tester.pumpAndSettle();
    expect(accentOf(tester), AccentPalette.indigo.dark);
    await finish(tester);
  });

  testWidgets('色块读屏：互斥组、颜色名、选中状态、可点按', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(testApp(db, clock: clock, settings: const AppSettings(accent: AccentColor.teal)));
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('外观').first);
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('湖蓝')),
      isSemantics(isInMutuallyExclusiveGroup: true, hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('朱红')),
      isSemantics(isInMutuallyExclusiveGroup: true, hasCheckedState: true, isChecked: false, hasTapAction: true),
    );
    handle.dispose();
    await finish(tester);
  });

  testWidgets('删除按钮固定用警示红，不随主题色变，并保留文字', (tester) async {
    await tester.db(() => TaskRepository(db).create(const TaskDraft(title: '要删的'), now: clock.value));
    for (final accent in [AccentColor.vermilion, AccentColor.pine]) {
      await tester.pumpWidget(testApp(db, clock: clock, settings: AppSettings(accent: accent)));
      await tester.pumpAndSettle();
      await tester.tapNav('任务');
      await tester.tap(find.text('要删的'));
      await tester.pumpAndSettle();
      final del = find.text('删除');
      await tester.ensureVisible(del);
      final text = tester.widget<Text>(del);
      expect(text.style!.color, FacetColors.light.danger, reason: accent.name);
      expect(text.style!.color, isNot(tester.element(del).colors.accent));
      await tester.disposeApp();
    }
    await tester.db(db.close);
  });

  testWidgets('320 宽、字号 1.3：色块一排放不下时换行，不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('外观'));
    await tester.pumpAndSettle();
    expect(find.byType(GeoSwatchPicker<AccentColor>), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('需要处理的提示固定用警示红：松绿主题下权限未开启，圆点和文字都不是绿色', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scheduler = FakeScheduler()..notificationsOn = false;
    await tester.pumpWidget(testApp(
      db,
      clock: clock,
      settings: const AppSettings(accent: AccentColor.pine),
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
    ));
    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提醒').first);
    await tester.pumpAndSettle();

    final bad = find.text('未开启，提醒不会弹出');
    expect(tester.widget<Text>(bad).style!.color, FacetColors.light.danger);
    final dots = tester.widgetList<StatusDot>(find.byType(StatusDot)).where((d) => d.kind == StatusKind.attention);
    expect(dots, isNotEmpty);
    final dotIcon = tester.widget<GeoIcon>(
      find.descendant(of: find.byWidget(dots.first), matching: find.byType(GeoIcon)),
    );
    expect(dotIcon.color, FacetColors.light.danger);
    expect(dotIcon.color, isNot(AccentPalette.pine.light));
    await finish(tester);
  });
}
