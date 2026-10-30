import 'package:flutter/widgets.dart';

import '../../design_system/widgets/page_frame.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(title: '今天', child: SizedBox.shrink());
  }
}
