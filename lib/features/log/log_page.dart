import 'package:flutter/widgets.dart';

import '../../design_system/widgets/page_frame.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(title: '日志', child: SizedBox.shrink());
  }
}
