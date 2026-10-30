import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_providers.dart';
import 'app_settings.dart';
import 'setting_keys.dart';
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
      _update(SettingKeys.theme, v, state.copyWith(theme: v));

  Future<void> setWeekStart(WeekStart v) =>
      _update(SettingKeys.weekStart, v, state.copyWith(weekStart: v));

  Future<void> setReminderLead(ReminderLead v) =>
      _update(SettingKeys.reminderLead, v, state.copyWith(reminderLead: v));

  Future<void> setLanguageTag(String? v) =>
      _update(SettingKeys.language, v, state.copyWith(languageTag: () => v));

  Future<void> _update<T>(SettingKey<T> key, T value, AppSettings next) async {
    final previous = state;
    if (next == previous) return;
    state = next;
    try {
      await ref.read(settingsRepositoryProvider).write(key, value);
    } catch (e) {
      debugPrint('保存设置失败（${key.name}）：$e');
      state = previous;
      rethrow;
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
