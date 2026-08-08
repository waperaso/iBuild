import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// Developer verification document for the B2C "Verified" badge.
@freezed
abstract class Document with _$Document {
  const factory Document({
    required String id,
    required String developerId,
    String? projectId,
    required DocumentType type,
    required String fileUrl,
    required DocumentStatus status,
    String? rejectReason,
    String? uploadedBy,
    DateTime? createdAt,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
}

/// Document types required for developer verification (matches server gate).
const List<DocumentType> requiredDocumentTypes = [
  DocumentType.license,
  DocumentType.constructionPermit,
  DocumentType.landRights,
  DocumentType.projectDeclaration,
];

/// Optional uploads; excluded from [requiredDocumentTypes] / approval gate.
const List<DocumentType> optionalDocumentTypes = [DocumentType.cadastre];

extension DocumentListX on List<Document> {
  /// True once every [requiredDocumentTypes] has at least one `accepted`
  /// document — matches the server-side gate on
  /// `PATCH /v1/platform/developers/:id/approve`.
  bool get isFullyVerified => requiredDocumentTypes.every(
    (type) => any((d) => d.type == type && d.status == DocumentStatus.accepted),
  );

  /// Latest document (if any) for a given [type], so a rejected-then-reuploaded
  /// document only shows its most recent status.
  Document? latestOfType(DocumentType type) {
    final matches = where((d) => d.type == type).toList();
    if (matches.isEmpty) return null;
    matches.sort(
      (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
        a.createdAt ?? DateTime(0),
      ),
    );
    return matches.first;
  }
}
