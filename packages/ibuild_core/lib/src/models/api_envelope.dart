import 'json_map.dart';

/// The iBuild REST API wraps every payload in a
/// `{ success, data, meta, error }` envelope. These helpers unwrap it in one
/// place so callers (and the Dio response interceptor) don't each re-implement
/// the "is this the envelope or the raw body?" check.
abstract final class ApiEnvelope {
  /// Returns the `data` field if [body] is an envelope, otherwise [body]
  /// itself. Handles the case where an interceptor has already unwrapped it.
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

/// A transport-agnostic API error. Repositories throw this so presentation
/// code can react to a stable type without depending on the HTTP client.
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
