import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/settings/settings_provider.dart';
import 'generated/app_localizations.dart';
import 'supported_locales.dart';

/// 系统语言列表（偏好顺序）。App 收到 didChangeLocales 时更新。
class SystemLocales extends Notifier<List<Locale>> {
  @override
  List<Locale> build() => WidgetsBinding.instance.platformDispatcher.locales;

  void set(List<Locale> locales) => state = locales;
}

final systemLocalesProvider = NotifierProvider<SystemLocales, List<Locale>>(SystemLocales.new);

/// 当前界面语言 = 设置里选的语言，或跟随系统解析出的语言。
final appLanguageProvider = Provider<AppLanguage>((ref) {
  final tag = ref.watch(settingsProvider.select((s) => s.languageTag));
  return resolveLanguage(tag, ref.watch(systemLocalesProvider));
});

/// 不在 widget 树里的代码（通知渠道名等）用它取当前语言的文字。
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(appLanguageProvider).locale),
);

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
