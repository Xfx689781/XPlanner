import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';
import 'geo_icon.dart';

class GeoNavItem {
  const GeoNavItem({required this.glyph, required this.label});

  final GeoGlyph glyph;
  final String label;
}

/// 几何导航。窄屏横向放在底部，宽屏纵向放在左侧。
/// 选中项：主色实心字形 + 一条主色短线；未选中：灰色空心字形。
class GeoNavBar extends StatelessWidget {
  const GeoNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.vertical = false,
  });

  final List<GeoNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = [
      for (var i = 0; i < items.length; i++)
        _NavButton(
          item: items[i],
          selected: i == selectedIndex,
          onTap: () => onSelected(i),
        ),
    ];
    final divider = BorderSide(color: colors.line, width: Stroke.thin);

    if (vertical) {
      return Container(
        width: Sizes.navRail,
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(right: divider),
        ),
        child: SafeArea(
          right: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xl),
            child: Column(
              children: [
                for (final c in children)
                  SizedBox(height: Sizes.navBar + Space.m, child: c),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: divider),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Sizes.navBar,
          child: Row(children: [for (final c in children) Expanded(child: c)]),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GeoNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.accent : colors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GeoIcon(item.glyph, color: color, filled: selected),
            const SizedBox(height: Space.xs),
            Text(item.label, style: context.text.small.copyWith(color: color)),
            const SizedBox(height: Space.xs),
            AnimatedContainer(
              duration: Motion.quick,
              curve: Motion.curve,
              width: selected ? Sizes.navIndicator : 0,
              height: Stroke.regular,
              color: colors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
