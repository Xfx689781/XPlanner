import 'package:flutter/widgets.dart';

import '../metrics.dart';
import '../tokens.dart';

/// 页面骨架：留白充足的大标题 + 可选右上角操作 + 内容。
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.l,
              Space.l,
              Space.s,
              Space.m,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.title),
                      if (subtitle != null) ...[
                        const SizedBox(height: Space.xs),
                        Text(subtitle!, style: context.text.small),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
