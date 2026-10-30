import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'home_shell.dart';
import 'theme.dart';

class FacetApp extends StatelessWidget {
  const FacetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facet',
      debugShowCheckedModeBanner: false,
      theme: buildFacetTheme(Brightness.light),
      darkTheme: buildFacetTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // 日期 / 时间选择器等系统组件的文字和一周第一天
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
    );
  }
}
