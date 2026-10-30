import 'package:drift/drift.dart';

import 'app_database.dart';
import 'enums.dart';

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
  });

  final String title;
  final String? note;
  final DateTime? dueAt;
  final bool dueHasTime;
  final Priority priority;
  final DateTime? reminderAt;
  final RepeatRule reminderRepeat;
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
    return (_db.select(_db.tasks)..where((t) => t.reminderAt.isNotNull())).get();
  }

  Future<Task> create(TaskDraft d, {required DateTime now}) {
    return _db.into(_db.tasks).insertReturning(
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
  }

  /// 返回更新后的任务；任务不存在时返回 null
  Future<Task?> update(int id, TaskDraft d, {required DateTime now}) async {
    final rows = await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).writeReturning(
      TasksCompanion(
        title: Value(d.title),
        note: Value(_blankToNull(d.note)),
        dueAt: Value(d.dueAt),
        dueHasTime: Value(d.dueAt != null && d.dueHasTime),
        priority: Value(d.priority),
        reminderAt: Value(d.reminderAt),
        reminderRepeat: Value(d.reminderAt == null ? RepeatRule.none : d.reminderRepeat),
        updatedAt: Value(now),
      ),
    );
    return rows.firstOrNull;
  }

  /// completedAt 为 null 表示取消完成
  Future<Task?> setCompleted(int id, DateTime? completedAt, {required DateTime now}) async {
    final rows = await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).writeReturning(
      TasksCompanion(completedAt: Value(completedAt), updatedAt: Value(now)),
    );
    return rows.firstOrNull;
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
