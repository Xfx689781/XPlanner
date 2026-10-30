import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// 用设计令牌构建 ThemeData，并关掉 Material 的默认视觉（水波纹、阴影、圆角卡片）。
ThemeData buildFacetTheme(Brightness brightness) {
  final colors = brightness == Brightness.light ? FacetColors.light : FacetColors.dark;
  final text = FacetText.from(ink: colors.ink, muted: colors.muted);
  final underline = UnderlineInputBorder(
    borderSide: BorderSide(color: colors.line, width: Stroke.thin),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      error: colors.accent,
      onError: colors.onAccent,
      surface: colors.background,
      onSurface: colors.ink,
    ),
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: colors.line.withValues(alpha: 0.4),
    dividerColor: colors.line,
    // 所有槽位都映射到三档字号，Material 组件（选择器、按钮）不会冒出别的字号。
    // 时间选择器的大号时分数字（display*）是唯一例外：保留标题档放大显示
    textTheme: TextTheme(
      displayLarge: text.title.copyWith(fontSize: FontSizes.title * 2),
      displayMedium: text.title,
      displaySmall: text.title,
      headlineLarge: text.title,
      headlineMedium: text.title,
      headlineSmall: text.title,
      titleLarge: text.body,
      titleMedium: text.body,
      titleSmall: text.body,
      bodyLarge: text.body,
      bodyMedium: text.body,
      bodySmall: text.small,
      labelLarge: text.body,
      labelMedium: text.small,
      labelSmall: text.small,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.accent,
      selectionColor: colors.accent.withValues(alpha: 0.25),
      selectionHandleColor: colors.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: underline,
      enabledBorder: underline,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.ink, width: Stroke.thin),
      ),
      hintStyle: text.body.copyWith(color: colors.muted),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: Space.s),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      modalBackgroundColor: colors.surface,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: colors.surface,
      headerBackgroundColor: colors.surface,
      headerForegroundColor: colors.ink,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      dayShape: const WidgetStatePropertyAll(CircleBorder()),
      todayBorder: BorderSide(color: colors.accent, width: Stroke.thin),
      dividerColor: colors.line,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: colors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      hourMinuteShape: const RoundedRectangleBorder(),
      dialBackgroundColor: colors.background,
      dialHandColor: colors.accent,
      dayPeriodBorderSide: BorderSide(color: colors.line, width: Stroke.thin),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.ink,
        shape: const RoundedRectangleBorder(),
        splashFactory: NoSplash.splashFactory,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surface,
      contentTextStyle: text.small.copyWith(color: colors.ink),
      actionTextColor: colors.accent,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: colors.line, width: Stroke.thin)),
      behavior: SnackBarBehavior.floating,
    ),
    extensions: [FacetTokens(colors)],
  );
}
