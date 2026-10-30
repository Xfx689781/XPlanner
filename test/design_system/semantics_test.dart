import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/themed.dart';

void main() {
  testWidgets('几何按钮在读屏模式下可以点击', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    var chosen = 0;
    var nav = 0;
    await tester.pumpWidget(themed(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GeoIconButton(glyph: GeoGlyph.plus, semanticLabel: '新建', onPressed: () => taps++),
        SizedBox(
          width: 300,
          child: GeoChoice<int>(
            value: 0,
            onChanged: (v) => chosen = v,
            options: const [GeoChoiceOption(value: 0, label: '低'), GeoChoiceOption(value: 1, label: '高')],
          ),
        ),
        SizedBox(
          width: 300,
          child: GeoNavBar(
            items: const [GeoNavItem(glyph: GeoGlyph.circle, label: '今天'), GeoNavItem(glyph: GeoGlyph.square, label: '任务')],
            selectedIndex: 0,
            onSelected: (i) => nav = i,
          ),
        ),
      ],
    )));

    for (final label in ['新建', '高', '任务']) {
      expect(tester.getSemantics(find.bySemanticsLabel(label)), matchesSemantics(
        label: label,
        isButton: true,
        hasTapAction: true,
        isSelected: false,
        hasSelectedState: label != '新建',
      ), reason: label);
    }
    for (final label in ['新建', '高', '任务']) {
      tester.semantics.tap(find.semantics.byLabel(label));
    }
    expect((taps, chosen, nav), (1, 1, 1));
    handle.dispose();
  });

  testWidgets('提醒短线有读屏标签', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themed(const ReminderMark(label: '09:00 · 每天')));
    expect(find.bySemanticsLabel('提醒 09:00 · 每天'), findsOneWidget);
    await tester.pumpWidget(themed(const ReminderMark(label: '09:00', active: false)));
    expect(find.bySemanticsLabel('提醒 09:00，已不会响'), findsOneWidget);
    handle.dispose();
  });
}
