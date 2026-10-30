import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// 挂在 ThemeData 上的设计令牌，Widget 通过 `context.colors` / `context.text` 取用。
@immutable
class FacetTokens extends ThemeExtension<FacetTokens> {
  FacetTokens(this.colors)
    : text = FacetText.from(ink: colors.ink, muted: colors.muted);

  final FacetColors colors;
  final FacetText text;

  @override
  FacetTokens copyWith({FacetColors? colors}) => FacetTokens(colors ?? this.colors);

  @override
  FacetTokens lerp(FacetTokens? other, double t) {
    if (other == null) return this;
    return FacetTokens(FacetColors.lerp(colors, other.colors, t));
  }
}

extension FacetTokensContext on BuildContext {
  FacetTokens get tokens => Theme.of(this).extension<FacetTokens>()!;
  FacetColors get colors => tokens.colors;
  FacetText get text => tokens.text;
}
