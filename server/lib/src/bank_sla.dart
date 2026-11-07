/// Bank time. The deadline of a stage is counted in working days of the bank:
/// Monday to Friday, 09:00 to 18:00 in Tashkent, without holidays. Time while the
/// tranche waits for the developer does not count.
library;

const bankWorkdayStartHour = 9;
const bankWorkdayEndHour = 18;
const bankWorkdayMinutes = (bankWorkdayEndHour - bankWorkdayStartHour) * 60;
const _tashkentOffset = Duration(hours: 5);

class BankInterval {
  const BankInterval(this.start, this.end);

  final DateTime start;

  /// Null while the interval is still open.
  final DateTime? end;
}

String _dayKey(DateTime local) {
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// Working minutes of the bank between two moments. Holidays are "YYYY-MM-DD".
int bankWorkingMinutes(DateTime from, DateTime to, Set<String> holidays) {
  if (!to.isAfter(from)) return 0;
  final start = from.toUtc().add(_tashkentOffset);
  final end = to.toUtc().add(_tashkentOffset);
  var total = 0;
  var day = DateTime.utc(start.year, start.month, start.day);
  final last = DateTime.utc(end.year, end.month, end.day);
  while (!day.isAfter(last)) {
    final weekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    if (!weekend && !holidays.contains(_dayKey(day))) {
      final open = day.add(const Duration(hours: bankWorkdayStartHour));
      final close = day.add(const Duration(hours: bankWorkdayEndHour));
      final from0 = start.isAfter(open) ? start : open;
      final to0 = end.isBefore(close) ? end : close;
      if (to0.isAfter(from0)) total += to0.difference(from0).inMinutes;
    }
    day = day.add(const Duration(days: 1));
  }
  return total;
}

/// Working minutes spent by the bank on the current stage: only the intervals
/// when the tranche was not at the developer and only since the stage began.
int bankStageMinutes(
  List<BankInterval> counted,
  DateTime stageStart,
  DateTime now,
  Set<String> holidays,
) {
  var total = 0;
  for (final interval in counted) {
    final from = interval.start.isAfter(stageStart) ? interval.start : stageStart;
    final to = interval.end ?? now;
    total += bankWorkingMinutes(from, to, holidays);
  }
  return total;
}

class BankElapsed {
  const BankElapsed(this.days, this.hours);

  final int days;
  final int hours;
}

BankElapsed bankElapsedOf(int minutes) {
  return BankElapsed(minutes ~/ bankWorkdayMinutes, (minutes % bankWorkdayMinutes) ~/ 60);
}
