import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../models/review.dart';

/// Project reviews (Konseptsiya §8) — see
/// `server/lib/src/app.dart` `/v1/projects/<id>/reviews*` and
/// `/v1/reviews/<id>/flag`.
class ReviewsRepository {
  ReviewsRepository(this._dio);

  final Dio _dio;

  Future<List<Review>> fetchForProject(String projectId) async {
    final response = await _dio.get<List<dynamic>>(
      '/projects/$projectId/reviews',
    );
    return (response.data ?? const [])
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Review> submit({
    required String projectId,
    required String body,
    int ratingOverall = 5,
    int? ratingLocation,
    int? ratingQuality,
    int? ratingValue,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/projects/$projectId/reviews',
      data: {
        'body': body,
        'ratingOverall': ratingOverall,
        'ratingLocation': ratingLocation,
        'ratingQuality': ratingQuality,
        'ratingValue': ratingValue,
      },
    );
    return Review.fromJson(response.data!);
  }

  Future<void> flag(String reviewId) => _dio.post('/reviews/$reviewId/flag');
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(apiClientProvider)),
);
