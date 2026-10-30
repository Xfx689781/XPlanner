import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUp(() => db = openTestDb());

  testWidgets('按天分组，跨年显示年份', (tester) async {
    await tester.db(() async {
      final logs = LogRepository(db);
      await logs.add('去年最后一天', now: DateTime(2025, 12, 31, 23, 30));
      await logs.add('昨晚', now: DateTime(2026, 10, 29, 23, 59));
      await logs.add('今早', now: DateTime(2026, 10, 30, 7, 5));
    });
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.tapNav('日志');

    expect(find.text('今天'), findsWidgets);
    expect(find.text('昨天'), findsOneWidget);
    expect(find.text('2025年12月31日 周三'), findsOneWidget);
    expect(find.text('07:05'), findsOneWidget);

    await tester.disposeApp();
    await tester.db(db.close);
  });
}
