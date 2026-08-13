import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/ai_models.dart';
import 'ai_search_labels.dart';

/// Rich, unit-scoped AI search result card — cover, price, district, a
/// room/area/floor summary line, the match-score badge and up to 3
/// "why this matched" chips. Distinct from `PropertyCard` (project-scoped)
/// since `POST /ai/search` ranks individual units.
///
/// The thumbnail is a fixed square rather than a stretched column: an
/// unbounded-height image inside an `IntrinsicHeight` row measures as zero on
/// Flutter web and collapsed the whole card to a blank rounded rectangle.
/// Every box here has a concrete size, so the card cannot render empty.
class AiSearchResultCard extends StatelessWidget {
  const AiSearchResultCard({
    super.key,
    required this.result,
    this.onBeforeNavigate,
  });

  final AiSearchResult result;

  /// Ran just before the GoRouter navigation — the full-results sheet passes
  /// its own `Navigator.pop` here so tapping a card closes the sheet first
  /// (same order as the floor-plans units sheet).
  final VoidCallback? onBeforeNavigate;

  void _open(BuildContext context) {
    onBeforeNavigate?.call();
    if (result.isUnitScoped) {
      context.go('/home/unit/${result.unitId}?project=${result.projectId}');
    } else {
      context.go('/home/project/${result.projectId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final priceLabel = result.rentMonthly != null
        ? Formatters.rentMonthly(result.rentMonthly!)
        : result.price != null
        ? Formatters.price(result.price!)
        : null;

    final summaryParts = <String>[
      if (result.rooms != null)
        (result.rooms == 0 ? l10n.roomsStudio : l10n.roomsCount(result.rooms!)),
      if (result.areaTotal != null) Formatters.area(result.areaTotal!),
      if (result.floor != null)
        (result.floorsTotal != null
            ? '${result.floor}/${result.floorsTotal}'
            : l10n.floorLabel(result.floor!)),
    ];

    final thumbSize = context.isMobile ? 96.0 : 104.0;

    return PressableScale(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: AppNetworkImage(
                    url: result.coverUrl,
                    width: thumbSize,
                    height: thumbSize,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              result.projectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _MatchBadge(score: result.matchScore),
                        ],
                      ),
                      if (priceLabel != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          priceLabel,
                          style: textTheme.titleSmall?.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: colors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              result.district,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelMedium?.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (summaryParts.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          summaryParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                      if (result.matchReasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final reason in result.matchReasons.take(3))
                              _ReasonChip(
                                label: aiMatchReasonLabel(l10n, reason),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.outline),
      ),
      child: Text(
        l10n.aiSearchMatchScoreLabel(score),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.inkMuted),
      ),
    );
  }
}
