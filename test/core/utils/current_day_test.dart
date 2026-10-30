import 'package:facet/core/utils/clock.dart';
import 'package:facet/core/utils/current_day.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('refresh', () {
    late FixedClock clock;
    late ProviderContainer container;
    late List<DateTime> changes;

    setUp(() {
      clock = FixedClock(DateTime(2026, 10, 30, 23, 59, 30));
      container = ProviderContainer(overrides: [clockProvider.overrideWithValue(clock)]);
      changes = [];
      container.listen<DateTime>(currentDayProvider, (_, next) => changes.add(next), fireImmediately: false);
    });
    tearDown(() => container.dispose());

    test('初始值是当天 00:00', () {
      expect(container.read(currentDayProvider), DateTime(2026, 10, 30));
    });

    test('跨过零点后 refresh 切换到新的一天，并通知监听者一次', () {
      container.read(currentDayProvider);
      clock.value = DateTime(2026, 10, 31, 0, 0, 1);
      container.read(currentDayProvider.notifier).refresh();
      expect(container.read(currentDayProvider), DateTime(2026, 10, 31));
      expect(changes, [DateTime(2026, 10, 31)]);
    });

    test('同一天内 refresh 不通知监听者', () {
      container.read(currentDayProvider);
      clock.value = DateTime(2026, 10, 30, 23, 59, 59);
      container.read(currentDayProvider.notifier).refresh();
      expect(changes, isEmpty);
    });

    test('跨月、跨年、闰日', () {
      container.read(currentDayProvider);
      final notifier = container.read(currentDayProvider.notifier);
      for (final (now, day) in [
        (DateTime(2026, 11, 1, 0, 5), DateTime(2026, 11, 1)),
        (DateTime(2027, 1, 1, 0, 0), DateTime(2027, 1, 1)),
        (DateTime(2028, 2, 29, 8), DateTime(2028, 2, 29)),
        (DateTime(2028, 3, 1, 0, 0), DateTime(2028, 3, 1)),
      ]) {
        clock.value = now;
        notifier.refresh();
        expect(container.read(currentDayProvider), day, reason: '$now');
      }
      expect(changes.length, 4);
    });

    test('时钟回拨到前一天（例如改了时区）：refresh 也会跟着回到前一天', () {
      container.read(currentDayProvider);
      clock.value = DateTime(2026, 10, 29, 22);
      container.read(currentDayProvider.notifier).refresh();
      expect(container.read(currentDayProvider), DateTime(2026, 10, 29));
    });
  });

  testWidgets('不调用 refresh：到零点（多等 1 秒）时计时器自动切换', (tester) async {
    final clock = FixedClock(DateTime(2026, 12, 31, 23, 59));
    final container = ProviderContainer(overrides: [clockProvider.overrideWithValue(clock)]);

    expect(container.read(currentDayProvider), DateTime(2026, 12, 31));

    // 零点刚到但还没到 +1s 的余量：仍是前一天
    clock.value = DateTime(2027, 1, 1, 0, 0, 0);
    await tester.pump(const Duration(seconds: 60));
    expect(container.read(currentDayProvider), DateTime(2026, 12, 31));

    clock.value = DateTime(2027, 1, 1, 0, 0, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(currentDayProvider), DateTime(2027, 1, 1));

    // 计时器会重新安排到下一个零点
    clock.value = DateTime(2027, 1, 2, 0, 0, 1);
    await tester.pump(const Duration(days: 1));
    expect(container.read(currentDayProvider), DateTime(2027, 1, 2));

    container.dispose();
  });
}
