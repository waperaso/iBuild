import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/admin_project.dart';
import '../../repositories/residence_repository.dart';
import '../auth/auth.dart';
import 'site_photo_cycle_card.dart';

final _residenceSitePhotoProjectsProvider =
    FutureProvider<List<AdminProject>>((ref) async {
  try {
    return await ref.watch(residenceRepositoryProvider).myProjects();
  } catch (e) {
    if (isAccountBannedError(e)) {
      ref.read(authControllerProvider.notifier).applyBannedFromError(e);
    }
    rethrow;
  }
});

/// Residence-admin surface to upload construction baseline / follow-up photos.
class ResidenceSitePhotos extends ConsumerWidget {
  const ResidenceSitePhotos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isWide = !context.isMobile;
    final projects = ref.watch(_residenceSitePhotoProjectsProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(l10n.navSitePhotos, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.residenceSitePhotosSubtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        projects.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            l10n.residenceLoadError('$e'),
            style: textTheme.bodyMedium?.copyWith(color: colors.danger),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.photo_camera_outlined,
                title: l10n.residenceNoProjects,
                subtitle: l10n.residenceNoProjectsSubtitle,
                actionLabel: l10n.residenceNewProject,
                onAction: () => context.go('/residence'),
              );
            }
            return Column(
              children: [
                for (final project in items) ...[
                  SitePhotoCycleCard(
                    projectId: project.id,
                    showIntro: false,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
