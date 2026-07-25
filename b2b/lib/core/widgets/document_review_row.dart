import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../env.dart';
import '../localization/status_labels.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../../l10n/gen/app_localizations.dart';

/// One document row in a moderation review dialog: type, status, a "View"
/// link (opens the uploaded file), and accept/reject actions when still
/// pending. Shared by the KYC review dialog and the project review dialog
/// so both present documents identically.
class DocumentReviewRow extends StatelessWidget {
  const DocumentReviewRow({
    super.key,
    required this.document,
    required this.onAccept,
    required this.onReject,
  });

  final Map<String, dynamic> document;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final type = document['type']?.toString() ?? '';
    final status = document['status']?.toString() ?? 'pending';
    final fileUrl = Env.resolveUrl(document['fileUrl']?.toString());
    final statusColor = switch (status) {
      'accepted' => colors.success,
      'rejected' => colors.danger,
      _ => colors.warning,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 18, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(documentTypeLabel(l10n, type), style: textTheme.labelLarge),
                Text(
                  documentStatusLabel(l10n, status),
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (fileUrl != null)
            IconButton(
              tooltip: l10n.platformKycDocumentView,
              iconSize: 18,
              onPressed: () =>
                  launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
            ),
          if (status == 'pending') ...[
            IconButton(
              tooltip: l10n.platformKycDocumentAccept,
              iconSize: 18,
              color: colors.success,
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline),
            ),
            IconButton(
              tooltip: l10n.platformKycDocumentReject,
              iconSize: 18,
              color: colors.danger,
              onPressed: onReject,
              icon: const Icon(Icons.cancel_outlined),
            ),
          ],
        ],
      ),
    );
  }
}
