import 'package:flutter/animation.dart';

/// 动效克制：所有动画不超过 400ms。
abstract final class Motion {
  /// 形状填充、展开
  static const Duration standard = Duration(milliseconds: 280);

  /// 小的状态切换（选中、颜色）
  static const Duration quick = Duration(milliseconds: 160);

  static const Curve curve = Curves.easeOutCubic;
}
