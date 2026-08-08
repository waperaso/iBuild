import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Ocean" — cyan-teal primary, navy secondary, seafoam canvas.
const AppColors oceanScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF0F6F7),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE0EEF0),
  accent: Color(0xFF0E7C86),
  onAccent: Color(0xFFEFFBFB),
  accentSecondary: Color(0xFF163A5E),
  onAccentSecondary: Color(0xFFEAF1F8),
  heroSurface: Color(0xFF0B2129),
  onHeroSurface: Color(0xFFE6F3F4),
  ink: Color(0xFF13201F),
  inkMuted: Color(0xFF5E6F70),
  outline: Color(0xFFD5E6E7),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF3FA79A),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFC1CFD0),
  unitBlocked: Color(0xFF51625F),
);

/// Dark [oceanScheme]: deep navy canvas, brighter cyan-teal.
const AppColors oceanSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF08110F),
  surface: Color(0xFF101B1A),
  surfaceAlt: Color(0xFF192726),
  accent: Color(0xFF3CBDC2),
  onAccent: Color(0xFF04201F),
  accentSecondary: Color(0xFF77A6D6),
  onAccentSecondary: Color(0xFF081726),
  heroSurface: Color(0xFF0E2830),
  onHeroSurface: Color(0xFFE6F3F4),
  ink: Color(0xFFE7F2F1),
  inkMuted: Color(0xFF8FA1A1),
  outline: Color(0xFF243433),
  success: Color(0xFF4FB884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4FB8B0),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF3E4C4B),
  unitBlocked: Color(0xFF677776),
);
