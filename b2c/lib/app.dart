import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/currency_controller.dart';
import 'core/localization/exchange_rate_provider.dart';
import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_scroll_behavior.dart';
import 'l10n/gen/app_localizations.dart';

/// Root widget. Wires the router, the active palette and the active
/// language into a [MaterialApp.router]; each flows reactively from its own
/// Riverpod controller ([themeControllerProvider], [localeControllerProvider]).
class IBuildApp extends ConsumerWidget {
  const IBuildApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    ref.watch(currencyControllerProvider);
    ref.watch(exchangeRateProvider);

    return MaterialApp.router(
      title: 'iBuild',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeState.themeMode,
      theme: buildAppTheme(themeState.light),
      darkTheme: buildAppTheme(themeState.dark),
      scrollBehavior: const AppScrollBehavior(),
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
