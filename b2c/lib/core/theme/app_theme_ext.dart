import 'package:flutter/material.dart';

import 'app_colors.dart';

/// `context.colors` → theme [AppColors] extension.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? _fallback;
}

// Fallback if [AppColors] isn't on the theme (should not happen in app).
const AppColors _fallback = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFE4E7EB),
  surface: Color(0xFFF3F4F6),
  surfaceAlt: Color(0xFFC8CCD2),
  accent: Color(0xFF002147),
  onAccent: Color(0xFFFFFFFF),
  accentSecondary: Color(0xFF8E959D),
  onAccentSecondary: Color(0xFF002147),
  heroSurface: Color(0xFF002147),
  onHeroSurface: Color(0xFFE8EAED),
  ink: Color(0xFF001833),
  inkMuted: Color(0xFF5A6270),
  outline: Color(0xFFB8BCC0),
  success: Color(0xFF2E7D52),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFB3392B),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFADB2BA),
  unitBlocked: Color(0xFF5A6270),
);
