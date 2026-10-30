import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings/settings_enums.dart';
import '../../../core/data/settings/settings_provider.dart';
import '../../../design_system/design_system.dart';
import '../settings_labels.dart';
import '../settings_widgets.dart';

class GeneralSection extends ConsumerWidget {
  const GeneralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(settingsProvider.select((s) => s.weekStart));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('语言'),
        // 多语言支持完成后改为语言选择
        const InfoRow(label: '界面语言', value: '跟随系统'),
        ChoiceSetting<WeekStart>(
          title: '一周从哪天开始',
          value: weekStart,
          options: [for (final w in WeekStart.values) GeoOption(value: w, label: weekStartLabel(w))],
          onChanged: (w) => saveSetting(context, () => ref.read(settingsProvider.notifier).setWeekStart(w)),
        ),
      ],
    );
  }
}
