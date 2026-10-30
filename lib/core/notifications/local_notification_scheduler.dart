import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'reminder_scheduler.dart';

/// 基于 flutter_local_notifications 的实现（Android；iOS 以后复用）。
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'task_reminders';
  static const _channelName = '任务提醒';
  static const _icon = 'ic_stat_facet';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '任务到点时的提醒',
      importance: Importance.high,
      priority: Priority.high,
      icon: _icon,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  bool get supported => true;

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        // 权限在用户第一次设提醒时再申请
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => onTap(r.payload),
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<ScheduleMode> schedule(ReminderRequest r) async {
    final exact = await canScheduleExact() ?? true;
    try {
      await _zoned(r, exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle);
      return exact ? ScheduleMode.exact : ScheduleMode.inexact;
    } on PlatformException catch (e) {
      // 查询和调度之间权限被收回：降级重试一次
      if (exact && e.code == 'exact_alarms_not_permitted') {
        await _zoned(r, AndroidScheduleMode.inexactAllowWhileIdle);
        return ScheduleMode.inexact;
      }
      rethrow;
    }
  }

  Future<void> _zoned(ReminderRequest r, AndroidScheduleMode mode) {
    return _plugin.zonedSchedule(
      id: r.id,
      scheduledDate: r.at,
      notificationDetails: _details,
      androidScheduleMode: mode,
      title: r.title,
      body: r.body,
      payload: r.payload,
      matchDateTimeComponents: r.match,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> cancelAllPending() => _plugin.cancelAllPendingNotifications();

  @override
  Future<bool?> notificationsEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return _android?.areNotificationsEnabled();
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<bool?> canScheduleExact() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return _android?.canScheduleExactNotifications();
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> showNow({required int id, required String title, String? body}) {
    return _plugin.show(id: id, title: title, body: body, notificationDetails: _details);
  }
}
