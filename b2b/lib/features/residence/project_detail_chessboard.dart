part of 'project_detail_admin.dart';

/// "All" + one chip per unit kind — filters both the chessboard and the
/// list view below without touching the underlying data (plan section 5,
/// "Split by property type").
class _UnitKindFilterBar extends StatelessWidget {
  const _UnitKindFilterBar({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _kinds = ['apartment', 'office', 'retail'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: Text(l10n.chessboardFilterAll),
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final kind in _kinds)
          ChoiceChip(
            label: Text(unitKindLabel(l10n, kind)),
            selected: value == kind,
            onSelected: (_) => onChanged(kind),
          ),
      ],
    );
  }
}

/// Colour key for the unit availability grid (шахматка).
class _ChessboardLegend extends StatelessWidget {
  const _ChessboardLegend();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final items = <(String, Color)>[
      (l10n.statusAvailable, colors.unitAvailable),
      (l10n.statusReserved, colors.unitReserved),
      (l10n.projectLegendSoldRented, colors.unitSold),
      (l10n.statusBlocked, colors.unitBlocked),
    ];
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
      ],
    );
  }
}

/// Fixed room-count → accent color (not theme-dependent).
Color _roomAccentColor(int? rooms) => switch (rooms) {
  null => Colors.transparent,
  1 => const Color(0xFF3B82F6),
  2 => const Color(0xFF10B981),
  3 => const Color(0xFFF59E0B),
  _ => const Color(0xFF8B5CF6),
};

/// Legend for room-count corner accents on chessboard cells.
class _ChessboardRoomLegend extends StatelessWidget {
  const _ChessboardRoomLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.chessboardRoomsLegendTitle,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        for (var rooms = 1; rooms <= 4; rooms++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _roomAccentColor(rooms),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                rooms == 4 ? l10n.chessboardRooms4Plus : '$rooms',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
      ],
    );
  }
}

/// A single building's units laid out floor-by-floor as a chessboard grid.
/// Floors and cells are built lazily so large buildings don't mount every
/// unit widget up front.
class _BuildingChessboard extends StatelessWidget {
  const _BuildingChessboard({required this.units, required this.onTapUnit});

  final List<Map> units;
  final void Function(Map) onTapUnit;

  static const _cellSize = 52.0;
  static const _cellGap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final byFloor = <int, List<Map>>{};
    for (final u in units) {
      final floor = (u['floor'] as int?) ?? 0;
      byFloor.putIfAbsent(floor, () => []).add(u);
    }
    final floors = byFloor.keys.toList()..sort((a, b) => b.compareTo(a));

    // Nested scrollables: parent project detail already scrolls vertically,
    // so floors use a shrink-wrapped builder (lazy build, no nested scroll
    // fight) and each floor's units scroll horizontally when needed.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: floors.length,
          itemBuilder: (context, index) {
            final floor = floors[index];
            final floorUnits = byFloor[floor]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('$floor', style: textTheme.labelMedium),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: _cellSize,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: floorUnits.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: _cellGap),
                        itemBuilder: (context, i) {
                          final u = floorUnits[i];
                          return _ChessboardCell(
                            unit: u,
                            onTap: () => onTapUnit(u),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// A single unit cell, coloured by availability status with a secondary
/// room-count accent dot, and a hover (desktop) / long-press (touch)
/// preview card (plan photo3).
class _ChessboardCell extends StatelessWidget {
  const _ChessboardCell({required this.unit, required this.onTap});

  final Map unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = unit['status']?.toString() ?? 'available';
    final color = switch (status) {
      'available' => colors.unitAvailable,
      'reserved' => colors.unitReserved,
      'sold' || 'rented' => colors.unitSold,
      _ => colors.unitBlocked,
    };
    final rooms = unit['rooms'] as int?;
    final accent = _roomAccentColor(rooms);

    final cell = Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Text(
              unit['number']?.toString() ?? '',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: status == 'blocked' ? Colors.white : colors.ink,
              ),
            ),
          ),
          if (rooms != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        richMessage: WidgetSpan(child: _UnitPreviewCard(unit: unit)),
        waitDuration: const Duration(milliseconds: 300),
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        decoration: const BoxDecoration(),
        child: cell,
      ),
    );
  }
}

/// Compact hover/long-press preview: unit number, room count, area, price,
/// price/m², and the first floorplan thumbnail if one exists.
class _UnitPreviewCard extends StatelessWidget {
  const _UnitPreviewCard({required this.unit});

  final Map unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final media = (unit['media'] as List?)?.cast<Map>() ?? const [];
    final floorplans = media.where((m) => m['type']?.toString() == 'floorplan');
    final floorplan = floorplans.isEmpty ? null : floorplans.first;
    final floorplanUrl = Env.resolveUrl(floorplan?['url']?.toString());

    final rooms = unit['rooms'] as int?;
    final areaTotal = (unit['areaTotal'] as num?)?.toDouble();
    final price = (unit['price'] as num?)?.toDouble();
    final priceM2 = (unit['priceM2'] as num?)?.toDouble();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (floorplanUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: AppNetworkImage(
                  url: floorplan?['url']?.toString(),
                  height: 90,
                  width: double.infinity,
                  memCacheWidth: 440,
                  memCacheHeight: 180,
                ),
              ),
            if (floorplanUrl != null) const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.projectUnitLabel(unit['number']?.toString() ?? ''),
              style: textTheme.titleSmall?.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 2),
            if (rooms != null)
              Text(
                '${l10n.projectRoomsLabel}: $rooms',
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            if (areaTotal != null)
              Text(
                '${areaTotal.toStringAsFixed(0)} m²',
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            if (price != null)
              Text(
                '\$${price.toStringAsFixed(0)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (priceM2 != null)
              Text(
                '${l10n.projectPriceM2Label}: \$${priceM2.toStringAsFixed(0)}',
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}
