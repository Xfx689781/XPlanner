import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/reminder_status.dart';
import '../../design_system/design_system.dart';
import 'settings_sections.dart';

PageRoute<void> _fadeRoute(WidgetBuilder builder) {
  return PageRouteBuilder<void>(
    transitionDuration: Motion.standard,
    reverseTransitionDuration: Motion.standard,
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Motion.curve),
      child: child,
    ),
  );
}

/// 设置中心。窄屏：分组列表 → 点进子页面；宽屏：左侧分组列表 + 右侧分组内容。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(_fadeRoute((_) => const SettingsPage()));
  }

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final AppLifecycleListener _lifecycle;
  String _selectedId = settingsSections.first.id;

  @override
  void initState() {
    super.initState();
    // 从系统设置页回来时刷新权限状态（主页上的警示标记也随之更新）
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(reminderStatusProvider));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Widget _list({required bool wide}) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xl),
      children: [
        for (final s in settingsSections)
          SettingsTile(
            title: s.title,
            value: s.summary(ref),
            attention: s.needsAttention?.call(ref) ?? false,
            attentionLabel: s.attentionLabel,
            selected: wide ? s.id == _selectedId : null,
            showChevron: !wide,
            onTap: () {
              if (wide) {
                setState(() => _selectedId = s.id);
              } else {
                Navigator.of(context).push(_fadeRoute((_) => SettingsSectionPage(section: s)));
              }
            },
          ),
      ],
    );
  }

  Widget _backButton() {
    return Padding(
      padding: const EdgeInsets.only(right: Space.s),
      child: GeoIconButton(
        glyph: GeoGlyph.back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= Sizes.wideBreakpoint;
          if (!wide) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Sizes.contentMaxWidth),
                child: PageFrame(title: '设置', trailing: _backButton(), child: _list(wide: false)),
              ),
            );
          }
          final selected = settingsSections.firstWhere((s) => s.id == _selectedId);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sizes.settingsMaxWidth),
              child: PageFrame(
                title: '设置',
                trailing: _backButton(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: Sizes.settingsListWidth, child: _list(wide: true)),
                    Container(width: Stroke.thin, color: context.colors.line),
                    Expanded(
                      child: ListView(
                        key: ValueKey(selected.id),
                        padding: const EdgeInsets.only(bottom: Space.xl),
                        children: [selected.content(context)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 窄屏下的分组子页面。
class SettingsSectionPage extends StatelessWidget {
  const SettingsSectionPage({super.key, required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Sizes.contentMaxWidth),
          child: PageFrame(
            title: section.title,
            trailing: Padding(
              padding: const EdgeInsets.only(right: Space.s),
              child: GeoIconButton(
                glyph: GeoGlyph.back,
                semanticLabel: '返回',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.only(bottom: Space.xl),
              children: [section.content(context)],
            ),
          ),
        ),
      ),
    );
  }
}
