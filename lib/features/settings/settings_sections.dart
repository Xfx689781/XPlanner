import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_info.dart';
import '../../core/data/settings/settings_provider.dart';
import '../../core/notifications/reminder_status.dart';
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
  });

  final String id;
  final String title;

  /// 主页右侧显示的当前值
  final String Function(WidgetRef ref) summary;

  /// 主页上是否显示警示标记
  final bool Function(WidgetRef ref)? needsAttention;
  final WidgetBuilder content;
}

final settingsSections = <SettingsSection>[
  SettingsSection(
    id: 'general',
    title: '通用',
    summary: (ref) => '跟随系统 · ${weekStartSummary(ref.watch(settingsProvider.select((s) => s.weekStart)))}',
    content: (_) => const GeneralSection(),
  ),
  SettingsSection(
    id: 'appearance',
    title: '外观',
    summary: (ref) => themeLabel(ref.watch(settingsProvider.select((s) => s.theme))),
    content: (_) => const AppearanceSection(),
  ),
  SettingsSection(
    id: 'reminders',
    title: '提醒',
    summary: (ref) => reminderLeadLabel(ref.watch(settingsProvider.select((s) => s.reminderLead))),
    needsAttention: (ref) => remindersNeedAttention(ref.watch(reminderStatusProvider).value),
    content: (_) => const RemindersSection(),
  ),
  SettingsSection(
    id: 'about',
    title: '关于',
    summary: (_) => appVersion,
    content: (_) => const AboutSection(),
  ),
];
