import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/settings/settings_enums.dart';
import '../core/data/settings/settings_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/locale_providers.dart';
import '../l10n/supported_locales.dart';
import 'accent.dart';
import 'app_info.dart';
import 'home_shell.dart';
import 'theme.dart';
import 'week_start_localizations.dart';

class FacetApp extends ConsumerStatefulWidget {
  const FacetApp({super.key});

  @override
  ConsumerState<FacetApp> createState() => _FacetAppState();
}

class _FacetAppState extends ConsumerState<FacetApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 系统语言变了（"跟随系统"时界面要跟着变）
  @override
  void didChangeLocales(List<Locale>? locales) {
    ref.read(systemLocalesProvider.notifier).set(locales ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    final weekStart = ref.watch(settingsProvider.select((s) => s.weekStart));
    final accent = paletteOf(ref.watch(settingsProvider.select((s) => s.accent)));
    final language = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: buildFacetTheme(Brightness.light, accent),
      darkTheme: buildFacetTheme(Brightness.dark, accent),
      themeMode: switch (theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      // 语言由我们自己解析（含简繁 scriptCode），不交给框架的 localeResolutionCallback
      locale: language.locale,
      supportedLocales: [for (final l in appLanguages) l.locale],
      localizationsDelegates: [
        // 必须在 GlobalMaterialLocalizations 之前：同类型只用第一个
        WeekStartMaterialDelegate(weekStart),
        ...AppLocalizations.localizationsDelegates,
      ],
      home: const HomeShell(),
    );
  }
}
