import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'env_loader.dart';

/// `{ success, data, meta }` — the envelope documented in
/// `IBUILD_APP_PLAN.md` §8 and unwrapped by the Flutter `apiClientProvider`
/// interceptor.
const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? data, {Map<String, dynamic>? meta, int status = 200}) {
  final body = <String, dynamic>{'success': true, 'data': data};
  if (meta != null) body['meta'] = meta;
  return Response(status, body: jsonEncode(body), headers: _jsonHeaders);
}

Response jsonError(
  String code,
  String message, {
  int status = 400,
  Map<String, String>? extraHeaders,
  Object? data,
}) {
  final error = <String, dynamic>{'code': code, 'message': message};
  if (data != null) error['data'] = data;
  return Response(
    status,
    body: jsonEncode({'success': false, 'data': null, 'error': error}),
    headers: extraHeaders == null
        ? _jsonHeaders
        : {..._jsonHeaders, ...extraHeaders},
  );
}

const _staticCorsHeaders = {
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, Accept',
};

/// Loopback hosts that stay allowed for zero-config local development even
/// when `ALLOWED_ORIGINS` is unset — never a public host, so production is
/// locked down by default rather than falling back to a wildcard.
bool _isLoopbackOrigin(String origin) {
  final uri = Uri.tryParse(origin);
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  final host = uri.host;
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}

/// Builds the CORS headers for a given [request].
///
/// The request's `Origin` is echoed back only when it is explicitly allowed;
/// otherwise `Access-Control-Allow-Origin` is omitted entirely so the browser
/// blocks the cross-origin response. An origin is allowed when either:
///
/// * it appears in the comma-separated `ALLOWED_ORIGINS` allow-list
///   (e.g. `http://localhost:8099,https://app.example.uz`), or
/// * `ALLOWED_ORIGINS` is unset **and** the origin is a loopback address
///   (`localhost`/`127.0.0.1`/`::1`) — preserving zero-config local dev.
///
/// Unlike the previous implementation this never emits a wildcard `*` by
/// default, so an unconfigured production deployment does not silently expose
/// its API to every origin. Operators who genuinely want the old permissive
/// behavior can opt in explicitly with `ALLOWED_ORIGINS=*`.
Map<String, String> corsHeadersFor(Request request) {
  final headers = {..._staticCorsHeaders};
  final origin = request.headers['origin'];
  final allowedOriginsEnv = appEnv()['ALLOWED_ORIGINS']?.trim();

  if (allowedOriginsEnv != null && allowedOriginsEnv.isNotEmpty) {
    // Explicit operator opt-in to the legacy wildcard behavior.
    if (allowedOriginsEnv == '*') {
      headers['Access-Control-Allow-Origin'] = '*';
      return headers;
    }
    final allowedOrigins = allowedOriginsEnv
        .split(',')
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toSet();
    if (origin != null && allowedOrigins.contains(origin)) {
      headers['Access-Control-Allow-Origin'] = origin;
      headers['Vary'] = 'Origin';
    }
    return headers;
  }

  // No allow-list configured: only reflect loopback origins so local dev keeps
  // working, while remote origins stay blocked until ALLOWED_ORIGINS is set.
  if (origin != null && _isLoopbackOrigin(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Vary'] = 'Origin';
  }
  return headers;
}

/// Adds CORS headers (allow-listed via `ALLOWED_ORIGINS`, with loopback
/// origins reflected for local dev — see [corsHeadersFor]) so the Flutter web
/// build (served from a different port) can call this API, and short-circuits
/// `OPTIONS` preflight.
Middleware corsHeaders() {
  return (Handler innerHandler) {
    return (Request request) async {
      final headers = corsHeadersFor(request);
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await innerHandler(request);
      return response.change(headers: {...response.headers, ...headers});
    };
  };
}

extension RequestJson on Request {
  Future<Map<String, dynamic>> readJson() async {
    final body = await readAsString();
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
