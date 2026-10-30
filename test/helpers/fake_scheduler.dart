import 'package:facet/core/notifications/reminder_scheduler.dart';

/// 记录调用的假调度器。[pending] 模拟系统里当前挂着的提醒。
class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.supported = true, this.exactAllowed = true});

  @override
  final bool supported;

  bool exactAllowed;
  bool notificationsOn = true;
  bool throwOnSchedule = false;

  final Map<int, ReminderRequest> pending = {};
  final List<String> log = [];
  void Function(String? payload)? onTap;
  String? launch;

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    this.onTap = onTap;
  }

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<ScheduleMode> schedule(ReminderRequest request) async {
    if (throwOnSchedule) throw StateError('boom');
    log.add('schedule ${request.id}');
    pending[request.id] = request;
    return exactAllowed ? ScheduleMode.exact : ScheduleMode.inexact;
  }

  @override
  Future<void> cancel(int id) async {
    log.add('cancel $id');
    pending.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    log.add('cancelAll');
    pending.clear();
  }

  @override
  Future<bool?> notificationsEnabled() async => notificationsOn;

  @override
  Future<bool> requestNotificationPermission() async {
    log.add('requestNotificationPermission');
    return notificationsOn;
  }

  @override
  Future<bool?> canScheduleExact() async => exactAllowed;

  @override
  Future<void> requestExactAlarmPermission() async {
    log.add('requestExactAlarmPermission');
  }

  @override
  Future<void> showNow({required int id, required String title, String? body}) async {
    log.add('showNow $id');
  }
}
