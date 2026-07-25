import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'brand_mark.dart';

/// Sidebar / auth header mark with the **iBuild B2B** product label.
class B2bBrand extends StatelessWidget {
  const B2bBrand({super.key, this.compact = false, this.onDark = false});

  final bool compact;

  /// Set on a dark hero panel (e.g. the desktop auth split-screen) so the
  /// "iBuild" wordmark switches to a light color instead of near-invisible
  /// dark-ink-on-dark-surface.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: compact ? 32 : 36),
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
                    color: onDark ? colors.onHeroSurface : null,
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
