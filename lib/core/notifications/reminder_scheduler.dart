import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:timezone/timezone.dart' as tz;

class ReminderRequest {
  const ReminderRequest({
    required this.id,
    required this.title,
    required this.at,
    this.body,
    this.match,
    this.payload,
  });

  final int id;
  final String title;
  final String? body;
  final tz.TZDateTime at;
  final DateTimeComponents? match;
  final String? payload;
}

/// 实际用了哪种调度方式
enum ScheduleMode { exact, inexact }

/// 通知能力的抽象：Android/iOS 用本地通知插件实现，Windows 等平台用空实现，测试用假实现。
abstract interface class ReminderScheduler {
  /// 这个平台是否支持定时提醒
  bool get supported;

  /// 初始化插件；[onTap] 在 App 运行中点击通知时调用
  Future<void> init({required void Function(String? payload) onTap});

  /// 如果 App 是被点通知冷启动的，返回那条通知的 payload
  Future<String?> launchPayload();

  /// 安排一条提醒。有精确闹钟权限时精确调度，否则降级为不精确调度。
  Future<ScheduleMode> schedule(ReminderRequest request);

  Future<void> cancel(int id);

  /// 取消所有待触发的提醒，并移除通知栏里已显示的通知
  Future<void> cancelAll();

  /// 只取消待触发的提醒，不动通知栏里已经弹出的通知（全量重建时用）
  Future<void> cancelAllPending();

  /// null = 无法判断（平台不支持）
  Future<bool?> notificationsEnabled();

  /// 弹系统授权框（Android 13+）。返回是否已授权
  Future<bool> requestNotificationPermission();

  /// null = 平台不需要这个权限
  Future<bool?> canScheduleExact();

  /// 打开系统的「闹钟和提醒」授权页
  Future<void> requestExactAlarmPermission();

  /// 立即显示一条通知（测试用）
  Future<void> showNow({required int id, required String title, String? body});
}
