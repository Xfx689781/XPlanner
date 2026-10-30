import 'package:flutter/foundation.dart';

import 'setting_keys.dart';
import 'settings_enums.dart';

/// 全部设置的不可变快照。新增设置项：SettingKeys 加一个键 + 这里加一个字段。
@immutable
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.accent = AccentColor.vermilion,
    this.weekStart = WeekStart.locale,
    this.reminderLead = ReminderLead.onTime,
    this.languageTag,
  });

  static const defaults = AppSettings();

  final ThemePreference theme;
  final AccentColor accent;
  final WeekStart weekStart;
  final ReminderLead reminderLead;

  /// null = 跟随系统
  final String? languageTag;

  /// 从键值表的原始行构建
  factory AppSettings.fromRaw(Map<String, String> raw) {
    return AppSettings(
      theme: SettingKeys.theme.read(raw[SettingKeys.theme.name]),
      accent: SettingKeys.accent.read(raw[SettingKeys.accent.name]),
      weekStart: SettingKeys.weekStart.read(raw[SettingKeys.weekStart.name]),
      reminderLead: SettingKeys.reminderLead.read(raw[SettingKeys.reminderLead.name]),
      languageTag: SettingKeys.language.read(raw[SettingKeys.language.name]),
    );
  }

  AppSettings copyWith({
    ThemePreference? theme,
    AccentColor? accent,
    WeekStart? weekStart,
    ReminderLead? reminderLead,
    String? Function()? languageTag,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      weekStart: weekStart ?? this.weekStart,
      reminderLead: reminderLead ?? this.reminderLead,
      languageTag: languageTag == null ? this.languageTag : languageTag(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.accent == accent &&
      other.weekStart == weekStart &&
      other.reminderLead == reminderLead &&
      other.languageTag == languageTag;

  @override
  int get hashCode => Object.hash(theme, accent, weekStart, reminderLead, languageTag);
}
