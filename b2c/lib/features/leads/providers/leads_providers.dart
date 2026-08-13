import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../data/leads_repository.dart';
import '../domain/lead_subject.dart';

/// Client's submitted leads ("My inquiries"), backed by [LeadsRepository]
/// (live API or mock fallback — see [ProjectsRepository] for the same seam).
class LeadsController extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() => ref.watch(leadsRepositoryProvider).fetchLeads();

  /// Submits a new lead (plan section 3.6) and prepends it to the list.
  /// [consent] must be `true` (the lead form gates the submit button on the
  /// PII consent checkbox before calling this).
  Future<Lead> submit({
    required String projectId,
    required String projectName,
    String? unitId,
    String? unitLabel,
    required LeadIntent intent,
    required String contactPhone,
    String? message,
    DateTime? preferredAt,
    required bool consent,
    LeadSubject? subject,
  }) async {
    final lead = await ref
        .read(leadsRepositoryProvider)
        .submitLead(
          projectId: projectId,
          projectName: projectName,
          unitId: unitId,
          unitLabel: unitLabel,
          intent: intent,
          contactPhone: contactPhone,
          message: message,
          preferredAt: preferredAt,
          consent: consent,
          subject: subject,
        );
    state = AsyncData([lead, ...(state.value ?? const [])]);
    return lead;
  }
}

final leadsProvider = AsyncNotifierProvider<LeadsController, List<Lead>>(
  LeadsController.new,
);
