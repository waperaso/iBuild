/// Stateless mortgage / installment / rental-yield math shared by
/// `POST /v1/calculators/*` (Konseptsiya §7 "инвестиционные калькуляторы",
/// §11.C bank referrals). Pure functions — no store, no I/O — so both the
/// route handler and tests can call them directly.
library;

import 'dart:math' as math;

/// Longest term any quote will accept, in years. Real mortgage products top
/// out well below this; the cap exists so a caller cannot ask for a term large
/// enough to matter computationally or produce meaningless output.
const kMaxTermYears = 50;

/// Standard amortizing-loan monthly payment (French amortization), the same
/// formula banks use for mortgage/installment quotes.
double monthlyPayment({
  required double loanAmount,
  required double annualRatePercent,
  required int termMonths,
}) {
  if (termMonths <= 0) return 0;
  if (annualRatePercent <= 0) return loanAmount / termMonths;
  final monthlyRate = annualRatePercent / 100 / 12;
  // math.pow is O(1); the hand-rolled loop this replaces ran once per month,
  // so a large term could pin the isolate from an unauthenticated request.
  final factor = math.pow(1 + monthlyRate, termMonths).toDouble();
  return loanAmount * monthlyRate * factor / (factor - 1);
}

class MortgageQuote {
  const MortgageQuote({
    required this.loanAmount,
    required this.downPayment,
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
    required this.termMonths,
    required this.annualRatePercent,
  });

  final double loanAmount;
  final double downPayment;
  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;
  final int termMonths;
  final double annualRatePercent;

  Map<String, dynamic> toJson() => {
    'loanAmount': loanAmount,
    'downPayment': downPayment,
    'monthlyPayment': monthlyPayment,
    'totalPayment': totalPayment,
    'totalInterest': totalInterest,
    'termMonths': termMonths,
    'annualRatePercent': annualRatePercent,
  };
}

MortgageQuote quoteMortgage({
  required double price,
  required double downPaymentPercent,
  required int termYears,
  required double annualRatePercent,
}) {
  final downPayment = price * downPaymentPercent;
  final loanAmount = price - downPayment;
  final termMonths = termYears * 12;
  final payment = monthlyPayment(
    loanAmount: loanAmount,
    annualRatePercent: annualRatePercent,
    termMonths: termMonths,
  );
  final totalPayment = payment * termMonths;
  return MortgageQuote(
    loanAmount: loanAmount,
    downPayment: downPayment,
    monthlyPayment: payment,
    totalPayment: totalPayment,
    totalInterest: totalPayment - loanAmount,
    termMonths: termMonths,
    annualRatePercent: annualRatePercent,
  );
}

class RentalYieldQuote {
  const RentalYieldQuote({
    required this.annualRent,
    required this.grossYieldPercent,
    required this.paybackYears,
    required this.pricePerM2,
    this.rentPerM2,
  });

  final double annualRent;
  final double grossYieldPercent;
  final double paybackYears;
  final double pricePerM2;
  final double? rentPerM2;

  Map<String, dynamic> toJson() => {
    'annualRent': annualRent,
    'grossYieldPercent': grossYieldPercent,
    'paybackYears': paybackYears,
    'pricePerM2': pricePerM2,
    'rentPerM2': rentPerM2,
  };
}

RentalYieldQuote quoteRentalYield({
  required double price,
  required double monthlyRent,
  double? areaTotal,
}) {
  final annualRent = monthlyRent * 12;
  final grossYield = price <= 0 ? 0.0 : (annualRent / price) * 100;
  final payback = annualRent <= 0 ? 0.0 : price / annualRent;
  return RentalYieldQuote(
    annualRent: annualRent,
    grossYieldPercent: grossYield,
    paybackYears: payback,
    pricePerM2: (areaTotal != null && areaTotal > 0) ? price / areaTotal : 0,
    rentPerM2: (areaTotal != null && areaTotal > 0)
        ? monthlyRent / areaTotal
        : null,
  );
}
