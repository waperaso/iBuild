import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../env.dart';
import '../localization/status_labels.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../../l10n/gen/app_localizations.dart';
import 'app_card.dart';
import 'pill_button.dart';

/// Shows a preview of the picked file (name, size, and an image thumbnail
/// when applicable) and asks the user to confirm before it's actually sent
/// to the server — documents are never uploaded the instant a file is
/// picked; the user always gets a last look first.
Future<bool> confirmDocumentUpload(
  BuildContext context, {
  required String documentTypeLabel,
  required String filename,
  required Uint8List bytes,
}) async {
  final l10n = AppLocalizations.of(context);
  final isImage = RegExp(
    r'\.(png|jpe?g|webp|gif)$',
    caseSensitive: false,
  ).hasMatch(filename);
  final sizeLabel = _formatFileSize(bytes.length);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.orgDocumentConfirmTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.orgDocumentConfirmMessage(documentTypeLabel)),
            const SizedBox(height: AppSpacing.lg),
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Image.memory(
                  bytes,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined, size: 40),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$filename · $sizeLabel',
              style: Theme.of(ctx).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.orgDocumentConfirmSend),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// The 4 document types required before a developer can be approved (see
/// the Documents API frozen contract).
const List<String> kRequiredDocumentTypes = [
  'license',
  'construction_permit',
  'land_rights',
  'project_declaration',
];

/// Uploadable alongside the required 4, but never required for approval —
/// rendered as its own "optional" row group in [DocumentsUploadCard].
const List<String> kOptionalDocumentTypes = ['cadastre'];

/// Whether [docs] (as returned by `GET /developers/me/documents`) covers
/// every entry in [kRequiredDocumentTypes] with an actual upload — i.e. every
/// required type has *some* document on file, regardless of review status.
/// Used to gate "Submit for review" during registration (Track B.3 follow-up:
/// documents must be on file before an application can be reviewed, since
/// platform approval itself requires them accepted).
bool hasAllRequiredDocuments(List<Map<String, dynamic>> docs) {
  final uploadedTypes = docs.map((d) => d['type']?.toString()).toSet();
  return kRequiredDocumentTypes.every(uploadedTypes.contains);
}

/// Verification-documents card (Track B.3, later reused for pre-approval
/// registration): one row per required document type with its current
/// review status and an upload/replace action.
///
/// Used by both the org profile screen (post-approval) and the developer
/// apply wizard (pre-approval) — documents must be uploadable before a
/// platform moderator can approve the application at all.
class DocumentsUploadCard extends StatelessWidget {
  const DocumentsUploadCard({
    super.key,
    required this.documentsAsync,
    required this.uploadingType,
    required this.uploadProgress,
    required this.onUpload,
  });

  final AsyncValue<List<Map<String, dynamic>>> documentsAsync;
  final String? uploadingType;
  final double uploadProgress;
  final void Function(String type) onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.orgDocumentsTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.orgDocumentsSubtitle,
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          documentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(l10n.orgDocumentsError('$e')),
            data: (docs) => Column(
              children: [
                for (final type in kRequiredDocumentTypes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _DocumentRow(
                      type: type,
                      document: docs.cast<Map<String, dynamic>?>().firstWhere(
                        (d) => d?['type'] == type,
                        orElse: () => null,
                      ),
                      uploading: uploadingType == type,
                      uploadProgress: uploadProgress,
                      onUpload: () => onUpload(type),
                    ),
                  ),
                if (kOptionalDocumentTypes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.orgDocumentOptionalSectionTitle,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final type in kOptionalDocumentTypes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _DocumentRow(
                        type: type,
                        isOptional: true,
                        document: docs
                            .cast<Map<String, dynamic>?>()
                            .firstWhere(
                              (d) => d?['type'] == type,
                              orElse: () => null,
                            ),
                        uploading: uploadingType == type,
                        uploadProgress: uploadProgress,
                        onUpload: () => onUpload(type),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.type,
    required this.document,
    required this.uploading,
    required this.uploadProgress,
    required this.onUpload,
    this.isOptional = false,
  });

  final String type;
  final Map<String, dynamic>? document;
  final bool uploading;
  final double uploadProgress;
  final VoidCallback onUpload;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final status = document?['status']?.toString();
    final fileUrl = Env.resolveUrl(document?['fileUrl']?.toString());
    final rejectReason = document?['rejectReason']?.toString();

    final statusColor = switch (status) {
      'accepted' => colors.success,
      'rejected' => colors.danger,
      'pending' => colors.warning,
      _ => colors.inkMuted,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  documentTypeLabel(l10n, type),
                  style: textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  status == null
                      ? (isOptional
                            ? l10n.orgDocumentOptionalBadge
                            : l10n.orgDocumentNotUploaded)
                      : documentStatusLabel(l10n, status),
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (status == 'rejected' &&
              rejectReason != null &&
              rejectReason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.orgDocumentRejectReason(rejectReason),
              style: textTheme.bodySmall?.copyWith(color: colors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (uploading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(value: uploadProgress),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.orgDocumentUploading((uploadProgress * 100).round()),
              style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
            ),
          ] else
            Row(
              children: [
                PillButton(
                  label: status == null
                      ? l10n.orgDocumentUpload
                      : l10n.orgDocumentReplace,
                  variant: PillButtonVariant.outline,
                  onPressed: onUpload,
                ),
                if (fileUrl != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(fileUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.orgDocumentView),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
