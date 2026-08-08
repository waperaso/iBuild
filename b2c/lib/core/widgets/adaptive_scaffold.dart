import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../localization/currency_controller.dart';
import '../localization/exchange_rate_provider.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../utils/formatters.dart';
import 'brand_mark.dart';
import 'language_menu.dart';
import 'nav_destinations.dart';
import 'pressable_scale.dart';
import 'shell_tab_scope.dart';

/// Width-adaptive shell: pill bottom nav on mobile; sidebar + top bar on desktop.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.navigationShell});

  /// Current index + branch navigation, provided by go_router's stateful shell.
  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return ShellTabScope(
      currentIndex: navigationShell.currentIndex,
      child: context.isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final isFullBleed = GoRouterState.of(context).uri.path.startsWith('/map');

    return Scaffold(
      body: Column(
        children: [
          if (!isFullBleed) const _MobileTopBar(),
          Expanded(child: navigationShell),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _PillBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _go,
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    // Map/search is a full-bleed surface — capping it (and stacking a top
    // bar above it) leaves huge side gutters and eats into the map, so it
    // keeps rendering edge-to-edge with no top bar.
    final isFullBleed = GoRouterState.of(context).uri.path.startsWith('/map');

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(currentIndex: navigationShell.currentIndex, onTap: _go),
          Expanded(
            child: isFullBleed
                ? navigationShell
                : Column(
                    children: [
                      _DesktopTopBar(
                        currentIndex: navigationShell.currentIndex,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppBreakpoints.maxContentWidth,
                            ),
                            child: navigationShell,
                          ),
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

/// Desktop top bar: section title + profile link.
class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final label = currentIndex >= 0 && currentIndex < kNavDestinations.length
        ? kNavDestinations[currentIndex].label(context)
        : '';

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: Row(
        children: [
          Text(label, style: textTheme.titleLarge),
          const Spacer(),
          const _CurrencyMenu(compact: true),
          const SizedBox(width: AppSpacing.md),
          const LanguageMenu(compact: true),
          const SizedBox(width: AppSpacing.md),
          PressableScale(
            child: Material(
              color: colors.surfaceAlt,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.go('/profile'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Icon(
                    Icons.person_outline,
                    size: 18,
                    color: colors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBottomNav extends StatelessWidget {
  const _PillBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < kNavDestinations.length; i++)
              Semantics(
                label: kNavDestinations[i].label(context),
                child: _NavCircle(
                  icon: kNavDestinations[i].icon,
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? colors.onAccent : colors.inkMuted,
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
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
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.xxl,
            ),
            child: Row(
              children: [
                const BrandMark(size: 36),
                const SizedBox(width: AppSpacing.md),
                Text('iBuild', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          for (var i = 0; i < kNavDestinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SidebarItem(
                destination: kNavDestinations[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
          const Spacer(),
          const _CurrencyMenu(),
          const SizedBox(height: AppSpacing.md),
          const LanguageMenu(),
          const SizedBox(height: AppSpacing.md),
          const _SidebarProfileTile(),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
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
                  destination.icon,
                  size: 20,
                  color: selected ? colors.onAccent : colors.inkMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  destination.label(context),
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

/// USD / UZS toggle in the navbar. Shows the active currency and, when UZS is
/// selected, the live USD→UZS rate fetched from exchangerate-api.com.
class _CurrencyMenu extends ConsumerWidget {
  const _CurrencyMenu({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(currencyControllerProvider);
    final currencyCtrl = ref.read(currencyControllerProvider.notifier);
    final rate = ref.watch(usdToUzsRateProvider);
    final label = kCurrencyLabels[currency] ?? currency.name.toUpperCase();
    final tooltip = l10n.exchangeRateTooltip(
      NumberFormat.compact().format(rate),
    );

    return PopupMenuButton<DisplayCurrency>(
      tooltip: tooltip,
      initialValue: currency,
      onSelected: currencyCtrl.setCurrency,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      itemBuilder: (context) => [
        for (final c in DisplayCurrency.values)
          CheckedPopupMenuItem<DisplayCurrency>(
            value: c,
            checked: c == currency,
            child: Text(kCurrencyLabels[c] ?? c.name.toUpperCase()),
          ),
      ],
      child: Material(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payments_outlined, size: 16, color: colors.inkMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(color: colors.ink),
              ),
              if (!compact) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.expand_more, size: 18, color: colors.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact header on mobile with the language picker — the main navbar affordance
/// besides the bottom pill nav.
class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(bottom: BorderSide(color: colors.outline)),
        ),
        child: Row(
          children: [
            const BrandMark(size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text('iBuild', style: textTheme.titleMedium),
            const Spacer(),
            const _CurrencyMenu(compact: true),
            const SizedBox(width: AppSpacing.sm),
            const LanguageMenu(compact: true),
          ],
        ),
      ),
    );
  }
}

/// Signed-in profile (or guest prompt) at the bottom of the desktop sidebar.
class _SidebarProfileTile extends ConsumerWidget {
  const _SidebarProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    return PressableScale(
      hoverScale: 1,
      child: Material(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => context.go(user != null ? '/profile' : '/login'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.accent,
                  child: Icon(Icons.person, size: 16, color: colors.onAccent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? l10n.guestUser,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                      Text(
                        user?.phone ?? l10n.signIn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
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
