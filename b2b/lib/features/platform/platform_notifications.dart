import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/gen/app_localizations.dart';
import 'notifications_providers.dart';

IconData _iconFor(String? type) => switch (type) {
  'project_created' => Icons.add_business_outlined,
  'project_submitted' => Icons.fact_check_outlined,
  'project_updated' => Icons.edit_note_outlined,
  'document_uploaded' => Icons.description_outlined,
  'developer_submitted' => Icons.assignment_ind_outlined,
  _ => Icons.notifications_outlined,
};

String _timeAgo(AppLocalizations l10n, String? iso) {
  final createdAt = iso == null ? null : DateTime.tryParse(iso);
  if (createdAt == null) return '';
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return l10n.notificationsJustNow;
  if (diff.inMinutes < 60) return l10n.notificationsMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.notificationsHoursAgo(diff.inHours);
  return l10n.notificationsDaysAgo(diff.inDays);
}

/// System-admin notification inbox: every developer-side change that needs
/// attention — new/updated/submitted projects and uploaded verification
/// documents — pushed live over WebSocket and persisted server-side so it
/// survives reloads (see `notifications_providers.dart`).
class PlatformNotifications extends ConsumerWidget {
  const PlatformNotifications({super.key});

  void _open(BuildContext context, WidgetRef ref, Map<String, dynamic> n) {
    if (n['isRead'] != true) {
      ref.read(adminNotificationsProvider.notifier).markRead(n['id'] as String);
    }
    final projectId = n['projectId']?.toString();
    if (projectId != null && projectId.isNotEmpty) {
      context.go('/residence/project/$projectId');
      return;
    }
    if (n['targetType'] == 'document' || n['type'] == 'developer_submitted') {
      context.go('/platform');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final notificationsAsync = ref.watch(adminNotificationsProvider);
    final unread = ref.watch(unreadAdminNotificationCountProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.notificationsTitle, style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.notificationsSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0)
              PillButton(
                label: l10n.notificationsMarkAllRead,
                variant: PillButtonVariant.outline,
                onPressed: () =>
                    ref.read(adminNotificationsProvider.notifier).markAllRead(),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: unread > 0
              ? l10n.notificationsUnreadSectionTitle(unread)
              : l10n.notificationsSectionTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        notificationsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(l10n.notificationsError('$e')),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.notifications_none_outlined,
                title: l10n.notificationsEmptyTitle,
                subtitle: l10n.notificationsEmptySubtitle,
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final n in items)
                    ListTile(
                      onTap: () => _open(context, ref, n),
                      leading: CircleAvatar(
                        backgroundColor: n['isRead'] == true
                            ? colors.surfaceAlt
                            : colors.accent.withValues(alpha: 0.16),
                        child: Icon(
                          _iconFor(n['type']?.toString()),
                          size: 18,
                          color: n['isRead'] == true
                              ? colors.inkMuted
                              : colors.accent,
                        ),
                      ),
                      title: Text(
                        n['title']?.toString() ?? '',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: n['isRead'] == true
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: n['body'] != null
                          ? Text(
                              n['body'].toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Text(
                        _timeAgo(l10n, n['createdAt']?.toString()),
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
