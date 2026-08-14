import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'ai_chat_models.dart';

/// Dio calls against the `/v1/ai/b2b/*` routes — the free-form B2B AI
/// assistant chat (admin-only: system admin gets a platform-wide analyst
/// view, residence admin gets their own residence's data). Distinct from
/// the guided `CRM assistant` (`admin_api.dart`'s `aiCrmQuery`), which stays a
/// separate, node-based Q&A flow.
class AiChatRepository {
  AiChatRepository(this._dio);

  final Dio _dio;

  /// `POST /v1/ai/b2b/chat` — `{messages, user_language}` -> `{reply, quota}`.
  Future<AiChatReply> sendChat({
    required List<AiChatMessage> messages,
    required String userLanguage,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ai/b2b/chat',
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

  /// `GET /v1/ai/b2b/chat/quota` — read-only, never consumes the budget.
  Future<AiQuota> fetchChatQuota() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/ai/b2b/chat/quota',
      );
      return AiQuota.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Normalizes every failure mode — server error envelope, timeout/offline,
  /// and the demo read-only guard in `api_client.dart` — into
  /// [AiChatException] so no screen ever has to sniff a raw [DioException].
  AiChatException _mapError(DioException error) {
    if (error.type == DioExceptionType.cancel &&
        error.message == 'DEMO_READ_ONLY') {
      return const AiChatException(
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

    final code = errorObj?['code'] as String? ?? _fallbackCode(status);
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

    return AiChatException(
      code: code,
      message: message,
      statusCode: status,
      quota: quota,
      retryAfterSeconds: retryAfterHeader == null
          ? null
          : int.tryParse(retryAfterHeader),
    );
  }

  String _fallbackCode(int? status) {
    if (status == null) return 'NETWORK';
    switch (status) {
      case 401:
        return 'UNAUTHENTICATED';
      case 403:
        return 'FORBIDDEN';
      case 422:
        return 'VALIDATION_ERROR';
      case 429:
        return 'RATE_LIMITED';
      case 503:
        return 'AI_UNAVAILABLE';
      default:
        return 'UNKNOWN';
    }
  }
}

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository(ref.watch(apiClientProvider));
});
