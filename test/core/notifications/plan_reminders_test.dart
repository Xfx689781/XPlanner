import 'package:facet/core/data/enums.dart';
import 'package:facet/core/notifications/next_trigger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/task_rules_test.dart' show task;

/// 按 flutter_local_notifications 22.x Android 端 getNextFireDateMatchingDateTimeComponents
/// 的算法，模拟插件收到 match 后实际安排的第一次触发：丢掉日期，从今天起找第一个
/// "钟点不早于现在"（每周还要星期几一致）的日子。
tz.TZDateTime pluginFirstFire(TriggerPlan p, tz.TZDateTime now) {
  final loc = now.location;
  var d = DateTime(now.year, now.month, now.day);
  tz.TZDateTime fire(DateTime d) => tz.TZDateTime(loc, d.year, d.month, d.day, p.at.hour, p.at.minute);
  while (fire(d).isBefore(now)) {
    d = DateTime(d.year, d.month, d.day + 1);
  }
  if (p.match == DateTimeComponents.dayOfWeekAndTime) {
    while (d.weekday != p.at.weekday) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
  }
  return fire(d);
}

void main() {
  late tz.Location ny;

  setUpAll(() {
    tzdata.initializeTimeZones();
    ny = tz.getLocation('America/New_York');
  });

  tz.TZDateTime at(int y, int m, int d, [int h = 0, int min = 0]) => tz.TZDateTime(ny, y, m, d, h, min);

  group('交给系统重复 vs 一次性窗口', () {
    test('普通每天重复：1 条，交给系统重复', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      final plans = planReminders(t, at(2026, 10, 30, 8), doneToday: false);
      expect(plans, hasLength(1));
      expect(plans.single.match, DateTimeComponents.time);
    });

    test('每天重复今天已完成（9 点前）：改为一次性窗口，从明天开始，今天不响', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      final plans = planReminders(t, at(2026, 10, 30, 8), doneToday: true);
      expect(plans, hasLength(dailyWindow));
      expect(plans.every((p) => p.match == null), isTrue);
      expect(plans.first.at, at(2026, 10, 31, 9));
      expect(plans.last.at, at(2026, 10, 30 + dailyWindow, 9));
    });

    test('每天重复今天已完成但 9 点已过：系统重复本来就从明天开始，仍用 1 条', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      final plans = planReminders(t, at(2026, 10, 30, 10), doneToday: true);
      expect(plans, hasLength(1));
      expect(plans.single.match, DateTimeComponents.time);
    });

    test('每天重复、开始日期在下周：一次性窗口，从开始日起', () {
      final t = task(reminderAt: DateTime(2026, 11, 5, 9), repeat: RepeatRule.daily);
      final plans = planReminders(t, at(2026, 10, 30, 8), doneToday: false);
      expect(plans, hasLength(dailyWindow));
      expect(plans.first.at, at(2026, 11, 5, 9));
    });

    test('每周重复、开始日期在 3 周后：一次性窗口，每周一次', () {
      final t = task(reminderAt: DateTime(2026, 11, 20, 9), repeat: RepeatRule.weekly); // 周五
      final plans = planReminders(t, at(2026, 10, 30, 8), doneToday: false);
      expect(plans, hasLength(weeklyWindow));
      expect(plans.map((p) => p.at), [
        at(2026, 11, 20, 9),
        at(2026, 11, 27, 9),
      ]);
    });

    test('每周重复今天是那一天且已完成：下周起的一次性窗口', () {
      final t = task(reminderAt: DateTime(2026, 10, 2, 9), repeat: RepeatRule.weekly);
      final plans = planReminders(t, at(2026, 10, 30, 8), doneToday: true);
      expect(plans.first.at, at(2026, 11, 6, 9));
      expect(plans.every((p) => p.match == null), isTrue);
    });

    test('一次性窗口跨过夏令时结束仍是当地 9:00', () {
      final t = task(reminderAt: DateTime(2026, 10, 1, 9), repeat: RepeatRule.daily);
      final plans = planReminders(t, at(2026, 10, 29, 8), doneToday: true);
      expect(plans.every((p) => p.at.hour == 9), isTrue);
      expect(plans.map((p) => p.at.timeZoneOffset).toSet(), {const Duration(hours: -4), const Duration(hours: -5)});
    });

    test('不重复：0 或 1 条', () {
      expect(planReminders(task(reminderAt: DateTime(2026, 10, 30, 9)), at(2026, 10, 30, 8), doneToday: false), hasLength(1));
      expect(planReminders(task(reminderAt: DateTime(2026, 10, 30, 7)), at(2026, 10, 30, 8), doneToday: false), isEmpty);
      expect(planReminders(task(), at(2026, 10, 30, 8), doneToday: false), isEmpty);
    });
  });

  test('回归：凡是交给系统重复的，插件实际算出的第一次触发 = 我们期望的第一次触发', () {
    // 覆盖一整年的每一天、每天/每周、完成/未完成、钟点在 now 前后
    final reminders = [DateTime(2026, 1, 2, 9), DateTime(2026, 1, 2, 23, 59), DateTime(2026, 3, 1, 2, 30)];
    var checked = 0;
    for (var day = 0; day < 366; day++) {
      final now = tz.TZDateTime(ny, 2026, 1, 1 + day, 8);
      for (final r in reminders) {
        for (final repeat in [RepeatRule.daily, RepeatRule.weekly]) {
          for (final done in [false, true]) {
            final t = task(reminderAt: r, repeat: repeat);
            final plans = planReminders(t, now, doneToday: done);
            if (plans.length != 1 || plans.single.match == null) continue;
            final expected = nextTrigger(t, now, doneToday: done)!;
            final fire = pluginFirstFire(plans.single, now);
            // 期望的第一次触发：按原始钟点在那一天解释（夏令时空档会被规范化）
            final want = _firstExpected(t.reminderAt!, repeat, now, done);
            expect(fire, want, reason: '$r $repeat done=$done now=$now plan=$expected');
            checked++;
          }
        }
      }
    }
    expect(checked, greaterThan(1000));
  });
}

/// 期望的第一次触发：严格晚于 now、不早于开始日、done 时跳过今天
tz.TZDateTime _firstExpected(DateTime r, RepeatRule repeat, tz.TZDateTime now, bool done) {
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(r.year, r.month, r.day);
  var d = start.isAfter(today) ? start : today;
  while (true) {
    final t = tz.TZDateTime(now.location, d.year, d.month, d.day, r.hour, r.minute);
    final ok = (repeat != RepeatRule.weekly || d.weekday == r.weekday) && !(done && d == today) && t.isAfter(now);
    if (ok) return t;
    d = DateTime(d.year, d.month, d.day + 1);
  }
}
