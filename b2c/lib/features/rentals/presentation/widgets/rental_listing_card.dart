import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../models/rental_listing.dart';

String _propertyKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'office' => l10n.unitKindOffice,
  'retail' => l10n.unitKindRetail,
  _ => l10n.unitKindApartment,
};

/// Card for an approved owner (secondary) rental listing, styled like
/// [PropertyCard] but visually tagged "Secondary" so it's never confused
/// with primary developer inventory (Konseptsiya §5).
class RentalListingCard extends StatelessWidget {
  const RentalListingCard({super.key, required this.listing, this.onTap});

  final RentalListing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

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
                      url: listing.photos.isNotEmpty
                          ? listing.photos.first
                          : null,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: TagBadge(label: l10n.secondaryTag),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 56,
                        color: Colors.black.withValues(alpha: 0.55),
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
                              listing.title,
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
                              Formatters.rentMonthly(listing.rentMonthly),
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
                    _Stat(icon: Icons.place_outlined, label: listing.district),
                    _Stat(
                      icon: Icons.square_foot_outlined,
                      label: Formatters.area(listing.areaTotal),
                    ),
                    _Stat(
                      icon: Icons.home_work_outlined,
                      label: _propertyKindLabel(l10n, listing.propertyKind),
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

/// Opens a bottom sheet with the full listing description and a one-tap
/// call action — there's no dedicated detail route since owner listings are
/// a lightweight secondary-market surface, not primary developer inventory.
Future<void> showRentalListingDetails(
  BuildContext context,
  RentalListing listing,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RentalListingSheet(listing: listing),
  );
}

class _RentalListingSheet extends StatelessWidget {
  const _RentalListingSheet({required this.listing});

  final RentalListing listing;

  Future<void> _dial(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(
      scheme: 'tel',
      path: listing.contactPhone.replaceAll(' ', ''),
    );
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.callFailedSnackbar)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(listing.title, style: textTheme.headlineSmall),
                  ),
                  TagBadge(label: l10n.secondaryTag),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${listing.district} · ${listing.address}',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _Stat(
                    icon: Icons.square_foot_outlined,
                    label: Formatters.area(listing.areaTotal),
                  ),
                  if (listing.rooms != null)
                    _Stat(
                      icon: Icons.meeting_room_outlined,
                      label: '${listing.rooms}',
                    ),
                  _Stat(
                    icon: Icons.calendar_month_outlined,
                    label: '${listing.minLeaseMonths}+ mo',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(listing.description, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text(
                    Formatters.rentMonthly(listing.rentMonthly),
                    style: textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  PillButton(
                    label: listing.contactPhone,
                    icon: Icons.call,
                    onPressed: () => _dial(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
