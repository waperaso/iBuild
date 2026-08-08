part of 'project_detail_admin.dart';

/// Editor for a project-level offer (discount / installment / rent promo).
class _OfferEditorDialog extends StatefulWidget {
  const _OfferEditorDialog();

  @override
  State<_OfferEditorDialog> createState() => _OfferEditorDialogState();
}

class _OfferEditorDialogState extends State<_OfferEditorDialog> {
  String _type = 'discount';
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _downPaymentPercent = TextEditingController();
  final _termMonths = TextEditingController();
  final _interestRate = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _downPaymentPercent.dispose();
    _termMonths.dispose();
    _interestRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.projectOfferEditorTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: l10n.projectOfferTypeLabel,
              ),
              items: [
                for (final t in const ['discount', 'installment', 'rent_promo'])
                  DropdownMenuItem(
                    value: t,
                    child: Text(offerTypeLabel(l10n, t)),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _title,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: InputDecoration(
                labelText: l10n.projectOfferTitleLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _description,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              decoration: InputDecoration(
                labelText: l10n.projectOfferDescriptionLabel,
              ),
            ),
            if (_type == 'installment') ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _downPaymentPercent,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  labelText: l10n.projectDownPaymentLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _termMonths,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: l10n.projectTermMonthsLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _interestRate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  labelText: l10n.projectInterestRateLabel,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        PillButton(
          label: l10n.commonAdd,
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'type': _type,
              'title': _title.text.trim(),
              if (_description.text.trim().isNotEmpty)
                'description': _description.text.trim(),
              if (_downPaymentPercent.text.trim().isNotEmpty)
                'downPaymentPercent': double.tryParse(
                  _downPaymentPercent.text.trim(),
                ),
              if (_termMonths.text.trim().isNotEmpty)
                'termMonths': int.tryParse(_termMonths.text.trim()),
              if (_interestRate.text.trim().isNotEmpty)
                'interestRate': double.tryParse(_interestRate.text.trim()),
            });
          },
        ),
      ],
    );
  }
}

/// Parameters for generating a floor-by-floor batch of units.
class _BulkUnitsSpec {
  const _BulkUnitsSpec({
    required this.buildingId,
    required this.floorFrom,
    required this.floorTo,
    required this.unitsPerFloor,
    required this.startingNumber,
    required this.kind,
    required this.dealType,
    required this.areaTotal,
    required this.rooms,
    required this.price,
  });

  final String buildingId;
  final int floorFrom;
  final int floorTo;
  final int unitsPerFloor;
  final int startingNumber;
  final String kind;
  final String dealType;
  final double areaTotal;
  final int rooms;
  final double price;
}

/// Form for bulk-generating units across a building's floors.
class _BulkUnitsDialog extends StatefulWidget {
  const _BulkUnitsDialog({required this.buildings});

  final List<Map<String, dynamic>> buildings;

  @override
  State<_BulkUnitsDialog> createState() => _BulkUnitsDialogState();
}

class _BulkUnitsDialogState extends State<_BulkUnitsDialog> {
  late String _buildingId = widget.buildings.first['id'] as String;
  final _floorFrom = TextEditingController(text: '1');
  final _floorTo = TextEditingController(text: '9');
  final _unitsPerFloor = TextEditingController(text: '4');
  final _startingNumber = TextEditingController(text: '1');
  String _kind = 'apartment';
  String _dealType = 'sale';
  final _areaTotal = TextEditingController(text: '55');
  final _rooms = TextEditingController(text: '2');
  final _price = TextEditingController(text: '65000');

  @override
  void dispose() {
    _floorFrom.dispose();
    _floorTo.dispose();
    _unitsPerFloor.dispose();
    _startingNumber.dispose();
    _areaTotal.dispose();
    _rooms.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.projectBulkUnitsDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _buildingId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.projectBuildingLabel),
              items: [
                for (final b in widget.buildings)
                  DropdownMenuItem(
                    value: b['id'] as String,
                    child: Text(
                      b['name']?.toString() ?? l10n.projectBuildingFallback,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _buildingId = v ?? _buildingId),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _floorFrom,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.projectFloorFromLabel,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _floorTo,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.projectFloorToLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _unitsPerFloor,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: l10n.projectUnitsPerFloorLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _startingNumber,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: l10n.projectStartingNumberLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.projectKindLabel),
              items: [
                for (final k in const ['apartment', 'office', 'retail'])
                  DropdownMenuItem(
                    value: k,
                    child: Text(
                      unitKindLabel(l10n, k),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _dealType,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.projectDealLabel),
              items: [
                for (final d in const ['sale', 'rent'])
                  DropdownMenuItem(
                    value: d,
                    child: Text(
                      dealTypeLabel(l10n, d),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _dealType = v ?? _dealType),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _areaTotal,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.projectAreaLabel,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _rooms,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.projectRoomsLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                labelText: _dealType == 'sale'
                    ? l10n.projectPriceLabel
                    : l10n.projectRentLabel,
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        SizedBox(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillButton(
                label: l10n.projectGenerate,
                expand: true,
                onPressed: () {
                  Navigator.pop(
                    context,
                    _BulkUnitsSpec(
                      buildingId: _buildingId,
                      floorFrom: int.tryParse(_floorFrom.text.trim()) ?? 1,
                      floorTo: int.tryParse(_floorTo.text.trim()) ?? 1,
                      unitsPerFloor:
                          int.tryParse(_unitsPerFloor.text.trim()) ?? 1,
                      startingNumber:
                          int.tryParse(_startingNumber.text.trim()) ?? 1,
                      kind: _kind,
                      dealType: _dealType,
                      areaTotal: double.tryParse(_areaTotal.text.trim()) ?? 50,
                      rooms: int.tryParse(_rooms.text.trim()) ?? 1,
                      price: double.tryParse(_price.text.trim()) ?? 0,
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
