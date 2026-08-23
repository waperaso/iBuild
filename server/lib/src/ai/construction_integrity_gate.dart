import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:exif/exif.dart' as exiflib;
import 'package:image/image.dart' as img;

import 'openai_client.dart';
import 'readiness_engine.dart';

/// Local Multiple-checks gate before OpenAI Vision.
///
/// Hard failures ([ConstructionIntegrityResult.passed] == false) mean the
/// vendor call must not run. Soft findings still allow Vision — they are
/// attached to the user JSON so the model can weight them.
class ConstructionIntegrityResult {
  const ConstructionIntegrityResult({
    required this.passed,
    required this.findings,
    required this.payload,
    required this.summary,
    required this.flags,
  });

  final bool passed;
  final List<Map<String, dynamic>> findings;

  /// Nested under the verify request as `integrity`.
  final Map<String, dynamic> payload;

  /// Inspector-facing English summary when Vision is skipped.
  final String summary;

  /// Flags merged into the cycle result when Vision is skipped.
  final List<String> flags;
}

/// Runs checksum / EXIF / geotag / perceptual-duplicate checks on A and B.
Future<ConstructionIntegrityResult> runConstructionIntegrityGate({
  required OpenAiImageFile fileA,
  required OpenAiImageFile fileB,
  double? projectLat,
  double? projectLng,
  ReadinessConfig config = const ReadinessConfig(),
}) async {
  final findings = <Map<String, dynamic>>[];
  final hardFlags = <String>[];
  final softFlags = <String>[];

  final shaA = sha256.convert(fileA.bytes).toString();
  final shaB = sha256.convert(fileB.bytes).toString();

  final decodedA = _decode(fileA.bytes);
  final decodedB = _decode(fileB.bytes);
  if (decodedA == null) {
    _fail(
      findings,
      hardFlags,
      code: 'image_a_unreadable',
      flag: 'image_unusable',
      detail: 'Photo A could not be decoded as an image file.',
    );
  }
  if (decodedB == null) {
    _fail(
      findings,
      hardFlags,
      code: 'image_b_unreadable',
      flag: 'image_unusable',
      detail: 'Photo B could not be decoded as an image file.',
    );
  }

  if (shaA == shaB) {
    _fail(
      findings,
      hardFlags,
      code: 'checksum_duplicate_a_b',
      flag: 'possible_staging',
      detail: 'Photo A and Photo B have the same SHA-256 checksum.',
    );
  }

  String? phashA;
  String? phashB;
  if (decodedA != null) phashA = combinedPerceptualHash(decodedA);
  if (decodedB != null) phashB = combinedPerceptualHash(decodedB);
  if (phashA != null && phashB != null) {
    final distance = hammingDistanceHex(phashA, phashB);
    if (distance <= config.duplicateFailDistance) {
      _fail(
        findings,
        hardFlags,
        code: 'perceptual_duplicate_a_b',
        flag: 'possible_staging',
        detail:
            'Photo A and Photo B are near-duplicates (hamming=$distance, '
            'threshold=${config.duplicateFailDistance}).',
        params: {
          'hamming': distance,
          'threshold': config.duplicateFailDistance,
        },
      );
    } else if (distance <= config.duplicateWarnDistance) {
      _warn(
        findings,
        softFlags,
        code: 'perceptual_near_duplicate_a_b',
        flag: 'integrity_concern',
        detail: 'Photo A and Photo B are visually similar (hamming=$distance).',
        params: {
          'hamming': distance,
          'threshold': config.duplicateWarnDistance,
        },
      );
    }
  }

  final metaA = await _readMeta(fileA.bytes);
  final metaB = await _readMeta(fileB.bytes);
  _applyExifGate(
    label: 'A',
    meta: metaA,
    findings: findings,
    hardFlags: hardFlags,
    softFlags: softFlags,
    projectLat: projectLat,
    projectLng: projectLng,
    config: config,
  );
  _applyExifGate(
    label: 'B',
    meta: metaB,
    findings: findings,
    hardFlags: hardFlags,
    softFlags: softFlags,
    projectLat: projectLat,
    projectLng: projectLng,
    config: config,
  );

  if (metaA.takenAt != null &&
      metaB.takenAt != null &&
      metaB.takenAt!.isBefore(metaA.takenAt!)) {
    _fail(
      findings,
      hardFlags,
      code: 'exif_temporal_regression',
      flag: 'integrity_concern',
      detail:
          'EXIF DateTime of Photo B is earlier than Photo A '
          '(${metaB.takenAt!.toIso8601String()} < '
          '${metaA.takenAt!.toIso8601String()}).',
    );
  }

  final passed = hardFlags.isEmpty;
  final flags = <String>{
    ...hardFlags,
    if (!passed) 'integrity_concern',
    ...softFlags,
  }.toList();

  final summary = passed
      ? 'Photo checks passed.'
      : findings
            .where((f) => f['severity'] == 'hard')
            .map((f) => f['detail'] as String? ?? f['code'] as String)
            .join(' ');

  return ConstructionIntegrityResult(
    passed: passed,
    findings: findings,
    summary: summary.isEmpty
        ? 'Photo checks did not pass. Review the findings before confirming.'
        : summary,
    flags: flags,
    payload: {
      'source': 'ibuild_local',
      'passed': passed,
      'note':
          'Metadata, fingerprint, and geotag checks are owned by iBuild. '
          'Vision only judges pixels when this gate passes.',
      'photoAFingerprintSha256': shaA,
      'photoBFingerprintSha256': shaB,
      if (phashA != null) 'photoAPhash': phashA,
      if (phashB != null) 'photoBPhash': phashB,
      'duplicateSuspect': shaA == shaB || hardFlags.contains('possible_staging'),
      'photoA': {
        'filename': fileA.filename,
        'exifTakenAt': metaA.takenAt?.toIso8601String(),
        'exifLat': metaA.lat,
        'exifLng': metaA.lng,
      },
      'photoB': {
        'filename': fileB.filename,
        'exifTakenAt': metaB.takenAt?.toIso8601String(),
        'exifLat': metaB.lat,
        'exifLng': metaB.lng,
      },
      'findings': findings,
    },
  );
}

