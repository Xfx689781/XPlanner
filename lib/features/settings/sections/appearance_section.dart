import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return ChoiceSetting<ThemePreference>(
      title: l10n.settingsTheme,
      value: theme,
      options: [for (final t in ThemePreference.values) GeoOption(value: t, label: themeLabel(l10n, t))],
      onChanged: (t) => saveSetting(context, () => ref.read(settingsProvider.notifier).setTheme(t)),
    );
  }
}
