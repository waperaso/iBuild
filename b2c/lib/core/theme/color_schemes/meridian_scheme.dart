import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Meridian" — the default palette, chosen after a competitor sweep of
/// global proptech portals (Zillow, Redfin, Airbnb) and local classifieds
/// (Uybor, OLX.uz) alongside luxury brokerages (Compass, Sotheby's,
/// Century 21).
///
/// Findings that shaped the tokens:
/// - Digital portals lean on saturated tech-blue/red/purple, which reads as
///   "classifieds" rather than a considered real-estate brand, and is where
///   every local competitor already lives.
/// - Luxury brokerages succeed with a disciplined, near-monochrome base and
///   a single confident accent — restraint signals trust for a high-value
///   transaction; 2026 brand trend data also flags a shift away from cool
///   grays toward warm, editorial neutrals.
///
/// Meridian applies that discipline: a warm ivory/graphite neutral base (not
/// another blue/red/purple portal), a deep jewel-toned teal primary (trust
/// and stability without colliding with the green "success" status color),
/// and a muted brass/champagne secondary reserved for premium moments
/// (subscriptions, featured badges, hero panels) — the same "gold on
/// charcoal" cue luxury real-estate brands use for perceived prestige.
const AppColors meridianScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF6F3EA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFEFEADD),
  accent: Color(0xFF0F5C56),
  onAccent: Color(0xFFF3FBF9),
  accentSecondary: Color(0xFFAD8036),
  onAccentSecondary: Color(0xFF211505),
  heroSurface: Color(0xFF12191A),
  onHeroSurface: Color(0xFFF6F2E6),
  ink: Color(0xFF1B1C1A),
  inkMuted: Color(0xFF69675F),
  outline: Color(0xFFE3DDCE),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFC1690E),
  danger: Color(0xFFB3392B),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFC7C2B7),
  unitBlocked: Color(0xFF5B564C),
);

/// Dark variant of [meridianScheme]: a near-black canvas with a teal undertone
/// so the deep hero/charcoal treatment carries through instead of defaulting
/// to a generic gray dark mode.
const AppColors meridianSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0F1412),
  surface: Color(0xFF161C1A),
  surfaceAlt: Color(0xFF1E2523),
  accent: Color(0xFF2FA79C),
  onAccent: Color(0xFF08201D),
  accentSecondary: Color(0xFFD9AC5C),
  onAccentSecondary: Color(0xFF241705),
  heroSurface: Color(0xFF0C1615),
  onHeroSurface: Color(0xFFF3EFE4),
  ink: Color(0xFFF1EEE4),
  inkMuted: Color(0xFFA3A099),
  outline: Color(0xFF2B322F),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0912F),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE3BE7C),
  unitSold: Color(0xFF4A4740),
  unitBlocked: Color(0xFF716D63),
);
