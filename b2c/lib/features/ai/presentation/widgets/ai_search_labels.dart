import 'package:flutter/widgets.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/enum_labels.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/ai_models.dart';
import '../../providers/ai_search_providers.dart';

/// Localizes one `steps[].code` entry into one of its 3–4 phrasing variants,
/// picked deterministically by [stepVariantIndex] so repeat searches for the
/// same query don't read identically but a given search stays stable while
/// it paces through its own step log.
String aiSearchStepLabel(AppLocalizations l10n, String query, AiSearchStep step) {
  int variant(int count) => stepVariantIndex(query, step.code, count);

  switch (step.code) {
    case 'parsing':
      final count = step.paramInt('constraintCount') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepParsingV1(count),
        1 => l10n.aiStepParsingV2(count),
        2 => l10n.aiStepParsingV3(count),
        _ => l10n.aiStepParsingV4(count),
      };
    case 'scanningDistrict':
      final district = step.paramString('district') ?? '';
      final count = step.paramInt('projectsScanned') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepScanningDistrictV1(district, count),
        1 => l10n.aiStepScanningDistrictV2(district, count),
        2 => l10n.aiStepScanningDistrictV3(district, count),
        _ => l10n.aiStepScanningDistrictV4(district, count),
      };
    case 'foundInDistrict':
      final district = step.paramString('district') ?? '';
      final count = step.paramInt('count') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepFoundInDistrictV1(district, count),
        1 => l10n.aiStepFoundInDistrictV2(district, count),
        2 => l10n.aiStepFoundInDistrictV3(district, count),
        _ => l10n.aiStepFoundInDistrictV4(district, count),
      };
    case 'openingProject':
      final project = step.paramString('project') ?? '';
      final index = step.paramInt('index') ?? 0;
      final total = step.paramInt('total') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepOpeningProjectV1(project, index, total),
        1 => l10n.aiStepOpeningProjectV2(project, index, total),
        2 => l10n.aiStepOpeningProjectV3(project, index, total),
        _ => l10n.aiStepOpeningProjectV4(project, index, total),
      };
    case 'scanningUnits':
      final project = step.paramString('project') ?? '';
      final count = step.paramInt('count') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepScanningUnitsV1(project, count),
        1 => l10n.aiStepScanningUnitsV2(project, count),
        2 => l10n.aiStepScanningUnitsV3(project, count),
        _ => l10n.aiStepScanningUnitsV4(project, count),
      };
    case 'filteringBooked':
      final removed = step.paramInt('removed') ?? 0;
      final left = step.paramInt('left') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepFilteringBookedV1(removed, left),
        1 => l10n.aiStepFilteringBookedV2(removed, left),
        2 => l10n.aiStepFilteringBookedV3(removed, left),
        _ => l10n.aiStepFilteringBookedV4(removed, left),
      };
    case 'rankingPrice':
      final count = step.paramInt('count') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepRankingPriceV1(count),
        1 => l10n.aiStepRankingPriceV2(count),
        2 => l10n.aiStepRankingPriceV3(count),
        _ => l10n.aiStepRankingPriceV4(count),
      };
    case 'done':
      final count = step.paramInt('count') ?? 0;
      final elapsedMs = step.paramInt('elapsedMs') ?? 0;
      return switch (variant(4)) {
        0 => l10n.aiStepDoneV1(count, elapsedMs),
        1 => l10n.aiStepDoneV2(count, elapsedMs),
        2 => l10n.aiStepDoneV3(count, elapsedMs),
        _ => l10n.aiStepDoneV4(count, elapsedMs),
      };
    // The clarification codes carry the server's own reading of the query, so
    // they read as one definite sentence rather than a phrasing variant.
    case 'noMatchIntent':
      return l10n.aiStepNoMatchIntent(_joinTerms(step, 'terms'));
    case 'lowConfidence':
      return l10n.aiStepLowConfidence(
        _joinTerms(step, 'terms'),
        step.paramInt('count') ?? 0,
      );
    case 'autocorrected':
      return l10n.aiStepAutocorrected(
        step.paramString('from') ?? '',
        step.paramString('to') ?? '',
      );
    case 'softenedAmenity':
      return l10n.aiStepSoftenedAmenity(step.paramString('amenity') ?? '');
    default:
      // Defensive only — every code the contract documents is handled above;
      // an unknown code (future server addition) still renders as text
      // rather than crashing the reveal loop.
      return step.code;
  }
}

