import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Midnight" — a deep navy primary with a bright cyan secondary on a cool
/// slate-tinted canvas. A darker, more nocturnal cousin of Sapphire; the cyan
/// keeps interactive accents lively against the sober navy.
const AppColors midnightScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF1F4F8),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE3E9F1),
  accent: Color(0xFF1E3A8A),
  onAccent: Color(0xFFEFF3FC),
  accentSecondary: Color(0xFF0E7490),
  onAccentSecondary: Color(0xFFF0FBFD),
  heroSurface: Color(0xFF0A1220),
  onHeroSurface: Color(0xFFE6ECF6),
  ink: Color(0xFF10151F),
  inkMuted: Color(0xFF555E6C),
  outline: Color(0xFFD3DBE6),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFC1690E),
  danger: Color(0xFFC6342A),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFC3CBD6),
  unitBlocked: Color(0xFF555E6C),
);

const AppColors midnightSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF080C14),
  surface: Color(0xFF10161F),
  surfaceAlt: Color(0xFF19212D),
  accent: Color(0xFF6C8FF5),
  onAccent: Color(0xFF0A1428),
  accentSecondary: Color(0xFF3EC2DF),
  onAccentSecondary: Color(0xFF041820),
  heroSurface: Color(0xFF111C2E),
  onHeroSurface: Color(0xFFE6ECF6),
  ink: Color(0xFFE9EEF7),
  inkMuted: Color(0xFF93A0B2),
  outline: Color(0xFF232D3B),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0912F),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE3BE7C),
  unitSold: Color(0xFF394454),
  unitBlocked: Color(0xFF68748A),
);
