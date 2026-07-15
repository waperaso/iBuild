import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Mint" — a soft mint-green primary with a cool slate secondary on a pale
/// mint canvas. Light and airy; the primary is a deep teal-green so its
/// foreground stays legible, while surfaces keep the fresh mint feel.
const AppColors mintScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFEFF7F3),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFDFEEE7),
  accent: Color(0xFF0F766E),
  onAccent: Color(0xFFF0FBF8),
  accentSecondary: Color(0xFF475569),
  onAccentSecondary: Color(0xFFF1F5F9),
  heroSurface: Color(0xFF0C231F),
  onHeroSurface: Color(0xFFE6F3EE),
  ink: Color(0xFF122019),
  inkMuted: Color(0xFF556660),
  outline: Color(0xFFD2E4DD),
  success: Color(0xFF2E8B57),
  warning: Color(0xFFC1690E),
  danger: Color(0xFFC6342A),
  unitAvailable: Color(0xFF3FA97A),
  unitReserved: Color(0xFFD9AE64),
  unitSold: Color(0xFFC3D0CA),
  unitBlocked: Color(0xFF556660),
);

const AppColors mintSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF08150F),
  surface: Color(0xFF101F19),
  surfaceAlt: Color(0xFF192B24),
  accent: Color(0xFF3FC0AE),
  onAccent: Color(0xFF04201B),
  accentSecondary: Color(0xFF9FB0C6),
  onAccentSecondary: Color(0xFF0E1626),
  heroSurface: Color(0xFF0E2620),
  onHeroSurface: Color(0xFFE6F3EE),
  ink: Color(0xFFE7F3EE),
  inkMuted: Color(0xFF93A69E),
  outline: Color(0xFF23372F),
  success: Color(0xFF4CB27E),
  warning: Color(0xFFE0912F),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4CB27E),
  unitReserved: Color(0xFFE3BE7C),
  unitSold: Color(0xFF39493F),
  unitBlocked: Color(0xFF687A72),
);
