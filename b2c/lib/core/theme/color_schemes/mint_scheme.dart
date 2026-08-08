import 'package:flutter/material.dart';

import '../app_colors.dart';

/// "Mint" — teal-green primary (dark enough for white text), slate secondary.
const AppColors mintScheme = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF0F6F2),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE1EEE7),
  accent: Color(0xFF1C7C63),
  onAccent: Color(0xFFEEFAF5),
  accentSecondary: Color(0xFF3B4A55),
  onAccentSecondary: Color(0xFFEEF2F5),
  heroSurface: Color(0xFF10221C),
  onHeroSurface: Color(0xFFE6F4EE),
  ink: Color(0xFF141F1B),
  inkMuted: Color(0xFF5E6E68),
  outline: Color(0xFFD5E6DE),
  success: Color(0xFF2F8B54),
  warning: Color(0xFFC1770E),
  danger: Color(0xFFC0392B),
  unitAvailable: Color(0xFF3FA786),
  unitReserved: Color(0xFFD9AE5C),
  unitSold: Color(0xFFC2CFC9),
  unitBlocked: Color(0xFF52625B),
);

/// Dark [mintScheme]: spruce canvas, brighter mint + slate.
const AppColors mintSchemeDark = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF08120F),
  surface: Color(0xFF101C18),
  surfaceAlt: Color(0xFF192824),
  accent: Color(0xFF48C6A4),
  onAccent: Color(0xFF042019),
  accentSecondary: Color(0xFFAFC0CB),
  onAccentSecondary: Color(0xFF141C21),
  heroSurface: Color(0xFF0F2620),
  onHeroSurface: Color(0xFFE6F4EE),
  ink: Color(0xFFE6F2ED),
  inkMuted: Color(0xFF8D9F98),
  outline: Color(0xFF243430),
  success: Color(0xFF4FB884),
  warning: Color(0xFFE0A038),
  danger: Color(0xFFE06A55),
  unitAvailable: Color(0xFF4FC6A4),
  unitReserved: Color(0xFFE0BE6E),
  unitSold: Color(0xFF3E4C47),
  unitBlocked: Color(0xFF667772),
);
