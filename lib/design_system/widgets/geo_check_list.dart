import 'package:flutter/widgets.dart';

import '../colors.dart';
import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';

class GeoCheckItem<T> {
  const GeoCheckItem({required this.value, required this.label, this.enabled = true});

  final T value;
  final String label;

  /// false：置灰、不能点（例如已选满、与重复周期冲突）
  final bool enabled;
}

/// 纵向多选列表：选中 = 主色实心小方块里一道底色横线，未选中 = 细线空心小方块。
/// 与单选的 [GeoOptionList] 区分：多选的方块里有一道横线（"勾"的几何化）。
class GeoCheckList<T> extends StatelessWidget {
  const GeoCheckList({
    super.key,
    required this.items,
    required this.selected,
    required this.onToggle,
    this.trailingOf,
  });

  final List<GeoCheckItem<T>> items;
  final Set<T> selected;
  final ValueChanged<T> onToggle;

  /// 选中项右侧的附加控件（例如通知 / 闹钟切换）
  final Widget? Function(T value)? trailingOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          _CheckRow<T>(
            item: item,
            checked: selected.contains(item.value),
            onTap: () => onToggle(item.value),
            trailing: selected.contains(item.value) ? trailingOf?.call(item.value) : null,
          ),
      ],
    );
  }
}

class _CheckRow<T> extends StatelessWidget {
  const _CheckRow({required this.item, required this.checked, required this.onTap, this.trailing});

  final GeoCheckItem<T> item;
  final bool checked;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = item.enabled || checked;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Semantics(
            checked: checked,
            enabled: enabled,
            label: item.label,
            onTap: enabled ? onTap : null,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? onTap : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: Sizes.tapTarget),
                padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: Motion.quick,
                      curve: Motion.curve,
                      width: Sizes.glyphInline,
                      height: Sizes.glyphInline,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: checked ? colors.accent : FacetColors.transparent,
                        border: Border.all(
                          color: checked ? colors.accent : (enabled ? colors.muted : colors.line),
                          width: Stroke.thin,
                        ),
                        borderRadius: BorderRadius.circular(Radii.square),
                      ),
                      child: checked
                          ? Container(width: Sizes.glyphInline / 2, height: Stroke.regular, color: colors.onAccent)
                          : null,
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Text(
                        item.label,
                        style: context.text.body.copyWith(color: enabled ? colors.ink : colors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (trailing != null) Flexible(flex: 2, child: Align(alignment: AlignmentDirectional.centerEnd, child: trailing)),
      ],
    );
  }
}