/// Flattens a list-valued step param (`terms`) into one readable enumeration.
String _joinTerms(AiSearchStep step, String key) {
  final raw = step.params[key];
  if (raw is List) return raw.map((e) => '$e').join(', ');
  return raw == null ? '' : '$raw';
}

/// Localizes one `matchReasons[]` code into a short chip label.
String aiMatchReasonLabel(AppLocalizations l10n, String code) => switch (code) {
  'districtMatch' => l10n.aiReasonDistrictMatch,
  'roomsMatch' => l10n.aiReasonRoomsMatch,
  'priceFit' => l10n.aiReasonPriceFit,
  'priceBelowBudget' => l10n.aiReasonPriceBelowBudget,
  'areaFit' => l10n.aiReasonAreaFit,
  'floorPreference' => l10n.aiReasonFloorPreference,
  'dealTypeMatch' => l10n.aiReasonDealTypeMatch,
  'kindMatch' => l10n.aiReasonKindMatch,
  'availableNow' => l10n.aiReasonAvailableNow,
  'amenityMatch' => l10n.aiReasonAmenityMatch,
  'developerMatch' => l10n.aiReasonDeveloperMatch,
  'projectMatch' => l10n.aiReasonProjectMatch,
  'highTrustIndex' => l10n.aiReasonHighTrustIndex,
  'readySoon' => l10n.aiReasonReadySoon,
  'offplanDiscount' => l10n.aiReasonOffplanDiscount,
  _ => code,
};

/// `/ai/search`'s `constraints.unitKind` domain is `apartment | commercial |
/// parking` (see the contract in `ai_routes.dart`) — a different, coarser
/// vocabulary than the catalogue's own `UnitKind` (`apartment | office |
/// retail`), so it is labeled with its own ARB strings rather than routed
/// through `UnitKindL10n`.
String? _aiUnitKindLabel(AppLocalizations l10n, String wire) => switch (wire) {
  'apartment' => l10n.aiUnitKindApartment,
  'commercial' => l10n.aiUnitKindCommercial,
  'parking' => l10n.aiUnitKindParking,
  _ => null,
};

ProjectStatus? _projectStatusFromWire(String wire) => switch (wire) {
  'planned' => ProjectStatus.planned,
  'under_construction' => ProjectStatus.underConstruction,
  'ready' => ProjectStatus.ready,
  'handed_over' => ProjectStatus.handedOver,
  _ => null,
};

String _formatConstraintMoney(double amount, String? currency) {
  if (currency == 'UZS') {
    return '${NumberFormat.decimalPattern('uz').format(amount.round())} so\u02bbm';
  }
  return NumberFormat.currency(symbol: r'$', decimalDigits: 0).format(amount);
}

/// One removable chip: its label plus the raw-map keys to drop when the
/// user taps its "×" (see [AiSearchConstraints.withoutKeys]).
class AiConstraintChipData {
  const AiConstraintChipData({required this.label, required this.removeKeys});

  final String label;
  final Set<String> removeKeys;
}

