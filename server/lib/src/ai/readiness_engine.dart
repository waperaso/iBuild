/// Deterministic construction-readiness image analysis — plan Part 4.
/// Implements the `stage_1`..`stage_7` schema from [kVerificationPrompt]
/// mechanically (no model call by default); `AI_VISION_ENABLED` merges a
/// GPT-vision pass over this local result later. Code namespace matches the
/// doc comment above `POST /v1/admin/projects/<id>/photo-reports/analyze` in
/// `ai_routes.dart` exactly.
///
/// Every "detector" here is a deliberately cheap, honestly-simplified stand-in
/// for the real computer-vision task it names (documented inline) — the goal
/// is a sane, testable, deterministic signal, not state-of-the-art accuracy.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:exif/exif.dart' as exiflib;
import 'package:image/image.dart' as img;

import 'openai_client.dart';
import 'prompts.dart';

/// The 8-stage construction vocabulary (ordinal — used for stage_4/stage_5
/// distance checks).
const kDeclaredStages = [
  'earthworks',
  'foundation',
  'frame_floors',
  'roofing',
  'facade',
  'utilities',
  'interior_finishing',
  'landscaping',
];

const _kStageNames = {
  'stage_1': 'Input validity',
  'stage_2': 'Duplicate detection',
  'stage_3': 'Relevance and stage classification',
  'stage_4': 'Match against declared stage',
  'stage_5': 'Progress relative to previous report',
  'stage_6': 'Visual risk and violation indicators',
  'stage_7': 'Final verdict',
};

/// One entry of the `checks[]` array.
class ReadinessCheck {
  ReadinessCheck({
    required this.stage,
    required this.status,
    required this.findingCode,
    this.findingParams = const {},
    required this.evidenceCode,
    this.evidenceParams = const {},
  });

  final String stage;
  final String status; // passed | failed | warning
  final String findingCode;
  final Map<String, dynamic> findingParams;
  final String evidenceCode;
  final Map<String, dynamic> evidenceParams;

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'name': _kStageNames[stage],
    'status': status,
    'finding': _fallbackText(findingCode, findingParams),
    'findingCode': findingCode,
    'findingParams': findingParams,
    'evidence': _fallbackText(evidenceCode, evidenceParams),
    'evidenceCode': evidenceCode,
    'evidenceParams': evidenceParams,
  };
}

/// English fallback strings for `finding`/`evidence` (the actual
/// localization is the code+params pair; these exist so the JSON is
/// human-readable in logs/tests without a client). Unknown codes fall back to
/// a generic `code: params` rendering.
String _fallbackText(String code, Map<String, dynamic> params) {
  String p(String key) => params[key]?.toString() ?? '?';
  switch (code) {
    case 'stage1.ok':
      return 'Image decoded and metadata look consistent.';
    case 'stage1.imageUnreadable':
      return 'The image could not be decoded.';
    case 'stage1.lowQuality':
      return 'Low image quality (blur=${p('blur')}, exposure=${p('exposure')}).';
    case 'stage1.metadataMissing':
      return 'No capture-date metadata found.';
    case 'stage1.geotagMissing':
      return 'No GPS metadata found.';
    case 'stage1.geotagFarFromObject':
      return 'GPS location is ${p('distanceKm')} km from the object (radius ${p('radiusKm')} km).';
    case 'stage1.dateInFuture':
      return 'Capture date ${p('takenAt')} is in the future.';
    case 'stage1.dateOutsideWindow':
      return 'Capture date ${p('takenAt')} is outside the ${p('windowDays')}-day reporting window.';
    case 'stage1.evidence.decoded':
      return 'Decoded ${p('width')}x${p('height')}, ${p('bytes')} bytes.';
    case 'stage1.evidence.exifDate':
      return 'EXIF capture date: ${p('takenAt')}.';
    case 'stage1.evidence.noExif':
      return 'No EXIF block present.';
    case 'stage1.evidence.geoDistance':
      return 'Distance to object: ${p('distanceKm')} km (radius ${p('radiusKm')} km).';
    case 'stage1.evidence.sharpness':
      return 'Sharpness score ${p('blur')} (threshold ${p('threshold')}).';
    case 'stage2.ok':
      return 'No near-duplicate found among prior reports.';
    case 'stage2.noPriorReports':
      return 'No prior reports to compare against.';
    case 'stage2.nearDuplicate':
      return 'Similar to report ${p('reportId')} (distance ${p('distance')}).';
    case 'stage2.duplicateFound':
      return 'Matches a previously submitted photo (report ${p('reportId')}, distance ${p('distance')}).';
    case 'stage2.evidence.comparedCount':
      return 'Compared against ${p('count')} prior report(s).';
    case 'stage2.evidence.hammingDistance':
      return 'Closest distance ${p('distance')} (threshold ${p('threshold')}, report ${p('reportId')}).';
    case 'stage3.ok':
      return 'Classified as ${p('stage')} (confidence ${p('confidence')}).';
    case 'stage3.notConstructionSite':
      return 'Does not appear to depict a construction site (confidence ${p('confidence')}).';
    case 'stage3.stageUnclear':
      return 'Stage could not be classified with acceptable confidence (${p('confidence')}).';
    case 'stage3.evidence.classified':
      return 'Detected stage ${p('stage')} at confidence ${p('confidence')}.';
    case 'stage3.evidence.features':
      return 'sky=${p('skyRatio')} soil=${p('soilRatio')} concrete=${p('concreteRatio')} '
          'veg=${p('vegetationRatio')} edges=${p('verticalEdgeDensity')} periodicity=${p('openingPeriodicity')}';
    case 'stage4.ok':
      return 'Matches declared stage ${p('declaredStage')}.';
    case 'stage4.noDeclaredStage':
      return 'No declared stage was provided.';
    case 'stage4.adjacentStageMismatch':
      return 'Declared ${p('declaredStage')} but detected ${p('detectedStage')} (adjacent stage).';
    case 'stage4.stageMismatch':
      return 'Declared ${p('declaredStage')} but detected ${p('detectedStage')} (distance ${p('distance')}).';
    case 'stage4.evidence.comparison':
      return '${p('declaredStage')} vs ${p('detectedStage')}, ordinal distance ${p('ordinalDistance')}.';
    case 'stage5.ok':
      return 'Visible progress since ${p('previousTakenAt')}.';
    case 'stage5.noPreviousReport':
      return 'No previous confirmed report to compare against.';
    case 'stage5.noVisibleProgress':
      return 'No visible progress since ${p('previousTakenAt')} (distance ${p('distance')}).';
    case 'stage5.regressionDetected':
      return 'Apparent regression: was ${p('previousStage')}, now ${p('detectedStage')}.';
    case 'stage5.progressNotDeclared':
      return 'No progress percentage was declared.';
    case 'stage5.evidence.similarity':
      return 'Distance to previous ${p('distance')} (threshold ${p('threshold')}, report ${p('previousReportId')}).';
    case 'stage5.evidence.progressDelta':
      return '${p('previousPercent')}% -> ${p('currentPercent')}%.';
    case 'stage5.evidence.developerComment':
      return p('comment');
    case 'stage6.ok':
      return 'No visual risk indicators found.';
    case 'stage6.safetyGearAbsent':
      return 'No safety gear/barriers visible despite active-phase work.';
    case 'stage6.structuralDamage':
      return 'Possible structural damage indicators (ratio ${p('ratio')}).';
    case 'stage6.workStoppage':
      return 'Indicators of work stoppage (no equipment visible).';
    case 'stage6.debrisAccumulation':
      return 'Debris/clutter texture detected (score ${p('score')}).';
    case 'stage6.ambiguousIndicator':
      return 'Ambiguous indicator: ${p('indicator')}.';
    case 'stage6.evidence.hiVisRatio':
      return 'Hi-vis pixel ratio ${p('ratio')} (threshold ${p('threshold')}).';
    case 'stage6.evidence.crackPixels':
      return 'Dark linear feature ratio ${p('ratio')} (threshold ${p('threshold')}).';
    case 'stage6.evidence.noEquipment':
      return 'No equipment-like vertical structures detected.';
    case 'stage6.evidence.debrisTexture':
      return 'Debris texture score ${p('score')}.';
    case 'stage7.confirmed':
      return 'All checks passed.';
    case 'stage7.manualReview':
      return '${p('warnings')} stage(s) need manual review.';
    case 'stage7.notReached':
      return 'Not reached (stopped at ${p('stoppedAt')}).';
    case 'stage7.evidence.stageSummary':
      return 'passed=${p('passed')} warnings=${p('warnings')} failed=${p('failed')}';
    case 'summary.confirmed':
      return 'Report confirmed at ${p('detectedStage')} (${p('progressPercent')}%).';
    case 'summary.manualReview':
      return 'Report needs manual review at ${p('stage')}.';
    case 'summary.discrepancy':
      return 'Discrepancy at ${p('stage')}: declared ${p('declaredStage')}, detected ${p('detectedStage')}.';
    case 'summary.violation':
      return 'Possible violation at ${p('stage')}: ${p('indicator')}.';
    default:
      if (code.endsWith('.insufficientData')) {
        return 'Insufficient data to verify this stage.';
      }
      return params.isEmpty ? code : '$code ($params)';
  }
}

