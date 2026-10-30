import 'package:facet/app/app.dart';
import 'package:facet/core/data/app_database.dart';
import 'package:facet/core/data/data_providers.dart';
import 'package:facet/core/data/settings/app_settings.dart';
import 'package:facet/core/data/settings/settings_provider.dart';
import 'package:facet/app/theme.dart';
import 'package:facet/core/utils/clock.dart';
import 'package:facet/l10n/generated/app_localizations.dart';
import 'package:facet/l10n/locale_providers.dart';
import 'package:facet/l10n/supported_locales.dart';
import 'package:facet/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

/// 用内存数据库和固定时钟启动整个 App。
Widget testApp(
  AppDatabase db, {
  Clock? clock,
  AppSettings settings = AppSettings.defaults,
  List<Locale> systemLocales = const [Locale('zh', 'CN')],
  bool use24h = true,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(settings),
      systemLocalesProvider.overrideWith(() => _FixedSystemLocales(systemLocales)),
      if (clock != null) clockProvider.overrideWithValue(clock),
      ...overrides,
    ],
    child: Builder(
      // 测试机默认 12 小时制；固定成 24 小时制，让断言里的时间与手机常见设置一致。
      // 外层 MediaQuery.fromView 保持对系统明暗、窗口尺寸变化的响应
      builder: (context) => MediaQuery.fromView(
        view: View.of(context),
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24h),
            child: const FacetApp(),
          ),
        ),
      ),
    ),
  );
}

/// 自建 ProviderContainer 的测试用：系统语言固定为简体中文
class ZhSystemLocales extends SystemLocales {
  @override
  List<Locale> build() => const [Locale('zh', 'CN')];
}

class _FixedSystemLocales extends SystemLocales {
  _FixedSystemLocales(this._initial);

  final List<Locale> _initial;

  @override
  List<Locale> build() => _initial;
}

/// 单独测试某个页面时用的 MaterialApp：带 Facet 主题和本地化，默认简体中文。
Widget localizedApp(Widget home, {Locale locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')}) {
  return MaterialApp(
    theme: buildFacetTheme(Brightness.light),
    locale: locale,
    supportedLocales: [for (final l in appLanguages) l.locale],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

extension DbTester on WidgetTester {
  /// 点导航栏里的某一栏（页面里可能有同名的分组标题）
  Future<void> tapNav(String label) async {
    await tap(find.descendant(of: find.byType(GeoNavBar), matching: find.text(label)));
    await pumpAndSettle();
  }

  /// 在 widget 测试里直接读写数据库要走真实的异步，否则 drift 的计时器在假时钟下不会推进。
  Future<T> db<T>(Future<T> Function() fn) async => (await runAsync(fn)) as T;

  /// 卸载 App，让 drift 的流查询和计时器正常收尾，避免"Timer is still pending"。
  Future<void> disposeApp() async {
    await pumpWidget(const SizedBox.shrink());
    await pump(const Duration(seconds: 1));
  }
}
