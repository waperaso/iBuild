import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/utils/redacted_phone.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/document_review_row.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/horizontal_scroll_rail.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import '../auth/auth.dart';
import 'platform_widgets.dart';

final _analyticsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).analytics();
});

final _pendingDevsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).pendingDevelopers();
});

final _usersProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).users();
});

final _businessesProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).platformBusinesses();
});

final _auditLogProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).auditLog();
});

/// Current page (0-indexed) of the audit log list — the admin flips through
/// pages themselves instead of one long, ever-growing feed being dumped on
/// screen at once.
class _AuditLogPageController extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int page) => state = page;
}

final _auditLogPageProvider = NotifierProvider<_AuditLogPageController, int>(
  _AuditLogPageController.new,
);

const _auditLogPageSize = 10;

/// Platform dashboard (KPIs, KYC, users, audit). Moderation is separate.
class PlatformHome extends ConsumerWidget {
  const PlatformHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final analytics = ref.watch(_analyticsProvider);
    final pendingDevs = ref.watch(_pendingDevsProvider);
    final users = ref.watch(_usersProvider);
    final businesses = ref.watch(_businessesProvider);
    final auditLog = ref.watch(_auditLogProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(l10n.platformTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.platformSubtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        analytics.when(
          data: (a) => HorizontalScrollRail(
            height: 132,
            itemCount: 8,
            itemBuilder: (context, index) {
              final items = [
                (Icons.people_outline, '${a['usersTotal']}', l10n.statUsers),
                (
                  Icons.apartment_outlined,
                  '${a['projectsTotal']}',
                  l10n.statProjects,
                ),
                (
                  Icons.publish_outlined,
                  '${a['publishedProjects']}',
                  l10n.statPublished,
                ),
                (Icons.inbox_outlined, '${a['leadsTotal']}', l10n.statLeads),
                (
                  Icons.pending_actions,
                  '${a['developersPending']}',
                  l10n.statAppsPending,
                ),
                (
                  Icons.fact_check_outlined,
                  '${a['projectsPending']}',
                  l10n.statProjectsPending,
                ),
                (
                  Icons.payments_outlined,
                  '${a['subscriptionsActive'] ?? 0}',
                  l10n.statPaid,
                ),
                (
                  Icons.money_off_outlined,
                  '${a['businessesUnpaid'] ?? 0}',
                  l10n.statUnpaid,
                ),
              ];
              final item = items[index];
              return StatCard(icon: item.$1, value: item.$2, label: item.$3);
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.platformAnalyticsError('$e')),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformBusinessesSectionTitle),
        const SizedBox(height: AppSpacing.md),
        businesses.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.store_outlined,
                title: l10n.platformNoBusinesses,
              );
            }
            return Column(
              children: [
                for (final d in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['name']?.toString() ?? '',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${l10n.kycInn} ${d['inn'] ?? '—'} · '
                                  '${d['verificationStatus'] ?? ''} · '
                                  '${d['directorFullName'] ?? ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: (d['canPublish'] == true)
                                  ? colors.success.withValues(alpha: 0.15)
                                  : colors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              (d['paymentStatus'] ?? 'none').toString(),
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.platformBusinessesError('$e')),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformPendingAppsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        pendingDevs.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.business_outlined,
                title: l10n.platformNoPendingApps,
              );
            }
            return Column(
              children: [
                for (final d in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      d['name']?.toString() ?? '',
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    _DeveloperStatusChip(
                                      status:
                                          d['verificationStatus']?.toString() ??
                                          'pending',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${l10n.kycInn}: ${d['inn'] ?? '—'} · '
                                  '${d['directorFullName'] ?? ''} · '
                                  '${displayPhone(l10n, d['phone']?.toString())}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                                if (d['legalName'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    d['legalName'].toString(),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PillButton(
                            label: l10n.platformViewKyc,
                            variant: PillButtonVariant.outline,
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => _KycDetailDialog(developer: d),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _DeveloperStatusMenu(
                            developerId: d['id'] as String,
                            status:
                                d['verificationStatus']?.toString() ??
                                'pending',
                            onChanged: () {
                              ref.invalidate(_pendingDevsProvider);
                              ref.invalidate(_analyticsProvider);
                              ref.invalidate(_usersProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformAuditLogSectionTitle),
        const SizedBox(height: AppSpacing.md),
        auditLog.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.history_outlined,
                title: l10n.platformNoAuditEvents,
              );
            }
            final usersById = <String, Map<String, dynamic>>{
              for (final u in users.value ?? const <Map<String, dynamic>>[])
                if (u['id'] != null) u['id'].toString(): u,
            };
            final pageCount =
                ((items.length - 1) ~/ _auditLogPageSize) + 1;
            final page = ref
                .watch(_auditLogPageProvider)
                .clamp(0, pageCount - 1);
            final pageItems = items.skip(page * _auditLogPageSize).take(
              _auditLogPageSize,
            );
            return Column(
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final entry in pageItems)
                        _AuditLogTile(
                          entry: entry,
                          actor: usersById[entry['actorUserId']?.toString()],
                        ),
                    ],
                  ),
                ),
                if (pageCount > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _AuditLogPager(
                    page: page,
                    pageCount: pageCount,
                    onPrevious: page > 0
                        ? () => ref
                              .read(_auditLogPageProvider.notifier)
                              .setPage(page - 1)
                        : null,
                    onNext: page < pageCount - 1
                        ? () => ref
                              .read(_auditLogPageProvider.notifier)
                              .setPage(page + 1)
                        : null,
                  ),
                ],
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.platformAuditError('$e')),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformUsersSectionTitle),
        const SizedBox(height: AppSpacing.md),
        users.when(
          data: (items) => AppCard(
            padding: EdgeInsets.zero,
            child: isWide
                ? DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.platformColPhone)),
                      DataColumn(label: Text(l10n.platformColRole)),
                      DataColumn(label: Text(l10n.platformColStatus)),
                      DataColumn(label: Text(l10n.platformColActions)),
                    ],
                    rows: [
                      for (final u in items)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(displayPhone(l10n, u['phone']?.toString())),
                            ),
                            DataCell(
                              Text(
                                roleLabel(l10n, u['role']?.toString() ?? ''),
                              ),
                            ),
                            DataCell(_BanStatusChip(user: u)),
                            DataCell(_UserActions(user: u)),
                          ],
                        ),
                    ],
                  )
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        _UserMobileTile(user: items[i]),
                        if (i < items.length - 1)
                          Divider(
                            height: 1,
                            indent: AppSpacing.lg,
                            endIndent: AppSpacing.lg,
                            color: context.colors.outline.withValues(alpha: 0.35),
                          ),
                      ],
                    ],
                  ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }
}

