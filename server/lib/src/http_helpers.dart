import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import 'env_loader.dart';

/// JSON response headers for the `{ success, data, meta }` envelope.
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

/// Loopback origins allowed when `ALLOWED_ORIGINS` is unset. Public hosts are not.
bool _isLoopbackOrigin(String origin) {
  final uri = Uri.tryParse(origin);
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  final host = uri.host;
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}

/// CORS for [request]: echo allowed `Origin` (`ALLOWED_ORIGINS`, else loopback; `*` opt-in).
Map<String, String> corsHeadersFor(Request request) {
  final headers = {..._staticCorsHeaders};
  final origin = request.headers['origin'];
  final allowedOriginsEnv = appEnv()['ALLOWED_ORIGINS']?.trim();

  if (allowedOriginsEnv != null && allowedOriginsEnv.isNotEmpty) {
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

  // Unset allow-list: reflect loopback only.
  if (origin != null && _isLoopbackOrigin(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Vary'] = 'Origin';
  }
  return headers;
}

/// CORS middleware; see [corsHeadersFor]. Short-circuits `OPTIONS` preflight.
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

/// Non-object JSON body. Mapped to 422 by [errorEnvelopeMiddleware].
class InvalidJsonBodyException implements Exception {
  const InvalidJsonBodyException(this.message);

  final String message;

  @override
  String toString() => 'InvalidJsonBodyException: $message';
}

/// Body larger than the handler buffer limit. Mapped to 413 by [errorEnvelopeMiddleware].
class PayloadTooLargeException implements Exception {
  const PayloadTooLargeException(this.message);

  final String message;

  @override
  String toString() => 'PayloadTooLargeException: $message';
}

extension RequestJson on Request {
  /// Decodes the body as a JSON object. Empty body → `{}`.
  Future<Map<String, dynamic>> readJson() async {
    final body = await readAsString();
    if (body.trim().isEmpty) return {};
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw InvalidJsonBodyException(
        'Request body is not valid JSON: '
        '${error.message}',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const InvalidJsonBodyException(
        'Request body must be a JSON object',
      );
    }
    return decoded;
  }
}

/// Maps unhandled errors to the `{ success, data, error }` envelope (no plain-text 500).
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
        // Log server-side; do not leak exception text to the client.
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
