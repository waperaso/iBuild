import 'package:ibuild_core/ibuild_core.dart';

/// Signed-in admin's org profile (`GET /developers/me`): shared [Developer]
/// plus `canPublish` / `subscriptionPriceUsd`. [raw] holds legal/subscription
/// fields read by the org screen.
class DeveloperProfile {
  const DeveloperProfile({
    required this.developer,
    required this.canPublish,
    required this.subscriptionPriceUsd,
    required this.raw,
  });

  /// The shared developer shape (id/name/logoUrl/rating/…) parsed from the
  /// same payload — see [fromJson]. `id`/`name` are the only fields required
  /// by [Developer], so this is always safe to construct.
  final Developer developer;
  final bool canPublish;
  final int subscriptionPriceUsd;
  final JsonMap raw;

  String get id => developer.id;
  String get name => developer.name;

  factory DeveloperProfile.fromJson(JsonMap json) {
    final normalized = <String, dynamic>{...json}
      ..['id'] ??= ''
      ..['name'] ??= '';
    return DeveloperProfile(
      developer: Developer.fromJson(normalized),
      canPublish: json.boolOr('canPublish'),
      subscriptionPriceUsd: json.intOr('subscriptionPriceUsd', 299),
      raw: json,
    );
  }
}
