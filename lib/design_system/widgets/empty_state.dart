import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../tokens.dart';
import 'geo_icon.dart';

/// 空状态：一个大的空心几何形 + 一句话。
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.glyph, required this.message});

  final GeoGlyph glyph;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GeoIcon(glyph, color: colors.line, size: Sizes.emptyGlyph, strokeWidth: Stroke.thin),
          const SizedBox(height: Space.m),
          Text(message, style: context.text.small),
        ],
      ),
    );
  }
}
