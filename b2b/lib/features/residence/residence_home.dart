import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/districts.dart';
import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/map_location_picker.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/admin_project.dart';
import '../../models/developer_profile.dart';
import '../../repositories/residence_repository.dart';
import '../auth/auth.dart';

final _myProjectsProvider = FutureProvider<List<AdminProject>>((ref) async {
  try {
    return await ref.watch(residenceRepositoryProvider).myProjects();
  } catch (e) {
    if (isAccountBannedError(e)) {
      ref.read(authControllerProvider.notifier).applyBannedFromError(e);
    }
    rethrow;
  }
});

final _myOrgBannerProvider = FutureProvider<DeveloperProfile?>((ref) {
  return ref.watch(residenceRepositoryProvider).myDeveloper();
});

class ResidenceHome extends ConsumerWidget {
  const ResidenceHome({super.key});

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_CreateProjectForm>(
      context: context,
      builder: (ctx) => const _CreateProjectDialog(),
    );
    if (result == null) return;
    await ref.read(residenceRepositoryProvider).createProject(
      name: result.name,
      district: result.district,
      address: result.address,
      lat: result.location.latitude,
      lng: result.location.longitude,
      type: result.type,
    );
    ref.invalidate(_myProjectsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.residenceCreatedSnackbar)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final projects = ref.watch(_myProjectsProvider);
    final org = ref.watch(_myOrgBannerProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        org.when(
          data: (d) {
            if (d == null || d.canPublish) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: AppCard(
                color: colors.warning.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.residencePublishingLocked(
                          '${d.subscriptionPriceUsd}',
                        ),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    PillButton(
                      label: l10n.navOrganization,
                      onPressed: () => context.go('/residence/org'),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.residenceTitle, style: textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.residenceSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PillButton(
                label: l10n.residenceNewProject,
                icon: Icons.add,
                onPressed: () => _createProject(context, ref),
              ),
            ],
          )
        else ...[
          Text(l10n.residenceTitle, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.residenceSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: l10n.residenceNewProject,
            icon: Icons.add,
            expand: true,
            onPressed: () => _createProject(context, ref),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.residenceProjectsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        projects.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.apartment_outlined,
                title: l10n.residenceNoProjects,
                subtitle: l10n.residenceNoProjectsSubtitle,
              );
            }
            final warned = items.where((p) => p.hasPlatformWarning).toList();
            return Column(
              children: [
                if (warned.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppCard(
                      color: colors.danger.withValues(alpha: 0.12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colors.danger,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              warned.length == 1
                                  ? '${l10n.projectWarningBanner}: ${warned.first.name}'
                                  : '${l10n.projectWarningBanner} (${warned.length})',
                              style: textTheme.titleSmall?.copyWith(
                                color: colors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final p in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      onTap: () => context.go('/residence/project/${p.id}'),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: p.hasPlatformWarning
                                  ? colors.danger.withValues(alpha: 0.12)
                                  : colors.accentSecondary.withValues(
                                      alpha: 0.12,
                                    ),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: Icon(
                              p.hasPlatformWarning
                                  ? Icons.warning_amber_rounded
                                  : Icons.apartment,
                              color: p.hasPlatformWarning
                                  ? colors.danger
                                  : colors.accentSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.residenceProjectMeta(
                                    p.district,
                                    projectModerationStatusLabel(
                                      l10n,
                                      p.moderationStatus,
                                    ),
                                    publishedStatusLabel(l10n, p.isPublished),
                                  ),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                                if (p.hasPlatformWarning) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.residenceProjectWarned,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (p.hasPlatformWarning)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: colors.danger,
                              ),
                            ),
                          Icon(Icons.chevron_right, color: colors.inkMuted),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) {
            if (isAccountBannedError(e)) {
              return Text(
                l10n.accountBannedTitle,
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              );
            }
            return Text(l10n.residenceLoadError('$e'));
          },
        ),
      ],
    );
  }
}

class _CreateProjectForm {
  const _CreateProjectForm({
    required this.name,
    required this.district,
    required this.address,
    required this.location,
    required this.type,
  });

  final String name;
  final String district;
  final String address;
  final LatLng location;
  final String type;
}

/// The 5 project types a residence admin can pick when creating a project
/// (plan section 6): the 3 original types plus office/cottage.
const List<String> kProjectTypeOptions = [
  'residential_complex',
  'business_centre',
  'street_retail',
  'office',
  'cottage',
];

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _name = TextEditingController();
  final _otherDistrict = TextEditingController();
  final _address = TextEditingController();
  String _district = kTashkentDistricts.first;
  String _type = kProjectTypeOptions.first;
  LatLng _location = kDefaultMapCenter;

  @override
  void dispose() {
    _name.dispose();
    _otherDistrict.dispose();
    _address.dispose();
    super.dispose();
  }

  String get _effectiveDistrict => _district == kOtherDistrictOption
      ? _otherDistrict.text.trim()
      : _district;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final canCreate =
        _name.text.trim().isNotEmpty && _effectiveDistrict.isNotEmpty;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.residenceNewProjectDialogTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: InputDecoration(hintText: l10n.residenceNameHint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: l10n.residenceTypeHint),
                items: [
                  for (final t in kProjectTypeOptions)
                    DropdownMenuItem(
                      value: t,
                      child: Text(projectTypeLabel(l10n, t)),
                    ),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _district,
                decoration: InputDecoration(
                  labelText: l10n.residenceDistrictHint,
                ),
                items: [
                  for (final d in kTashkentDistricts)
                    DropdownMenuItem(value: d, child: Text(d)),
                  DropdownMenuItem(
                    value: kOtherDistrictOption,
                    child: Text(l10n.residenceDistrictOther),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _district = value ?? _district),
              ),
              if (_district == kOtherDistrictOption) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _otherDistrict,
                  autofocus: true,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  decoration: InputDecoration(
                    hintText: l10n.residenceDistrictOtherHint,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _address,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                decoration: InputDecoration(
                  hintText: l10n.residenceAddressHint,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              MapLocationPicker(
                location: _location,
                height: 240,
                onLocationChanged: (point) => setState(() => _location = point),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        PillButton(
          label: l10n.residenceCreate,
          onPressed: !canCreate
              ? null
              : () => Navigator.pop(
                  context,
                  _CreateProjectForm(
                    name: _name.text.trim(),
                    district: _effectiveDistrict,
                    address: _address.text.trim(),
                    location: _location,
                    type: _type,
                  ),
                ),
        ),
      ],
    );
  }
}
