/// A decoded JSON object. Every model in the iBuild apps is constructed from
/// one of these (the REST API always returns JSON objects for entities).
typedef JsonMap = Map<String, dynamic>;

/// Small, null-safe coercion helpers for reading loosely-typed JSON into
/// strongly-typed model fields. The iBuild API occasionally returns numbers
/// as strings (and vice versa), so these normalise on the way in instead of
/// scattering `as`/`?? ` casts across every model.
extension JsonReaders on JsonMap {
  String? optString(String key) {
    final value = this[key];
    if (value == null) return null;
    return value.toString();
  }

  String stringOr(String key, [String fallback = '']) =>
      optString(key) ?? fallback;

  bool boolOr(String key, [bool fallback = false]) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return fallback;
  }

  int? optInt(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int intOr(String key, [int fallback = 0]) => optInt(key) ?? fallback;

  double? optDouble(String key) {
    final value = this[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double doubleOr(String key, [double fallback = 0]) =>
      optDouble(key) ?? fallback;
}