/// Configurable knobs (all optional; sane defaults for a dev/staging server).
class ReadinessConfig {
  const ReadinessConfig({
    this.geoRadiusKm = 0.5,
    this.reportingWindowDays = 90,
    this.blurThreshold = 4.0,
    this.duplicateFailDistance = 6,
    this.duplicateWarnDistance = 12,
    this.progressStaleDistance = 16,
    this.stageClassificationFailConfidence = 50,
    this.reliabilityDowngradeConfidence = 60,
  });

  final double geoRadiusKm;
  final int reportingWindowDays;
  final double blurThreshold;
  final int duplicateFailDistance;
  final int duplicateWarnDistance;
  final int progressStaleDistance;
  final int stageClassificationFailConfidence;
  final int reliabilityDowngradeConfidence;
}

/// Everything the engine needs about one prior report of the same project,
/// without depending on `Store` (keeps the engine unit-testable).
class PriorReport {
  const PriorReport({
    required this.id,
    required this.phash,
    this.takenAt,
    this.verificationStatus,
    this.declaredStage,
    this.progressPercent,
    this.featureVector,
  });

  final String id;
  final String phash;
  final DateTime? takenAt;
  final String? verificationStatus;
  final String? declaredStage;
  final int? progressPercent;
  final Map<String, double>? featureVector;
}

/// Full outcome of one analysis: the response `data` plus the fields the
/// caller persists on `photo_reports`.
class ReadinessResult {
  const ReadinessResult({
    required this.json,
    required this.phash,
    required this.detectedStage,
    required this.overallStatus,
    required this.confidence,
    this.exifTakenAt,
    this.exifLat,
    this.exifLng,
  });

  final Map<String, dynamic> json;
  final String phash;
  final String? detectedStage;
  final String overallStatus;
  final int confidence;
  final DateTime? exifTakenAt;
  final double? exifLat;
  final double? exifLng;
}

class ReadinessEngine {
  const ReadinessEngine([this.config = const ReadinessConfig()]);

  final ReadinessConfig config;

