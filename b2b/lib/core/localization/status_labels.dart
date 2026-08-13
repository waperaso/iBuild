import '../../l10n/gen/app_localizations.dart';

/// Upper-cases the first character of [value], leaving the rest untouched.
/// Used for dynamic dropdown/label values that read better in sentence-case
/// (e.g. "Apartment", "Sale") while the raw API value stays lowercase.
String _capitalize(String value) => value.isEmpty
    ? value
    : '${value[0].toUpperCase()}${value.substring(1)}';

/// Maps raw API enum values (unit status, offer type, lead score, etc.) to
/// their localized display labels. The raw value is still what's sent back
/// to the API — only the on-screen text changes with the active language.
String unitStatusLabel(AppLocalizations l10n, String value) => switch (value) {
  'available' => l10n.statusAvailable,
  'reserved' => l10n.statusReserved,
  'sold' => l10n.statusSold,
  'rented' => l10n.statusRented,
  'blocked' => l10n.statusBlocked,
  _ => value,
};

String offerTypeLabel(AppLocalizations l10n, String value) => switch (value) {
  'discount' => l10n.offerTypeDiscount,
  'installment' => l10n.offerTypeInstallment,
  'rent_promo' => l10n.offerTypeRentPromo,
  _ => value,
};

String unitKindLabel(AppLocalizations l10n, String value) => _capitalize(
  switch (value) {
    'apartment' => l10n.unitKindApartment,
    'office' => l10n.unitKindOffice,
    'retail' => l10n.unitKindRetail,
    _ => value,
  },
);

String dealTypeLabel(AppLocalizations l10n, String value) => _capitalize(
  switch (value) {
    'sale' => l10n.dealTypeSale,
    'rent' => l10n.dealTypeRent,
    _ => value,
  },
);

/// Property type for a residence/project — shown in the B2B create-project
/// type picker (plan section 6: business centre / office / residential
/// complex / cottage, plus the legacy `street_retail`).
String projectTypeLabel(AppLocalizations l10n, String value) => switch (value) {
  'residential_complex' => l10n.projectTypeResidentialComplex,
  'business_centre' => l10n.projectTypeBusinessCentre,
  'street_retail' => l10n.projectTypeStreetRetail,
  'office' => l10n.projectTypeOffice,
  'cottage' => l10n.projectTypeCottage,
  _ => value,
};

/// Localized label for a developer's `accountKind` (as stored/returned by the
/// API). Falls back to the raw value for unknown kinds.
String accountKindLabel(AppLocalizations l10n, String value) => switch (value) {
  'property_developer' => l10n.applyKindDeveloperLabel,
  'construction_company' => l10n.applyKindConstructionLabel,
  _ => value,
};

String leadScoreLabel(AppLocalizations l10n, String value) => _capitalize(
  switch (value) {
    'hot' => l10n.leadScoreHot,
    'warm' => l10n.leadScoreWarm,
    'cold' => l10n.leadScoreCold,
    _ => value,
  },
);

String leadStatusLabel(AppLocalizations l10n, String value) => _capitalize(
  switch (value) {
    'new' => l10n.leadStatusNew,
    'contacted' => l10n.leadStatusContacted,
    'scheduled' => l10n.leadStatusScheduled,
    'visited' => l10n.leadStatusVisited,
    'qualified' => l10n.leadStatusQualified,
    'won' => l10n.leadStatusWon,
    'lost' => l10n.leadStatusLost,
    _ => value,
  },
);

String roleLabel(AppLocalizations l10n, String value) => switch (value) {
  'ordinary_user' => l10n.roleOrdinaryUser,
  'residence_admin' => l10n.roleResidenceAdmin,
  'system_admin' => l10n.roleSystemAdmin,
  _ => value,
};

/// Developer application review pipeline: pending ("waiting for review") ->
/// in_review ("on review") -> approved/rejected.
String developerStatusLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'draft' => l10n.devStatusDraft,
      'pending' => l10n.devStatusPending,
      'in_review' => l10n.devStatusInReview,
      'approved' => l10n.devStatusApproved,
      'rejected' => l10n.devStatusRejected,
      _ => value,
    };

/// Human-readable yes/no for the `isPublished` flag.
String publishedStatusLabel(AppLocalizations l10n, bool isPublished) =>
    isPublished ? l10n.publishedYes : l10n.publishedNo;

/// Verification document type — the 4 required types from the Documents
/// API frozen contract (license/construction_permit/land_rights/
/// project_declaration).
String documentTypeLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'license' => l10n.documentTypeLicense,
      'construction_permit' => l10n.documentTypeConstructionPermit,
      'land_rights' => l10n.documentTypeLandRights,
      'project_declaration' => l10n.documentTypeProjectDeclaration,
      'cadastre' => l10n.documentTypeCadastre,
      _ => value,
    };

