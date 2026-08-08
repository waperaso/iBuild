import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import 'language_switcher.dart';
import 'theme_switcher.dart';

/// Theme (light/dark + palette) and language controls side by side.
class LocaleThemeBar extends StatelessWidget {
  const LocaleThemeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemeSwitcher(),
        SizedBox(width: AppSpacing.sm),
        LanguageSwitcher(),
      ],
    );
  }
}
