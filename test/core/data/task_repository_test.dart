import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  final now = DateTime(2026, 10, 30, 8);

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('新建任务：默认中优先级、不重复', () async {
    final t = await repo.create(const TaskDraft(title: '买菜'), now: now);
    expect(t.id, greaterThan(0));
    expect(t.priority, Priority.medium);
    expect(t.reminderRepeat, RepeatRule.none);
    expect(t.completedAt, isNull);
  });

  test('空白备注存为 null；没有提醒时重复规则强制为不重复', () async {
    final t = await repo.create(
      const TaskDraft(title: 'a', note: '   ', reminderRepeat: RepeatRule.daily),
      now: now,
    );
    expect(t.note, isNull);
    expect(t.reminderRepeat, RepeatRule.none);
  });

  test('没有日期时 dueHasTime 为 false', () async {
    final t = await repo.create(const TaskDraft(title: 'a', dueHasTime: true), now: now);
    expect(t.dueHasTime, isFalse);
  });

  test('日期和提醒按当地钟点原样读回', () async {
    final due = DateTime(2026, 11, 1, 15, 30);
    final remind = DateTime(2026, 11, 1, 9, 0);
    final t = await repo.create(
      TaskDraft(title: 'a', dueAt: due, dueHasTime: true, reminderAt: remind),
      now: now,
    );
    final read = await repo.getById(t.id);
    expect(read!.dueAt, due);
    expect(read.reminderAt, remind);
    expect(read.reminderAt!.isUtc, isFalse);
  });

  test('编辑任务', () async {
    final t = await repo.create(const TaskDraft(title: 'a'), now: now);
    final later = now.add(const Duration(hours: 1));
    final u = await repo.update(
      t.id,
      TaskDraft(
        title: 'b',
        priority: Priority.high,
        reminderAt: DateTime(2026, 10, 31, 7),
        reminderRepeat: RepeatRule.weekly,
      ),
      now: later,
    );
    expect(u!.title, 'b');
    expect(u.priority, Priority.high);
    expect(u.reminderRepeat, RepeatRule.weekly);
    expect(u.updatedAt, later);
    expect(u.createdAt, now);
  });

  test('编辑不存在的任务返回 null', () async {
    expect(await repo.update(999, const TaskDraft(title: 'x'), now: now), isNull);
  });

  test('完成与取消完成', () async {
    final t = await repo.create(const TaskDraft(title: 'a'), now: now);
    final done = await repo.setCompleted(t.id, now, now: now);
    expect(done!.completedAt, now);
    final undone = await repo.setCompleted(t.id, null, now: now);
    expect(undone!.completedAt, isNull);
  });

  test('删除后 id 不复用', () async {
    final a = await repo.create(const TaskDraft(title: 'a'), now: now);
    await repo.delete(a.id);
    expect(await repo.getById(a.id), isNull);
    final b = await repo.create(const TaskDraft(title: 'b'), now: now);
    expect(b.id, greaterThan(a.id));
  });

  test('getWithReminder 只返回有提醒的任务', () async {
    await repo.create(const TaskDraft(title: 'a'), now: now);
    await repo.create(TaskDraft(title: 'b', reminderAt: DateTime(2026, 11, 1, 9)), now: now);
    final list = await repo.getWithReminder();
    expect(list.map((t) => t.title), ['b']);
  });

  test('watchAll：有日期的在前，同日期高优先级在前', () async {
    await repo.create(const TaskDraft(title: '无日期'), now: now);
    await repo.create(TaskDraft(title: '低', dueAt: DateTime(2026, 11, 1), priority: Priority.low), now: now);
    await repo.create(TaskDraft(title: '高', dueAt: DateTime(2026, 11, 1), priority: Priority.high), now: now);
    final list = await repo.watchAll().first;
    expect(list.map((t) => t.title), ['高', '低', '无日期']);
  });
}
