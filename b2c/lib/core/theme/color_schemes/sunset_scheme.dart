import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Sunset" — coral-orange primary, plum secondary, blush canvas.
const AppColors sunsetScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFFBF4F0),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF4E7DF),
  accent: Color(0xFFC0492B),
  onAccent: Color(0xFFFDF1EC),
  accentSecondary: Color(0xFF5B3A6B),
  onAccentSecondary: Color(0xFFF6EEF8),
  heroSurface: Color(0xFF2A1620),
  onHeroSurface: Color(0xFFF9EBE4),
  ink: Color(0xFF221815),
  inkMuted: Color(0xFF7A665F),
  outline: Color(0xFFEEDDD3),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFB53225),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFDDA15A),
  unitSold: Color(0xFFD2C4BC),
  unitBlocked: Color(0xFF6B584F),
);

/// Dark [sunsetScheme]: warm charcoal canvas, brighter coral + plum.
const AppColors sunsetSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF150E0C),
  surface: Color(0xFF1F1613),
  surfaceAlt: Color(0xFF2B1F1B),
  accent: Color(0xFFE8836A),
  onAccent: Color(0xFF2A0F08),
  accentSecondary: Color(0xFFB48ECB),
  onAccentSecondary: Color(0xFF1F1226),
  heroSurface: Color(0xFF2E1A22),
  onHeroSurface: Color(0xFFF9EBE4),
  ink: Color(0xFFF3E7E2),
  inkMuted: Color(0xFFAC968E),
  outline: Color(0xFF362824),
  success: Color(0xFF54B884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE87060),
  unitAvailable: Color(0xFF54B884),
  unitReserved: Color(0xFFE0B06E),
  unitSold: Color(0xFF4C3E39),
  unitBlocked: Color(0xFF7C6960),
);