  Future<ReadinessResult> analyze({
    required Uint8List imageBytes,
    required String objectId,
    required String reportId,
    required String userLanguage,
    String? declaredStage,
    String? buildingId,
    int? progressPercent,
    String? comment,
    double? projectLat,
    double? projectLng,
    List<PriorReport> priorReports = const [],
    PriorReport? lastConfirmedReport,
    OpenAiClient? visionClient,
  }) async {
    final checks = <ReadinessCheck>[];
    String? stoppedAt;

    // --- stage_1: input validity -------------------------------------------
    final decoded = _safeDecode(imageBytes);
    if (decoded == null) {
      checks.add(
        ReadinessCheck(
          stage: 'stage_1',
          status: 'failed',
          findingCode: 'stage1.imageUnreadable',
          evidenceCode: 'stage1.evidence.decoded',
          evidenceParams: {'width': 0, 'height': 0, 'bytes': imageBytes.length},
        ),
      );
      stoppedAt = 'stage_1';
      return _finish(
        checks,
        stoppedAt,
        objectId: objectId,
        reportId: reportId,
        userLanguage: userLanguage,
        declaredStage: declaredStage,
        detectedStage: null,
        phash: '',
        progressPercent: progressPercent,
      );
    }

    final gray = img.grayscale(
      img.copyResize(
        decoded,
        width: 256,
        interpolation: img.Interpolation.average,
      ),
    );
    final blur = laplacianVarianceScore(gray);
    final exposure = exposureImbalance(gray);
    final blurry = blur < config.blurThreshold;
    final badExposure = exposure > 0.6;

    Map<String, dynamic>? exif;
    try {
      exif = await exiflib.readExifFromBytes(imageBytes);
    } catch (_) {
      exif = null;
    }
    final exifTakenAt = _exifDateTime(exif);
    final exifGeo = _exifLatLng(exif);

    var stage1Status = 'passed';
    String stage1Code = 'stage1.ok';
    Map<String, dynamic> stage1Params = const {};
    double? geoDistanceKm;

    if (blurry || badExposure) {
      stage1Status = 'warning';
      stage1Code = 'stage1.lowQuality';
      stage1Params = {
        'blur': blur.toStringAsFixed(1),
        'exposure': exposure.toStringAsFixed(2),
      };
    }
    if (exifTakenAt == null) {
      stage1Status = _worseOf(stage1Status, 'warning');
      stage1Code = 'stage1.metadataMissing';
    } else {
      final now = DateTime.now();
      if (exifTakenAt.isAfter(now.add(const Duration(hours: 1)))) {
        stage1Status = 'failed';
        stage1Code = 'stage1.dateInFuture';
        stage1Params = {'takenAt': exifTakenAt.toIso8601String()};
      } else if (now.difference(exifTakenAt).inDays >
          config.reportingWindowDays) {
        stage1Status = _worseOf(stage1Status, 'warning');
        stage1Code = 'stage1.dateOutsideWindow';
        stage1Params = {
          'takenAt': exifTakenAt.toIso8601String(),
          'windowDays': config.reportingWindowDays,
        };
      }
    }
    if (exifGeo == null) {
      if (projectLat != null && projectLng != null) {
        stage1Status = _worseOf(stage1Status, 'warning');
        if (stage1Status == 'warning' && stage1Code == 'stage1.ok') {
          stage1Code = 'stage1.geotagMissing';
        }
      }
    } else if (projectLat != null && projectLng != null) {
      geoDistanceKm = haversineKm(
        exifGeo.$1,
        exifGeo.$2,
        projectLat,
        projectLng,
      );
      if (geoDistanceKm > config.geoRadiusKm) {
        stage1Status = 'failed';
        stage1Code = 'stage1.geotagFarFromObject';
        stage1Params = {
          'distanceKm': double.parse(geoDistanceKm.toStringAsFixed(2)),
          'radiusKm': config.geoRadiusKm,
        };
      }
    }

    checks.add(
      ReadinessCheck(
        stage: 'stage_1',
        status: stage1Status,
        findingCode: stage1Code,
        findingParams: stage1Params,
        evidenceCode: exifTakenAt != null
            ? 'stage1.evidence.exifDate'
            : 'stage1.evidence.noExif',
        evidenceParams: exifTakenAt != null
            ? {'takenAt': exifTakenAt.toIso8601String()}
            : const {},
      ),
    );

    final combinedHash = combinedPerceptualHash(decoded);

    if (stage1Status == 'failed') {
      return _finish(
        checks,
        'stage_1',
        objectId: objectId,
        reportId: reportId,
        userLanguage: userLanguage,
        declaredStage: declaredStage,
        detectedStage: null,
        phash: combinedHash,
        progressPercent: progressPercent,
        exifTakenAt: exifTakenAt,
        exifLat: exifGeo?.$1,
        exifLng: exifGeo?.$2,
      );
    }

    // --- stage_2: duplicate detection ---------------------------------------
    if (priorReports.isEmpty) {
      checks.add(
        ReadinessCheck(
          stage: 'stage_2',
          status: 'passed',
          findingCode: 'stage2.noPriorReports',
          evidenceCode: 'stage2.evidence.comparedCount',
          evidenceParams: {'count': 0},
        ),
      );
    } else {
      var minDistance = 64;
      PriorReport? closest;
      for (final prior in priorReports) {
        final d = hammingDistanceHex(combinedHash, prior.phash);
        if (d < minDistance) {
          minDistance = d;
          closest = prior;
        }
      }
      final String stage2Code;
      final String stage2Status;
      if (minDistance <= config.duplicateFailDistance) {
        stage2Status = 'failed';
        stage2Code = 'stage2.duplicateFound';
      } else if (minDistance <= config.duplicateWarnDistance) {
        stage2Status = 'warning';
        stage2Code = 'stage2.nearDuplicate';
      } else {
        stage2Status = 'passed';
        stage2Code = 'stage2.ok';
      }
      checks.add(
        ReadinessCheck(
          stage: 'stage_2',
          status: stage2Status,
          findingCode: stage2Code,
          findingParams: stage2Status == 'passed'
              ? const {}
              : {
                  'distance': minDistance,
                  'reportId': closest?.id,
                  'takenAt': closest?.takenAt?.toIso8601String(),
                },
          evidenceCode: 'stage2.evidence.hammingDistance',
          evidenceParams: {
            'distance': minDistance,
            'threshold': config.duplicateFailDistance,
            'reportId': closest?.id,
          },
        ),
      );
      if (stage2Status == 'failed') {
        return _finish(
          checks,
          'stage_2',
          objectId: objectId,
          reportId: reportId,
          userLanguage: userLanguage,
          declaredStage: declaredStage,
          detectedStage: null,
          phash: combinedHash,
          progressPercent: progressPercent,
          exifTakenAt: exifTakenAt,
          exifLat: exifGeo?.$1,
          exifLng: exifGeo?.$2,
        );
      }
    }

    // --- stage_3: relevance & stage classification --------------------------
    final features = extractFeatureVector(decoded);
    final classification = classifyStage(features);
    final detectedStage = classification.stage;
    final classificationConfidence = classification.confidence;

    String stage3Status;
    String stage3Code;
    Map<String, dynamic> stage3Params;
    if (classificationConfidence < config.stageClassificationFailConfidence) {
      stage3Status = detectedStage == null ? 'failed' : 'warning';
      stage3Code = detectedStage == null
          ? 'stage3.notConstructionSite'
          : 'stage3.stageUnclear';
      stage3Params = {'confidence': classificationConfidence};
    } else {
      stage3Status = 'passed';
      stage3Code = 'stage3.ok';
      stage3Params = {
        'stage': detectedStage,
        'confidence': classificationConfidence,
      };
    }
    checks.add(
      ReadinessCheck(
        stage: 'stage_3',
        status: stage3Status,
        findingCode: stage3Code,
        findingParams: stage3Params,
        evidenceCode: 'stage3.evidence.features',
        evidenceParams: features.map(
          (k, v) => MapEntry(k, double.parse(v.toStringAsFixed(3))),
        ),
      ),
    );
    if (stage3Status == 'failed') {
      return _finish(
        checks,
        'stage_3',
        objectId: objectId,
        reportId: reportId,
        userLanguage: userLanguage,
        declaredStage: declaredStage,
        detectedStage: detectedStage,
        phash: combinedHash,
        progressPercent: progressPercent,
        exifTakenAt: exifTakenAt,
        exifLat: exifGeo?.$1,
        exifLng: exifGeo?.$2,
      );
    }

    // --- stage_4: match against declared stage -------------------------------
    if (declaredStage == null || !kDeclaredStages.contains(declaredStage)) {
      checks.add(
        ReadinessCheck(
          stage: 'stage_4',
          status: 'warning',
          findingCode: 'stage4.noDeclaredStage',
          evidenceCode: 'stage4.evidence.comparison',
          evidenceParams: {
            'declaredStage': declaredStage,
            'detectedStage': detectedStage,
            'ordinalDistance': null,
          },
        ),
      );
    } else if (detectedStage != null) {
      final distance =
          (kDeclaredStages.indexOf(declaredStage) -
                  kDeclaredStages.indexOf(detectedStage))
              .abs();
      String stage4Status;
      String stage4Code;
      if (distance == 0) {
        stage4Status = 'passed';
        stage4Code = 'stage4.ok';
      } else if (distance == 1) {
        stage4Status = 'warning';
        stage4Code = 'stage4.adjacentStageMismatch';
      } else {
        stage4Status = 'failed';
        stage4Code = 'stage4.stageMismatch';
      }
      // Reliability rule: a low-confidence classification cannot support a
      // hard failure — downgrade to a warning and let stage_7 route to
      // manual review instead of a hard stop.
      if (stage4Status == 'failed' &&
          classificationConfidence < config.reliabilityDowngradeConfidence) {
        stage4Status = 'warning';
      }
      checks.add(
        ReadinessCheck(
          stage: 'stage_4',
          status: stage4Status,
          findingCode: stage4Code,
          findingParams: stage4Status == 'passed'
              ? {'declaredStage': declaredStage}
              : {
                  'declaredStage': declaredStage,
                  'detectedStage': detectedStage,
                  'distance': distance,
                },
          evidenceCode: 'stage4.evidence.comparison',
          evidenceParams: {
            'declaredStage': declaredStage,
            'detectedStage': detectedStage,
            'ordinalDistance': distance,
          },
        ),
      );
      if (stage4Status == 'failed') {
        return _finish(
          checks,
          'stage_4',
          objectId: objectId,
          reportId: reportId,
          userLanguage: userLanguage,
          declaredStage: declaredStage,
          detectedStage: detectedStage,
          phash: combinedHash,
          progressPercent: progressPercent,
          exifTakenAt: exifTakenAt,
          exifLat: exifGeo?.$1,
          exifLng: exifGeo?.$2,
        );
      }
    }

    // --- stage_5: progress relative to previous report -----------------------
    if (lastConfirmedReport == null) {
      checks.add(
        ReadinessCheck(
          stage: 'stage_5',
          status: 'warning',
          findingCode: 'stage5.noPreviousReport',
          evidenceCode: 'stage5.evidence.similarity',
          evidenceParams: const {},
        ),
      );
    } else {
      final distance = hammingDistanceHex(
        combinedHash,
        lastConfirmedReport.phash,
      );
      final previousStage = lastConfirmedReport.declaredStage;
      var stage5Status = 'passed';
      var stage5Code = 'stage5.ok';
      var stage5Params = <String, dynamic>{
        'previousTakenAt': lastConfirmedReport.takenAt?.toIso8601String(),
      };

      final stageRegressed =
          previousStage != null &&
          detectedStage != null &&
          kDeclaredStages.contains(previousStage) &&
          kDeclaredStages.indexOf(detectedStage) <
              kDeclaredStages.indexOf(previousStage);
      final percentRegressed =
          progressPercent != null &&
          lastConfirmedReport.progressPercent != null &&
          progressPercent < lastConfirmedReport.progressPercent!;

      if (distance <= config.progressStaleDistance) {
        stage5Status = 'warning';
        stage5Code = 'stage5.noVisibleProgress';
        stage5Params = {
          'distance': distance,
          'previousTakenAt': lastConfirmedReport.takenAt?.toIso8601String(),
        };
      } else if (stageRegressed || percentRegressed) {
        final explained = comment != null && comment.trim().isNotEmpty;
        stage5Status = explained ? 'warning' : 'failed';
        stage5Code = 'stage5.regressionDetected';
        stage5Params = {
          'previousStage': previousStage,
          'detectedStage': detectedStage,
        };
      } else if (progressPercent == null) {
        stage5Status = 'warning';
        stage5Code = 'stage5.progressNotDeclared';
        stage5Params = const {};
      }

      checks.add(
        ReadinessCheck(
          stage: 'stage_5',
          status: stage5Status,
          findingCode: stage5Code,
          findingParams: stage5Params,
          evidenceCode: 'stage5.evidence.similarity',
          evidenceParams: {
            'distance': distance,
            'threshold': config.progressStaleDistance,
            'previousReportId': lastConfirmedReport.id,
            'previousTakenAt': lastConfirmedReport.takenAt?.toIso8601String(),
          },
        ),
      );
      if (stage5Status == 'failed') {
        return _finish(
          checks,
          'stage_5',
          objectId: objectId,
          reportId: reportId,
          userLanguage: userLanguage,
          declaredStage: declaredStage,
          detectedStage: detectedStage,
          phash: combinedHash,
          progressPercent: progressPercent,
          exifTakenAt: exifTakenAt,
          exifLat: exifGeo?.$1,
          exifLng: exifGeo?.$2,
        );
      }
    }

    // --- stage_6: visual risk & violation indicators -------------------------
    final risk = detectRiskIndicators(decoded, declaredStage: declaredStage);
    var stage6Status = risk.status;
    if (stage6Status == 'failed' &&
        classificationConfidence < config.reliabilityDowngradeConfidence) {
      stage6Status = 'warning';
    }
    checks.add(
      ReadinessCheck(
        stage: 'stage_6',
        status: stage6Status,
        findingCode: risk.findingCode,
        findingParams: risk.findingParams,
        evidenceCode: risk.evidenceCode,
        evidenceParams: risk.evidenceParams,
      ),
    );
    if (stage6Status == 'failed') {
      return _finish(
        checks,
        'stage_6',
        objectId: objectId,
        reportId: reportId,
        userLanguage: userLanguage,
        declaredStage: declaredStage,
        detectedStage: detectedStage,
        phash: combinedHash,
        progressPercent: progressPercent,
        exifTakenAt: exifTakenAt,
        exifLat: exifGeo?.$1,
        exifLng: exifGeo?.$2,
      );
    }

    // --- stage_7: final verdict ---------------------------------------------
    final warningCount = checks.where((c) => c.status == 'warning').length;
    final stage7Status = warningCount == 0 ? 'passed' : 'warning';
    checks.add(
      ReadinessCheck(
        stage: 'stage_7',
        status: stage7Status,
        findingCode: warningCount == 0
            ? 'stage7.confirmed'
            : 'stage7.manualReview',
        findingParams: warningCount == 0
            ? const {}
            : {'warnings': warningCount},
        evidenceCode: 'stage7.evidence.stageSummary',
        evidenceParams: {
          'passed': checks.where((c) => c.status == 'passed').length,
          'warnings': warningCount,
          'failed': 0,
        },
      ),
    );

    var result = _finish(
      checks,
      null,
      objectId: objectId,
      reportId: reportId,
      userLanguage: userLanguage,
      declaredStage: declaredStage,
      detectedStage: detectedStage,
      phash: combinedHash,
      progressPercent: progressPercent,
      exifTakenAt: exifTakenAt,
      exifLat: exifGeo?.$1,
      exifLng: exifGeo?.$2,
      classificationConfidence: classificationConfidence,
    );

    if (visionClient != null && visionClient.isVisionEnabled) {
      result = await _tryVisionOverride(
        result,
        visionClient: visionClient,
        imageBytes: imageBytes,
        objectId: objectId,
        reportId: reportId,
        userLanguage: userLanguage,
      );
    }
    return result;
  }

