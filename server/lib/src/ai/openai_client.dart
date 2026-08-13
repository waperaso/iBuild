import 'dart:convert';
import 'dart:io';

import '../env_loader.dart';

/// Upstream AI failure, safe to surface. Deliberately carries no upstream
/// detail: bodies, headers, URLs and the API key stay in stderr so a 502 from
/// the provider cannot leak configuration to a client.
class AiUnavailableException implements Exception {
  const AiUnavailableException([
    this.message = 'AI is temporarily unavailable. Please try again later.',
  ]);

  final String message;

  @override
  String toString() => 'AiUnavailableException: $message';
}

/// One turn of a chat completion. `role` is `user` | `assistant` (the system
/// prompt is passed separately so callers cannot override it).
class AiMessage {
  const AiMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Chat/vision completions over `dart:io` HttpClient (mirrors `SmsService`).
/// The key is read here and nowhere else, and never echoed by any route.
class OpenAiClient {
  OpenAiClient();

  /// Cheap current chat model; override per environment with `OPENAI_MODEL`.
  static const _defaultModel = 'gpt-4o-mini';
  static const _defaultBaseUrl = 'https://api.openai.com/v1';

  /// Upstream is slow under load; below ~20s the client sees spurious failures.
  static const defaultTimeout = Duration(seconds: 25);

  String? get _apiKey {
    final key = appEnv()['OPENAI_API_KEY']?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  /// `OPENAI_MODEL` or [_defaultModel]. Server-side only — never sent to clients.
  String get model {
    final configured = appEnv()['OPENAI_MODEL']?.trim();
    return (configured == null || configured.isEmpty)
        ? _defaultModel
        : configured;
  }

  String get _baseUrl {
    final configured = appEnv()['OPENAI_BASE_URL']?.trim();
    final base = (configured == null || configured.isEmpty)
        ? _defaultBaseUrl
        : configured;
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  /// False when the key is missing or `AI_ENABLED=false` — callers answer
  /// `AI_UNAVAILABLE` without consuming quota instead of attempting a call.
  bool get isConfigured {
    if ((appEnv()['AI_ENABLED'] ?? '').trim().toLowerCase() == 'false') {
      return false;
    }
    return _apiKey != null;
  }

  /// GPT-vision photo verification path (plan Part 4). Off by default; the
  /// readiness engine runs locally until this is switched on.
  bool get isVisionEnabled =>
      isConfigured &&
      (appEnv()['AI_VISION_ENABLED'] ?? '').trim().toLowerCase() == 'true';

  /// Text chat completion. Returns the assistant message content.
  /// Throws [AiUnavailableException] on any upstream or transport failure.
  Future<String> complete({
    required String systemPrompt,
    required List<AiMessage> messages,
    int maxTokens = 700,
    double temperature = 0.4,
    Duration timeout = defaultTimeout,
  }) => _postChatCompletion(
    body: {
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages.map((m) => m.toJson()),
      ],
    },
    timeout: timeout,
  );

  /// Vision completion for one image, passed as a base64 `data:` URL so the
  /// photo never has to be publicly reachable. Unused until
  /// `AI_VISION_ENABLED=true`; see [isVisionEnabled].
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userText,
    required String imageDataUrl,
    int maxTokens = 1200,
    double temperature = 0.0,
    Duration timeout = defaultTimeout,
  }) => _postChatCompletion(
    body: {
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userText},
            {
              'type': 'image_url',
              'image_url': {'url': imageDataUrl, 'detail': 'high'},
            },
          ],
        },
      ],
    },
    timeout: timeout,
  );

  Future<String> _postChatCompletion({
    required Map<String, dynamic> body,
    required Duration timeout,
  }) async {
    final key = _apiKey;
    if (key == null) {
      stderr.writeln('[OpenAiClient] OPENAI_API_KEY is not set');
      throw const AiUnavailableException();
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client
          .postUrl(Uri.parse('$_baseUrl/chat/completions'))
          .timeout(timeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(timeout);
      final raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode >= 400) {
        // Body can echo the request (and hint at the key); stderr only.
        stderr.writeln(
          '[OpenAiClient] Upstream ${response.statusCode}: '
          '${_clip(raw, 500)}',
        );
        throw const AiUnavailableException();
      }
      final content = _contentOf(raw);
      if (content == null || content.trim().isEmpty) {
        stderr.writeln('[OpenAiClient] Upstream returned no message content');
        throw const AiUnavailableException();
      }
      return content.trim();
    } on AiUnavailableException {
      rethrow;
    } catch (error) {
      // Transport/timeout/parse: the message can contain the URL and headers.
      stderr.writeln('[OpenAiClient] Request failed: $error');
      throw const AiUnavailableException();
    } finally {
      client.close(force: true);
    }
  }

  String? _contentOf(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final message = (choices.first as Map)['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }

  String _clip(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…';
}