class _ExifMeta {
  const _ExifMeta({this.takenAt, this.lat, this.lng});
  final DateTime? takenAt;
  final double? lat;
  final double? lng;
}

Future<_ExifMeta> _readMeta(List<int> bytes) async {
  Map<String, dynamic>? exif;
  try {
    exif = await exiflib.readExifFromBytes(Uint8List.fromList(bytes));
  } catch (_) {
    exif = null;
  }
  return _ExifMeta(
    takenAt: _exifDateTime(exif),
    lat: _exifLatLng(exif)?.$1,
    lng: _exifLatLng(exif)?.$2,
  );
}

void _applyExifGate({
  required String label,
  required _ExifMeta meta,
  required List<Map<String, dynamic>> findings,
  required List<String> hardFlags,
  required List<String> softFlags,
  required double? projectLat,
  required double? projectLng,
  required ReadinessConfig config,
}) {
  if (meta.takenAt == null) {
    _warn(
      findings,
      softFlags,
      code: 'exif_date_missing_$label'.toLowerCase(),
      flag: 'documentation_gap',
      detail: 'Photo $label has no EXIF capture date.',
    );
  } else {
    final now = DateTime.now();
    if (meta.takenAt!.isAfter(now.add(const Duration(hours: 1)))) {
      _fail(
        findings,
        hardFlags,
        code: 'exif_date_in_future_$label'.toLowerCase(),
        flag: 'integrity_concern',
        detail: 'Photo $label EXIF date is in the future.',
        params: {'takenAt': meta.takenAt!.toIso8601String()},
      );
    } else if (now.difference(meta.takenAt!).inDays >
        config.reportingWindowDays) {
      _warn(
        findings,
        softFlags,
        code: 'exif_date_outside_window_$label'.toLowerCase(),
        flag: 'documentation_gap',
        detail:
            'Photo $label EXIF date is older than '
            '${config.reportingWindowDays} days.',
        params: {
          'takenAt': meta.takenAt!.toIso8601String(),
          'windowDays': config.reportingWindowDays,
        },
      );
    }
  }

  if (meta.lat == null || meta.lng == null) {
    if (projectLat != null && projectLng != null) {
      _warn(
        findings,
        softFlags,
        code: 'geotag_missing_$label'.toLowerCase(),
        flag: 'documentation_gap',
        detail: 'Photo $label has no GPS EXIF while the project has coordinates.',
      );
    }
  } else if (projectLat != null && projectLng != null) {
    final km = haversineKm(meta.lat!, meta.lng!, projectLat, projectLng);
    if (km > config.geoRadiusKm) {
      _fail(
        findings,
        hardFlags,
        code: 'geotag_far_$label'.toLowerCase(),
        flag: 'wrong_site',
        detail:
            'Photo $label geotag is ${km.toStringAsFixed(2)} km from the '
            'project (limit ${config.geoRadiusKm} km).',
        params: {
          'distanceKm': double.parse(km.toStringAsFixed(2)),
          'radiusKm': config.geoRadiusKm,
        },
      );
    }
  }
}

