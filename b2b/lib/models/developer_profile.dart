import 'package:ibuild_core/ibuild_core.dart';

/// The signed-in residence admin's own developer/organization profile
/// (`GET /developers/me`). Thin wrapper around the shared [Developer] model
/// (`packages/ibuild_core`) that adds the admin-only fields with no meaning
/// on the buyer-facing profile (`canPublish`, `subscriptionPriceUsd`).
///
/// Drives the "publishing locked" banner and the org profile screen. [raw]
/// keeps the full payload for fields the org screen reads directly (legal
/// details, subscription metadata, …).
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
