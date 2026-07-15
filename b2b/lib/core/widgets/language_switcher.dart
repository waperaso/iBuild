import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/locale_controller.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import '../../l10n/gen/app_localizations.dart';

/// Compact EN/RU/UZ picker — reused on the login screen (before a session
/// exists) and in the authenticated shell's top bar / mobile header, so the
/// active language is reachable everywhere.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final locale = ref.watch(localeControllerProvider);
    return PopupMenuButton<Locale>(
      tooltip: AppLocalizations.of(context).languageLabel,
      initialValue: locale,
      onSelected: (l) =>
          ref.read(localeControllerProvider.notifier).setLocale(l),
      itemBuilder: (_) => [
        for (final l in kSupportedLocales)
          PopupMenuItem(
            value: l,
            child: Text(kLanguageNames[l.languageCode] ?? l.languageCode),
          ),
      ],
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
            Icon(Icons.language, size: 16, color: colors.inkMuted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              kLanguageShort[locale.languageCode] ?? locale.languageCode,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
