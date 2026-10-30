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
import '../../../l10n/locale_providers.dart';
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceSetting<ReminderLead>(
          title: l10n.settingsReminderLead,
          value: lead,
          options: [for (final l in ReminderLead.values) GeoOption(value: l, label: reminderLeadLabel(l10n, l))],
          onChanged: (l) => saveSetting(context, () => ref.read(settingsProvider.notifier).setReminderLead(l)),
        ),
        SectionHeader(l10n.settingsPermissionsHeader),
        if (status == null)
          const SizedBox.shrink()
        else if (!status.supported)
          SettingsParagraph(l10n.settingsUnsupported)
        else ...[
          StatusRow(
            label: l10n.settingsNotifications,
            ok: status.notificationsEnabled,
            okText: l10n.settingsNotificationsOn,
            badText: l10n.settingsNotificationsOff,
            unknownText: l10n.settingsCannotDetect,
            action: l10n.commonTurnOn,
            onAction: () => _requestNotifications(context, ref),
          ),
          StatusRow(
            label: l10n.settingsExactAlarms,
            ok: status.exactAllowed,
            okText: l10n.settingsExactOn,
            badText: l10n.settingsExactOff,
            unknownText: l10n.settingsCannotDetect,
            action: l10n.commonTurnOn,
            onAction: scheduler.requestExactAlarmPermission,
          ),
          StatusRow(
            label: l10n.settingsBattery,
            ok: status.batteryUnrestricted,
            okText: l10n.settingsBatteryOk,
            badText: l10n.settingsBatteryBad,
            unknownText: l10n.settingsCannotDetect,
            action: l10n.settingsOpenAppSettings,
            onAction: () => _openAppDetails(context, ref),
          ),
          StatusRow(
            label: l10n.settingsTimezone,
            ok: !status.timezoneGuessed,
            okText: status.timezone,
            badText: l10n.settingsTimezoneGuessed(status.timezone),
            unknownText: l10n.settingsCannotDetect,
          ),
          SettingsParagraph(l10n.settingsTimezoneNote),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GeoButton(label: l10n.settingsTestButton, onPressed: () => _testNotification(context, ref)),
            ),
          ),
          SectionHeader(l10n.settingsSamsungHeader),
          SettingsParagraph(l10n.settingsSamsungIntro),
          SettingsStep(1, l10n.settingsSamsungStep1),
          SettingsStep(2, l10n.settingsSamsungStep2),
          SettingsStep(3, l10n.settingsSamsungStep3),
          SettingsStep(4, l10n.settingsSamsungStep4),
        ],
      ],
    );
  }

  Future<void> _requestNotifications(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final systemSettings = ref.read(systemSettingsProvider);
    final granted = await ref.read(reminderSchedulerProvider).requestNotificationPermission();
    ref.invalidate(reminderStatusProvider);
    if (!granted) {
      // 用户之前拒绝过时系统不会再弹窗，只能去应用设置里开
      final opened = await systemSettings.openAppDetails();
      if (!opened) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.settingsNotificationsManual)));
      }
    }
  }

  Future<void> _openAppDetails(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final opened = await ref.read(systemSettingsProvider).openAppDetails();
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsOpenAppManual)));
    }
  }

  Future<void> _testNotification(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final now = ref.read(clockProvider).now();
    final at = tz.TZDateTime.from(now, tz.local).add(const Duration(seconds: 5));
    try {
      final mode = await ref.read(reminderSchedulerProvider).schedule(
        ReminderRequest(id: testNotificationId, title: l10n.notificationTestTitle, body: l10n.notificationTestBody, at: at),
      );
      messenger.showSnackBar(SnackBar(
        content: Text(mode == ScheduleMode.exact ? l10n.settingsTestScheduledExact : l10n.settingsTestScheduledInexact),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsTestFailed('$e'))));
    }
  }
}
