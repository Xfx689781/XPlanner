import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../metrics.dart';

/// 只用圆、方、三角、线组成的图标字形。
enum GeoGlyph {
  /// 今天：圆
  circle,

  /// 任务：方块
  square,

  /// 日志：三条递减的横线
  lines,

  /// 新建
  plus,

  /// 关闭
  close,

  /// 设置：三条带圆点的滑杆
  sliders,

  /// 逾期：三角
  triangle,

  /// 返回：左折线
  back,
}

class GeoIcon extends StatelessWidget {
  const GeoIcon(
    this.glyph, {
    super.key,
    required this.color,
    this.size = Sizes.icon,
    this.filled = false,
    this.strokeWidth = Stroke.regular,
  });

  final GeoGlyph glyph;
  final Color color;
  final double size;

  /// 闭合形状（圆、方、三角）是否实心
  final bool filled;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _GeoIconPainter(glyph, color, filled, strokeWidth),
      ),
    );
  }
}

class _GeoIconPainter extends CustomPainter {
  _GeoIconPainter(this.glyph, this.color, this.filled, this.strokeWidth);

  final GeoGlyph glyph;
  final Color color;
  final bool filled;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;
    final fill = Paint()..color = color;
    final shapePaint = filled ? fill : stroke;
    final inset = strokeWidth / 2 + s * 0.12;
    final box = Rect.fromLTWH(inset, inset, s - inset * 2, s - inset * 2);
    final c = box.center;

    switch (glyph) {
      case GeoGlyph.circle:
        canvas.drawCircle(c, box.width / 2, shapePaint);
      case GeoGlyph.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(Radii.square)),
          shapePaint,
        );
      case GeoGlyph.lines:
        final widths = [1.0, 0.72, 0.44];
        for (var i = 0; i < 3; i++) {
          final y = box.top + box.height * (0.2 + 0.3 * i);
          canvas.drawLine(
            Offset(box.left, y),
            Offset(box.left + box.width * widths[i], y),
            stroke,
          );
        }
      case GeoGlyph.plus:
        canvas.drawLine(Offset(c.dx, box.top), Offset(c.dx, box.bottom), stroke);
        canvas.drawLine(Offset(box.left, c.dy), Offset(box.right, c.dy), stroke);
      case GeoGlyph.close:
        final d = box.deflate(box.width * 0.08);
        canvas.drawLine(d.topLeft, d.bottomRight, stroke);
        canvas.drawLine(d.topRight, d.bottomLeft, stroke);
      case GeoGlyph.sliders:
        final knobs = [0.7, 0.3, 0.55];
        final r = box.width * 0.11;
        for (var i = 0; i < 3; i++) {
          final y = box.top + box.height * (0.15 + 0.35 * i);
          canvas.drawLine(Offset(box.left, y), Offset(box.right, y), stroke..strokeWidth = Stroke.thin);
          canvas.drawCircle(Offset(box.left + box.width * knobs[i], y), r, fill);
        }
        stroke.strokeWidth = strokeWidth;
      case GeoGlyph.triangle:
        final h = box.width * math.sqrt(3) / 2;
        final top = c.dy - h / 2;
        final path = Path()
          ..moveTo(c.dx, top)
          ..lineTo(box.right, top + h)
          ..lineTo(box.left, top + h)
          ..close();
        canvas.drawPath(path, shapePaint..strokeJoin = StrokeJoin.miter);
      case GeoGlyph.back:
        final path = Path()
          ..moveTo(c.dx + box.width * 0.2, box.top)
          ..lineTo(c.dx - box.width * 0.25, c.dy)
          ..lineTo(c.dx + box.width * 0.2, box.bottom);
        canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_GeoIconPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.filled != filled ||
      old.strokeWidth != strokeWidth;
}
