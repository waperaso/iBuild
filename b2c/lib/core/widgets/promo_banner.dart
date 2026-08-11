import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'pill_button.dart';

/// Dark gradient hero block for a single offer/CTA.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.auto_awesome,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        color: colors.heroSurface,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -16,
            top: -28,
            child: Icon(
              icon,
              size: 130,
              color: colors.onHeroSurface.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onHeroSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onHeroSurface.withValues(alpha: 0.78),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: actionLabel,
                variant: PillButtonVariant.hero,
                onPressed: onAction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
