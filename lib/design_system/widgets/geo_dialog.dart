import 'package:flutter/material.dart';

import '../metrics.dart';
import '../tokens.dart';
import 'geo_button.dart';

/// 直角、无阴影的确认框。返回 true 表示确认。
Future<bool> showGeoConfirm(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: context.text.body),
            const SizedBox(height: Space.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GeoButton(
                  label: '取消',
                  style: GeoButtonStyle.text,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: Space.s),
                GeoButton(
                  label: confirmLabel,
                  style: destructive ? GeoButtonStyle.outline : GeoButtonStyle.primary,
                  destructive: destructive,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
