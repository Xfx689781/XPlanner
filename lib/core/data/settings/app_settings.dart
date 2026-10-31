import 'package:flutter/foundation.dart';

import '../enums.dart';
import 'setting_keys.dart';
import 'settings_enums.dart';

/// 全部设置的不可变快照。新增设置项：SettingKeys 加一个键 + 这里加一个字段。
@immutable
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.accent = AccentColor.vermilion,
    this.weekStart = WeekStart.locale,
    this.reminderOffsets = const [0],
    this.reminderKind = ReminderKind.notification,
    this.languageTag,
  });

  static const defaults = AppSettings();

  final ThemePreference theme;
  final AccentColor accent;
  final WeekStart weekStart;
  /// 新建提醒时默认选中的提前量（分钟，先响的在前，最多 5 个）
  final List<int> reminderOffsets;

  /// 新建提醒时的默认方式
  final ReminderKind reminderKind;

  /// null = 跟随系统
  final String? languageTag;

  /// 从键值表的原始行构建
  factory AppSettings.fromRaw(Map<String, String> raw) {
    return AppSettings(
      theme: SettingKeys.theme.read(raw[SettingKeys.theme.name]),
      accent: SettingKeys.accent.read(raw[SettingKeys.accent.name]),
      weekStart: SettingKeys.weekStart.read(raw[SettingKeys.weekStart.name]),
      reminderOffsets: raw[SettingKeys.reminderOffsets.name] != null
          ? SettingKeys.reminderOffsets.read(raw[SettingKeys.reminderOffsets.name])
          : decodeLegacyReminderLead(raw[SettingKeys.legacyReminderLead]) ?? SettingKeys.reminderOffsets.defaultValue,
      reminderKind: SettingKeys.reminderKind.read(raw[SettingKeys.reminderKind.name]),
      languageTag: SettingKeys.language.read(raw[SettingKeys.language.name]),
    );
  }

  AppSettings copyWith({
    ThemePreference? theme,
    AccentColor? accent,
    WeekStart? weekStart,
    List<int>? reminderOffsets,
    ReminderKind? reminderKind,
    String? Function()? languageTag,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      weekStart: weekStart ?? this.weekStart,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      reminderKind: reminderKind ?? this.reminderKind,
      languageTag: languageTag == null ? this.languageTag : languageTag(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.accent == accent &&
      other.weekStart == weekStart &&
      listEquals(other.reminderOffsets, reminderOffsets) &&
      other.reminderKind == reminderKind &&
      other.languageTag == languageTag;

  @override
  int get hashCode => Object.hash(theme, accent, weekStart, Object.hashAll(reminderOffsets), reminderKind, languageTag);
}
