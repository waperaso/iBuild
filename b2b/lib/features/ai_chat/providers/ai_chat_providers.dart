import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_chat_models.dart';
import '../data/ai_chat_repository.dart';

/// One rendered chat bubble. Kept separate from [AiChatMessage] (the wire
/// model) so the UI layer never has to reach into request DTOs.
class AiChatTurn {
  const AiChatTurn({required this.role, required this.content});

  final String role;
  final String content;

  bool get isUser => role == 'user';
}

/// What the chat surface should show instead of the input row.
enum AiChatUiStatus { ready, quotaExhausted, unavailable, forbidden }

/// Practical cap on how many turns are sent over the wire per request —
/// the server caps history server-side too, but the client shouldn't let a
/// long-running session's payload grow unbounded. Keeps the last N turns
/// (always ending on the just-added user message).
const _kMaxWireTurns = 24;

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.sending = false,
    this.quota,
    this.status = AiChatUiStatus.ready,
    this.resetAt,
    this.transientErrorCode,
  });

  final List<AiChatTurn> messages;
  final bool sending;
  final AiQuota? quota;
  final AiChatUiStatus status;
  final DateTime? resetAt;

  /// One-shot error code for a failure that isn't quota/availability related
  /// (network blip, validation, demo mode) — the sheet shows a SnackBar for
  /// it once, then calls [AiChatController.clearTransientError].
  final String? transientErrorCode;

  AiChatState copyWith({
    List<AiChatTurn>? messages,
    bool? sending,
    AiQuota? quota,
    AiChatUiStatus? status,
    DateTime? resetAt,
    Object? transientErrorCode = _unset,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      quota: quota ?? this.quota,
      status: status ?? this.status,
      resetAt: resetAt ?? this.resetAt,
      transientErrorCode: transientErrorCode == _unset
          ? this.transientErrorCode
          : transientErrorCode as String?,
    );
  }
}

const _unset = Object();

/// Chat transcript + send state + quota, backed by [AiChatRepository].
class AiChatController extends Notifier<AiChatState> {
  @override
  AiChatState build() {
    Future.microtask(_loadQuota);
    return const AiChatState();
  }

  Future<void> _loadQuota() async {
    try {
      final quota = await ref.read(aiChatRepositoryProvider).fetchChatQuota();
      state = state.copyWith(
        quota: quota,
        status: quota.isExhausted
            ? AiChatUiStatus.quotaExhausted
            : AiChatUiStatus.ready,
        resetAt: quota.resetAt,
      );
    } catch (_) {
      // Informational only — a real send attempt will surface any real error.
    }
  }

  Future<void> refreshQuota() => _loadQuota();

  Future<void> sendMessage(String text, String userLanguage) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    if (state.status != AiChatUiStatus.ready) return;

    final history = [
      ...state.messages,
      AiChatTurn(role: 'user', content: trimmed),
    ];
    state = state.copyWith(messages: history, sending: true);

    final wireHistory = history.length > _kMaxWireTurns
        ? history.sublist(history.length - _kMaxWireTurns)
        : history;

    try {
      final reply = await ref
          .read(aiChatRepositoryProvider)
          .sendChat(
            messages: wireHistory
                .map((m) => AiChatMessage(role: m.role, content: m.content))
                .toList(),
            userLanguage: userLanguage,
          );
      state = state.copyWith(
        messages: [
          ...history,
          AiChatTurn(role: 'assistant', content: reply.reply),
        ],
        sending: false,
        quota: reply.quota,
        resetAt: reply.quota.resetAt,
        status: reply.quota.isExhausted
            ? AiChatUiStatus.quotaExhausted
            : AiChatUiStatus.ready,
      );
    } on AiChatException catch (error) {
      state = state.copyWith(
        messages: history,
        sending: false,
        status: switch (error.code) {
          'RATE_LIMITED' => AiChatUiStatus.quotaExhausted,
          'AI_UNAVAILABLE' => AiChatUiStatus.unavailable,
          'UNAUTHENTICATED' || 'FORBIDDEN' => AiChatUiStatus.forbidden,
          _ => state.status,
        },
        quota: error.quota,
        resetAt: error.quota?.resetAt,
        transientErrorCode: error.isRateLimited || error.isUnavailable
            ? null
            : error.code,
      );
    }
  }

  void clearTransientError() => state = state.copyWith(transientErrorCode: null);

  void reset() => state = const AiChatState();
}

final aiChatProvider = NotifierProvider<AiChatController, AiChatState>(
  AiChatController.new,
);
