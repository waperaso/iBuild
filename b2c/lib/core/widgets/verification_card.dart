import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../features/developer/providers/developer_providers.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'app_card.dart';

/// The B2C "Verified" badge + mandatory disclaimer (plan section 11 "Trust
/// system") shown wherever a developer's verification status matters — the
/// developer profile header and the project page's developer card.
///
/// Badge state is derived from [developerDocumentsProvider]:
/// - all 4 required document types `accepted` → green "Verified" badge.
/// - some documents on file but not all accepted yet → grey "Verification
///   in progress" badge.
/// - no documents available (none uploaded yet, or the breakdown isn't
///   reachable for a signed-out buyer) → falls back to the plain
///   `iBuildPartner` pill, no per-document breakdown.
///
/// The disclaimer itself always renders — a buyer should understand what
/// "Verified" does (and doesn't) mean before ever seeing a green badge.
class VerificationCard extends ConsumerWidget {
  const VerificationCard({super.key, required this.developerId});

  final String developerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final documentsAsync = ref.watch(developerDocumentsProvider(developerId));
    final documents = documentsAsync.value;
    final hasBreakdown = documents != null && documents.isNotEmpty;
    final isVerified = hasBreakdown && documents.isFullyVerified;

    final badgeIcon = isVerified
        ? Icons.verified
        : hasBreakdown
        ? Icons.pending_outlined
        : Icons.shield_outlined;
    final badgeColor = isVerified ? colors.success : colors.inkMuted;
    final badgeLabel = isVerified
        ? l10n.verifiedBadgeLabel
        : hasBreakdown
        ? l10n.verificationPendingBadgeLabel
        : l10n.iBuildPartner;

    return AppCard(
      border: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(badgeIcon, size: 20, color: badgeColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                badgeLabel,
                style: textTheme.titleSmall?.copyWith(color: badgeColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.verificationDisclaimer,
            style: textTheme.bodySmall?.copyWith(
              color: colors.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (hasBreakdown) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: colors.outline, height: 1),
            const SizedBox(height: AppSpacing.md),
            for (final type in requiredDocumentTypes) ...[
              _DocumentStatusRow(
                type: type,
                document: documents.latestOfType(type),
              ),
              if (type != requiredDocumentTypes.last)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _DocumentStatusRow extends StatelessWidget {
  const _DocumentStatusRow({required this.type, required this.document});

  final DocumentType type;
  final Document? document;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final status = document?.status;
    final (icon, color, label) = switch (status) {
      DocumentStatus.accepted => (
        Icons.check_circle,
        colors.success,
        status!.label(context),
      ),
      DocumentStatus.pending => (
        Icons.hourglass_top,
        colors.warning,
        status!.label(context),
      ),
      DocumentStatus.rejected => (
        Icons.cancel,
        colors.danger,
        status!.label(context),
      ),
      null => (Icons.remove_circle_outline, colors.inkMuted, l10n.documentStatusMissing),
    };

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(type.label(context), style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
