import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'media.dart';

part 'unit.freezed.dart';
part 'unit.g.dart';

/// Sellable/rentable unit; sale/rent fields filled per [dealType].
@freezed
abstract class Unit with _$Unit {
  const factory Unit({
    required String id,
    required String buildingId,
    required String number,
    required UnitKind kind,
    required DealType dealType,
    required UnitStatus status,
    required int floor,
    @Default(false) bool isOffplan,
    double? areaTotal,
    double? areaLiving,
    int? rooms,
    String? layout,
    // Sale
    double? price,
    double? priceM2,
    // Rent
    double? rentMonthly,
    double? rentM2,
    int? minLeaseMonths,
    String? finishing,
    String? view,
    int? planColumn,
    int? planRow,
    @Default(<MediaItem>[]) List<MediaItem> media,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}
