import '../core/data/settings/settings_enums.dart';
import '../design_system/colors.dart';

/// 设置里的主题色 → design_system 的调色板。穷举 switch：新增颜色时漏改任何一边都编译不过。
AccentPalette paletteOf(AccentColor a) => switch (a) {
  AccentColor.vermilion => AccentPalette.vermilion,
  AccentColor.amber => AccentPalette.amber,
  AccentColor.pine => AccentPalette.pine,
  AccentColor.teal => AccentPalette.teal,
  AccentColor.indigo => AccentPalette.indigo,
  AccentColor.plum => AccentPalette.plum,
};
