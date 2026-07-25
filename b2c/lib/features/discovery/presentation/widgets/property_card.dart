import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart' hide PressableScale;

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../favorites/providers/favorites_providers.dart';

/// Property card matching the "Recommend for You" cards in the mockups, now
/// image-forward: the cover photo fills most of the card and carries the
/// name/price directly on a gradient overlay (Airbnb/Zillow style) instead
/// of a plain white block below, with a hover-lift on desktop/web via
/// [PressableScale].
class PropertyCard extends ConsumerWidget {
  const PropertyCard({super.key, required this.project, this.onTap});

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    // Business centres are rent-only; residential complexes lead with the
    // sale price even when a handful of units are also offered for rent.
    final priceLabel = project.priceMin != null
        ? Formatters.price(project.priceMin!)
        : project.rentMin != null
        ? Formatters.rentMonthly(project.rentMin!)
        : '-';
    final showsRentToo = project.priceMin != null && project.rentMin != null;
    final hasDiscount = project.offers.any((o) => o.type == OfferType.discount);
    final hasInstallment = project.offers.any(
      (o) => o.type == OfferType.installment,
    );

    return PressableScale(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      url: project.gallery.isNotEmpty
                          ? project.gallery.first.url
                          : null,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 72,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    if (project.isFeatured || hasDiscount || hasInstallment)
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (project.isFeatured)
                              TagBadge(label: l10n.bestDeal, filled: true),
                            if (hasDiscount)
                              TagBadge(label: l10n.discountBadge),
                            if (hasInstallment)
                              TagBadge(label: l10n.installmentBadge),
                          ],
                        ),
                      ),
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isFavorite = ref.watch(
                            favoritesProvider.select(
                              (ids) => ids.contains(project.id),
                            ),
                          );
                          return PressableScale(
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(project.id),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.92,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 17,
                                  color: isFavorite
                                      ? colors.danger
                                      : const Color(0xFF17181C),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              priceLabel,
                              style: textTheme.labelMedium?.copyWith(
                                color: colors.onAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Stat(icon: Icons.place_outlined, label: project.district),
                    _Stat(
                      icon: Icons.star_rounded,
                      label: project.rating.toStringAsFixed(1),
                    ),
                    _Stat(
                      icon: Icons.meeting_room_outlined,
                      label: l10n.unitsAvailableCount(project.availableUnits),
                    ),
                    if (showsRentToo)
                      _Stat(
                        icon: Icons.key_outlined,
                        label: l10n.rentFromPrice(
                          Formatters.rentMonthly(project.rentMin!),
                        ),
                      ),
                    if (project.completionDate != null)
                      _Stat(
                        icon: Icons.event_outlined,
                        label: Formatters.quarterYear(project.completionDate!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
