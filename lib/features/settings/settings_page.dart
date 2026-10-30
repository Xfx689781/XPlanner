import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Motion.standard,
        reverseTransitionDuration: Motion.standard,
        pageBuilder: (_, _, _) => const SettingsPage(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Motion.curve),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageFrame(
        title: '设置',
        trailing: Padding(
          padding: const EdgeInsets.only(right: Space.s),
          child: GeoIconButton(
            glyph: GeoGlyph.close,
            semanticLabel: '返回',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
