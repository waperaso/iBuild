import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/calculators_repository.dart';

/// Rental-yield calculator (`POST /v1/calculators/rental-yield`).
Future<void> showRentalYieldCalculatorSheet(
  BuildContext context, {
  required double price,
  double? initialMonthlyRent,
  double? areaTotal,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RentalYieldCalculatorSheet(
      price: price,
      initialMonthlyRent: initialMonthlyRent,
      areaTotal: areaTotal,
    ),
  );
}

class RentalYieldCalculatorSheet extends ConsumerStatefulWidget {
  const RentalYieldCalculatorSheet({
    super.key,
    required this.price,
    this.initialMonthlyRent,
    this.areaTotal,
  });

  final double price;
  final double? initialMonthlyRent;
  final double? areaTotal;

  @override
  ConsumerState<RentalYieldCalculatorSheet> createState() =>
      _RentalYieldCalculatorSheetState();
}

class _RentalYieldCalculatorSheetState
    extends ConsumerState<RentalYieldCalculatorSheet> {
  late final TextEditingController _rentController;
  RentalYieldQuote? _quote;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final defaultRent = widget.initialMonthlyRent ?? (widget.price * 0.006);
    _rentController = TextEditingController(
      text: defaultRent.toStringAsFixed(0),
    );
    _fetchQuote();
  }

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuote() async {
    final rent = double.tryParse(_rentController.text);
    if (rent == null || rent <= 0) return;
    setState(() => _loading = true);
    try {
      final quote = await ref
          .read(calculatorsRepositoryProvider)
          .rentalYieldQuote(
            price: widget.price,
            monthlyRent: rent,
            areaTotal: widget.areaTotal,
          );
      if (mounted) setState(() => _quote = quote);
    } catch (_) {
      // Keep the last known quote on transient network errors.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final quote = _quote;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                l10n.rentalYieldCalculatorTitle,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.rentalRentLabel, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _fetchQuote(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                color: colors.surfaceAlt,
                child: _loading && quote == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Text(l10n.calculatingLabel),
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.grossYieldLabel,
                                style: textTheme.bodyLarge,
                              ),
                              Text(
                                quote == null
                                    ? '-'
                                    : '${quote.grossYieldPercent.toStringAsFixed(1)}%',
                                style: textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          const Divider(height: AppSpacing.lg),
                          _QuoteRow(
                            label: l10n.annualRentLabel,
                            value: quote == null
                                ? '-'
                                : Formatters.price(quote.annualRent),
                          ),
                          _QuoteRow(
                            label: l10n.paybackYearsLabel,
                            value: quote == null
                                ? '-'
                                : l10n.paybackYearsValue(
                                    quote.paybackYears.toStringAsFixed(1),
                                  ),
                          ),
                          if (quote?.pricePerM2 != null &&
                              quote!.pricePerM2 > 0)
                            _QuoteRow(
                              label: l10n.comparePriceLabel,
                              value: Formatters.pricePerM2(quote.pricePerM2),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