/// Builds one chip per active field in [constraints] — every field the
/// server can return in `constraints` (plan Part 2) has a renderer here,
/// `currency` (qualifies the price chip) and `unrecognized` (diagnostic,
/// not a filter) are intentionally not chips of their own.
List<AiConstraintChipData> buildAiConstraintChips(
  BuildContext context,
  AiSearchConstraints constraints,
) {
  final l10n = AppLocalizations.of(context);
  final chips = <AiConstraintChipData>[];

  final rooms = constraints.rooms;
  if (rooms != null && rooms.isNotEmpty) {
    final label = rooms
        .map((r) => r == 0 ? l10n.roomsStudio : '$r')
        .join(', ');
    chips.add(AiConstraintChipData(label: label, removeKeys: {'rooms'}));
  }

  final priceMin = constraints.priceMin;
  final priceMax = constraints.priceMax;
  if (priceMin != null || priceMax != null) {
    final currency = constraints.currency;
    final label = priceMin != null && priceMax != null
        ? l10n.priceRangeLabel(
            _formatConstraintMoney(priceMin, currency),
            _formatConstraintMoney(priceMax, currency),
          )
        : priceMax != null
        ? l10n.savedSearchUnderPrice(_formatConstraintMoney(priceMax, currency))
        : l10n.savedSearchFromPrice(
            _formatConstraintMoney(priceMin!, currency),
          );
    chips.add(
      AiConstraintChipData(
        label: label,
        removeKeys: {'priceMin', 'priceMax'},
      ),
    );
  }

  final areaMin = constraints.areaMin;
  final areaMax = constraints.areaMax;
  if (areaMin != null || areaMax != null) {
    final label = areaMin != null && areaMax != null
        ? l10n.aiChipAreaRange(areaMin.round(), areaMax.round())
        : areaMax != null
        ? l10n.aiChipAreaUpTo(areaMax.round())
        : l10n.aiChipAreaFrom(areaMin!.round());
    chips.add(
      AiConstraintChipData(label: label, removeKeys: {'areaMin', 'areaMax'}),
    );
  }

  final district = constraints.district;
  if (district != null && district.isNotEmpty) {
    chips.add(AiConstraintChipData(label: district, removeKeys: {'district'}));
  }

  final dealType = constraints.dealType;
  if (dealType != null && dealType.isNotEmpty) {
    chips.add(
      AiConstraintChipData(
        label: dealType == 'rent' ? l10n.aiDealTypeRent : l10n.aiDealTypeSale,
        removeKeys: {'dealType'},
      ),
    );
  }

  final unitKind = constraints.unitKind;
  if (unitKind != null && unitKind.isNotEmpty) {
    final label = _aiUnitKindLabel(l10n, unitKind);
    chips.add(
      AiConstraintChipData(
        label: label ?? unitKind,
        removeKeys: {'unitKind'},
      ),
    );
  }

  final projectStatus = constraints.projectStatus;
  if (projectStatus != null && projectStatus.isNotEmpty) {
    final parsed = _projectStatusFromWire(projectStatus);
    chips.add(
      AiConstraintChipData(
        label: parsed == null ? projectStatus : parsed.label(context),
        removeKeys: {'projectStatus'},
      ),
    );
  }

  if (constraints.isOffplan == true) {
    chips.add(
      AiConstraintChipData(
        label: l10n.offplanOnlyLabel,
        removeKeys: {'isOffplan'},
      ),
    );
  }

  final floorMin = constraints.floorMin;
  final floorMax = constraints.floorMax;
  if (floorMin != null || floorMax != null) {
    final label = floorMin != null && floorMax != null
        ? l10n.aiChipFloorRange(floorMin, floorMax)
        : floorMin != null
        ? l10n.aiChipFloorFrom(floorMin)
        : l10n.aiChipFloorUpTo(floorMax!);
    chips.add(
      AiConstraintChipData(
        label: label,
        removeKeys: {'floorMin', 'floorMax'},
      ),
    );
  }

  if (constraints.notFirstFloor == true) {
    chips.add(
      AiConstraintChipData(
        label: l10n.aiChipNotFirstFloor,
        removeKeys: {'notFirstFloor'},
      ),
    );
  }

  if (constraints.notLastFloor == true) {
    chips.add(
      AiConstraintChipData(
        label: l10n.aiChipNotLastFloor,
        removeKeys: {'notLastFloor'},
      ),
    );
  }

  if (constraints.availableOnly == true) {
    chips.add(
      AiConstraintChipData(
        label: l10n.aiChipAvailableOnly,
        removeKeys: {'availableOnly'},
      ),
    );
  }

  final amenities = constraints.amenities;
  if (amenities != null && amenities.isNotEmpty) {
    chips.add(
      AiConstraintChipData(
        label: amenities.join(', '),
        removeKeys: {'amenities'},
      ),
    );
  }

  final excludedAmenities = constraints.excludedAmenities;
  if (excludedAmenities != null && excludedAmenities.isNotEmpty) {
    chips.add(
      AiConstraintChipData(
        label: l10n.aiConstraintWithout(excludedAmenities.join(', ')),
        removeKeys: {'excludedAmenities'},
      ),
    );
  }

  final developerName = constraints.developerName;
  if (developerName != null && developerName.isNotEmpty) {
    chips.add(
      AiConstraintChipData(
        label: developerName,
        removeKeys: {'developerName'},
      ),
    );
  }

  final projectName = constraints.projectName;
  if (projectName != null && projectName.isNotEmpty) {
    chips.add(
      AiConstraintChipData(label: projectName, removeKeys: {'projectName'}),
    );
  }

  return chips;
}
