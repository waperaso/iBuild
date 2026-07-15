import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Graphite" — a disciplined near-monochrome base (graphite ink on a cool
/// stone canvas) with a single electric-blue accent for interactive moments.
/// Foregrounds clear WCAG AA on their surfaces.
const AppColors graphiteScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF4F5F6),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE9EAEC),
  accent: Color(0xFF2A2D33),
  onAccent: Color(0xFFF3F4F6),
  accentSecondary: Color(0xFF1E6BE6),
  onAccentSecondary: Color(0xFFEFF5FE),
  heroSurface: Color(0xFF17191D),
  onHeroSurface: Color(0xFFECEDEF),
  ink: Color(0xFF191B1E),
  inkMuted: Color(0xFF696D74),
  outline: Color(0xFFDDDFE3),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFC8CACE),
  unitBlocked: Color(0xFF585B61),
);

/// Dark variant of [graphiteScheme]: a true charcoal canvas with a brightened
/// electric blue that pops against the neutral surfaces.
const AppColors graphiteSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0D0E10),
  surface: Color(0xFF16181B),
  surfaceAlt: Color(0xFF212327),
  accent: Color(0xFFD7D9DD),
  onAccent: Color(0xFF17191D),
  accentSecondary: Color(0xFF5B95F2),
  onAccentSecondary: Color(0xFF08132A),
  heroSurface: Color(0xFF1B1E22),
  onHeroSurface: Color(0xFFECEDEF),
  ink: Color(0xFFECEDEF),
  inkMuted: Color(0xFF979AA1),
  outline: Color(0xFF2B2E33),
  success: Color(0xFF54B884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF54B884),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF44474D),
  unitBlocked: Color(0xFF6C7078),
);
