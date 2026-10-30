import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/notifications/notification_ids.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/reminder_scheduler.dart';
import '../../core/notifications/reminder_status.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/system_settings.dart';
import '../../design_system/design_system.dart';

class SettingsPage extends ConsumerStatefulWidget {
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
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 从系统设置页回来时刷新状态
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(reminderStatusProvider));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  Future<void> _requestNotifications() async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await _scheduler.requestNotificationPermission();
    ref.invalidate(reminderStatusProvider);
    if (!granted) {
      // 用户之前拒绝过时系统不会再弹窗，只能去应用设置里开
      final opened = await ref.read(systemSettingsProvider).openAppDetails();
      if (!opened) {
        messenger.showSnackBar(const SnackBar(content: Text('请在系统设置 → 应用 → Facet → 通知 中开启')));
      }
    }
  }

  Future<void> _openAppDetails() async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref.read(systemSettingsProvider).openAppDetails();
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text('请手动打开 设置 → 应用 → Facet')));
    }
  }

  Future<void> _testNotification() async {
    final messenger = ScaffoldMessenger.of(context);
    final now = ref.read(clockProvider).now();
    final at = tz.TZDateTime.from(now, tz.local).add(const Duration(seconds: 5));
    try {
      final mode = await _scheduler.schedule(ReminderRequest(
        id: testNotificationId,
        title: 'Facet 测试提醒',
        body: '能看到这条，说明提醒正常',
        at: at,
      ));
      messenger.showSnackBar(SnackBar(
        content: Text(mode == ScheduleMode.exact
            ? '5 秒后会弹出一条通知，可以先锁屏'
            : '已安排（不精确模式，可能晚一些才弹出）'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('安排失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(reminderStatusProvider).value;

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
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xl),
          children: [
            const SectionHeader('提醒'),
            if (status == null)
              const SizedBox.shrink()
            else if (!status.supported)
              const _Paragraph('这个平台暂不支持提醒。任务和提醒时间会正常保存，在手机上会按时弹出。')
            else ...[
              _StatusRow(
                label: '通知权限',
                ok: status.notificationsEnabled,
                okText: '已开启',
                badText: '未开启，提醒不会弹出',
                action: '开启',
                onAction: _requestNotifications,
              ),
              _StatusRow(
                label: '闹钟和提醒',
                ok: status.exactAllowed,
                okText: '已开启，提醒准时',
                badText: '未开启，提醒可能晚几分钟到十几分钟',
                action: '去开启',
                onAction: _scheduler.requestExactAlarmPermission,
              ),
              _StatusRow(
                label: '电池',
                ok: status.batteryUnrestricted,
                okText: '不受限制',
                badText: '可能被省电策略拦截',
                action: '打开应用设置',
                onAction: _openAppDetails,
              ),
              _StatusRow(
                label: '时区',
                ok: !status.timezoneGuessed,
                okText: status.timezone,
                badText: '${status.timezone}（没取到系统时区，按时差推测，提醒可能差一小时）',
              ),
              const _Paragraph('提醒按当地钟点：换了时区后请打开一次 Facet，提醒会改按新时区的钟点响。'),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GeoButton(label: '5 秒后发一条测试通知', onPressed: _testNotification),
                ),
              ),
              const SectionHeader('三星手机：防止提醒被拦截'),
              const _Paragraph('三星的省电策略可能在后台拦截提醒。建议按下面设置一次：'),
              const _Step(1, '设置 → 应用 → Facet → 电池 → 选「不受限制」。上面「打开应用设置」可以直接跳到这里。'),
              const _Step(2, '设置 → 电池 → 后台使用限制：确认 Facet 不在「休眠应用」或「深度休眠应用」里；可以把它加入「永不休眠的应用」。'),
              const _Step(3, '设置 → 应用 → Facet → 通知：允许通知，并打开「锁定屏幕」上的显示。'),
              const _Step(4, '长时间不打开的 App 可能被系统自动放进休眠列表，如果某天提醒不响了，回来检查第 2 步。'),
            ],
          ],
        ),
      ),
    );
  }
}

/// 一行状态：几何点（实心 = 正常，空心主色 = 需要处理）+ 名称 + 说明 + 操作。
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.ok,
    required this.okText,
    this.badText,
    this.action,
    this.onAction,
  });

  final String label;

  /// null = 无法判断，不显示操作
  final bool? ok;
  final String okText;
  final String? badText;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bad = ok == false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
      child: Row(
        children: [
          GeoIcon(
            GeoGlyph.circle,
            size: FontSizes.body,
            color: bad ? colors.accent : colors.ink,
            filled: !bad,
            strokeWidth: Stroke.thin,
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.body),
                Text(
                  ok == null ? '无法检测' : (bad ? badText ?? '' : okText),
                  style: context.text.small.copyWith(color: bad ? colors.accent : null),
                ),
              ],
            ),
          ),
          if (bad && action != null)
            GeoButton(label: action!, style: GeoButtonStyle.outline, onPressed: onAction),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.s),
      child: Text(text, style: context.text.small.copyWith(color: context.colors.ink)),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: Space.l, child: Text('$n', style: context.text.small)),
          Expanded(child: Text(text, style: context.text.small.copyWith(color: context.colors.ink))),
        ],
      ),
    );
  }
}
