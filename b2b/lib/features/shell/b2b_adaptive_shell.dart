import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/b2b_brand.dart';
import '../../core/widgets/confirm_dialogs.dart';
import '../../core/widgets/demo_mode.dart';
import '../../core/widgets/locale_theme_bar.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/account_banned_panel.dart';
import '../auth/auth.dart';
import '../platform/notifications_providers.dart';

class _B2bNavItem {
  const _B2bNavItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

/// Responsive admin shell — sidebar + top bar on desktop, pill bottom nav on
/// mobile — matching the B2C app chrome with an **iBuild B2B** label.
class B2bAdaptiveShell extends ConsumerWidget {
  const B2bAdaptiveShell({super.key, required this.child});

  final Widget child;

  /// A system admin never owns a ЖК of their own — their menu is the
  /// platform-wide governance surface (dashboard, moderation queue, ЖК
  /// roster for oversight, CRM, tickets). A residence admin's menu stays
  /// exactly what it was: their own projects, org profile, and a way to
  /// reach the platform's support team.
  List<_B2bNavItem> _items(AppLocalizations l10n, AdminUser? user) {
    if (user?.isSystemAdmin == true) {
      return [
        _B2bNavItem(
          label: l10n.navPlatform,
          icon: Icons.dashboard_outlined,
          path: '/platform',
        ),
        _B2bNavItem(
          label: l10n.navModeration,
          icon: Icons.fact_check_outlined,
          path: '/platform/moderation',
        ),
        _B2bNavItem(
          label: l10n.navActiveProjects,
          icon: Icons.public_outlined,
          path: '/platform/active',
        ),
        _B2bNavItem(
          label: l10n.navResidence,
          icon: Icons.apartment_outlined,
          path: '/platform/projects',
        ),
        _B2bNavItem(
          label: l10n.navCrm,
          icon: Icons.leaderboard_outlined,
          path: '/platform/crm',
        ),
        _B2bNavItem(
          label: l10n.navTickets,
          icon: Icons.support_agent_outlined,
          path: '/platform/tickets',
        ),
        _B2bNavItem(
          label: l10n.notificationsTitle,
          icon: Icons.notifications_outlined,
          path: '/platform/notifications',
        ),
      ];
    }
    return [
      _B2bNavItem(
        label: l10n.navResidence,
        icon: Icons.apartment_outlined,
        path: '/residence',
      ),
      _B2bNavItem(
        label: l10n.navOrganization,
        icon: Icons.business_outlined,
        path: '/residence/org',
      ),
      _B2bNavItem(
        label: l10n.navTickets,
        icon: Icons.support_agent_outlined,
        path: '/support',
      ),
    ];
  }

