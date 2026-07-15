import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/rental_listing.dart';
import '../data/rental_listings_repository.dart';

/// Approved owner-listing feed for a given filter — used to surface
/// secondary rentals alongside developer projects in Rent mode. Listings are
/// submitted and moderated on the business side (iBuild for Business); B2C
/// only ever reads this approved feed.
final approvedRentalListingsProvider = FutureProvider.autoDispose
    .family<List<RentalListing>, RentalListingFilter>((ref, filter) async {
      final repo = ref.watch(rentalListingsRepositoryProvider);
      try {
        return await repo.fetchApproved(filter);
      } catch (_) {
        return const <RentalListing>[];
      }
    });
