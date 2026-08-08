import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/review.dart';
import '../data/reviews_repository.dart';

/// Published reviews for one project; invalidate after submit/flag.
final reviewsProvider = FutureProvider.autoDispose.family<List<Review>, String>(
  (ref, projectId) =>
      ref.watch(reviewsRepositoryProvider).fetchForProject(projectId),
);
