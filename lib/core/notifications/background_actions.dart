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

/// 处理「完成 / 稍后 10 分钟」。App 在前台（[main] 的点按回调）和后台（[notificationBackgroundHandler]）共用。
/// 同步提醒时会取消这个任务的所有通知，正在响的闹钟也随之停下。
Future<void> applyNotificationAction({
  required String actionId,
  required int taskId,
  required TaskRepository repository,
  required ReminderSyncService sync,
  required Clock clock,
}) async {
  final now = clock.now();
  final task = await repository.getById(taskId);
  if (task == null) {
    await sync.cancelTask(taskId);
    return;
  }
  switch (actionId) {
    case actionDone:
      // 重复任务只完成今天；已经完成的不重复记
      final updated = task.isDoneOn(startOfDay(now)) ? task : await repository.setCompleted(taskId, now, now: now);
      await sync.syncTask(updated ?? task);
    case actionSnooze:
      final updated = await repository.setSnoozed(taskId, now.add(ReminderSyncService.snoozeDuration));
      await sync.syncTask(updated ?? task);
  }
}

/// App 没打开（或在后台被系统杀掉）时点通知按钮：在单独的 isolate 里打开数据库并处理。
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse response) async {
  final taskId = parseTaskPayload(response.payload);
  final actionId = response.actionId;
  if (taskId == null || actionId == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  AppDatabase? db;
  try {
    await initializeDateFormatting();
    await initLocalTimezone();
    db = AppDatabase();
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
    final repository = TaskRepository(db);
    await applyNotificationAction(
      actionId: actionId,
      taskId: taskId,
      repository: repository,
      sync: ReminderSyncService(scheduler: scheduler, repository: repository, clock: const SystemClock(), dates: () => dates),
      clock: const SystemClock(),
    );
  } catch (e, s) {
    debugPrint('后台处理通知按钮失败：$e\n$s');
  } finally {
    await db?.close();
  }
}
