import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Ocean" — a bright cyan-teal primary grounded by a deep navy secondary on a
/// cool aqua-tinted canvas. Fresh and clean for a data-heavy admin surface.
const AppColors oceanScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFEFF6F7),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFDFEDEF),
  accent: Color(0xFF0E7490),
  onAccent: Color(0xFFF0FBFD),
  accentSecondary: Color(0xFF1E3A5F),
  onAccentSecondary: Color(0xFFEEF3F9),
  heroSurface: Color(0xFF0A2230),
  onHeroSurface: Color(0xFFE6F1F4),
  ink: Color(0xFF11212A),
  inkMuted: Color(0xFF556269),
  outline: Color(0xFFD1E2E5),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFC1690E),
  danger: Color(0xFFC6342A),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFC3CFD2),
  unitBlocked: Color(0xFF556269),
);

const AppColors oceanSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF08161C),
  surface: Color(0xFF102028),
  surfaceAlt: Color(0xFF192D36),
  accent: Color(0xFF3EC2DF),
  onAccent: Color(0xFF041820),
  accentSecondary: Color(0xFF7FA8D6),
  onAccentSecondary: Color(0xFF0A1826),
  heroSurface: Color(0xFF0E2833),
  onHeroSurface: Color(0xFFE6F1F4),
  ink: Color(0xFFE8F2F4),
  inkMuted: Color(0xFF94A5AC),
  outline: Color(0xFF243943),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0912F),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE3BE7C),
  unitSold: Color(0xFF3B4E57),
  unitBlocked: Color(0xFF69797F),
);
