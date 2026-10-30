import 'package:drift/drift.dart';

import 'enums.dart';
import 'wall_time_converter.dart';

@TableIndex(name: 'idx_tasks_due', columns: {#dueAt})
@TableIndex(name: 'idx_tasks_reminder', columns: {#reminderAt})
class Tasks extends Table {
  /// AUTOINCREMENT：删除的 id 不会复用，通知 id 直接取自它
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  TextColumn get note => text().nullable()();

  /// 当地钟点。dueHasTime = false 时只看日期部分
  DateTimeColumn get dueAt => dateTime().nullable().map(const WallTimeConverter())();

  BoolColumn get dueHasTime => boolean().withDefault(const Constant(false))();

  IntColumn get priority =>
      intEnum<Priority>().withDefault(Constant(Priority.medium.index))();

  /// 当地钟点。不重复时是触发时刻；每天取时分；每周取星期几 + 时分
  DateTimeColumn get reminderAt =>
      dateTime().nullable().map(const WallTimeConverter())();

  IntColumn get reminderRepeat =>
      intEnum<RepeatRule>().withDefault(Constant(RepeatRule.none.index))();

  /// 完成的时刻。重复任务只在它落在今天时算"今天已完成"
  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

@TableIndex(name: 'idx_log_created', columns: {#createdAt})
class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get content => text().withLength(min: 1, max: 500)();

  DateTimeColumn get createdAt => dateTime()();
}

/// 键值设置表。加设置项不需要改表或迁移：类型、默认值、校验在 Dart 端（settings/setting_keys.dart）。
/// 值等于默认值时删除该行。
class SettingEntries extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
