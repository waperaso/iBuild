import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Sand" — a warm desert-tan primary with a terracotta secondary on a soft
/// sandstone canvas. Earthy and calm. The tan primary is deep enough that a
/// dark foreground clears WCAG-AA.
const AppColors sandScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF8F3EA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFEFE6D5),
  accent: Color(0xFF9A6B33),
  onAccent: Color(0xFFFBF4E9),
  accentSecondary: Color(0xFFB0532F),
  onAccentSecondary: Color(0xFFFCF0EB),
  heroSurface: Color(0xFF2A2013),
  onHeroSurface: Color(0xFFF4EBD9),
  ink: Color(0xFF231D14),
  inkMuted: Color(0xFF6B6255),
  outline: Color(0xFFE7DBC6),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFBE7710),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFCFC6B5),
  unitBlocked: Color(0xFF6B6255),
);

const AppColors sandSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF15110A),
  surface: Color(0xFF1F1910),
  surfaceAlt: Color(0xFF2B2418),
  accent: Color(0xFFD9AB6A),
  onAccent: Color(0xFF241802),
  accentSecondary: Color(0xFFE08A5F),
  onAccentSecondary: Color(0xFF240E05),
  heroSurface: Color(0xFF2A2013),
  onHeroSurface: Color(0xFFF4EBD9),
  ink: Color(0xFFF2EADB),
  inkMuted: Color(0xFFA99E8B),
  outline: Color(0xFF35301F),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0912F),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE3BE7C),
  unitSold: Color(0xFF48412F),
  unitBlocked: Color(0xFF7E7460),
);