/// One row in the audit trail: what happened, on which target, and — the
/// part that used to be missing — exactly who did it (role, name and
/// phone), so a platform admin can trace any change back to a person.
class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.entry, required this.actor});

  final Map<String, dynamic> entry;
  final Map<String, dynamic>? actor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final targetLine =
        '${entry['targetType'] ?? ''} ${entry['targetId'] ?? ''}'
        '${entry['detail'] != null ? ' · ${entry['detail']}' : ''}';

    final actorName = actor?['name']?.toString().trim();
    final actorPhone = displayPhone(l10n, actor?['phone']?.toString());
    final actorRole = actor?['role']?.toString();
    final actorLine = actor == null
        ? l10n.platformAuditLogActorUnknown
        : [
            actorRole != null ? roleLabel(l10n, actorRole) : null,
            (actorName?.isNotEmpty ?? false) ? actorName : null,
            actorPhone.isNotEmpty ? actorPhone : null,
          ].whereType<String>().join(' · ');

    return ListTile(
      dense: true,
      leading: const Icon(Icons.fact_check_outlined),
      title: Text(entry['action']?.toString() ?? ''),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(targetLine),
          const SizedBox(height: 2),
          Text(
            '${l10n.platformAuditLogActorPrefix}: $actorLine',
            style: textTheme.bodySmall?.copyWith(
              color: colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: Text(
        (entry['createdAt']?.toString() ?? '').split('T').first,
        style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
      ),
    );
  }
}

