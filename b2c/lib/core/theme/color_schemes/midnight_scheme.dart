import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Midnight" — a deep navy primary on a cool pale-blue canvas, lit by a bright
/// cyan secondary for a nocturnal, high-tech pairing. Foregrounds clear WCAG AA
/// on their surfaces.
const AppColors midnightScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF1F4F8),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE3E9F1),
  accent: Color(0xFF1B2F63),
  onAccent: Color(0xFFEDF1F9),
  accentSecondary: Color(0xFF0E8FA6),
  onAccentSecondary: Color(0xFFEDFAFC),
  heroSurface: Color(0xFF0C1430),
  onHeroSurface: Color(0xFFE7ECF7),
  ink: Color(0xFF161A24),
  inkMuted: Color(0xFF616779),
  outline: Color(0xFFD7DEEA),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF4DA47A),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFC3C9D5),
  unitBlocked: Color(0xFF535A6B),
);

/// Dark variant of [midnightScheme]: a near-black indigo canvas with a
/// brightened periwinkle primary and a vivid cyan secondary.
const AppColors midnightSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF080B14),
  surface: Color(0xFF10131F),
  surfaceAlt: Color(0xFF191E2E),
  accent: Color(0xFF7C93E0),
  onAccent: Color(0xFF0A1028),
  accentSecondary: Color(0xFF3ECBDE),
  onAccentSecondary: Color(0xFF04212A),
  heroSurface: Color(0xFF121B3B),
  onHeroSurface: Color(0xFFE7ECF7),
  ink: Color(0xFFE8ECF5),
  inkMuted: Color(0xFF929AAE),
  outline: Color(0xFF232838),
  success: Color(0xFF4FB884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4FB884),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF3F4557),
  unitBlocked: Color(0xFF636B7F),
);
