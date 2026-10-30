import 'package:drift/drift.dart';

import 'app_database.dart';
import 'enums.dart';
import 'reminder_spec.dart';

/// 新建 / 编辑任务时由界面填写的内容。
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.note,
    this.dueAt,
    this.dueHasTime = false,
    this.priority = Priority.medium,
    this.reminderAt,
    this.reminderRepeat = RepeatRule.none,
    this.reminders = const [],
  });

  final String title;
  final String? note;
  final DateTime? dueAt;
  final bool dueHasTime;
  final Priority priority;
  /// 提醒锚点（当地钟点）：任务有时间时一般等于任务时间；每个提醒 = 锚点 − 提前量
  final DateTime? reminderAt;
  final RepeatRule reminderRepeat;

  /// 提前量和方式（最多 5 个）。为空但有 [reminderAt] 时按"准时、普通通知"处理（与 v2 行为一致）
  final List<ReminderSpec> reminders;

  /// 实际要保存的提醒：去重、过滤掉与重复周期冲突的；没有锚点时为空
  List<ReminderSpec> get effectiveReminders {
    if (reminderAt == null) return const [];
    final list = ReminderSpec.normalize(reminders, reminderRepeat);
    return list.isEmpty ? const [ReminderSpec(0)] : list;
  }
}

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  Stream<List<Task>> watchAll() {
    return (_db.select(_db.tasks)..orderBy([
          (t) => OrderingTerm(expression: t.dueAt, nulls: NullsOrder.last),
          (t) => OrderingTerm.desc(t.priority),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .watch();
  }

  Stream<Task?> watchById(int id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<Task?> getById(int id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 所有设置了提醒的任务（含已完成，是否调度由同步服务判断）
  Future<List<Task>> getWithReminder() {
    return (_db.select(_db.tasks)..where((t) => t.reminderAt.isNotNull() | t.snoozedUntil.isNotNull())).get();
  }

  /// 一个任务的提醒，先响的在前
  Future<List<ReminderSpec>> remindersFor(int taskId) async {
    final rows = await (_db.select(_db.taskReminders)
          ..where((r) => r.taskId.equals(taskId))
          ..orderBy([(r) => OrderingTerm.desc(r.offsetMinutes)]))
        .get();
    return [for (final r in rows) ReminderSpec(r.offsetMinutes, r.kind)];
  }

  Stream<List<ReminderSpec>> watchRemindersFor(int taskId) {
    return (_db.select(_db.taskReminders)
          ..where((r) => r.taskId.equals(taskId))
          ..orderBy([(r) => OrderingTerm.desc(r.offsetMinutes)]))
        .watch()
        .map((rows) => [for (final r in rows) ReminderSpec(r.offsetMinutes, r.kind)]);
  }

  Future<Task> create(TaskDraft d, {required DateTime now}) {
    return _db.transaction(() async {
      final task = await _db.into(_db.tasks).insertReturning(
        TasksCompanion.insert(
          title: d.title,
          note: Value(_blankToNull(d.note)),
          dueAt: Value(d.dueAt),
          dueHasTime: Value(d.dueAt != null && d.dueHasTime),
          priority: Value(d.priority),
          reminderAt: Value(d.reminderAt),
          reminderRepeat: Value(d.reminderAt == null ? RepeatRule.none : d.reminderRepeat),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _writeReminders(task.id, d.effectiveReminders);
      return task;
    });
  }

  /// 返回更新后的任务；任务不存在时返回 null。编辑会清掉"稍后提醒"
  Future<Task?> update(int id, TaskDraft d, {required DateTime now}) {
    return _db.transaction(() async {
      final rows = await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).writeReturning(
        TasksCompanion(
          title: Value(d.title),
          note: Value(_blankToNull(d.note)),
          dueAt: Value(d.dueAt),
          dueHasTime: Value(d.dueAt != null && d.dueHasTime),
          priority: Value(d.priority),
          reminderAt: Value(d.reminderAt),
          reminderRepeat: Value(d.reminderAt == null ? RepeatRule.none : d.reminderRepeat),
          snoozedUntil: const Value(null),
          updatedAt: Value(now),
        ),
      );
      final task = rows.firstOrNull;
      if (task != null) await _writeReminders(id, d.effectiveReminders);
      return task;
    });
  }

  Future<void> _writeReminders(int taskId, List<ReminderSpec> specs) async {
    await (_db.delete(_db.taskReminders)..where((r) => r.taskId.equals(taskId))).go();
    for (final s in specs) {
      await _db.into(_db.taskReminders).insert(
        TaskRemindersCompanion.insert(taskId: taskId, offsetMinutes: s.offsetMinutes, kind: Value(s.kind)),
      );
    }
  }

  /// completedAt 为 null 表示取消完成。完成 / 取消完成都会清掉"稍后提醒"
  Future<Task?> setCompleted(int id, DateTime? completedAt, {required DateTime now}) async {
    final rows = await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).writeReturning(
      TasksCompanion(completedAt: Value(completedAt), snoozedUntil: const Value(null), updatedAt: Value(now)),
    );
    return rows.firstOrNull;
  }

  /// "稍后提醒"：记下再次响铃的时刻（null = 取消）
  Future<Task?> setSnoozed(int id, DateTime? until) async {
    final rows = await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).writeReturning(
      TasksCompanion(snoozedUntil: Value(until)),
    );
    return rows.firstOrNull;
  }

  Future<void> delete(int id) {
    return _db.transaction(() async {
      // 外键已开级联删除；这里再显式删一次，不依赖 PRAGMA
      await (_db.delete(_db.taskReminders)..where((r) => r.taskId.equals(id))).go();
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
    });
  }

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
