import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/data_providers.dart';
import '../../core/utils/current_day.dart';
import '../../core/utils/date_utils.dart';

final todayLogsProvider = StreamProvider<List<LogEntry>>((ref) {
  final today = ref.watch(currentDayProvider);
  return ref.watch(logRepositoryProvider).watchBetween(today, nextDay(today));
});
