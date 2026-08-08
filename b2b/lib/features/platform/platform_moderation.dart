import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/env.dart';
import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/document_review_row.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/map_location_picker.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import 'platform_providers.dart';
import 'platform_widgets.dart';

/// Moderation inbox: pending ЖК publish, warn/unpublish, flagged reviews.
class PlatformModeration extends ConsumerWidget {
  const PlatformModeration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final pendingProjects = ref.watch(platformPendingProjectsProvider);
    final pendingRentals = ref.watch(platformPendingRentalListingsProvider);
    final pendingReviews = ref.watch(platformPendingReviewsProvider);
    final allProjects = ref.watch(platformAllProjectsProvider).value;
    final projectNames = <String, String>{
      for (final proj in allProjects ?? const <Map<String, dynamic>>[])
        if (proj['id'] != null && proj['name'] != null)
          proj['id'].toString(): proj['name'].toString(),
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(l10n.moderationTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.moderationSubtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.platformPendingProjectsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        pendingProjects.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.apartment_outlined,
                title: l10n.platformNoPendingProjects,
              );
            }
            return Column(
              children: [
                for (final p in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name']?.toString() ?? '',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${p['district'] ?? ''} · ${p['type'] ?? ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                                if ((p['developer'] as Map?)?['name']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.platformProjectDeveloper(
                                      (p['developer'] as Map)['name']
                                          .toString(),
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.platformProjectDetails,
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => _ProjectReviewDialog(project: p),
                            ),
                            icon: const Icon(Icons.info_outline),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformPublish,
                            onPressed: () => runPlatformAction(
                              context,
                              ref,
                              action: () => ref
                                  .read(adminApiProvider)
                                  .moderateProject(
                                    p['id'] as String,
                                    decision: 'approve',
                                  ),
                              onSuccess: () =>
                                  invalidatePlatformProjectLists(ref),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformReject,
                            variant: PillButtonVariant.outline,
                            onPressed: () async {
                              final note = await showDialog<String>(
                                context: context,
                                builder: (_) => NoteDialog(
                                  title: l10n.platformReject,
                                  hint: l10n.platformDeclineReasonHint,
                                  confirmLabel: l10n.platformReject,
                                ),
                              );
                              if (note == null || !context.mounted) return;
                              await runPlatformAction(
                                context,
                                ref,
                                action: () => ref
                                    .read(adminApiProvider)
                                    .moderateProject(
                                      p['id'] as String,
                                      decision: 'reject',
                                      note: note,
                                    ),
                                onSuccess: () =>
                                    invalidatePlatformProjectLists(ref),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformPendingRentalsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        pendingRentals.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.key_outlined,
                title: l10n.platformNoPendingRentals,
              );
            }
            return Column(
              children: [
                for (final r in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PendingRentalListingCard(listing: r),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformPendingReviewsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        pendingReviews.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.reviews_outlined,
                title: l10n.platformNoPendingReviews,
              );
            }
            return Column(
              children: [
                for (final r in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r['userName'] ?? l10n.platformAnonymous} · '
                                  '${r['ratingOverall'] ?? '—'}★',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Wrap(
                                  spacing: AppSpacing.md,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    for (final (label, value) in [
                                      (
                                        l10n.platformReviewRatingLocation,
                                        r['ratingLocation'],
                                      ),
                                      (
                                        l10n.platformReviewRatingQuality,
                                        r['ratingQuality'],
                                      ),
                                      (
                                        l10n.platformReviewRatingValue,
                                        r['ratingValue'],
                                      ),
                                    ])
                                      if (value != null)
                                        Text(
                                          '$label $value★',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colors.inkMuted,
                                          ),
                                        ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  r['body']?.toString() ?? '',
                                  style: textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  [
                                    if (projectNames[r['projectId']
                                            ?.toString()] !=
                                        null)
                                      l10n.platformReviewProjectLabel(
                                        projectNames[r['projectId']
                                                .toString()]!,
                                      ),
                                    (r['createdAt']?.toString() ?? '')
                                        .split('T')
                                        .first,
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformKeep,
                            onPressed: () => runPlatformAction(
                              context,
                              ref,
                              action: () => ref
                                  .read(adminApiProvider)
                                  .moderateReview(
                                    r['id'] as String,
                                    keep: true,
                                  ),
                              onSuccess: () => ref.invalidate(
                                platformPendingReviewsProvider,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformRemove,
                            variant: PillButtonVariant.outline,
                            onPressed: () => runPlatformAction(
                              context,
                              ref,
                              action: () => ref
                                  .read(adminApiProvider)
                                  .moderateReview(
                                    r['id'] as String,
                                    keep: false,
                                  ),
                              onSuccess: () => ref.invalidate(
                                platformPendingReviewsProvider,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }
}

String _fmtNumber(num? value) =>
    value == null ? '—' : NumberFormat.decimalPattern().format(value);

/// One owner-submitted secondary-market rental listing awaiting approval —
/// a lightweight card (no separate detail dialog, unlike ЖК projects) since
/// these submissions carry far less data than a full project application.
class _PendingRentalListingCard extends ConsumerWidget {
  const _PendingRentalListingCard({required this.listing});

  final Map<String, dynamic> listing;

  Future<void> _approve(BuildContext context, WidgetRef ref) => runPlatformAction(
    context,
    ref,
    action: () => ref
        .read(adminApiProvider)
        .moderateRentalListing(listing['id'] as String, approve: true),
    onSuccess: () => ref.invalidate(platformPendingRentalListingsProvider),
  );

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => NoteDialog(
        title: l10n.platformReject,
        hint: l10n.platformDeclineReasonHint,
        confirmLabel: l10n.platformReject,
      ),
    );
    if (note == null || !context.mounted) return;
    await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .moderateRentalListing(
            listing['id'] as String,
            approve: false,
            note: note,
          ),
      onSuccess: () => ref.invalidate(platformPendingRentalListingsProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final gallery = (listing['photos'] as List?)?.cast<Object?>() ?? const [];
    final areaTotal = (listing['areaTotal'] as num?)?.toDouble();
    final rooms = listing['rooms'] as int?;
    final rentMonthly = listing['rentMonthly'] as num?;
    final contactPhone = listing['contactPhone']?.toString() ?? '';

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['title']?.toString() ?? '',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      '${listing['district'] ?? ''} · ${listing['address'] ?? ''}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                    Text(
                      unitKindLabel(
                        l10n,
                        listing['propertyKind']?.toString() ?? '',
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                    if (areaTotal != null)
                      Text(
                        '${areaTotal.toStringAsFixed(0)} m²',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    if (rooms != null)
                      Text(
                        '$rooms ${l10n.projectRoomsLabel.toLowerCase()}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.platformRentalMonthlyRent(_fmtNumber(rentMonthly)),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (contactPhone.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.platformRentalContactLabel(contactPhone),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
                if (gallery.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: gallery.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (_, i) {
                        final url = Env.resolveUrl(gallery[i]?.toString());
                        if (url == null) return const SizedBox.shrink();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: Image.network(
                            url,
                            width: 84,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PillButton(
            label: l10n.platformApprove,
            onPressed: () => _approve(context, ref),
          ),
          const SizedBox(width: AppSpacing.sm),
          PillButton(
            label: l10n.platformReject,
            variant: PillButtonVariant.outline,
            onPressed: () => _reject(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Pending-project review dialog (details, buildings, KYC docs).
class _ProjectReviewDialog extends ConsumerStatefulWidget {
  const _ProjectReviewDialog({required this.project});

  final Map<String, dynamic> project;

  @override
  ConsumerState<_ProjectReviewDialog> createState() =>
      _ProjectReviewDialogState();
}

class _ProjectReviewDialogState extends ConsumerState<_ProjectReviewDialog> {
  Map<String, dynamic>? _fullProject;
  String? _projectError;
  bool _loadingProject = true;

  List<Map<String, dynamic>>? _documents;
  String? _documentsError;
  bool _loadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
    _loadDocuments();
  }

  Future<void> _loadProject() async {
    setState(() {
      _loadingProject = true;
      _projectError = null;
    });
    try {
      final full = await ref
          .read(adminApiProvider)
          .getAdminProject(widget.project['id'] as String);
      if (mounted) setState(() => _fullProject = full);
    } catch (e) {
      if (mounted) setState(() => _projectError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProject = false);
    }
  }

  Future<void> _loadDocuments() async {
    final developerId = (widget.project['developer'] as Map?)?['id']
        ?.toString();
    if (developerId == null) {
      setState(() => _loadingDocuments = false);
      return;
    }
    setState(() {
      _loadingDocuments = true;
      _documentsError = null;
    });
    try {
      final docs = await ref
          .read(adminApiProvider)
          .developerDocuments(developerId);
      if (mounted) setState(() => _documents = docs);
    } catch (e) {
      if (mounted) setState(() => _documentsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDocuments = false);
    }
  }

  Future<void> _acceptDoc(String documentId) async {
    await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .reviewDocument(documentId, status: 'accepted'),
      onSuccess: _loadDocuments,
    );
  }

  Future<void> _rejectDoc(String documentId) async {
    final l10n = AppLocalizations.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => NoteDialog(
        title: l10n.platformKycDocumentRejectDialogTitle,
        hint: l10n.platformKycDocumentRejectReasonHint,
        confirmLabel: l10n.platformKycDocumentReject,
      ),
    );
    if (reason == null || !mounted) return;
    await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .reviewDocument(documentId, status: 'rejected', rejectReason: reason),
      onSuccess: _loadDocuments,
    );
  }

  Future<void> _approve() async {
    final ok = await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .moderateProject(widget.project['id'] as String, decision: 'approve'),
      onSuccess: () => invalidatePlatformProjectLists(ref),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => NoteDialog(
        title: l10n.platformReject,
        hint: l10n.platformDeclineReasonHint,
        confirmLabel: l10n.platformReject,
      ),
    );
    if (note == null || !mounted) return;
    final ok = await runPlatformAction(
      context,
      ref,
      action: () => ref.read(adminApiProvider).moderateProject(
        widget.project['id'] as String,
        decision: 'reject',
        note: note,
      ),
      onSuccess: () => invalidatePlatformProjectLists(ref),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final project = widget.project;
    final developer = project['developer'] as Map?;
    final lat = (project['lat'] as num?)?.toDouble();
    final lng = (project['lng'] as num?)?.toDouble();
    final gallery = (project['gallery'] as List?)?.cast<Map>() ?? const [];
    final amenities = (project['amenities'] as List?) ?? const [];
    final description = project['description']?.toString() ?? '';
    final buildings = (_fullProject?['buildings'] as List?)?.cast<Map>() ??
        const [];
    final units = buildings
        .expand((b) => (b['units'] as List?)?.cast<Map>() ?? const [])
        .toList();
    final unitCounts = <String, int>{};
    for (final unit in units) {
      final status = unit['status']?.toString() ?? 'available';
      unitCounts[status] = (unitCounts[status] ?? 0) + 1;
    }

    final priceMin = project['priceMin'] as num?;
    final priceMax = project['priceMax'] as num?;
    final rentMin = project['rentMin'] as num?;
    final rentMax = project['rentMax'] as num?;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(project['name']?.toString() ?? ''),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Chip(
                    label: Text(
                      projectModerationStatusLabel(
                        l10n,
                        project['moderationStatus']?.toString() ?? 'pending',
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(
                      projectTypeLabel(l10n, project['type']?.toString() ?? ''),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (developer?['name'] != null)
                    Chip(
                      label: Text(
                        l10n.platformProjectDeveloper(
                          developer!['name'].toString(),
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${project['district'] ?? ''}, ${project['address'] ?? ''}',
                style: textTheme.bodyMedium,
              ),
              if (lat != null && lng != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: MapLocationPicker(
                    location: LatLng(lat, lng),
                    interactive: false,
                    height: 140,
                    onLocationChanged: (_) {},
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const Divider(height: AppSpacing.xl),
                Text(
                  l10n.platformProjectDescriptionLabel,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: textTheme.bodyMedium),
              ],
              if (amenities.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final amenity in amenities)
                      Chip(
                        label: Text(amenity.toString()),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              if (priceMin != null ||
                  priceMax != null ||
                  rentMin != null ||
                  rentMax != null) ...[
                const Divider(height: AppSpacing.xl),
                Text(
                  l10n.platformProjectPricingLabel,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (priceMin != null || priceMax != null)
                  Text(
                    l10n.platformProjectPriceRange(
                      _fmtNumber(priceMin),
                      _fmtNumber(priceMax),
                    ),
                    style: textTheme.bodyMedium,
                  ),
                if (rentMin != null || rentMax != null)
                  Text(
                    l10n.platformProjectRentRange(
                      _fmtNumber(rentMin),
                      _fmtNumber(rentMax),
                    ),
                    style: textTheme.bodyMedium,
                  ),
              ],
              if (project['completionDate'] != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.platformProjectCompletionLabel(
                    project['completionDate'].toString(),
                  ),
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
              if (gallery.isNotEmpty) ...[
                const Divider(height: AppSpacing.xl),
                Text(
                  l10n.platformProjectGalleryLabel,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gallery.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final url = Env.resolveUrl(
                        gallery[i]['url']?.toString(),
                      );
                      if (url == null) return const SizedBox.shrink();
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: Image.network(
                          url,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const Divider(height: AppSpacing.xl),
              Text(l10n.platformProjectUnitsLabel, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              if (_loadingProject)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: LinearProgressIndicator(),
                )
              else if (_projectError != null)
                Text(
                  l10n.platformProjectLoadError(_projectError!),
                  style: textTheme.bodySmall?.copyWith(color: colors.danger),
                )
              else if (units.isEmpty)
                Text(
                  l10n.platformProjectUnitsEmpty,
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.platformProjectUnitsSummary(
                        buildings.length,
                        units.length,
                      ),
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final entry in unitCounts.entries)
                          Text(
                            '${entry.value} ${unitStatusLabel(l10n, entry.key)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              const Divider(height: AppSpacing.xl),
              Text(l10n.platformKycDocumentsTitle, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (_loadingDocuments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: LinearProgressIndicator(),
                )
              else if (_documentsError != null)
                Text(
                  l10n.platformKycDocumentsError(_documentsError!),
                  style: textTheme.bodySmall?.copyWith(color: colors.danger),
                )
              else if ((_documents ?? const []).isEmpty)
                Text(
                  l10n.platformKycDocumentsEmpty,
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                )
              else
                for (final doc in _documents!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: DocumentReviewRow(
                      document: doc,
                      onAccept: () => _acceptDoc(doc['id'] as String),
                      onReject: () => _rejectDoc(doc['id'] as String),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
        PillButton(
          label: l10n.platformReject,
          variant: PillButtonVariant.outline,
          onPressed: _reject,
        ),
        PillButton(label: l10n.platformPublish, onPressed: _approve),
      ],
    );
  }
}
