import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../l10n/locale_providers.dart';

/// 一组单选设置：小标题 + 几何单选列表。分组页里加一个选择型设置项就用它。
class ChoiceSetting<T> extends StatelessWidget {
  const ChoiceSetting({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<GeoOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title),
        GeoOptionList<T>(options: options, value: value, onChanged: onChanged),
      ],
    );
  }
}

/// 一行"名称 + 值"的只读信息。
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: context.text.body)),
          const SizedBox(width: Space.m),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: context.text.small)),
        ],
      ),
    );
  }
}

/// 一行状态：几何点（实心 = 正常，主色空心 = 需要处理，灰色空心 = 无法检测）+ 名称 + 说明。
/// 需要处理时操作按钮放在说明下面，长文字的语言也不会挤压。
class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.label,
    required this.ok,
    required this.okText,
    this.badText,
    required this.unknownText,
    this.action,
    this.onAction,
  });

  final String label;

  /// null = 无法判断，不显示操作
  final bool? ok;
  final String okText;
  final String? badText;
  final String unknownText;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bad = ok == false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: StatusDot(
              bad ? StatusKind.attention : (ok == null ? StatusKind.unknown : StatusKind.ok),
            ),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.body),
                Text(
                  ok == null ? unknownText : (bad ? badText ?? '' : okText),
                  style: context.text.small.copyWith(color: bad ? colors.accent : null),
                ),
                if (bad && action != null) ...[
                  const SizedBox(height: Space.s),
                  GeoButton(label: action!, style: GeoButtonStyle.outline, onPressed: onAction),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsParagraph extends StatelessWidget {
  const SettingsParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.s),
      child: Text(text, style: context.text.small.copyWith(color: context.colors.ink)),
    );
  }
}

class SettingsStep extends StatelessWidget {
  const SettingsStep(this.n, this.text, {super.key});

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

/// 保存设置；写库失败时（设置已自动恢复原值）给出提示。
Future<void> saveSetting(BuildContext context, Future<void> Function() save) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.settingsSaveFailed;
  try {
    await save();
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
