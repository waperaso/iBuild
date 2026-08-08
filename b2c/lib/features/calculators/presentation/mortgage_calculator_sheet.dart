import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/currency_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/calculators_repository.dart';

const double kDefaultMortgageRatePercent = 18;
const int kDefaultMortgageTermYears = 15;

/// Upper bound on the annual rate we'll send to the server, so a runaway value
/// can never explode the amortization factor client- or server-side.
const double kMaxMortgageRatePercent = 60;

/// Default starting price (canonical USD) when the calculator is opened without
/// a unit (Profile shortcut). Rough mid-market Tashkent primary-sale apartment.
const double kDefaultCalculatorPriceUsd = 65000;

/// Mortgage calculator (`POST /v1/calculators/mortgage`) + optional referral.
Future<void> showMortgageCalculatorSheet(
  BuildContext context, {
  double? price,
  String? projectId,
  String? unitId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MortgageCalculatorSheet(
      price: price ?? kDefaultCalculatorPriceUsd,
      projectId: projectId,
      unitId: unitId,
    ),
  );
}

class MortgageCalculatorSheet extends ConsumerStatefulWidget {
  const MortgageCalculatorSheet({
    super.key,
    required this.price,
    this.projectId,
    this.unitId,
  });

  /// Canonical USD price (catalog prices are stored in USD on the server).
  final double price;
  final String? projectId;
  final String? unitId;

  @override
  ConsumerState<MortgageCalculatorSheet> createState() =>
      _MortgageCalculatorSheetState();
}

