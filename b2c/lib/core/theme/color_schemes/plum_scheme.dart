import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Plum" — purple primary, peach secondary, lilac canvas.
const AppColors plumScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF7F4FA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFECE6F2),
  accent: Color(0xFF5E3A9E),
  onAccent: Color(0xFFF4EFFB),
  accentSecondary: Color(0xFFE8A26A),
  onAccentSecondary: Color(0xFF241505),
  heroSurface: Color(0xFF1F162E),
  onHeroSurface: Color(0xFFF0EAF7),
  ink: Color(0xFF1D1822),
  inkMuted: Color(0xFF6C6577),
  outline: Color(0xFFE4DCEE),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFCAC5D2),
  unitBlocked: Color(0xFF5D5768),
);

/// Dark [plumScheme]: aubergine canvas, brighter violet + peach.
const AppColors plumSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF100C16),
  surface: Color(0xFF191320),
  surfaceAlt: Color(0xFF241C2E),
  accent: Color(0xFF9F80E4),
  onAccent: Color(0xFF150A29),
  accentSecondary: Color(0xFFEDB07E),
  onAccentSecondary: Color(0xFF231404),
  heroSurface: Color(0xFF241834),
  onHeroSurface: Color(0xFFF0EAF7),
  ink: Color(0xFFEEE9F4),
  inkMuted: Color(0xFF9E96AA),
  outline: Color(0xFF302639),
  success: Color(0xFF54B884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF54B884),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF473F52),
  unitBlocked: Color(0xFF6F6880),
);
