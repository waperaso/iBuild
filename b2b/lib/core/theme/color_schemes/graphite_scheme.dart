import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Graphite" — a disciplined monochrome base (near-black primary on a light
/// gray canvas) with a single electric-blue secondary for accents and CTAs.
/// Maximum legibility; the blue does all the "pop".
const AppColors graphiteScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF4F5F6),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE9EAEC),
  accent: Color(0xFF23262B),
  onAccent: Color(0xFFF3F4F6),
  accentSecondary: Color(0xFF2563EB),
  onAccentSecondary: Color(0xFFF2F6FF),
  heroSurface: Color(0xFF16181C),
  onHeroSurface: Color(0xFFECEEF1),
  ink: Color(0xFF16181C),
  inkMuted: Color(0xFF5C616B),
  outline: Color(0xFFDCDEE2),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFC1690E),
  danger: Color(0xFFC6342A),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFC8CBD0),
  unitBlocked: Color(0xFF5C616B),
);

const AppColors graphiteSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0E0F12),
  surface: Color(0xFF17191E),
  surfaceAlt: Color(0xFF212430),
  accent: Color(0xFFE6E8EC),
  onAccent: Color(0xFF14161A),
  accentSecondary: Color(0xFF6C93F6),
  onAccentSecondary: Color(0xFF0A1428),
  heroSurface: Color(0xFF1C1F26),
  onHeroSurface: Color(0xFFECEEF1),
  ink: Color(0xFFECEEF1),
  inkMuted: Color(0xFF979CA7),
  outline: Color(0xFF2A2D35),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0912F),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE3BE7C),
  unitSold: Color(0xFF404450),
  unitBlocked: Color(0xFF6C717C),
);