  /// Best-effort GPT-vision merge (plan Part 4 future path). Any failure —
  /// network, timeout, unparsable JSON — silently falls back to [local];
  /// the caller never sees the failure, per the plan.
  Future<ReadinessResult> _tryVisionOverride(
    ReadinessResult local, {
    required OpenAiClient visionClient,
    required Uint8List imageBytes,
    required String objectId,
    required String reportId,
    required String userLanguage,
  }) async {
    try {
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
      final raw = await visionClient.completeWithImage(
        systemPrompt: kVerificationPrompt,
        userText: jsonEncode({
          'object_id': objectId,
          'report_id': reportId,
          'user_language': userLanguage,
        }),
        imageDataUrl: dataUrl,
      );
      final decoded = jsonDecode(sanitizeProviderMentions(raw));
      if (decoded is! Map<String, dynamic>) return local;
      // Merge: trust the model's narrative fields, keep our codes/params and
      // persisted identifiers (the model doesn't know our internal hash/ids).
      final merged = Map<String, dynamic>.from(local.json);
      for (final key in [
        'overall_status',
        'confidence',
        'stopped_at',
        'summary_for_buyer',
      ]) {
        if (decoded.containsKey(key)) merged[key] = decoded[key];
      }
      if (decoded['checks'] is List) merged['checks'] = decoded['checks'];
      return ReadinessResult(
        json: merged,
        phash: local.phash,
        detectedStage: local.detectedStage,
        overallStatus:
            (decoded['overall_status'] as String?) ?? local.overallStatus,
        confidence:
            (decoded['confidence'] as num?)?.toInt() ?? local.confidence,
        exifTakenAt: local.exifTakenAt,
        exifLat: local.exifLat,
        exifLng: local.exifLng,
      );
    } catch (_) {
      return local;
    }
  }

