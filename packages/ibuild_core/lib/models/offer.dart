import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'offer.freezed.dart';
part 'offer.g.dart';

@freezed
abstract class Offer with _$Offer {
  const factory Offer({
    required String id,
    required String projectId,
    required OfferType type,
    required String title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    double? downPaymentPercent,
    int? termMonths,
    double? interestRate,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
}
