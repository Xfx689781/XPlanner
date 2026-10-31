import '../enums.dart';
import '../reminder_spec.dart';
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

  /// 是否等于默认值。先直接比较（可空类型的默认值 null 不能编码），
  /// 都不为 null 时再按编码后的值比较（列表等类型没有值相等）
  bool isDefault(T value) {
    if (value == defaultValue) return true;
    if (value == null || defaultValue == null) return false;
    return encode(value) == encode(defaultValue);
  }
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

  static const accent = SettingKey<AccentColor>(
    'accentColor',
    AccentColor.vermilion,
    _enumName,
    _decodeAccent,
  );

  static const weekStart = SettingKey<WeekStart>(
    'weekStart',
    WeekStart.locale,
    _enumName,
    _decodeWeekStart,
  );

  /// 新建提醒时默认选中的提前量（分钟，先响的在前），例如 "1440,15"
  static const reminderOffsets = SettingKey<List<int>>(
    'reminderDefaultOffsets',
    [0],
    _encodeOffsets,
    _decodeOffsets,
  );

  /// 新建提醒时的默认方式
  static const reminderKind = SettingKey<ReminderKind>(
    'reminderDefaultKind',
    ReminderKind.notification,
    _enumName,
    _decodeKind,
  );

  /// 旧版（单选 准时 / 5 / 15 分钟）的键：读到时转成 [reminderOffsets]，写新键时删除
  static const legacyReminderLead = 'reminderLeadMinutes';

  /// BCP-47 标签（如 zh-Hans）；null = 跟随系统
  static const language = SettingKey<String?>('language', null, _identity, _identity);
}

String _enumName(Enum e) => e.name;
ThemePreference? _decodeTheme(String raw) => _byName(ThemePreference.values, raw);
WeekStart? _decodeWeekStart(String raw) => _byName(WeekStart.values, raw);
AccentColor? _decodeAccent(String raw) => _byName(AccentColor.values, raw);
ReminderKind? _decodeKind(String raw) => _byName(ReminderKind.values, raw);

String _encodeOffsets(List<int> offsets) => offsets.join(',');

/// 解析并规范化（去重、合法范围、先响的在前、最多 5 个）；一个合法值都没有时返回 null（按默认）
List<int>? _decodeOffsets(String raw) {
  final parsed = [for (final p in raw.split(',')) ?int.tryParse(p.trim())];
  final specs = ReminderSpec.normalize([for (final m in parsed) ReminderSpec(m)], RepeatRule.none);
  return specs.isEmpty ? null : [for (final s in specs) s.offsetMinutes];
}

/// 旧单选键的值 → 新的提前量列表
List<int>? decodeLegacyReminderLead(String? raw) {
  final m = raw == null ? null : int.tryParse(raw);
  return const [0, 5, 15].contains(m) ? [m!] : null;
}

String _identity(String? s) => s!;
