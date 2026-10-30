import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data_providers.dart';
import '../../core/utils/current_day.dart';
import '../../design_system/design_system.dart';
import '../../l10n/locale_providers.dart';
import 'task_editor_sheet.dart';
import 'task_groups.dart';
import 'task_tile.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDayProvider);
    final tasks = ref.watch(allTasksProvider);

    return PageFrame(
      title: context.l10n.tasksTitle,
      trailing: Padding(
        padding: const EdgeInsets.only(right: Space.s),
        child: GeoIconButton(
          glyph: GeoGlyph.plus,
          semanticLabel: context.l10n.tasksNewTask,
          color: context.colors.accent,
          onPressed: () => showTaskEditor(context),
        ),
      ),
      child: switch (tasks) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          glyph: GeoGlyph.square,
          message: context.l10n.tasksEmpty,
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: Space.xl),
          children: [
            for (final (group, items) in groupTasks(value, today)) ...[
              SectionHeader(
                taskGroupLabel(context.l10n, group),
                // 逾期 = 主色描边的空心方块，与任务方块一致
                glyph: group == TaskGroup.overdue ? GeoGlyph.square : null,
                glyphFilled: false,
                accent: group == TaskGroup.overdue,
              ),
              for (final t in items) TaskTile(key: ValueKey(t.id), task: t),
            ],
          ],
        ),
        AsyncError() => EmptyState(glyph: GeoGlyph.close, message: context.l10n.tasksLoadError),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
