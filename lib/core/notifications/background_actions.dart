import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/supported_locales.dart';
import '../data/app_database.dart';
import '../data/settings/settings_repository.dart';
import '../data/task_repository.dart';
import '../data/task_rules.dart';
import '../utils/clock.dart';
import '../utils/date_utils.dart';
import '../utils/format.dart';
import '../utils/timezone_setup.dart';
import 'local_notification_scheduler.dart';
import 'notification_ids.dart';
import 'reminder_sync_service.dart';

/// 通知 / 全屏闹钟上的按钮 id
const actionDone = 'done';
const actionSnooze = 'snooze';

/// 只把「完成 / 稍后 10 分钟」写进数据库，不排提醒。返回更新后的任务（任务已删除时为 null）。
Future<Task?> recordNotificationAction({
  required String actionId,
  required int taskId,
  required TaskRepository repository,
  required Clock clock,
}) async {
  final now = clock.now();
  final task = await repository.getById(taskId);
  if (task == null) return null;
  return switch (actionId) {
    // 重复任务只完成今天；已经完成的不重复记
    actionDone => task.isDoneOn(startOfDay(now)) ? task : await repository.setCompleted(taskId, now, now: now),
    actionSnooze => await repository.setSnoozed(taskId, now.add(ReminderSyncService.snoozeDuration)),
    _ => task,
  };
}

/// 处理「完成 / 稍后 10 分钟」：写数据库并重排提醒。闹钟页和测试使用；
/// 通知上的按钮在 Android 上总是由 [notificationBackgroundHandler] 处理（插件把不打开界面的按钮
/// 一律交给后台引擎，不管 App 是否在前台）。
/// 同步提醒时会取消这个任务的所有通知，正在响的闹钟也随之停下。
Future<void> applyNotificationAction({
  required String actionId,
  required int taskId,
  required TaskRepository repository,
  required ReminderSyncService sync,
  required Clock clock,
}) async {
  if (actionId != actionDone && actionId != actionSnooze) return;
  final updated = await recordNotificationAction(actionId: actionId, taskId: taskId, repository: repository, clock: clock);
  if (updated == null) {
    await sync.cancelTask(taskId);
  } else {
    await sync.syncTask(updated);
  }
}

/// App 没打开（或在后台被系统杀掉）时点通知按钮：在单独的 isolate 里打开数据库并处理。
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse response) async {
  final taskId = parseTaskPayload(response.payload);
  final actionId = response.actionId;
  if (taskId == null || actionId == null || (actionId != actionDone && actionId != actionSnooze)) return;

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  AppDatabase? db;
  try {
    db = AppDatabase();
    // 先把用户的操作写进数据库：接收器不会等我们，进程随时可能被回收。
    // 写进去之后，即使后面没来得及重排，下次启动的全量重建也会按数据库补上
    final repository = TaskRepository(db);
    await recordNotificationAction(actionId: actionId, taskId: taskId, repository: repository, clock: const SystemClock());

    await initializeDateFormatting();
    await initLocalTimezone();
    // 按用户设置的语言生成通知文字（重排时用）
    final settings = await SettingsRepository(db).load();
    final dispatcher = PlatformDispatcher.instance;
    final language = resolveLanguage(settings.languageTag, dispatcher.locales);
    final l10n = lookupAppLocalizations(language.locale);
    final dates = AppDateFormat(l10n, language.intlLocale, use24h: dispatcher.alwaysUse24HourFormat);

    final scheduler = LocalNotificationScheduler();
    await scheduler.configureChannel(name: l10n.notificationChannelName, description: l10n.notificationChannelDescription);
    await scheduler.configureAlarm(
      name: l10n.alarmChannelName,
      description: l10n.alarmChannelDescription,
      doneLabel: l10n.notificationActionDone,
      snoozeLabel: l10n.notificationActionSnooze,
    );
    final task = await repository.getById(taskId);
    final sync = ReminderSyncService(scheduler: scheduler, repository: repository, clock: const SystemClock(), dates: () => dates);
    if (task == null) {
      await sync.cancelTask(taskId);
    } else {
      await sync.syncTask(task);
    }
  } catch (e, s) {
    debugPrint('后台处理通知按钮失败：$e\n$s');
  } finally {
    await db?.close();
  }
}
