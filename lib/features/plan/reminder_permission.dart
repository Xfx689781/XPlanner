import 'package:flutter/material.dart';

import '../../core/notifications/reminder_scheduler.dart';
import '../../l10n/generated/app_localizations.dart';

/// 用户第一次设提醒时在场景里申请通知权限（而不是一启动就弹）。
/// 返回 false 表示权限仍未开启。
Future<bool> ensureNotificationPermission(ReminderScheduler scheduler) async {
  if (!scheduler.supported) return true;
  final enabled = await scheduler.notificationsEnabled();
  if (enabled != false) return true;
  return scheduler.requestNotificationPermission();
}

/// 保存带提醒的任务后，根据结果给出提示。
void showReminderOutcome(
  ScaffoldMessengerState messenger, {
  required bool permissionGranted,
  required ScheduleMode? mode,
  required VoidCallback openExactSettings,
  required AppLocalizations l10n,
}) {
  final String? message;
  SnackBarAction? action;
  if (!permissionGranted) {
    message = l10n.reminderPermissionDenied;
  } else if (mode == ScheduleMode.inexact) {
    message = l10n.reminderInexactNotice;
    action = SnackBarAction(label: l10n.commonTurnOn, onPressed: openExactSettings);
  } else {
    message = null;
  }
  if (message == null) return;
  messenger.showSnackBar(SnackBar(content: Text(message), action: action));
}
