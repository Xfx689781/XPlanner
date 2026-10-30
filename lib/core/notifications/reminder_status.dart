import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

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
  );
});

/// App 回到前台时检查：时区或精确闹钟权限变了就全量重建提醒。
class ReminderMonitor {
  ReminderMonitor(this._ref);

  final Ref _ref;
  String? _timezone;
  bool? _exact;
  bool _initialized = false;

  Future<void> onResume() async {
    final scheduler = _ref.read(reminderSchedulerProvider);
    if (!scheduler.supported) return;
    final previousTz = _timezone ?? tz.local.name;
    final timezone = await initLocalTimezone() ?? previousTz;
    final exact = await scheduler.canScheduleExact();

    final tzChanged = timezone != previousTz;
    final exactChanged = _initialized && exact != _exact;
    _timezone = timezone;
    _exact = exact;
    _initialized = true;

    if (tzChanged || exactChanged) {
      await _ref.read(reminderSyncProvider).resyncAll();
    }
    _ref.invalidate(reminderStatusProvider);
  }
}

final reminderMonitorProvider = Provider<ReminderMonitor>(ReminderMonitor.new);
