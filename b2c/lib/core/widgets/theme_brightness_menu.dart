import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../theme/theme_controller.dart';

/// Light / dark theme pill (onboarding header, etc.).
class ThemeBrightnessMenu extends ConsumerWidget {
  const ThemeBrightnessMenu({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final themeState = ref.watch(themeControllerProvider);
    final themeCtrl = ref.read(themeControllerProvider.notifier);
    final isDark = themeState.themeMode == ThemeMode.dark;
    final label = isDark ? l10n.darkModeLabel : l10n.lightModeLabel;

    return PopupMenuButton<ThemeMode>(
      tooltip: l10n.appearanceTitle,
      initialValue: isDark ? ThemeMode.dark : ThemeMode.light,
      onSelected: themeCtrl.setThemeMode,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      itemBuilder: (context) => [
        CheckedPopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          checked: !isDark,
          child: Text(l10n.lightModeLabel),
        ),
        CheckedPopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          checked: isDark,
          child: Text(l10n.darkModeLabel),
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
              Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 16,
                color: colors.inkMuted,
              ),
              if (!compact) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(color: colors.ink),
                ),
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