img.Image? _decode(List<int> bytes) {
  try {
    return img.decodeImage(Uint8List.fromList(bytes));
  } catch (_) {
    return null;
  }
}

DateTime? _exifDateTime(Map<String, dynamic>? exif) {
  if (exif == null) return null;
  final tag = exif['EXIF DateTimeOriginal'] ?? exif['Image DateTime'];
  if (tag == null) return null;
  final text = tag.toString().trim();
  final match = RegExp(
    r'(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(text);
  if (match == null) return null;
  try {
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  } catch (_) {
    return null;
  }
}

(double, double)? _exifLatLng(Map<String, dynamic>? exif) {
  if (exif == null) return null;
  final latTag = exif['GPS GPSLatitude'];
  final latRef = exif['GPS GPSLatitudeRef'];
  final lngTag = exif['GPS GPSLongitude'];
  final lngRef = exif['GPS GPSLongitudeRef'];
  if (latTag == null || lngTag == null) return null;
  final lat = _dmsToDecimal(latTag, latRef?.toString());
  final lng = _dmsToDecimal(lngTag, lngRef?.toString());
  if (lat == null || lng == null) return null;
  return (lat, lng);
}

double? _dmsToDecimal(dynamic ratiosTag, String? ref) {
  try {
    final values = (ratiosTag as dynamic).values;
    final list = values.toList();
    if (list.length < 3) return null;
    double toDouble(dynamic ratio) {
      if (ratio is num) return ratio.toDouble();
      final n = (ratio as dynamic).numerator as num;
      final d = (ratio as dynamic).denominator as num;
      return d == 0 ? 0 : n / d;
    }

    final deg = toDouble(list[0]);
    final min = toDouble(list[1]);
    final sec = toDouble(list[2]);
    var decimal = deg + min / 60 + sec / 3600;
    if (ref == 'S' || ref == 'W') decimal = -decimal;
    return decimal;
  } catch (_) {
    return null;
  }
}

void _fail(
  List<Map<String, dynamic>> findings,
  List<String> hardFlags, {
  required String code,
  required String flag,
  required String detail,
  Map<String, dynamic> params = const {},
}) {
  hardFlags.add(flag);
  findings.add({
    'severity': 'hard',
    'code': code,
    'flag': flag,
    'detail': detail,
    if (params.isNotEmpty) 'params': params,
  });
}

void _warn(
  List<Map<String, dynamic>> findings,
  List<String> softFlags, {
  required String code,
  required String flag,
  required String detail,
  Map<String, dynamic> params = const {},
}) {
  softFlags.add(flag);
  findings.add({
    'severity': 'soft',
    'code': code,
    'flag': flag,
    'detail': detail,
    if (params.isNotEmpty) 'params': params,
  });
}
