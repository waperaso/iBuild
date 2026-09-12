import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../env_loader.dart';
import '../static_files.dart';

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

/// Local image file bytes for [OpenAiClient.completeWithImageFiles].
class OpenAiImageFile {
  const OpenAiImageFile({
    required this.bytes,
    required this.filename,
  });

  final List<int> bytes;
  final String filename;

  String toDataUrl() {
    var mime = contentTypeFor(filename);
    if (!mime.startsWith('image/')) mime = 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}

/// Chat/vision completions over `dart:io` HttpClient (mirrors `SmsService`).
/// The key is read here and nowhere else, and never echoed by any route.
class OpenAiClient {
  OpenAiClient({
    String? apiKey,
    String? baseUrl,
    String? chatModel,
    String? visionModel,
  }) : _apiKeyOverride = apiKey,
       _baseUrlOverride = baseUrl,
       _chatModelOverride = chatModel,
       _visionModelOverride = visionModel;

  /// Cheap current chat model; override per environment with `OPENAI_MODEL`.
  static const _defaultModel = 'gpt-4o-mini';

  /// A vs B construction photos; override with `OPENAI_VISION_MODEL`.
  static const _defaultVisionModel = 'gpt-4o';
  static const _defaultBaseUrl = 'https://api.openai.com/v1';

  /// Upstream is slow under load; below ~20s the client sees spurious failures.
  static const defaultTimeout = Duration(seconds: 25);

  /// Two high-detail images routinely exceed the chat budget.
  static const visionTimeout = Duration(seconds: 60);

  final String? _apiKeyOverride;
  final String? _baseUrlOverride;
  final String? _chatModelOverride;
  final String? _visionModelOverride;

