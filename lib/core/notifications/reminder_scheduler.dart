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
    this.alarm = false,
  });

  final int id;
  final String title;
  final String? body;
  final tz.TZDateTime at;
  final DateTimeComponents? match;
  final String? payload;

  /// 闹钟方式：闹钟渠道、持续响铃、全屏（有权限时）、带「完成 / 稍后」按钮
  final bool alarm;
}

/// 一次通知点按：点通知本身时 [actionId] 为空；点「完成 / 稍后」按钮时是按钮 id
class NotificationTap {
  const NotificationTap({this.payload, this.actionId, this.notificationId});

  final String? payload;
  final String? actionId;
  final int? notificationId;
}

/// 实际用了哪种调度方式
enum ScheduleMode { exact, inexact }

/// 通知能力的抽象：Android/iOS 用本地通知插件实现，Windows 等平台用空实现，测试用假实现。
abstract interface class ReminderScheduler {
  /// 这个平台是否支持定时提醒
  bool get supported;

  /// 初始化插件；[onTap] 在 App 运行中点击通知（或通知上的按钮）时调用
  Future<void> init({required void Function(NotificationTap tap) onTap});

  /// 如果 App 是被点通知（或全屏闹钟）冷启动的，返回那次点按
  Future<NotificationTap?> launchTap();

  /// 这条通知是否还在通知栏里（闹钟还在响）
  Future<bool> isShowing(int id);

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

  /// 设置通知渠道的名称和描述（系统设置里可见），按当前界面语言
  Future<void> configureChannel({required String name, required String description});

  /// 设置闹钟渠道的名称、描述和通知按钮文字，按当前界面语言
  Future<void> configureAlarm({
    required String name,
    required String description,
    required String doneLabel,
    required String snoozeLabel,
  });

  /// 打开系统的"全屏通知"授权页（Android 14+）
  Future<void> requestFullScreenPermission();

  /// 立即显示一条通知（测试用）
  Future<void> showNow({required int id, required String title, String? body});
}
