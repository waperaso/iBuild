import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import '../residence/site_photo_verify_chrome.dart';

final _sitePhotoCyclesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, status) {
      return ref
          .watch(adminApiProvider)
          .platformSitePhotoCycles(status: status.isEmpty ? null : status);
    });

class PlatformSitePhotos extends ConsumerStatefulWidget {
  const PlatformSitePhotos({super.key});

  @override
  ConsumerState<PlatformSitePhotos> createState() => _PlatformSitePhotosState();
}

class _PlatformSitePhotosState extends ConsumerState<PlatformSitePhotos> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isWide = !context.isMobile;
    final cycles = ref.watch(_sitePhotoCyclesProvider(_filter));

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(l10n.platformSitePhotosTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.platformSitePhotosSubtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final entry in [
              ('', l10n.platformSitePhotosFilterAll),
              ('awaiting_a', l10n.platformSitePhotosFilterA),
              ('waiting', l10n.platformSitePhotosFilterWaiting),
              ('awaiting_b', l10n.platformSitePhotosFilterB),
              ('inspector', l10n.platformSitePhotosFilterInspector),
              ('analyzing', l10n.siteCycleStatusAnalyzing),
              ('missed', l10n.siteCycleFilterMissed),
              ('confirmed', l10n.platformSitePhotosFilterConfirmed),
              ('rejected', l10n.platformSitePhotosFilterRejected),
            ])
              ChoiceChip(
                label: Text(entry.$2),
                selected: _filter == entry.$1,
                onSelected: (_) => setState(() => _filter = entry.$1),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        cycles.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.photo_library_outlined,
                title: l10n.platformSitePhotosEmpty,
              );
            }
            return Column(
              children: [
                for (final row in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      onTap: () => _openDetail(row),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.apartment_rounded,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row['projectName']?.toString() ??
                                      row['projectId']?.toString() ??
                                      '',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  row['developerName']?.toString() ?? '—',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SitePhotoStatusPill.forStatus(
                            l10n,
                            row['status']?.toString() ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openDetail(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context);
    final projectId = row['projectId'] as String?;
    if (projectId == null) return;

    var cycleId = row['id']?.toString();
    var status = row['status']?.toString() ?? '';
    SitePhotoRef? photoA;
    SitePhotoRef? photoB;
    var title = row['projectName']?.toString() ?? l10n.platformSitePhotosTitle;
    var subtitle = row['developerName']?.toString() ?? '';
    Map<String, dynamic>? result;
    Map<String, dynamic>? verifyExport;

    try {
      final cycle = await ref.read(adminApiProvider).sitePhotoCycle(projectId);
      cycleId = cycle.id;
      status = cycle.status;
      photoA = cycle.photoA;
      photoB = cycle.photoB;
      title = cycle.projectName ?? title;
      subtitle = [
        if (cycle.developerName?.trim().isNotEmpty == true)
          cycle.developerName!.trim(),
      ].join(' · ');
      result = cycle.result;
      verifyExport = cycle.verifyExport;
    } catch (_) {
      photoA = _refFromMap(row['photoA']);
      photoB = _refFromMap(row['photoB']);
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        var busy = false;
        var currentStatus = status;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final canInspect = currentStatus == 'inspector' && !busy;
            final dialogW =
                (MediaQuery.sizeOf(ctx).width - 48).clamp(320.0, 560.0);
            final colors = context.colors;
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              backgroundColor: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              content: SizedBox(
                width: dialogW,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SitePhotoProjectHeader(
                        title: title,
                        subtitle: subtitle,
                        statusLabel: SitePhotoStatusPill.forStatus(
                          l10n,
                          currentStatus,
                        ).label,
                        status: currentStatus,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SitePhotoVerifyPipeline(
                        active: sitePhotoPipeStepForStatus(currentStatus),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SitePhotoSlotTile(
                              badge: l10n.siteCycleSlotA,
                              caption: sitePhotoSlotCaption(
                                l10n,
                                photoA,
                                emptyWaiting: false,
                              ),
                              photo: photoA,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: SitePhotoSlotTile(
                              badge: l10n.siteCycleSlotB,
                              caption: sitePhotoSlotCaption(
                                l10n,
                                photoB,
                                emptyWaiting: photoB == null,
                              ),
                              photo: photoB,
                              dimmed: currentStatus == 'waiting',
                            ),
                          ),
                        ],
                      ),
                      if (currentStatus == 'analyzing') ...[
                        const SizedBox(height: AppSpacing.lg),
                        const SitePhotoAnalyzeCard(),
                      ] else if (currentStatus == 'inspector' ||
                          currentStatus == 'confirmed' ||
                          currentStatus == 'rejected') ...[
                        const SizedBox(height: AppSpacing.lg),
                        SitePhotoInspectResultCard(
                          status: currentStatus,
                          result: result,
                          verifyExport: verifyExport,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label: l10n.platformSitePhotosConfirm,
                        expand: true,
                        loading: busy,
                        onPressed: canInspect && cycleId != null
                            ? () async {
                                setLocal(() => busy = true);
                                try {
                                  await ref
                                      .read(adminApiProvider)
                                      .confirmSitePhotoCycle(cycleId!);
                                  currentStatus = 'confirmed';
                                  ref.invalidate(
                                    _sitePhotoCyclesProvider(_filter),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.platformSitePhotosActionFailed,
                                        ),
                                      ),
                                    );
                                  }
                                  setLocal(() => busy = false);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PillButton(
                        label: l10n.platformSitePhotosOverturn,
                        variant: PillButtonVariant.outline,
                        expand: true,
                        loading: busy,
                        onPressed: canInspect && cycleId != null
                            ? () async {
                                setLocal(() => busy = true);
                                try {
                                  await ref
                                      .read(adminApiProvider)
                                      .overturnSitePhotoCycle(cycleId!);
                                  currentStatus = 'rejected';
                                  ref.invalidate(
                                    _sitePhotoCyclesProvider(_filter),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.platformSitePhotosActionFailed,
                                        ),
                                      ),
                                    );
                                  }
                                  setLocal(() => busy = false);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PillButton(
                        label:
                            '${l10n.platformSitePhotosGov} · ${l10n.platformSitePhotosDay3}',
                        variant: PillButtonVariant.outline,
                        expand: true,
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.commonClose),
                ),
              ],
            );
          },
        );
      },
    );
  }

  SitePhotoRef? _refFromMap(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['photoUrl']?.toString() ?? '';
    if (url.isEmpty) return null;
    return SitePhotoRef(
      id: raw['id']?.toString() ?? 'photo',
      photoUrl: url,
      takenAt: raw['takenAt']?.toString() ?? '',
    );
  }
}
