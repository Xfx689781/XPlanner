import 'package:flutter/widgets.dart';

import '../colors.dart';
import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';

class GeoSwatch<T> {
  const GeoSwatch({required this.value, required this.color, required this.label});

  final T value;
  final Color color;

  /// 颜色名（读屏）
  final String label;
}

/// 一排实心小圆色块，选中项外面加一圈细环。
/// 例外说明：圆在 SPEC 里代表"一天"，这里只作为设置页的颜色样本使用（见 SPEC「设计语言」）。
class GeoSwatchPicker<T> extends StatelessWidget {
  const GeoSwatchPicker({
    super.key,
    required this.swatches,
    required this.value,
    required this.onChanged,
  });

  final List<GeoSwatch<T>> swatches;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const ringBox = Sizes.swatch + (Space.xs + Stroke.thin) * 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.m),
      child: Wrap(
        children: [
          for (final s in swatches)
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: s.value == value,
              label: s.label,
              onTap: () => onChanged(s.value),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(s.value),
                child: SizedBox.square(
                  dimension: Sizes.tapTarget,
                  child: Center(
                    child: AnimatedContainer(
                      duration: Motion.quick,
                      curve: Motion.curve,
                      width: ringBox,
                      height: ringBox,
                      padding: const EdgeInsets.all(Space.xs),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: s.value == value ? colors.ink : FacetColors.transparent,
                          width: Stroke.thin,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
