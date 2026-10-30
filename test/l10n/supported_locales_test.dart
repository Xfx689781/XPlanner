import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/supported_locales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

String resolve(List<Locale> system, {String? stored}) => resolveLanguage(stored, system).tag;

void main() {
  group('跟随系统时的语言匹配', () {
    test('简体中文：zh_CN、zh_SG、裸 zh、zh_Hans_HK（按文字是简体）', () {
      expect(resolve(const [Locale('zh', 'CN')]), 'zh-Hans');
      expect(resolve(const [Locale('zh', 'SG')]), 'zh-Hans');
      expect(resolve(const [Locale('zh')]), 'zh-Hans');
      expect(resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'HK')]), 'zh-Hans');
    });

    test('繁體中文：zh_TW、zh_HK、zh_MO、zh_Hant、zh_Hant_CN（按文字是繁体）', () {
      expect(resolve(const [Locale('zh', 'TW')]), 'zh-Hant');
      expect(resolve(const [Locale('zh', 'HK')]), 'zh-Hant');
      expect(resolve(const [Locale('zh', 'MO')]), 'zh-Hant');
      expect(resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')]), 'zh-Hant');
      expect(resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'CN')]), 'zh-Hant');
    });

    test('英文：任何地区', () {
      expect(resolve(const [Locale('en', 'US')]), 'en');
      expect(resolve(const [Locale('en', 'GB')]), 'en');
    });

    test('按系统偏好顺序找第一个支持的语言', () {
      expect(resolve(const [Locale('it'), Locale('zh', 'CN')]), 'zh-Hans');
      expect(resolve(const [Locale('en'), Locale('zh', 'CN')]), 'en');
    });

    test('都不支持或列表为空：用 English 兜底', () {
      expect(resolve(const [Locale('it')]), 'en');
      expect(resolve(const []), 'en');
    });

    test('用户选过的语言优先；存的标签不认识时按跟随系统处理', () {
      expect(resolve(const [Locale('zh', 'CN')], stored: 'en'), 'en');
      expect(resolve(const [Locale('zh', 'CN')], stored: 'xx-Unknown'), 'zh-Hans');
    });
  });

  test('繁体界面用繁体文字和用词，不是简体', () {
    final hant = lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
    final hans = lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    expect(hant.settingsTitle, '設定');
    expect(hans.settingsTitle, '设置');
    expect(hant.taskEditorSave, '儲存');
    expect(hant.repeatEveryWeekday('fri'), '每週五');
  });

  test('支持列表与生成的 ARB 语言、Material 本地化一一对应', () {
    for (final lang in appLanguages) {
      // 每种语言都能找到 AppLocalizations（有对应 ARB）
      expect(lookupAppLocalizations(lang.locale).localeName, startsWith(lang.locale.languageCode));
      // 日期 / 时间选择器能翻译
      expect(GlobalMaterialLocalizations.delegate.isSupported(lang.locale), isTrue, reason: lang.tag);
      expect(AppLocalizations.delegate.isSupported(lang.locale), isTrue, reason: lang.tag);
    }
    expect(appLanguages.map((l) => l.tag).toSet().length, appLanguages.length);
  });
}
