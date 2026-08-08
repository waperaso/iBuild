import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Rose" — rose primary, charcoal secondary, pink-tinted canvas.
const AppColors roseScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFFAF4F5),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF2E6E9),
  accent: Color(0xFFB03A5B),
  onAccent: Color(0xFFFDEFF3),
  accentSecondary: Color(0xFF33323A),
  onAccentSecondary: Color(0xFFF1F0F3),
  heroSurface: Color(0xFF261A1E),
  onHeroSurface: Color(0xFFF7E9ED),
  ink: Color(0xFF201A1C),
  inkMuted: Color(0xFF75656A),
  outline: Color(0xFFECDCE0),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFCFC3C6),
  unitBlocked: Color(0xFF67585C),
);

/// Dark [roseScheme]: mauve-charcoal canvas, brighter rose.
const AppColors roseSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF130F10),
  surface: Color(0xFF1D1618),
  surfaceAlt: Color(0xFF281F22),
  accent: Color(0xFFE0748F),
  onAccent: Color(0xFF2A0C16),
  accentSecondary: Color(0xFFCBC7CE),
  onAccentSecondary: Color(0xFF1A181C),
  heroSurface: Color(0xFF2A1C21),
  onHeroSurface: Color(0xFFF7E9ED),
  ink: Color(0xFFF2E7EA),
  inkMuted: Color(0xFFA5959A),
  outline: Color(0xFF33282B),
  success: Color(0xFF54B884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE87060),
  unitAvailable: Color(0xFF54B884),
  unitReserved: Color(0xFFE0B96E),
  unitSold: Color(0xFF483C3F),
  unitBlocked: Color(0xFF786569),
);