/// Prev/next pager for the audit log — the admin steps through pages of at
/// most [_auditLogPageSize] entries instead of one long feed being dumped
/// on screen at once.
class _AuditLogPager extends StatelessWidget {
  const _AuditLogPager({
    required this.page,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.platformAuditLogPrevPage,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          l10n.platformAuditLogPageInfo(page + 1, pageCount),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        IconButton(
          tooltip: l10n.platformAuditLogNextPage,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// Small colored pill for a developer application's place in the review
/// pipeline (pending -> in_review -> approved/rejected).
class _DeveloperStatusChip extends StatelessWidget {
  const _DeveloperStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final color = switch (status) {
      'approved' => colors.success,
      'rejected' => colors.danger,
      'in_review' => colors.warning,
      _ => colors.inkMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        developerStatusLabel(l10n, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Developer application status transitions for platform review.
class _DeveloperStatusMenu extends ConsumerWidget {
  const _DeveloperStatusMenu({
    required this.developerId,
    required this.status,
    required this.onChanged,
  });

  final String developerId;
  final String status;
  final VoidCallback onChanged;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String next,
  ) async {
    String? reason;
    if (next == 'rejected') {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _DeclineDialog(),
      );
      if (reason == null || !context.mounted) return;
    }
    await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .setDeveloperStatus(developerId, next, reason: reason),
      onSuccess: onChanged,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.platformChangeStatusTooltip,
      onSelected: (next) => _setStatus(context, ref, next),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'pending',
          checked: status == 'pending',
          child: Text(l10n.devStatusPending),
        ),
        CheckedPopupMenuItem(
          value: 'in_review',
          checked: status == 'in_review',
          child: Text(l10n.devStatusInReview),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'approved',
          child: Text(l10n.platformStatusMenuAccept),
        ),
        PopupMenuItem(
          value: 'rejected',
          child: Text(l10n.platformStatusMenuDecline),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.platformChangeStatusTooltip,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Captures why an application is being declined — echoed back to the
/// applicant on their pending/rejected screen.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return StatefulBuilder(
      builder: (context, setState) {
        final isValid = _reasonController.text.trim().isNotEmpty;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          title: Text(l10n.platformDeclineDialogTitle),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: _reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.platformDeclineReasonLabel,
                hintText: l10n.platformDeclineReasonHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: isValid
                  ? () => Navigator.pop(context, _reasonController.text.trim())
                  : null,
              style: FilledButton.styleFrom(backgroundColor: colors.danger),
              child: Text(l10n.platformDeclineConfirm),
            ),
          ],
        );
      },
    );
  }
}

class _BanStatusChip extends StatelessWidget {
  const _BanStatusChip({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    if (user['banned'] != true) return const SizedBox.shrink();
    final reason = user['banReason']?.toString() ?? '';
    final by = user['bannedByName']?.toString() ?? '';
    return Tooltip(
      message: l10n.platformBannedTooltip(by, reason),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: colors.danger.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          l10n.platformBannedLabel,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.danger),
        ),
      ),
    );
  }
}

/// Mobile-friendly user row — avoids ListTile trailing squeezing the phone.
class _UserMobileTile extends StatelessWidget {
  const _UserMobileTile({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayPhone(l10n, user['phone']?.toString()),
            style: textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                roleLabel(l10n, user['role']?.toString() ?? ''),
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
              _BanStatusChip(user: user),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _UserActions(user: user),
        ],
      ),
    );
  }
}