/// Plain-language explanation of what a verification document type is —
/// shown in the (i) tooltip next to each upload row so an applicant doesn't
/// have to guess what e.g. "Project declaration" actually means.
String documentTypeHint(AppLocalizations l10n, String value) =>
    switch (value) {
      'license' => l10n.documentTypeLicenseHint,
      'construction_permit' => l10n.documentTypeConstructionPermitHint,
      'land_rights' => l10n.documentTypeLandRightsHint,
      'project_declaration' => l10n.documentTypeProjectDeclarationHint,
      'cadastre' => l10n.documentTypeCadastreHint,
      _ => '',
    };

/// Verification document review status (pending/accepted/rejected).
String documentStatusLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'pending' => l10n.documentStatusPending,
      'accepted' => l10n.documentStatusAccepted,
      'rejected' => l10n.documentStatusRejected,
      _ => value,
    };

/// ЖК / project moderation pipeline labels for residence-admin surfaces.
String projectModerationStatusLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'draft' => l10n.projectModerationStatusDraft,
      'pending' => l10n.projectModerationStatusPending,
      'approved' => l10n.adminProjectsFilterApproved,
      'rejected' => l10n.projectModerationStatusRejected,
      _ => value,
    };

/// The `aiBand` filter row in a lead workspace — plural forms ("Горячие"),
/// unlike [leadScoreLabel], which labels a single lead's band.
String aiBandFilterLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'hot' => l10n.crmBandFilterHot,
      'warm' => l10n.crmBandFilterWarm,
      'cold' => l10n.crmBandFilterCold,
      _ => l10n.crmBandFilterAll,
    };

/// `aiReasons[]` codes from `GET /ai/crm/leads` / bot `lead` cards (AI layer
/// plan, Part 3) — full list documented on the server's
/// `GET /v1/ai/crm/leads` route.
String aiReasonLabel(AppLocalizations l10n, String value) => switch (value) {
  'highIntent' => l10n.aiReasonHighIntent,
  'viewingRequested' => l10n.aiReasonViewingRequested,
  'specificUnit' => l10n.aiReasonSpecificUnit,
  'preferredTimeSet' => l10n.aiReasonPreferredTimeSet,
  'longMessage' => l10n.aiReasonLongMessage,
  'mortgageInterest' => l10n.aiReasonMortgageInterest,
  'cashBuyer' => l10n.aiReasonCashBuyer,
  'urgentKeyword' => l10n.aiReasonUrgentKeyword,
  'repeatContact' => l10n.aiReasonRepeatContact,
  'recentActivity' => l10n.aiReasonRecentActivity,
  'noResponse24h' => l10n.aiReasonNoResponse24h,
  'noResponse3d' => l10n.aiReasonNoResponse3d,
  'slaBreach' => l10n.aiReasonSlaBreach,
  'funnelAdvanced' => l10n.aiReasonFunnelAdvanced,
  'stalled' => l10n.aiReasonStalled,
  'hotProject' => l10n.aiReasonHotProject,
  'unitScarcity' => l10n.aiReasonUnitScarcity,
  'offplanInterest' => l10n.aiReasonOffplanInterest,
  'rentIntent' => l10n.aiReasonRentIntent,
  'lowSpecificity' => l10n.aiReasonLowSpecificity,
  _ => value,
};

/// The 8 construction-stage identifiers used by `declaredStage` /
/// `detectedStage` in the AI readiness check (plan Part 4).
const List<String> kReadinessStages = [
  'earthworks',
  'foundation',
  'frame_floors',
  'roofing',
  'facade',
  'utilities',
  'interior_finishing',
  'landscaping',
];

String readinessStageLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'earthworks' => l10n.readinessStageEarthworks,
      'foundation' => l10n.readinessStageFoundation,
      'frame_floors' => l10n.readinessStageFrameFloors,
      'roofing' => l10n.readinessStageRoofing,
      'facade' => l10n.readinessStageFacade,
      'utilities' => l10n.readinessStageUtilities,
      'interior_finishing' => l10n.readinessStageInteriorFinishing,
      'landscaping' => l10n.readinessStageLandscaping,
      _ => value,
    };

/// `overall_status` from `POST /photo-reports/analyze` (plan Part 4).
String readinessStatusLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'confirmed' => l10n.readinessStatusConfirmed,
      'requires_manual_review' => l10n.readinessStatusRequiresManualReview,
      'discrepancy_found' => l10n.readinessStatusDiscrepancyFound,
      'violation_found' => l10n.readinessStatusViolationFound,
      _ => value,
    };
