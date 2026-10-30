import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/data/app_database.dart';
import 'core/data/data_providers.dart';
import 'core/data/settings/app_settings.dart';
import 'core/data/settings/settings_provider.dart';
import 'core/data/settings/settings_repository.dart';
import 'core/notifications/notification_ids.dart';
import 'core/notifications/notification_language.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/noop_reminder_scheduler.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'core/utils/timezone_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await initLocalTimezone();

  final scheduler = await _initScheduler();
  // runApp 之前预读设置：第一帧就是保存的主题 / 语言，不闪烁。读库时会先跑迁移
  final db = AppDatabase();
  final settings = await _loadSettings(db);
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(settings),
      reminderSchedulerProvider.overrideWithValue(scheduler),
    ],
    // 本地数据库出错时重试没有意义
    retry: (_, _) => null,
  );

  void openFromPayload(String? payload) {
    final id = parseTaskPayload(payload);
    if (id != null) container.read(pendingNavigationProvider.notifier).open(id);
  }

  _onNotificationTap = openFromPayload;
  // 冷启动：App 是被点通知打开的
  try {
    openFromPayload(await scheduler.launchPayload());
  } catch (e) {
    debugPrint('读取启动通知失败：$e');
  }

  await configureNotificationChannel(container);
  runApp(UncontrolledProviderScope(container: container, child: const FacetApp()));

  // 兜底：按数据库重建所有提醒
  unawaited(container.read(reminderSyncProvider).resyncAll());

  // 切换语言后：更新渠道名，按新语言重排已安排的提醒
  listenLanguageForNotifications(container);
}

void Function(String? payload)? _onNotificationTap;

Future<AppSettings> _loadSettings(AppDatabase db) async {
  try {
    return await SettingsRepository(db).load();
  } catch (e) {
    debugPrint('读取设置失败，使用默认设置：$e');
    return AppSettings.defaults;
  }
}

/// 初始化失败时退回空实现，保证 App 能启动
Future<ReminderScheduler> _initScheduler() async {
  final scheduler = createPlatformScheduler();
  try {
    await scheduler.init(onTap: (payload) => _onNotificationTap?.call(payload));
    return scheduler;
  } catch (e) {
    debugPrint('通知初始化失败，提醒不可用：$e');
    return const NoopReminderScheduler();
  }
}
