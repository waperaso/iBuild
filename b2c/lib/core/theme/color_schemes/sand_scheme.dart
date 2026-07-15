import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Sand" — a warm desert-tan base with a grounded terracotta primary, evoking
/// sunbaked adobe. The secondary is a deep olive-brown for contrast.
/// Foregrounds clear WCAG AA on their surfaces.
const AppColors sandScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF7F1E7),
  surface: Color(0xFFFFFDF9),
  surfaceAlt: Color(0xFFEFE6D6),
  accent: Color(0xFFB25A34),
  onAccent: Color(0xFFFCF2EB),
  accentSecondary: Color(0xFF5C5230),
  onAccentSecondary: Color(0xFFF4F1E4),
  heroSurface: Color(0xFF2A2116),
  onHeroSurface: Color(0xFFF4EBDC),
  ink: Color(0xFF211C14),
  inkMuted: Color(0xFF746B58),
  outline: Color(0xFFE7DBC6),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFBE7810),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD6A64F),
  unitSold: Color(0xFFCEC4B2),
  unitBlocked: Color(0xFF6A6049),
);

/// Dark variant of [sandScheme]: a deep espresso canvas with a brightened
/// terracotta primary and a warm khaki secondary.
const AppColors sandSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF12100B),
  surface: Color(0xFF1C1812),
  surfaceAlt: Color(0xFF29231A),
  accent: Color(0xFFDE8B62),
  onAccent: Color(0xFF2A1206),
  accentSecondary: Color(0xFFCEC08A),
  onAccentSecondary: Color(0xFF1E1B0C),
  heroSurface: Color(0xFF2B2317),
  onHeroSurface: Color(0xFFF4EBDC),
  ink: Color(0xFFF1E9DA),
  inkMuted: Color(0xFFA69B84),
  outline: Color(0xFF342C20),
  success: Color(0xFF54B884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF54B884),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF4A4132),
  unitBlocked: Color(0xFF786D56),
);
