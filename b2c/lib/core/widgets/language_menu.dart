import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../localization/locale_controller.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Language picker pill (shell header, onboarding, etc.).
class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final localeCtrl = ref.read(localeControllerProvider.notifier);
    final code = locale.languageCode;
    final label = compact
        ? (kLanguageShort[code] ?? code.toUpperCase())
        : (kLanguageNames[code] ?? code);

    return PopupMenuButton<Locale>(
      tooltip: l10n.languageLabel,
      initialValue: locale,
      onSelected: localeCtrl.setLocale,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      itemBuilder: (context) => [
        for (final l in kSupportedLocales)
          CheckedPopupMenuItem<Locale>(
            value: l,
            checked: l == locale,
            child: Text(kLanguageNames[l.languageCode] ?? l.languageCode),
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
              Icon(Icons.language, size: 16, color: colors.inkMuted),
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
