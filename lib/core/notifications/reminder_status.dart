import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils/clock.dart';
import '../utils/date_utils.dart';
import '../utils/system_settings.dart';
import '../utils/timezone_setup.dart';
import 'notification_providers.dart';

/// 提醒相关的系统状态，供设置页和编辑弹层显示。
class ReminderStatus {
  const ReminderStatus({
    required this.supported,
    required this.notificationsEnabled,
    required this.exactAllowed,
    required this.timezone,
    this.batteryUnrestricted,
    this.timezoneGuessed = false,
    this.fullScreenAllowed,
  });

  /// 平台是否支持提醒（Windows 为 false）
  final bool supported;

  /// null = 无法判断
  final bool? notificationsEnabled;

  /// null = 平台不需要这个权限
  final bool? exactAllowed;

  /// 当前用于计算提醒的时区名；UTC 可能意味着获取失败
  final String timezone;

  /// 电池是否「不受限制」；null = 无法判断（非 Android）
  final bool? batteryUnrestricted;

  /// 没取到设备时区名，按 UTC 偏移推测
  final bool timezoneGuessed;

  /// 能否用全屏闹钟；null = 无法判断（非 Android）。没有时闹钟降级为持续响铃 + 横幅，不算"需要处理"
  final bool? fullScreenAllowed;

  bool get exactMissing => exactAllowed == false;
  bool get notificationsMissing => notificationsEnabled == false;
}

final reminderStatusProvider = FutureProvider<ReminderStatus>((ref) async {
  final s = ref.watch(reminderSchedulerProvider);
  return ReminderStatus(
    supported: s.supported,
    notificationsEnabled: await s.notificationsEnabled(),
    exactAllowed: await s.canScheduleExact(),
    timezone: tz.local.name,
    batteryUnrestricted: await ref.watch(systemSettingsProvider).isIgnoringBatteryOptimizations(),
    timezoneGuessed: timezoneIsFallback,
    fullScreenAllowed: await ref.watch(systemSettingsProvider).canUseFullScreenIntent(),
  );
});

/// App 回到前台时检查，以下情况全量重建提醒：
/// - 时区变了（提醒按当地钟点，要换算到新时区）
/// - 精确闹钟权限变了（换调度方式）
/// - 跨天了（补满"跳过今天 / 延后开始"用的一次性提醒窗口）
class ReminderMonitor {
  ReminderMonitor(this._ref);

  final Ref _ref;
  String? _timezone;
  bool? _exact;
  DateTime? _day;
  bool _initialized = false;

  Future<void> onResume() async {
    try {
      final scheduler = _ref.read(reminderSchedulerProvider);
      if (!scheduler.supported) return;
      final previousTz = _timezone ?? tz.local.name;
      final timezone = await initLocalTimezone() ?? previousTz;
      final exact = await scheduler.canScheduleExact();
      final day = startOfDay(_ref.read(clockProvider).now());

      final tzChanged = timezone != previousTz;
      final exactChanged = _initialized && exact != _exact;
      final dayChanged = _initialized && day != _day;
      _timezone = timezone;
      _exact = exact;
      _day = day;
      _initialized = true;

      if (tzChanged || exactChanged || dayChanged) {
        await _ref.read(reminderSyncProvider).resyncAll();
      }
    } catch (e, s) {
      debugPrint('回到前台检查提醒失败：$e\n$s');
    } finally {
      _ref.invalidate(reminderStatusProvider);
    }
  }
}

final reminderMonitorProvider = Provider<ReminderMonitor>(ReminderMonitor.new);
