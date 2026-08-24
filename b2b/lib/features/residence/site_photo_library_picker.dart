import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import 'site_photo_test_library.dart';

/// Photo library sheet for site-photo A/B testing.
Future<SitePhotoLibraryPick?> showSitePhotoLibraryPicker(
  BuildContext context,
  WidgetRef ref, {
  SitePhotoRef? referencePhoto,
}) {
  return showModalBottomSheet<SitePhotoLibraryPick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _SitePhotoLibrarySheet(
      referencePhoto: referencePhoto,
    ),
  );
}

class _SitePhotoLibrarySheet extends ConsumerStatefulWidget {
  const _SitePhotoLibrarySheet({this.referencePhoto});

  final SitePhotoRef? referencePhoto;

  @override
  ConsumerState<_SitePhotoLibrarySheet> createState() =>
      _SitePhotoLibrarySheetState();
}

class _SitePhotoLibrarySheetState extends ConsumerState<_SitePhotoLibrarySheet> {
  List<SitePhotoLibraryEntry> _local = const [];
  SitePhotoLibraryEntry? _selected;
  var _loading = true;
  var _adding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final local = await ref.read(sitePhotoTestLibraryProvider).loadLocal();
      if (!mounted) return;
      setState(() => _local = local);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPhoto() async {
    setState(() => _adding = true);
    try {
      await ref.read(sitePhotoTestLibraryProvider).addFromDevice();
      await _reload();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = e is SitePhotoLibraryTooLargeException
          ? l10n.siteCycleLibraryTooLarge
          : l10n.siteCycleLibraryAddError('$e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _remove(SitePhotoLibraryEntry entry) async {
    await ref.read(sitePhotoTestLibraryProvider).removeLocal(entry.id);
    if (_selected?.id == entry.id) _selected = null;
    await _reload();
  }

  Future<void> _confirm() async {
    final entry = _selected;
    if (entry == null) return;
    try {
      final pick = await ref.read(sitePhotoTestLibraryProvider).resolvePick(entry);
      if (!mounted) return;
      Navigator.pop(context, pick);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).siteCycleLibraryAddError('$e')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final library = ref.watch(sitePhotoTestLibraryProvider);
    final builtins = library.builtins(l10n);
    final refPhoto = widget.referencePhoto;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.siteCycleLibraryTitle,
                    style: textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.siteCycleLibrarySubtitle,
                      style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                    ),
                    if (refPhoto != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.siteCycleReferenceA, style: textTheme.labelMedium),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: AppNetworkImage(
                            url: refPhoto.photoUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PillButton(
                        label: l10n.siteCycleLibraryAdd,
                        icon: Icons.upload_outlined,
                        variant: PillButtonVariant.outline,
                        loading: _adding,
                        onPressed: _adding ? null : _addPhoto,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      Text(
                        l10n.siteCycleLibraryBuiltin,
                        style: textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PhotoGrid(
                        entries: builtins,
                        selected: _selected,
                        onSelect: (e) => setState(() => _selected = e),
                      ),
                      if (_local.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.siteCycleLibraryMine,
                          style: textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PhotoGrid(
                          entries: _local,
                          selected: _selected,
                          onSelect: (e) => setState(() => _selected = e),
                          onRemove: _remove,
                        ),
                      ],
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(color: colors.danger),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: l10n.siteCycleLibraryUse,
              expand: true,
              onPressed: _selected == null ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.entries,
    required this.selected,
    required this.onSelect,
    this.onRemove,
  });

  final List<SitePhotoLibraryEntry> entries;
  final SitePhotoLibraryEntry? selected;
  final ValueChanged<SitePhotoLibraryEntry> onSelect;
  final ValueChanged<SitePhotoLibraryEntry>? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = selected?.id == entry.id;
        return InkWell(
          onTap: () => onSelect(entry),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isSelected ? colors.accent : colors.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.md - 1),
                    ),
                    child: _Thumb(entry: entry),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      if (onRemove != null && entry.kind == SitePhotoLibraryKind.local)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => onRemove!(entry),
                          icon: Icon(Icons.delete_outline, size: 18, color: colors.danger),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.entry});

  final SitePhotoLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = entry.previewUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(color: Color(0xFFE4E7EB));
    }
    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma > 0) {
        return Image.memory(
          base64Decode(url.substring(comma + 1)),
          fit: BoxFit.cover,
        );
      }
    }
    return AppNetworkImage(url: url, fit: BoxFit.cover);
  }
}
