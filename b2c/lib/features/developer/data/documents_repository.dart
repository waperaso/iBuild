import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../models/mock_data.dart';

/// Public verification summary (`GET /v1/developers/:id/verification`).
/// Returns null on failure so the card can fall back to badge + disclaimer.
class DocumentsRepository {
  DocumentsRepository(this._dio);

  final Dio _dio;

  /// Document statuses, or null if unavailable.
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
          // Omit "missing" rows; card treats absent types as no document.
          .where((d) => d['status'] != 'missing')
          .map(
            (d) => Document.fromJson({
              ...d,
              'id': '$developerId-${d['type']}',
              'developerId': developerId,
              // Public summary has no file URL.
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
