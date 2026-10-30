import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/data/settings/settings_enums.dart';
import '../../../core/data/settings/settings_provider.dart';
import '../../../core/notifications/notification_ids.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_status.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/system_settings.dart';
import '../../../design_system/design_system.dart';
import '../settings_labels.dart';
import '../settings_widgets.dart';

/// 提醒分组是否需要用户处理：通知权限或闹钟权限没开（电池状态部分机型检测不到，不算在内）。
bool remindersNeedAttention(ReminderStatus? s) =>
    s != null && s.supported && (s.notificationsMissing || s.exactMissing);

class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(reminderStatusProvider).value;
    final lead = ref.watch(settingsProvider.select((s) => s.reminderLead));
    final scheduler = ref.read(reminderSchedulerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceSetting<ReminderLead>(
          title: '新建提醒时默认',
          value: lead,
          options: [for (final l in ReminderLead.values) GeoOption(value: l, label: reminderLeadLabel(l))],
          onChanged: (l) => saveSetting(context, () => ref.read(settingsProvider.notifier).setReminderLead(l)),
        ),
        const SectionHeader('权限与状态'),
        if (status == null)
          const SizedBox.shrink()
        else if (!status.supported)
          const SettingsParagraph('这个平台暂不支持提醒。任务和提醒时间会正常保存，在手机上会按时弹出。')
        else ...[
          StatusRow(
            label: '通知权限',
            ok: status.notificationsEnabled,
            okText: '已开启',
            badText: '未开启，提醒不会弹出',
            action: '开启',
            onAction: () => _requestNotifications(context, ref),
          ),
          StatusRow(
            label: '闹钟和提醒',
            ok: status.exactAllowed,
            okText: '已开启，提醒准时',
            badText: '未开启，提醒可能晚几分钟到十几分钟',
            action: '去开启',
            onAction: scheduler.requestExactAlarmPermission,
          ),
          StatusRow(
            label: '电池',
            ok: status.batteryUnrestricted,
            okText: '不受限制',
            badText: '可能被省电策略拦截',
            action: '打开应用设置',
            onAction: () => _openAppDetails(context, ref),
          ),
          StatusRow(
            label: '时区',
            ok: !status.timezoneGuessed,
            okText: status.timezone,
            badText: '${status.timezone}（没取到系统时区，按时差推测，提醒可能差一小时）',
          ),
          const SettingsParagraph('提醒按当地钟点：换了时区后请打开一次 Facet，提醒会改按新时区的钟点响。'),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GeoButton(label: '5 秒后发一条测试通知', onPressed: () => _testNotification(context, ref)),
            ),
          ),
          const SectionHeader('三星手机：防止提醒被拦截'),
          const SettingsParagraph('三星的省电策略可能在后台拦截提醒。建议按下面设置一次：'),
          const SettingsStep(1, '设置 → 应用 → Facet → 电池 → 选「不受限制」。上面「打开应用设置」可以直接跳到这里。'),
          const SettingsStep(2, '设置 → 电池 → 后台使用限制：确认 Facet 不在「休眠应用」或「深度休眠应用」里；可以把它加入「永不休眠的应用」。'),
          const SettingsStep(3, '设置 → 应用 → Facet → 通知：允许通知，并打开「锁定屏幕」上的显示。'),
          const SettingsStep(4, '长时间不打开的 App 可能被系统自动放进休眠列表，如果某天提醒不响了，回来检查第 2 步。'),
        ],
      ],
    );
  }

  Future<void> _requestNotifications(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final systemSettings = ref.read(systemSettingsProvider);
    final granted = await ref.read(reminderSchedulerProvider).requestNotificationPermission();
    ref.invalidate(reminderStatusProvider);
    if (!granted) {
      // 用户之前拒绝过时系统不会再弹窗，只能去应用设置里开
      final opened = await systemSettings.openAppDetails();
      if (!opened) {
        messenger.showSnackBar(const SnackBar(content: Text('请在系统设置 → 应用 → Facet → 通知 中开启')));
      }
    }
  }

  Future<void> _openAppDetails(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref.read(systemSettingsProvider).openAppDetails();
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text('请手动打开 设置 → 应用 → Facet')));
    }
  }

  Future<void> _testNotification(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = ref.read(clockProvider).now();
    final at = tz.TZDateTime.from(now, tz.local).add(const Duration(seconds: 5));
    try {
      final mode = await ref.read(reminderSchedulerProvider).schedule(
        ReminderRequest(id: testNotificationId, title: 'Facet 测试提醒', body: '能看到这条，说明提醒正常', at: at),
      );
      messenger.showSnackBar(SnackBar(
        content: Text(mode == ScheduleMode.exact ? '5 秒后会弹出一条通知，可以先锁屏' : '已安排（不精确模式，可能晚一些才弹出）'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('安排失败：$e')));
    }
  }
}