  ReadinessResult _finish(
    List<ReadinessCheck> checks,
    String? stoppedAt, {
    required String objectId,
    required String reportId,
    required String userLanguage,
    required String? declaredStage,
    required String? detectedStage,
    required String phash,
    required int? progressPercent,
    DateTime? exifTakenAt,
    double? exifLat,
    double? exifLng,
    int? classificationConfidence,
  }) {
    final failedStage = checks
        .where((c) => c.status == 'failed')
        .firstOrNull
        ?.stage;
    final hasWarning = checks.any((c) => c.status == 'warning');

    String overallStatus;
    String summaryCode;
    Map<String, dynamic> summaryParams;
    if (failedStage != null) {
      overallStatus = failedStage == 'stage_6'
          ? 'violation_found'
          : 'discrepancy_found';
      summaryCode = overallStatus == 'violation_found'
          ? 'summary.violation'
          : 'summary.discrepancy';
      summaryParams = overallStatus == 'violation_found'
          ? {'stage': failedStage, 'indicator': checks.last.findingCode}
          : {
              'stage': failedStage,
              'declaredStage': declaredStage,
              'detectedStage': detectedStage,
            };
    } else if (hasWarning) {
      overallStatus = 'requires_manual_review';
      summaryCode = 'summary.manualReview';
      summaryParams = {
        'stage': checks.where((c) => c.status == 'warning').first.stage,
      };
    } else {
      overallStatus = 'confirmed';
      summaryCode = 'summary.confirmed';
      summaryParams = {
        'detectedStage': detectedStage,
        'progressPercent': progressPercent,
      };
    }

    int confidence;
    if (failedStage != null) {
      confidence = 30;
    } else if (hasWarning) {
      confidence = math.min(classificationConfidence ?? 65, 65);
    } else {
      confidence = classificationConfidence ?? 80;
    }

    final json = {
      'object_id': objectId,
      'report_id': reportId,
      'user_language': userLanguage,
      'stopped_at': stoppedAt,
      'overall_status': overallStatus,
      'confidence': confidence,
      'checks': checks.map((c) => c.toJson()).toList(),
      'summary_for_buyer': _fallbackText(summaryCode, summaryParams),
      'summaryCode': summaryCode,
      'summaryParams': summaryParams,
      'phash': phash,
      'detected_stage': detectedStage,
      'declared_stage': declaredStage,
    };

    return ReadinessResult(
      json: json,
      phash: phash,
      detectedStage: detectedStage,
      overallStatus: overallStatus,
      confidence: confidence,
      exifTakenAt: exifTakenAt,
      exifLat: exifLat,
      exifLng: exifLng,
    );
  }

  img.Image? _safeDecode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  String _worseOf(String a, String b) {
    const rank = {'passed': 0, 'warning': 1, 'failed': 2};
    return (rank[a] ?? 0) >= (rank[b] ?? 0) ? a : b;
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
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ============================================================================
// Pure, independently-testable primitives
// ============================================================================

/// Great-circle distance in kilometres.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _deg2rad(double deg) => deg * (math.pi / 180.0);

/// Simplified Laplacian-variance sharpness score on a grayscale [image] (the
/// classic "blur detector"): higher = sharper. Runs on whatever resolution
/// [image] already is — callers downscale first for speed.
double laplacianVarianceScore(img.Image image) {
  final w = image.width, h = image.height;
  if (w < 3 || h < 3) return 0;
  final values = <double>[];
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final center = image.getPixel(x, y).luminance;
      final up = image.getPixel(x, y - 1).luminance;
      final down = image.getPixel(x, y + 1).luminance;
      final left = image.getPixel(x - 1, y).luminance;
      final right = image.getPixel(x + 1, y).luminance;
      values.add((up + down + left + right - 4 * center).toDouble());
    }
  }
  if (values.isEmpty) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
      values.length;
  return variance;
}

/// 0..1 imbalance score for over/under-exposure: fraction of pixels sitting
/// in the extreme (near-black or near-white) histogram bins.
double exposureImbalance(img.Image grayImage) {
  final histogram = List<int>.filled(256, 0);
  var total = 0;
  for (final pixel in grayImage) {
    final l = pixel.luminance.round().clamp(0, 255);
    histogram[l]++;
    total++;
  }
  if (total == 0) return 0;
  final dark = histogram.sublist(0, 12).reduce((a, b) => a + b);
  final bright = histogram.sublist(244, 256).reduce((a, b) => a + b);
  return (dark + bright) / total;
}

