import 'package:json_annotation/json_annotation.dart';

/// Domain enums mirroring the backend schema (plan section 7.2 "Status enums").
/// `@JsonValue` keeps wire values aligned with the API's snake_case strings.

enum ProjectType {
  @JsonValue('residential_complex')
  residentialComplex,
  @JsonValue('business_centre')
  businessCentre,
  @JsonValue('street_retail')
  streetRetail,
  @JsonValue('office')
  office,
  @JsonValue('cottage')
  cottage,
}

enum ProjectStatus {
  @JsonValue('planned')
  planned,
  @JsonValue('under_construction')
  underConstruction,
  @JsonValue('ready')
  ready,
  @JsonValue('handed_over')
  handedOver,
}

enum UnitKind {
  @JsonValue('apartment')
  apartment,
  @JsonValue('office')
  office,
  @JsonValue('retail')
  retail,
}

enum DealType {
  @JsonValue('sale')
  sale,
  @JsonValue('rent')
  rent,
}

enum UnitStatus {
  @JsonValue('available')
  available,
  @JsonValue('reserved')
  reserved,
  @JsonValue('sold')
  sold,
  @JsonValue('rented')
  rented,
  @JsonValue('blocked')
  blocked,
}

enum LeadIntent {
  @JsonValue('buy')
  buy,
  @JsonValue('buy_offplan')
  buyOffplan,
  @JsonValue('rent')
  rent,
  @JsonValue('viewing')
  viewing,
  @JsonValue('callback')
  callback,
}

enum LeadStatus {
  @JsonValue('new')
  newLead,
  @JsonValue('contacted')
  contacted,
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('visited')
  visited,
  @JsonValue('won')
  won,
  @JsonValue('lost')
  lost,
}

enum MediaType {
  @JsonValue('photo')
  photo,
  @JsonValue('floorplan')
  floorplan,
  @JsonValue('render')
  render,
  @JsonValue('tour')
  tour,
}

enum OfferType {
  @JsonValue('discount')
  discount,
  @JsonValue('installment')
  installment,
  @JsonValue('rent_promo')
  rentPromo,
}

/// The Buy / Rent / New-builds toggle used across discovery (plan section 3.2).
enum DiscoveryMode { buy, rent, newBuilds }

/// Verification document types a developer must upload (plan section 11) —
/// all 4 must be `accepted` before the platform lets a developer's "Verified"
/// status mean anything (see `server`'s developer-approve gating).
enum DocumentType {
  @JsonValue('license')
  license,
  @JsonValue('construction_permit')
  constructionPermit,
  @JsonValue('land_rights')
  landRights,
  @JsonValue('project_declaration')
  projectDeclaration,
  /// Optional — cadastral document. Never required for approval (not part
  /// of [requiredDocumentTypes]), but uploadable alongside the required 4.
  @JsonValue('cadastre')
  cadastre,
}

/// Moderation status of one uploaded [DocumentType].
enum DocumentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected,
}

/// Human-readable labels for these enums are localized — each app's own
/// `l10n/enum_labels.dart` provides `BuildContext`-aware `.label(context)`
/// extension methods used throughout the UI.
extension LeadStatusX on LeadStatus {
  bool get isActive => switch (this) {
    LeadStatus.newLead || LeadStatus.contacted || LeadStatus.scheduled => true,
    _ => false,
  };
}
