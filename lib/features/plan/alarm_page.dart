import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/app_database.dart';
import '../../core/data/data_providers.dart';
import '../../core/notifications/background_actions.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/notification_tap_handler.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/format.dart';
import '../../core/utils/system_settings.dart';
import '../../design_system/design_system.dart';
import '../../l10n/locale_providers.dart';
import 'task_labels.dart';

/// 全屏闹钟页：锁屏时由全屏通知拉起，或 App 在前台时闹钟响起后显示。
/// 任务方块 + 标题 + 时间，两个大按钮「完成」「稍后 10 分钟」。按完停止响铃。
class AlarmPage extends ConsumerStatefulWidget {
  const AlarmPage({super.key, required this.request});

  final AlarmRequest request;

  static Future<void> open(BuildContext context, AlarmRequest request) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Motion.standard,
        pageBuilder: (_, _, _) => AlarmPage(request: request),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  ConsumerState<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends ConsumerState<AlarmPage> {
  late final SystemSettings _system;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _system = ref.read(systemSettingsProvider);
    // 只在闹钟页显示期间允许出现在锁屏上方
    _system.setShowOnLockScreen(true);
  }

  @override
  void dispose() {
    _system.setShowOnLockScreen(false);
    super.dispose();
  }

  Future<void> _act(String actionId) async {
    if (_busy) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final scheduler = ref.read(reminderSchedulerProvider);
    try {
      // 先停止响铃，再改任务、重排提醒
      await scheduler.cancel(widget.request.notificationId);
      await applyNotificationAction(
        actionId: actionId,
        taskId: widget.request.taskId,
        repository: ref.read(taskRepositoryProvider),
        sync: ref.read(reminderSyncProvider),
        clock: ref.read(clockProvider),
      );
    } finally {
      if (widget.request.fromLockScreen) {
        // 从锁屏拉起：处理完回到锁屏，不停留在 App 里
        await SystemNavigator.pop();
      } else if (mounted) {
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = AppDateFormat.of(context);
    final task = ref.watch(_taskProvider(widget.request.taskId)).value;
    final time = task?.reminderAt == null ? '' : dates.time(task!.reminderAt!);

    return Scaffold(
      body: SafeArea(
        child: Semantics(
          label: task == null ? null : l10n.alarmPageSemantics(task.title, time),
          child: Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                if (task != null) ...[
                  Center(
                    child: TaskSquare(
                      done: false,
                      strokeWidth: strokeForPriority(task.priority),
                      size: Sizes.alarmSquare,
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  Text(time, textAlign: TextAlign.center, style: context.text.title),
                  const SizedBox(height: Space.s),
                  Text(task.title, textAlign: TextAlign.center, style: context.text.body),
                ],
                const Spacer(),
                GeoButton(
                  label: l10n.notificationActionDone,
                  style: GeoButtonStyle.primary,
                  large: true,
                  onPressed: _busy ? null : () => _act(actionDone),
                ),
                const SizedBox(height: Space.m),
                GeoButton(
                  label: l10n.notificationActionSnooze,
                  style: GeoButtonStyle.outline,
                  large: true,
                  onPressed: _busy ? null : () => _act(actionSnooze),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _taskProvider = StreamProvider.family<Task?, int>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchById(id),
);
