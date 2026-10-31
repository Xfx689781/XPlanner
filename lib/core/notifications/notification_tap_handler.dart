import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_providers.dart';
import '../utils/clock.dart';
import 'background_actions.dart';
import 'notification_ids.dart';
import 'notification_providers.dart';
import 'reminder_scheduler.dart';

/// 要显示的闹钟页：哪个任务、哪条通知（用来停止响铃）、是否从锁屏冷启动
@immutable
class AlarmRequest {
  const AlarmRequest({
    required this.taskId,
    required this.notificationId,
    this.fromLockScreen = false,
    this.offsetMinutes,
  });

  final int taskId;
  final int notificationId;

  /// 这条闹钟的提前量（来自 payload；稍后提醒 / 旧通知为 null），用来判断完成的是哪一天
  final int? offsetMinutes;

  /// 冷启动拉起（锁屏全屏）：处理完回到锁屏，不停留在 App 里
  final bool fromLockScreen;
}

class PendingAlarm extends Notifier<AlarmRequest?> {
  @override
  AlarmRequest? build() => null;

  void open(AlarmRequest request) => state = request;

  void clear() => state = null;
}

final pendingAlarmProvider = NotifierProvider<PendingAlarm, AlarmRequest?>(PendingAlarm.new);

/// 通知点按的分流：
/// - 点了「完成 / 稍后」按钮：直接处理（Android 上这类按钮实际由后台引擎处理，这里是 iOS 和兜底）
/// - 闹钟通知还在响（全屏 intent 拉起 App）：显示闹钟页
/// - 其他：打开任务
Future<void> handleNotificationTap(ProviderContainer container, NotificationTap tap, {bool coldStart = false}) async {
  final taskId = parseTaskPayload(tap.payload);
  if (taskId == null) return;
  final action = tap.actionId;
  if (action == actionDone || action == actionSnooze) {
    await applyNotificationAction(
      actionId: action!,
      taskId: taskId,
      repository: container.read(taskRepositoryProvider),
      sync: container.read(reminderSyncProvider),
      clock: container.read(clockProvider),
      offsetMinutes: parseReminderOffset(tap.payload),
    );
    return;
  }
  final notificationId = tap.notificationId;
  var ringing = false;
  if (isAlarmPayload(tap.payload) && notificationId != null) {
    try {
      ringing = await container.read(reminderSchedulerProvider).isShowing(notificationId);
    } catch (e) {
      debugPrint('查询通知是否仍在显示失败：$e'); // 例如 Android 6.0 以下：按普通点按打开任务
    }
  }
  if (ringing && notificationId != null) {
    container.read(pendingAlarmProvider.notifier).open(
      AlarmRequest(
        taskId: taskId,
        notificationId: notificationId,
        fromLockScreen: coldStart,
        offsetMinutes: parseReminderOffset(tap.payload),
      ),
    );
    return;
  }
  container.read(pendingNavigationProvider.notifier).open(taskId);
}