/// Set-role menu + ban/unban action for a single row in "Users & roles".
class _UserActions extends ConsumerWidget {
  const _UserActions({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final isBanned = user['banned'] == true;
    final isSystemAdmin = user['role'] == 'system_admin';
    final isSelf = user['id'] == ref.watch(authControllerProvider).value?.id;
    final isMobile = context.isMobile;
    final demoMode = DemoSession.isActive;

    if (demoMode) {
      return Text(
        l10n.demoModeBanner,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.inkMuted,
        ),
      );
    }

    final setRole = MenuAnchor(
      builder: (context, controller, child) {
        return PillButton(
          label: l10n.platformSetRoleLabel,
          variant: PillButtonVariant.outline,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        for (final role in const [
          'ordinary_user',
          'residence_admin',
          'system_admin',
        ])
          MenuItemButton(
            onPressed: () async {
              await runPlatformAction(
                context,
                ref,
                action: () => ref
                    .read(adminApiProvider)
                    .setUserRole(user['id'] as String, role),
                onSuccess: () => ref.invalidate(_usersProvider),
              );
            },
            child: Text(roleLabel(l10n, role)),
          ),
      ],
    );

    final ban = PillButton(
      label: isBanned ? l10n.platformUnban : l10n.platformBan,
      variant: PillButtonVariant.outline,
      onPressed: () async {
        if (isBanned) {
          await runPlatformAction(
            context,
            ref,
            action: () => ref
                .read(adminApiProvider)
                .unbanUser(user['id'] as String),
            onSuccess: () => ref.invalidate(_usersProvider),
          );
          return;
        }
        final result = await showDialog<_BanResult>(
          context: context,
          builder: (_) => _BanDialog(user: user),
        );
        if (result == null || !context.mounted) return;
        await runPlatformAction(
          context,
          ref,
          action: () => ref.read(adminApiProvider).banUser(
            user['id'] as String,
            reason: result.reason,
            bannedByName: result.bannedByName,
          ),
          onSuccess: () => ref.invalidate(_usersProvider),
        );
      },
    );

    final deleteAdmin = isSystemAdmin
        ? IconButton(
            icon: Icon(Icons.person_remove_outlined, color: colors.danger),
            tooltip: isSelf
                ? l10n.platformDeleteAdminSelfHint
                : l10n.platformDeleteAdminTooltip,
            onPressed: isSelf
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          l10n.platformDeleteAdminConfirmTitle(
                            displayPhone(l10n, user['phone']?.toString()),
                          ),
                        ),
                        content: Text(l10n.platformDeleteAdminConfirmBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.commonCancel),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.danger,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.platformDeleteAdminConfirm),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    await runPlatformAction(
                      context,
                      ref,
                      action: () => ref
                          .read(adminApiProvider)
                          .deleteUser(user['id'] as String),
                      onSuccess: () => ref.invalidate(_usersProvider),
                    );
                  },
          )
        : null;

    if (isMobile) {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          setRole,
          ban,
          ?deleteAdmin,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        setRole,
        const SizedBox(width: AppSpacing.sm),
        ban,
        if (deleteAdmin != null) ...[
          const SizedBox(width: AppSpacing.sm),
          deleteAdmin,
        ],
      ],
    );
  }
}

class _BanResult {
  const _BanResult({required this.reason, required this.bannedByName});
  final String reason;
  final String bannedByName;
}

/// Captures the two pieces of information a ban needs: why the account is
/// being frozen, and who (by name) is imposing it — both are shown back on
/// the banned account's own profile.
class _BanDialog extends ConsumerStatefulWidget {
  const _BanDialog({required this.user});

  final Map<String, dynamic> user;

  @override
  ConsumerState<_BanDialog> createState() => _BanDialogState();
}

class _BanDialogState extends ConsumerState<_BanDialog> {
  final _reasonController = TextEditingController();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final admin = ref.read(authControllerProvider).value;
    _nameController = TextEditingController(
      text: admin?.name?.trim().isNotEmpty == true
          ? admin!.name
          : (isPhoneRedacted(admin?.phone) ? '' : admin?.phone ?? ''),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _reasonController.text.trim().isNotEmpty &&
      _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final shownPhone = displayPhone(l10n, widget.user['phone']?.toString());
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          title: Text(
            l10n.platformBanDialogTitle(
              shownPhone.isNotEmpty
                  ? shownPhone
                  : l10n.platformBanDialogUserFallback,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.platformBanDialogBody),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _reasonController,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.platformBanReasonLabel,
                    hintText: l10n.platformBanReasonHint,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.platformBanByLabel,
                    hintText: l10n.platformBanByHint,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: _isValid
                  ? () => Navigator.pop(
                      context,
                      _BanResult(
                        reason: _reasonController.text.trim(),
                        bannedByName: _nameController.text.trim(),
                      ),
                    )
                  : null,
              style: FilledButton.styleFrom(backgroundColor: colors.danger),
              child: Text(l10n.platformBanConfirm),
            ),
          ],
        );
      },
    );
  }
}

