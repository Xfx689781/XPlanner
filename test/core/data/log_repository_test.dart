import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late LogRepository repo;

  setUp(() {
    db = openTestDb();
    repo = LogRepository(db);
  });
  tearDown(() => db.close());

  test('空内容不写入，首尾空白被去掉', () async {
    expect(await repo.add('   ', now: DateTime(2026, 10, 30)), isNull);
    final e = await repo.add('  跑了 5 公里 ', now: DateTime(2026, 10, 30, 7));
    expect(e!.content, '跑了 5 公里');
  });

  test('watchAll 新的在前', () async {
    await repo.add('早', now: DateTime(2026, 10, 30, 7));
    await repo.add('晚', now: DateTime(2026, 10, 30, 22));
    final list = await repo.watchAll().first;
    expect(list.map((e) => e.content), ['晚', '早']);
  });

  test('watchBetween 是左闭右开区间', () async {
    await repo.add('前一天最后一秒', now: DateTime(2026, 10, 29, 23, 59, 59));
    await repo.add('零点', now: DateTime(2026, 10, 30));
    await repo.add('次日零点', now: DateTime(2026, 10, 31));
    final list = await repo.watchBetween(DateTime(2026, 10, 30), DateTime(2026, 10, 31)).first;
    expect(list.map((e) => e.content), ['零点']);
  });

  test('删除', () async {
    final e = await repo.add('x', now: DateTime(2026, 10, 30));
    await repo.delete(e!.id);
    expect(await repo.watchAll().first, isEmpty);
  });
}
