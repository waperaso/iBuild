import 'json_map.dart';

/// Unwrap helpers for the API `{ success, data, meta, error }` envelope.
abstract final class ApiEnvelope {
  /// `data` if [body] is an envelope; otherwise [body] (already unwrapped).
  static dynamic unwrap(dynamic body) {
    if (body is JsonMap && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  /// Unwraps [body] and casts the result to a [JsonMap], or `null` if it is
  /// not an object.
  static JsonMap? asObject(dynamic body) {
    final data = unwrap(body);
    return data is JsonMap ? data : null;
  }

  /// Unwraps [body] and casts the result to a list of [JsonMap]s. Returns an
  /// empty list when the payload is absent or not a list.
  static List<JsonMap> asList(dynamic body) {
    final data = unwrap(body);
    if (data is List) {
      return data.whereType<JsonMap>().toList(growable: false);
    }
    return const [];
  }
}

/// API error thrown by repositories; independent of the HTTP client.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  /// Whether the failure was an auth rejection (expired/invalid session).
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() =>
      'ApiException(${statusCode ?? '-'}${code != null ? ' $code' : ''}): '
      '$message';
}
