import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Bank-grade amortizing mortgage quote — mirrors
/// `server/lib/src/calculators.dart` `MortgageQuote`.
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

  factory MortgageQuote.fromJson(Map<String, dynamic> json) => MortgageQuote(
    loanAmount: (json['loanAmount'] as num).toDouble(),
    downPayment: (json['downPayment'] as num).toDouble(),
    monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
    totalPayment: (json['totalPayment'] as num).toDouble(),
    totalInterest: (json['totalInterest'] as num).toDouble(),
    termMonths: (json['termMonths'] as num).toInt(),
    annualRatePercent: (json['annualRatePercent'] as num).toDouble(),
  );
}

/// Rental-yield / investment quote — mirrors `RentalYieldQuote`.
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

  factory RentalYieldQuote.fromJson(Map<String, dynamic> json) =>
      RentalYieldQuote(
        annualRent: (json['annualRent'] as num).toDouble(),
        grossYieldPercent: (json['grossYieldPercent'] as num).toDouble(),
        paybackYears: (json['paybackYears'] as num).toDouble(),
        pricePerM2: (json['pricePerM2'] as num).toDouble(),
        rentPerM2: (json['rentPerM2'] as num?)?.toDouble(),
      );
}

/// Investment calculators (Konseptsiya §7, §11.C) and bank-partner referral
/// submission — see `server/lib/src/app.dart` `/v1/calculators/*` and
/// `/v1/mortgage-referrals`.
class CalculatorsRepository {
  CalculatorsRepository(this._dio);

  final Dio _dio;

  Future<MortgageQuote> mortgageQuote({
    required double price,
    required double downPaymentPercent,
    required int termYears,
    required double annualRatePercent,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/calculators/mortgage',
      data: {
        'price': price,
        'downPaymentPercent': downPaymentPercent,
        'termYears': termYears,
        'annualRatePercent': annualRatePercent,
      },
    );
    return MortgageQuote.fromJson(response.data!);
  }

  Future<RentalYieldQuote> rentalYieldQuote({
    required double price,
    required double monthlyRent,
    double? areaTotal,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/calculators/rental-yield',
      data: {
        'price': price,
        'monthlyRent': monthlyRent,
        'areaTotal': areaTotal,
      },
    );
    return RentalYieldQuote.fromJson(response.data!);
  }

  /// Submits a mortgage-consultation lead to a bank partner (requires
  /// explicit user consent in the UI before calling this).
  Future<String> submitMortgageReferral({
    required double price,
    required double downPayment,
    required int termYears,
    required String contactPhone,
    String? projectId,
    String? unitId,
    String? bankName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/mortgage-referrals',
      data: {
        'price': price,
        'downPayment': downPayment,
        'termYears': termYears,
        'contactPhone': contactPhone,
        'projectId': projectId,
        'unitId': unitId,
        'bankName': bankName,
      },
    );
    return response.data!['message'] as String? ?? '';
  }
}

final calculatorsRepositoryProvider = Provider<CalculatorsRepository>(
  (ref) => CalculatorsRepository(ref.watch(apiClientProvider)),
);
