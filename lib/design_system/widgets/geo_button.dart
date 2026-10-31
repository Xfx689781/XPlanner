import 'package:flutter/widgets.dart';

import '../colors.dart';
import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';
import 'geo_icon.dart';

enum GeoButtonStyle {
  /// 主色实心
  primary,

  /// 1px 描边
  outline,

  /// 只有文字
  text,
}

/// 直角矩形按钮，不用 Material 的水波纹和阴影。
class GeoButton extends StatefulWidget {
  const GeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = GeoButtonStyle.outline,
    this.destructive = false,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final GeoButtonStyle style;

  /// 危险操作（删除等）：文字用固定的警示红，不随主题色变
  final bool destructive;

  /// 大按钮（闹钟页）：更高，便于刚醒时点中
  final bool large;

  @override
  State<GeoButton> createState() => _GeoButtonState();
}

class _GeoButtonState extends State<GeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onPressed != null;
    final (Color bg, Color fg, Color? border) = switch (widget.style) {
      GeoButtonStyle.primary =>
        widget.destructive
            ? (colors.danger, colors.onDanger, null)
            : (colors.accent, colors.onAccent, null),
      GeoButtonStyle.outline => (
        FacetColors.transparent,
        widget.destructive ? colors.danger : colors.ink,
        widget.destructive ? colors.danger : colors.muted,
      ),
      GeoButtonStyle.text => (
        FacetColors.transparent,
        widget.destructive ? colors.danger : colors.ink,
        null,
      ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: Motion.quick,
          opacity: !enabled ? 0.4 : (_pressed ? 0.6 : 1),
          child: Container(
            constraints: BoxConstraints(
              minHeight: widget.large ? Sizes.largeButton : Sizes.tapTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              border: border == null
                  ? null
                  : Border.all(color: border, width: Stroke.thin),
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// 只有一个几何字形的点击区域。
class GeoIconButton extends StatelessWidget {
  const GeoIconButton({
    super.key,
    required this.glyph,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    this.filled = false,
  });

  final GeoGlyph glyph;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      // excludeSemantics 会把手势的语义动作一起去掉，显式补上
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: Sizes.tapTarget,
          child: Center(
            child: GeoIcon(
              glyph,
              color: color ?? context.colors.ink,
              filled: filled,
            ),
          ),
        ),
      ),
    );
  }
}
