import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/themed.dart';

/// 设置中心用到的两个 design_system 组件在读屏下的表现。
void main() {
  group('GeoOptionList', () {
    Widget list(String value, ValueChanged<String> onChanged) => SizedBox(
      width: 320,
      child: GeoOptionList<String>(
        value: value,
        onChanged: onChanged,
        options: const [
          GeoOption(value: 'a', label: '跟随语言', detail: '当前：周一'),
          GeoOption(value: 'b', label: '周一'),
          GeoOption(value: 'c', label: '周日'),
        ],
      ),
    );

    testWidgets('每项是互斥组里的可勾选项：选中项 checked，其他未选中；都有点按动作', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(list('b', (_) {})));

      expect(
        tester.getSemantics(find.bySemanticsLabel('周一')),
        isSemantics(
          label: '周一',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      for (final label in ['跟随语言，当前：周一', '周日']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(
            label: label,
            isInMutuallyExclusiveGroup: true,
            hasCheckedState: true,
            isChecked: false,
            hasTapAction: true,
          ),
          reason: label,
        );
      }
      handle.dispose();
    });

    testWidgets('第二行说明拼进读屏标签，内部文字不重复朗读', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(list('a', (_) {})));
      expect(find.bySemanticsLabel('跟随语言，当前：周一'), findsOneWidget);
      // excludeSemantics：内部 Text 不再单独成为节点
      expect(find.bySemanticsLabel('当前：周一'), findsNothing);
      expect(find.bySemanticsLabel('跟随语言'), findsNothing);
      handle.dispose();
    });

    testWidgets('读屏点按触发 onChanged 并传对应的值；普通点按也一样', (tester) async {
      final handle = tester.ensureSemantics();
      final chosen = <String>[];
      await tester.pumpWidget(themed(list('a', chosen.add)));

      tester.semantics.tap(find.semantics.byLabel('周日'));
      tester.semantics.tap(find.semantics.byLabel('跟随语言，当前：周一'));
      await tester.tap(find.text('周一'));
      expect(chosen, ['c', 'a', 'b']);
      handle.dispose();
    });

    testWidgets('value 不在选项里：全部未选中，不报错', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(list('zzz', (_) {})));
      expect(tester.takeException(), isNull);
      for (final label in ['跟随语言，当前：周一', '周一', '周日']) {
        expect(tester.getSemantics(find.bySemanticsLabel(label)), isSemantics(isChecked: false), reason: label);
      }
      handle.dispose();
    });

    testWidgets('深色主题下也能正常渲染', (tester) async {
      await tester.pumpWidget(themed(list('b', (_) {}), brightness: Brightness.dark));
      expect(tester.takeException(), isNull);
      expect(find.text('周一'), findsOneWidget);
    });
  });

  group('SettingsTile', () {
    testWidgets('读屏标签包含标题、当前值和警示文字，是可点按的按钮', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(themed(SizedBox(
        width: 360,
        child: SettingsTile(
          title: '提醒',
          value: '准时',
          attention: true,
          attentionLabel: '需要处理',
          onTap: () => taps++,
        ),
      )));

      final node = find.bySemanticsLabel('提醒，准时，需要处理');
      expect(node, findsOneWidget);
      expect(tester.getSemantics(node), isSemantics(isButton: true, hasTapAction: true));
      tester.semantics.tap(find.semantics.byLabel('提醒，准时，需要处理'));
      await tester.tap(find.text('提醒'));
      expect(taps, 2);
      handle.dispose();
    });

    testWidgets('没有警示时标签不含警示文字；没有当前值时只有标题', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsTile(title: '外观', value: '深色', attentionLabel: '需要处理', onTap: () {}),
            SettingsTile(title: '关于', onTap: () {}),
          ],
        ),
      )));
      expect(find.bySemanticsLabel('外观，深色'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('需要处理')), findsNothing);
      expect(find.bySemanticsLabel('关于'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('有警示但没给警示文字：标签只有标题和值，不出现多余分隔符', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(SizedBox(
        width: 360,
        child: SettingsTile(title: '提醒', value: '准时', attention: true, onTap: () {}),
      )));
      expect(find.bySemanticsLabel('提醒，准时'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('两栏模式下暴露选中状态；单栏（selected 为 null）不暴露', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsTile(title: '通用', selected: true, showChevron: false, onTap: () {}),
            SettingsTile(title: '外观', selected: false, showChevron: false, onTap: () {}),
            SettingsTile(title: '关于', onTap: () {}),
          ],
        ),
      )));
      expect(tester.getSemantics(find.bySemanticsLabel('通用')),
          isSemantics(hasSelectedState: true, isSelected: true));
      expect(tester.getSemantics(find.bySemanticsLabel('外观')),
          isSemantics(hasSelectedState: true, isSelected: false));
      expect(tester.getSemantics(find.bySemanticsLabel('关于')), isSemantics(hasSelectedState: false));
      handle.dispose();
    });

    testWidgets('很长的当前值不溢出（窄宽度 + 深色）', (tester) async {
      await tester.pumpWidget(themed(
        SizedBox(
          width: 240,
          child: SettingsTile(
            title: '一个比较长的分组标题',
            value: '一个非常非常非常非常非常非常非常非常非常非常非常长的当前值说明文字',
            attention: true,
            attentionLabel: '需要处理',
            onTap: () {},
          ),
        ),
        brightness: Brightness.dark,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
