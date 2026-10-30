import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/settings/settings_enums.dart';
import '../core/data/settings/settings_provider.dart';
import 'home_shell.dart';
import 'theme.dart';
import 'week_start_localizations.dart';

class FacetApp extends ConsumerWidget {
  const FacetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    final weekStart = ref.watch(settingsProvider.select((s) => s.weekStart));
    return MaterialApp(
      title: 'Facet',
      debugShowCheckedModeBanner: false,
      theme: buildFacetTheme(Brightness.light),
      darkTheme: buildFacetTheme(Brightness.dark),
      themeMode: switch (theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      // 日期 / 时间选择器等系统组件的文字和一周第一天
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: [
        WeekStartMaterialDelegate(weekStart),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: const HomeShell(),
    );
  }
}
