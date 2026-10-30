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
    final label = [title, ?value, if (attention) ?attentionLabel].join(', ');
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
          padding: const EdgeInsets.fromLTRB(
            Space.l - Stroke.regular,
            Space.s,
            Space.m,
            Space.s,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected == true
                    ? colors.accent
                    : FacetColors.transparent,
                width: Stroke.regular,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scaler = MediaQuery.textScalerOf(context);
              final titleWidth = _measure(title, context.text.body, scaler);
              final valueWidth = value == null
                  ? 0.0
                  : _measure(value!, context.text.small, scaler);
              final fixed =
                  (attention ? Space.s + Sizes.glyphInline : 0) +
                  Space.m +
                  (showChevron ? Space.s + Sizes.glyphInline : 0);
              // 标题按自然宽度显示（不断词）；一行放不下标题 + 当前值时，当前值换到标题下面一行
              final oneLine =
                  titleWidth + valueWidth + fixed <= constraints.maxWidth;
              final titleRow = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(title, style: context.text.body)),
                  if (attention) ...[
                    const SizedBox(width: Space.s),
                    const StatusDot(StatusKind.attention),
                  ],
                ],
              );
              final chevron = showChevron
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: Space.s),
                      child: GeoIcon(
                        GeoGlyph.forward,
                        size: Sizes.glyphInline,
                        color: colors.muted,
                        strokeWidth: Stroke.regular,
                      ),
                    )
                  : const SizedBox.shrink();
              if (oneLine) {
                return Row(
                  children: [
                    titleRow,
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: value == null
                          ? const SizedBox.shrink()
                          : Text(
                              value!,
                              textAlign: TextAlign.end,
                              style: context.text.small,
                            ),
                    ),
                    chevron,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleRow,
                        if (value != null)
                          Text(value!, style: context.text.small),
                      ],
                    ),
                  ),
                  chevron,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

double _measure(String text, TextStyle style, TextScaler scaler) {
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
