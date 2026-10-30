import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUp(() {
    db = openTestDb();
    repo = TaskRepository(db);
  });

  Future<void> openTasksTab(WidgetTester tester) async {
    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.tapNav('任务');
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.disposeApp();
    await tester.db(db.close);
  }

  testWidgets('新建任务后出现在列表里', (tester) async {
    await openTasksTab(tester);
    await tester.tap(find.bySemanticsLabel('新建任务'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '写周报');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('今天').last);
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('写周报'), findsOneWidget);
    final rows = await tester.db(() => repo.watchAll().first);
    expect(rows.single.dueAt, DateTime(2026, 10, 30));
    await finish(tester);
  });

  testWidgets('标题为空时不能保存', (tester) async {
    await openTasksTab(tester);
    await tester.tap(find.bySemanticsLabel('新建任务'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('新任务'), findsOneWidget);
    expect(await tester.db(() => repo.watchAll().first), isEmpty);
    await finish(tester);
  });

  testWidgets('逾期分组 + 点方块完成', (tester) async {
    await tester.db(() async {
      await repo.create(TaskDraft(title: '过期的', dueAt: DateTime(2026, 10, 28)), now: clock.value);
      await repo.create(
        TaskDraft(title: '今天的', dueAt: DateTime(2026, 10, 30), priority: Priority.high),
        now: clock.value,
      );
    });
    await openTasksTab(tester);

    expect(find.text('逾期'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^今天的，高优先级')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final t = (await tester.db(() => repo.watchAll().first)).firstWhere((t) => t.title == '今天的');
    expect(t.completedAt, clock.value);
    final square = tester.widget<TaskSquare>(
      find.byWidgetPredicate((w) => w is TaskSquare && (w.semanticLabel ?? '').startsWith('今天的')),
    );
    expect(square.done, isTrue);
    await finish(tester);
  });

  testWidgets('编辑后删除任务', (tester) async {
    await tester.db(() => repo.create(const TaskDraft(title: '要删的'), now: clock.value));
    await openTasksTab(tester);

    await tester.tap(find.text('要删的'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('要删的'), findsNothing);
    expect(await tester.db(() => repo.watchAll().first), isEmpty);
    await finish(tester);
  });
}
