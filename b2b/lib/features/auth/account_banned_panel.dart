import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import 'auth.dart';

/// Full-page freeze notice for a banned B2B session — reason + who banned,
/// with sign-out as the only remaining action (matches banGuardMiddleware).
class AccountBannedPanel extends ConsumerWidget {
  const AccountBannedPanel({super.key, required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppCard(
            color: colors.danger.withValues(alpha: 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.block, color: colors.danger, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.accountBannedTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.accountBannedBody,
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                if (user.banReason != null && user.banReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.accountBannedReasonLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(user.banReason!, style: textTheme.titleMedium),
                ],
                if (user.bannedByName != null &&
                    user.bannedByName!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.accountBannedByLabel(user.bannedByName!),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerRight,
                  child: PillButton(
                    label: l10n.commonSignOut,
                    variant: PillButtonVariant.ink,
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact card for Settings — same info as [AccountBannedPanel].
class AccountBannedCard extends StatelessWidget {
  const AccountBannedCard({super.key, required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      color: colors.danger.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, color: colors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.accountBannedTitle,
                  style: textTheme.titleMedium?.copyWith(color: colors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.accountBannedBody, style: textTheme.bodyMedium),
          if (user.banReason != null && user.banReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.accountBannedReasonLabel,
              style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: 2),
            Text(user.banReason!, style: textTheme.bodyMedium),
          ],
          if (user.bannedByName != null && user.bannedByName!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.accountBannedByLabel(user.bannedByName!),
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
