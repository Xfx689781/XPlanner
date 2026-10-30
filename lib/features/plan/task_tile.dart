import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/task_rules.dart';
import '../../core/utils/current_day.dart';
import '../../design_system/design_system.dart';
import 'task_actions.dart';
import 'task_editor_sheet.dart';
import 'task_labels.dart';

/// 一行任务：方块（点击完成）+ 标题 + 日期 / 提醒。点击文字区域打开编辑。
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final today = ref.watch(currentDayProvider);
    final done = task.isDoneOn(today);
    final overdue = task.isOverdue(today);
    final due = dueLabel(task, today);
    final reminder = task.reminderAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskSquare(
            done: done,
            strokeWidth: strokeForPriority(task.priority),
            semanticLabel: [
              task.title,
              '${priorityLabel(task.priority)}优先级',
              if (overdue) '逾期',
            ].join('，'),
            onTap: () => ref.read(taskActionsProvider).toggleDone(task),
          ),
          Expanded(
            child: Semantics(
              button: true,
              hint: '编辑',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showTaskEditor(context, task: task),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.xs,
                    Space.s + Space.xs,
                    Space.m,
                    Space.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: context.text.body.copyWith(
                          color: done ? colors.muted : colors.ink,
                        ),
                      ),
                      if (due != null || reminder != null) ...[
                        const SizedBox(height: Space.xs),
                        Wrap(
                          spacing: Space.m,
                          runSpacing: Space.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (due != null)
                              Text(
                                due,
                                style: context.text.small.copyWith(
                                  color: overdue ? colors.accent : null,
                                ),
                              ),
                            if (reminder != null)
                              ReminderMark(
                                label: reminderLabel(
                                  reminder,
                                  task.reminderRepeat,
                                ),
                                active: !done && !overdue,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
