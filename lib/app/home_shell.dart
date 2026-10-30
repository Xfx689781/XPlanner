import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import '../features/log/log_page.dart';
import '../features/plan/tasks_page.dart';
import '../features/today/today_page.dart';

/// 三栏外壳：今天 / 任务 / 日志。窄屏底部导航，宽屏左侧导航。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _items = [
    GeoNavItem(glyph: GeoGlyph.circle, label: '今天'),
    GeoNavItem(glyph: GeoGlyph.square, label: '任务'),
    GeoNavItem(glyph: GeoGlyph.lines, label: '日志'),
  ];

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Sizes.wideBreakpoint;
    final pages = IndexedStack(
      index: _index,
      children: const [TodayPage(), TasksPage(), LogPage()],
    );
    final nav = GeoNavBar(
      items: _items,
      selectedIndex: _index,
      onSelected: _select,
      vertical: wide,
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            nav,
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Sizes.contentMaxWidth),
                  child: pages,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(body: pages, bottomNavigationBar: nav);
  }
}
