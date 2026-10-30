import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/themed.dart';

TaskSquarePainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(TaskSquare), matching: find.byType(CustomPaint)),
  );
  return paint.painter! as TaskSquarePainter;
}

void main() {
  testWidgets('首次构建不播放动画，直接显示最终状态', (tester) async {
    await tester.pumpWidget(themed(const TaskSquare(done: true, strokeWidth: Stroke.bold)));
    expect(_painter(tester).fill, 1);
    expect(_painter(tester).strokeWidth, Stroke.bold);
  });

  testWidgets('完成时填充动画在 400ms 内结束', (tester) async {
    var done = false;
    late StateSetter setState;
    await tester.pumpWidget(themed(StatefulBuilder(builder: (context, s) {
      setState = s;
      return TaskSquare(
        done: done,
        strokeWidth: Stroke.regular,
        onTap: () => setState(() => done = !done),
      );
    })));
    expect(_painter(tester).fill, 0);

    await tester.tap(find.byType(TaskSquare));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _painter(tester).fill;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));

    await tester.pump(const Duration(milliseconds: 300));
    expect(_painter(tester).fill, 1);
  });

  testWidgets('点击区域不小于最小触控尺寸', (tester) async {
    await tester.pumpWidget(themed(const TaskSquare(done: false, strokeWidth: Stroke.thin)));
    final size = tester.getSize(find.byType(TaskSquare));
    expect(size.width, greaterThanOrEqualTo(Sizes.tapTarget));
  });

  testWidgets('深色主题下也能渲染', (tester) async {
    await tester.pumpWidget(
      themed(const TaskSquare(done: false, strokeWidth: Stroke.thin), brightness: Brightness.dark),
    );
    expect(_painter(tester).outline, FacetColors.dark.ink);
  });

  testWidgets('逾期：未完成时主色描边，完成后与普通完成一致', (tester) async {
    await tester.pumpWidget(themed(const TaskSquare(done: false, overdue: true, strokeWidth: Stroke.regular)));
    expect(_painter(tester).outline, FacetColors.light.accent);
    expect(_painter(tester).fill, 0);

    await tester.pumpWidget(themed(const TaskSquare(done: false, strokeWidth: Stroke.regular)));
    await tester.pumpAndSettle();
    expect(_painter(tester).outline, FacetColors.light.ink);
  });
}
