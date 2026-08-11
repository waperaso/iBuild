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
import 'confirm_dialogs.dart';
import 'pill_button.dart';

/// Confirm document upload after a file preview.
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

  final confirmed = await showConfirmDialog(
    context: context,
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Icon(Icons.picture_as_pdf_outlined, size: 40),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$filename · $sizeLabel',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.orgDocumentConfirmSend,
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

/// Optional upload types (not required for approval).
const List<String> kOptionalDocumentTypes = ['cadastre'];

/// True when every [kRequiredDocumentTypes] entry has an upload on file.
bool hasAllRequiredDocuments(List<Map<String, dynamic>> docs) {
  final uploadedTypes = docs.map((d) => d['type']?.toString()).toSet();
  return kRequiredDocumentTypes.every(uploadedTypes.contains);
}

/// Required document types still missing, in display order (for submit UI copy).
List<String> missingRequiredDocumentTypes(List<Map<String, dynamic>> docs) {
  final uploadedTypes = docs.map((d) => d['type']?.toString()).toSet();
  return kRequiredDocumentTypes
      .where((type) => !uploadedTypes.contains(type))
      .toList();
}

/// Required/optional document rows with upload/replace (org profile + apply).
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        documentTypeLabel(l10n, type),
                        style: textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Tooltip(
                      message: documentTypeHint(l10n, type),
                      triggerMode: TooltipTriggerMode.tap,
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
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
