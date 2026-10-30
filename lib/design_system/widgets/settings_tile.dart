import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';
import 'geo_icon.dart';

/// 设置中心的一行：标题 + 右侧当前值 + 可选警示 + 进入箭头。
/// 两栏模式下 [selected] 用一条主色竖线标出当前分组。
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    required this.onTap,
    this.value,
    this.attention = false,
    this.attentionLabel,
    this.selected = false,
    this.showChevron = true,
  });

  final String title;

  /// 当前值（如"深色"）
  final String? value;

  /// 需要处理：标题旁画一个主色空心小圆
  final bool attention;

  /// 警示的读屏文字（如"需要处理"）
  final String? attentionLabel;
  final bool selected;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = [title, ?value, if (attention) ?attentionLabel].join('，');
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.quick,
          constraints: const BoxConstraints(minHeight: Sizes.tapTarget + Space.s),
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.m, Space.s),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? colors.accent : const Color(0x00000000),
                width: Stroke.regular,
              ),
            ),
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(title, style: context.text.body),
              ),
              if (attention) ...[
                const SizedBox(width: Space.s),
                GeoIcon(
                  GeoGlyph.circle,
                  size: Sizes.glyphInline,
                  color: colors.accent,
                  strokeWidth: Stroke.regular,
                ),
              ],
              const SizedBox(width: Space.m),
              Expanded(
                child: value == null
                    ? const SizedBox.shrink()
                    : Text(
                        value!,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.small,
                      ),
              ),
              if (showChevron) ...[
                const SizedBox(width: Space.s),
                GeoIcon(GeoGlyph.forward, size: Sizes.glyphInline, color: colors.muted, strokeWidth: Stroke.thin),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
