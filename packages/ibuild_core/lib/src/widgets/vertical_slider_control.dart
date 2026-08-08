import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact vertical slider rail (+/− buttons) for map zoom and similar controls.
class VerticalSliderControl extends StatelessWidget {
  const VerticalSliderControl({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onIncrease,
    required this.onDecrease,
    required this.increaseTooltip,
    required this.decreaseTooltip,
    required this.colors,
    this.trackHeight = 112,
    this.compact = false,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final String increaseTooltip;
  final String decreaseTooltip;
  final AppColors colors;
  final double trackHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = colors.brightness == Brightness.dark;
    final clamped = value.clamp(min, max);
    final iconSize = compact ? 14.0 : 18.0;
    final buttonSize = compact ? 28.0 : 36.0;
    final railWidth = compact ? 26.0 : 32.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: isDark ? 0.94 : 0.97),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.outline.withValues(alpha: isDark ? 0.55 : 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: isDark ? 0.28 : 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RailIconButton(
              tooltip: increaseTooltip,
              icon: Icons.add,
              iconSize: iconSize,
              size: buttonSize,
              enabled: onIncrease != null,
              colors: colors,
              onPressed: onIncrease,
            ),
            SizedBox(
              width: railWidth,
              height: trackHeight,
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: clamped,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
            _RailIconButton(
              tooltip: decreaseTooltip,
              icon: Icons.remove,
              iconSize: iconSize,
              size: buttonSize,
              enabled: onDecrease != null,
              colors: colors,
              onPressed: onDecrease,
            ),
          ],
        ),
      ),
    );
  }
}

class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
    required this.tooltip,
    required this.icon,
    required this.iconSize,
    required this.size,
    required this.enabled,
    required this.colors,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final double iconSize;
  final double size;
  final bool enabled;
  final AppColors colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      iconSize: iconSize,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: enabled ? colors.ink : colors.inkMuted.withValues(alpha: 0.45),
      ),
    );
  }
}
