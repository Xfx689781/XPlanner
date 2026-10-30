import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data_providers.dart';
import '../../core/utils/current_day.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/format.dart';
import '../../design_system/design_system.dart';
import 'log_input_bar.dart';
import 'log_row.dart';

class LogPage extends ConsumerWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDayProvider);
    final logs = ref.watch(allLogsProvider);

    return PageFrame(
      title: '日志',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LogInputBar(),
          Expanded(
            child: switch (logs) {
              AsyncData(:final value) when value.isEmpty => const EmptyState(
                glyph: GeoGlyph.lines,
                message: '还没有记录',
              ),
              AsyncData(:final value) => ListView(
                padding: const EdgeInsets.only(bottom: Space.xl),
                children: [
                  for (final (day, items) in groupByDay(value, (e) => e.createdAt)) ...[
                    SectionHeader(formatRelativeDate(day, today)),
                    for (final e in items) LogRow(key: ValueKey(e.id), entry: e),
                  ],
                ],
              ),
              AsyncError() => const EmptyState(glyph: GeoGlyph.close, message: '读取记录失败'),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}
