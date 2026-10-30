import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/task_repository.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_db.dart';

/// App 开着跨过零点：今天页自动切到新的一天。
void main() {
  late AppDatabase db;

  setUp(() => db = openTestDb());

  testWidgets('跨零点：重复任务回到未完成，昨天的日期任务变成逾期', (tester) async {
    final clock = FixedClock(DateTime(2026, 12, 31, 23, 59, 50));
    final repo = TaskRepository(db);
    await tester.db(() async {
      final daily = await repo.create(
        TaskDraft(title: '每天读书', reminderAt: DateTime(2026, 12, 1, 21), reminderRepeat: RepeatRule.daily),
        now: clock.value,
      );
      await repo.setCompleted(daily.id, DateTime(2026, 12, 31, 21, 30), now: clock.value);
      await repo.create(TaskDraft(title: '年终总结', dueAt: DateTime(2026, 12, 31)), now: clock.value);
    });

    await tester.pumpWidget(testApp(db, clock: clock));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2 已完成'), findsWidgets);
    expect(find.text('逾期'), findsNothing);
    expect(tester.widget<DayCircle>(find.byType(DayCircle)).progress, 0.5);

    // 跨过零点（CurrentDay 的计时器在零点后 1 秒触发）
    clock.value = DateTime(2027, 1, 1, 0, 0, 5);
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();

    expect(find.text('0 / 1 已完成'), findsWidgets);
    expect(find.text('逾期'), findsOneWidget);
    expect(find.text('年终总结'), findsOneWidget);
    expect(tester.widget<DayCircle>(find.byType(DayCircle)).progress, 0);

    await tester.disposeApp();
    await tester.db(db.close);
  });
}
