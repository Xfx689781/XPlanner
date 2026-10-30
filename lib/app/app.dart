import 'package:flutter/material.dart';

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
      home: const HomeShell(),
    );
  }
}