/// 64-bit average hash: resize to 8x8, bit = pixel > mean.
int averageHash64(img.Image src) {
  final small = img.grayscale(
    img.copyResize(
      src,
      width: 8,
      height: 8,
      interpolation: img.Interpolation.average,
    ),
  );
  final values = <int>[];
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      values.add(small.getPixel(x, y).luminance.round());
    }
  }
  final mean = values.reduce((a, b) => a + b) / values.length;
  var hash = 0;
  for (var i = 0; i < 64; i++) {
    if (values[i] > mean) hash |= (1 << i);
  }
  return hash;
}

/// 64-bit difference hash: resize to 9x8, bit = pixel(x+1) > pixel(x).
int differenceHash64(img.Image src) {
  final small = img.grayscale(
    img.copyResize(
      src,
      width: 9,
      height: 8,
      interpolation: img.Interpolation.average,
    ),
  );
  var hash = 0;
  var bit = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final left = small.getPixel(x, y).luminance;
      final right = small.getPixel(x + 1, y).luminance;
      if (right > left) hash |= (1 << bit);
      bit++;
    }
  }
  return hash;
}

/// Simplified 64-bit perceptual hash: resize to 32x32 grayscale, compute the
/// 8x8 low-frequency block of a direct (non-separable-FFT) 2D DCT-II, bit =
/// coefficient > median of that block. This is the textbook pHash recipe
/// minus the speed optimization of a real FFT — fine at 32x32.
int perceptualHash64(img.Image src) {
  const n = 32;
  final small = img.grayscale(
    img.copyResize(
      src,
      width: n,
      height: n,
      interpolation: img.Interpolation.average,
    ),
  );
  final pixels = List.generate(
    n,
    (y) => List.generate(n, (x) => small.getPixel(x, y).luminance.toDouble()),
  );

  final coeffs = <double>[];
  for (var u = 0; u < 8; u++) {
    for (var v = 0; v < 8; v++) {
      var sum = 0.0;
      for (var x = 0; x < n; x++) {
        final cu = math.cos((math.pi / n) * (x + 0.5) * u);
        for (var y = 0; y < n; y++) {
          final cv = math.cos((math.pi / n) * (y + 0.5) * v);
          sum += pixels[x][y] * cu * cv;
        }
      }
      coeffs.add(sum);
    }
  }
  final sorted = [...coeffs]..sort();
  final median = sorted[sorted.length ~/ 2];
  var hash = 0;
  for (var i = 0; i < 64; i++) {
    if (coeffs[i] > median) hash |= (1 << i);
  }
  return hash;
}

/// Combined 64-bit fingerprint: majority vote per bit across aHash, dHash,
/// and pHash. Each algorithm individually is a legitimate 64-bit perceptual
/// hash; fusing them bit-by-bit keeps the result a single 64-bit value (the
/// `photo_reports.phash` column stores one hash) while still reflecting all
/// three, and Hamming distance on the fused value stays meaningful because
/// every bit is still a single binary decision.
String combinedPerceptualHash(img.Image src) {
  final a = averageHash64(src);
  final d = differenceHash64(src);
  final p = perceptualHash64(src);
  var fused = 0;
  for (var i = 0; i < 64; i++) {
    final votes = ((a >> i) & 1) + ((d >> i) & 1) + ((p >> i) & 1);
    if (votes >= 2) fused |= (1 << i);
  }
  return _hex64(fused);
}

/// Encodes a 64-bit hash as unsigned hex. Dart's native `int` is a 64-bit
/// signed two's complement value, so any hash with bit 63 set (about half of
/// them) is *negative* — neither `toRadixString()` nor `toUnsigned(64)` (a
/// no-op on the VM once width == the native int width) produce the correct
/// unsigned digits for that case. Splitting into two 32-bit halves keeps
/// every intermediate value non-negative and sidesteps the issue entirely.
String _hex64(int value) {
  final hi = (value >> 32) & 0xFFFFFFFF;
  final lo = value & 0xFFFFFFFF;
  return '${hi.toRadixString(16).padLeft(8, '0')}${lo.toRadixString(16).padLeft(8, '0')}';
}

/// Inverse of [_hex64]; null on anything that isn't exactly 16 hex digits.
int? _parseHex64(String hex) {
  if (hex.length != 16) return null;
  try {
    final hi = int.parse(hex.substring(0, 8), radix: 16);
    final lo = int.parse(hex.substring(8, 16), radix: 16);
    return (hi << 32) | lo;
  } catch (_) {
    return null;
  }
}

/// Hamming distance between two 64-bit hex-encoded hashes (0..64). Malformed
/// input compares as maximally different so a bad stored hash never wins a
/// dedup match by accident.
int hammingDistanceHex(String aHex, String bHex) {
  final a = _parseHex64(aHex);
  final b = _parseHex64(bHex);
  if (a == null || b == null) return 64;
  return _popcount(a ^ b);
}

/// Bit count over exactly 64 positions (never a `while (v != 0)` loop): `v`
/// may be negative (two's complement, bit 63 set) and `>>` is an arithmetic,
/// sign-extending shift on Dart's native int, so a naive "shift until zero"
/// loop never terminates for a negative value.
int _popcount(int value) {
  var count = 0;
  for (var i = 0; i < 64; i++) {
    if ((value >> i) & 1 == 1) count++;
  }
  return count;
}

/// stage_3 feature vector: sky/soil/concrete/vegetation HSV-band ratios, a
/// Sobel-based vertical-edge density, and an autocorrelation-based opening
/// "periodicity" heuristic for facade window rhythm.
Map<String, double> extractFeatureVector(img.Image src) {
  final small = img.copyResize(
    src,
    width: 128,
    interpolation: img.Interpolation.average,
  );
  final w = small.width, h = small.height;
  var sky = 0, soil = 0, concrete = 0, vegetation = 0, total = 0;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final px = small.getPixel(x, y);
      final r = px.r.toDouble(), g = px.g.toDouble(), b = px.b.toDouble();
      final hsv = _rgbToHsv(r, g, b);
      final hue = hsv.$1, sat = hsv.$2, val = hsv.$3;
      total++;
      // Sky: bright, low-saturation blue, biased toward the upper half.
      if (y < h * 0.45 &&
          val > 0.55 &&
          ((hue >= 180 && hue <= 260) || sat < 0.15) &&
          val > 0.4) {
        sky++;
      }
      // Vegetation: green hue band, moderate saturation.
      if (hue >= 70 && hue <= 170 && sat > 0.2 && val > 0.15) {
        vegetation++;
      }
      // Soil/earth: orange-brown hue band, low-to-mid value.
      if (hue >= 10 && hue < 45 && sat > 0.25 && val < 0.6) {
        soil++;
      }
      // Concrete/gray: low saturation, mid value (neither sky-bright nor
      // shadow-dark) — the plan's "concrete gray ratio".
      if (sat < 0.12 && val >= 0.2 && val <= 0.85) {
        concrete++;
      }
    }
  }

  final gray = img.grayscale(small);
  final verticalEdgeDensity = _verticalEdgeDensity(gray);
  final periodicity = _rowProfileAutocorrelation(gray);

  return {
    'skyRatio': total == 0 ? 0 : sky / total,
    'soilRatio': total == 0 ? 0 : soil / total,
    'concreteRatio': total == 0 ? 0 : concrete / total,
    'vegetationRatio': total == 0 ? 0 : vegetation / total,
    'verticalEdgeDensity': verticalEdgeDensity,
    'openingPeriodicity': periodicity,
  };
}

