import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';

class GeoChoiceOption<T> {
  const GeoChoiceOption({
    required this.value,
    required this.label,
    this.leading,
  });

  final T value;
  final String label;

  /// 可选的几何示意（例如不同粗细的方块）
  final Widget? leading;
}

/// 分段选择：选中项下方一条主色线。
class GeoChoice<T> extends StatelessWidget {
  const GeoChoice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<GeoChoiceOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// 每项两侧的内边距
  static const _itemPadding = Space.s;

  @override
  Widget build(BuildContext context) {
    final style = context.text.small;
    final scaler = MediaQuery.textScalerOf(context);
    final widths = [
      for (final o in options)
        _textWidth(o.label, style, scaler) +
            (o.leading == null ? 0 : Sizes.glyphInline + Space.s) +
            _itemPadding * 2,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = widths.fold<double>(0, (a, b) => a + b);
        // 一行放得下：按每项文字的自然宽度分配（长词不会被拆开）；放不下：改为纵向一项一行
        if (total <= constraints.maxWidth) {
          return Row(
            children: [
              for (var i = 0; i < options.length; i++)
                Expanded(
                  flex: (widths[i] * 100).round().clamp(1, 1 << 30),
                  child: _item(context, options[i]),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final o in options) _item(context, o)],
        );
      },
    );
  }

  static double _textWidth(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w.ceilToDouble() + 1;
  }

  Widget _item(BuildContext context, GeoChoiceOption<T> o) {
    final colors = context.colors;
    final selected = o.value == value;
    return Semantics(
      button: true,
      selected: selected,
      label: o.label,
      onTap: () => onChanged(o.value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(o.value),
        child: AnimatedContainer(
          duration: Motion.quick,
          curve: Motion.curve,
          constraints: const BoxConstraints(minHeight: Sizes.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: _itemPadding),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? colors.accent : colors.line,
                width: selected ? Stroke.regular : Stroke.thin,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (o.leading != null) ...[
                o.leading!,
                const SizedBox(width: Space.s),
              ],
              Flexible(
                child: Text(
                  o.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.small.copyWith(
                    color: selected ? colors.ink : colors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
