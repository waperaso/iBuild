import 'package:flutter/material.dart';

/// Semantic color tokens. Widgets use `context.colors`, not raw [Color]s.
/// Shared by B2B and B2C; swap palette via a different [AppColors] instance.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.onAccent,
    required this.accentSecondary,
    required this.onAccentSecondary,
    required this.heroSurface,
    required this.onHeroSurface,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.success,
    required this.warning,
    required this.danger,
    required this.unitAvailable,
    required this.unitReserved,
    required this.unitSold,
    required this.unitBlocked,
  });

  /// Whether this scheme is light or dark. Drives icon brightness, overlays.
  final Brightness brightness;

  /// App canvas / page background (the cream tone in the mockups).
  final Color background;

  /// Primary card / sheet surface (usually white).
  final Color surface;

  /// Secondary surface for chips, inputs, subtle panels.
  final Color surfaceAlt;

  /// Brand accent (the lime highlight): active chips, badges, hero cards.
  final Color accent;

  /// Foreground drawn on top of [accent].
  final Color onAccent;

  /// Secondary brand color for CTAs and badges.
  final Color accentSecondary;

  /// Foreground drawn on top of [accentSecondary].
  final Color onAccentSecondary;

  /// Dark hero/promo surface; independent of [brightness] in both modes.
  final Color heroSurface;

  /// Foreground drawn on top of [heroSurface].
  final Color onHeroSurface;

  /// Primary text / high-emphasis foreground (near-black ink).
  final Color ink;

  /// Secondary text / muted foreground.
  final Color inkMuted;

  /// Hairline borders and dividers.
  final Color outline;

  final Color success;
  final Color warning;
  final Color danger;

  /// Unit availability-grid statuses (see plan section 3.4 "шахматка").
  final Color unitAvailable;
  final Color unitReserved;
  final Color unitSold;
  final Color unitBlocked;

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? accent,
    Color? onAccent,
    Color? accentSecondary,
    Color? onAccentSecondary,
    Color? heroSurface,
    Color? onHeroSurface,
    Color? ink,
    Color? inkMuted,
    Color? outline,
    Color? success,
    Color? warning,
    Color? danger,
    Color? unitAvailable,
    Color? unitReserved,
    Color? unitSold,
    Color? unitBlocked,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      onAccentSecondary: onAccentSecondary ?? this.onAccentSecondary,
      heroSurface: heroSurface ?? this.heroSurface,
      onHeroSurface: onHeroSurface ?? this.onHeroSurface,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      outline: outline ?? this.outline,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      unitAvailable: unitAvailable ?? this.unitAvailable,
      unitReserved: unitReserved ?? this.unitReserved,
      unitSold: unitSold ?? this.unitSold,
      unitBlocked: unitBlocked ?? this.unitBlocked,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      onAccentSecondary: Color.lerp(
        onAccentSecondary,
        other.onAccentSecondary,
        t,
      )!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHeroSurface: Color.lerp(onHeroSurface, other.onHeroSurface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      unitAvailable: Color.lerp(unitAvailable, other.unitAvailable, t)!,
      unitReserved: Color.lerp(unitReserved, other.unitReserved, t)!,
      unitSold: Color.lerp(unitSold, other.unitSold, t)!,
      unitBlocked: Color.lerp(unitBlocked, other.unitBlocked, t)!,
    );
  }
}
