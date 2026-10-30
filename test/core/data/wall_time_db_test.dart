import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/data/task_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

/// 当地钟点经过真实的 drift 内存数据库往返后不变。
void main() {
  late AppDatabase db;
  late TaskRepository repo;
  final now = DateTime(2026, 10, 30, 8);

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('边界钟点往返不变：零点、23:59、闰日、跨年', () async {
    for (final d in [
      DateTime(2026, 10, 30, 0, 0),
      DateTime(2026, 10, 30, 23, 59),
      DateTime(2028, 2, 29, 9, 30),
      DateTime(2026, 12, 31, 23, 59),
      DateTime(2027, 1, 1, 0, 0),
    ]) {
      final t = await repo.create(TaskDraft(title: 'a', dueAt: d, dueHasTime: true, reminderAt: d), now: now);
      final read = (await repo.getById(t.id))!;
      expect(read.dueAt, d, reason: '$d');
      expect(read.reminderAt, d, reason: '$d');
      expect(read.isForDay(DateTime(d.year, d.month, d.day)), isTrue, reason: '$d');
    }
  });

  test('getWithReminder 只返回有提醒的任务（含已完成）', () async {
    final a = await repo.create(TaskDraft(title: 'a', reminderAt: DateTime(2026, 11, 1, 9)), now: now);
    await repo.create(const TaskDraft(title: 'b'), now: now);
    final c = await repo.create(
      TaskDraft(title: 'c', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.weekly),
      now: now,
    );
    await repo.setCompleted(c.id, now, now: now);
    final ids = (await repo.getWithReminder()).map((t) => t.id).toSet();
    expect(ids, {a.id, c.id});
  });

  test('重复任务完成时刻往返后仍落在同一天（23:59:59）', () async {
    final t = await repo.create(
      TaskDraft(title: 'a', reminderAt: DateTime(2026, 10, 1, 9), reminderRepeat: RepeatRule.daily),
      now: now,
    );
    final done = await repo.setCompleted(t.id, DateTime(2026, 10, 29, 23, 59, 59), now: now);
    expect(done!.isDoneOn(DateTime(2026, 10, 29)), isTrue);
    expect(done.isDoneOn(DateTime(2026, 10, 30)), isFalse);
  });
}