/// KYC review dialog with document accept/reject.
class _KycDetailDialog extends ConsumerStatefulWidget {
  const _KycDetailDialog({required this.developer});

  final Map<String, dynamic> developer;

  @override
  ConsumerState<_KycDetailDialog> createState() => _KycDetailDialogState();
}

class _KycDetailDialogState extends ConsumerState<_KycDetailDialog> {
  List<Map<String, dynamic>>? _documents;
  bool _loadingDocuments = true;
  String? _documentsError;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loadingDocuments = true;
      _documentsError = null;
    });
    try {
      final docs = await ref
          .read(adminApiProvider)
          .developerDocuments(widget.developer['id'] as String);
      if (mounted) setState(() => _documents = docs);
    } catch (e) {
      if (mounted) setState(() => _documentsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDocuments = false);
    }
  }

  Future<void> _accept(String documentId) async {
    await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .reviewDocument(documentId, status: 'accepted'),
      onSuccess: _loadDocuments,
    );
  }

  Future<void> _reject(String documentId) async {
    final l10n = AppLocalizations.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => NoteDialog(
        title: l10n.platformKycDocumentRejectDialogTitle,
        hint: l10n.platformKycDocumentRejectReasonHint,
        confirmLabel: l10n.platformKycDocumentReject,
      ),
    );
    if (reason == null || !mounted) return;
    await runPlatformAction(
      context,
      ref,
      action: () => ref
          .read(adminApiProvider)
          .reviewDocument(documentId, status: 'rejected', rejectReason: reason),
      onSuccess: _loadDocuments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final developer = widget.developer;
    final accountKind = developer['accountKind'];
    final fields = <(String, dynamic, String?)>[
      (l10n.kycCompanyName, developer['name'], null),
      (l10n.kycLegalName, developer['legalName'], null),
      (
        l10n.kycAccountKind,
        accountKind == null ? null : accountKindLabel(l10n, '$accountKind'),
        null,
      ),
      (l10n.kycLegalForm, developer['legalForm'], null),
      (l10n.kycInn, developer['inn'], null),
      (l10n.kycRegistrationNumber, developer['registrationNumber'], null),
      (l10n.kycOkedCode, developer['okedCode'], null),
      (l10n.kycLegalAddress, developer['legalAddress'], null),
      (l10n.kycOfficeAddress, developer['officeAddress'], null),
      (l10n.kycRegion, developer['region'], null),
      (l10n.kycEmail, developer['email'], null),
      (l10n.kycWebsite, developer['website'], null),
      (l10n.kycDirectorFullName, developer['directorFullName'], null),
      (l10n.kycDirectorPinfl, developer['directorPinfl'], null),
      (l10n.kycDirectorPassport, developer['directorPassport'], null),
      (l10n.kycDirectorPhone, developer['directorPhone'], null),
      (l10n.kycDirectorEmail, developer['directorEmail'], null),
      (l10n.kycUboDeclared, developer['uboDeclared'], l10n.kycUboHelper),
      (l10n.kycUboFullName, developer['uboFullName'], null),
      (l10n.kycConstructionLicense, developer['constructionLicense'], null),
    ];
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(l10n.platformKycTitle(developer['name']?.toString() ?? '')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, value, helper) in fields)
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 160,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  label,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.inkMuted),
                                ),
                              ),
                              if (helper != null) ...[
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: helper,
                                  triggerMode: TooltipTriggerMode.tap,
                                  showDuration: const Duration(seconds: 8),
                                  child: Icon(
                                    Icons.help_outline,
                                    size: 15,
                                    color: colors.inkMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            value.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              const Divider(height: AppSpacing.xl),
              Text(
                l10n.platformKycDocumentsTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_loadingDocuments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: LinearProgressIndicator(),
                )
              else if (_documentsError != null)
                Text(
                  l10n.platformKycDocumentsError(_documentsError!),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.danger),
                )
              else if ((_documents ?? const []).isEmpty)
                Text(
                  l10n.platformKycDocumentsEmpty,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                )
              else
                for (final doc in _documents!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: DocumentReviewRow(
                      document: doc,
                      onAccept: () => _accept(doc['id'] as String),
                      onReject: () => _reject(doc['id'] as String),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

