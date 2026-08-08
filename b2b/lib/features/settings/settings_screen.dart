import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialogs.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/account_banned_panel.dart';
import '../auth/auth.dart';

/// Admin preferences: palette/dark-mode (swatch grid), language, sign-out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final themeState = ref.watch(themeControllerProvider);
    final themeCtrl = ref.read(themeControllerProvider.notifier);
    final locale = ref.watch(localeControllerProvider);
    final localeCtrl = ref.read(localeControllerProvider.notifier);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (user?.banned == true) ...[
            AccountBannedCard(user: user!),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(l10n.settingsAppearance, style: textTheme.titleMedium),
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
                  title: Text(l10n.settingsDarkMode),
                  value: themeState.themeMode == ThemeMode.dark,
                  onChanged: (_) => themeCtrl.toggleBrightness(),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
          Text(l10n.settingsPalette, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: _PaletteGrid(
              selected: themeState.palette,
              isDark: themeState.themeMode == ThemeMode.dark,
              onSelected: themeCtrl.setPalette,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.settingsAccount, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                if (user != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colors.accentSecondary,
                      child: Icon(
                        Icons.verified_user,
                        size: 18,
                        color: colors.surface,
                      ),
                    ),
                    title: Text(user.role),
                    subtitle: Text(user.phone),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout, color: colors.danger),
                  title: Text(
                    l10n.commonSignOut,
                    style: textTheme.bodyLarge?.copyWith(color: colors.danger),
                  ),
                  onTap: () async {
                    if (await confirmSignOut(context)) {
                      ref.read(authControllerProvider.notifier).signOut();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Palette swatches previewing accent + secondary on their surface.
class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid({
    required this.selected,
    required this.isDark,
    required this.onSelected,
  });

  final AppPalette selected;
  final bool isDark;
  final ValueChanged<AppPalette> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final palette in AppPalette.values)
          _PaletteSwatch(
            palette: palette,
            colors: isDark ? palette.dark : palette.light,
            selected: palette == selected,
            onTap: () => onSelected(palette),
          ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final AppColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeColors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 104,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: selected ? themeColors.ink : themeColors.outline,
                  width: selected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(AppRadii.input),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.accentSecondary,
                        borderRadius: BorderRadius.circular(AppRadii.input),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: themeColors.accent,
                    ),
                  ),
                Expanded(
                  child: Text(
                    palette.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
