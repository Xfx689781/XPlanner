import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'background_actions.dart';
import 'reminder_scheduler.dart';

/// 基于 flutter_local_notifications 的实现（Android；iOS 以后复用）。
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'task_reminders';

  /// 闹钟渠道：声音和重要程度创建后改不了，以后要调整就换新 id（_v2）并删除旧渠道
  static const _alarmChannelId = 'task_alarms_v1';
  static const _icon = 'ic_stat_facet';

  /// 系统闹钟铃声
  static const _alarmSound = UriAndroidNotificationSound('content://settings/system/alarm_alert');

  /// FLAG_INSISTENT：持续响铃和震动，直到通知被点开、划掉或按了按钮
  static final _insistent = Int32List.fromList([4]);
  static final _alarmVibration = Int64List.fromList([0, 800, 600, 800]);

  /// 没人理的闹钟 10 分钟后自动停止
  static const _alarmTimeout = Duration(minutes: 10);

  // 渠道名和按钮文字显示给用户，由 configureChannel / configureAlarm 按当前语言设置（启动时、切换语言后）
  String _channelName = 'Task reminders';
  String _channelDescription = 'Reminders when a task is due';
  String _alarmName = 'Task alarms';
  String _alarmDescription = 'Keeps ringing until you tap Done or Snooze';
  String _doneLabel = 'Done';
  String _snoozeLabel = 'Snooze 10 min';

  NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: _icon,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  NotificationDetails get _alarmDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      _alarmChannelId,
      _alarmName,
      channelDescription: _alarmDescription,
      importance: Importance.max,
      priority: Priority.max,
      icon: _icon,
      category: AndroidNotificationCategory.alarm,
      // 闹钟音频通道：静音模式下也响，音量跟随系统闹钟音量
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: _alarmSound,
      enableVibration: true,
      vibrationPattern: _alarmVibration,
      additionalFlags: _insistent,
      // 锁屏时拉起全屏闹钟页；没有 USE_FULL_SCREEN_INTENT 权限时系统自动降级为横幅（仍持续响）
      fullScreenIntent: true,
      // 点横幅正文不取消通知：进入闹钟页后由按钮停止响铃（也可以直接划掉）
      autoCancel: false,
      timeoutAfter: _alarmTimeout.inMilliseconds,
      actions: [
        AndroidNotificationAction(actionDone, _doneLabel, cancelNotification: true),
        AndroidNotificationAction(actionSnooze, _snoozeLabel, cancelNotification: true),
      ],
    ),
    // iOS 不支持持续响铃和全屏页：降级为带声音的时效性通知
    iOS: const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
  );

  @override
  Future<void> configureChannel({required String name, required String description}) async {
    _channelName = name;
    _channelDescription = description;
    // 同一个 id 再创建一次会更新已有渠道的名称和描述（重要程度保持不变）
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(_channelId, name, description: description, importance: Importance.high),
    );
  }

  @override
  Future<void> configureAlarm({
    required String name,
    required String description,
    required String doneLabel,
    required String snoozeLabel,
  }) async {
    _alarmName = name;
    _alarmDescription = description;
    _doneLabel = doneLabel;
    _snoozeLabel = snoozeLabel;
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        _alarmChannelId,
        name,
        description: description,
        importance: Importance.max,
        sound: _alarmSound,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: _alarmVibration,
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  bool get supported => true;

  @override
  Future<void> init({required void Function(NotificationTap tap) onTap}) async {
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
      onDidReceiveNotificationResponse: (r) =>
          onTap(NotificationTap(payload: r.payload, actionId: r.actionId, notificationId: r.id)),
      // App 没打开时按「完成 / 稍后」：在后台 isolate 里处理
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
  }

  @override
  Future<NotificationTap?> launchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final r = details.notificationResponse;
    return r == null ? null : NotificationTap(payload: r.payload, actionId: r.actionId, notificationId: r.id);
  }

  @override
  Future<bool> isShowing(int id) async {
    final active = await _plugin.getActiveNotifications();
    return active.any((n) => n.id == id);
  }

  @override
  Future<ScheduleMode> schedule(ReminderRequest r) async {
    final exact = await canScheduleExact() ?? true;
    // 闹钟也用 exactAllowWhileIdle，不用 alarmClock：插件把 alarmClock 的"查看"入口指向触发广播，
    // 用户在状态栏 / 时钟里点"下一个闹钟"会让它提前响
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
      notificationDetails: r.alarm ? _alarmDetails : _details,
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
  Future<void> requestFullScreenPermission() async {
    // 已有权限时直接返回；没有时打开系统的"全屏通知"设置页
    await _android?.requestFullScreenIntentPermission();
  }

  @override
  Future<void> showNow({required int id, required String title, String? body}) {
    return _plugin.show(id: id, title: title, body: body, notificationDetails: _details);
  }
}
