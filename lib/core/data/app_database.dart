import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'app_database.steps.dart';
import 'tables.dart';
import 'wall_time_converter.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, LogEntries, SettingEntries, TaskReminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    // shareAcrossIsolates：App 没打开时点通知按钮，后台 isolate 打开的是同一个数据库连接，前台列表会自动刷新
    : super(executor ?? driftDatabase(name: 'facet', native: const DriftNativeOptions(shareAcrossIsolates: true)));

  /// 发布后任何表结构改动都要写迁移并 +1
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2：新增设置表
      from1To2: (m, schema) async => m.createTable(schema.settingEntries),
      // v3：一个任务多个提醒（提前量 + 方式）、稍后提醒
      from2To3: (m, schema) async {
        await m.createTable(schema.taskReminders);
        await m.createIndex(schema.idxTaskRemindersTask);
        await m.addColumn(schema.tasks, schema.tasks.snoozedUntil);
        await migrateRemindersToV3(this);
      },
    ),
    // 删除任务时级联删除它的提醒行
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// 把 v2 的"每个任务一个提醒时间"转成 v3 的"锚点 + 提前量"，每个提醒的实际触发时刻都不变：
  /// - 任务有时间、提醒比任务早 1 分钟～30 天（且小于重复周期）：锚点 = 任务时间，提前量 = 差值
  /// - 其余（无任务时间、提醒晚于任务、超过 30 天）：提前量 0，锚点 = 原提醒时间
  /// 两个时间都按"当地钟点"存储，直接相减就是钟点差，不受夏令时影响。都按普通通知迁移。
  @visibleForTesting
  static Future<void> migrateRemindersToV3(GeneratedDatabase db) async {
    const convertible = '''
      due_has_time = 1 AND due_at IS NOT NULL
      AND due_at - reminder_at >= 60 AND due_at - reminder_at <= 43200 * 60
      AND (due_at - reminder_at) % 60 = 0
      AND CASE reminder_repeat
            WHEN 1 THEN due_at - reminder_at < 1440 * 60
            WHEN 2 THEN due_at - reminder_at < 10080 * 60
            ELSE 1 END''';
    await db.customStatement('''
      INSERT INTO task_reminders (task_id, offset_minutes, kind)
      SELECT id, CASE WHEN $convertible THEN (due_at - reminder_at) / 60 ELSE 0 END, 0
      FROM tasks WHERE reminder_at IS NOT NULL''');
    await db.customStatement('''
      UPDATE tasks SET reminder_at = due_at
      WHERE reminder_at IS NOT NULL AND $convertible''');
  }
}
