// ignore_for_file: unused_local_variable
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/next_trigger.dart';
import 'package:facet/core/notifications/notification_ids.dart';
import 'package:facet/core/notifications/reminder_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_scheduler.dart';
import '../../helpers/test_app.dart';
import 'generated/schema.dart';
import 'generated/schema_v2.dart' as v2;

/// 与本机在 [at] 这一天的 UTC 偏移相同的固定偏移时区（Etc/GMT+5 表示 UTC-5）
tz.Location deviceLocation(DateTime at) {
  final hours = at.timeZoneOffset.inHours;
  if (hours == 0) return tz.UTC;
  return tz.getLocation('Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}');
}

/// 当地钟点按 UTC 分量存成秒（与 WallTimeConverter 一致）
int wall(int y, int m, int d, int h, int min, [int s = 0]) =>
    DateTime.utc(y, m, d, h, min, s).millisecondsSinceEpoch ~/ 1000;

/// 存储的秒 → 本地钟点 DateTime（与 WallTimeConverter.fromSql 一致）
DateTime? fromWall(int? s) {
  if (s == null) return null;
  final u = DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);
  return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
}

/// 迁移前（v2）的任务，按 v2 的逻辑（提醒时间就是触发时刻）解释
Task v2AsTask(v2.TasksData d) => Task(
  id: d.id,
  title: d.title,
  dueAt: fromWall(d.dueAt),
  dueHasTime: d.dueHasTime == 1,
  priority: Priority.values[d.priority],
  reminderAt: fromWall(d.reminderAt),
  reminderRepeat: RepeatRule.values[d.reminderRepeat],
  completedAt: d.completedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(d.completedAt! * 1000),
  createdAt: DateTime.fromMillisecondsSinceEpoch(d.createdAt * 1000),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(d.updatedAt * 1000),
);

