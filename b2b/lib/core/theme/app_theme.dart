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
    // ChoiceChip (M3) fills with secondaryContainer and labels with
    // onSecondaryContainer — keep these in lockstep with accent/onAccent so
    // selected pills stay white-on-accent (light) / black-on-accent (dark).
    secondaryContainer: colors.accent,
    onSecondaryContainer: colors.onAccent,
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
    // InkSparkle is costly on Flutter web. Default hover/highlight also paints
    // a rectangular wash that clips badly on rounded tiles without a matching
    // InkWell borderRadius — disable both (same as b2c).
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
      // ChoiceChip reads secondarySelectedColor, not selectedColor.
      secondarySelectedColor: colors.accent,
      side: BorderSide(color: colors.outline),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.accent;
        return colors.surface;
      }),
      // WidgetStateColor survives M3's labelStyle merge path; plain Color on
      // labelStyle alone is overwritten and selected chips keep ink (black).
      labelStyle: textTheme.labelLarge?.copyWith(
        height: 1.25,
        color: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.onAccent;
          return colors.ink;
        }),
      ),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: colors.onAccent,
      ),
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
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        colors.inkMuted.withValues(alpha: isDark ? 0.4 : 0.3),
      ),
    ),
    // Fade-through on all platforms instead of Android's default slide-up.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeThroughPageTransitionsBuilder(),
        TargetPlatform.iOS: _FadeThroughPageTransitionsBuilder(),
        TargetPlatform.linux: _FadeThroughPageTransitionsBuilder(),
        TargetPlatform.macOS: _FadeThroughPageTransitionsBuilder(),
        TargetPlatform.windows: _FadeThroughPageTransitionsBuilder(),
      },
    ),
  );
}

/// Fade + slight upward slide for page transitions.
class _FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
