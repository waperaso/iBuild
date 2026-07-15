import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Freeform defaults used when no matching installment [Offer] can be
/// resolved for the unit/project (plan Phase 3, installment calculator).
const double kDefaultDownPaymentPercent = 0.2;
const int kDefaultTermMonths = 12;
const double kDefaultInterestRate = 0.0;

Future<void> showInstallmentCalculatorSheet(
  BuildContext context, {
  required double price,
  Offer? offer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        InstallmentCalculatorSheet(price: price, offer: offer),
  );
}

/// Down-payment / term sliders with a live-computed monthly payment,
/// seeded from an [Offer]'s installment terms when available.
class InstallmentCalculatorSheet extends StatefulWidget {
  const InstallmentCalculatorSheet({
    super.key,
    required this.price,
    this.offer,
  });

  final double price;
  final Offer? offer;

  @override
  State<InstallmentCalculatorSheet> createState() =>
      _InstallmentCalculatorSheetState();
}

class _InstallmentCalculatorSheetState
    extends State<InstallmentCalculatorSheet> {
  late double _downPaymentPercent;
  late int _termMonths;
  late double _interestRate;

  @override
  void initState() {
    super.initState();
    _downPaymentPercent =
        widget.offer?.downPaymentPercent ?? kDefaultDownPaymentPercent;
    _termMonths = widget.offer?.termMonths ?? kDefaultTermMonths;
    _interestRate = widget.offer?.interestRate ?? kDefaultInterestRate;
  }

  double get _monthlyPayment {
    if (_termMonths <= 0) return 0;
    return (widget.price * (1 - _downPaymentPercent) * (1 + _interestRate)) /
        _termMonths;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

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
              l10n.installmentCalculatorTitle,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.downPaymentLabel(
                (_downPaymentPercent * 100).round(),
                Formatters.price(widget.price * _downPaymentPercent),
              ),
              style: textTheme.titleMedium,
            ),
            Slider(
              value: _downPaymentPercent,
              min: 0.1,
              max: 0.9,
              divisions: 16,
              label: '${(_downPaymentPercent * 100).round()}%',
              onChanged: (value) => setState(() => _downPaymentPercent = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.termMonthsLabel(_termMonths),
              style: textTheme.titleMedium,
            ),
            Slider(
              value: _termMonths.toDouble(),
              min: 3,
              max: 60,
              divisions: 57,
              label: '$_termMonths',
              onChanged: (value) => setState(() => _termMonths = value.round()),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              color: colors.surfaceAlt,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.monthlyPaymentLabel, style: textTheme.bodyLarge),
                  Text(
                    Formatters.price(_monthlyPayment),
                    style: textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
