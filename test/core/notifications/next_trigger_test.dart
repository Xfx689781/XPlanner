import 'package:facet/core/data/enums.dart';
import 'package:facet/core/notifications/next_trigger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/task_rules_test.dart' show task;

void main() {
  late tz.Location ny;
  late tz.Location shanghai;

  setUpAll(() {
    tzdata.initializeTimeZones();
    ny = tz.getLocation('America/New_York');
    shanghai = tz.getLocation('Asia/Shanghai');
  });

  tz.TZDateTime at(tz.Location l, int y, int m, int d, [int h = 0, int min = 0]) =>
      tz.TZDateTime(l, y, m, d, h, min);

  group('不重复', () {
    test('未来的时间：按原样安排一次', () {
      final t = task(reminderAt: DateTime(2026, 10, 30, 9));
      final p = nextTrigger(t, at(ny, 2026, 10, 30, 8), doneToday: false)!;
      expect(p.at, at(ny, 2026, 10, 30, 9));
      expect(p.match, isNull);
    });

    test('已经过去或正好等于现在：不安排', () {
      final t = task(reminderAt: DateTime(2026, 10, 30, 9));
      expect(nextTrigger(t, at(ny, 2026, 10, 30, 9), doneToday: false), isNull);
      expect(nextTrigger(t, at(ny, 2026, 10, 30, 9, 1), doneToday: false), isNull);
    });

    test('已完成：不安排', () {
      final t = task(reminderAt: DateTime(2026, 10, 30, 9), completedAt: DateTime(2026, 10, 30, 7));
      expect(nextTrigger(t, at(ny, 2026, 10, 30, 8), doneToday: true), isNull);
    });

    test('没有提醒：不安排', () {
      expect(nextTrigger(task(), at(ny, 2026, 10, 30), doneToday: false), isNull);
    });
  });

  group('每天', () {
    final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);

    test('今天的时间还没到：今天', () {
      final p = nextTrigger(t, at(ny, 2026, 10, 30, 8), doneToday: false)!;
      expect(p.at, at(ny, 2026, 10, 30, 9));
      expect(p.match, DateTimeComponents.time);
    });

    test('今天的时间已过：明天', () {
      final p = nextTrigger(t, at(ny, 2026, 10, 30, 10), doneToday: false)!;
      expect(p.at, at(ny, 2026, 10, 31, 9));
    });

    test('今天已完成：即使时间没到也从明天开始', () {
      final p = nextTrigger(t, at(ny, 2026, 10, 30, 8), doneToday: true)!;
      expect(p.at, at(ny, 2026, 10, 31, 9));
    });

    test('开始日期在未来：从开始那天起', () {
      final future = task(reminderAt: DateTime(2026, 11, 5, 9), repeat: RepeatRule.daily);
      final p = nextTrigger(future, at(ny, 2026, 10, 30, 10), doneToday: false)!;
      expect(p.at, at(ny, 2026, 11, 5, 9));
    });

    test('跨月、跨年', () {
      expect(nextTrigger(t, at(ny, 2026, 10, 31, 10), doneToday: false)!.at, at(ny, 2026, 11, 1, 9));
      expect(nextTrigger(t, at(ny, 2026, 12, 31, 23), doneToday: false)!.at, at(ny, 2027, 1, 1, 9));
    });
  });

  group('每周', () {
    // 2026-10-02 是周五
    final t = task(reminderAt: DateTime(2026, 10, 2, 9), repeat: RepeatRule.weekly);

    test('今天就是那一天且时间未到：今天', () {
      final p = nextTrigger(t, at(ny, 2026, 10, 30, 8), doneToday: false)!;
      expect(p.at, at(ny, 2026, 10, 30, 9));
      expect(p.match, DateTimeComponents.dayOfWeekAndTime);
    });

    test('今天就是那一天但已过或已完成：下周', () {
      expect(nextTrigger(t, at(ny, 2026, 10, 30, 10), doneToday: false)!.at, at(ny, 2026, 11, 6, 9));
      expect(nextTrigger(t, at(ny, 2026, 10, 30, 8), doneToday: true)!.at, at(ny, 2026, 11, 6, 9));
    });

    test('跨年找到下一个周五', () {
      final p = nextTrigger(t, at(ny, 2026, 12, 30, 12), doneToday: false)!;
      expect(p.at, at(ny, 2027, 1, 1, 9));
      expect(p.at.weekday, DateTime.friday);
    });
  });

  group('夏令时（America/New_York）', () {
    test('夏令时开始当天，每天 9:00 仍是当地 9:00（偏移从 -5 变 -4）', () {
      final t = task(reminderAt: DateTime(2026, 3, 1, 9), repeat: RepeatRule.daily);
      final before = nextTrigger(t, at(ny, 2026, 3, 7, 10), doneToday: false)!.at;
      expect(before.hour, 9);
      expect(before.day, 8);
      expect(before.timeZoneOffset, const Duration(hours: -4));
      expect(at(ny, 2026, 3, 7, 9).timeZoneOffset, const Duration(hours: -5));
    });

    test('夏令时结束当天，每天 9:00 仍是当地 9:00（偏移从 -4 变 -5）', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      final p = nextTrigger(t, at(ny, 2026, 10, 31, 10), doneToday: false)!.at;
      expect((p.month, p.day, p.hour), (11, 1, 9));
      expect(p.timeZoneOffset, const Duration(hours: -5));
    });

    test('不存在的钟点 02:30（3 月 8 日跳过）被规范化到跳变之后', () {
      final t = task(reminderAt: DateTime(2026, 3, 8, 2, 30));
      final p = nextTrigger(t, at(ny, 2026, 3, 7, 12), doneToday: false)!.at;
      expect(p.day, 8);
      expect(p.hour, 3);
      expect(p.minute, 30);
    });

    test('重复出现的钟点 01:30（11 月 1 日）安排在当地 01:30', () {
      final t = task(reminderAt: DateTime(2026, 11, 1, 1, 30));
      final p = nextTrigger(t, at(ny, 2026, 10, 31, 12), doneToday: false)!.at;
      expect((p.day, p.hour, p.minute), (1, 1, 30));
    });
  });

  test('换时区：同一个任务在新时区仍是当地 9:00', () {
    final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
    final inNy = nextTrigger(t, at(ny, 2026, 10, 30, 8), doneToday: false)!.at;
    final inSh = nextTrigger(t, at(shanghai, 2026, 10, 30, 8), doneToday: false)!.at;
    expect(inNy.hour, 9);
    expect(inSh.hour, 9);
    expect(inNy.location.name, 'America/New_York');
    expect(inSh.location.name, 'Asia/Shanghai');
    // 两个"9:00"是不同的绝对时刻
    expect(inNy.toUtc(), isNot(inSh.toUtc()));
  });
}
