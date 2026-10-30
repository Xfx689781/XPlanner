
import '../app_database.dart';
import 'app_settings.dart';
import 'setting_keys.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.settingEntries).get();
    return AppSettings.fromRaw({for (final r in rows) r.key: r.value});
  }

  /// 等于默认值时删除该行，否则写入
  Future<void> write<T>(SettingKey<T> key, T value) async {
    if (value == key.defaultValue) {
      await (_db.delete(_db.settingEntries)..where((s) => s.key.equals(key.name))).go();
    } else {
      await _db.into(_db.settingEntries).insertOnConflictUpdate(
        SettingEntriesCompanion.insert(key: key.name, value: key.encode(value)),
      );
    }
  }

  /// 原始读取（测试和排查用）
  Future<String?> raw(String key) async {
    final row = await (_db.select(_db.settingEntries)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }
}
