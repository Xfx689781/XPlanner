import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/enums.dart';
import 'package:facet/core/data/settings/setting_keys.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/core/data/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

/// 默认提前量：旧单选键 reminderLeadMinutes 与新多选键 reminderDefaultOffsets 的兼容。
void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = openTestDb();
    repo = SettingsRepository(db);
  });
  tearDown(() => db.close());

  Future<void> put(String key, String value) =>
      db.into(db.settingEntries).insertOnConflictUpdate(SettingEntriesCompanion.insert(key: key, value: value));

  Future<ProviderContainer> container() async {
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(await repo.load()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  for (final (raw, expected) in [('5', [5]), ('15', [15]), ('0', [0])]) {
    test('旧键 reminderLeadMinutes=$raw → $expected', () async {
      await put(SettingKeys.legacyReminderLead, raw);
      expect((await repo.load()).reminderOffsets, expected);
    });
  }

  test('旧键不是 0/5/15（例如 30、空串、abc）：按默认 [0]', () async {
    for (final raw in ['30', '', 'abc', '-5']) {
      await put(SettingKeys.legacyReminderLead, raw);
      expect((await repo.load()).reminderOffsets, [0], reason: raw);
    }
  });

  test('新旧键并存：以新键为准', () async {
    await put(SettingKeys.legacyReminderLead, '5');
    await put(SettingKeys.reminderOffsets.name, '1440,60');
    expect((await repo.load()).reminderOffsets, [1440, 60]);
  });

  test('新键全是非法值、旧键合法：新键按默认 [0]（不退回旧键）', () async {
    await put(SettingKeys.legacyReminderLead, '15');
    await put(SettingKeys.reminderOffsets.name, 'abc,-1,99999');
    expect((await repo.load()).reminderOffsets, [0]);
  });

  test('新键解析时规范化：去重、去掉非法值、先响的在前、最多 5 个', () async {
    await put(SettingKeys.reminderOffsets.name, ' 15, 0,15,abc,43201,1440,5,10,30');
    expect((await repo.load()).reminderOffsets, [1440, 30, 15, 10, 5]);
  });

  test('写新键后旧键被删除（含写回默认值 [0] 时：两个键都不在，读出 [0]）', () async {
    await put(SettingKeys.legacyReminderLead, '5');
    final c = await container();
    expect(c.read(settingsProvider).reminderOffsets, [5]);

    await c.read(settingsProvider.notifier).setReminderOffsets([0]);
    expect(await repo.raw(SettingKeys.legacyReminderLead), isNull);
    expect(await repo.raw(SettingKeys.reminderOffsets.name), isNull);
    expect((await repo.load()).reminderOffsets, [0]);
  });

  test('写新键：非法值被过滤后为空时不保存，旧键也保留', () async {
    await put(SettingKeys.legacyReminderLead, '15');
    final c = await container();
    await c.read(settingsProvider.notifier).setReminderOffsets([-1, 99999]);
    expect(c.read(settingsProvider).reminderOffsets, [15]);
    expect(await repo.raw(SettingKeys.legacyReminderLead), '15');
    expect(await repo.raw(SettingKeys.reminderOffsets.name), isNull);
  });

  test('默认方式：写闹钟后读出闹钟；写回通知删除该行；非法值按通知', () async {
    final c = await container();
    await c.read(settingsProvider.notifier).setReminderKind(ReminderKind.alarm);
    expect(await repo.raw(SettingKeys.reminderKind.name), 'alarm');
    expect((await repo.load()).reminderKind, ReminderKind.alarm);
    await c.read(settingsProvider.notifier).setReminderKind(ReminderKind.notification);
    expect(await repo.raw(SettingKeys.reminderKind.name), isNull);

    await put(SettingKeys.reminderKind.name, 'siren');
    expect((await repo.load()).reminderKind, ReminderKind.notification);
  });
}
