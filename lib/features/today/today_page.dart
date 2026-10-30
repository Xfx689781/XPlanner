import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/current_day.dart';
import '../../core/utils/format.dart';
import '../../design_system/design_system.dart';
import '../log/log_input_bar.dart';
import '../log/log_providers.dart';
import '../log/log_row.dart';
import '../plan/task_editor_sheet.dart';
import '../plan/task_tile.dart';
import '../settings/settings_page.dart';
import 'today_providers.dart';

/// 首页：大圆（今天任务的完成比例）→ 逾期 → 今天的任务 → 今天的日志。
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDayProvider);
    final summary = ref.watch(todaySummaryProvider).value;
    final logs = ref.watch(todayLogsProvider).value ?? const [];
    final progress = summary?.progress;

    return PageFrame(
      title: '今天',
      subtitle: formatDate(today, today: today),
      trailing: Padding(
        padding: const EdgeInsets.only(right: Space.s),
        child: GeoIconButton(
          glyph: GeoGlyph.sliders,
          semanticLabel: '设置',
          color: context.colors.muted,
          onPressed: () => SettingsPage.open(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.xl),
        children: [
          const SizedBox(height: Space.m),
          Center(
            child: DayCircle(
              progress: progress?.ratio ?? 0,
              semanticLabel: progress == null
                  ? null
                  : '今天完成 ${progress.done} / ${progress.total}',
            ),
          ),
          const SizedBox(height: Space.m),
          Center(
            child: Text(
              progress == null || progress.total == 0
                  ? '今天没有安排'
                  : '${progress.done} / ${progress.total}',
              style: context.text.small,
            ),
          ),
          if (summary != null && summary.overdue.isNotEmpty) ...[
            const SectionHeader('逾期', glyph: GeoGlyph.triangle, accent: true),
            for (final t in summary.overdue) TaskTile(key: ValueKey('o${t.id}'), task: t),
          ],
          SectionHeader(
            '任务',
            trailing: GeoIconButton(
              glyph: GeoGlyph.plus,
              semanticLabel: '新建任务',
              color: context.colors.accent,
              onPressed: () => showTaskEditor(context, dueToday: true),
            ),
          ),
          if (summary != null && summary.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
              child: Text('今天还没有任务，点 + 添加', style: context.text.small),
            ),
          if (summary != null)
            for (final t in summary.tasks) TaskTile(key: ValueKey('t${t.id}'), task: t),
          const SectionHeader('日志'),
          const LogInputBar(),
          for (final e in logs) LogRow(key: ValueKey(e.id), entry: e),
        ],
      ),
    );
  }
}
