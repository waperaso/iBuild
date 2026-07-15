import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../models/mock_data.dart';

/// Developer verification documents backing the B2C "Verified" badge (plan
/// section 11 "Trust system") — live API or mock fallback (see
/// [ProjectsRepository] for the same seam).
///
/// Calls the public `GET /v1/developers/:id/verification` summary route
/// (no auth required — real buyers are never signed in as moderators), which
/// intentionally only exposes `{type, status}` per required document type
/// (no `fileUrl`/`rejectReason`/reviewer identity — those stay behind the
/// moderator-only `/v1/platform/developers/:id/documents` route). Any
/// failure (404, network error) is treated as "no data available" so the
/// verification card falls back to just the badge + disclaimer.
class DocumentsRepository {
  DocumentsRepository(this._dio);

  final Dio _dio;

  /// Returns this developer's documents, or `null` if the breakdown isn't
  /// available (no documents yet, or the endpoint isn't reachable) —
  /// callers should render just the badge + disclaimer in that case.
  Future<List<Document>?> fetchDeveloperDocuments(String developerId) async {
    if (Env.useMockData) {
      return MockData.documentsByDeveloper[developerId];
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/developers/$developerId/verification',
      );
      final rawDocuments =
          (response.data?['documents'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
      final documents = rawDocuments
          // The summary reports "missing" for required types with nothing
          // uploaded yet, so the client can render all 4 rows consistently;
          // omit those here — `latestOfType` returning `null` already
          // renders as "no document" in the card.
          .where((d) => d['status'] != 'missing')
          .map(
            (d) => Document.fromJson({
              ...d,
              'id': '$developerId-${d['type']}',
              'developerId': developerId,
              // Deliberately not part of the public summary payload.
              'fileUrl': '',
            }),
          )
          .toList();
      return documents.isEmpty ? null : documents;
    } on DioException {
      return null;
    }
  }
}

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepository(ref.watch(apiClientProvider));
});
