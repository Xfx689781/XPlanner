import 'package:facet/features/plan/reminder_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 30, 8, 20);

  DateTime calc({DateTime? date, int? h, int? m, DateTime? at, int lead = 0}) => defaultReminderTime(
    dueDate: date,
    dueHour: h,
    dueMinute: m,
    now: at ?? now,
    leadMinutes: lead,
  );

  test('有日期时间：准时 / 提前 5 / 提前 15 分钟', () {
    final d = DateTime(2026, 10, 30);
    expect(calc(date: d, h: 10, m: 0), DateTime(2026, 10, 30, 10));
    expect(calc(date: d, h: 10, m: 0, lead: 5), DateTime(2026, 10, 30, 9, 55));
    expect(calc(date: d, h: 10, m: 0, lead: 15), DateTime(2026, 10, 30, 9, 45));
  });

  test('提前量跨过零点、月初、年初', () {
    expect(calc(date: DateTime(2026, 11, 2), h: 0, m: 5, lead: 15), DateTime(2026, 11, 1, 23, 50));
    expect(calc(date: DateTime(2026, 12, 1), h: 0, m: 10, lead: 15), DateTime(2026, 11, 30, 23, 55));
    expect(calc(date: DateTime(2027, 1, 1), h: 0, m: 0, lead: 5), DateTime(2026, 12, 31, 23, 55));
  });

  test('提前后的时间已经过去、任务时间还没到：改为准时', () {
    // 现在 8:20，任务 8:30，提前 15 分钟是 8:15（已过）
    expect(calc(date: DateTime(2026, 10, 30), h: 8, m: 30, lead: 15), DateTime(2026, 10, 30, 8, 30));
  });

  test('任务时间也已过去：保持减去提前量（编辑弹层会提示已过去）', () {
    expect(calc(date: DateTime(2026, 10, 30), h: 7, m: 0, lead: 15), DateTime(2026, 10, 30, 6, 45));
  });

  test('只有日期或没有日期：提前量不起作用', () {
    expect(calc(lead: 15), DateTime(2026, 10, 30, 9)); // 今天下一个整点
    expect(calc(date: DateTime(2026, 10, 30), lead: 15), DateTime(2026, 10, 30, 9));
    expect(calc(date: DateTime(2026, 11, 3), lead: 15), DateTime(2026, 11, 3, 9));
  });

  test('今天 23 点后没有日期：下一个整点落到明天 0 点', () {
    expect(calc(at: DateTime(2026, 12, 31, 23, 30)), DateTime(2027, 1, 1));
  });
}
