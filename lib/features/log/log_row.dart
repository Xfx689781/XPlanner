import 'package:flutter/semantics.dart';
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
    Future<void> confirmDelete() async {
      final repo = ref.read(logRepositoryProvider);
      final ok = await showGeoConfirm(
        context,
        message: '删除这条记录？',
        confirmLabel: '删除',
        destructive: true,
      );
      if (ok) await repo.delete(entry.id);
    }

    return Semantics(
      label: '$time ${entry.content}',
      customSemanticsActions: {const CustomSemanticsAction(label: '删除'): confirmDelete},
      onLongPress: confirmDelete,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: confirmDelete,
        // 桌面上右键也能删除
        onSecondaryTap: confirmDelete,
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
