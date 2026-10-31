import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/reminder_spec.dart';
import 'package:facet/features/plan/reminder_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 30, 8, 20);

  group('锚点', () {
    test('任务有日期时间：就是任务时间', () {
      expect(defaultReminderTime(dueDate: DateTime(2026, 10, 30), dueHour: 10, dueMinute: 0, now: now), DateTime(2026, 10, 30, 10));
    });

    test('只有日期或没有日期：今天 / 无日期 → 下一个整点；其他日期 → 9:00', () {
      expect(defaultReminderTime(now: now), DateTime(2026, 10, 30, 9));
      expect(defaultReminderTime(dueDate: DateTime(2026, 10, 30), now: now), DateTime(2026, 10, 30, 9));
      expect(defaultReminderTime(dueDate: DateTime(2026, 11, 3), now: now), DateTime(2026, 11, 3, 9));
    });

    test('今天 23 点后没有日期：下一个整点落到明天 0 点', () {
      expect(defaultReminderTime(now: DateTime(2026, 12, 31, 23, 30)), DateTime(2027, 1, 1));
    });
  });

  group('默认提醒', () {
    List<int> offsets(List<ReminderSpec> specs) => [for (final s in specs) s.offsetMinutes];

    test('用设置里的默认提前量和方式，先响的在前', () {
      final specs = defaultReminderSpecs(
        anchor: DateTime(2026, 11, 3, 14),
        now: now,
        offsets: const [15, 1440],
        kind: ReminderKind.alarm,
      );
      expect(offsets(specs), [1440, 15]);
      expect(specs.every((s) => s.kind == ReminderKind.alarm), isTrue);
    });

    test('已经过去的提前量去掉（现在 8:20，任务 8:30：提前 15 分钟已过，准时保留）', () {
      final specs = defaultReminderSpecs(anchor: DateTime(2026, 10, 30, 8, 30), now: now, offsets: const [15, 0], kind: ReminderKind.notification);
      expect(offsets(specs), [0]);
    });

    test('全部过去时保留准时（编辑页会提示已经过去）', () {
      final specs = defaultReminderSpecs(anchor: DateTime(2026, 10, 30, 7), now: now, offsets: const [15], kind: ReminderKind.notification);
      expect(offsets(specs), [0]);
    });

    test('重复任务：不按"已过去"过滤，但去掉与重复周期冲突的提前量', () {
      final specs = defaultReminderSpecs(
        anchor: DateTime(2026, 10, 1, 7),
        now: now,
        offsets: const [1440, 15],
        kind: ReminderKind.notification,
        repeat: RepeatRule.daily,
      );
      expect(offsets(specs), [15]);
    });

    test('提前 15 分钟跨零点：00:05 的任务 → 前一天 23:50 仍在未来时保留', () {
      final specs = defaultReminderSpecs(anchor: DateTime(2026, 11, 2, 0, 5), now: now, offsets: const [15], kind: ReminderKind.notification);
      expect(offsets(specs), [15]);
    });
  });
}
