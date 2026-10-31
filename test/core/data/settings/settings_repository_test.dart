import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/setting_keys.dart';
import 'package:facet/core/data/settings/settings_enums.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = openTestDb();
    repo = SettingsRepository(db);
  });
  tearDown(() => db.close());

  test('空表读出默认值', () async {
    expect(await repo.load(), AppSettings.defaults);
  });

  test('写入后读出一致；用同一个数据库新建仓库（模拟重启）仍在', () async {
    await repo.write(SettingKeys.theme, ThemePreference.dark);
    await repo.write(SettingKeys.weekStart, WeekStart.monday);
    await repo.write(SettingKeys.reminderOffsets, [1440, 15]);
    await repo.write(SettingKeys.reminderKind, ReminderKind.alarm);
    await repo.write(SettingKeys.language, 'zh-Hant');

    final reloaded = await SettingsRepository(db).load();
    expect(reloaded.theme, ThemePreference.dark);
    expect(reloaded.weekStart, WeekStart.monday);
    expect(reloaded.reminderOffsets, [1440, 15]);
    expect(reloaded.reminderKind, ReminderKind.alarm);
    expect(reloaded.languageTag, 'zh-Hant');
  });

  test('写回默认值时删除该行', () async {
    await repo.write(SettingKeys.theme, ThemePreference.light);
    expect(await repo.raw('theme'), 'light');
    await repo.write(SettingKeys.theme, ThemePreference.system);
    expect(await repo.raw('theme'), isNull);

    await repo.write(SettingKeys.language, 'en');
    await repo.write(SettingKeys.language, null);
    expect(await repo.raw('language'), isNull);
  });

  test('非法值按默认值处理，不抛异常', () async {
    await db.into(db.settingEntries).insert(SettingEntriesCompanion.insert(key: 'theme', value: 'purple'));
    await db.into(db.settingEntries).insert(SettingEntriesCompanion.insert(key: 'reminderLeadMinutes', value: '7'));
    await db.into(db.settingEntries).insert(SettingEntriesCompanion.insert(key: 'weekStart', value: ''));
    expect(await repo.load(), AppSettings.defaults);
  });

  test('提前量按分钟数存储', () async {
    await repo.write(SettingKeys.reminderOffsets, [60, 5]);
    expect(await repo.raw('reminderDefaultOffsets'), '60,5');
    // 写回默认值 [0] 时删除该行（列表按编码值比较）
    await repo.write(SettingKeys.reminderOffsets, [0]);
    expect(await repo.raw('reminderDefaultOffsets'), isNull);
  });

  test('兼容旧版单选：reminderLeadMinutes=15 读成 [15]；写新值后删除旧键', () async {
    await db.into(db.settingEntries).insert(SettingEntriesCompanion.insert(key: 'reminderLeadMinutes', value: '15'));
    expect((await repo.load()).reminderOffsets, [15]);

    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(await repo.load()),
    ]);
    addTearDown(c.dispose);
    await c.read(settingsProvider.notifier).setReminderOffsets([15, 1440, 15]);
    expect(c.read(settingsProvider).reminderOffsets, [1440, 15]); // 去重、先响的在前
    expect(await repo.raw('reminderLeadMinutes'), isNull);
    expect((await repo.load()).reminderOffsets, [1440, 15]);
  });

  test('默认提前量最多 5 个，全部清空时不保存', () async {
    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(settingsProvider.notifier).setReminderOffsets([0, 5, 10, 15, 30, 60, 120]);
    expect(c.read(settingsProvider).reminderOffsets, hasLength(5));
    await c.read(settingsProvider.notifier).setReminderOffsets([]);
    expect(c.read(settingsProvider).reminderOffsets, hasLength(5));
  });

  group('SettingsController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    });
    tearDown(() => container.dispose());

    test('初始值来自 initialSettingsProvider', () {
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(const AppSettings(theme: ThemePreference.dark)),
      ]);
      addTearDown(c.dispose);
      expect(c.read(settingsProvider).theme, ThemePreference.dark);
    });

    test('设置立即生效并写入数据库', () async {
      final f = container.read(settingsProvider.notifier).setTheme(ThemePreference.light);
      expect(container.read(settingsProvider).theme, ThemePreference.light);
      await f;
      expect((await repo.load()).theme, ThemePreference.light);
    });

    test('写库失败：恢复原值并抛出', () async {
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(_FailingRepo(db)),
      ]);
      addTearDown(c.dispose);
      await expectLater(c.read(settingsProvider.notifier).setReminderOffsets([5]), throwsStateError);
      expect(c.read(settingsProvider).reminderOffsets, [0]);
    });
  });
}

class _FailingRepo extends SettingsRepository {
  _FailingRepo(super.db);

  @override
  Future<void> write<T>(SettingKey<T> key, T value) async => throw StateError('disk full');
}
