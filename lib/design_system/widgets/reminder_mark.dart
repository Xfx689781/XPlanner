import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../tokens.dart';

/// 提醒 = 一条短横线 + 时间。
class ReminderMark extends StatelessWidget {
  const ReminderMark({
    super.key,
    required this.label,
    required this.semanticLabel,
    this.active = true,
  });

  /// 例如「09:00」「09:00 · 每天」
  final String label;

  /// 读屏文字（由调用方按语言提供，如"提醒 09:00"）
  final String semanticLabel;

  /// false 时（已完成 / 已过期）整体变灰
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.accent : colors.muted;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Sizes.reminderDash,
            height: Stroke.regular,
            color: color,
          ),
          const SizedBox(width: Space.s),
          Flexible(
            child: Text(
              label,
              style: context.text.small.copyWith(
                color: active ? colors.ink : colors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
