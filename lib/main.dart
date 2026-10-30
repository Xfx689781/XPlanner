import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/notifications/notification_ids.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/noop_reminder_scheduler.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'core/utils/timezone_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalTimezone();

  final scheduler = await _initScheduler();
  final container = ProviderContainer(
    overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
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

  runApp(UncontrolledProviderScope(container: container, child: const FacetApp()));

  // 兜底：按数据库重建所有提醒
  unawaited(container.read(reminderSyncProvider).resyncAll());
}

void Function(String? payload)? _onNotificationTap;

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
