/// Wire models for the b2b AI assistant chat (`POST /v1/ai/b2b/chat`,
/// `GET /v1/ai/b2b/chat/quota`) — shape mirrors the b2c `ai_models.dart`
/// contract exactly, just against the `/ai/b2b/*` routes (admin-only, see
/// `ai_chat_repository.dart`).
library;

/// One turn in a chat transcript, `role` is `user` or `assistant`.
class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// `{used, limit, remaining, resetAt}`, optionally `available` (only present
/// on `GET /ai/b2b/chat/quota`).
class AiQuota {
  const AiQuota({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.resetAt,
    this.available,
  });

  final int used;
  final int limit;
  final int remaining;
  final DateTime resetAt;
  final bool? available;

  bool get isExhausted => remaining <= 0;

  factory AiQuota.fromJson(Map<String, dynamic> json) => AiQuota(
    used: (json['used'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    resetAt:
        DateTime.tryParse(json['resetAt'] as String? ?? '') ??
        DateTime.now().toUtc(),
    available: json['available'] as bool?,
  );
}

/// `POST /v1/ai/b2b/chat` response: `{reply, quota}`.
class AiChatReply {
  const AiChatReply({required this.reply, required this.quota});

  final String reply;
  final AiQuota quota;

  factory AiChatReply.fromJson(Map<String, dynamic> json) => AiChatReply(
    reply: json['reply'] as String? ?? '',
    quota: AiQuota.fromJson(json['quota'] as Map<String, dynamic>? ?? const {}),
  );
}

/// Normalized error for every AI chat call — maps the `{success:false,
/// error: {code, message, data}}` envelope plus Dio-level failures (timeout,
/// offline, demo read-only guard) into one shape the UI can switch on
/// without ever showing a raw error string. Mirrors b2c's `AiException`.
class AiChatException implements Exception {
  const AiChatException({
    required this.code,
    required this.message,
    this.statusCode,
    this.quota,
    this.retryAfterSeconds,
  });

  /// Server error code (`RATE_LIMITED`, `AI_UNAVAILABLE`, `VALIDATION_ERROR`,
  /// `UNAUTHENTICATED`, `FORBIDDEN`, ...) or a client-side one (`NETWORK`,
  /// `DEMO_READ_ONLY`, `UNKNOWN`).
  final String code;
  final String message;
  final int? statusCode;

  /// Present on `RATE_LIMITED` — the 429 payload carries a full quota
  /// snapshot (`used`, `limit`, `remaining`, `resetAt`).
  final AiQuota? quota;
  final int? retryAfterSeconds;

  bool get isRateLimited => code == 'RATE_LIMITED';
  bool get isUnavailable => code == 'AI_UNAVAILABLE';
  bool get isDemoReadOnly => code == 'DEMO_READ_ONLY';
  bool get isForbidden => code == 'FORBIDDEN' || code == 'UNAUTHENTICATED';

  @override
  String toString() => 'AiChatException($code: $message)';
}
