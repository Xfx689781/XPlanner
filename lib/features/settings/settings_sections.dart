import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_info.dart';
import '../../core/data/settings/settings_provider.dart';
import '../../core/notifications/reminder_status.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/locale_providers.dart';
import '../../l10n/supported_locales.dart';
import 'sections/about_section.dart';
import 'sections/appearance_section.dart';
import 'sections/general_section.dart';
import 'sections/reminders_section.dart';
import 'settings_labels.dart';

/// 设置中心的一个分组。新增分组：在 [settingsSections] 里加一项；
/// 新增设置项：在对应分组的内容组件里加一个 ChoiceSetting / StatusRow 等。
class SettingsSection {
  const SettingsSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    this.needsAttention,
    this.attentionLabel,
  });

  final String id;
  final String Function(AppLocalizations l10n) title;

  /// 主页右侧显示的当前值
  final String Function(AppLocalizations l10n, WidgetRef ref) summary;

  /// 主页上是否显示警示标记
  final bool Function(WidgetRef ref)? needsAttention;

  /// 警示的读屏文字：说明要处理什么
  final String Function(AppLocalizations l10n)? attentionLabel;
  final WidgetBuilder content;
}

String _generalSummary(AppLocalizations l10n, WidgetRef ref) {
  final settings = ref.watch(settingsProvider);
  final language = languageByTag(settings.languageTag)?.autonym ?? l10n.languageFollowSystem;
  final intlLocale = ref.watch(appLanguageProvider).intlLocale;
  return l10n.settingsGeneralSummary(language, weekStartSummary(l10n, settings.weekStart, intlLocale));
}

final settingsSections = <SettingsSection>[
  SettingsSection(
    id: 'general',
    title: (l10n) => l10n.settingsSectionGeneral,
    summary: _generalSummary,
    content: (_) => const GeneralSection(),
  ),
  SettingsSection(
    id: 'appearance',
    title: (l10n) => l10n.settingsSectionAppearance,
    summary: (l10n, ref) {
      final (theme, accent) = ref.watch(settingsProvider.select((s) => (s.theme, s.accent)));
      return l10n.settingsAppearanceSummary(themeLabel(l10n, theme), accentLabel(l10n, accent));
    },
    content: (_) => const AppearanceSection(),
  ),
  SettingsSection(
    id: 'reminders',
    title: (l10n) => l10n.settingsSectionReminders,
    summary: (l10n, ref) => reminderLeadLabel(l10n, ref.watch(settingsProvider.select((s) => s.reminderLead))),
    needsAttention: (ref) => remindersNeedAttention(ref.watch(reminderStatusProvider).value),
    attentionLabel: (l10n) => l10n.settingsRemindersAttention,
    content: (_) => const RemindersSection(),
  ),
  SettingsSection(
    id: 'about',
    title: (l10n) => l10n.settingsSectionAbout,
    summary: (_, _) => appVersion,
    content: (_) => const AboutSection(),
  ),
];
