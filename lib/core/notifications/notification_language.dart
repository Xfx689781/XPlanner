import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/locale_providers.dart';
import '../../l10n/supported_locales.dart';
import 'notification_providers.dart';

/// 按界面语言设置通知渠道的名称和描述（显示在系统设置里）。
/// [language] 为空时用当前语言。
Future<void> configureNotificationChannel(ProviderContainer container, [AppLanguage? language]) async {
  final l10n = language == null
      ? container.read(appLocalizationsProvider)
      : lookupAppLocalizations(language.locale);
  try {
    final scheduler = container.read(reminderSchedulerProvider);
    await scheduler.configureChannel(
      name: l10n.notificationChannelName,
      description: l10n.notificationChannelDescription,
    );
    await scheduler.configureAlarm(
      name: l10n.alarmChannelName,
      description: l10n.alarmChannelDescription,
      doneLabel: l10n.notificationActionDone,
      snoozeLabel: l10n.notificationActionSnooze,
    );
  } catch (e) {
    debugPrint('设置通知渠道失败：$e');
  }
}

/// 界面语言变化时（手动选择，或"跟随系统"时系统语言变了）：更新渠道名，并重排已安排的提醒。
/// 返回的 subscription 在测试里用来取消监听。
ProviderSubscription<AppLanguage> listenLanguageForNotifications(ProviderContainer container) {
  return container.listen<AppLanguage>(appLanguageProvider, (previous, next) {
    if (previous?.tag == next.tag) return;
    unawaited(() async {
      // 用回调传进来的新语言：此刻 appLocalizationsProvider 可能还没更新
      await configureNotificationChannel(container, next);
      await container.read(reminderSyncProvider).resyncAll();
    }());
  });
}
