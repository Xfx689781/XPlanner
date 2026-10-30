import 'package:drift/drift.dart';

import 'app_database.dart';

class LogRepository {
  LogRepository(this._db);

  final AppDatabase _db;

  /// 新的在前
  Stream<List<LogEntry>> watchAll() {
    return (_db.select(_db.logEntries)..orderBy([
          (l) => OrderingTerm.desc(l.createdAt),
          (l) => OrderingTerm.desc(l.id),
        ]))
        .watch();
  }

  /// [from, to) 之间的记录，新的在前
  Stream<List<LogEntry>> watchBetween(DateTime from, DateTime to) {
    return (_db.select(_db.logEntries)
          ..where((l) => l.createdAt.isBiggerOrEqualValue(from) & l.createdAt.isSmallerThanValue(to))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt), (l) => OrderingTerm.desc(l.id)]))
        .watch();
  }

  /// 内容去掉首尾空白；空内容返回 null 不写入
  Future<LogEntry?> add(String content, {required DateTime now}) async {
    final text = content.trim();
    if (text.isEmpty) return null;
    return _db.into(_db.logEntries).insertReturning(
      LogEntriesCompanion.insert(content: text, createdAt: now),
    );
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.logEntries)..where((l) => l.id.equals(id))).go();
  }
}
