// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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
}
