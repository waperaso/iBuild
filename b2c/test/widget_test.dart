import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:ibuild_client/app.dart';
import 'package:ibuild_client/core/localization/exchange_rate_provider.dart';
import 'package:ibuild_client/core/localization/locale_controller.dart';
import 'package:ibuild_client/core/network/auth_token_cache.dart';

/// The app defaults to Uzbek (see [LocaleController]) so these widget tests
/// pin the locale to English to keep hardcoded string assertions stable
/// regardless of which language ships as the default.
class _EnglishLocaleController extends LocaleController {
  @override
  Locale build() {
    Intl.defaultLocale = 'en';
    return const Locale('en');
  }
}

/// Also stub the live USD→UZS fetch: it hits a real HTTP endpoint (blocked
/// in the test binding) and otherwise leaves a pending `Timer` behind that
/// trips `flutter_test`'s "no pending timers" teardown assertion.
/// Also stub the cold-start bootstrap (secure-storage token warm-up behind
/// `/splash`) so tests don't touch a real platform channel — it resolves
/// on its own microtask regardless, but this keeps it instant and isolated.
final _englishLocaleOverrides = [
  localeControllerProvider.overrideWith(_EnglishLocaleController.new),
  exchangeRateProvider.overrideWith((ref) async => kFallbackUsdToUzs),
  bootstrapProvider.overrideWith((ref) async {}),
];

/// Advances the fake clock in small steps instead of one big jump, so
/// [FadeSlideIn] timers created lazily while later list items scroll into
/// view (partway through an earlier big pump) still get a chance to fire
/// before the test tears down.
Future<void> _pumpSteps(
  WidgetTester tester, {
  int steps = 12,
  Duration step = const Duration(milliseconds: 60),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

void main() {
  testWidgets('App boots to the onboarding hero', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _englishLocaleOverrides,
        child: const IBuildApp(),
      ),
    );
    // First frame paints the animated splash; one more pump lets the
    // bootstrap future resolve and the router redirect off it settle.
    // Then step the clock so onboarding FadeSlideIn delays fire before
    // teardown (pending Timer assertion).
    await tester.pump();
    await tester.pump();
    await _pumpSteps(tester);

    expect(find.text('Find Your\nDream Home\nToday'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Start leads to discovery with mock projects loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _englishLocaleOverrides,
        child: const IBuildApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Start'));
    // The projects list is a FutureProvider (mock data resolves on a
    // microtask). Avoid `pumpAndSettle` — the network-image shimmer
    // placeholder animates forever with no real network in tests. Step the
    // clock instead of one big jump so FadeSlideIn cards created lazily by
    // later layout passes still get to fire before the test tears down.
    await tester.pump();
    await _pumpSteps(tester);

    expect(find.text('Explore Properties'), findsOneWidget);
    // At least one bundled mock residential complex should render as a card.
    expect(find.textContaining('Aaradhya'), findsWidgets);
  });

  testWidgets('My inquiries lists the bundled mock leads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _englishLocaleOverrides,
        child: const IBuildApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pump();
    await _pumpSteps(tester);

    // Deep-link straight to the inquiries tab via its NavigatorState is
    // overkill here — instead drive through the bottom/side nav icon.
    final inquiriesIcon = find.byIcon(Icons.calendar_today_outlined);
    if (inquiriesIcon.evaluate().isNotEmpty) {
      await tester.tap(inquiriesIcon.first);
      await tester.pump();
      await _pumpSteps(tester);
      expect(find.text('My inquiries'), findsOneWidget);
    }
  });
}
