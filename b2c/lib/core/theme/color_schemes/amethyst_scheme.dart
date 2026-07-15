import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Amethyst" — a vivid violet primary on a cool lavender-white canvas, sparked
/// by a fresh lime secondary for a bold, energetic contrast. The lime is
/// darkened enough for dark text to clear WCAG AA. Foregrounds clear WCAG AA on
/// their surfaces.
const AppColors amethystScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF6F4FB),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFEAE5F4),
  accent: Color(0xFF6A34C7),
  onAccent: Color(0xFFF3EEFC),
  accentSecondary: Color(0xFFA9C734),
  onAccentSecondary: Color(0xFF1B2103),
  heroSurface: Color(0xFF1C1533),
  onHeroSurface: Color(0xFFEFEAF9),
  ink: Color(0xFF1B1826),
  inkMuted: Color(0xFF696478),
  outline: Color(0xFFE2DBF0),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFC8C3D4),
  unitBlocked: Color(0xFF5B5569),
);

/// Dark variant of [amethystScheme]: a deep indigo-violet canvas with a
/// brightened amethyst primary and a vivid lime secondary.
const AppColors amethystSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0E0B16),
  surface: Color(0xFF171221),
  surfaceAlt: Color(0xFF221B30),
  accent: Color(0xFFA981EC),
  onAccent: Color(0xFF160830),
  accentSecondary: Color(0xFFC3E05A),
  onAccentSecondary: Color(0xFF1B2103),
  heroSurface: Color(0xFF231838),
  onHeroSurface: Color(0xFFEFEAF9),
  ink: Color(0xFFEDE9F5),
  inkMuted: Color(0xFF9B95AC),
  outline: Color(0xFF2E263B),
  success: Color(0xFF54B884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF54B884),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF453E54),
  unitBlocked: Color(0xFF6D6782),
);
