import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/log_repository.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUp(() => db = openTestDb());

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  testWidgets('大圆按今天任务完成比例填充，逾期单独显示且不计入', (tester) async {
    final repo = TaskRepository(db);
    await tester.db(() async {
      final a = await repo.create(TaskDraft(title: 'A', dueAt: DateTime(2026, 10, 30)), now: clock.value);
      await repo.create(TaskDraft(title: 'B', dueAt: DateTime(2026, 10, 30)), now: clock.value);
      await repo.create(TaskDraft(title: '逾期的', dueAt: DateTime(2026, 10, 20)), now: clock.value);
      await repo.create(TaskDraft(title: '明天的', dueAt: DateTime(2026, 10, 31)), now: clock.value);
      await repo.setCompleted(a.id, clock.value, now: clock.value);
    });

    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.pumpAndSettle();

    expect(find.text('逾期'), findsOneWidget);
    expect(find.text('逾期的'), findsOneWidget);
    expect(find.text('明天的'), findsNothing);
    expect(find.text('1 / 2 已完成'), findsWidgets);
    final circle = tester.widget<DayCircle>(find.byType(DayCircle));
    expect(circle.progress, 0.5);
    await finish(tester);
  });

  testWidgets('没有任务时圆心显示今天没有任务和添加入口', (tester) async {
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.pumpAndSettle();
    expect(find.text('今天没有任务'), findsOneWidget);
    expect(find.text('+ 添加'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('今天页只显示今天的日志，并可以快速记一句', (tester) async {
    await tester.db(() async {
      final logs = LogRepository(db);
      await logs.add('昨天的事', now: DateTime(2026, 10, 29, 22));
      await logs.add('早起', now: DateTime(2026, 10, 30, 6, 30));
    });
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.pumpAndSettle();

    expect(find.text('早起'), findsOneWidget);
    expect(find.text('昨天的事'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, '记一句…'), '喝了咖啡');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('喝了咖啡'), findsOneWidget);
    await finish(tester);
  });
}
