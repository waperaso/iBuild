import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Builds a full [ThemeData] from a semantic [AppColors] token set. This is the
/// single bridge between our palette tokens and Flutter's Material theming, so
/// switching palettes flows through here automatically.
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
    // InkSparkle is expensive on Flutter web (shader + animation per tap).
    // `hoverColor`/`highlightColor` default to a flat black wash the size of
    // whatever rect the InkWell/IconButton happens to occupy — on a rounded
    // photo tile without a matching `borderRadius` on that InkWell, this
    // painted as a plain rectangle laid over the rounded corners, reading as
    // a stock Android ripple/hover rather than a considered hover state.
    // Matches the b2c theme, which already disables these for the same
    // reason — plain taps/hovers feel snappier and don't fight rounded
    // cards without one.
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
    // Softer, calmer route transitions on every platform instead of the
    // default Android bottom-up slide, for a more premium feel.
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

/// A gentle fade + slight upward slide used for all page transitions. Reads as
/// a soft cross-fade rather than the hard platform-default push.
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
