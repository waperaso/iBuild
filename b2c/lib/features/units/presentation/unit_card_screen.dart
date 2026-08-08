import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/localization/currency_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../calculators/presentation/mortgage_calculator_sheet.dart';
import '../../calculators/presentation/rental_yield_calculator_sheet.dart';
import '../providers/units_providers.dart';
import 'widgets/installment_calculator_sheet.dart';

/// Unit detail: gallery, headline price, spec chips and lead CTAs
/// (Book a viewing / Request a callback / Reserve — plan section 3.5).
class UnitCardScreen extends ConsumerWidget {
  const UnitCardScreen({super.key, required this.unitId, this.projectId});

  final String unitId;
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final unitAsync = ref.watch(unitByIdProvider(unitId));
    final unit = unitAsync.value;
    final l10n = AppLocalizations.of(context);
    ref.watch(currencyControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          unit == null
              ? l10n.unitFallbackTitle
              : l10n.unitNumberTitle(unit.number),
        ),
      ),
      body: AsyncValueView(
        value: unitAsync,
        onRetry: () => ref.invalidate(unitByIdProvider(unitId)),
        builder: (context, resolvedUnit) => resolvedUnit == null
            ? Center(child: Text(l10n.unitNotFound))
            : _Body(unit: resolvedUnit, projectId: projectId),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.unit, this.projectId});

  final Unit unit;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    final isWide = !context.isMobile;

    return ConstrainedBody(
      maxWidth: isWide ? 1040 : 760,
      child: isWide
          ? _DesktopUnitLayout(unit: unit, projectId: projectId)
          : _MobileUnitLayout(unit: unit, projectId: projectId),
    );
  }
}

class _MobileUnitLayout extends StatelessWidget {
  const _MobileUnitLayout({required this.unit, this.projectId});

  final Unit unit;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _UnitHeroImage(unit: unit),
        const SizedBox(height: AppSpacing.lg),
        _UnitSummary(unit: unit, projectId: projectId),
      ],
    );
  }
}

class _DesktopUnitLayout extends StatelessWidget {
  const _DesktopUnitLayout({required this.unit, this.projectId});

  final Unit unit;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 11, child: _UnitHeroImage(unit: unit, desktop: true)),
          const SizedBox(width: AppSpacing.xxl),
          Expanded(
            flex: 9,
            child: _UnitSummary(
              unit: unit,
              projectId: projectId,
              desktop: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitHeroImage extends StatelessWidget {
  const _UnitHeroImage({required this.unit, this.desktop = false});

  final Unit unit;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = unit.media.isNotEmpty ? unit.media.first.url : null;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: AspectRatio(
        aspectRatio: desktop ? 4 / 3 : 16 / 10,
        child: imageUrl != null
            ? AppNetworkImage(url: imageUrl, width: double.infinity)
            : ColoredBox(
                color: colors.surface,
                child: Icon(
                  Icons.apartment,
                  size: desktop ? 48 : 64,
                  color: colors.inkMuted,
                ),
              ),
      ),
    );

    if (!desktop) return image;

    return AppCard(padding: EdgeInsets.zero, child: image);
  }
}

class _UnitSummary extends StatelessWidget {
  const _UnitSummary({
    required this.unit,
    this.projectId,
    this.desktop = false,
  });

  final Unit unit;
  final String? projectId;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isRent = unit.dealType == DealType.rent;
    final headline = isRent
        ? Formatters.rentMonthly(unit.rentMonthly ?? 0)
        : Formatters.price(unit.price ?? 0);
    final perM2 = isRent
        ? (unit.rentM2 != null
              ? '${Formatters.price(unit.rentM2!)}/m²·mo'
              : null)
        : (unit.priceM2 != null ? Formatters.pricePerM2(unit.priceM2!) : null);

    final chips = <String>[
      if (unit.rooms != null) l10n.roomsCount(unit.rooms!),
      if (unit.layout != null) unit.layout!,
      if (unit.areaTotal != null) Formatters.area(unit.areaTotal!),
      if (unit.finishing != null) unit.finishing!,
      if (unit.view != null) l10n.viewLabel(unit.view!),
      l10n.floorLabel(unit.floor),
    ];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: desktop
                        ? textTheme.headlineLarge
                        : textTheme.displayMedium,
                  ),
                  if (perM2 != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      perM2,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            UnitStatusBadge(status: unit.status),
          ],
        ),
        if (unit.isOffplan) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TagBadge(label: l10n.offplanInstallmentBadge, filled: true),
              if (unit.price != null)
                TextButton(
                  onPressed: () => showInstallmentCalculatorSheet(
                    context,
                    price: unit.price!,
                  ),
                  child: Text(l10n.installmentCalculatorTitle),
                ),
            ],
          ),
        ],
        if (!isRent && unit.price != null) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => showMortgageCalculatorSheet(
                  context,
                  price: unit.price!,
                  projectId: projectId,
                  unitId: unit.id,
                ),
                icon: const Icon(Icons.account_balance_outlined, size: 18),
                label: Text(l10n.mortgageCalculatorAction),
              ),
              OutlinedButton.icon(
                onPressed: () => showRentalYieldCalculatorSheet(
                  context,
                  price: unit.price!,
                  areaTotal: unit.areaTotal,
                ),
                icon: const Icon(Icons.trending_up, size: 18),
                label: Text(l10n.rentalYieldCalculatorAction),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final c in chips) TagBadge(label: c)],
        ),
        if (isRent && unit.minLeaseMonths != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            border: true,
            color: colors.background,
            child: Row(
              children: [
                Icon(Icons.schedule, color: colors.inkMuted, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.minimumLeaseMonths(unit.minLeaseMonths!),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: desktop ? AppSpacing.xxl : AppSpacing.xl),
        _UnitActions(unit: unit, projectId: projectId),
      ],
    );

    if (!desktop) return content;

    return AppCard(child: content);
  }
}

class _UnitActions extends StatelessWidget {
  const _UnitActions({
    required this.unit,
    this.projectId,
  });

  final Unit unit;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRent = unit.dealType == DealType.rent;

    void lead() {
      final project = projectId != null ? '&project=$projectId' : '';
      context.go('/home/lead/new?unit=${unit.id}$project');
    }

    final viewing = PillButton(
      label: l10n.bookViewing,
      variant: PillButtonVariant.outline,
      expand: true,
      onPressed: lead,
    );
    final primary = PillButton(
      label: isRent ? l10n.rentEnquiry : l10n.reserve,
      expand: true,
      onPressed: lead,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        viewing,
        const SizedBox(height: AppSpacing.md),
        primary,
      ],
    );
  }
}
