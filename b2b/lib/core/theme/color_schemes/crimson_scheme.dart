import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Crimson" — deep red primary, gold secondary, warm off-white canvas.
/// Danger token is a distinct orange-red for status readability.
const AppColors crimsonScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFFAF3F1),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF3E2DE),
  accent: Color(0xFFA51D2D),
  onAccent: Color(0xFFFDEFEE),
  accentSecondary: Color(0xFF9A7B1E),
  onAccentSecondary: Color(0xFFFBF7EA),
  heroSurface: Color(0xFF29120F),
  onHeroSurface: Color(0xFFF5E5E2),
  ink: Color(0xFF221614),
  inkMuted: Color(0xFF6C5B57),
  outline: Color(0xFFEAD4CF),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFC1690E),
  danger: Color(0xFFD2452F),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFD2C2BD),
  unitBlocked: Color(0xFF6C5B57),
);

const AppColors crimsonSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF160D0C),
  surface: Color(0xFF201413),
  surfaceAlt: Color(0xFF2C1D1B),
  accent: Color(0xFFE86173),
  onAccent: Color(0xFF2A0810),
  accentSecondary: Color(0xFFD9B45C),
  onAccentSecondary: Color(0xFF1E1704),
  heroSurface: Color(0xFF2A1512),
  onHeroSurface: Color(0xFFF5E5E2),
  ink: Color(0xFFF3E5E2),
  inkMuted: Color(0xFFAD9793),
  outline: Color(0xFF362523),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0912F),
  danger: Color(0xFFEE6B54),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE3BE7C),
  unitSold: Color(0xFF47352F),
  unitBlocked: Color(0xFF816D68),
);
