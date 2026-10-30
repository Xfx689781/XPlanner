import 'package:flutter/widgets.dart';

import '../colors.dart';
import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';
import 'geo_icon.dart';
import 'status_dot.dart';

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
    this.selected,
    this.showChevron = true,
  });

  final String title;

  /// 当前值（如"深色"）
  final String? value;

  /// 需要处理：标题旁画一个主色空心小圆
  final bool attention;

  /// 警示的读屏文字（如"需要处理"）
  final String? attentionLabel;
  /// 两栏模式下是否为当前分组；单栏传 null（不暴露"选中"状态给读屏）
  final bool? selected;
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
          constraints: const BoxConstraints(minHeight: Sizes.settingsRow),
          // 左侧竖线占 Stroke.regular，内边距相应减去，标题与页标题左对齐
          padding: const EdgeInsets.fromLTRB(Space.l - Stroke.regular, Space.s, Space.m, Space.s),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected == true ? colors.accent : FacetColors.transparent,
                width: Stroke.regular,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                // 标题不参与弹性分配（最多占一半），剩余宽度全部给右侧的当前值
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                  child: Text(title, style: context.text.body),
                ),
                if (attention) ...[
                  const SizedBox(width: Space.s),
                  const StatusDot(StatusKind.attention),
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
                  GeoIcon(GeoGlyph.forward, size: Sizes.glyphInline, color: colors.muted, strokeWidth: Stroke.regular),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
