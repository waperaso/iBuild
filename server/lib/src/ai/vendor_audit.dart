import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../store.dart';
import 'prompt_bundle.dart';

/// Canonical SHA-256 of [payload] (sorted keys, no image bytes, no secrets).
String sha256Canonical(Map<String, dynamic> payload) {
  return sha256.convert(utf8.encode(jsonEncode(_sort(payload)))).toString();
}

dynamic _sort(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _sort(value[k])};
  }
  if (value is List) return [for (final item in value) _sort(item)];
  return value;
}

/// Inserts a `vendor_ai_calls` row. Never pass an API key or raw image bytes.
Map<String, dynamic> recordVendorCall(
  Store store, {
  required String? actorUserId,
  required String projectId,
  required String cycleId,
  String? photoAId,
  String? photoBId,
  required PromptBundle prompt,
  required Map<String, dynamic> requestPayload,
  Map<String, dynamic>? responsePayload,
  String verdict = 'stub',
  int httpStatus = 0,
  int? latencyMs,
  String? model,
}) {
  return store.addVendorAiCall({
    'actorUserId': actorUserId,
    'projectId': projectId,
    'cycleId': cycleId,
    'photoAId': photoAId,
    'photoBId': photoBId,
    'promptId': prompt.id,
    'promptSha256': prompt.sha256hex,
    'model': model ?? 'none',
    'requestSha256': sha256Canonical(requestPayload),
    'responseSha256': responsePayload == null
        ? null
        : sha256Canonical(responsePayload),
    'httpStatus': httpStatus,
    'latencyMs': latencyMs,
    'verdict': verdict,
  });
}
