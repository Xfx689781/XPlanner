import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../motion.dart';
import '../tokens.dart';
import '../typography.dart';
import 'geo_icon.dart';

/// 一天 = 圆。
///
/// - 内圆：主色从底部升起，水位 = 完成比例；圆心是大号百分比 + 一行"2 / 3 已完成"
/// - 外圈：分段细环，每个任务一段，完成的段主色加粗；任务超过 [maxSegments] 个时改为连续进度环
/// - 文字跨过水位线时分两层绘制：水位以下用底色、以上用前景色，任何进度下都看得清
/// - 没有任务：细线空心圆，圆心放 [emptyChild]；全部完成：圆心是对勾
///
/// 文字由调用方按语言提供（design_system 不依赖 l10n）。
class DayCircle extends StatelessWidget {
  const DayCircle({
    super.key,
    required this.done,
    required this.total,
    required this.formatPercent,
    required this.subtitle,
    this.emptyChild,
    this.diameter = Sizes.dayCircle,
    this.semanticLabel,
  });

  /// 分段环的上限：超过后改为连续进度环
  static const maxSegments = 12;

  final int done;
  final int total;

  /// 0..1 → "67%"（动画过程中会被反复调用，数字随之滚动）
  final String Function(double ratio) formatPercent;

  /// 圆心第二行，例如"2 / 3 已完成"
  final String subtitle;

  /// 没有任务时圆心显示的内容（例如"今天没有任务" + 添加入口）
  final Widget? emptyChild;
  final double diameter;
  final String? semanticLabel;

