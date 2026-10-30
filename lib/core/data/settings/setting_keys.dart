import 'settings_enums.dart';

/// 一个设置项在键值表里的描述：键名、默认值、编解码。
/// 解码失败（被手动改过、旧版本留下的值）返回 null，按默认值处理。
class SettingKey<T> {
  const SettingKey(this.name, this.defaultValue, this.encode, this.decode);

  final String name;
  final T defaultValue;
  final String Function(T value) encode;
  final T? Function(String raw) decode;

  T read(String? raw) => (raw == null ? null : decode(raw)) ?? defaultValue;
}

T? _byName<T extends Enum>(List<T> values, String raw) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

abstract final class SettingKeys {
  static const theme = SettingKey<ThemePreference>(
    'theme',
    ThemePreference.system,
    _enumName,
    _decodeTheme,
  );

  static const weekStart = SettingKey<WeekStart>(
    'weekStart',
    WeekStart.locale,
    _enumName,
    _decodeWeekStart,
  );

  static const reminderLead = SettingKey<ReminderLead>(
    'reminderLeadMinutes',
    ReminderLead.onTime,
    _encodeLead,
    _decodeLead,
  );

  /// BCP-47 标签（如 zh-Hans）；null = 跟随系统
  static const language = SettingKey<String?>('language', null, _identity, _identity);
}

String _enumName(Enum e) => e.name;
ThemePreference? _decodeTheme(String raw) => _byName(ThemePreference.values, raw);
WeekStart? _decodeWeekStart(String raw) => _byName(WeekStart.values, raw);
String _encodeLead(ReminderLead l) => '${l.minutes}';
ReminderLead? _decodeLead(String raw) {
  final m = int.tryParse(raw);
  for (final l in ReminderLead.values) {
    if (l.minutes == m) return l;
  }
  return null;
}

String _identity(String? s) => s!;
