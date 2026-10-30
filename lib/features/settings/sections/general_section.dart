import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings/settings_enums.dart';
import '../../../core/data/settings/settings_provider.dart';
import '../../../core/utils/week_start.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/locale_providers.dart';
import '../../../l10n/supported_locales.dart';
import '../settings_labels.dart';
import '../settings_widgets.dart';

class GeneralSection extends ConsumerWidget {
  const GeneralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(settingsProvider.notifier);
    final languageTag = ref.watch(settingsProvider.select((s) => s.languageTag));
    final weekStart = ref.watch(settingsProvider.select((s) => s.weekStart));
    final systemLanguage = resolveLanguage(null, ref.watch(systemLocalesProvider));
    final current = ref.watch(appLanguageProvider);
    final localeDay = weekdayName(l10n, localeFirstWeekday(current.intlLocale));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceSetting<String?>(
          title: l10n.settingsLanguage,
          value: languageByTag(languageTag)?.tag,
          options: [
            GeoOption(
              value: null,
              label: l10n.languageFollowSystem,
              detail: l10n.languageCurrent(systemLanguage.autonym),
            ),
            // 语言名用它自己的文字和字形显示（不翻译）
            for (final lang in appLanguages) GeoOption(value: lang.tag, label: lang.autonym, labelLocale: lang.locale),
          ],
          onChanged: (tag) => saveSetting(context, () => controller.setLanguageTag(tag)),
        ),
        ChoiceSetting<WeekStart>(
          title: l10n.settingsWeekStart,
          value: weekStart,
          options: [
            for (final w in WeekStart.values)
              GeoOption(
                value: w,
                label: weekStartLabel(l10n, w),
                // "跟随语言"写出实际是哪天，避免看起来和另一项重复
                detail: w == WeekStart.locale ? l10n.weekStartCurrent(localeDay) : null,
              ),
          ],
          onChanged: (w) => saveSetting(context, () => controller.setWeekStart(w)),
        ),
      ],
    );
  }
}
