import 'package:facet/app/theme.dart';
import 'package:flutter/material.dart';

/// 用 Facet 主题包一层，方便单独测试 design_system 组件。
Widget themed(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: buildFacetTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}
