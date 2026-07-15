import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Aurora" — a calm ivory canvas with a confident deep-indigo primary and a
/// warm amber secondary. Mirrors the B2C palette of the same name so the two
/// surfaces stay visually related, tuned for WCAG-AA foreground contrast.
const AppColors auroraScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF7F6F2),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFEEEDE6),
  accent: Color(0xFF3A4CA8),
  onAccent: Color(0xFFF7F8FE),
  accentSecondary: Color(0xFFE79A2B),
  onAccentSecondary: Color(0xFF201603),
  heroSurface: Color(0xFF171A2E),
  onHeroSurface: Color(0xFFF3F4FB),
  ink: Color(0xFF1B1D24),
  inkMuted: Color(0xFF6C707B),
  outline: Color(0xFFE3E1D9),
  success: Color(0xFF2F8F55),
  warning: Color(0xFFC9860F),
  danger: Color(0xFFCB3F3F),
  unitAvailable: Color(0xFF6FBF8E),
  unitReserved: Color(0xFFE6C24E),
  unitSold: Color(0xFFC7C9D0),
  unitBlocked: Color(0xFF565A64),
);

/// Dark variant: a deep slate canvas with a brightened indigo so the primary
/// stays legible on dark surfaces.
const AppColors auroraSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF13141B),
  surface: Color(0xFF1C1E28),
  surfaceAlt: Color(0xFF262935),
  accent: Color(0xFF8994F0),
  onAccent: Color(0xFF12142A),
  accentSecondary: Color(0xFFEBB05A),
  onAccentSecondary: Color(0xFF1E1503),
  heroSurface: Color(0xFF232741),
  onHeroSurface: Color(0xFFF1F2FA),
  ink: Color(0xFFF2F3F8),
  inkMuted: Color(0xFF9A9EAB),
  outline: Color(0xFF32353F),
  success: Color(0xFF54C07D),
  warning: Color(0xFFE7B94A),
  danger: Color(0xFFE56B6B),
  unitAvailable: Color(0xFF54C07D),
  unitReserved: Color(0xFFE6C24E),
  unitSold: Color(0xFF474A54),
  unitBlocked: Color(0xFF6B6F79),
);
