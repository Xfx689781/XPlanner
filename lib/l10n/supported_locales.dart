import 'package:flutter/widgets.dart';

/// 一种界面语言。新增语言：加一个 ARB 文件 + 在 [appLanguages] 里加一行（见 CLAUDE.md「多语言」）。
@immutable
class AppLanguage {
  const AppLanguage({
    required this.tag,
    required this.locale,
    required this.autonym,
    required this.intlLocale,
  });

  /// 存进设置表的标签（BCP-47，如 zh-Hans）
  final String tag;

  /// 给 MaterialApp / 字形选择用。中文必须带 scriptCode，Android 才会选对简繁字形
  final Locale locale;

  /// 用这种语言自己的文字写的名字（"繁體中文"），各界面语言下都一样，不进 ARB
  final String autonym;

  /// intl 日期数据的 locale 名（intl 没有 zh_Hant，要用 zh_TW）
  final String intlLocale;
}

/// 支持的语言（唯一来源）。第一项是兜底语言。
const appLanguages = <AppLanguage>[
  AppLanguage(tag: 'en', locale: Locale('en'), autonym: 'English', intlLocale: 'en'),
  AppLanguage(
    tag: 'zh-Hans',
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    autonym: '简体中文',
    intlLocale: 'zh_CN',
  ),
];

AppLanguage get fallbackLanguage => appLanguages.first;

AppLanguage? languageByTag(String? tag) {
  for (final l in appLanguages) {
    if (l.tag == tag) return l;
  }
  return null;
}

/// 系统的一个 locale 对应我们支持的哪种语言；不支持返回 null。
AppLanguage? matchSystemLocale(Locale system) {
  final candidates = appLanguages.where((l) => l.locale.languageCode == system.languageCode).toList();
  if (candidates.isEmpty) return null;
  if (candidates.length == 1) return candidates.single;
  // 同一语言有多个文字变体（中文简 / 繁）：先看 scriptCode，没有就按地区推断
  final script = system.scriptCode ?? _scriptForRegion(system.languageCode, system.countryCode);
  for (final l in candidates) {
    if (l.locale.scriptCode == script) return l;
  }
  return candidates.first;
}

String? _scriptForRegion(String language, String? country) {
  if (language == 'zh') {
    return const {'TW', 'HK', 'MO'}.contains(country) ? 'Hant' : 'Hans';
  }
  return null;
}

/// 实际使用的语言：用户选了就用；跟随系统时按系统语言的偏好顺序找第一个支持的；都不支持用兜底语言。
AppLanguage resolveLanguage(String? storedTag, List<Locale> systemLocales) {
  final stored = languageByTag(storedTag);
  if (stored != null) return stored;
  for (final l in systemLocales) {
    final match = matchSystemLocale(l);
    if (match != null) return match;
  }
  return fallbackLanguage;
}
