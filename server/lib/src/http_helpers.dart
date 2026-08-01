import 'dart:convert';
import 'dart:io';

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

/// Thrown by [RequestJson.readJson] when the request body is not a JSON
/// object. Converted to a 422 envelope by [errorEnvelopeMiddleware] instead of
/// escaping as an unhandled error (which shelf renders as a plain-text 500 the
/// clients' envelope interceptor cannot parse).
class InvalidJsonBodyException implements Exception {
  const InvalidJsonBodyException(this.message);

  final String message;

  @override
  String toString() => 'InvalidJsonBodyException: $message';
}

/// Thrown when a request body exceeds the limit a handler is willing to buffer
/// in memory. Rendered as a 413 envelope by [errorEnvelopeMiddleware].
class PayloadTooLargeException implements Exception {
  const PayloadTooLargeException(this.message);

  final String message;

  @override
  String toString() => 'PayloadTooLargeException: $message';
}

extension RequestJson on Request {
  /// Decodes the body as a JSON object. An empty body is treated as `{}` so
  /// handlers can rely on per-field validation for their own error messages.
  Future<Map<String, dynamic>> readJson() async {
    final body = await readAsString();
    if (body.trim().isEmpty) return {};
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw InvalidJsonBodyException('Request body is not valid JSON: '
          '${error.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const InvalidJsonBodyException(
        'Request body must be a JSON object',
      );
    }
    return decoded;
  }
}

/// Guarantees every response — including ones produced by an unhandled
/// exception — uses the `{ success, data, error }` envelope, so the Flutter
/// clients never receive shelf's plain-text `Internal Server Error` body that
/// their Dio interceptor cannot unwrap.
Middleware errorEnvelopeMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      try {
        return await inner(request);
      } on InvalidJsonBodyException catch (error) {
        return jsonError('VALIDATION_ERROR', error.message, status: 422);
      } on PayloadTooLargeException catch (error) {
        return jsonError('PAYLOAD_TOO_LARGE', error.message, status: 413);
      } catch (error, stack) {
        // Log server-side; never leak the exception text to the caller.
        stderr.writeln(
          '[error] ${request.method} ${request.requestedUri.path}: '
          '$error\n$stack',
        );
        return jsonError(
          'INTERNAL_ERROR',
          'Something went wrong. Please try again.',
          status: 500,
        );
      }
    };
  };
}
