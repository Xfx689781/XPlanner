import 'package:facet/app/accent.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// core 层的 AccentColor（存进设置表的名字）与 design_system 的 AccentPalette（色值）按名称一一对应。
/// 以后加颜色只加了一边时，这里先失败，而不是运行时 byName 抛异常。
void main() {
  test('AccentColor 与 AccentPalette 名称集合相同、顺序相同、数量为 6', () {
    final core = [for (final a in AccentColor.values) a.name];
    final design = [for (final p in AccentPalette.values) p.name];
    expect(design, core);
    expect(core.length, 6);
  });

  test('每个 AccentColor 都能按名称找到 AccentPalette，index 也一致', () {
    for (final a in AccentColor.values) {
      final p = AccentPalette.values.byName(a.name);
      expect(p.index, a.index, reason: a.name);
    }
  });

  test('paletteOf 把每个 AccentColor 映射到同名调色板，且是双射', () {
    final mapped = [for (final a in AccentColor.values) paletteOf(a)];
    for (final a in AccentColor.values) {
      expect(paletteOf(a).name, a.name);
    }
    expect(mapped.toSet(), AccentPalette.values.toSet());
  });

  test('默认主题色是第一项朱红', () {
    expect(AccentColor.values.first, AccentColor.vermilion);
    expect(AccentPalette.values.first, AccentPalette.vermilion);
  });

  test('6 色的浅色版两两不同、深色版两两不同；同一色的浅深两版不同', () {
    final lights = {for (final p in AccentPalette.values) p.light};
    final darks = {for (final p in AccentPalette.values) p.dark};
    expect(lights.length, AccentPalette.values.length);
    expect(darks.length, AccentPalette.values.length);
    for (final p in AccentPalette.values) {
      expect(p.light, isNot(p.dark), reason: p.name);
    }
  });

  test('forBrightness 返回对应明暗版本，且与 FacetColors.resolve 一致', () {
    for (final p in AccentPalette.values) {
      expect(p.forBrightness(Brightness.light), p.light);
      expect(p.forBrightness(Brightness.dark), p.dark);
      for (final b in Brightness.values) {
        expect(FacetColors.resolve(b, p).accent, p.forBrightness(b), reason: '${p.name} ${b.name}');
      }
    }
  });

  test('所有色值不透明（避免叠在底色上变色、对比度计算失真）', () {
    for (final p in AccentPalette.values) {
      expect(p.light.a, 1.0, reason: p.name);
      expect(p.dark.a, 1.0, reason: p.name);
    }
  });
}
