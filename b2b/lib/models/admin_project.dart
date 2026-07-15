import 'package:ibuild_core/ibuild_core.dart';

/// A residence (ЖК) / project as seen by an admin. Thin wrapper around the
/// shared [Project] model (`packages/ibuild_core`) that adds the
/// admin-/moderation-only fields the public-facing model has no business
/// knowing about (`moderationStatus`, `isPublished`, `moderationNote`).
///
/// Delegates the fields it shares with [Project] straight through, so
/// existing call sites (`p.id`, `p.name`, `p.district`, `p.address`) keep
/// working unchanged. [raw] retains the original payload so callers that
/// still need a not-yet-modelled field can read it without a second network
/// trip — the model can grow incrementally without breaking existing screens.
class AdminProject {
  const AdminProject({
    required this.project,
    required this.moderationStatus,
    required this.isPublished,
    required this.moderationNote,
    required this.raw,
  });

  /// The shared project shape (type/status/lat/lng/etc.) parsed from the
  /// same payload — see [fromJson].
  final Project project;
  final String moderationStatus;
  final bool isPublished;
  final String? moderationNote;
  final JsonMap raw;

  String get id => project.id;
  String get name => project.name;
  String get district => project.district;
  String get address => project.address;

  bool get hasPlatformWarning {
    final note = moderationNote?.trim() ?? '';
    if (note.isEmpty) return false;
    return moderationStatus == 'approved' || moderationStatus == '—';
  }

  /// Parses [json] into both the admin-only fields and, tolerantly, the
  /// shared [Project] shape: required [Project] fields (`type`, `status`,
  /// `lat`, `lng`) fall back to sane defaults if the admin endpoint's payload
  /// happens to omit them, so this never throws where the old ad-hoc parser
  /// wouldn't have either.
  factory AdminProject.fromJson(JsonMap json) {
    final normalized = <String, dynamic>{...json}
      ..['id'] ??= ''
      ..['name'] ??= ''
      ..['district'] ??= ''
      ..['address'] ??= ''
      ..['type'] ??= 'residential_complex'
      ..['status'] ??= 'under_construction'
      ..['lat'] ??= 0
      ..['lng'] ??= 0;
    return AdminProject(
      project: Project.fromJson(normalized),
      moderationStatus: json.optString('moderationStatus') ?? '—',
      isPublished: json.boolOr('isPublished'),
      moderationNote: json.optString('moderationNote'),
      raw: json,
    );
  }
}
