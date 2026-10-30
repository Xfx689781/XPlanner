import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/data_providers.dart';
import '../core/notifications/notification_providers.dart';
import '../core/notifications/reminder_status.dart';
import '../core/utils/current_day.dart';
import '../design_system/design_system.dart';
import '../features/log/log_page.dart';
import '../features/plan/task_editor_sheet.dart';
import '../features/plan/tasks_page.dart';
import '../features/today/today_page.dart';

/// 三栏外壳：今天 / 任务 / 日志。窄屏底部导航，宽屏左侧导航。
/// 同时负责：点通知后打开对应任务；回到前台时刷新"今天"并检查提醒。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _tasksTab = 1;

  int _index = 0;
  late final AppLifecycleListener _lifecycle;

  static const _items = [
    GeoNavItem(glyph: GeoGlyph.circle, label: '今天'),
    GeoNavItem(glyph: GeoGlyph.square, label: '任务'),
    GeoNavItem(glyph: GeoGlyph.lines, label: '日志'),
  ];

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 冷启动时 main 已经把要打开的任务放进来了
      final pending = ref.read(pendingNavigationProvider);
      if (pending != null) _openTask(pending);
      ref.read(reminderMonitorProvider).onResume();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onResume() {
    ref.read(currentDayProvider.notifier).refresh();
    ref.read(reminderMonitorProvider).onResume();
  }

  Future<void> _openTask(int id) async {
    ref.read(pendingNavigationProvider.notifier).clear();
    setState(() => _index = _tasksTab);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final task = await ref.read(taskRepositoryProvider).getById(id);
    if (!mounted) return;
    if (task == null) {
      messenger.showSnackBar(const SnackBar(content: Text('这个任务已经删除')));
      return;
    }
    // 关掉设置页等上层页面，回到外壳再打开任务
    navigator.popUntil((r) => r.isFirst);
    await showTaskEditor(context, task: task);
  }

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(pendingNavigationProvider, (_, id) {
      if (id != null) _openTask(id);
    });

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