v2.TasksData task(int id, {int? due, bool hasTime = true, int? reminder, int repeat = 0, int? completed}) => v2.TasksData(
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

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(tzdata.initializeTimeZones);

  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  // 任务时间 12/3（周四）14:00
  final due = wall(2026, 12, 3, 14, 0);
  final oldTasks = <v2.TasksData>[
    task(1, due: due, reminder: wall(2026, 11, 3, 14, 0)), // 正好早 30 天 = 43200 分
    task(2, due: due, reminder: wall(2026, 11, 3, 13, 59)), // 30 天 + 1 分
    task(3, due: due, reminder: wall(2026, 12, 3, 13, 59, 1)), // 早 59 秒（不足 1 分钟）
    task(4, due: wall(2026, 11, 10, 14, 0), reminder: wall(2026, 11, 3, 15, 0), repeat: 2), // 每周 + 早 6 天 23 小时
    task(5, due: wall(2026, 11, 10, 14, 0), reminder: wall(2026, 11, 3, 14, 0), repeat: 2), // 每周 + 早正好 7 天
    task(6, due: due, hasTime: false, reminder: wall(2026, 12, 2, 9, 0)), // 有日期无时间（due_has_time = 0）
    task(7, due: wall(2026, 11, 4, 9, 0), reminder: wall(2026, 11, 3, 9, 1), repeat: 1), // 每天 + 早 23:59
    task(8, due: wall(2026, 11, 4, 9, 0), reminder: wall(2026, 11, 3, 20, 0), repeat: 1), // 每天 + 跨零点早 13 小时
    task(9, due: wall(2027, 1, 1, 0, 10), reminder: wall(2026, 12, 31, 23, 55)), // 跨年早 15 分钟
    task(10, due: wall(2028, 3, 1, 9, 0), reminder: wall(2028, 2, 29, 9, 0)), // 闰年 2/29，早 1 天
  ];

  Future<AppDatabase> migrated() async {
    final schema = await verifier.schemaAt(2);
    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await oldDb.batch((b) => b.insertAll(oldDb.tasks, oldTasks));
    await oldDb.close();
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    return db;
  }

  group('v2 → v3 边界', () {
    late AppDatabase db;
    late TaskRepository repo;
    setUp(() async {
      db = await migrated();
      repo = TaskRepository(db);
    });
    tearDown(() => db.close());

    test('提前量与锚点：30 天整转换、30 天+1 分 / 59 秒 / 每周 7 天 / 无时间 不转换', () async {
      Future<(int, DateTime?)> of(int id) async =>
          ((await repo.remindersFor(id)).single.offsetMinutes, (await repo.getById(id))!.reminderAt);

      expect(await of(1), (43200, DateTime(2026, 12, 3, 14)));
      expect(await of(2), (0, DateTime(2026, 11, 3, 13, 59)));
      // 不足 1 分钟：保留原提醒时间（含秒），提前量 0
      expect(await of(3), (0, DateTime(2026, 12, 3, 13, 59, 1)));
      expect(await of(4), (10020, DateTime(2026, 11, 10, 14)));
      expect(await of(5), (0, DateTime(2026, 11, 3, 14)));
      expect(await of(6), (0, DateTime(2026, 12, 2, 9)));
      expect(await of(7), (1439, DateTime(2026, 11, 4, 9)));
      expect(await of(8), (780, DateTime(2026, 11, 4, 9)));
      expect(await of(9), (15, DateTime(2027, 1, 1, 0, 10)));
      expect(await of(10), (1440, DateTime(2028, 3, 1, 9)));
      // 每个都是普通通知
      for (final t in oldTasks) {
        expect((await repo.remindersFor(t.id)).single.kind, ReminderKind.notification, reason: 'task ${t.id}');
      }
    });

    test('迁移后的调度 = 迁移前 v2 逻辑的调度（多个"现在"、纽约时区，含夏令时结束 11/1 之后）', () async {
      final ny = tz.getLocation('America/New_York');
      final nows = [
        tz.TZDateTime(ny, 2026, 10, 31, 12), // 夏令时结束前
        tz.TZDateTime(ny, 2026, 11, 3, 14, 30),
        tz.TZDateTime(ny, 2026, 11, 5, 21),
        tz.TZDateTime(ny, 2026, 12, 3, 13, 58),
        tz.TZDateTime(ny, 2026, 12, 31, 23, 50),
        tz.TZDateTime(ny, 2028, 2, 28, 10),
      ];
      for (final old in oldTasks) {
        final before = v2AsTask(old);
        final after = (await repo.getById(old.id))!;
        final specs = await repo.remindersFor(old.id);
        for (final now in nows) {
          final expected = planReminders(before, now, doneToday: false);
          final actual = [for (final s in specs) ...planSpec(after, s, now, doneToday: false)];
          expect(
            [for (final p in actual) (p.at, p.match)],
            [for (final p in expected) (p.at, p.match)],
            reason: 'task ${old.id} @ $now',
          );
        }
      }
    });

    test('同步服务排出来的首次触发时刻 = v2 逻辑的首次触发时刻', () async {
      final clock = FixedClock(DateTime(2026, 11, 3, 8));
      final loc = deviceLocation(clock.value);
      final scheduler = FakeScheduler();
      final sync = ReminderSyncService(scheduler: scheduler, repository: repo, clock: clock, location: () => loc);
      await sync.resyncAll();
      final now = tz.TZDateTime.from(clock.value, loc);
      for (final old in oldTasks) {
        final expected = planReminders(v2AsTask(old), now, doneToday: false);
        final reqs = scheduler.requestsFor(old.id);
        expect(reqs.map((r) => r.at), expected.map((p) => p.at), reason: 'task ${old.id}');
        if (reqs.isNotEmpty) expect(reqs.first.id, notificationIdForReminder(old.id, 0, 0));
      }
    });

    test('行为差异（记录现状）：每天重复、提醒在前一天晚上（跨零点）且今天已完成 —— '
        'v2 跳过今晚那次；v3 认为今晚那次属于明天的锚点，照常响', () async {
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 11, 5, 10);
      final before = v2AsTask(oldTasks.firstWhere((t) => t.id == 8));
      final after = (await repo.getById(8))!;
      final spec = (await repo.remindersFor(8)).single;
      expect(planReminders(before, now, doneToday: true).first.at, tz.TZDateTime(ny, 2026, 11, 6, 20));
      expect(planSpec(after, spec, now, doneToday: true).first.at, tz.TZDateTime(ny, 2026, 11, 5, 20));
    });
  });

  test('ReminderSpec 上限：43200 合法、43201 非法', () {
    expect(ReminderSpec.validOffset(43200), isTrue);
    expect(ReminderSpec.validOffset(43201), isFalse);
    expect(ReminderSpec.allowedFor(10079, RepeatRule.weekly), isTrue);
    expect(ReminderSpec.allowedFor(10080, RepeatRule.weekly), isFalse);
  });
}