class _MortgageCalculatorSheetState
    extends ConsumerState<MortgageCalculatorSheet> {
  /// Canonical price in USD. The editable field renders it in the active
  /// display currency and converts back on edit, so price, quote and results
  /// always share one currency without any double conversion.
  late double _priceUsd;
  double _downPaymentPercent = 0.2;
  int _termYears = kDefaultMortgageTermYears;
  double _annualRate = kDefaultMortgageRatePercent;
  MortgageQuote? _quote;
  bool _loading = false;
  bool _hasError = false;
  bool _consent = false;
  bool _submitting = false;
  Timer? _debounce;
  final _phone = TextEditingController(text: '+998 ');
  late final TextEditingController _priceController;

  /// Tracks the currency the price field was last rendered in, so we only
  /// rewrite its text (which would fight the user's cursor) when it changes.
  DisplayCurrency _fieldCurrency = Formatters.displayCurrency;

  @override
  void initState() {
    super.initState();
    _priceUsd = widget.price;
    _priceController = TextEditingController(
      text: Formatters.amountField(_priceUsd),
    );
    _fetchQuote();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authControllerProvider).value;
    if (user?.phone != null && user!.phone.isNotEmpty) {
      _phone.text = user.phone;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _phone.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _scheduleFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _fetchQuote);
  }

  void _onPriceChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(digits);
    if (parsed == null || parsed <= 0) return;
    setState(() => _priceUsd = Formatters.fromDisplay(parsed).toDouble());
    _scheduleFetch();
  }

  /// Rewrites the price field into [currency] without conversion drift when the
  /// user switches the app currency while the sheet is open.
  void _syncFieldCurrency(DisplayCurrency currency) {
    if (currency == _fieldCurrency) return;
    _fieldCurrency = currency;
    _priceController.text = Formatters.amountField(_priceUsd);
  }

  Future<void> _fetchQuote() async {
    if (_priceUsd <= 0) return;
    setState(() => _loading = true);
    try {
      final quote = await ref
          .read(calculatorsRepositoryProvider)
          .mortgageQuote(
            price: _priceUsd,
            downPaymentPercent: _downPaymentPercent.clamp(0.0, 1.0),
            termYears: _termYears,
            annualRatePercent: _annualRate.clamp(0.0, kMaxMortgageRatePercent),
          );
      if (mounted) {
        setState(() {
          _quote = quote;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReferral() async {
    final quote = _quote;
    if (quote == null || _submitting) return;
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(calculatorsRepositoryProvider)
          .submitMortgageReferral(
            price: _priceUsd,
            downPayment: quote.downPayment,
            termYears: _termYears,
            contactPhone: _phone.text.trim(),
            projectId: widget.projectId,
            unitId: widget.unitId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bankReferralSubmittedSnackbar)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    // Rebuilds (and re-formats results) whenever the display currency switches.
    final currency = ref.watch(currencyControllerProvider);
    _syncFieldCurrency(currency);
    final quote = _quote;
    final canSubmit =
        quote != null && _consent && _phone.text.trim().length >= 9;

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
                l10n.mortgageCalculatorTitle,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.\s ]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: InputDecoration(
                  labelText: l10n.mortgagePropertyPriceLabel,
                  suffixText: Formatters.currencyCode,
                ),
                onChanged: _onPriceChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.downPaymentLabel(
                  (_downPaymentPercent * 100).round(),
                  Formatters.price(_priceUsd * _downPaymentPercent),
                ),
                style: textTheme.titleMedium,
              ),
              Slider(
                value: _downPaymentPercent,
                min: 0.0,
                max: 0.9,
                divisions: 18,
                label: '${(_downPaymentPercent * 100).round()}%',
                onChanged: (value) {
                  setState(() => _downPaymentPercent = value);
                  _scheduleFetch();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.termYearsLabel(_termYears),
                style: textTheme.titleMedium,
              ),
              Slider(
                value: _termYears.toDouble(),
                min: 1,
                max: 25,
                divisions: 24,
                label: '$_termYears',
                onChanged: (value) {
                  setState(() => _termYears = value.round());
                  _scheduleFetch();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.interestRateLabel(_annualRate.toStringAsFixed(1)),
                style: textTheme.titleMedium,
              ),
              Slider(
                value: _annualRate,
                min: 0,
                max: 36,
                divisions: 72,
                label: '${_annualRate.toStringAsFixed(1)}%',
                onChanged: (value) {
                  setState(() => _annualRate = value);
                  _scheduleFetch();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                color: colors.surfaceAlt,
                child: _buildQuoteBody(context, l10n, quote),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\s()-]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: InputDecoration(
                  labelText: l10n.contactPhoneLabel,
                  hintText: l10n.phoneHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _consent,
                onChanged: (value) => setState(() => _consent = value ?? false),
                title: Text(
                  l10n.bankReferralConsentLabel,
                  style: textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PillButton(
                label: l10n.requestBankConsultationAction,
                expand: true,
                loading: _submitting,
                onPressed: canSubmit ? _submitReferral : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteBody(
    BuildContext context,
    AppLocalizations l10n,
    MortgageQuote? quote,
  ) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    if (_loading && quote == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(l10n.calculatingLabel),
        ),
      );
    }

    if (_hasError && quote == null) {
      return Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.somethingWentWrong,
              style: textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          ),
          TextButton(onPressed: _fetchQuote, child: Text(l10n.retry)),
        ],
      );
    }

    return Column(
      children: [
        if (_hasError) ...[
          Row(
            children: [
              Icon(Icons.cloud_off, size: 16, color: colors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.somethingWentWrong,
                  style: textTheme.labelMedium?.copyWith(color: colors.warning),
                ),
              ),
              TextButton(onPressed: _fetchQuote, child: Text(l10n.retry)),
            ],
          ),
          const Divider(height: AppSpacing.lg),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.monthlyPaymentLabel, style: textTheme.bodyLarge),
            Text(
              quote == null ? '-' : Formatters.price(quote.monthlyPayment),
              style: textTheme.headlineSmall,
            ),
          ],
        ),
        const Divider(height: AppSpacing.lg),
        _QuoteRow(
          label: l10n.totalInterestLabel,
          value: quote == null ? '-' : Formatters.price(quote.totalInterest),
        ),
        _QuoteRow(
          label: l10n.totalPaymentLabel,
          value: quote == null ? '-' : Formatters.price(quote.totalPayment),
        ),
      ],
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