  String? get _apiKey {
    final override = _apiKeyOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    final key = appEnv()['OPENAI_API_KEY']?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  /// `OPENAI_MODEL` or [_defaultModel]. Server-side only — never sent to clients.
  String get model {
    final override = _chatModelOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    final configured = appEnv()['OPENAI_MODEL']?.trim();
    return (configured == null || configured.isEmpty)
        ? _defaultModel
        : configured;
  }

  /// `OPENAI_VISION_MODEL` or [_defaultVisionModel]. Never sent to clients.
  String get visionModel {
    final override = _visionModelOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    final configured = appEnv()['OPENAI_VISION_MODEL']?.trim();
    return (configured == null || configured.isEmpty)
        ? _defaultVisionModel
        : configured;
  }

  String get _baseUrl {
    final override = _baseUrlOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override.endsWith('/')
          ? override.substring(0, override.length - 1)
          : override;
    }
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

  /// GPT-vision photo verification path (plan Part 4). On by default (see
  /// `.env.example`); a missing [OPENAI_API_KEY] still makes this a no-op —
  /// the readiness engine's own local result always ships regardless.
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

  /// Vision completion for two (or more) images as `data:` URLs. JSON mode is
  /// on so the construction-verify schema can be parsed. Image bytes are sent
  /// upstream only — they are never written to logs.
  Future<String> completeWithImages({
    required String systemPrompt,
    required String userText,
    required List<String> imageDataUrls,
    int maxTokens = 1200,
    double temperature = 0.0,
    Duration timeout = visionTimeout,
  }) {
    if (imageDataUrls.length < 2) {
      throw const AiUnavailableException();
    }
    return _postChatCompletion(
      body: {
        'model': visionModel,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': userText},
              for (final url in imageDataUrls)
                {
                  'type': 'image_url',
                  'image_url': {'url': url, 'detail': 'high'},
                },
            ],
          },
        ],
      },
      timeout: timeout,
    );
  }

  /// Upload bytes to OpenAI Files API (`purpose=user_data`) and return `id`.
  /// Used so construction photos are treated as files, not only inline data
  /// URLs. Never logs bytes or the API key.
  Future<String> uploadFile({
    required List<int> bytes,
    required String filename,
    String purpose = 'user_data',
    Duration timeout = visionTimeout,
  }) async {
    final key = _apiKey;
    if (key == null) {
      stderr.writeln('[OpenAiClient] OPENAI_API_KEY is not set');
      throw const AiUnavailableException();
    }
    final safeName = filename.trim().isEmpty ? 'photo.jpg' : filename.trim();
    final boundary = 'ibuild-${DateTime.now().microsecondsSinceEpoch}';
    final body = BytesBuilder();
    void writeAscii(String s) => body.add(utf8.encode(s));

    writeAscii('--$boundary\r\n');
    writeAscii(
      'Content-Disposition: form-data; name="purpose"\r\n\r\n$purpose\r\n',
    );
    writeAscii('--$boundary\r\n');
    writeAscii(
      'Content-Disposition: form-data; name="file"; '
      'filename="$safeName"\r\n'
      'Content-Type: application/octet-stream\r\n\r\n',
    );
    body.add(bytes);
    writeAscii('\r\n--$boundary--\r\n');

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client
          .postUrl(Uri.parse('$_baseUrl/files'))
          .timeout(timeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      request.add(body.takeBytes());
      final response = await request.close().timeout(timeout);
      final raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode >= 400) {
        stderr.writeln(
          '[OpenAiClient] Files upload ${response.statusCode}: '
          '${_clip(raw, 500)}',
        );
        throw const AiUnavailableException();
      }
      final decoded = jsonDecode(raw);
      final id = decoded is Map ? decoded['id'] as String? : null;
      if (id == null || id.isEmpty) {
        stderr.writeln('[OpenAiClient] Files upload returned no id');
        throw const AiUnavailableException();
      }
      return id;
    } on AiUnavailableException {
      rethrow;
    } catch (error) {
      stderr.writeln('[OpenAiClient] Files upload failed: $error');
      throw const AiUnavailableException();
    } finally {
      client.close(force: true);
    }
  }

  /// Best-effort cleanup after a vision call (ignore failures).
  Future<void> deleteFile(String fileId) async {
    final key = _apiKey;
    if (key == null || fileId.trim().isEmpty) return;
    final client = HttpClient()..connectionTimeout = defaultTimeout;
    try {
      final request = await client
          .deleteUrl(Uri.parse('$_baseUrl/files/${fileId.trim()}'))
          .timeout(defaultTimeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
      final response = await request.close().timeout(defaultTimeout);
      await response.drain<void>();
    } catch (error) {
      stderr.writeln('[OpenAiClient] Files delete failed: $error');
    } finally {
      client.close(force: true);
    }
  }

  /// Construction-verify path: upload A/B as Files, then run vision.
  /// Prefer Responses API with `input_image.file_id`; fall back to chat
  /// completions + `data:` URLs if the file-id path is unavailable.
  Future<String> completeWithImageFiles({
    required String systemPrompt,
    required String userText,
    required List<OpenAiImageFile> images,
    // The construction-verify envelope now carries a structured report
    // (overallConclusion + per-photo findings + a risks table +
    // recommendations), which routinely runs longer than the old
    // markdown-only summary — keep headroom so it is never truncated
    // mid-JSON.
    int maxTokens = 2000,
    double temperature = 0.0,
    Duration timeout = visionTimeout,
  }) async {
    if (images.length < 2) {
      throw const AiUnavailableException();
    }

    final uploadedIds = <String>[];
    try {
      for (final image in images) {
        uploadedIds.add(
          await uploadFile(
            bytes: image.bytes,
            filename: image.filename,
            timeout: timeout,
          ),
        );
      }

      try {
        return await _postResponsesVision(
          systemPrompt: systemPrompt,
          userText: userText,
          fileIds: uploadedIds,
          maxTokens: maxTokens,
          temperature: temperature,
          timeout: timeout,
        );
      } on AiUnavailableException {
        // Older gateways / models may reject file_id on images — keep verify
        // working with the proven chat + data-URL path.
        stderr.writeln(
          '[OpenAiClient] Responses file_id path failed; '
          'falling back to chat data URLs',
        );
        return completeWithImages(
          systemPrompt: systemPrompt,
          userText: userText,
          imageDataUrls: [
            for (final image in images) image.toDataUrl(),
          ],
          maxTokens: maxTokens,
          temperature: temperature,
          timeout: timeout,
        );
      }
    } finally {
      for (final id in uploadedIds) {
        await deleteFile(id);
      }
    }
  }

  Future<String> _postResponsesVision({
    required String systemPrompt,
    required String userText,
    required List<String> fileIds,
    required int maxTokens,
    required double temperature,
    required Duration timeout,
  }) async {
    final key = _apiKey;
    if (key == null) {
      stderr.writeln('[OpenAiClient] OPENAI_API_KEY is not set');
      throw const AiUnavailableException();
    }
    final body = {
      'model': visionModel,
      'max_output_tokens': maxTokens,
      'temperature': temperature,
      'instructions': systemPrompt,
      'text': {
        'format': {'type': 'json_object'},
      },
      'input': [
        {
          'role': 'user',
          'content': [
            // Responses `json_object` requires the word "json" in `input`,
            // not only in `instructions`.
            {
              'type': 'input_text',
              'text': userText.toLowerCase().contains('json')
                  ? userText
                  : 'Respond with JSON.\n$userText',
            },
            for (final id in fileIds)
              {
                'type': 'input_image',
                'file_id': id,
                'detail': 'high',
              },
          ],
        },
      ],
    };
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client
          .postUrl(Uri.parse('$_baseUrl/responses'))
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
        stderr.writeln(
          '[OpenAiClient] Responses ${response.statusCode}: '
          '${_clip(raw, 500)}',
        );
        throw const AiUnavailableException();
      }
      final content = _responsesText(raw);
      if (content == null || content.trim().isEmpty) {
        stderr.writeln('[OpenAiClient] Responses returned no text');
        throw const AiUnavailableException();
      }
      return content.trim();
    } on AiUnavailableException {
      rethrow;
    } catch (error) {
      stderr.writeln('[OpenAiClient] Responses request failed: $error');
      throw const AiUnavailableException();
    } finally {
      client.close(force: true);
    }
  }

  String? _responsesText(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final direct = decoded['output_text'];
    if (direct is String && direct.trim().isNotEmpty) return direct;
    final output = decoded['output'];
    if (output is! List) return null;
    final buffer = StringBuffer();
    for (final item in output) {
      if (item is! Map) continue;
      final content = item['content'];
      if (content is! List) continue;
      for (final part in content) {
        if (part is! Map) continue;
        final text = part['text'];
        if (text is String) buffer.write(text);
      }
    }
    final joined = buffer.toString();
    return joined.isEmpty ? null : joined;
  }

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
