import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Crimson" — a deep, assured crimson primary on a warm bone canvas, paired
/// with an antique-gold secondary for a heraldic, high-trust feel. The primary
/// is deliberately darker than the [AppColors.danger] token so the two never
/// collide. Foregrounds clear WCAG AA on their surfaces.
const AppColors crimsonScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF9F3F1),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF0E3DF),
  accent: Color(0xFF9E2233),
  onAccent: Color(0xFFFBEDEE),
  accentSecondary: Color(0xFFA67C22),
  onAccentSecondary: Color(0xFF221803),
  heroSurface: Color(0xFF261417),
  onHeroSurface: Color(0xFFF6E7E7),
  ink: Color(0xFF201818),
  inkMuted: Color(0xFF75625F),
  outline: Color(0xFFEBD9D5),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFD14A3C),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFCFC2BF),
  unitBlocked: Color(0xFF67595A),
);

/// Dark variant of [crimsonScheme]: a deep oxblood canvas with a brightened
/// crimson primary and a warm gold secondary.
const AppColors crimsonSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF130D0D),
  surface: Color(0xFF1D1515),
  surfaceAlt: Color(0xFF291D1E),
  accent: Color(0xFFDE5E6E),
  onAccent: Color(0xFF2A0910),
  accentSecondary: Color(0xFFD9B25E),
  onAccentSecondary: Color(0xFF201704),
  heroSurface: Color(0xFF2A171B),
  onHeroSurface: Color(0xFFF6E7E7),
  ink: Color(0xFFF2E6E6),
  inkMuted: Color(0xFFA69192),
  outline: Color(0xFF342526),
  success: Color(0xFF54B884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE87060),
  unitAvailable: Color(0xFF54B884),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF493B3C),
  unitBlocked: Color(0xFF786566),
);
