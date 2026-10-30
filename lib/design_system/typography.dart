import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 字号只有三档。
abstract final class FontSizes {
  /// 辅助文字、时间、标签
  static const double small = 13;

  /// 正文
  static const double body = 16;

  /// 页标题
  static const double title = 28;

  /// 唯一例外：今天页大圆中心的百分比数字（整页最醒目的文字），不要用于其他地方
  static const double display = 40;
}

/// 按调色板生成的文字样式。
@immutable
class FacetText {
  const FacetText({
    required this.title,
    required this.body,
    required this.small,
  });

  factory FacetText.from({required Color ink, required Color muted}) {
    return FacetText(
      title: TextStyle(
        fontSize: FontSizes.title,
        height: 1.2,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
        color: ink,
      ),
      body: TextStyle(
        fontSize: FontSizes.body,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      small: TextStyle(
        fontSize: FontSizes.small,
        height: 1.3,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        color: muted,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  final TextStyle title;
  final TextStyle body;
  final TextStyle small;
}
