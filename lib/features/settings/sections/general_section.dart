import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_locale.dart';
import '../../../core/data/settings/settings_enums.dart';
import '../../../core/data/settings/settings_provider.dart';
import '../../../core/utils/week_start.dart';
import '../../../design_system/design_system.dart';
import '../settings_labels.dart';
import '../settings_widgets.dart';

class GeneralSection extends ConsumerWidget {
  const GeneralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(settingsProvider.select((s) => s.weekStart));
    final localeDay = weekdayName(localeFirstWeekday(appIntlLocale));
    return ChoiceSetting<WeekStart>(
      title: '一周从哪天开始',
      value: weekStart,
      options: [
        for (final w in WeekStart.values)
          GeoOption(
            value: w,
            label: weekStartLabel(w),
            // "跟随语言"写出实际是哪天，避免看起来和另一项重复
            detail: w == WeekStart.locale ? '当前：$localeDay' : null,
          ),
      ],
      onChanged: (w) => saveSetting(context, () => ref.read(settingsProvider.notifier).setWeekStart(w)),
    );
  }
}
