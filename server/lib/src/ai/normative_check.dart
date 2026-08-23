/// Planned-progress note for the verify payload.
///
/// Does not score Vision deltas yet — records whether the project has a
/// planned % so inspectors see the expected baseline.
Map<String, dynamic> normativeCheck({num? plannedProgress}) {
  if (plannedProgress == null) {
    return {'ok': true, 'reason': 'no_planned_progress'};
  }
  return {
    'ok': true,
    'reason': 'planned_progress_noted',
    'plannedProgress': plannedProgress,
  };
}

Map<String, dynamic> normativePassThrough() => {
  'ok': true,
  'reason': 'passThrough',
};
