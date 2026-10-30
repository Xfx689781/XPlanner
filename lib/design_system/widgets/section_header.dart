import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../tokens.dart';
import '../typography.dart';
import 'geo_icon.dart';

/// 分组标题：小号文字 + 向右延伸的细线。
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.glyph, this.accent = false, this.trailing});

  final String label;
  final GeoGlyph? glyph;

  /// 细线右侧的操作
  final Widget? trailing;

  /// 用主色强调（例如逾期）
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = accent ? colors.accent : colors.muted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
      child: Row(
        children: [
          if (glyph != null) ...[
            GeoIcon(glyph!, color: color, size: FontSizes.small, filled: true),
            const SizedBox(width: Space.s),
          ],
          Text(label, style: context.text.small.copyWith(color: color)),
          const SizedBox(width: Space.s),
          Expanded(child: Container(height: Stroke.thin, color: colors.line)),
          ?trailing,
        ],
      ),
    );
  }
}