/// (hue 0..360, saturation 0..1, value 0..1).
(double, double, double) _rgbToHsv(double r, double g, double b) {
  final rn = r / 255.0, gn = g / 255.0, bn = b / 255.0;
  final maxC = math.max(rn, math.max(gn, bn));
  final minC = math.min(rn, math.min(gn, bn));
  final delta = maxC - minC;
  double hue;
  if (delta == 0) {
    hue = 0;
  } else if (maxC == rn) {
    hue = 60 * (((gn - bn) / delta) % 6);
  } else if (maxC == gn) {
    hue = 60 * (((bn - rn) / delta) + 2);
  } else {
    hue = 60 * (((rn - gn) / delta) + 4);
  }
  if (hue < 0) hue += 360;
  final sat = maxC == 0 ? 0.0 : delta / maxC;
  return (hue, sat, maxC);
}

/// Fraction of pixels with strong vertical gradient (Sobel-Gy magnitude
/// above a fixed threshold) — a cheap proxy for scaffolding/frame/rebar
/// density, per the plan.
double _verticalEdgeDensity(img.Image gray) {
  final w = gray.width, h = gray.height;
  if (w < 3 || h < 3) return 0;
  var strong = 0, total = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final top = gray.getPixel(x, y - 1).luminance;
      final bottom = gray.getPixel(x, y + 1).luminance;
      final gy = (bottom - top).abs();
      total++;
      if (gy > 25) strong++;
    }
  }
  return total == 0 ? 0 : strong / total;
}

/// Autocorrelation of the per-column vertical-edge profile, looking for a
/// repeating peak in a plausible window-spacing range — a cheap,
/// FFT-free stand-in for detecting facade opening periodicity.
double _rowProfileAutocorrelation(img.Image gray) {
  final w = gray.width, h = gray.height;
  if (w < 8 || h < 8) return 0;
  final profile = List<double>.filled(w, 0);
  for (var x = 0; x < w; x++) {
    var edge = 0.0;
    for (var y = 1; y < h; y++) {
      edge +=
          (gray.getPixel(x, y).luminance - gray.getPixel(x, y - 1).luminance)
              .abs();
    }
    profile[x] = edge;
  }
  final mean = profile.reduce((a, b) => a + b) / profile.length;
  final centered = profile.map((v) => v - mean).toList();
  final variance = centered.map((v) => v * v).reduce((a, b) => a + b);
  if (variance == 0) return 0;

  var bestLag = 0;
  var bestScore = 0.0;
  final minLag = math.max(2, (w * 0.05).round());
  final maxLag = (w * 0.4).round();
  for (var lag = minLag; lag <= maxLag && lag < w; lag++) {
    var sum = 0.0;
    for (var i = 0; i < w - lag; i++) {
      sum += centered[i] * centered[i + lag];
    }
    final score = sum / variance;
    if (score > bestScore) {
      bestScore = score;
      bestLag = lag;
    }
  }
  return bestLag == 0 ? 0 : bestScore.clamp(0, 1).toDouble();
}

/// One classification outcome: `stage` is null when nothing scores
/// meaningfully above the others (treated as "not a construction site").
class StageClassification {
  const StageClassification(this.stage, this.confidence);
  final String? stage;
  final int confidence;
}

/// Hand-tuned scoring matrix mapping the [features] vector to one of
/// [kDeclaredStages], with a 0..100 confidence (the gap between the best and
/// second-best score, scaled). This is intentionally simple linear scoring,
/// not a trained model — see the phase report for the honesty note.
StageClassification classifyStage(Map<String, double> features) {
  final sky = features['skyRatio'] ?? 0;
  final soil = features['soilRatio'] ?? 0;
  final concrete = features['concreteRatio'] ?? 0;
  final vegetation = features['vegetationRatio'] ?? 0;
  final edges = features['verticalEdgeDensity'] ?? 0;
  final periodicity = features['openingPeriodicity'] ?? 0;

  final scores = <String, double>{
    'earthworks': soil * 3.0 + (1 - edges) * 0.5,
    'foundation': soil * 1.2 + concrete * 1.5 + (edges.clamp(0, 0.3)) * 1.0,
    'frame_floors': edges * 3.0 + concrete * 1.0 + sky * 0.6,
    'roofing': sky * 1.2 + edges * 1.0 - vegetation * 0.5,
    'facade': concrete * 1.8 + periodicity * 2.5,
    'utilities': concrete * 1.0 + edges * 1.4 - periodicity * 0.5,
    'interior_finishing': concrete * 0.6 + (1 - sky) * 1.0 + (1 - edges) * 0.8,
    'landscaping': vegetation * 3.0 + (1 - concrete) * 0.6,
  };

  // A frame with almost no recognizable construction texture at all (mostly
  // sky/vegetation, near-zero concrete or edges) is more likely "not a
  // construction site" than any specific stage.
  final siteSignal =
      concrete + edges + soil + (scores['facade']! > 0 ? 0.1 : 0);
  if (siteSignal < 0.08 && vegetation + sky > 0.6) {
    return const StageClassification(null, 20);
  }

  final ranked = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final best = ranked.first;
  final secondBest = ranked.length > 1 ? ranked[1].value : 0.0;
  final gap = best.value - secondBest;
  // Confidence: how decisively the winner beat the runner-up, plus a floor
  // proportional to the raw signal strength (an image with barely any
  // matching features anywhere should not read as "very confident").
  final confidence = (45 + gap * 220 + best.value * 40).clamp(0, 100).round();

  return StageClassification(best.key, confidence);
}

