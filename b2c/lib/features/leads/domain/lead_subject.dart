import 'package:flutter/widgets.dart';

import '../../../l10n/gen/app_localizations.dart';

/// What the lead is about — sent as `subject` on `POST /leads` alongside
/// `projectId`/`unitId`/`intent` (plan Part 3). Defined locally in `b2c/`
/// rather than in `ibuild_core` since it's a client-form concern, not a
/// server-shared domain model.
enum LeadSubject { project, unit, rent, office, mortgage, other }

extension LeadSubjectWire on LeadSubject {
  /// Exact wire value the server contract expects.
  String get wire => switch (this) {
    LeadSubject.project => 'project',
    LeadSubject.unit => 'unit',
    LeadSubject.rent => 'rent',
    LeadSubject.office => 'office',
    LeadSubject.mortgage => 'mortgage',
    LeadSubject.other => 'other',
  };
}

extension LeadSubjectLabel on LeadSubject {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      LeadSubject.project => l10n.leadSubjectProject,
      LeadSubject.unit => l10n.leadSubjectUnit,
      LeadSubject.rent => l10n.leadSubjectRent,
      LeadSubject.office => l10n.leadSubjectOffice,
      LeadSubject.mortgage => l10n.leadSubjectMortgage,
      LeadSubject.other => l10n.leadSubjectOther,
    };
  }
}
