import 'dart:async';

import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/settings/setting_keys.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

/// SettingsController 在写库还没完成时又改了设置（连点、或同时改两项）的行为。
void main() {
  late AppDatabase db;
  late _GatedRepo repo;
  late ProviderContainer c;

  setUp(() {
    db = openTestDb();
    repo = _GatedRepo(db);
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsRepositoryProvider.overrideWithValue(repo),
    ]);
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  SettingsController ctrl() => c.read(settingsProvider.notifier);

  test('连续改两项、写库都成功：内存和数据库一致', () async {
    final a = ctrl().setTheme(ThemePreference.dark);
    final b = ctrl().setWeekStart(WeekStart.monday);
    await Future.wait([a, b]);
    final s = c.read(settingsProvider);
    expect(s.theme, ThemePreference.dark);
    expect(s.weekStart, WeekStart.monday);
    expect(await SettingsRepository(db).load(), s);
  });

  test(
    '主题写库较慢且失败、期间一周开始日已成功保存：失败回滚不应把一周开始日也改回去',
    () async {
      repo.gate['theme'] = Completer<void>();
      final theme = ctrl().setTheme(ThemePreference.dark);
      await ctrl().setWeekStart(WeekStart.monday); // 这次写库成功
      repo.gate['theme']!.completeError(StateError('disk full'));
      await expectLater(theme, throwsStateError);

      // 数据库里一周开始日是周一
      expect((await SettingsRepository(db).load()).weekStart, WeekStart.monday);
      // 内存（界面）也应是周一、主题回到跟随系统
      final s = c.read(settingsProvider);
      expect(s.theme, ThemePreference.system);
      expect(s.weekStart, WeekStart.monday);
    }
  );

  test(
    '同一项连点：深色（慢、失败）→ 浅色（成功）：最终应保持浅色',
    () async {
      repo.gate['theme'] = Completer<void>();
      final dark = ctrl().setTheme(ThemePreference.dark);
      repo.passThrough = true; // 后面这次直接写库
      await ctrl().setTheme(ThemePreference.light);
      repo.gate['theme']!.completeError(StateError('disk full'));
      await expectLater(dark, throwsStateError);

      expect(await SettingsRepository(db).raw('theme'), 'light');
      expect(c.read(settingsProvider).theme, ThemePreference.light);
    }
  );
}

/// 可以让某个键的写入挂起，之后成功或失败。
class _GatedRepo extends SettingsRepository {
  _GatedRepo(super.db);

  final Map<String, Completer<void>> gate = {};
  bool passThrough = false;

  @override
  Future<void> write<T>(SettingKey<T> key, T value) async {
    final g = gate[key.name];
    if (g != null && !passThrough) {
      await g.future; // 失败时这里抛出
    }
    await super.write(key, value);
  }
}
