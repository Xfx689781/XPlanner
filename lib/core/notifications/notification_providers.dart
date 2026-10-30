import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_providers.dart';
import '../utils/clock.dart';
import 'local_notification_scheduler.dart';
import 'noop_reminder_scheduler.dart';
import 'reminder_scheduler.dart';
import 'reminder_sync_service.dart';

/// 按平台选择实现：Android / iOS 用本地通知，其他平台（MVP 的 Windows）不支持。
ReminderScheduler createPlatformScheduler() {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return LocalNotificationScheduler();
  }
  return const NoopReminderScheduler();
}

/// main 里用初始化好的实例 override；测试里换成假实现。默认不做任何事。
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => const NoopReminderScheduler(),
);

final reminderSyncProvider = Provider<ReminderSyncService>(
  (ref) => ReminderSyncService(
    scheduler: ref.watch(reminderSchedulerProvider),
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// 等待打开的任务 id：点通知后设置，外壳打开对应任务后清空。
class PendingNavigation extends Notifier<int?> {
  @override
  int? build() => null;

  void open(int taskId) => state = taskId;

  void clear() => state = null;
}

final pendingNavigationProvider = NotifierProvider<PendingNavigation, int?>(PendingNavigation.new);
