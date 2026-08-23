import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'brand_mark.dart';

/// Sidebar / auth header mark with the **iBuild** wordmark and a role-aware
/// B2B subtitle (`B2B | Platform admin` / `B2B | Residence admin` / plain
/// `B2B` before sign-in).
class B2bBrand extends ConsumerWidget {
  const B2bBrand({super.key, this.compact = false, this.onDark});

  final bool compact;

  /// Force logo/wordmark for a dark surface (e.g. auth hero). When null,
  /// follows [ThemeData.brightness] — dark mark on light theme, light mark
  /// on dark theme.
  final bool? onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final onDarkSurface =
        onDark ?? Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authControllerProvider).value;
    final subtitle = user?.isSystemAdmin == true
        ? l10n.brandSubtitlePlatform
        : user?.isResidenceAdmin == true
            ? l10n.brandSubtitleResidence
            : l10n.brandSubtitle;

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
              subtitle,
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
