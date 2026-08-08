/// Request validation helpers shared by route handlers.
library;

/// Constant-time string compare. Timing must not leak OTP/bootstrap secrets.
bool constantTimeEquals(String a, String b) {
  final aUnits = a.codeUnits;
  final bUnits = b.codeUnits;
  final maxLen = aUnits.length > bUnits.length ? aUnits.length : bUnits.length;
  var diff = aUnits.length ^ bUnits.length;
  for (var i = 0; i < maxLen; i++) {
    final x = i < aUnits.length ? aUnits[i] : 0;
    final y = i < bUnits.length ? bUnits[i] : 0;
    diff |= x ^ y;
  }
  return diff == 0;
}

final RegExp _phonePattern = RegExp(r'^\+?[0-9]{9,15}$');

/// Auth/user map key: strip spaces, dashes, parentheses.
String normalizePhone(String phone) =>
    phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');

/// Optional `+` plus 9–15 digits after stripping spaces/dashes/parentheses.
bool isValidPhone(String? v) {
  if (v == null) return false;
  return _phonePattern.hasMatch(normalizePhone(v));
}

/// Uzbekistan legal-entity STIR/INN: exactly 9 digits.
bool isValidInn(String? v) {
  if (v == null) return false;
  final cleaned = v.replaceAll(RegExp(r'\s'), '');
  return RegExp(r'^\d{9}$').hasMatch(cleaned);
}

String? normalizeInn(String? v) {
  if (v == null) return null;
  final cleaned = v.replaceAll(RegExp(r'\s'), '');
  return cleaned.isEmpty ? null : cleaned;
}

/// PINFL (JShShIR): 14 digits (UZ KYC for directors / UBO).
bool isValidPinfl(String? v) {
  if (v == null) return false;
  final cleaned = v.replaceAll(RegExp(r'\s'), '');
  return RegExp(r'^\d{14}$').hasMatch(cleaned);
}

String? normalizePinfl(String? v) {
  if (v == null) return null;
  final cleaned = v.replaceAll(RegExp(r'\s'), '');
  return cleaned.isEmpty ? null : cleaned;
}

/// [v] if length ≤ [maxLen]; otherwise `null` (callers reject with 422 — no silent truncate).
String? capString(String? v, int maxLen) {
  if (v == null) return null;
  if (v.length > maxLen) return null;
  return v;
}

/// True if [v] is in [allowed] (enum-like query/body params).
bool isOneOf(String? v, Set<String> allowed) =>
    v != null && allowed.contains(v);

/// Complete HTML/XML tags (`<script>`, `<img ...>`, `</b>`, ...).
final RegExp _htmlTagPattern = RegExp(r'<[^>]*>', dotAll: true);

/// Leftover `<`/`>` after tag strip (blocks partial `<script` fragments).
final RegExp _strayAnglePattern = RegExp(r'[<>]');

/// C0/C1 controls except tab, newline, carriage return.
final RegExp _controlCharPattern = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

/// Strip HTML tags and control chars from free text before storage (stored XSS).
/// Idempotent: safe at both route and store layers. Returns `null` iff [v] is `null`.
String? sanitizeText(String? v) {
  if (v == null) return null;
  return v
      .replaceAll(_htmlTagPattern, '')
      .replaceAll(_strayAnglePattern, '')
      .replaceAll(_controlCharPattern, '')
      .trim();
}

/// [sanitizeText] on each string in a list; drops non-strings. `null` if [value] is not a list.
List<String>? sanitizeTextList(Object? value) {
  if (value is! List) return null;
  return value.whereType<String>().map((e) => sanitizeText(e)!).toList();
}
