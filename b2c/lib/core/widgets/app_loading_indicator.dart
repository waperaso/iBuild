import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Branded circular loader — uses the active palette accent, never Material blue.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.6,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.accent;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: accent,
        backgroundColor: accent.withValues(alpha: 0.12),
      ),
    );
  }
}

/// Compact indeterminate bar used on splash / inline waits.
class AppLoadingBar extends StatelessWidget {
  const AppLoadingBar({super.key, this.width = 120, this.height = 3});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: LinearProgressIndicator(
          backgroundColor: colors.surfaceAlt,
          color: colors.accent,
        ),
      ),
    );
  }
}
