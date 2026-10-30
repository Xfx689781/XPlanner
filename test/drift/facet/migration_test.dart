// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v1 → v2 只新增设置表：已有任务和日志必须原样保留（用户手机上可能装过 v1 的调试版）
  test('migration from v1 to v2 does not corrupt data', () async {
    const oldTasksData = [
      v1.TasksData(
        id: 1,
        title: '交房租',
        note: '月底前',
        dueAt: 1793404800,
        dueHasTime: 1,
        priority: 2,
        reminderAt: 1793401200,
        reminderRepeat: 2,
        completedAt: null,
        createdAt: 1790000000,
        updatedAt: 1790000500,
      ),
      v1.TasksData(
        id: 7,
        title: '无日期',
        dueHasTime: 0,
        priority: 0,
        reminderRepeat: 0,
        completedAt: 1790001000,
        createdAt: 1790000000,
        updatedAt: 1790001000,
      ),
    ];
    final expectedNewTasksData = [
      for (final t in oldTasksData)
        v2.TasksData(
          id: t.id,
          title: t.title,
          note: t.note,
          dueAt: t.dueAt,
          dueHasTime: t.dueHasTime,
          priority: t.priority,
          reminderAt: t.reminderAt,
          reminderRepeat: t.reminderRepeat,
          completedAt: t.completedAt,
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
        ),
    ];

    const oldLogEntriesData = [v1.LogEntriesData(id: 3, content: '跑了 5 公里', createdAt: 1790002000)];
    final expectedNewLogEntriesData = [
      for (final l in oldLogEntriesData) v2.LogEntriesData(id: l.id, content: l.content, createdAt: l.createdAt),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.tasks, oldTasksData);
        batch.insertAll(oldDb.logEntries, oldLogEntriesData);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.tasks).get(), expectedNewTasksData);
        expect(await newDb.select(newDb.logEntries).get(), expectedNewLogEntriesData);
        expect(await newDb.select(newDb.settingEntries).get(), isEmpty);
      },
    );
  });

  // v2 → v3：每个任务的提醒转成"锚点 + 提前量"，实际触发时刻都不变
  group('migration from v2 to v3', () {
    /// 当地钟点按 UTC 分量存成秒（与 WallTimeConverter 一致）
    int wall(int y, int m, int d, int h, int min) => DateTime.utc(y, m, d, h, min).millisecondsSinceEpoch ~/ 1000;

    v2.TasksData task(
      int id, {
      int? due,
      bool hasTime = true,
      int? reminder,
      int repeat = 0,
      int? completed,
    }) => v2.TasksData(
      id: id,
      title: 't$id',
      dueAt: due,
      dueHasTime: hasTime ? 1 : 0,
      priority: 1,
      reminderAt: reminder,
      reminderRepeat: repeat,
      completedAt: completed,
      createdAt: 1790000000,
      updatedAt: 1790000000,
    );

    final due14 = wall(2026, 11, 3, 14, 0);
    final oldTasks = [
      task(1, due: due14, reminder: wall(2026, 11, 3, 13, 45)), // 提前 15 分钟（预设）
      task(2, due: due14, reminder: wall(2026, 11, 3, 13, 10)), // 提前 50 分钟（不是预设，自定义也保留）
      task(3, reminder: wall(2026, 11, 5, 9, 0)), // 没有日期，只有提醒
      task(4, due: due14, hasTime: false, reminder: wall(2026, 11, 3, 9, 0)), // 只有日期没时间
      task(5, due: due14, reminder: wall(2026, 11, 3, 15, 0)), // 提醒晚于任务时间
      task(6, due: due14, reminder: wall(2026, 9, 1, 14, 0)), // 提前超过 30 天
      task(7, due: due14, reminder: wall(2026, 11, 2, 14, 0), repeat: 1), // 每天重复 + 提前 1 天：超过周期，不转换
      task(8, due: due14, reminder: wall(2026, 11, 3, 13, 30), repeat: 2), // 每周重复 + 提前 30 分钟
      task(9, due: due14, reminder: due14), // 准时
      task(10, due: due14), // 没有提醒
      task(11, due: due14, reminder: wall(2026, 11, 3, 13, 45), completed: 1790001000), // 已完成也保留
    ];

    test('提醒行、锚点、触发时刻都正确', () async {
      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.tasks, oldTasks);
          batch.insertAll(oldDb.logEntries, [const v2.LogEntriesData(id: 1, content: 'log', createdAt: 1790002000)]);
          batch.insertAll(oldDb.settingEntries, [const v2.SettingEntriesData(key: 'theme', value: 'dark')]);
        },
        validateItems: (newDb) async {
          final tasks = {for (final t in await newDb.select(newDb.tasks).get()) t.id: t};
          final reminders = await newDb.select(newDb.taskReminders).get();
          final offsets = {for (final r in reminders) r.taskId: r.offsetMinutes};

          // 每个原来有提醒的任务都恰好有一行，没提醒的没有
          expect(offsets.keys.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9, 11});
          expect(reminders.every((r) => r.kind == 0), isTrue); // 都是普通通知

          expect(offsets[1], 15);
          expect(offsets[2], 50);
          expect(offsets[8], 30);
          expect(offsets[11], 15);
          for (final id in [3, 4, 5, 6, 7, 9]) {
            expect(offsets[id], 0, reason: 'task $id');
          }

          // 关键不变量：锚点 − 提前量 = 原来的提醒时刻
          for (final old in oldTasks.where((t) => t.reminderAt != null)) {
            final t = tasks[old.id]!;
            expect(t.reminderAt! - offsets[old.id]! * 60, old.reminderAt, reason: 'task ${old.id}');
          }
          // 转换成提前量的，锚点 = 任务时间
          for (final id in [1, 2, 8, 11]) {
            expect(tasks[id]!.reminderAt, due14);
          }
          // 其他字段原样保留
          expect(tasks[7]!.reminderRepeat, 1);
          expect(tasks[11]!.completedAt, 1790001000);
          expect(tasks[10]!.reminderAt == null, isTrue);
          expect(tasks.values.every((t) => t.snoozedUntil == null), isTrue);
          expect(await newDb.select(newDb.logEntries).get(), hasLength(1));
          expect((await newDb.select(newDb.settingEntries).get()).single.value, 'dark');
        },
      );
    });
  });
}
