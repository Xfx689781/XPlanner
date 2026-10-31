import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_providers.dart';
import 'app_settings.dart';
import 'setting_keys.dart';
import '../enums.dart';
import '../reminder_spec.dart';
import 'settings_enums.dart';
import 'settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// main 在 runApp 之前从数据库预读并 override，第一帧就是保存的设置（不闪烁）。
final initialSettingsProvider = Provider<AppSettings>((ref) => AppSettings.defaults);

/// 全部设置的唯一来源。主题、一周开始日、默认提前量、语言都从这里读。
/// 写入时先改内存（界面立即生效）再写库；写库失败恢复原值并把异常抛给调用方提示。
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> setTheme(ThemePreference v) =>
      _update(SettingKeys.theme, v, (s) => s.theme, (s, v) => s.copyWith(theme: v));

  Future<void> setAccent(AccentColor v) =>
      _update(SettingKeys.accent, v, (s) => s.accent, (s, v) => s.copyWith(accent: v));

  Future<void> setWeekStart(WeekStart v) =>
      _update(SettingKeys.weekStart, v, (s) => s.weekStart, (s, v) => s.copyWith(weekStart: v));

  /// 默认提前量：规范化（去重、先响的在前、最多 5 个），至少保留一个
  Future<void> setReminderOffsets(List<int> offsets) async {
    final specs = ReminderSpec.normalize([for (final m in offsets) ReminderSpec(m)], RepeatRule.none);
    if (specs.isEmpty) return;
    final normalized = [for (final s in specs) s.offsetMinutes];
    await _update(SettingKeys.reminderOffsets, normalized, (s) => s.reminderOffsets, (s, v) => s.copyWith(reminderOffsets: v));
    // 新键写成功后删掉旧版单选键
    await ref.read(settingsRepositoryProvider).remove(SettingKeys.legacyReminderLead);
  }

  Future<void> setReminderKind(ReminderKind v) =>
      _update(SettingKeys.reminderKind, v, (s) => s.reminderKind, (s, v) => s.copyWith(reminderKind: v));

  Future<void> setLanguageTag(String? v) =>
      _update(SettingKeys.language, v, (s) => s.languageTag, (s, v) => s.copyWith(languageTag: () => v));

  /// 只回滚这一项，且只在它仍是这次写入的值时回滚：
  /// 写库期间别的设置（或同一项的更新值）已经成功保存，不能被一起冲掉。
  Future<void> _update<T>(
    SettingKey<T> key,
    T value,
    T Function(AppSettings) read,
    AppSettings Function(AppSettings, T) apply,
  ) async {
    final previous = read(state);
    if (previous == value) return;
    state = apply(state, value);
    try {
      await ref.read(settingsRepositoryProvider).write(key, value);
    } catch (e) {
      debugPrint('保存设置失败（${key.name}）：$e');
      if (read(state) == value) state = apply(state, previous);
      rethrow;
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
