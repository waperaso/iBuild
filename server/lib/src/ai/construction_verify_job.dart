import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../static_files.dart';
import '../store.dart';
import 'construction_integrity_gate.dart';
import 'construction_verify_schema.dart';
import 'normative_check.dart';
import 'openai_client.dart';
import 'prompt_bundle.dart';
import 'temporal_check.dart';
import 'vendor_audit.dart';

const kConstructionVerifyStubSummary = 'Submitted for review.';
const kConstructionVerifyImagesUnavailableSummary =
    'Photos could not be read for automated checks. Manual review required.';
const kConstructionVerifyTimeoutSummary =
    'Automated check timed out. Manual review required.';
const kConstructionVerifyFailedSummary =
    'Automated check failed. Manual review required.';

String constructionVerifyFallbackSummary(String kind, String language) {
  final lang = normalizeSitePhotoLanguage(language);
  return switch ((kind, lang)) {
    ('images', 'ru') =>
      'Фото не удалось прочитать для автопроверки. Нужна ручная проверка.',
    ('images', 'uz') =>
      'Fotolar avtotekshiruv uchun o‘qilmadi. Qo‘lda ko‘rish kerak.',
    ('timeout', 'ru') =>
      'Автопроверка не успела завершиться. Нужна ручная проверка.',
    ('timeout', 'uz') =>
      'Avtotekshiruv vaqti tugadi. Qo‘lda ko‘rish kerak.',
    ('failed', 'ru') =>
      'Автопроверка не удалась. Нужна ручная проверка.',
    ('failed', 'uz') =>
      'Avtotekshiruv muvaffaqiyatsiz. Qo‘lda ko‘rish kerak.',
    ('invalid', 'ru') =>
      'Автопроверка вернула неполный ответ. Нужна ручная проверка.',
    ('invalid', 'uz') =>
      'Avtotekshiruv to‘liq javob bermadi. Qo‘lda ko‘rish kerak.',
    ('stub', 'ru') => 'Отправлено на проверку специалисту.',
    ('stub', 'uz') => 'Mutaxassis tekshiruviga yuborildi.',
    ('images', _) => kConstructionVerifyImagesUnavailableSummary,
    ('timeout', _) => kConstructionVerifyTimeoutSummary,
    ('failed', _) => kConstructionVerifyFailedSummary,
    ('invalid', _) =>
      'Automated check returned an incomplete answer. Manual review required.',
    _ => kConstructionVerifyStubSummary,
  };
}

