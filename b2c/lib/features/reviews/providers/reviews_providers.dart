import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/review.dart';
import '../data/reviews_repository.dart';

/// Published reviews for one project (Konseptsiya §8). Mutations
/// (submit/flag) go straight through [reviewsRepositoryProvider] and then
/// invalidate this provider to refetch — the list is small and rarely
/// changes, so a network round-trip beats hand-rolling an optimistic cache.
final reviewsProvider = FutureProvider.autoDispose.family<List<Review>, String>(
  (ref, projectId) =>
      ref.watch(reviewsRepositoryProvider).fetchForProject(projectId),
);
