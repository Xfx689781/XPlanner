import 'dart:math' as math;

import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x 相对亮度
double luminance(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double hue(Color c) => HSLColor.fromColor(c).hue;

void main() {
  for (final palette in AccentPalette.values) {
    for (final b in Brightness.values) {
      test('${palette.name} ${b.name}：主色对底色、浮层表面、主色上的文字对比度都 ≥ 4.5', () {
        final c = FacetColors.resolve(b, palette);
        expect(contrast(c.accent, c.background), greaterThanOrEqualTo(4.5));
        expect(contrast(c.accent, c.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      });
    }
  }

  for (final b in Brightness.values) {
    test('警示红 ${b.name}：对底色和表面、警示红上的文字对比度 ≥ 4.5', () {
      final c = FacetColors.resolve(b, AccentPalette.vermilion);
      expect(contrast(c.danger, c.background), greaterThanOrEqualTo(4.5));
      expect(contrast(c.danger, c.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(c.onDanger, c.danger), greaterThanOrEqualTo(4.5));
    });

    test('警示红 ${b.name}：与每个主题色都明显区分（色相差 ≥ 30°，接近时还要求明度拉开）', () {
      for (final palette in AccentPalette.values) {
        final c = FacetColors.resolve(b, palette);
        var dh = (hue(c.danger) - hue(c.accent)).abs();
        dh = math.min(dh, 360 - dh);
        expect(dh, greaterThanOrEqualTo(30), reason: palette.name);
        // 色相只差 30–45° 的（朱红）还要在明度上拉开
        if (dh < 45) expect(contrast(c.danger, c.accent), greaterThanOrEqualTo(1.3), reason: palette.name);
      }
    });
  }

  test('换主题色只换主色，中性色和警示红不变', () {
    for (final b in Brightness.values) {
      final a = FacetColors.resolve(b, AccentPalette.vermilion);
      final z = FacetColors.resolve(b, AccentPalette.plum);
      expect(z.accent, isNot(a.accent));
      expect((z.background, z.surface, z.ink, z.muted, z.line), (a.background, a.surface, a.ink, a.muted, a.line));
      expect((z.danger, z.onDanger), (a.danger, a.onDanger));
    }
  });

  test('默认主题色就是原来的朱红', () {
    expect(FacetColors.resolve(Brightness.light, AccentPalette.vermilion).accent, FacetColors.light.accent);
    expect(FacetColors.resolve(Brightness.dark, AccentPalette.vermilion).accent, FacetColors.dark.accent);
  });
}
