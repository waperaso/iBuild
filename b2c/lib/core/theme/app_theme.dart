import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Maps [AppColors] tokens onto Flutter [ThemeData].
ThemeData buildAppTheme(AppColors colors) {
  final isDark = colors.brightness == Brightness.dark;
  final textTheme = AppTypography.textTheme(
    colors.brightness,
  ).apply(bodyColor: colors.ink, displayColor: colors.ink);

  final colorScheme = ColorScheme(
    brightness: colors.brightness,
    primary: colors.accent,
    onPrimary: colors.onAccent,
    secondary: colors.accent,
    onSecondary: colors.onAccent,
    error: colors.danger,
    onError: Colors.white,
    surface: colors.surface,
    onSurface: colors.ink,
    surfaceContainerHighest: colors.surfaceAlt,
    outline: colors.outline,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: colors.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    textTheme: textTheme,
    // Expose the raw token set to widgets via `context.colors`.
    extensions: <ThemeExtension<dynamic>>[colors],
    // InkSparkle is costly on Flutter web; skip splash overlays.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: colors.ink),
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.outline,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surface,
      selectedColor: colors.accent,
      side: BorderSide(color: colors.outline),
      labelStyle: textTheme.labelLarge,
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    // Without this, each Tab's hover/press overlay defaults to a flat
    // rectangle the size of the tab — same "stock Android" look we already
    // stripped from buttons/cards below. Splashes are already disabled
    // globally, so keep tabs consistent instead of leaving a rare rectangle.
    tabBarTheme: const TabBarThemeData(
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      hintStyle: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // A full [AppRadii.pill] radius here used to make every text field —
      // including multi-line ones like the lead form's comment box — a
      // stadium shape. On a tall multi-line box the corner radius exceeds
      // half the field's own height/width, so `OutlineInputBorder` can't
      // draw a clean stadium and the border visibly kinks/breaks at the
      // corners instead. [AppRadii.input] stays a small, fixed radius that
      // never approaches half the field's height, so it can't break.
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.ink, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.danger, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 0,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.ink,
        side: BorderSide(color: colors.outline),
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
    ),
    iconTheme: IconThemeData(color: colors.ink),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.accent,
      linearTrackColor: colors.surfaceAlt,
      circularTrackColor: colors.accent.withValues(alpha: 0.12),
      refreshBackgroundColor: colors.surface,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        colors.inkMuted.withValues(alpha: isDark ? 0.4 : 0.3),
      ),
    ),
  );
}
