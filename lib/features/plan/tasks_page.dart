import 'package:flutter/widgets.dart';

import '../../design_system/widgets/page_frame.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(title: '任务', child: SizedBox.shrink());
  }
}
