import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware scrollbar — pill thumb, subtle track on hover/drag.
ScrollbarThemeData buildIbuildScrollbarTheme(AppColors colors) {
  final isDark = colors.brightness == Brightness.dark;

  Color thumbColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.dragged)) {
      return colors.accent.withValues(alpha: isDark ? 0.92 : 0.88);
    }
    if (states.contains(WidgetState.hovered)) {
      return colors.inkMuted.withValues(alpha: isDark ? 0.78 : 0.68);
    }
    return colors.inkMuted.withValues(alpha: isDark ? 0.48 : 0.38);
  }

  Color trackColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.dragged)) {
      return colors.outline.withValues(alpha: isDark ? 0.42 : 0.32);
    }
    if (states.contains(WidgetState.hovered)) {
      return colors.outline.withValues(alpha: isDark ? 0.32 : 0.22);
    }
    return colors.outline.withValues(alpha: isDark ? 0.18 : 0.12);
  }

  return ScrollbarThemeData(
    interactive: true,
    thickness: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.dragged) ||
          states.contains(WidgetState.hovered)) {
        return 8;
      }
      return 6;
    }),
    radius: const Radius.circular(999),
    crossAxisMargin: 4,
    mainAxisMargin: 8,
    minThumbLength: 44,
    thumbVisibility: const WidgetStatePropertyAll(true),
    trackVisibility: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.dragged) ||
          states.contains(WidgetState.hovered)) {
        return true;
      }
      return false;
    }),
    thumbColor: WidgetStateProperty.resolveWith(thumbColor),
    trackColor: WidgetStateProperty.resolveWith(trackColor),
    trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

/// Shared [Slider] styling for zoom rails, calculators, and filter sheets.
SliderThemeData buildIbuildSliderTheme(AppColors colors) {
  final isDark = colors.brightness == Brightness.dark;

  return SliderThemeData(
    activeTrackColor: colors.accent.withValues(alpha: isDark ? 0.92 : 0.86),
    inactiveTrackColor: colors.outline.withValues(alpha: isDark ? 0.55 : 0.45),
    secondaryActiveTrackColor: colors.accentSecondary.withValues(alpha: 0.55),
    thumbColor: colors.accent,
    overlayColor: colors.accent.withValues(alpha: 0.14),
    valueIndicatorColor: colors.accent,
    valueIndicatorTextStyle: TextStyle(
      color: colors.onAccent,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    disabledActiveTrackColor: colors.outline.withValues(alpha: 0.35),
    disabledInactiveTrackColor: colors.outline.withValues(alpha: 0.2),
    disabledThumbColor: colors.inkMuted.withValues(alpha: 0.45),
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 7,
      disabledThumbRadius: 6,
      elevation: 1,
    ),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    trackShape: const RoundedRectSliderTrackShape(),
  );
}