/// One stage_6 outcome (finding + evidence, pre-packaged for [ReadinessCheck]).
class RiskFinding {
  const RiskFinding({
    required this.status,
    required this.findingCode,
    this.findingParams = const {},
    required this.evidenceCode,
    this.evidenceParams = const {},
  });
  final String status;
  final String findingCode;
  final Map<String, dynamic> findingParams;
  final String evidenceCode;
  final Map<String, dynamic> evidenceParams;
}

const _kActivePhases = {'frame_floors', 'roofing', 'facade', 'utilities'};

/// stage_6: hi-vis blob presence (helmet/barrier proxy), dark-linear-feature
/// density on concrete-classified regions (crack proxy), ground-level
/// texture variance (debris proxy), and vertical-edge scarcity (absent
/// equipment proxy).
RiskFinding detectRiskIndicators(img.Image src, {String? declaredStage}) {
  final small = img.copyResize(
    src,
    width: 160,
    interpolation: img.Interpolation.average,
  );
  final w = small.width, h = small.height;

  final hiVisGrid = List.generate(
    (h / 8).ceil(),
    (_) => List.filled((w / 8).ceil(), false),
  );
  var hiVisPixels = 0;
  var concretePixels = 0;
  var darkLinePixels = 0;
  var groundVarianceSum = 0.0;
  var groundCells = 0;
  var edgePixels = 0;
  var totalPixels = 0;

  final gray = img.grayscale(small);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final px = small.getPixel(x, y);
      final hsv = _rgbToHsv(px.r.toDouble(), px.g.toDouble(), px.b.toDouble());
      totalPixels++;
      final isHiVis =
          hsv.$2 > 0.55 && hsv.$3 > 0.55 && ((hsv.$1 >= 15 && hsv.$1 <= 60));
      if (isHiVis) {
        hiVisPixels++;
        hiVisGrid[y ~/ 8][x ~/ 8] = true;
      }
      final isConcrete = hsv.$2 < 0.12 && hsv.$3 >= 0.2 && hsv.$3 <= 0.85;
      if (isConcrete) {
        concretePixels++;
        if (x > 0 && y > 0) {
          final l = gray.getPixel(x, y).luminance;
          final left = gray.getPixel(x - 1, y).luminance;
          final up = gray.getPixel(x, y - 1).luminance;
          final localAvg = (left + up) / 2;
          if (localAvg - l > 22) darkLinePixels++;
        }
      }
      if (y > h * 0.7) {
        groundCells++;
      }
      if (x > 0 && y > 0) {
        final gy =
            (gray.getPixel(x, y).luminance - gray.getPixel(x, y - 1).luminance)
                .abs();
        if (gy > 25) edgePixels++;
      }
    }
  }

  // Ground-level local variance (debris/clutter proxy): sample the bottom
  // strip in 8x8 blocks and average per-block variance.
  final groundTop = (h * 0.7).floor();
  for (var by = groundTop; by < h - 8; by += 8) {
    for (var bx = 0; bx < w - 8; bx += 8) {
      final values = <double>[];
      for (var y = by; y < by + 8; y++) {
        for (var x = bx; x < bx + 8; x++) {
          values.add(gray.getPixel(x, y).luminance.toDouble());
        }
      }
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          values.length;
      groundVarianceSum += variance;
      groundCells++;
    }
  }
  final debrisScore = groundCells == 0 ? 0.0 : groundVarianceSum / groundCells;

  final hiVisRatio = totalPixels == 0 ? 0.0 : hiVisPixels / totalPixels;
  final crackRatio = concretePixels == 0
      ? 0.0
      : darkLinePixels / concretePixels;
  final edgeDensity = totalPixels == 0 ? 0.0 : edgePixels / totalPixels;
  final blobCount = _connectedComponents(hiVisGrid);
  final isActivePhase =
      declaredStage != null && _kActivePhases.contains(declaredStage);

  if (crackRatio > 0.35) {
    return RiskFinding(
      status: 'failed',
      findingCode: 'stage6.structuralDamage',
      findingParams: {'ratio': double.parse(crackRatio.toStringAsFixed(3))},
      evidenceCode: 'stage6.evidence.crackPixels',
      evidenceParams: {
        'ratio': double.parse(crackRatio.toStringAsFixed(3)),
        'threshold': 0.35,
      },
    );
  }
  if (crackRatio > 0.18) {
    return RiskFinding(
      status: 'warning',
      findingCode: 'stage6.ambiguousIndicator',
      findingParams: {'indicator': 'structuralDamage'},
      evidenceCode: 'stage6.evidence.crackPixels',
      evidenceParams: {
        'ratio': double.parse(crackRatio.toStringAsFixed(3)),
        'threshold': 0.35,
      },
    );
  }
  if (isActivePhase && blobCount == 0 && edgeDensity > 0.08) {
    return RiskFinding(
      status: 'warning',
      findingCode: 'stage6.safetyGearAbsent',
      evidenceCode: 'stage6.evidence.hiVisRatio',
      evidenceParams: {
        'ratio': double.parse(hiVisRatio.toStringAsFixed(4)),
        'threshold': 0.0,
      },
    );
  }
  if (debrisScore > 900) {
    return RiskFinding(
      status: 'warning',
      findingCode: 'stage6.debrisAccumulation',
      findingParams: {'score': debrisScore.round()},
      evidenceCode: 'stage6.evidence.debrisTexture',
      evidenceParams: {'score': debrisScore.round()},
    );
  }
  if (isActivePhase && edgeDensity < 0.02) {
    return RiskFinding(
      status: 'warning',
      findingCode: 'stage6.workStoppage',
      evidenceCode: 'stage6.evidence.noEquipment',
    );
  }
  return RiskFinding(
    status: 'passed',
    findingCode: 'stage6.ok',
    evidenceCode: 'stage6.evidence.hiVisRatio',
    evidenceParams: {
      'ratio': double.parse(hiVisRatio.toStringAsFixed(4)),
      'threshold': 0.0,
    },
  );
}

/// Number of 4-connected `true` components in a small boolean grid — a cheap
/// "blob count" for the hi-vis mask.
int _connectedComponents(List<List<bool>> grid) {
  if (grid.isEmpty) return 0;
  final rows = grid.length, cols = grid[0].length;
  final visited = List.generate(rows, (_) => List.filled(cols, false));
  var count = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (!grid[r][c] || visited[r][c]) continue;
      count++;
      final stack = <(int, int)>[(r, c)];
      while (stack.isNotEmpty) {
        final (cr, cc) = stack.removeLast();
        if (cr < 0 || cr >= rows || cc < 0 || cc >= cols) continue;
        if (visited[cr][cc] || !grid[cr][cc]) continue;
        visited[cr][cc] = true;
        stack.addAll([(cr - 1, cc), (cr + 1, cc), (cr, cc - 1), (cr, cc + 1)]);
      }
    }
  }
  return count;
}
