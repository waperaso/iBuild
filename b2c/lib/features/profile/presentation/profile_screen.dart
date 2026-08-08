import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/shell_tab_scope.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../calculators/presentation/mortgage_calculator_sheet.dart';
import '../../calculators/presentation/rental_yield_calculator_sheet.dart';

/// Profile & settings, including a live palette/brightness switcher that
/// demonstrates the swappable color-schema system.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final themeState = ref.watch(themeControllerProvider);
    final themeCtrl = ref.read(themeControllerProvider.notifier);
    final locale = ref.watch(localeControllerProvider);
    final localeCtrl = ref.read(localeControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final isSignedIn = authState.value != null;
    final tabIndex = ShellTabScope.maybeOf(context);
    // Indexed stack keeps Profile mounted — refresh /users/me only when open.
    if (tabIndex == null || tabIndex == ShellTabScope.profileTabIndex) {
      ref.watch(profileRefreshProvider);
    }
    final bannedUser = authState.value?.banned == true ? authState.value : null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: authState.when(
              data: (user) => user != null
                  ? _SignedInHeader(user: user)
                  : const _GuestHeader(),
              loading: () => const _ProfileHeaderLoading(),
              error: (_, _) => const _GuestHeader(),
            ),
          ),
          if (bannedUser != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _BannedAccountCard(user: bannedUser),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.appearanceTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.darkModeLabel),
                  value: themeState.themeMode == ThemeMode.dark,
                  onChanged: (_) => themeCtrl.toggleBrightness(),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.paletteLabel),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (final p in AppPalette.values)
                            _PaletteSwatch(
                              palette: p,
                              selected: p == themeState.palette,
                              dark: themeState.themeMode == ThemeMode.dark,
                              onTap: () => themeCtrl.setPalette(p),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.languageLabel)),
                      DropdownButton<Locale>(
                        value: locale,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final l in kSupportedLocales)
                            DropdownMenuItem(
                              value: l,
                              child: Text(
                                kLanguageNames[l.languageCode] ??
                                    l.languageCode,
                              ),
                            ),
                        ],
                        onChanged: (l) {
                          if (l != null) localeCtrl.setLocale(l);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ForBusinessCard(),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.toolsSectionTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.account_balance_outlined,
            label: l10n.mortgageCalculatorAction,
            onTap: () => showMortgageCalculatorSheet(context),
          ),
          _SettingsTile(
            icon: Icons.trending_up,
            label: l10n.rentalYieldCalculatorAction,
            onTap: () => showRentalYieldCalculatorSheet(
              context,
              price: kDefaultCalculatorPriceUsd,
            ),
          ),
          _SettingsTile(
            icon: Icons.auto_awesome,
            label: l10n.quizEntryAction,
            onTap: () => context.push('/quiz'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.accountTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.tune,
            label: l10n.preferencesLabel,
            disabled: true,
          ),
          _SettingsTile(
            icon: Icons.notifications_none,
            label: l10n.notificationsLabel,
            disabled: true,
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            label: l10n.helpSupportLabel,
            disabled: true,
          ),
          _SettingsTile(
            icon: Icons.logout,
            label: l10n.signOutLabel,
            disabled: !isSignedIn,
            onTap: isSignedIn
                ? () => ref.read(authControllerProvider.notifier).signOut()
                : null,
          ),
        ],
      ),
    );
  }
}

String _roleLabel(AppLocalizations l10n, String role) {
  switch (role) {
    case UserRole.ordinaryUser:
      return l10n.accountTypeOrdinaryUser;
    default:
      return role;
  }
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: colors.accent,
          child: Icon(Icons.person, color: colors.onAccent),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name ?? l10n.signedInLabel,
                style: textTheme.titleMedium,
              ),
              Text(
                user.phone,
                style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
              Text(
                _roleLabel(l10n, user.role),
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.surfaceAlt,
              child: Icon(Icons.person_outline, color: colors.inkMuted),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.guestUser, style: textTheme.titleMedium),
                  Text(
                    l10n.signInPromptMessage,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: l10n.signIn,
          expand: true,
          onPressed: () => context.push('/login'),
        ),
      ],
    );
  }
}

/// Ban notice with reason and admin name.
class _BannedAccountCard extends StatelessWidget {
  const _BannedAccountCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      color: colors.danger.withValues(alpha: 0.08),
      border: true,
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
          if (user.banReason != null) ...[
            Text(
              l10n.accountBannedReasonLabel,
              style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: 2),
            Text(user.banReason!, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (user.bannedByName != null)
            Text(
              l10n.accountBannedByLabel(user.bannedByName!),
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
        ],
      ),
    );
  }
}

/// Link to the B2B workspace for listing inventory.
class _ForBusinessCard extends StatelessWidget {
  const _ForBusinessCard();

  Future<void> _openBusinessApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse(Env.businessUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.accent.withValues(alpha: 0.14),
            child: Icon(Icons.storefront_outlined, color: colors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.forBusinessTitle, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.forBusinessSubtitle,
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                PillButton(
                  label: l10n.forBusinessAction,
                  icon: Icons.open_in_new,
                  variant: PillButtonVariant.outline,
                  onPressed: () => _openBusinessApp(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderLoading extends StatelessWidget {
  const _ProfileHeaderLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        CircleAvatar(radius: 28, backgroundColor: colors.surfaceAlt),
        const SizedBox(width: AppSpacing.lg),
        const AppLoadingIndicator(size: 20, strokeWidth: 2),
      ],
    );
  }
}

/// Selectable palette swatch (accent + secondary preview).
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final scheme = dark ? palette.dark : palette.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.accent,
                  width: selected ? 3 : 1.5,
                ),
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ColoredBox(color: scheme.accent),
                        ),
                        Expanded(
                          child: ColoredBox(color: scheme.accentSecondary),
                        ),
                      ],
                    ),
                    if (selected)
                      Center(
                        child: Icon(
                          Icons.check,
                          size: 20,
                          color: scheme.onAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              palette.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: selected ? colors.ink : colors.inkMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          onTap: disabled ? null : onTap,
          child: Row(
            children: [
              Icon(icon, color: colors.ink, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label)),
              if (!disabled) Icon(Icons.chevron_right, color: colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
