/// Canonical money is a positive `NUMERIC(18,2)` string such as `12500000.00`.
/// This parser never uses [double].
String? normalizeMoney(String raw) {
  final text = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (!RegExp(r'^(?:0|[1-9]\d*)(?:\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final whole = parts[0];
  if (whole.length > 16) return null;
  final fraction = (parts.length == 2 ? parts[1] : '').padRight(2, '0');
  if (RegExp(r'^0+$').hasMatch('$whole$fraction')) return null;
  return '$whole.$fraction';
}

const moneyZero = '0.00';
