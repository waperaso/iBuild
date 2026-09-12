import 'dart:convert';

const kConstructionVerifyVerdicts = {'confirm', 'reject', 'needs_review'};
const kConstructionVerifyRiskLevels = {'low', 'medium', 'high'};
const kConstructionVerifyPhotoRoles = {'a', 'b'};

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
  if (map.containsKey('overallConclusion') &&
      map['overallConclusion'] != null &&
      map['overallConclusion'] is! String) {
    return null;
  }
  if (map.containsKey('recommendations') && map['recommendations'] != null) {
    final recs = map['recommendations'];
    if (recs is! List || recs.any((e) => e is! String)) return null;
  }
  final photoFindings = _parsePhotoFindings(map['photoFindings']);
  if (photoFindings == _invalid) return null;
  if (photoFindings != null) map['photoFindings'] = photoFindings;

  final risks = _parseRisks(map['risks']);
  if (risks == _invalid) return null;
  if (risks != null) map['risks'] = risks;

  return map;
}

/// Sentinel distinguishing "field absent/null" from "field present but
/// malformed" without a second return value.
const _invalid = Object();

/// Validates `photoFindings`; drops entries that do not conform instead of
/// invalidating the whole response over one bad item — the structured
/// breakdown is a UI upgrade, not something worth discarding an otherwise
/// valid verdict for.
Object? _parsePhotoFindings(Object? value) {
  if (value == null) return null;
  if (value is! List) return _invalid;
  final out = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is! Map) continue;
    final role = item['role'];
    final stage = item['stage'];
    final description = item['description'];
    if (role is! String ||
        !kConstructionVerifyPhotoRoles.contains(role) ||
        stage is! String ||
        stage.trim().isEmpty ||
        description is! String ||
        description.trim().isEmpty) {
      continue;
    }
    out.add({'role': role, 'stage': stage, 'description': description});
  }
  return out;
}

/// Validates `risks`; same drop-bad-items policy as [_parsePhotoFindings].
Object? _parseRisks(Object? value) {
  if (value == null) return null;
  if (value is! List) return _invalid;
  final out = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is! Map) continue;
    final description = item['description'];
    final level = item['level'];
    final recommendation = item['recommendation'];
    if (description is! String ||
        description.trim().isEmpty ||
        level is! String ||
        !kConstructionVerifyRiskLevels.contains(level) ||
        recommendation is! String ||
        recommendation.trim().isEmpty) {
      continue;
    }
    final normReference = item['normReference'];
    out.add({
      'description': description,
      'level': level,
      'normReference': normReference is String && normReference.trim().isNotEmpty
          ? normReference
          : null,
      'recommendation': recommendation,
    });
  }
  return out;
}
