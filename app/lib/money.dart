/// Monetary amounts travel as decimal strings, for example "12500000.00".
/// Decisions must not use [double] or [num] arithmetic.
String moneyAsShown(Object? raw) {
  if (raw == null) return '—';
  if (raw is num) return '—';
  final text = raw.toString().trim();
  if (text.isEmpty) return '—';
  return _grouped(text);
}

String _grouped(String canonical) {
  final parts = canonical.split('.');
  final whole = parts[0];
  final negative = whole.startsWith('-');
  final digits = negative ? whole.substring(1) : whole;
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.add(digits.substring(start, end));
  }
  final body = groups.reversed.join('\u00a0');
  final fraction = parts.length == 2 ? '.${parts[1]}' : '';
  return '${negative ? '-' : ''}$body$fraction';
}

/// Millions of UZS for the bank cabinet, for example "18 740,0".
String moneyMillions(Object? raw) {
  final cents = moneyCents(raw);
  final negative = cents.isNegative;
  // One tenth of a million is 10 000 000 cents. Round half up.
  final tenths = (cents.abs() + BigInt.from(5000000)) ~/ BigInt.from(10000000);
  final whole = (tenths ~/ BigInt.from(10)).toString();
  final fraction = (tenths % BigInt.from(10)).toString();
  final groups = <String>[];
  for (var end = whole.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.add(whole.substring(start, end));
  }
  final body = groups.reversed.join(' ');
  final zero = tenths == BigInt.zero;
  return '${negative && !zero ? '-' : ''}$body,$fraction';
}

String moneyUzs(Object? raw) {
  final shown = moneyAsShown(raw);
  if (shown == '—') return '0.00 UZS';
  return '$shown UZS';
}

/// Preview only. [usdPerSom] is the CBU rate: how many soms buy one dollar.
String moneyPreview(Object? raw, {String? usdPerSom}) {
  if (usdPerSom == null || usdPerSom.isEmpty) return moneyUzs(raw);
  final soms = moneyCents(raw);
  final rate = moneyCents(usdPerSom);
  if (rate == BigInt.zero) return moneyUzs(raw);
  final dollars = (soms * BigInt.from(100) + rate ~/ BigInt.two) ~/ rate;
  final shown = moneyAsShown(moneyFromCents(dollars));
  return shown == '—' ? '0.00 USD' : '$shown USD';
}

BigInt moneyCents(Object? raw) {
  final text = raw?.toString().trim().replaceAll('\u00a0', '').replaceAll(' ', '') ?? '';
  if (text.isEmpty || text == '—') return BigInt.zero;
  final negative = text.startsWith('-');
  final body = negative ? text.substring(1) : text;
  final parts = body.split('.');
  if (!RegExp(r'^\d+$').hasMatch(parts[0])) return BigInt.zero;
  final frac = (parts.length > 1 ? parts[1] : '').padRight(2, '0').substring(0, 2);
  if (!RegExp(r'^\d{2}$').hasMatch(frac)) return BigInt.zero;
  final cents = BigInt.parse(parts[0]) * BigInt.from(100) + BigInt.parse(frac);
  return negative ? -cents : cents;
}

String moneyFromCents(BigInt cents) {
  final negative = cents.isNegative;
  final abs = cents.abs();
  final whole = (abs ~/ BigInt.from(100)).toString();
  final frac = (abs % BigInt.from(100)).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$whole.$frac';
}

String moneySum(Iterable<Object?> values) {
  var total = BigInt.zero;
  for (final value in values) {
    total += moneyCents(value);
  }
  return moneyFromCents(total);
}

bool moneyLess(String left, String right) {
  String key(String value) {
    final parts = value.split('.');
    final whole = parts[0].replaceAll(RegExp(r'\s'), '');
    final fraction = (parts.length == 2 ? parts[1] : '').padRight(2, '0');
    return '${whole.padLeft(16, '0')}$fraction';
  }

  return key(left).compareTo(key(right)) < 0;
}
