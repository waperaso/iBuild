import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/enum_labels.dart';
import '../../../../l10n/gen/app_localizations.dart';

const _isometricMapAsset = 'assets/images/isometric_map_hero.png';

/// A "live tracking"-style hero for the project page: a dark isometric map
/// visual with a pin over the location, and a floating card summarising the
/// developer contact, construction progress and quick links — inspired by
/// delivery-tracking UIs, adapted to "tracking your future home".
class LocationTrackingHero extends StatelessWidget {
  const LocationTrackingHero({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MapPanel(project: project),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _TrackingCard(project: project),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _MapPanel(project: project, desktop: true)),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          flex: 6,
          child: _TrackingCard(project: project, desktop: true),
        ),
      ],
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.project, this.desktop = false});

  final Project project;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final map = Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_isometricMapAsset, fit: BoxFit.cover),
        Positioned(
          top: AppSpacing.lg,
          left: AppSpacing.lg,
          child: _PinLabel(project: project),
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: desktop
          ? SizedBox(height: 280, width: double.infinity, child: map)
          : AspectRatio(aspectRatio: 16 / 10, child: map),
    );
  }
}

class _PinLabel extends StatelessWidget {
  const _PinLabel({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).liveLocationDistrict(project.district),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.project, this.desktop = false});

  final Project project;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final card = Padding(
      padding: EdgeInsets.all(desktop ? AppSpacing.xl : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DeveloperRow(project: project),
          const SizedBox(height: AppSpacing.lg),
          _AddressRow(project: project),
          const SizedBox(height: AppSpacing.lg),
          if (project.constructionProgress != null)
            _ProgressTimeline(project: project)
          else
            _ReadyBanner(project: project),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _MenuRow(
            icon: Icons.apartment_outlined,
            label: l10n.projectDetailsMenu,
            trailing: project.type.label(context),
            onTap: () => DefaultTabController.of(context).animateTo(2),
          ),
          _MenuRow(
            icon: Icons.local_offer_outlined,
            label: l10n.offersInstallmentsMenu,
            trailing: project.offers.isEmpty
                ? l10n.noneLabel
                : l10n.activeOffersCount(project.offers.length),
            onTap: () => _showOffers(context, project.offers),
          ),
          _MenuRow(
            icon: Icons.support_agent_outlined,
            label: l10n.supportMenu,
            trailing: l10n.requestCallbackTrailing,
            onTap: () => context.go(
              '/home/lead/new?project=${project.id}&intent=callback',
            ),
          ),
        ],
      ),
    );

    if (desktop) {
      return Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: colors.outline),
          ),
          child: card,
        ),
      );
    }

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      elevation: 6,
      shadowColor: colors.ink.withValues(alpha: 0.15),
      child: card,
    );
  }

  void _showOffers(BuildContext context, List<Offer> offers) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (context) {
        final colors = context.colors;
        final l10n = AppLocalizations.of(context);
        if (offers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              l10n.noActiveOffers,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.offersSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final offer in offers)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_offer, color: colors.accent, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (offer.description != null)
                              Text(
                                offer.description!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.inkMuted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DeveloperRow extends StatelessWidget {
  const _DeveloperRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final developer = project.developer;

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.accent,
          child: Text(
            _initials(developer?.name ?? project.name),
            style: textTheme.titleMedium?.copyWith(color: colors.onAccent),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                developer?.name ?? AppLocalizations.of(context).iBuildPartner,
                style: textTheme.titleMedium,
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: colors.warning),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    (developer?.rating ?? project.rating).toStringAsFixed(1),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.chat_bubble_outline,
          onTap: () =>
              context.go('/home/lead/new?project=${project.id}&intent=viewing'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(
          icon: Icons.call_outlined,
          onTap: () => _callAgent(context, project),
        ),
      ],
    );
  }

  Future<void> _callAgent(BuildContext context, Project project) async {
    final phone = project.developer?.agentPhone ?? project.developer?.phone;
    if (phone == null || phone.isEmpty) {
      context.go('/home/lead/new?project=${project.id}&intent=callback');
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      context.go('/home/lead/new?project=${project.id}&intent=callback');
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.ink,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Icon(icon, size: 18, color: colors.surface),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.place_outlined, size: 18, color: colors.inkMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            project.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            project.status.label(context),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final progress = (project.constructionProgress ?? 0).clamp(0, 100) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const markerSize = 30.0;
            final trackWidth = constraints.maxWidth;
            final markerX = (trackWidth - markerSize) * progress;
            return SizedBox(
              height: markerSize,
              child: Stack(
                children: [
                  Positioned(
                    top: (markerSize - 6) / 2,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: Container(height: 6, color: colors.surfaceAlt),
                    ),
                  ),
                  Positioned(
                    top: (markerSize - 6) / 2,
                    left: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: Container(
                        height: 6,
                        width: trackWidth * progress,
                        color: colors.accent,
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerX,
                    child: Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        color: colors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.apartment,
                        size: 15,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text(
              AppLocalizations.of(
                context,
              ).builtPercent(project.constructionProgress ?? 0),
              style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
            const Spacer(),
            if (project.completionDate != null)
              Text(
                AppLocalizations.of(
                  context,
                ).completionDate(Formatters.date(project.completionDate!)),
                style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  const _ReadyBanner({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: colors.success),
        const SizedBox(width: AppSpacing.sm),
        Text(
          project.status == ProjectStatus.handedOver
              ? AppLocalizations.of(context).handedOverToResidents
              : AppLocalizations.of(context).readyToMoveIn,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.ink),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              trailing,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 18, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
