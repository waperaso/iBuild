/// Small, dependency-free request validation helpers shared by the route
/// handlers in `lib/src/app.dart`.
library;

/// Compares [a] and [b] in constant time relative to their contents, so an
/// attacker cannot use response-timing to recover a secret (OTP code,
/// bootstrap secret) character-by-character. The comparison still runs over
/// the longer of the two lengths and folds a length mismatch into the result.
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

/// Canonical phone form used as the auth/user map key: strip spaces,
/// dashes and parentheses so `+998 90 330 64 16` and `+998903306416` match.
String normalizePhone(String phone) =>
    phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');

/// Loosely validates a phone number: strips spaces/dashes/parentheses (the
/// seed data and UI both format numbers as `+998 90 123 45 67`), then
/// requires an optional leading `+` followed by 9-15 digits — covers
/// `+998XXXXXXXXX`-style numbers and similarly-shaped ones generally.
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

/// PINFL (JShShIR): 14 digits — required for directors / UBO under UZ KYC.
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

/// Returns [v] unchanged if it's at most [maxLen] characters long, or `null`
/// if it's missing/too long. Callers treat a `null` result as "reject the
/// request with 422" rather than silently truncating.
String? capString(String? v, int maxLen) {
  if (v == null) return null;
  if (v.length > maxLen) return null;
  return v;
}

/// Whether [v] is present and a member of [allowed] — used for enum-like
/// query/body params (`status`, `mode`, `district`, ...).
bool isOneOf(String? v, Set<String> allowed) =>
    v != null && allowed.contains(v);

/// Matches complete HTML/XML tags (`<script>`, `<img ...>`, `</b>`, ...).
final RegExp _htmlTagPattern = RegExp(r'<[^>]*>', dotAll: true);

/// Any leftover angle bracket after tags are stripped — removed so an
/// unterminated `<script` fragment can't survive as a partial injection.
final RegExp _strayAnglePattern = RegExp(r'[<>]');

/// C0/C1 control characters except tab (\t), newline (\n) and carriage
/// return (\r), which are legitimate in multi-line free text.
final RegExp _controlCharPattern = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

/// Sanitizes user-supplied free text before it is stored, as a defense
/// against stored XSS (developer descriptions, review/lead bodies, rental
/// listing text, project descriptions, etc.). It strips HTML/script tags and
/// control characters, then trims surrounding whitespace.
///
/// This is deliberately **idempotent** — running it again on already-cleaned
/// text yields the same result — so it can be applied defensively at both the
/// route boundary and the store layer without corrupting content on edit
/// round-trips (unlike HTML-entity escaping, which would double-encode).
///
/// Returns `null` iff [v] is `null`; callers decide whether an empty/`null`
/// result should be rejected.
String? sanitizeText(String? v) {
  if (v == null) return null;
  return v
      .replaceAll(_htmlTagPattern, '')
      .replaceAll(_strayAnglePattern, '')
      .replaceAll(_controlCharPattern, '')
      .trim();
}

/// Applies [sanitizeText] to each string in [value] when it is a list,
/// dropping non-string entries. Returns `null` when [value] is not a list, so
/// callers can fall back to their own default (e.g. an empty list).
List<String>? sanitizeTextList(Object? value) {
  if (value is! List) return null;
  return value.whereType<String>().map((e) => sanitizeText(e)!).toList();
}
