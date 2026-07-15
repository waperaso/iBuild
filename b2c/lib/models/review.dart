/// A published project/developer review (Konseptsiya §8 "Отзывы"). Plain
/// class — server-backed, not persisted locally, so only JSON parsing is
/// needed (see `saved_search.dart`/`rental_listing.dart` for the same style).
class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.projectId,
    this.developerId,
    required this.ratingOverall,
    this.ratingLocation,
    this.ratingQuality,
    this.ratingValue,
    required this.body,
    this.status = 'published',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String projectId;
  final String? developerId;
  final int ratingOverall;
  final int? ratingLocation;
  final int? ratingQuality;
  final int? ratingValue;
  final String body;

  /// `published` | `flagged` | `removed`.
  final String status;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    userId: json['userId'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    projectId: json['projectId'] as String? ?? '',
    developerId: json['developerId'] as String?,
    ratingOverall: (json['ratingOverall'] as num?)?.toInt() ?? 5,
    ratingLocation: (json['ratingLocation'] as num?)?.toInt(),
    ratingQuality: (json['ratingQuality'] as num?)?.toInt(),
    ratingValue: (json['ratingValue'] as num?)?.toInt(),
    body: json['body'] as String? ?? '',
    status: json['status'] as String? ?? 'published',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );
}
