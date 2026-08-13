import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'ai_models.dart';

/// Dio calls against the `/v1/ai/*` routes documented (Dart-doc, as the
/// authoritative contract) in `server/lib/src/ai/ai_routes.dart`. Chat is
/// live today; search is coded against its documented response shape ahead
/// of the sibling engine landing (it currently answers 501, surfaced here as
/// [AiException.isNotImplemented] rather than thrown as a raw [DioException]).
class AiRepository {
  AiRepository(this._dio);

  final Dio _dio;

  /// `POST /v1/ai/chat` — `{messages, user_language}` -> `{reply, quota}`.
  Future<AiChatReply> sendChat({
    required List<AiChatMessage> messages,
    required String userLanguage,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ai/chat',
        data: {
          'messages': messages.map((m) => m.toJson()).toList(),
          'user_language': userLanguage,
        },
      );
      return AiChatReply.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// `GET /v1/ai/chat/quota` — read-only, never consumes the budget.
  Future<AiQuota> fetchChatQuota() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/ai/chat/quota');
      return AiQuota.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// `POST /v1/ai/search` — `{query, user_language, constraints?, limit}`.
  /// When [constraints] is passed (e.g. after removing a chip), the server
  /// takes it as authoritative and skips re-parsing [query].
  Future<AiSearchResponse> search({
    required String query,
    required String userLanguage,
    Map<String, dynamic>? constraints,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ai/search',
        data: {
          'query': query,
          'user_language': userLanguage,
          'constraints': ?constraints,
          'limit': limit,
        },
      );
      return AiSearchResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// `POST /v1/ai/search/suggest` — `{query, user_language, limit}`. Cheap,
  /// deterministic and outside the AI quota, so the search bar can call it
  /// while the user types. Callers treat a failure as "no completion" rather
  /// than surfacing an error: it is a convenience, never a search.
  Future<AiSearchSuggestResponse> suggest({
    required String query,
    required String userLanguage,
    int limit = 6,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ai/search/suggest',
        data: {
          'query': query,
          'user_language': userLanguage,
          'limit': limit,
        },
      );
      return AiSearchSuggestResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Normalizes every failure mode — server error envelope, timeout/offline,
  /// and the demo read-only guard in `api_client.dart` — into [AiException]
  /// so no screen ever has to sniff a raw [DioException].
  AiException _mapError(DioException error) {
    if (error.type == DioExceptionType.cancel &&
        error.message == 'DEMO_READ_ONLY') {
      return const AiException(
        code: 'DEMO_READ_ONLY',
        message: 'Demo mode is view-only — this action was not saved.',
      );
    }

    final status = error.response?.statusCode;
    final body = error.response?.data;
    Map<String, dynamic>? errorObj;
    if (body is Map && body['error'] is Map) {
      errorObj = (body['error'] as Map).cast<String, dynamic>();
    }

    final code = errorObj?['code'] as String? ?? _fallbackCode(error, status);
    final message =
        errorObj?['message'] as String? ??
        error.message ??
        'Something went wrong.';

    AiQuota? quota;
    final quotaData = errorObj?['data'];
    if (quotaData is Map) {
      quota = AiQuota.fromJson(quotaData.cast<String, dynamic>());
    }

    final retryAfterHeader = error.response?.headers.value('retry-after');

    return AiException(
      code: code,
      message: message,
      statusCode: status,
      quota: quota,
      retryAfterSeconds: retryAfterHeader == null
          ? null
          : int.tryParse(retryAfterHeader),
    );
  }

  String _fallbackCode(DioException error, int? status) {
    if (status == null) return 'NETWORK';
    switch (status) {
      case 429:
        return 'RATE_LIMITED';
      case 501:
        return 'NOT_IMPLEMENTED';
      case 503:
        return 'AI_UNAVAILABLE';
      default:
        return 'UNKNOWN';
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(apiClientProvider));
});
