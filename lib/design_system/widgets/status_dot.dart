import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../tokens.dart';
import 'geo_icon.dart';

enum StatusKind { ok, attention, unknown }

/// 行内状态小圆（固定 glyphInline 大小，只出现在文字行内，与"一天"的大圆靠尺寸和位置区分）：
/// 实心 = 正常，主色空心 = 需要处理，灰色空心 = 无法检测。
class StatusDot extends StatelessWidget {
  const StatusDot(this.kind, {super.key});

  final StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GeoIcon(
      GeoGlyph.circle,
      size: Sizes.glyphInline,
      color: switch (kind) {
        StatusKind.ok => colors.ink,
        StatusKind.attention => colors.accent,
        StatusKind.unknown => colors.muted,
      },
      filled: kind == StatusKind.ok,
      strokeWidth: Stroke.regular,
    );
  }
}
