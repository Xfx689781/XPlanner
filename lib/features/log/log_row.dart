import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/data_providers.dart';
import '../../core/utils/format.dart';
import '../../design_system/design_system.dart';

/// 一条日志：左侧时间，右侧内容。长按删除。
class LogRow extends ConsumerWidget {
  const LogRow({super.key, required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = formatTime(entry.createdAt.toLocal());
    return Semantics(
      label: '$time ${entry.content}',
      hint: '长按删除',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () async {
          final ok = await showGeoConfirm(
            context,
            message: '删除这条记录？',
            confirmLabel: '删除',
            destructive: true,
          );
          if (ok) await ref.read(logRepositoryProvider).delete(entry.id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(time, style: context.text.small),
              const SizedBox(width: Space.m),
              Expanded(child: Text(entry.content, style: context.text.body)),
            ],
          ),
        ),
      ),
    );
  }
}
