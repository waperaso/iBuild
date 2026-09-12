// Route-level tests for `GET /v1/platform/ai/status` — the wiring check
// added after the 2026-09-12 incident where the A→B construction-verify
// pipeline silently never called OpenAI for weeks (missing OPENAI_API_KEY/
// AI_VISION_ENABLED *and* an unmounted construction-verify prompt, with
// /v1/health unaffected either way). See server/deploy/healthcheck-ai.sh.
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import '../lib/src/ai/ai_routes.dart';
import '../lib/src/ai/openai_client.dart';
import '../lib/src/app.dart';
import '../lib/src/auth_context.dart';
import '../lib/src/env_loader.dart';
import '../lib/src/store.dart';
import 'test_fixtures.dart';

Future<Map<String, dynamic>> _decode(Response response) async {
  final body = await response.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

Request _get(String path, {String? token}) => Request(
  'GET',
  Uri.parse('http://localhost$path'),
  headers: {if (token != null) 'authorization': 'Bearer $token'},
);

Handler _aiOnlyHandler(Store store, OpenAiClient client) {
  final router = Router();
  mountAiRoutes(router, store, openAiClient: client);
  return Pipeline().addMiddleware(authMiddleware(store)).addHandler(router.call);
}

void main() {
  late Store store;

  setUp(() {
    store = createTestStore();
  });

  tearDown(() => store.dispose());

  test('401 without auth', () async {
    final handler = _aiOnlyHandler(store, OpenAiClient());
    final response = await handler(_get('/v1/platform/ai/status'));
    expect(response.statusCode, 401);
    expect((await _decode(response))['error']['code'], 'UNAUTHENTICATED');
  });

  test('403 for a residence admin (system-admin only — leaks infra shape)',
      () async {
    final handler = _aiOnlyHandler(store, OpenAiClient());
    final demo = store.createDemoSession(profile: 'b2b_residence');
    final response = await handler(
      _get('/v1/platform/ai/status', token: demo.accessToken),
    );
    expect(response.statusCode, 403);
    expect((await _decode(response))['error']['code'], 'FORBIDDEN');
  });

  test('reports not-ready when OPENAI_API_KEY is unset', () async {
    // Force a clean slate via env overrides rather than relying on the
    // ambient server/.env: a developer's own checkout may well have a real
    // key + CONSTRUCTION_VERIFY_PROMPT_FILE set for manual local testing
    // (exactly the setup used to verify this incident's fix), which would
    // otherwise make this assertion flaky depending on who runs the suite.
    setAppEnvTestOverrides({
      'OPENAI_API_KEY': '',
      'AI_VISION_ENABLED': 'false',
      'CONSTRUCTION_VERIFY_PROMPT_FILE': '',
    });
    addTearDown(() => setAppEnvTestOverrides(null));

    final handler = _aiOnlyHandler(store, OpenAiClient());
    final demo = store.createDemoSession(profile: 'b2b_platform');
    final response = await handler(
      _get('/v1/platform/ai/status', token: demo.accessToken),
    );
    expect(response.statusCode, 200);
    final json = (await _decode(response))['data'] as Map;
    expect(json['chatConfigured'], isFalse);
    expect(json['visionEnabled'], isFalse);
    expect(json['constructionVerifyReady'], isFalse);
    // Never leaks the key itself, only booleans/model names/hash.
    expect(json.containsKey('OPENAI_API_KEY'), isFalse);
    expect(jsonEncode(json).contains('sk-'), isFalse);
  });

  test('constructionVerifyReady requires BOTH visionEnabled and a shipped '
      'prompt, never either alone', () async {
    // Vision "on" via a network-free fake client, but force the prompt gate
    // back to the committed placeholder regardless of any local override
    // file, so this test isolates exactly the interaction the route exists
    // to catch: one switch on is not enough.
    setAppEnvTestOverrides({'CONSTRUCTION_VERIFY_PROMPT_FILE': ''});
    addTearDown(() => setAppEnvTestOverrides(null));

    final configuredButUnshipped = _FakeConfiguredClient();
    final handler = _aiOnlyHandler(store, configuredButUnshipped);
    final demo = store.createDemoSession(profile: 'b2b_platform');
    final response = await handler(
      _get('/v1/platform/ai/status', token: demo.accessToken),
    );
    final json = (await _decode(response))['data'] as Map;
    expect(json['visionEnabled'], isTrue);
    // The committed prompt pack is still the PROMPT_NOT_SHIPPED placeholder
    // in this checkout, so readiness must stay false even with vision "on".
    expect(json['constructionVerifyPromptShipped'], isFalse);
    expect(json['constructionVerifyReady'], isFalse);
  });
}

/// Reports a configured, vision-enabled client without any network access —
/// isolates the assertion above to the prompt-shipped half of the gate.
class _FakeConfiguredClient extends OpenAiClient {
  @override
  bool get isConfigured => true;

  @override
  bool get isVisionEnabled => true;
}
