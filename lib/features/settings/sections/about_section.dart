import 'package:flutter/material.dart';

import '../../../app/app_info.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/locale_providers.dart';
import '../settings_widgets.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.settingsAppInfo),
        InfoRow(label: l10n.settingsAppName, value: appName),
        InfoRow(label: l10n.settingsVersion, value: '$appVersion ($appBuild)'),
        SectionHeader(l10n.settingsPrivacy),
        SettingsParagraph(l10n.settingsPrivacyText),
      ],
    );
  }
}
