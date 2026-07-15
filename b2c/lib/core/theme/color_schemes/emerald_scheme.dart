import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Emerald" — a rich forest-green primary on a warm parchment canvas, with a
/// restrained antique-gold secondary for premium accents. Foregrounds clear
/// WCAG AA on their surfaces.
const AppColors emeraldScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF4F6F0),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE8EDE2),
  accent: Color(0xFF1F6B47),
  onAccent: Color(0xFFF1FBF4),
  accentSecondary: Color(0xFFB08528),
  onAccentSecondary: Color(0xFF221803),
  heroSurface: Color(0xFF102019),
  onHeroSurface: Color(0xFFEBF3ED),
  ink: Color(0xFF16201A),
  inkMuted: Color(0xFF63705F),
  outline: Color(0xFFDCE4D6),
  success: Color(0xFF2E8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF43A574),
  unitReserved: Color(0xFFD7B155),
  unitSold: Color(0xFFC6CCC0),
  unitBlocked: Color(0xFF556157),
);

/// Dark variant of [emeraldScheme]: a deep pine canvas with a brightened
/// emerald primary and a warmer gold that reads clearly on dark surfaces.
const AppColors emeraldSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0B120E),
  surface: Color(0xFF131C16),
  surfaceAlt: Color(0xFF1D2820),
  accent: Color(0xFF44B584),
  onAccent: Color(0xFF06180F),
  accentSecondary: Color(0xFFD9B25E),
  onAccentSecondary: Color(0xFF201704),
  heroSurface: Color(0xFF11241B),
  onHeroSurface: Color(0xFFEBF3ED),
  ink: Color(0xFFEBF1EC),
  inkMuted: Color(0xFF93A197),
  outline: Color(0xFF29352D),
  success: Color(0xFF4FB884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4FB884),
  unitReserved: Color(0xFFDEBE6E),
  unitSold: Color(0xFF434E46),
  unitBlocked: Color(0xFF6A776D),
);
