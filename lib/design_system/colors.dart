import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 限定调色板：中性底色 + 1 个主色（可在设置里换 [AccentPalette]）+ 固定的警示红。浅色、深色各一套。
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
    required this.danger,
    required this.onDanger,
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

  /// 警示红：删除等危险操作。固定不随主题色变，与朱红在色相和明度上都拉开；必须配文字，不能只靠颜色
  final Color danger;

  /// 警示红上的文字
  final Color onDanger;

  static const light = FacetColors(
    background: Color(0xFFF4F2EE),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1D1D1F),
    muted: Color(0xFF6F6D69),
    line: Color(0xFFD8D5CF),
    accent: Color(0xFFBF3F1C),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFA0003F),
    onDanger: Color(0xFFFFFFFF),
  );

  static const dark = FacetColors(
    background: Color(0xFF121213),
    surface: Color(0xFF1B1B1D),
    ink: Color(0xFFECEAE6),
    muted: Color(0xFF8E8C88),
    line: Color(0xFF2F2F33),
    accent: Color(0xFFFF7A52),
    onAccent: Color(0xFF121213),
    danger: Color(0xFFFFA3C2),
    onDanger: Color(0xFF121213),
  );

  /// 占位用的透明色（例如未选中时的边框），不属于调色板
  static const transparent = Color(0x00000000);

  static FacetColors lerp(FacetColors a, FacetColors b, double t) {
    return FacetColors(
      background: Color.lerp(a.background, b.background, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      muted: Color.lerp(a.muted, b.muted, t)!,
      line: Color.lerp(a.line, b.line, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
      danger: Color.lerp(a.danger, b.danger, t)!,
      onDanger: Color.lerp(a.onDanger, b.onDanger, t)!,
    );
  }

  /// 按明暗和主题色得到整套颜色：只换主色，中性色和警示红不变
  static FacetColors resolve(Brightness brightness, AccentPalette palette) {
    final base = brightness == Brightness.light ? light : dark;
    return FacetColors(
      background: base.background,
      surface: base.surface,
      ink: base.ink,
      muted: base.muted,
      line: base.line,
      accent: palette.forBrightness(brightness),
      onAccent: base.onAccent,
      danger: base.danger,
      onDanger: base.onDanger,
    );
  }
}

/// 6 个预设主题色。每个都有浅色、深色两版；对底色、浮层表面、主色上的文字三项对比度都 ≥ 4.5
/// （test/design_system/colors_test.dart 按 WCAG 公式校验）。
enum AccentPalette {
  vermilion(Color(0xFFBF3F1C), Color(0xFFFF7A52)),
  amber(Color(0xFF8F5A00), Color(0xFFE9A23B)),
  pine(Color(0xFF2E7044), Color(0xFF5FC383)),
  teal(Color(0xFF1C6E80), Color(0xFF4FC0D6)),
  indigo(Color(0xFF3F51B5), Color(0xFF8C9EFF)),
  // 紫：偏蓝紫（色相约 275°），与警示红（约 340°）、靛蓝（约 231°）都拉开
  plum(Color(0xFF7A3E9E), Color(0xFFC79AEE));

  const AccentPalette(this.light, this.dark);

  final Color light;
  final Color dark;

  Color forBrightness(Brightness b) => b == Brightness.dark ? dark : light;
}
