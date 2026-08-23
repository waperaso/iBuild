import 'dart:convert';

const kConstructionVerifyVerdicts = {'confirm', 'reject', 'needs_review'};

/// Parses a vendor JSON object against `v0.schema.json`. Returns null on any
/// mismatch so the job can fall back to `needs_review` without guessing.
Map<String, dynamic>? parseConstructionVerifyJson(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    text = text
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final map = Map<String, dynamic>.from(decoded);
  final verdict = map['verdict'];
  if (verdict is! String || !kConstructionVerifyVerdicts.contains(verdict)) {
    return null;
  }
  final confidence = map['confidence'];
  if (confidence is! num || confidence < 0 || confidence > 1) return null;
  final summary = map['summary'];
  if (summary is! String || summary.trim().isEmpty) return null;
  if (map.containsKey('sameViewpoint') &&
      map['sameViewpoint'] != null &&
      map['sameViewpoint'] is! bool) {
    return null;
  }
  if (map.containsKey('progressDelta') &&
      map['progressDelta'] != null &&
      map['progressDelta'] is! num) {
    return null;
  }
  if (map.containsKey('flags') && map['flags'] != null) {
    final flags = map['flags'];
    if (flags is! List || flags.any((e) => e is! String)) return null;
  }
  return map;
}
