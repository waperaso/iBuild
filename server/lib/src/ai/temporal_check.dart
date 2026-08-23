/// Interval / EXIF-time gate for A→B construction photos.
///
/// Compares declared `takenAt` timestamps against the cycle interval. Soft
/// findings travel with the verify result; they do not auto-reject the cycle.
Map<String, dynamic> temporalCheck({
  DateTime? takenA,
  DateTime? takenB,
  required int intervalDays,
  int? intervalMinutes,
}) {
  if (takenA == null || takenB == null) {
    return {
      'ok': true,
      'reason': 'missing_timestamps',
    };
  }
  final a = takenA.toUtc();
  final b = takenB.toUtc();
  if (b.isBefore(a)) {
    return {
      'ok': false,
      'reason': 'b_before_a',
      'gapDays': b.difference(a).inDays,
      'expectedDays': intervalDays,
      if (intervalMinutes != null) 'expectedMinutes': intervalMinutes,
    };
  }
  // Fast / demo cycles use minute-scale gaps; do not require full days.
  if (intervalMinutes != null) {
    final gapMinutes = b.difference(a).inMinutes;
    return {
      'ok': true,
      'reason': 'interval_ok_fast',
      'gapMinutes': gapMinutes,
      'expectedMinutes': intervalMinutes,
    };
  }
  final gapDays = b.difference(a).inDays;
  if (gapDays < intervalDays) {
    return {
      'ok': false,
      'reason': 'interval_too_short',
      'gapDays': gapDays,
      'expectedDays': intervalDays,
    };
  }
  return {
    'ok': true,
    'reason': 'interval_ok',
    'gapDays': gapDays,
    'expectedDays': intervalDays,
  };
}

/// Day-3 pass-through kept for callers that have no timestamps yet.
Map<String, dynamic> temporalPassThrough() => {
  'ok': true,
  'reason': 'passThrough',
};
