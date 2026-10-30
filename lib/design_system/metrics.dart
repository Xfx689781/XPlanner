/// 间距档位
abstract final class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 40;
}

/// 线宽只有三档：1 / 2 / 4
abstract final class Stroke {
  static const double thin = 1;
  static const double regular = 2;
  static const double bold = 4;
}

/// 圆角只在方块上使用，统一一档
abstract final class Radii {
  static const double square = 2;
}

/// 几何元素和布局的固定尺寸
abstract final class Sizes {
  /// 列表里的任务方块边长
  static const double taskSquare = 22;

  /// 图标（几何字形）边长
  static const double icon = 22;

  /// 文字行内的小字形（分组标题、状态点、优先级示意）
  static const double glyphInline = 14;

  /// 空状态的大字形
  static const double emptyGlyph = 64;

  /// 确认框最大宽度
  static const double dialogMaxWidth = 360;

  /// 设置中心两栏模式下左侧分组列表宽度
  static const double settingsListWidth = 280;

  /// 设置中心两栏模式下的总宽度上限
  static const double settingsMaxWidth = 960;

  /// 首页大圆直径（窄屏）
  static const double dayCircle = 184;

  /// 提醒短横线长度
  static const double reminderDash = 12;

  /// 底部导航高度（不含系统安全区）
  static const double navBar = 64;

  /// 宽屏左侧导航宽度
  static const double navRail = 88;

  /// 选中标记短线长度
  static const double navIndicator = 16;

  /// 最小点击区域
  static const double tapTarget = 44;

  /// 宽于此值时用左侧导航
  static const double wideBreakpoint = 720;

  /// 宽屏下内容区的最大宽度
  static const double contentMaxWidth = 640;
}
