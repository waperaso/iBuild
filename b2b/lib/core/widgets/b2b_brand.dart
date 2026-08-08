import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'brand_mark.dart';

/// Sidebar / auth header mark with the **iBuild B2B** product label.
class B2bBrand extends StatelessWidget {
  const B2bBrand({super.key, this.compact = false, this.onDark});

  final bool compact;

  /// Force logo/wordmark for a dark surface (e.g. auth hero). When null,
  /// follows [ThemeData.brightness] — dark mark on light theme, light mark
  /// on dark theme.
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final onDarkSurface =
        onDark ?? Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: compact ? 32 : 36, onDark: onDark),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'iBuild',
              style: (compact ? textTheme.titleMedium : textTheme.titleLarge)
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onDarkSurface ? colors.onHeroSurface : null,
                  ),
            ),
            Text(
              'B2B',
              style: textTheme.labelSmall?.copyWith(
                color: colors.accentSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
