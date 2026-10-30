import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'enums.dart';
import 'tables.dart';
import 'wall_time_converter.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, LogEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'facet'));

  /// 发布后任何表结构改动都要写迁移并 +1
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
  );
}
