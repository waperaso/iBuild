import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'b2b_brand.dart';

/// Decorative left panel for wide auth/onboarding layouts.
class AuthHeroPanel extends StatelessWidget {
  const AuthHeroPanel({super.key});

  /// Panel width; show only when there's room for this plus a form column.
  static const double width = 420;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final onHero = colors.onHeroSurface;

    return Container(
      width: width,
      color: colors.heroSurface,
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -70,
            child: _Blob(size: 220, color: onHero.withValues(alpha: 0.05)),
          ),
          Positioned(
            left: -90,
            bottom: -60,
            child: _Blob(
              size: 260,
              color: colors.accentSecondary.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.xxxl,
              AppSpacing.xxl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const B2bBrand(onDark: true),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  l10n.authHeroTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: onHero,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.authHeroSubtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: onHero.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _HeroPoint(
                  icon: Icons.verified_outlined,
                  text: l10n.authHeroPointVerified,
                ),
                const SizedBox(height: AppSpacing.lg),
                _HeroPoint(
                  icon: Icons.forum_outlined,
                  text: l10n.authHeroPointLeads,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPoint extends StatelessWidget {
  const _HeroPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final onHero = colors.onHeroSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: onHero.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, size: 18, color: colors.accentSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: onHero.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
