import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_api.dart';

/// Lead statuses used across the AI CRM panel and bot lead-editor dialogs —
/// mirrors `_kLeadStatuses` in platform_crm.dart / project_detail_admin.dart.
const kAiCrmLeadStatuses = [
  'new',
  'contacted',
  'scheduled',
  'visited',
  'qualified',
  'won',
  'lost',
];

/// Orders leads inside a kanban column by AI urgency — highest `aiScore`
/// first, with leads the scoring engine has not reached yet left at the
/// bottom in their original newest-first order.
int compareLeadsByAiUrgency(Map<String, dynamic> a, Map<String, dynamic> b) {
  final scoreA = (a['aiScore'] as num?)?.toDouble();
  final scoreB = (b['aiScore'] as num?)?.toDouble();
  if (scoreA == null) return scoreB == null ? 0 : 1;
  if (scoreB == null) return -1;
  return scoreB.compareTo(scoreA);
}

/// Filters for [aiCrmLeadsProvider] — identity-equatable so Riverpod caches
/// one request per distinct scope (platform-wide, one developer's leads, or
/// one project's leads).
class AiCrmScope {
  const AiCrmScope({this.projectId, this.owner, this.band, this.limit = 20});

  final String? projectId;
  final String? owner;
  final String? band;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is AiCrmScope &&
      other.projectId == projectId &&
      other.owner == owner &&
      other.band == band &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(projectId, owner, band, limit);
}

/// Result of `GET /ai/crm/leads`. [available] is false on any error
/// (including the 501 the server sibling returns until the scoring engine
/// ships) so the UI always has a calm, non-crashing state to render.
class AiCrmLeadsResult {
  const AiCrmLeadsResult({
    required this.leads,
    required this.metrics,
    required this.available,
  });

  final List<Map<String, dynamic>> leads;
  final Map<String, dynamic>? metrics;
  final bool available;
}

final aiCrmLeadsProvider = FutureProvider.family<AiCrmLeadsResult, AiCrmScope>((
  ref,
  scope,
) async {
  try {
    final data = await ref
        .watch(adminApiProvider)
        .aiCrmLeads(
          projectId: scope.projectId,
          owner: scope.owner,
          band: scope.band,
          limit: scope.limit,
        );
    return AiCrmLeadsResult(
      leads: (data['leads'] as List? ?? const []).cast<Map<String, dynamic>>(),
      metrics: data['metrics'] as Map<String, dynamic>?,
      available: true,
    );
  } on DioException {
    return const AiCrmLeadsResult(leads: [], metrics: null, available: false);
  } catch (_) {
    return const AiCrmLeadsResult(leads: [], metrics: null, available: false);
  }
});