  int _selectedIndex(String location, List<_B2bNavItem> items) {
    if (location.startsWith('/residence/project')) {
      // Shared detail screen: residence admin's own project, or a system
      // admin browsing the platform-wide ЖК roster — highlight whichever
      // "ЖК" entry this role actually has.
      final i = items.indexWhere(
        (e) => e.path == '/residence' || e.path == '/platform/projects',
      );
      return i >= 0 ? i : 0;
    }
    for (final path in [
      '/residence/org',
      '/residence',
      '/platform/moderation',
      '/platform/active',
      '/platform/projects',
      '/platform/crm',
      '/platform/tickets',
      '/platform/notifications',
      '/support',
      '/platform',
    ]) {
      if (location.startsWith(path)) {
        final i = items.indexWhere((e) => e.path == path);
        if (i >= 0) return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    // Frozen accounts only see the ban notice + sign-out (no nav / data fetch).
    if (user?.banned == true) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: AccountBannedPanel(user: user!),
      );
    }
    final items = _items(l10n, user);
    final location = GoRouterState.of(context).matchedLocation;
    final index = _selectedIndex(location, items);

    Future<void> handleSignOut() async {
      if (await confirmSignOut(context)) {
        ref.read(authControllerProvider.notifier).signOut();
      }
    }

    return context.isMobile
        ? _MobileShell(
            items: items,
            currentIndex: index,
            user: user,
            onSignOut: handleSignOut,
            child: child,
          )
        : _DesktopShell(
            items: items,
            currentIndex: index,
            user: user,
            onSignOut: handleSignOut,
            child: child,
          );
  }
}

/// Bell with an unread-count badge, shown only for system admins — the
/// admin notification inbox (`platform_notifications.dart`) is where all
/// developer-side changes and submitted documents surface for review.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAdminNotificationCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: AppLocalizations.of(context).notificationsTitle,
          onPressed: () => context.go('/platform/notifications'),
          icon: const Icon(Icons.notifications_outlined, size: 20),
        ),
        if (unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: context.colors.danger,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.items,
    required this.currentIndex,
    required this.child,
    required this.user,
    required this.onSignOut,
  });

  final List<_B2bNavItem> items;
  final int currentIndex;
  final Widget child;
  final AdminUser? user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final title = currentIndex >= 0 && currentIndex < items.length
        ? items[currentIndex].label
        : '';

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 248,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(right: BorderSide(color: colors.outline)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    bottom: AppSpacing.xxl,
                  ),
                  child: B2bBrand(),
                ),
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SidebarItem(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => context.go(items[i].path),
                    ),
                  ),
                const Spacer(),
                _ProfileTile(user: user, onSignOut: onSignOut),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    border: Border(bottom: BorderSide(color: colors.outline)),
                  ),
                  child: Row(
                    children: [
                      Text(title, style: textTheme.titleLarge),
                      const Spacer(),
                      if (user?.isSystemAdmin == true) ...[
                        const _NotificationBell(),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      const LocaleThemeBar(),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        tooltip: AppLocalizations.of(context).navSettings,
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.settings_outlined, size: 20),
                      ),
                      if (user != null) ...[
                        const SizedBox(width: AppSpacing.lg),
                        Text(
                          user!.phone,
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          Expanded(
            child: Column(
              children: [
                const DemoModeStrip(),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppBreakpoints.maxContentWidth,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.items,
    required this.currentIndex,
    required this.user,
    required this.child,
    required this.onSignOut,
  });

  final List<_B2bNavItem> items;
  final int currentIndex;
  final AdminUser? user;
  final Widget child;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(bottom: BorderSide(color: colors.outline)),
              ),
              child: Row(
                children: [
                  const B2bBrand(compact: true),
                  const Spacer(),
                  if (user?.isSystemAdmin == true) ...[
                    const _NotificationBell(),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  const LocaleThemeBar(),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: AppLocalizations.of(context).navSettings,
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.settings_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context).commonSignOut,
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const DemoModeStrip(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _PillBottomNav(
        items: items,
        currentIndex: currentIndex,
        onTap: (i) => context.go(items[i].path),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _B2bNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableScale(
      hoverScale: 1,
      child: Material(
        color: selected ? colors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? colors.onAccent : colors.inkMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? colors.onAccent : colors.ink,
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.user, required this.onSignOut});

  final AdminUser? user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      hoverScale: 1,
      child: Material(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onSignOut,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.accentSecondary,
                  child: Icon(
                    Icons.verified_user,
                    size: 16,
                    color: colors.surface,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.role ??
                            AppLocalizations.of(context).shellAdminFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                      Text(
                        user?.phone ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.logout, size: 18, color: colors.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillBottomNav extends StatelessWidget {
  const _PillBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_B2bNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;

    // Many admin tabs need tighter outer padding so icon pills stay tappable.
    final horizontalInset = items.length > 5 ? AppSpacing.sm : AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        bottom + AppSpacing.md,
      ),
      child: Material(
        color: colors.surface,
        elevation: 8,
        shadowColor: colors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  child: _NavPill(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Icon-only: no label Text under the icon (7 admin tabs don't fit).
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? colors.onAccent : colors.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
