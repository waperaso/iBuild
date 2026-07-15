import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ergonomic access to the semantic palette from any widget.
///
/// ```dart
/// final c = context.colors;
/// Container(color: c.accent);
/// ```
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? _fallback;
}

// Should never be hit in practice because [buildAppTheme] always registers the
// extension, but keeps `context.colors` non-null and crash-free. Mirrors
// [meridianScheme] so the fallback never looks like a stale/different brand.
const AppColors _fallback = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF6F3EA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFEFEADD),
  accent: Color(0xFF0F5C56),
  onAccent: Color(0xFFF3FBF9),
  accentSecondary: Color(0xFFAD8036),
  onAccentSecondary: Color(0xFF211505),
  heroSurface: Color(0xFF12191A),
  onHeroSurface: Color(0xFFF6F2E6),
  ink: Color(0xFF1B1C1A),
  inkMuted: Color(0xFF69675F),
  outline: Color(0xFFE3DDCE),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFC1690E),
  danger: Color(0xFFB3392B),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFC7C2B7),
  unitBlocked: Color(0xFF5B564C),
);
