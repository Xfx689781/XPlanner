import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data_providers.dart';
import '../../core/utils/clock.dart';
import '../../design_system/design_system.dart';
import '../../l10n/locale_providers.dart';

/// 一句话记录：回车或点加号保存，时间戳自动取当前时间。
class LogInputBar extends ConsumerStatefulWidget {
  const LogInputBar({super.key});

  @override
  ConsumerState<LogInputBar> createState() => _LogInputBarState();
}

class _LogInputBarState extends ConsumerState<LogInputBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(logRepositoryProvider).add(text, now: ref.read(clockProvider).now());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.s, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              maxLength: 500,
              style: context.text.body,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                _submit();
                _focus.requestFocus();
              },
              decoration: InputDecoration(hintText: context.l10n.logInputHint, counterText: ''),
            ),
          ),
          GeoIconButton(
            glyph: GeoGlyph.plus,
            semanticLabel: context.l10n.logAddSemantics,
            color: context.colors.accent,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
