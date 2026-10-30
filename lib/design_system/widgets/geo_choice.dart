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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final o in options)
          Expanded(
            child: Semantics(
              button: true,
              selected: o.value == value,
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
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: o.value == value ? colors.accent : colors.line,
                        width: o.value == value ? Stroke.regular : Stroke.thin,
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
                            color: o.value == value ? colors.ink : colors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
