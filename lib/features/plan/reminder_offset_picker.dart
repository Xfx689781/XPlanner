import 'package:flutter/material.dart';

import '../../core/data/enums.dart';
import '../../core/data/reminder_spec.dart';
import '../../core/notifications/reminder_text.dart';
import '../../design_system/design_system.dart';
import '../../l10n/locale_providers.dart';

/// 提前量多选（设置里的默认值和任务编辑共用）：10 个预设 + 已选的自定义值 + "自定义…"，最多 5 个。
/// [kindOf] 不为空时，每个选中项右侧有一个"通知 / 闹钟"切换。
class ReminderOffsetPicker extends StatelessWidget {
  const ReminderOffsetPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.repeat = RepeatRule.none,
    this.kindOf,
    this.onKindChanged,
  });

  /// 已选的提前量（分钟）
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  /// 重复任务：提前量 ≥ 重复周期的选项置灰
  final RepeatRule repeat;
  final ReminderKind Function(int offset)? kindOf;
  final void Function(int offset, ReminderKind kind)? onKindChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final full = selected.length >= ReminderSpec.maxPerTask;
    final offsets = {...ReminderSpec.presets, ...selected}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GeoCheckList<int>(
          selected: selected.toSet(),
          items: [
            for (final m in offsets)
              GeoCheckItem(
                value: m,
                label: leadOptionLabel(l10n, m),
                enabled: !full && ReminderSpec.allowedFor(m, repeat),
              ),
          ],
          onToggle: (m) => onChanged(
            selected.contains(m) ? [...selected.where((x) => x != m)] : [...selected, m],
          ),
          trailingOf: kindOf == null ? null : (m) => _KindToggle(offset: m, kind: kindOf!(m), onChanged: onKindChanged!),
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s),
              child: GeoButton(
                label: l10n.reminderLeadCustom,
                style: GeoButtonStyle.text,
                onPressed: full
                    ? null
                    : () async {
                        final m = await showCustomOffsetDialog(context);
                        if (m != null && !selected.contains(m)) onChanged([...selected, m]);
                      },
              ),
            ),
            if (full) Flexible(child: Text(l10n.reminderMaxReached, style: context.text.small)),
          ],
        ),
      ],
    );
  }
}

/// 选中项右侧的"通知 / 闹钟"切换：两个小几何字形（线 = 通知，实心三角铃 = 闹钟）用文字标明
class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.offset, required this.kind, required this.onChanged});

  final int offset;
  final ReminderKind kind;
  final void Function(int offset, ReminderKind kind) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final alarm = kind == ReminderKind.alarm;
    final label = alarm ? l10n.reminderKindAlarm : l10n.reminderKindNotification;
    return Semantics(
      button: true,
      label: l10n.reminderKindToggle(leadOptionLabel(l10n, offset), label),
      onTap: () => onChanged(offset, alarm ? ReminderKind.notification : ReminderKind.alarm),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(right: Space.s),
        child: GeoButton(
          label: label,
          style: alarm ? GeoButtonStyle.primary : GeoButtonStyle.outline,
          onPressed: () => onChanged(offset, alarm ? ReminderKind.notification : ReminderKind.alarm),
        ),
      ),
    );
  }
}

/// 自定义提前量：数字 + 单位（分钟 / 小时 / 天），1 分钟～30 天。返回分钟数，取消返回 null。
Future<int?> showCustomOffsetDialog(BuildContext context) {
  return showDialog<int>(context: context, builder: (_) => const _CustomOffsetDialog());
}

class _CustomOffsetDialog extends StatefulWidget {
  const _CustomOffsetDialog();

  @override
  State<_CustomOffsetDialog> createState() => _CustomOffsetDialogState();
}

class _CustomOffsetDialogState extends State<_CustomOffsetDialog> {
  final _amount = TextEditingController();
  OffsetUnit _unit = OffsetUnit.minutes;
  bool _invalid = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _minutes {
    final n = int.tryParse(_amount.text.trim());
    if (n == null || n <= 0) return null;
    final m = switch (_unit) {
      OffsetUnit.minutes => n,
      OffsetUnit.hours => n * 60,
      OffsetUnit.days => n * ReminderSpec.minutesPerDay,
      OffsetUnit.weeks => n * ReminderSpec.minutesPerWeek,
    };
    return m <= ReminderSpec.maxOffsetMinutes ? m : null;
  }

  void _submit() {
    final m = _minutes;
    if (m == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(m);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Sizes.dialogMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.reminderCustomTitle, style: context.text.body),
              const SizedBox(height: Space.m),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: context.text.body,
                decoration: InputDecoration(hintText: l10n.reminderCustomAmount),
                onChanged: (_) => setState(() => _invalid = false),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.s),
              GeoChoice<OffsetUnit>(
                value: _unit,
                onChanged: (u) => setState(() => _unit = u),
                options: [
                  GeoChoiceOption(value: OffsetUnit.minutes, label: l10n.unitMinutes),
                  GeoChoiceOption(value: OffsetUnit.hours, label: l10n.unitHours),
                  GeoChoiceOption(value: OffsetUnit.days, label: l10n.unitDays),
                ],
              ),
              if (_invalid) ...[
                const SizedBox(height: Space.s),
                Text(l10n.reminderCustomInvalid, style: context.text.small.copyWith(color: context.colors.danger)),
              ],
              const SizedBox(height: Space.l),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: Space.s,
                children: [
                  GeoButton(label: l10n.commonCancel, style: GeoButtonStyle.text, onPressed: () => Navigator.of(context).pop()),
                  GeoButton(label: l10n.commonOk, style: GeoButtonStyle.primary, onPressed: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
