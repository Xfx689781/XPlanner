import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/data_providers.dart';
import '../../core/data/task_rules.dart';
import '../../core/utils/current_day.dart';

/// 今天的任务、逾期任务和完成比例，都从全部任务派生。
class TodaySummary {
  const TodaySummary({required this.tasks, required this.overdue, required this.progress});

  final List<Task> tasks;
  final List<Task> overdue;

  /// 只统计今天的任务，逾期不计入
  final DayProgress progress;

  static TodaySummary from(List<Task> all, DateTime today) {
    return TodaySummary(
      tasks: [for (final t in all) if (t.isForDay(today)) t],
      overdue: [for (final t in all) if (t.isOverdue(today)) t],
      progress: DayProgress.of(all, today),
    );
  }
}

final todaySummaryProvider = Provider<AsyncValue<TodaySummary>>((ref) {
  final today = ref.watch(currentDayProvider);
  return ref.watch(allTasksProvider).whenData((all) => TodaySummary.from(all, today));
});
