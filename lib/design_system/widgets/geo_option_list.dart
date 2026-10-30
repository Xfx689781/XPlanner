import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../motion.dart';
import '../colors.dart';
import '../tokens.dart';

class GeoOption<T> {
  const GeoOption({
    required this.value,
    required this.label,
    this.detail,
    this.labelLocale,
  });

  final T value;
  final String label;

  /// 第二行说明（可选）
  final String? detail;

  /// 标签用哪个 locale 选字形（例如在简体界面里显示"繁體中文"）
  final Locale? labelLocale;
}

/// 纵向单选列表：选中 = 主色实心小方块，未选中 = 细线空心小方块。不用 Material 的 Radio。
class GeoOptionList<T> extends StatelessWidget {
  const GeoOptionList({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<GeoOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in options)
          _OptionRow(
            option: o,
            selected: o.value == value,
            onTap: () => onChanged(o.value),
          ),
      ],
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final GeoOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: [option.label, ?option.detail].join('，'),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Sizes.tapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: Space.s,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Motion.quick,
                curve: Motion.curve,
                width: Sizes.glyphInline,
                height: Sizes.glyphInline,
                decoration: BoxDecoration(
                  color: selected ? colors.accent : FacetColors.transparent,
                  border: Border.all(
                    color: selected ? colors.accent : colors.muted,
                    width: Stroke.thin,
                  ),
                  borderRadius: BorderRadius.circular(Radii.square),
                ),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      locale: option.labelLocale,
                      style: context.text.body,
                    ),
                    if (option.detail != null)
                      Text(option.detail!, style: context.text.small),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
