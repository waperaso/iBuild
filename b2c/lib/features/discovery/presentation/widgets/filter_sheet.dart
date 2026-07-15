import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../l10n/enum_labels.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../models/saved_search.dart';
import '../../../favorites/providers/saved_searches_providers.dart';
import '../../providers/discovery_providers.dart';
import '../../providers/filters_providers.dart';

/// Districts covered by the dev server's seed data (`server/lib/src/seed_data.dart`).
/// There's no dedicated `/v1/districts` endpoint yet, so this dropdown works
/// off a fixed, alphabetised list rather than deriving it from a fetch.
const List<String> kDiscoveryDistricts = [
  'Bektemir',
  'Chilanzar',
  'Mirabad',
  'Mirzo Ulugbek',
  'Olmazor',
  'Sergeli',
  'Shayxontohur',
  'Uchtepa',
  'Yakkasaray',
  'Yangihayot',
  'Yashnobod',
  'Yunusabad',
];

const double kDiscoveryPriceMin = 0;
const double kDiscoveryPriceMax = 300000;

/// Opens the district/status/price-range filter sheet, writing to
/// [discoveryFiltersProvider] on Apply/Clear.
///
/// Mobile uses a bottom sheet; desktop uses a centered dialog so the panel
/// doesn't stretch edge-to-edge across a wide monitor.
Future<void> showFilterSheet(BuildContext context) {
  if (context.isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterSheet(),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: context.colors.background,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: const FilterSheet(dialog: true),
      ),
    ),
  );
}

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key, this.dialog = false});

  final bool dialog;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String? _district;
  ProjectStatus? _status;
  late RangeValues _priceRange;
  Set<int> _rooms = {};
  double? _areaMin;
  bool _offplanOnly = false;
  late TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(discoveryFiltersProvider);
    _district = filters.district;
    _status = filters.status;
    _priceRange = RangeValues(
      filters.minPrice ?? kDiscoveryPriceMin,
      filters.maxPrice ?? kDiscoveryPriceMax,
    );
    _rooms = {...filters.rooms};
    _areaMin = filters.areaMin;
    _offplanOnly = filters.offplanOnly;
    _areaController = TextEditingController(
      text: _areaMin == null ? '' : _areaMin!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _apply() {
    ref
        .read(discoveryFiltersProvider.notifier)
        .applySheetFilters(
          district: _district,
          status: _status,
          minPrice: _priceRange.start <= kDiscoveryPriceMin
              ? null
              : _priceRange.start,
          maxPrice: _priceRange.end >= kDiscoveryPriceMax
              ? null
              : _priceRange.end,
          rooms: _rooms,
          areaMin: _areaMin,
          offplanOnly: _offplanOnly,
        );
    Navigator.of(context).pop();
  }

  void _toggleRoom(int n) {
    if (!_rooms.remove(n)) _rooms.add(n);
  }

  void _clear() {
    ref.read(discoveryFiltersProvider.notifier).clearSheetFilters();
    setState(() {
      _rooms = {};
      _areaMin = null;
      _offplanOnly = false;
      _areaController.clear();
    });
    Navigator.of(context).pop();
  }

  void _saveSearch() {
    final l10n = AppLocalizations.of(context);
    final mode = ref.read(discoveryModeProvider);
    final searchText = ref.read(discoveryFiltersProvider).searchText;
    final minPrice = _priceRange.start <= kDiscoveryPriceMin
        ? null
        : _priceRange.start;
    final maxPrice = _priceRange.end >= kDiscoveryPriceMax
        ? null
        : _priceRange.end;

    final parts = <String>[
      switch (mode) {
        DiscoveryMode.buy => l10n.modeBuy,
        DiscoveryMode.rent => l10n.modeRent,
        DiscoveryMode.newBuilds => l10n.modeNewBuilds,
      },
      ?_district,
      if (_status != null) _status!.label(context),
      if (maxPrice != null)
        l10n.savedSearchUnderPrice(Formatters.compact(maxPrice))
      else if (minPrice != null)
        l10n.savedSearchFromPrice(Formatters.compact(minPrice)),
      if (searchText.isNotEmpty) '"$searchText"',
    ];

    ref
        .read(savedSearchesProvider.notifier)
        .add(
          SavedSearch(
            id: 'ss-${DateTime.now().microsecondsSinceEpoch}',
            label: parts.join(' · '),
            mode: mode,
            searchText: searchText,
            district: _district,
            status: _status,
            minPrice: minPrice,
            maxPrice: maxPrice,
            createdAt: DateTime.now(),
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.savedSearchSavedSnackbar)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.dialog)
          Row(
            children: [
              Expanded(
                child: Text(l10n.filtersTitle, style: textTheme.headlineSmall),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
              ),
            ],
          )
        else ...[
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
          Text(l10n.filtersTitle, style: textTheme.headlineSmall),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.districtLabel, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String?>(
          initialValue: _district,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.categoryAll)),
            for (final d in kDiscoveryDistricts)
              DropdownMenuItem(value: d, child: Text(d)),
          ],
          onChanged: (value) => setState(() => _district = value),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.statusLabel, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(
              label: l10n.categoryAll,
              selected: _status == null,
              onTap: () => setState(() => _status = null),
            ),
            for (final status in ProjectStatus.values)
              AppChip(
                label: status.label(context),
                selected: _status == status,
                onTap: () => setState(() => _status = status),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.roomsLabel, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(
              label: l10n.roomsStudio,
              selected: _rooms.contains(0),
              onTap: () => setState(() => _toggleRoom(0)),
            ),
            for (final n in [1, 2, 3, 4])
              AppChip(
                label: n == 4 ? l10n.roomsPlus(n) : '$n',
                selected: _rooms.contains(n),
                onTap: () => setState(() => _toggleRoom(n)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.areaMinLabel, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _areaController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surface,
            hintText: l10n.areaMinLabel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) =>
              _areaMin = value.isEmpty ? null : double.tryParse(value),
        ),
        const SizedBox(height: AppSpacing.lg),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _offplanOnly,
          onChanged: (value) => setState(() => _offplanOnly = value),
          title: Text(l10n.offplanOnlyLabel, style: textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.priceRangeLabel(
            Formatters.compact(_priceRange.start),
            Formatters.compact(_priceRange.end),
          ),
          style: textTheme.titleMedium,
        ),
        RangeSlider(
          values: _priceRange,
          min: kDiscoveryPriceMin,
          max: kDiscoveryPriceMax,
          divisions: 60,
          labels: RangeLabels(
            Formatters.compact(_priceRange.start),
            Formatters.compact(_priceRange.end),
          ),
          onChanged: (values) => setState(() => _priceRange = values),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clear,
                child: Text(l10n.clearFilters),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _apply,
                child: Text(l10n.applyFilters),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: _saveSearch,
            icon: Icon(Icons.bookmark_add_outlined, color: colors.ink),
            label: Text(
              l10n.saveThisSearch,
              style: textTheme.labelLarge?.copyWith(color: colors.ink),
            ),
          ),
        ),
      ],
    );

    if (widget.dialog) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(child: content),
      );
    }

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
        child: SingleChildScrollView(child: content),
      ),
    );
  }
}
