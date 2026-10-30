import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';

/// 任务方块：空心 = 未完成，实心 = 完成，描边粗细 = 优先级，主色描边的空心 = 逾期。
/// 完成状态切换时，主色自下而上填满（或退回）。
class TaskSquare extends StatelessWidget {
  const TaskSquare({
    super.key,
    required this.done,
    required this.strokeWidth,
    this.size = Sizes.taskSquare,
    this.onTap,
    this.semanticLabel,
    this.overdue = false,
  });

  final bool done;

  /// 逾期：未完成时描边用主色（警示）
  final bool overdue;
  final double strokeWidth;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final square = TweenAnimationBuilder<double>(
      tween: Tween(end: done ? 1 : 0),
      duration: Motion.standard,
      curve: Motion.curve,
      builder: (context, t, _) => CustomPaint(
        size: Size.square(size),
        painter: TaskSquarePainter(
          fill: t,
          strokeWidth: strokeWidth,
          outline: Color.lerp(
            overdue ? colors.accent : colors.ink,
            colors.accent,
            t,
          )!,
          fillColor: colors.accent,
        ),
      ),
    );

    return Semantics(
      checked: done,
      label: semanticLabel,
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size < Sizes.tapTarget ? Sizes.tapTarget : size,
          child: Center(child: square),
        ),
      ),
    );
  }
}

class TaskSquarePainter extends CustomPainter {
  TaskSquarePainter({
    required this.fill,
    required this.strokeWidth,
    required this.outline,
    required this.fillColor,
  });

  /// 0 = 空心，1 = 实心
  final double fill;
  final double strokeWidth;
  final Color outline;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rect = Offset.zero & size;
    final strokeRect = RRect.fromRectAndRadius(
      rect.deflate(half),
      const Radius.circular(Radii.square),
    );

    if (fill > 0) {
      final outer = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(Radii.square),
      );
      canvas.save();
      canvas.clipRRect(outer);
      final top = size.height * (1 - fill);
      canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, size.height),
        Paint()..color = fillColor,
      );
      canvas.restore();
    }

    canvas.drawRRect(
      strokeRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(TaskSquarePainter old) =>
      old.fill != fill ||
      old.strokeWidth != strokeWidth ||
      old.outline != outline ||
      old.fillColor != fillColor;
}
