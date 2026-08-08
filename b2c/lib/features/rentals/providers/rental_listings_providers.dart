import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/rental_listing.dart';
import '../data/rental_listings_repository.dart';

/// Approved secondary rental feed for Rent mode.
final approvedRentalListingsProvider = FutureProvider.autoDispose
    .family<List<RentalListing>, RentalListingFilter>((ref, filter) async {
      final repo = ref.watch(rentalListingsRepositoryProvider);
      try {
        return await repo.fetchApproved(filter);
      } catch (_) {
        return const <RentalListing>[];
      }
    });
