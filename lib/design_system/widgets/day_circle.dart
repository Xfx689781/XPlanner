import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';

/// 一天 = 圆。主色从底部升起，水位 = 完成比例。
class DayCircle extends StatelessWidget {
  const DayCircle({
    super.key,
    required this.progress,
    this.diameter = Sizes.dayCircle,
    this.child,
    this.semanticLabel,
  });

  /// 0..1
  final double progress;
  final double diameter;

  /// 圆心处的内容（例如 3/5）
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semanticLabel,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0.0, 1.0)),
        duration: Motion.standard,
        curve: Motion.curve,
        builder: (context, t, child) => CustomPaint(
          size: Size.square(diameter),
          painter: DayCirclePainter(
            progress: t,
            ring: colors.ink,
            fillColor: colors.accent,
          ),
          child: SizedBox.square(
            dimension: diameter,
            child: Center(child: child),
          ),
        ),
        child: child,
      ),
    );
  }
}

class DayCirclePainter extends CustomPainter {
  DayCirclePainter({
    required this.progress,
    required this.ring,
    required this.fillColor,
  });

  final double progress;
  final Color ring;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    if (progress > 0) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      final top = size.height * (1 - progress);
      canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, size.height),
        Paint()..color = fillColor,
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius - Stroke.thin / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Stroke.thin
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(DayCirclePainter old) =>
      old.progress != progress ||
      old.ring != ring ||
      old.fillColor != fillColor;
}
