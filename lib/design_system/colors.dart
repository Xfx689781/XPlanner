import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 限定调色板：中性底色 + 1 个主色。浅色、深色各一套。
@immutable
class FacetColors {
  const FacetColors({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
  });

  /// 页面底色
  final Color background;

  /// 弹层、输入区等浮起表面
  final Color surface;

  /// 主要文字、未完成形状的描边
  final Color ink;

  /// 次要文字、时间
  final Color muted;

  /// 分隔线、空轨道
  final Color line;

  /// 唯一主色：填充、进度、选中
  final Color accent;

  /// 主色上的文字
  final Color onAccent;

  static const light = FacetColors(
    background: Color(0xFFF4F2EE),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1D1D1F),
    muted: Color(0xFF8C8A86),
    line: Color(0xFFD8D5CF),
    accent: Color(0xFFE4572E),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = FacetColors(
    background: Color(0xFF121213),
    surface: Color(0xFF1B1B1D),
    ink: Color(0xFFECEAE6),
    muted: Color(0xFF8E8C88),
    line: Color(0xFF2F2F33),
    accent: Color(0xFFFF7A52),
    onAccent: Color(0xFF121213),
  );

  static FacetColors lerp(FacetColors a, FacetColors b, double t) {
    return FacetColors(
      background: Color.lerp(a.background, b.background, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      muted: Color.lerp(a.muted, b.muted, t)!,
      line: Color.lerp(a.line, b.line, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
    );
  }
}
