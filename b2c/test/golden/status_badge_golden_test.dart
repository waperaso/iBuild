import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/core/theme/app_theme.dart';
import 'package:ibuild_client/core/theme/color_schemes/lime_scheme.dart';
import 'package:ibuild_client/core/widgets/status_badge.dart';
import 'package:ibuild_client/l10n/gen/app_localizations.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// Establishes the golden-test pattern for this app: a small, visually
/// stable, theme-sensitive widget rendered in both the light and dark
/// variants of the app's real theme (see `core/theme/app_theme.dart`).
Widget _harness({required bool dark}) {
  return MaterialApp(
    theme: buildAppTheme(dark ? limeSchemeDark : limeScheme),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            UnitStatusBadge(status: UnitStatus.available),
            UnitStatusBadge(status: UnitStatus.reserved),
            UnitStatusBadge(status: UnitStatus.sold),
            UnitStatusBadge(status: UnitStatus.blocked),
            TagBadge(label: 'Best Deal', filled: true),
            TagBadge(label: 'New build'),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('status badges - light theme', (tester) async {
    await tester.pumpWidget(_harness(dark: false));
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('golden_files/status_badges_light.png'),
    );
  });

  testWidgets('status badges - dark theme', (tester) async {
    await tester.pumpWidget(_harness(dark: true));
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('golden_files/status_badges_dark.png'),
    );
  });
}
