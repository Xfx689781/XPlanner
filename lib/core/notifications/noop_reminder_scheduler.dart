import 'reminder_scheduler.dart';

/// 不支持提醒的平台（MVP 阶段的 Windows）：所有操作静默跳过。
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  bool get supported => false;

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<ScheduleMode> schedule(ReminderRequest request) async => ScheduleMode.inexact;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllPending() async {}

  @override
  Future<void> configureChannel({required String name, required String description}) async {}

  @override
  Future<bool?> notificationsEnabled() async => null;

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<bool?> canScheduleExact() async => null;

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<void> showNow({required int id, required String title, String? body}) async {}
}
