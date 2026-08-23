import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import 'package:ibuild_client/app.dart';
import 'package:ibuild_client/core/localization/exchange_rate_provider.dart';
import 'package:ibuild_client/core/localization/locale_controller.dart';
import 'package:ibuild_client/core/network/auth_token_cache.dart';
import 'package:ibuild_client/features/auth/data/auth_repository.dart';
import 'package:ibuild_client/features/auth/providers/auth_providers.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// Pins the locale to English so the hardcoded string assertions below stay
/// stable regardless of the shipped default (Uzbek). Mirrors the helper in
/// `test/widget_test.dart`.
class _EnglishLocaleController extends LocaleController {
  @override
  Locale build() {
    Intl.defaultLocale = 'en';
    return const Locale('en');
  }
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<void> signInAsDemo() async {
    DemoSession.activate();
    state = const AsyncData(
      AuthUser(
        id: 'demo-user-b2c',
        phone: '+998900000000',
        name: 'Demo Reviewer',
        isDemo: true,
      ),
    );
  }
}

/// The same determinism knobs `test/widget_test.dart` relies on: English copy,
/// a stubbed FX fetch (no real HTTP / dangling timers), a no-op bootstrap,
/// and a demo-capable auth controller. This must run under mock mode — pass
/// `--dart-define=USE_MOCK_DATA=true` (CI does).
final _overrides = [
  localeControllerProvider.overrideWith(_EnglishLocaleController.new),
  exchangeRateProvider.overrideWith((ref) async => kFallbackUsdToUzs),
  bootstrapProvider.overrideWith((ref) async {}),
  authControllerProvider.overrideWith(_TestAuthController.new),
];

Future<void> _pumpSteps(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _enterDemoFromOnboarding(WidgetTester tester) async {
  await tester.tap(find.text('Start (demo)'));
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('Got it').evaluate().isNotEmpty) break;
  }
  await tester.tap(find.text('Got it'));
  await tester.pump();
  await tester.pump();
}

/// Smoke flow on the mock catalogue; asserts stable text from widget_test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding -> discovery -> project detail smoke flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides, child: const IBuildApp()),
    );
    // First frame paints the splash; a couple of pumps let the (stubbed)
    // bootstrap future resolve and the router redirect to onboarding settle.
    await tester.pump();
    await tester.pump();
    await _pumpSteps(tester);

    // Onboarding hero — demo CTA (regular Start is gated off in mock mode).
    expect(find.text('Start (demo)'), findsOneWidget);

    await _enterDemoFromOnboarding(tester);
    // Mock projects resolve on a microtask via a FutureProvider; avoid
    // `pumpAndSettle` since the network-image shimmer placeholder animates
    // forever with no real network available in tests.
    await tester.pump();
    await _pumpSteps(tester);

    // Discovery screen loaded with the bundled mock catalogue.
    expect(find.text('Explore Properties'), findsOneWidget);
    final projectCards = find.textContaining('NestOne');
    expect(projectCards, findsWidgets);

    await tester.tap(projectCards.first);
    await tester.pump();
    await _pumpSteps(tester);

    // Project detail renders (its AppBar title becomes the project name).
    expect(find.textContaining('NestOne'), findsWidgets);
  });
}
