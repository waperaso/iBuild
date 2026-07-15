import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/ws_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/app_notification.dart';
import '../providers/notifications_providers.dart';

/// Notifications list. All unread notifications are marked read as soon as
/// this screen opens (rather than on the bell tap) so the badge clears the
/// moment the user has actually seen the list.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final notifications = ref.watch(notificationsProvider);
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(l10n.notificationsTitle),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(l10n.markAllRead),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.notifications_none,
                title: l10n.notificationsEmpty,
                subtitle: l10n.notificationsEmptySubtitle,
              ),
            )
          : ConstrainedBody(
              maxWidth: isDesktop ? 960 : 760,
              child: isDesktop
                  ? _DesktopNotificationGrid(notifications: notifications)
                  : _MobileNotificationList(notifications: notifications),
            ),
    );
  }
}

class _MobileNotificationList extends ConsumerWidget {
  const _MobileNotificationList({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _NotificationTile(
        notification: notifications[index],
        onTap: () => ref
            .read(notificationsProvider.notifier)
            .markRead(notifications[index].id),
      ),
    );
  }
}

class _DesktopNotificationGrid extends ConsumerWidget {
  const _DesktopNotificationGrid({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: [
        for (var i = 0; i < notifications.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _NotificationTile(
            notification: notifications[i],
            expanded: true,
            onTap: () => ref
                .read(notificationsProvider.notifier)
                .markRead(notifications[i].id),
          ),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.expanded = false,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final accent = _accentFor(notification.type, colors);

    return PressableScale(
      hoverScale: expanded ? 1.005 : 1,
      child: Material(
        color: notification.read ? colors.surface : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: EdgeInsets.all(expanded ? AppSpacing.lg : AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: notification.read
                    ? colors.outline
                    : colors.accent.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: expanded ? 48 : 40,
                  height: expanded ? 48 : 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    _iconFor(notification.type),
                    size: expanded ? 22 : 20,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style:
                                  (expanded
                                          ? textTheme.titleMedium
                                          : textTheme.titleSmall)
                                      ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _relativeTime(notification.createdAt, l10n),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        notification.body,
                        maxLines: expanded ? 4 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.inkMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.read) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentFor(WsEventType type, AppColors colors) => switch (type) {
    WsEventType.newOffer => colors.warning,
    WsEventType.leadStatusChanged => colors.accentSecondary,
    WsEventType.leadCreated => colors.success,
    _ => colors.inkMuted,
  };

  IconData _iconFor(WsEventType type) => switch (type) {
    WsEventType.leadStatusChanged => Icons.assignment_turned_in_outlined,
    WsEventType.newOffer => Icons.local_offer_outlined,
    WsEventType.leadCreated => Icons.mark_email_read_outlined,
    WsEventType.unitStatusChanged ||
    WsEventType.unitPriceChanged => Icons.apartment_outlined,
    WsEventType.constructionProgress => Icons.construction_outlined,
    WsEventType.unknown => Icons.notifications_none,
  };

  String _relativeTime(DateTime dateTime, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}
