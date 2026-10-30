import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/themed.dart';

String pct(double r) => '${(r * 100).round()}%';

Widget circle(int done, int total, {Widget? empty, Brightness brightness = Brightness.light}) => themed(
  DayCircle(
    done: done,
    total: total,
    formatPercent: pct,
    subtitle: '$done / $total 已完成',
    emptyChild: empty,
  ),
  brightness: brightness,
);

DayCirclePainter painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(DayCircle), matching: find.byType(CustomPaint)).first,
  );
  return paint.painter! as DayCirclePainter;
}

void main() {
  testWidgets('圆心：大号百分比 + "2 / 3 已完成"，都在圆内居中', (tester) async {
    await tester.pumpWidget(circle(2, 3));
    // 两层绘制：前景色一层 + 底色一层（按水位裁切）
    expect(find.text('67%'), findsNWidgets(2));
    expect(find.text('2 / 3 已完成'), findsNWidgets(2));

    final circleRect = tester.getRect(find.byType(DayCircle));
    for (final e in find.text('67%').evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(circleRect.contains(r.topLeft) && circleRect.contains(r.bottomRight), isTrue);
      expect((r.center.dx - circleRect.center.dx).abs(), lessThan(1));
    }
    // 百分比是页面里最大的字
    final text = tester.widget<Text>(find.text('67%').first);
    expect(text.style!.fontSize, FontSizes.display);
    expect(FontSizes.display, greaterThan(FontSizes.title));
  });

  testWidgets('跨过水位线的文字：水位以下那层用底色，并按水位裁切', (tester) async {
    await tester.pumpWidget(circle(1, 2, brightness: Brightness.dark));
    final layers = tester.widgetList<Text>(find.text('50%')).toList();
    final colorsUsed = {for (final t in layers) t.style!.color};
    expect(colorsUsed, {FacetColors.dark.ink, FacetColors.dark.background});
    // 底色那层在 ClipPath 里；前景层没有被裁切
    final clipped = find.ancestor(of: find.text('50%'), matching: find.byType(ClipPath));
    expect(clipped, findsOneWidget);
    // 没有一层用主色（不会出现橙字压在橙底上）
    expect(colorsUsed.contains(FacetColors.dark.accent), isFalse);
  });

  testWidgets('外圈分段：任务数 = 段数，完成的段点亮', (tester) async {
    await tester.pumpWidget(circle(2, 5));
    final p = painter(tester);
    expect(p.total, 5);
    expect(p.litSegments, 2);
    expect(p.progress, closeTo(0.4, 1e-9));
  });

  testWidgets('超过 12 个任务：改为连续进度环（仍按完成数绘制）', (tester) async {
    await tester.pumpWidget(circle(6, 13));
    final p = painter(tester);
    expect(p.total, greaterThan(DayCircle.maxSegments));
    expect(p.litSegments, 6);
  });

  testWidgets('完成一个任务：百分比滚动、水位上升、环段点亮，400ms 内结束', (tester) async {
    await tester.pumpWidget(circle(1, 4));
    expect(find.text('25%'), findsNWidgets(2));

    await tester.pumpWidget(circle(2, 4));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = painter(tester);
    expect(mid.progress, inExclusiveRange(0.25, 0.5));
    expect(mid.litSegments, inExclusiveRange(1, 2));
    // 中途的百分比既不是旧值也不是新值
    expect(find.text('25%'), findsNothing);
    expect(find.text('50%'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(painter(tester).progress, 0.5);
    expect(painter(tester).litSegments, 2);
    expect(find.text('50%'), findsNWidgets(2));
    expect(Motion.standard.inMilliseconds, lessThanOrEqualTo(400));
  });

  testWidgets('全部完成：圆心是对勾，不显示 100%', (tester) async {
    await tester.pumpWidget(circle(3, 3));
    expect(find.text('100%'), findsNothing);
    final checks = tester.widgetList<GeoIcon>(find.byType(GeoIcon)).where((i) => i.glyph == GeoGlyph.check);
    expect(checks, isNotEmpty);
    expect(find.text('3 / 3 已完成'), findsWidgets);
  });

  testWidgets('没有任务：细线空心圆，圆心是调用方给的内容', (tester) async {
    await tester.pumpWidget(circle(0, 0, empty: const Text('今天没有任务')));
    expect(find.text('今天没有任务'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    final p = painter(tester);
    expect(p.total, 0);
    expect(p.progress, 0);
  });

  test('尺寸：外环在最外侧，环与内圆之间留有间距', () {
    final g = DayCircleGeometry(Sizes.dayCircle);
    expect(g.ringRadius + g.ringWidth / 2, closeTo(Sizes.dayCircle / 2, 1e-9));
    expect(g.ringRadius - g.ringWidth / 2 - g.innerRadius, closeTo(Space.s, 1e-9));
  });
}
