import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_card_grid.dart';
import '../../../core/widgets/scroll_tuning.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/verification_card.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../discovery/presentation/widgets/property_card.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../providers/developer_providers.dart';

/// Developer profile: company summary, contacts and a split catalogue of
/// residential complexes vs business-centre offices.
class DeveloperScreen extends ConsumerWidget {
  const DeveloperScreen({super.key, required this.developerId});

  final String developerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final projectsAsync = ref.watch(projectsProvider);
    final catalogEntry = ref.watch(developerByIdProvider(developerId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(catalogEntry?.developer.name ?? ''),
      ),
      body: ConstrainedBody(
        maxWidth: AppBreakpoints.maxContentWidth,
        child: AsyncValueView(
          value: projectsAsync,
          minHeight: 400,
          onRetry: () => ref.invalidate(projectsProvider),
          builder: (context, _) {
            final entry = ref.watch(developerByIdProvider(developerId));
            if (entry == null) {
              final l10n = AppLocalizations.of(context);
              return EmptyState(
                icon: Icons.business_outlined,
                title: l10n.developerNotFoundTitle,
                subtitle: l10n.developerNotFoundSubtitle,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(projectsProvider),
              );
            }
            return _DeveloperBody(entry: entry);
          },
        ),
      ),
    );
  }
}

class _DeveloperBody extends StatelessWidget {
  const _DeveloperBody({required this.entry});

  final DeveloperCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dev = entry.developer;
    final residences = entry.projects
        .where((p) => p.type == ProjectType.residentialComplex)
        .toList();
    final offices = entry.projects
        .where((p) => p.type == ProjectType.businessCentre)
        .toList();

    return CustomScrollView(
      scrollCacheExtent: scrollCacheExtentFor(context),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DeveloperHeader(
                  developer: dev,
                  projectsCount: entry.projects.length,
                ),
                const SizedBox(height: AppSpacing.lg),
                VerificationCard(developerId: dev.id),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: l10n.developerContactsTitle),
                const SizedBox(height: AppSpacing.md),
                _ContactsCard(developer: dev),
              ],
            ),
          ),
        ),
        if (residences.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: l10n.developerResidencesTitle),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: ResponsiveCardSliverGrid(
              itemCount: residences.length,
              itemBuilder: (context, index) {
                final project = residences[index];
                return PropertyCard(
                  project: project,
                  onTap: () => context.go('/home/project/${project.id}'),
                );
              },
            ),
          ),
        ],
        if (offices.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: l10n.developerOfficesTitle),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: ResponsiveCardSliverGrid(
              itemCount: offices.length,
              itemBuilder: (context, index) {
                final project = offices[index];
                return PropertyCard(
                  project: project,
                  onTap: () => context.go('/home/project/${project.id}'),
                );
              },
            ),
          ),
        ],
        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
        ),
      ],
    );
  }
}

class _DeveloperHeader extends StatelessWidget {
  const _DeveloperHeader({
    required this.developer,
    required this.projectsCount,
  });

  final Developer developer;
  final int projectsCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final logoUrl = AppNetworkImage.resolveUrl(developer.logoUrl);

    return AppCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colors.accentSecondary.withValues(alpha: 0.35),
            backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
            child: logoUrl != null
                ? null
                : Text(
                    developer.name.isNotEmpty
                        ? developer.name[0].toUpperCase()
                        : '?',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            developer.name,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, size: 18, color: colors.warning),
              const SizedBox(width: AppSpacing.xs),
              Text(
                developer.rating.toStringAsFixed(1),
                style: textTheme.titleMedium,
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                l10n.developerProjectsCount(projectsCount),
                style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 1,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              l10n.iBuildPartner,
              style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.developer});

  final Developer developer;

  Future<void> _dial(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.callFailedSnackbar)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final avatarUrl = AppNetworkImage.resolveUrl(developer.agentAvatarUrl);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (developer.phone != null && developer.phone!.isNotEmpty)
            _ContactRow(
              icon: Icons.phone_outlined,
              label: l10n.contactPhoneLabel,
              value: developer.phone!,
              onTap: () => _dial(context, developer.phone!),
            ),
          if (developer.agentName != null &&
              developer.agentName!.isNotEmpty) ...[
            if (developer.phone != null && developer.phone!.isNotEmpty)
              const Divider(height: AppSpacing.xl),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.surfaceAlt,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl != null
                      ? null
                      : Icon(Icons.person_outline, color: colors.inkMuted),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.contactAgentTitle,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                      Text(developer.agentName!, style: textTheme.titleSmall),
                      if (developer.agentPhone != null &&
                          developer.agentPhone!.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              _dial(context, developer.agentPhone!),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(developer.agentPhone!),
                        ),
                    ],
                  ),
                ),
                if (developer.agentPhone != null &&
                    developer.agentPhone!.isNotEmpty)
                  IconButton(
                    onPressed: () => _dial(context, developer.agentPhone!),
                    icon: const Icon(Icons.call_outlined),
                    tooltip: l10n.callAgentLabel,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.inkMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  Text(value, style: textTheme.titleSmall),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
