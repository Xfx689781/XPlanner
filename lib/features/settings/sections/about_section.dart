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
        SectionHeader('关于'),
        InfoRow(label: '应用', value: appName),
        InfoRow(label: '版本', value: '$appVersion ($appBuild)'),
        SectionHeader('隐私'),
        SettingsParagraph('你的任务、日志和设置只保存在这台设备上，不会发送到任何网络地址。Facet 没有账号，也不收集使用数据。'),
      ],
    );
  }
}
