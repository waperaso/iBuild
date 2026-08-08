import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../theme/theme_controller.dart';

/// Compact light/dark + palette picker — matches [LanguageSwitcher] pill style
/// so both sit side-by-side in shell headers and auth screens.
class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final themeState = ref.watch(themeControllerProvider);
    final themeCtrl = ref.read(themeControllerProvider.notifier);
    final isDark = themeState.themeMode == ThemeMode.dark;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: colors.outline),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.md)),
      ),
      menuChildren: [
        SizedBox(
          width: 248,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settingsAppearance,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _BrightnessChip(
                      label: l10n.settingsLightMode,
                      icon: Icons.light_mode_outlined,
                      selected: !isDark,
                      onTap: () => themeCtrl.setThemeMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _BrightnessChip(
                      label: l10n.settingsDarkShort,
                      icon: Icons.dark_mode_outlined,
                      selected: isDark,
                      onTap: () => themeCtrl.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.settingsPalette,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final palette in AppPalette.values)
                    _PaletteDot(
                      palette: palette,
                      colors: isDark ? palette.dark : palette.light,
                      selected: palette == themeState.palette,
                      onTap: () => themeCtrl.setPalette(palette),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, _) {
        return Tooltip(
          message: l10n.settingsAppearance,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      size: 16,
                      color: colors.inkMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrightnessChip extends StatelessWidget {
  const _BrightnessChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? colors.accent : colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? colors.onAccent : colors.ink,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: selected ? colors.onAccent : colors.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteDot extends StatelessWidget {
  const _PaletteDot({
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
    return Tooltip(
      message: palette.label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.accent, colors.accentSecondary],
            ),
            border: Border.all(
              color: selected ? themeColors.ink : themeColors.outline,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: selected
              ? Icon(Icons.check, size: 14, color: colors.onAccent)
              : null,
        ),
      ),
    );
  }
}
