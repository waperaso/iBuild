import 'package:intl/intl.dart';

/// Which currency prices are rendered in across the app.
enum DisplayCurrency { usd, uzs }

/// Presentation helpers for money, area and dates.
///
/// Currency display is driven by [Formatters.displayCurrency] and
/// [Formatters.usdToUzsRate], kept in sync by [CurrencyController] and
/// [exchangeRateProvider]. Catalog prices are stored in USD on the server, so
/// every amount passed in here is treated as canonical USD and converted once
/// for display. Editable amount fields (e.g. the mortgage calculator) work in
/// the display currency and convert back with [fromDisplay] before sending the
/// canonical USD value to the server.
abstract class Formatters {
  static DisplayCurrency displayCurrency = DisplayCurrency.uzs;
  static double usdToUzsRate = 12650;

  static NumberFormat get _usd =>
      NumberFormat.currency(symbol: r'$', decimalDigits: 0);

  /// Bare grouped integer, e.g. `403 200 000` — no symbol, so callers can place
  /// the currency label wherever it reads correctly for the locale.
  static NumberFormat get _grouped => NumberFormat.decimalPattern('uz');

  static NumberFormat get _compact => NumberFormat.compact();
  static DateFormat get _date => DateFormat('d MMM yyyy');

  /// Currency label/code shown next to an editable amount field.
  static String get currencyCode =>
      displayCurrency == DisplayCurrency.uzs ? 'soʻm' : 'USD';

  /// Converts a canonical USD amount into the active display currency value.
  static num toDisplay(num valueUsd) =>
      displayCurrency == DisplayCurrency.uzs
      ? valueUsd * usdToUzsRate
      : valueUsd;

  /// Converts a value expressed in the active display currency back to
  /// canonical USD (the unit the server and catalog store).
  static num fromDisplay(num displayValue) =>
      displayCurrency == DisplayCurrency.uzs
      ? displayValue / usdToUzsRate
      : displayValue;

  /// Formats a canonical USD [value] for display with the currency symbol in
  /// its conventional position (`$32,000` for USD, `403 200 000 soʻm` for UZS).
  static String _money(num displayValue) =>
      displayCurrency == DisplayCurrency.uzs
      ? '${_grouped.format(displayValue.round())} soʻm'
      : _usd.format(displayValue);

  /// e.g. `$32,000` or `403 200 000 soʻm`
  static String price(num value) => _money(toDisplay(value));

  /// e.g. `$63,000/m²`
  static String pricePerM2(num value) => '${_money(toDisplay(value))}/m²';

  /// e.g. `$1,500/mo`
  static String rentMonthly(num value) => '${_money(toDisplay(value))}/mo';

  /// Bare grouped amount (no symbol) for the active display currency, used to
  /// seed editable price fields. [valueUsd] is canonical USD.
  static String amountField(num valueUsd) =>
      _grouped.format(toDisplay(valueUsd).round());

  /// e.g. `21000` -> `21k`
  static String compact(num value) => _compact.format(value);

  /// e.g. `110 m²`
  static String area(num sqm) => '${sqm.toStringAsFixed(0)} m²';

  static String date(DateTime value) => _date.format(value);

  /// e.g. `Q3 2026` — used for construction completion badges.
  static String quarterYear(DateTime value) {
    final quarter = ((value.month - 1) ~/ 3) + 1;
    return 'Q$quarter ${value.year}';
  }

  /// e.g. `June 2026` (localized month name) — used to group the
  /// construction-progress photo timeline by month.
  static String monthYear(DateTime value) =>
      DateFormat.yMMMM(Intl.defaultLocale).format(value);
}
