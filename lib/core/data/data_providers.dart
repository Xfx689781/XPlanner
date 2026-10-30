import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'log_repository.dart';
import 'task_repository.dart';

/// 测试里 override 成内存数据库
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
);

final logRepositoryProvider = Provider<LogRepository>(
  (ref) => LogRepository(ref.watch(databaseProvider)),
);

final allTasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAll(),
);

final allLogsProvider = StreamProvider<List<LogEntry>>(
  (ref) => ref.watch(logRepositoryProvider).watchAll(),
);
