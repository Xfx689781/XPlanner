import 'dart:math' as math;

import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// WCAG 2.x 相对亮度 / 对比度
double _luminance(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// 6 种主题色 × 浅 / 深：实际渲染出来的颜色都来自当前主题色（大圆水位、方块、导航、分段选择），
/// 危险操作（删除按钮、删除确认框）固定是警示红。
void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));
  setUp(() => db = openTestDb());

  for (final accent in AccentColor.values) {
    for (final brightness in Brightness.values) {
      final palette = AccentPalette.values.byName(accent.name);
      final expectedAccent = palette.forBrightness(brightness);
      final expectedDanger = brightness == Brightness.light ? FacetColors.light.danger : FacetColors.dark.danger;

      testWidgets('${accent.name} × ${brightness.name}：大圆 / 方块 / 导航 / 分段选择用主题色，删除用警示红', (tester) async {
        await tester.db(() async {
          final repo = TaskRepository(db);
          final a = await repo.create(TaskDraft(title: '已完成的', dueAt: DateTime(2026, 10, 30)), now: clock.value);
          await repo.create(TaskDraft(title: '没做的', dueAt: DateTime(2026, 10, 30)), now: clock.value);
          await repo.setCompleted(a.id, clock.value, now: clock.value);
        });
        await tester.pumpWidget(testApp(
          db,
          clock: clock,
          settings: AppSettings(
            theme: brightness == Brightness.light ? ThemePreference.light : ThemePreference.dark,
            accent: accent,
          ),
        ));
        await tester.pumpAndSettle();

        final colors = tester.element(find.byType(DayCircle)).colors;
        expect(colors.accent, expectedAccent);
        expect(Theme.of(tester.element(find.byType(DayCircle))).brightness, brightness);

        // ---- 今天页大圆（部分完成）----
        final circle = tester.widget<DayCircle>(find.byType(DayCircle));
        expect(circle.progress, 0.5);
        final painter = tester
            .widgetList<CustomPaint>(find.descendant(of: find.byType(DayCircle), matching: find.byType(CustomPaint)))
            .map((p) => p.painter)
            .whereType<DayCirclePainter>()
            .single;
        expect(painter.fillColor, expectedAccent);

        // 两层文字：用裁切路径区分哪一层是水位以下（包含内圆底部的点）
        final clips = find.descendant(of: find.byType(DayCircle), matching: find.byType(ClipPath));
        expect(clips, findsNWidgets(2));
        final circleBox = tester.getSize(find.byType(DayCircle));
        final geometry = DayCircleGeometry(circle.diameter);
        final bottomInside = Offset(circleBox.width / 2, circleBox.height / 2 + geometry.innerRadius - 2);
        var belowCount = 0;
        for (var i = 0; i < 2; i++) {
          final clipFinder = clips.at(i);
          final clip = tester.widget<ClipPath>(clipFinder);
          final path = clip.clipper!.getClip(circleBox);
          final isBelow = path.contains(bottomInside) &&
              !path.contains(Offset(circleBox.width / 2, circleBox.height / 2 - geometry.innerRadius + 2));
          final texts = tester.widgetList<Text>(find.descendant(of: clipFinder, matching: find.byType(Text)));
          expect(texts, isNotEmpty);
          for (final t in texts) {
            expect(t.style!.color, isBelow ? colors.onAccent : colors.ink, reason: '"${t.data}" below=$isBelow');
          }
          if (isBelow) belowCount++;
        }
        expect(belowCount, 1, reason: '应恰好有一层在水位以下');
        expect(_contrast(colors.onAccent, expectedAccent), greaterThanOrEqualTo(4.5));

        // ---- 任务方块完成填充 ----
        final doneSquare = find.byWidgetPredicate((w) => w is TaskSquare && w.done);
        expect(doneSquare, findsOneWidget);
        final squarePainter = tester
            .widgetList<CustomPaint>(find.descendant(of: doneSquare, matching: find.byType(CustomPaint)))
            .map((p) => p.painter)
            .whereType<TaskSquarePainter>()
            .single;
        expect(squarePainter.fill, 1.0);
        expect(squarePainter.fillColor, expectedAccent);
        expect(squarePainter.outline, expectedAccent);

        // ---- 导航选中项 ----
        final nav = find.byType(GeoNavBar);
        final todayLabel = tester.widget<Text>(find.descendant(of: nav, matching: find.text('今天')));
        expect(todayLabel.style!.color, expectedAccent);
        final tasksLabel = tester.widget<Text>(find.descendant(of: nav, matching: find.text('任务')));
        expect(tasksLabel.style!.color, colors.muted);
        final selectedIcon = tester
            .widgetList<GeoIcon>(find.descendant(of: nav, matching: find.byType(GeoIcon)))
            .where((i) => i.filled)
            .single;
        expect(selectedIcon.color, expectedAccent);

        // ---- 任务编辑弹层：GeoChoice 选中下划线 ----
        await tester.tap(find.text('没做的'));
        await tester.pumpAndSettle();
        final choice = find.byType(GeoChoice<Priority>);
        expect(choice, findsOneWidget);
        final underlines = [
          for (final c in tester.widgetList<AnimatedContainer>(
            find.descendant(of: choice, matching: find.byType(AnimatedContainer)),
          ))
            ((c.decoration! as BoxDecoration).border! as Border).bottom,
        ];
        final selected = underlines.where((b) => b.width == Stroke.regular).toList();
        expect(selected, hasLength(1));
        expect(selected.single.color, expectedAccent);
        expect(underlines.where((b) => b.width != Stroke.regular).every((b) => b.color == colors.line), isTrue);

        // ---- 编辑弹层的"删除"：警示红，不是主题色 ----
        final del = find.text('删除');
        await tester.ensureVisible(del);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(del).style!.color, expectedDanger);
        expect(tester.element(del).colors.danger, expectedDanger);

        // ---- 删除确认框：确认文字和描边是警示红，取消不是 ----
        await tester.tap(del);
        await tester.pumpAndSettle();
        final dialog = find.byType(Dialog);
        expect(dialog, findsOneWidget);
        final confirm = find.descendant(of: dialog, matching: find.widgetWithText(GeoButton, '删除'));
        final cancel = find.descendant(of: dialog, matching: find.widgetWithText(GeoButton, '取消'));
        Color textColor(Finder button) =>
            tester.widget<Text>(find.descendant(of: button, matching: find.byType(Text))).style!.color!;
        BoxDecoration deco(Finder button) => tester
            .widget<Container>(find.descendant(of: button, matching: find.byType(Container)).first)
            .decoration! as BoxDecoration;

        expect(textColor(confirm), expectedDanger);
        final confirmBorder = deco(confirm).border! as Border;
        expect(confirmBorder.top.color, expectedDanger);
        expect(confirmBorder.left.color, expectedDanger);
        expect(textColor(cancel), isNot(expectedDanger));
        expect(textColor(cancel), colors.ink);
        expect(deco(cancel).border, isNull);

        await tester.tap(find.descendant(of: dialog, matching: find.text('取消')));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);

        await tester.disposeApp();
        await tester.db(db.close);
      });
    }
  }
}
