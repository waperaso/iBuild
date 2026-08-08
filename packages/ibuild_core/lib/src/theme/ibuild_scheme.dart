import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Official iBuild brand palette — navy "IB" on cool gray (see `assets/brand/`).
const AppColors ibuildScheme = AppColors(
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

/// Dark [ibuildScheme]: deep navy canvas matching the dark logo plate.
const AppColors ibuildSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0A1F35),
  surface: Color(0xFF122840),
  surfaceAlt: Color(0xFF1E3348),
  accent: Color(0xFFC8CCD2),
  onAccent: Color(0xFF0A1F35),
  accentSecondary: Color(0xFF4A7EC7),
  onAccentSecondary: Color(0xFFE8EAED),
  heroSurface: Color(0xFF0A1F35),
  onHeroSurface: Color(0xFFC8CCD2),
  ink: Color(0xFFE8EAED),
  inkMuted: Color(0xFF9AA3AD),
  outline: Color(0xFF2E3640),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE0C070),
  unitSold: Color(0xFF454A57),
  unitBlocked: Color(0xFF6C7180),
);

/// Light-theme logo — navy "IB" on cool gray.
const String ibuildLogoAsset = 'assets/brand/ibuild-logo.jpg';

/// Dark-theme logo — silver "IB" on deep navy.
const String ibuildLogoDarkAsset = 'assets/brand/ibuild-logo-dark.png';
