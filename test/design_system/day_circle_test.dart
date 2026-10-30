import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/themed.dart';

DayCirclePainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(DayCircle), matching: find.byType(CustomPaint)),
  );
  return paint.painter! as DayCirclePainter;
}

void main() {
  testWidgets('进度被限制在 0..1', (tester) async {
    await tester.pumpWidget(themed(const DayCircle(progress: 1.7)));
    expect(_painter(tester).progress, 1);

    await tester.pumpWidget(themed(const DayCircle(progress: -0.2)));
    await tester.pumpAndSettle();
    expect(_painter(tester).progress, 0);
  });

  testWidgets('进度变化有平滑过渡', (tester) async {
    await tester.pumpWidget(themed(const DayCircle(progress: 0)));
    await tester.pumpWidget(themed(const DayCircle(progress: 0.5)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).progress, inExclusiveRange(0, 0.5));
    await tester.pumpAndSettle();
    expect(_painter(tester).progress, 0.5);
  });

  testWidgets('显示圆心内容', (tester) async {
    await tester.pumpWidget(themed(const DayCircle(progress: 0.3, child: Text('1/3'))));
    expect(find.text('1/3'), findsOneWidget);
  });
}
