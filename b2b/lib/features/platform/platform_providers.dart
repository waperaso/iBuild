import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_api.dart';

final platformPendingProjectsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).pendingProjects();
});

final platformPublishedProjectsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).publishedProjects();
});

final platformAllProjectsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).allProjects();
});

final platformPendingReviewsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).pendingReviews();
});

final platformPendingRentalListingsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).pendingRentalListings();
});

/// Call after a platform moderation mutation so every project roster refreshes.
void invalidatePlatformProjectLists(WidgetRef ref) {
  ref.invalidate(platformPendingProjectsProvider);
  ref.invalidate(platformPublishedProjectsProvider);
  ref.invalidate(platformAllProjectsProvider);
}
