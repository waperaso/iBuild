import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Default palette, sampled from the DESIGN mockups: a lime-yellow accent on a
/// warm cream canvas with near-black ink text.
///
/// To introduce a new theme, copy this file, tweak the tokens, and register it
/// in `theme_controller.dart`. No other code needs to change.
const AppColors limeScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF4F2E8),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF1F0EA),
  accent: Color(0xFFDCEE5B),
  onAccent: Color(0xFF17181C),
  accentSecondary: Color(0xFF2C2F6B),
  onAccentSecondary: Color(0xFFF4F2E8),
  heroSurface: Color(0xFF14151A),
  onHeroSurface: Color(0xFFF4F2E8),
  ink: Color(0xFF17181C),
  // Darkened from 0xFF7C7F86 so muted body text clears WCAG AA (≈4.5:1) on the
  // cream background and white surfaces.
  inkMuted: Color(0xFF5F6169),
  outline: Color(0xFFE1DFD6),
  success: Color(0xFF2F9450),
  warning: Color(0xFFC98A12),
  danger: Color(0xFFC93B3B),
  unitAvailable: Color(0xFF7ED09A),
  unitReserved: Color(0xFFEBCB5B),
  unitSold: Color(0xFFC9CCD1),
  unitBlocked: Color(0xFF5B5E66),
);

/// Optional dark variant, kept in the same file for convenience. Wired up as an
/// alternative in `theme_controller.dart`.
const AppColors limeSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF15161A),
  surface: Color(0xFF1E2026),
  surfaceAlt: Color(0xFF272A31),
  accent: Color(0xFFDCEE5B),
  onAccent: Color(0xFF17181C),
  accentSecondary: Color(0xFF6C74F0),
  onAccentSecondary: Color(0xFF14151A),
  heroSurface: Color(0xFF23265A),
  onHeroSurface: Color(0xFFF4F4F2),
  ink: Color(0xFFF4F4F2),
  inkMuted: Color(0xFF9A9DA6),
  outline: Color(0xFF33363E),
  success: Color(0xFF57C77D),
  warning: Color(0xFFEBB93E),
  danger: Color(0xFFE86767),
  unitAvailable: Color(0xFF57C77D),
  unitReserved: Color(0xFFEBCB5B),
  unitSold: Color(0xFF4B4E56),
  unitBlocked: Color(0xFF6E727B),
);