  double get progress => total == 0 ? 0 : (done / total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final geometry = DayCircleGeometry(diameter);

    if (total == 0) {
      return Semantics(
        label: semanticLabel,
        child: SizedBox.square(
          dimension: diameter,
          child: CustomPaint(
            painter: DayCirclePainter(
              progress: 0,
              litSegments: 0,
              total: 0,
              geometry: geometry,
              ring: colors.ink,
              track: colors.line,
              fillColor: colors.accent,
            ),
            child: Center(child: emptyChild),
          ),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: TweenAnimationBuilder<_DayValue>(
        tween: _DayValueTween(end: _DayValue(progress, done.toDouble())),
        duration: Motion.standard,
        curve: Motion.curve,
        builder: (context, v, _) {
          final allDone = done == total && v.ratio >= 1 - 1e-6;
          // 文字限制在内圆的内接正方形里，太长（长语言 / 大字号）时等比缩小，不会溢出圆外
          Widget content(Color color) => SizedBox.square(
            dimension: geometry.innerRadius * math.sqrt2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: allDone
                  ? _DoneContent(color: color, subtitle: subtitle, size: geometry.innerRadius)
                  : _ProgressContent(color: color, percent: formatPercent(v.ratio), subtitle: subtitle),
            ),
          );

          return SizedBox.square(
            dimension: diameter,
            child: CustomPaint(
              painter: DayCirclePainter(
                progress: v.ratio,
                litSegments: v.done,
                total: total,
                geometry: geometry,
                ring: colors.ink,
                track: colors.line,
                fillColor: colors.accent,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 水位以上：前景色
                  Center(child: content(colors.ink)),
                  // 水位以下：底色，按水位裁切
                  ClipPath(
                    clipper: _FillClipper(geometry, v.ratio),
                    child: Center(child: content(colors.background)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 外环与内圆的尺寸关系：环在最外侧，环与内圆之间留 [Space.s]。
class DayCircleGeometry {
  DayCircleGeometry(this.diameter);

  final double diameter;

  double get ringWidth => Stroke.bold;
  double get ringRadius => diameter / 2 - ringWidth / 2;
  double get innerRadius => diameter / 2 - ringWidth - Space.s;
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.color, required this.percent, required this.subtitle});

  final Color color;
  final String percent;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          percent,
          maxLines: 1,
          style: context.text.title.copyWith(
            fontSize: FontSizes.display,
            fontWeight: FontWeight.w300,
            height: 1.1,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(subtitle, maxLines: 1, style: context.text.small.copyWith(color: color)),
      ],
    );
  }
}

class _DoneContent extends StatelessWidget {
  const _DoneContent({required this.color, required this.subtitle, required this.size});

  final Color color;
  final String subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GeoIcon(GeoGlyph.check, color: color, size: size * 0.7, strokeWidth: Stroke.bold),
        Text(subtitle, maxLines: 1, style: context.text.small.copyWith(color: color)),
      ],
    );
  }
}

/// 裁出内圆里水位以下的部分
class _FillClipper extends CustomClipper<Path> {
  _FillClipper(this.geometry, this.ratio);

  final DayCircleGeometry geometry;
  final double ratio;

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final r = geometry.innerRadius;
    final top = center.dy + r - 2 * r * ratio;
    final circle = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    final below = Path()..addRect(Rect.fromLTRB(0, top, size.width, size.height));
    return Path.combine(PathOperation.intersect, circle, below);
  }

  @override
  bool shouldReclip(_FillClipper old) => old.ratio != ratio || old.geometry.diameter != geometry.diameter;
}

class DayCirclePainter extends CustomPainter {
  DayCirclePainter({
    required this.progress,
    required this.litSegments,
    required this.total,
    required this.geometry,
    required this.ring,
    required this.track,
    required this.fillColor,
  });

  /// 内圆水位 0..1
  final double progress;

  /// 已点亮的段数（动画中可以是小数：最后一段按比例点亮）
  final double litSegments;
  final int total;
  final DayCircleGeometry geometry;
  final Color ring;
  final Color track;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final inner = geometry.innerRadius;

    // 内圆：水位填充
    if (progress > 0) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: inner)));
      final top = center.dy + inner - 2 * inner * progress;
      canvas.drawRect(Rect.fromLTRB(0, top, size.width, size.height), Paint()..color = fillColor);
      canvas.restore();
    }

    if (total == 0) {
      // 没有任务：只有一个细线空心圆
      canvas.drawCircle(
        center,
        size.shortestSide / 2 - Stroke.thin / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = Stroke.thin
          ..color = ring,
      );
      return;
    }

    // 内圆轮廓
    canvas.drawCircle(
      center,
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Stroke.thin
        ..color = track,
    );

    final rect = Rect.fromCircle(center: center, radius: geometry.ringRadius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Stroke.thin
      ..color = track;
    final litPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.ringWidth
      ..strokeCap = StrokeCap.butt
      ..color = fillColor;
    const start = -math.pi / 2;

    if (total > DayCircle.maxSegments) {
      // 连续进度环
      canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
      final sweep = math.pi * 2 * (litSegments / total).clamp(0.0, 1.0);
      if (sweep > 0) canvas.drawArc(rect, start, sweep, false, litPaint);
      return;
    }

    // 分段环：段之间留 Space.xs 的缝隙（1 段时是完整的圆）
    final gap = total == 1 ? 0.0 : Space.xs / geometry.ringRadius;
    final segment = math.pi * 2 / total;
    final sweep = segment - gap;
    for (var i = 0; i < total; i++) {
      final from = start + i * segment + gap / 2;
      canvas.drawArc(rect, from, sweep, false, trackPaint);
      final lit = (litSegments - i).clamp(0.0, 1.0);
      if (lit > 0) canvas.drawArc(rect, from, sweep * lit, false, litPaint);
    }
  }

  @override
  bool shouldRepaint(DayCirclePainter old) =>
      old.progress != progress ||
      old.litSegments != litSegments ||
      old.total != total ||
      old.geometry.diameter != geometry.diameter ||
      old.ring != ring ||
      old.track != track ||
      old.fillColor != fillColor;
}

/// 动画中的进度：水位比例 + 已点亮段数，一起插值
@immutable
class _DayValue {
  const _DayValue(this.ratio, this.done);

  final double ratio;
  final double done;
}

class _DayValueTween extends Tween<_DayValue> {
  _DayValueTween({super.end});

  @override
  _DayValue lerp(double t) {
    final b = begin ?? end!;
    return _DayValue(
      b.ratio + (end!.ratio - b.ratio) * t,
      b.done + (end!.done - b.done) * t,
    );
  }
}
