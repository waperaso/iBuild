import '../../l10n/gen/app_localizations.dart';

/// Localizes a `findingCode` / `evidenceCode` / `summaryCode` from
/// `POST /admin/projects/<id>/photo-reports/analyze` (plan Part 4). The full
/// code namespace for stage_1..stage_7 plus `summary.*` is documented on the
/// server's route in `server/lib/src/ai/ai_routes.dart`.
///
/// Falls back to [rawText] (the server's own free-text field) when [code] is
/// null or unrecognized, so an engine emitting a code we didn't anticipate
/// never crashes the client — it just shows the server's plain-language copy
/// (or, failing that, the raw code) instead of a localized string.
String localizeVerificationCode(
  AppLocalizations l10n,
  String? code,
  Map<String, dynamic>? params,
  String? rawText,
) {
  final p = params ?? const <String, dynamic>{};
  // Server params arrive as loosely-typed JSON — [v] renders any scalar
  // (measured ratios/scores/distances can be int or double) as display text,
  // while [vs]/[vi] coerce to the exact String/int types the generated ARB
  // getters below expect.
  Object v(String key, [Object fallback = '']) => p[key] ?? fallback;
  String vs(String key) => p[key]?.toString() ?? '';
  int vi(String key) => (p[key] as num?)?.round() ?? 0;

  switch (code) {
    // --- stage_1 : input validity ---------------------------------------
    case 'stage1.ok':
      return l10n.verifStage1Ok;
    case 'stage1.imageUnreadable':
      return l10n.verifStage1ImageUnreadable;
    case 'stage1.lowQuality':
      return l10n.verifStage1LowQuality(v('blur'), v('exposure'));
    case 'stage1.metadataMissing':
      return l10n.verifStage1MetadataMissing;
    case 'stage1.geotagMissing':
      return l10n.verifStage1GeotagMissing;
    case 'stage1.geotagFarFromObject':
      return l10n.verifStage1GeotagFarFromObject(
        v('distanceKm'),
        v('radiusKm'),
      );
    case 'stage1.dateInFuture':
      return l10n.verifStage1DateInFuture(vs('takenAt'));
    case 'stage1.dateOutsideWindow':
      return l10n.verifStage1DateOutsideWindow(
        vs('takenAt'),
        vi('windowDays'),
      );
    case 'stage1.insufficientData':
      return l10n.verifInsufficientData;
    case 'stage1.evidence.decoded':
      return l10n.verifStage1EvidenceDecoded(
        vi('width'),
        vi('height'),
        vi('bytes'),
      );
    case 'stage1.evidence.exifDate':
      return l10n.verifStage1EvidenceExifDate(vs('takenAt'));
    case 'stage1.evidence.noExif':
      return l10n.verifStage1EvidenceNoExif;
    case 'stage1.evidence.geoDistance':
      return l10n.verifStage1EvidenceGeoDistance(
        v('distanceKm'),
        v('radiusKm'),
      );
    case 'stage1.evidence.sharpness':
      return l10n.verifStage1EvidenceSharpness(v('blur'), v('threshold'));

    // --- stage_2 : duplicate detection -----------------------------------
    case 'stage2.ok':
      return l10n.verifStage2Ok;
    case 'stage2.noPriorReports':
      return l10n.verifStage2NoPriorReports;
    case 'stage2.nearDuplicate':
      return l10n.verifStage2NearDuplicate(
        v('distance'),
        vs('reportId'),
        vs('takenAt'),
      );
    case 'stage2.duplicateFound':
      return l10n.verifStage2DuplicateFound(
        v('distance'),
        vs('reportId'),
        vs('takenAt'),
      );
    case 'stage2.insufficientData':
      return l10n.verifInsufficientData;
    case 'stage2.evidence.comparedCount':
      return l10n.verifStage2EvidenceComparedCount(vi('count'));
    case 'stage2.evidence.hammingDistance':
      return l10n.verifStage2EvidenceHammingDistance(
        v('distance'),
        v('threshold'),
        vs('reportId'),
      );

    // --- stage_3 : relevance & stage classification ----------------------
    case 'stage3.ok':
      return l10n.verifStage3Ok(vs('stage'), v('confidence'));
    case 'stage3.notConstructionSite':
      return l10n.verifStage3NotConstructionSite(v('confidence'));
    case 'stage3.stageUnclear':
      return l10n.verifStage3StageUnclear(v('confidence'));
    case 'stage3.insufficientData':
      return l10n.verifInsufficientData;
    case 'stage3.evidence.classified':
      return l10n.verifStage3EvidenceClassified(vs('stage'), v('confidence'));
    case 'stage3.evidence.features':
      return l10n.verifStage3EvidenceFeatures(
        v('skyRatio'),
        v('soilRatio'),
        v('concreteRatio'),
        v('vegetationRatio'),
        v('verticalEdgeDensity'),
        v('openingPeriodicity'),
      );

    // --- stage_4 : match against declared stage --------------------------
    case 'stage4.ok':
      return l10n.verifStage4Ok(vs('declaredStage'));
    case 'stage4.noDeclaredStage':
      return l10n.verifStage4NoDeclaredStage;
    case 'stage4.adjacentStageMismatch':
      return l10n.verifStage4AdjacentStageMismatch(
        vs('declaredStage'),
        vs('detectedStage'),
      );
    case 'stage4.stageMismatch':
      return l10n.verifStage4StageMismatch(
        vs('declaredStage'),
        vs('detectedStage'),
        v('distance'),
      );
    case 'stage4.insufficientData':
      return l10n.verifInsufficientData;
    case 'stage4.evidence.comparison':
      return l10n.verifStage4EvidenceComparison(
        vs('declaredStage'),
        vs('detectedStage'),
        vi('ordinalDistance'),
      );

    // --- stage_5 : progress relative to previous report -------------------
    case 'stage5.ok':
      return l10n.verifStage5Ok(vs('previousTakenAt'));
    case 'stage5.noPreviousReport':
      return l10n.verifStage5NoPreviousReport;
    case 'stage5.noVisibleProgress':
      return l10n.verifStage5NoVisibleProgress(
        v('distance'),
        vs('previousTakenAt'),
      );
    case 'stage5.regressionDetected':
      return l10n.verifStage5RegressionDetected(
        vs('previousStage'),
        vs('detectedStage'),
      );
    case 'stage5.progressNotDeclared':
      return l10n.verifStage5ProgressNotDeclared;
    case 'stage5.insufficientData':
      return l10n.verifInsufficientData;
    case 'stage5.evidence.similarity':
      return l10n.verifStage5EvidenceSimilarity(
        v('distance'),
        v('threshold'),
        vs('previousReportId'),
        vs('previousTakenAt'),
      );
    case 'stage5.evidence.progressDelta':
      return l10n.verifStage5EvidenceProgressDelta(
        v('previousPercent'),
        v('currentPercent'),
      );
    case 'stage5.evidence.developerComment':
      return l10n.verifStage5EvidenceDeveloperComment;

    // --- stage_6 : visual risk & violation indicators ----------------------
    case 'stage6.ok':
      return l10n.verifStage6Ok;
    case 'stage6.safetyGearAbsent':
      return l10n.verifStage6SafetyGearAbsent;
    case 'stage6.structuralDamage':
      return l10n.verifStage6StructuralDamage(v('ratio'));
    case 'stage6.workStoppage':
      return l10n.verifStage6WorkStoppage;
    case 'stage6.debrisAccumulation':
      return l10n.verifStage6DebrisAccumulation(v('score'));
    case 'stage6.ambiguousIndicator':
      return l10n.verifStage6AmbiguousIndicator(vs('indicator'));
    case 'stage6.insufficientData':
      return l10n.verifInsufficientData;
    case 'stage6.evidence.hiVisRatio':
      return l10n.verifStage6EvidenceHiVisRatio(v('ratio'), v('threshold'));
    case 'stage6.evidence.crackPixels':
      return l10n.verifStage6EvidenceCrackPixels(v('ratio'), v('threshold'));
    case 'stage6.evidence.noEquipment':
      return l10n.verifStage6EvidenceNoEquipment;
    case 'stage6.evidence.debrisTexture':
      return l10n.verifStage6EvidenceDebrisTexture(v('score'));

    // --- stage_7 : final verdict -------------------------------------------
    case 'stage7.confirmed':
      return l10n.verifStage7Confirmed;
    case 'stage7.manualReview':
      return l10n.verifStage7ManualReview(vi('warnings'));
    case 'stage7.notReached':
      return l10n.verifStage7NotReached(vs('stoppedAt'));
    case 'stage7.insufficientData':
      return l10n.verifInsufficientData;
    case 'stage7.evidence.stageSummary':
      return l10n.verifStage7EvidenceStageSummary(
        vi('passed'),
        vi('warnings'),
        vi('failed'),
      );

    // --- buyer-facing summary ------------------------------------------
    case 'summary.confirmed':
      return l10n.verifSummaryConfirmed(
        vs('detectedStage'),
        v('progressPercent'),
      );
    case 'summary.manualReview':
      return l10n.verifSummaryManualReview(vs('stage'));
    case 'summary.discrepancy':
      return l10n.verifSummaryDiscrepancy(
        vs('stage'),
        vs('declaredStage'),
        vs('detectedStage'),
      );
    case 'summary.violation':
      return l10n.verifSummaryViolation(vs('stage'), vs('indicator'));

    default:
      if (rawText != null && rawText.trim().isNotEmpty) return rawText;
      return code ?? '';
  }
}
