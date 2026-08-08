import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Sapphire" — deep blue primary, silver secondary, cool ivory canvas.
const AppColors sapphireScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF4F6FA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE8ECF3),
  accent: Color(0xFF1E4FA3),
  onAccent: Color(0xFFF2F6FE),
  accentSecondary: Color(0xFFB9C2CE),
  onAccentSecondary: Color(0xFF1B222B),
  heroSurface: Color(0xFF0E1B33),
  onHeroSurface: Color(0xFFEAF0FB),
  ink: Color(0xFF171A20),
  inkMuted: Color(0xFF666C78),
  outline: Color(0xFFDDE2EB),
  success: Color(0xFF2F8F55),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD9B15A),
  unitSold: Color(0xFFC5C9D2),
  unitBlocked: Color(0xFF565B66),
);

/// Dark [sapphireScheme]: midnight-navy canvas, brighter sapphire.
const AppColors sapphireSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0C0F16),
  surface: Color(0xFF141824),
  surfaceAlt: Color(0xFF1E2333),
  accent: Color(0xFF6C93E8),
  onAccent: Color(0xFF0A1220),
  accentSecondary: Color(0xFFC4CCD8),
  onAccentSecondary: Color(0xFF161C25),
  heroSurface: Color(0xFF152444),
  onHeroSurface: Color(0xFFEAF0FB),
  ink: Color(0xFFEDF0F6),
  inkMuted: Color(0xFF979CAA),
  outline: Color(0xFF2A3040),
  success: Color(0xFF4FB37E),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4FB37E),
  unitReserved: Color(0xFFE0C070),
  unitSold: Color(0xFF454A57),
  unitBlocked: Color(0xFF6C7180),
);
