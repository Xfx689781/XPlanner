import 'package:flutter/foundation.dart';

import 'enums.dart';

/// 一个提醒：在锚点之前多少分钟、用什么方式。
@immutable
class ReminderSpec {
  const ReminderSpec(this.offsetMinutes, [this.kind = ReminderKind.notification]);

  /// 0 = 准时
  final int offsetMinutes;
  final ReminderKind kind;

  /// 一个任务最多几个提醒
  static const maxPerTask = 5;

  /// 自定义提前量上限：30 天
  static const maxOffsetMinutes = 30 * 24 * 60;

  /// 预设：准时、5/10/15/30 分钟、1/2 小时、1/2 天、1 周
  static const presets = [0, 5, 10, 15, 30, 60, 120, 1440, 2880, 10080];

  static const minutesPerDay = 24 * 60;
  static const minutesPerWeek = 7 * minutesPerDay;

  /// 重复任务的提前量必须小于重复周期（每天重复不能提前 ≥1 天，每周重复不能提前 ≥1 周）
  static bool allowedFor(int offsetMinutes, RepeatRule repeat) => switch (repeat) {
    RepeatRule.none => true,
    RepeatRule.daily => offsetMinutes < minutesPerDay,
    RepeatRule.weekly => offsetMinutes < minutesPerWeek,
  };

  static bool validOffset(int offsetMinutes) => offsetMinutes >= 0 && offsetMinutes <= maxOffsetMinutes;

  /// 去重、过滤非法值、按提前量从大到小排序（先响的在前），最多 [maxPerTask] 个
  static List<ReminderSpec> normalize(Iterable<ReminderSpec> specs, RepeatRule repeat) {
    final byOffset = <int, ReminderSpec>{};
    for (final s in specs) {
      if (!validOffset(s.offsetMinutes) || !allowedFor(s.offsetMinutes, repeat)) continue;
      byOffset.putIfAbsent(s.offsetMinutes, () => s);
    }
    final list = byOffset.values.toList()..sort((a, b) => b.offsetMinutes.compareTo(a.offsetMinutes));
    return list.take(maxPerTask).toList();
  }

  ReminderSpec copyWith({int? offsetMinutes, ReminderKind? kind}) =>
      ReminderSpec(offsetMinutes ?? this.offsetMinutes, kind ?? this.kind);

  @override
  bool operator ==(Object other) =>
      other is ReminderSpec && other.offsetMinutes == offsetMinutes && other.kind == kind;

  @override
  int get hashCode => Object.hash(offsetMinutes, kind);

  @override
  String toString() => 'ReminderSpec($offsetMinutes, ${kind.name})';
}

/// 提前量拆成"数字 + 单位"，用于显示：能整除周按周，其次天、小时，否则分钟
enum OffsetUnit { minutes, hours, days, weeks }

(int, OffsetUnit) splitOffset(int minutes) {
  if (minutes > 0 && minutes % ReminderSpec.minutesPerWeek == 0) return (minutes ~/ ReminderSpec.minutesPerWeek, OffsetUnit.weeks);
  if (minutes > 0 && minutes % ReminderSpec.minutesPerDay == 0) return (minutes ~/ ReminderSpec.minutesPerDay, OffsetUnit.days);
  if (minutes > 0 && minutes % 60 == 0) return (minutes ~/ 60, OffsetUnit.hours);
  return (minutes, OffsetUnit.minutes);
}
