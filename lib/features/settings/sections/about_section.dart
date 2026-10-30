import 'package:flutter/material.dart';

import '../../../app/app_info.dart';
import '../../../design_system/design_system.dart';
import '../settings_widgets.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('应用信息'),
        InfoRow(label: '应用', value: appName),
        InfoRow(label: '版本', value: '$appVersion ($appBuild)'),
        SectionHeader('隐私'),
        SettingsParagraph('你的任务、日志和设置保存在本机。Facet 没有账号，不收集使用数据，也不会把数据发送到任何服务器。'),
      ],
    );
  }
}