/// Request/response the UI may show. No API key, image bytes, prompt text,
/// or image fingerprints.
Map<String, dynamic> buildSafeVerifyExport({
  required Map<String, dynamic> requestPayload,
  required Map<String, dynamic> parsedFields,
  required String promptVersion,
  required String model,
  required int httpStatus,
  int? latencyMs,
}) {
  final integrity = requestPayload['integrity'];
  Map<String, dynamic>? safeIntegrity;
  if (integrity is Map) {
    final findings = (integrity['findings'] as List?)
            ?.map((f) {
              if (f is! Map) return null;
              return {
                'code': f['code'],
                if (f['severity'] != null) 'severity': f['severity'],
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    safeIntegrity = {
      'passed': integrity['passed'],
      'findings': findings,
    };
  }
  return {
    'request': {
      'photoA': requestPayload['photoA'],
      'photoB': requestPayload['photoB'],
      'expectedState': requestPayload['expectedState'],
      'user_language': requestPayload['user_language'],
      'checks': requestPayload['checks'],
      if (safeIntegrity != null) 'integrity': safeIntegrity,
      'temporal': requestPayload['temporal'],
      'normative': requestPayload['normative'],
    },
    'response': {
      'verdict': parsedFields['verdict'],
      'confidence': parsedFields['confidence'],
      'summary': parsedFields['summary'],
      'sameViewpoint': parsedFields['sameViewpoint'],
      'progressDelta': parsedFields['progressDelta'],
      'flags': parsedFields['flags'],
      if (parsedFields['overallConclusion'] != null)
        'overallConclusion': parsedFields['overallConclusion'],
      if (parsedFields['photoFindings'] != null)
        'photoFindings': parsedFields['photoFindings'],
      if (parsedFields['risks'] != null) 'risks': parsedFields['risks'],
      if (parsedFields['recommendations'] != null)
        'recommendations': parsedFields['recommendations'],
    },
    'vendor': {
      'promptVersion': promptVersion,
      'model': model,
      'httpStatus': httpStatus,
      if (latencyMs != null) 'latencyMs': latencyMs,
    },
  };
}

/// Runs after photo B. Default path is stub → inspector. Real gpt-4o is used
/// only when vision is on, the prompt is shipped, both images are local
/// files, **and** the local integrity gate passes (checksum / EXIF / geotag /
/// perceptual duplicate). If the gate fails, OpenAI is not called. If it
/// passes, Vision still runs. Never auto-confirms: a human always sees the cycle.
Future<void> runConstructionVerifyJob({
  required Store store,
  required String cycleId,
  required String actorUserId,
  OpenAiClient? client,
}) async {
  final cycle = store.sitePhotoCycleById(cycleId);
  if (cycle == null) return;

  final prompt = loadPromptBundle();
  final photoA = store.photoReportById(cycle['photoAId'] as String? ?? '');
  final photoB = store.photoReportById(cycle['photoBId'] as String? ?? '');
  final project = store.projectById(cycle['projectId'] as String);
  final fileA = await _localImageFile(photoA?['photoUrl'] as String?);
  final fileB = await _localImageFile(photoB?['photoUrl'] as String?);

  ConstructionIntegrityResult? integrity;
  if (fileA != null && fileB != null) {
    integrity = await runConstructionIntegrityGate(
      fileA: fileA,
      fileB: fileB,
      projectLat: (project?['lat'] as num?)?.toDouble(),
      projectLng: (project?['lng'] as num?)?.toDouble(),
    );
  }

  final takenA = DateTime.tryParse(photoA?['takenAt'] as String? ?? '');
  final takenB = DateTime.tryParse(photoB?['takenAt'] as String? ?? '');
  final intervalDays =
      cycle['intervalDays'] as int? ?? kSitePhotoIntervalDays;
  final intervalMinutes = cycle['intervalMinutes'] as int?;
  final userLanguage = normalizeSitePhotoLanguage(cycle['userLanguage']);
  final temporal = temporalCheck(
    takenA: takenA,
    takenB: takenB,
    intervalDays: intervalDays,
    intervalMinutes: intervalMinutes,
  );
  final normative = normativeCheck(
    plannedProgress: project?['plannedProgress'] as num?,
  );

  final requestPayload = <String, dynamic>{
    'photoA': {
      'id': cycle['photoAId'],
      'takenAt': photoA?['takenAt'],
      'filename': fileA?.filename,
      'role': 'baseline_file',
    },
    'photoB': {
      'id': cycle['photoBId'],
      'takenAt': photoB?['takenAt'],
      'filename': fileB?.filename,
      'role': 'followup_file',
    },
    'expectedState': {
      'plannedProgress': project?['plannedProgress'],
      'intervalDays': intervalDays,
    },
    if (integrity != null) 'integrity': integrity.payload,
    'temporal': temporal,
    'normative': normative,
    'user_language': userLanguage,
    'checks': const [
      'image_authenticity_visual',
      'same_building_visual',
      'progress_delta_visual',
    ],
  };

  var verdict = 'stub';
  var httpStatus = 0;
  var model = 'none';
  var latencyMs = 0;
  Map<String, dynamic> parsedFields = {
    'verdict': 'needs_review',
    'confidence': 0,
    'summary': constructionVerifyFallbackSummary('stub', userLanguage),
    'sameViewpoint': null,
    'progressDelta': null,
    'flags': <String>[],
  };
  final vision = client ?? OpenAiClient();

  List<String> mergeFlags(Iterable<String> extra) {
    final flags = <String>{
      ...((parsedFields['flags'] as List?)?.map((e) => e.toString()) ??
          const <String>[]),
      ...extra,
    };
    return flags.toList();
  }

  try {
    final gateOk = integrity == null || integrity.passed;
    final imagesAvailable = fileA != null && fileB != null;
    final canCallVision =
        vision.isVisionEnabled &&
        prompt.isShipped &&
        imagesAvailable &&
        gateOk;

    if (!imagesAvailable) {
      verdict = 'images_unavailable';
      parsedFields = {
        'verdict': 'needs_review',
        'confidence': 0,
        'summary': constructionVerifyFallbackSummary('images', userLanguage),
        'sameViewpoint': null,
        'progressDelta': null,
        'flags': <String>['images_unavailable'],
      };
    } else if (integrity != null && !integrity.passed) {
      // Local Multiple checks failed — do not spend OpenAI budget.
      verdict = 'integrity_blocked';
      parsedFields = {
        'verdict': 'needs_review',
        'confidence': 0,
        'summary': integrity.summary,
        'sameViewpoint': null,
        'progressDelta': null,
        'flags': List<String>.from(integrity.flags),
      };
      stderr.writeln(
        '[construction_verify] Integrity gate blocked Vision for $cycleId: '
        '${integrity.findings.map((f) => f['code']).join(', ')}',
      );
    } else if (canCallVision) {
      final started = DateTime.now();
      final raw = await vision.completeWithImageFiles(
        systemPrompt: prompt.systemText,
        userText: jsonEncode(requestPayload),
        images: [fileA!, fileB!],
      );
      latencyMs = DateTime.now().difference(started).inMilliseconds;
      httpStatus = 200;
      model = vision.visionModel;
      final parsed = parseConstructionVerifyJson(raw);
      if (parsed == null) {
        verdict = 'needs_review';
        parsedFields = {
          'verdict': 'needs_review',
          'confidence': 0,
          'summary': constructionVerifyFallbackSummary('invalid', userLanguage),
          'sameViewpoint': null,
          'progressDelta': null,
          'flags': mergeFlags(const ['schema_invalid']),
        };
      } else {
        verdict = parsed['verdict'] as String;
        final flags = List<String>.from(
          (parsed['flags'] as List?)?.map((e) => e.toString()) ?? const [],
        );
        // Soft integrity findings still travel with the Vision result.
        if (integrity != null) {
          for (final flag in integrity.flags) {
            if (!flags.contains(flag)) flags.add(flag);
          }
        }
        if (temporal['ok'] == false) {
          final reason = temporal['reason']?.toString();
          if (reason != null && reason.isNotEmpty && !flags.contains(reason)) {
            flags.add(reason);
          }
        }
        parsedFields = {
          'verdict': verdict,
          'confidence': parsed['confidence'],
          'summary': parsed['summary'],
          'sameViewpoint': parsed['sameViewpoint'],
          'progressDelta': parsed['progressDelta'],
          'flags': flags,
          'overallConclusion': parsed['overallConclusion'],
          'photoFindings': parsed['photoFindings'],
          'risks': parsed['risks'],
          'recommendations': parsed['recommendations'],
        };
      }
    } else {
      // Stub path — still tell the inspector why Vision did not run.
      final flags = <String>[];
      if (!prompt.isShipped) flags.add('prompt_not_shipped');
      if (!vision.isVisionEnabled) flags.add('vision_disabled');
      if (integrity != null) flags.addAll(integrity.flags);
      if (temporal['ok'] == false) {
        final reason = temporal['reason']?.toString();
        if (reason != null && reason.isNotEmpty) flags.add(reason);
      }
      parsedFields = {
        'verdict': 'needs_review',
        'confidence': 0,
        'summary': constructionVerifyFallbackSummary('stub', userLanguage),
        'sameViewpoint': null,
        'progressDelta': null,
        'flags': flags,
      };
    }
  } catch (error) {
    // Transport / parse / missing key: never leave the cycle stuck in analyzing.
    stderr.writeln('[construction_verify] Vision path failed: $error');
    verdict = 'stub';
    httpStatus = 0;
    model = 'none';
    final flags = <String>['verify_error'];
    if (fileA == null || fileB == null) flags.add('images_unavailable');
    if (integrity != null) flags.addAll(integrity.flags);
    parsedFields = {
      'verdict': 'needs_review',
      'confidence': 0,
      'summary': constructionVerifyFallbackSummary(
        flags.contains('images_unavailable') ? 'images' : 'failed',
        userLanguage,
      ),
      'sameViewpoint': null,
      'progressDelta': null,
      'flags': flags.toSet().toList(),
    };
  }

  recordVendorCall(
    store,
    actorUserId: actorUserId,
    projectId: cycle['projectId'] as String,
    cycleId: cycleId,
    photoAId: cycle['photoAId'] as String?,
    photoBId: cycle['photoBId'] as String?,
    prompt: prompt,
    requestPayload: requestPayload,
    responsePayload: {
      'verdict': parsedFields['verdict'],
      'confidence': parsedFields['confidence'],
      'summary': parsedFields['summary'],
      if (integrity != null) 'integrityPassed': integrity.passed,
    },
    verdict: verdict,
    httpStatus: httpStatus,
    latencyMs: latencyMs == 0 ? null : latencyMs,
    model: model,
  );

  final result = {
    // Cycle outcome stays needs_review until an inspector acts.
    'verdict': 'needs_review',
    'vendorVerdict': parsedFields['verdict'],
    'confidence': parsedFields['confidence'],
    'sameViewpoint': parsedFields['sameViewpoint'],
    'progressDelta': parsedFields['progressDelta'],
    'flags': parsedFields['flags'] ?? <String>[],
    'summary': parsedFields['summary'] ??
        constructionVerifyFallbackSummary('stub', userLanguage),
    if (parsedFields['overallConclusion'] != null)
      'overallConclusion': parsedFields['overallConclusion'],
    if (parsedFields['photoFindings'] != null)
      'photoFindings': parsedFields['photoFindings'],
    if (parsedFields['risks'] != null) 'risks': parsedFields['risks'],
    if (parsedFields['recommendations'] != null)
      'recommendations': parsedFields['recommendations'],
    'temporal': temporal,
    'normative': normative,
    if (integrity != null)
      'integrity': {
        'passed': integrity.passed,
        'findings': integrity.findings,
      },
  };
  store.completeConstructionVerify(
    cycleId: cycleId,
    result: result,
    verifyExport: buildSafeVerifyExport(
      requestPayload: requestPayload,
      parsedFields: parsedFields,
      promptVersion: prompt.id,
      model: model,
      httpStatus: httpStatus,
      latencyMs: latencyMs == 0 ? null : latencyMs,
    ),
  );
}

Future<OpenAiImageFile?> _localImageFile(String? photoUrl) async {
  final bytes = await tryReadLocalUploadBytes(photoUrl);
  if (bytes == null || bytes.isEmpty) return null;
  final filename =
      (Uri.tryParse(photoUrl ?? '')?.pathSegments.isNotEmpty ?? false)
      ? Uri.parse(photoUrl!).pathSegments.last
      : 'photo.jpg';
  return OpenAiImageFile(
    bytes: Uint8List.fromList(bytes),
    filename: filename,
  );
}
