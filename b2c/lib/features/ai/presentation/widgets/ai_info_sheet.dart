import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/ai_models.dart';
import 'ai_mark_badge.dart';

/// Opens the shared "about this AI feature" sheet — mobile bottom sheet,
/// desktop dialog — used by both the chat header's `(i)` button and the
/// search bar's `(i)` affordance. [quota] renders the daily-limit rows
/// (chat); [examples] renders 2–3 sample queries (search). Pass at most one.
Future<void> showAiInfoSheet(
  BuildContext context, {
  required String title,
  required String description,
  AiQuota? quota,
  List<String>? examples,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiInfoSheet(
        title: title,
        description: description,
        quota: quota,
        examples: examples,
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: context.colors.background,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AiInfoSheet(
          title: title,
          description: description,
          quota: quota,
          examples: examples,
          dialog: true,
        ),
      ),
    ),
  );
}

class AiInfoSheet extends StatelessWidget {
  const AiInfoSheet({
    super.key,
    required this.title,
    required this.description,
    this.quota,
    this.examples,
    this.dialog = false,
  });

  final String title;
  final String description;
  final AiQuota? quota;
  final List<String>? examples;
  final bool dialog;

  String _formatResetAt(DateTime resetAt) =>
      DateFormat('d MMM, HH:mm', Intl.defaultLocale).format(resetAt.toLocal());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final quotaValue = quota;
    final exampleList = examples;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dialog)
          Row(
            children: [
              const AiMarkBadge(),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: textTheme.headlineSmall)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
              ),
            ],
          )
        else ...[
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          Row(
            children: [
              const AiMarkBadge(),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: textTheme.headlineSmall)),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          description,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          color: colors.surfaceAlt,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: colors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.aiBetaNoticeTitle, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.aiBetaNoticeBody,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (quotaValue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.aiQuotaTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _QuotaRow(
            icon: Icons.forum_outlined,
            label: l10n.aiQuotaUsedLabel(quotaValue.used, quotaValue.limit),
          ),
          const SizedBox(height: AppSpacing.xs),
          _QuotaRow(
            icon: Icons.schedule,
            label: l10n.aiQuotaResetLabel(_formatResetAt(quotaValue.resetAt)),
          ),
        ],
        if (exampleList != null && exampleList.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.aiSearchInfoExamplesTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final example in exampleList)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                color: colors.surface,
                border: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  '\u201c$example\u201d',
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ],
    );

    if (dialog) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(child: content),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
        child: SingleChildScrollView(child: content),
      ),
    );
  }
}

class _QuotaRow extends StatelessWidget {
  const _QuotaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.inkMuted),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }
}
