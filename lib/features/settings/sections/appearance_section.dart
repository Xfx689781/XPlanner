import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/accent.dart';
import '../../../core/data/settings/settings_enums.dart';
import '../../../core/data/settings/settings_provider.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/locale_providers.dart';
import '../settings_labels.dart';
import '../settings_widgets.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    final accent = ref.watch(settingsProvider.select((s) => s.accent));
    final controller = ref.read(settingsProvider.notifier);
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceSetting<ThemePreference>(
          title: l10n.settingsTheme,
          value: theme,
          options: [for (final t in ThemePreference.values) GeoOption(value: t, label: themeLabel(l10n, t))],
          onChanged: (t) => saveSetting(context, () => controller.setTheme(t)),
        ),
        SectionHeader(l10n.settingsAccentColor),
        GeoSwatchPicker<AccentColor>(
          value: accent,
          swatches: [
            for (final a in AccentColor.values)
              GeoSwatch(
                value: a,
                // 色块显示当前明暗模式下的那一版
                color: paletteOf(a).forBrightness(brightness),
                label: accentLabel(l10n, a),
              ),
          ],
          onChanged: (a) => saveSetting(context, () => controller.setAccent(a)),
        ),
      ],
    );
  }
}
