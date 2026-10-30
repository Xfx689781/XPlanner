import 'package:facet/app/app.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/core/notifications/notification_providers.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_scheduler.dart';
import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final clock = FixedClock(DateTime(2026, 10, 30, 8));

  setUp(() {
    db = openTestDb();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
      reminderSchedulerProvider.overrideWithValue(FakeScheduler(supported: false)),
    ]);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const FacetApp()));
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // UncontrolledProviderScope 卸载时不会销毁 container：先销毁，让 drift 流查询在假时钟下收尾
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.db(db.close);
  }

  testWidgets('App 运行中点通知：切到任务页并打开该任务', (tester) async {
    final t = await tester.db(() => TaskRepository(db).create(const TaskDraft(title: '交房租'), now: clock.value));
    await pumpApp(tester);

    container.read(pendingNavigationProvider.notifier).open(t.id);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('编辑任务'), findsOneWidget);
    expect(find.widgetWithText(TextField, '交房租'), findsOneWidget);
    expect(container.read(pendingNavigationProvider), isNull);
    await finish(tester);
  });

  testWidgets('冷启动带着通知参数：首帧后打开该任务', (tester) async {
    final t = await tester.db(() => TaskRepository(db).create(const TaskDraft(title: '吃药'), now: clock.value));
    container.read(pendingNavigationProvider.notifier).open(t.id);
    await pumpApp(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '吃药'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('任务已被删除：提示而不是崩溃', (tester) async {
    await pumpApp(tester);
    container.read(pendingNavigationProvider.notifier).open(12345);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('这个任务已经删除'), findsOneWidget);
    await finish(tester);
  });
}
