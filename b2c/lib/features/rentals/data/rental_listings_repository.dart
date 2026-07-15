import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../models/rental_listing.dart';

/// Filters accepted by `GET /v1/rental-listings` (public, approved-only feed).
class RentalListingFilter {
  const RentalListingFilter({
    this.district,
    this.propertyKind,
    this.priceMax,
    this.roomsMin,
  });

  final String? district;
  final String? propertyKind;
  final double? priceMax;
  final int? roomsMin;
}

/// Owner (secondary) rental listings feed (Konseptsiya §5). Submission is a
/// business-side action performed through iBuild for Business, not from the
/// consumer app — ordinary B2C users may only browse the moderated feed and
/// place inquiries, never list their own property. See
/// `server/lib/src/app.dart` `/v1/rental-listings` route.
class RentalListingsRepository {
  RentalListingsRepository(this._dio);

  final Dio _dio;

  /// Public, moderated feed of approved listings.
  Future<List<RentalListing>> fetchApproved(RentalListingFilter filter) async {
    final response = await _dio.get<List<dynamic>>(
      '/rental-listings',
      queryParameters: {
        if (filter.district != null && filter.district!.isNotEmpty)
          'district': filter.district,
        if (filter.propertyKind != null) 'propertyKind': filter.propertyKind,
        if (filter.priceMax != null) 'priceMax': filter.priceMax,
        if (filter.roomsMin != null) 'roomsMin': filter.roomsMin,
      },
    );
    return (response.data ?? const [])
        .map((e) => RentalListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final rentalListingsRepositoryProvider = Provider<RentalListingsRepository>(
  (ref) => RentalListingsRepository(ref.watch(apiClientProvider)),
);
