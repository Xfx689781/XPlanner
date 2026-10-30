import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/current_day.dart';
import '../../core/utils/format.dart';
import '../../design_system/design_system.dart';
import '../../l10n/locale_providers.dart';
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
    final l10n = context.l10n;

    return PageFrame(
      title: l10n.todayTitle,
      subtitle: AppDateFormat.of(context).date(today, today: today),
      trailing: Padding(
        padding: const EdgeInsets.only(right: Space.s),
        child: GeoIconButton(
          glyph: GeoGlyph.sliders,
          semanticLabel: l10n.todaySettings,
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
              done: progress?.done ?? 0,
              total: progress?.total ?? 0,
              // 向下取整到 1%：没全部完成时不会显示 100%
              formatPercent: (r) => NumberFormat.percentPattern(
                AppDateFormat.of(context).intlLocale,
              ).format((r * 100).floor() / 100),
              subtitle: progress == null
                  ? ''
                  : l10n.todayProgressDone(progress.done, progress.total),
              // 空状态由圆心的文字自己读出，不再重复
              semanticLabel: progress == null || progress.total == 0
                  ? null
                  : l10n.todayProgressSemantics(progress.done, progress.total),
              // 数据还没加载时只画空心圆，避免冷启动闪一下"今天没有任务"
              emptyChild: progress == null
                  ? null
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.todayNoTasks, style: context.text.small),
                        GeoButton(
                          label: l10n.todayAddTask,
                          style: GeoButtonStyle.text,
                          onPressed: () =>
                              showTaskEditor(context, dueToday: true),
                        ),
                      ],
                    ),
            ),
          ),
          if (summary != null && summary.overdue.isNotEmpty) ...[
            SectionHeader(
              l10n.todayOverdueHeader,
              glyph: GeoGlyph.square,
              glyphFilled: false,
              accent: true,
            ),
            for (final t in summary.overdue)
              TaskTile(key: ValueKey('o${t.id}'), task: t),
          ],
          SectionHeader(
            l10n.todayTasksHeader,
            trailing: GeoIconButton(
              glyph: GeoGlyph.plus,
              semanticLabel: l10n.todayNewTask,
              color: context.colors.accent,
              onPressed: () => showTaskEditor(context, dueToday: true),
            ),
          ),
          if (summary != null)
            for (final t in summary.tasks)
              TaskTile(key: ValueKey('t${t.id}'), task: t),
          SectionHeader(l10n.todayLogHeader),
          const LogInputBar(),
          for (final e in logs) LogRow(key: ValueKey(e.id), entry: e),
        ],
      ),
    );
  }
}
