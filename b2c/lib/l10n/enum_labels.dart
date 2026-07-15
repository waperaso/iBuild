import 'package:flutter/widgets.dart';
import 'package:ibuild_core/ibuild_core.dart';

import 'gen/app_localizations.dart';

/// `BuildContext`-aware label getters for domain enums, kept separate from
/// `models/enums.dart` so the model layer stays free of UI/localization
/// concerns while call sites still read as `status.label(context)`.
extension ProjectTypeL10n on ProjectType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      ProjectType.residentialComplex => l10n.projectTypeResidentialComplex,
      ProjectType.businessCentre => l10n.projectTypeBusinessCentre,
      ProjectType.streetRetail => l10n.projectTypeStreetRetail,
      ProjectType.office => l10n.projectTypeOffice,
      ProjectType.cottage => l10n.projectTypeCottage,
    };
  }
}

extension ProjectStatusL10n on ProjectStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      ProjectStatus.planned => l10n.projectStatusPlanned,
      ProjectStatus.underConstruction => l10n.projectStatusUnderConstruction,
      ProjectStatus.ready => l10n.projectStatusReady,
      ProjectStatus.handedOver => l10n.projectStatusHandedOver,
    };
  }
}

extension UnitKindL10n on UnitKind {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      UnitKind.apartment => l10n.unitKindApartment,
      UnitKind.office => l10n.unitKindOffice,
      UnitKind.retail => l10n.unitKindRetail,
    };
  }
}

extension UnitStatusL10n on UnitStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      UnitStatus.available => l10n.statusAvailable,
      UnitStatus.reserved => l10n.statusReserved,
      UnitStatus.sold => l10n.statusSold,
      UnitStatus.rented => l10n.statusRented,
      UnitStatus.blocked => l10n.statusBlocked,
    };
  }
}

extension LeadIntentL10n on LeadIntent {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      LeadIntent.buy => l10n.leadIntentBuy,
      LeadIntent.buyOffplan => l10n.leadIntentBuyOffplan,
      LeadIntent.rent => l10n.leadIntentRent,
      LeadIntent.viewing => l10n.leadIntentViewing,
      LeadIntent.callback => l10n.leadIntentCallback,
    };
  }
}

extension LeadStatusL10n on LeadStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      LeadStatus.newLead => l10n.leadStatusNew,
      LeadStatus.contacted => l10n.leadStatusContacted,
      LeadStatus.scheduled => l10n.leadStatusScheduled,
      LeadStatus.visited => l10n.leadStatusVisited,
      LeadStatus.won => l10n.leadStatusWon,
      LeadStatus.lost => l10n.leadStatusLost,
    };
  }
}

extension DocumentTypeL10n on DocumentType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      DocumentType.license => l10n.documentTypeLicense,
      DocumentType.constructionPermit => l10n.documentTypeConstructionPermit,
      DocumentType.landRights => l10n.documentTypeLandRights,
      DocumentType.projectDeclaration => l10n.documentTypeProjectDeclaration,
      DocumentType.cadastre => l10n.documentTypeCadastre,
    };
  }
}

extension DocumentStatusL10n on DocumentStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      DocumentStatus.pending => l10n.documentStatusPending,
      DocumentStatus.accepted => l10n.documentStatusAccepted,
      DocumentStatus.rejected => l10n.documentStatusRejected,
    };
  }
}
