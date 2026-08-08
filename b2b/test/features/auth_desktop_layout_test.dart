import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ibuild_b2b/core/session_storage.dart';
import 'package:ibuild_b2b/core/theme/app_theme.dart';
import 'package:ibuild_b2b/core/theme/theme_controller.dart';
import 'package:ibuild_b2b/core/widgets/auth_hero_panel.dart';
import 'package:ibuild_b2b/features/admin/admin_api.dart';
import 'package:ibuild_b2b/features/auth/apply_screen.dart';
import 'package:ibuild_b2b/features/auth/login_screen.dart';
import 'package:ibuild_b2b/features/auth/otp_screen.dart';
import 'package:ibuild_b2b/l10n/gen/app_localizations.dart';

/// A brand-new applicant with nothing on file yet — `myDeveloper()` resolves
/// to `null` quickly so [DeveloperApplyScreen] settles on the wizard's
/// onboarding step without ever touching the network for real.
class _FreshApplicantAdminApi extends AdminApi {
  _FreshApplicantAdminApi() : super(Dio());

  @override
  Future<Map<String, dynamic>?> myDeveloper() async => null;

  @override
  Future<List<Map<String, dynamic>>> myDocuments() async => [];
}

Widget _wrap(Widget child, {AdminApi? adminApi}) {
  return ProviderScope(
    overrides: [
      if (adminApi != null) adminApiProvider.overrideWithValue(adminApi),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeControllerProvider);
        return MaterialApp(
          theme: buildAppTheme(theme.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        );
      },
    ),
  );
}

/// [DeveloperApplyScreen] briefly shows an indeterminate
/// [CircularProgressIndicator] while it bootstraps, which never stops
/// scheduling frames — `pumpAndSettle` would hang forever waiting for it, so
/// this pumps a bounded number of times instead, enough for the bootstrap's
/// awaited futures to resolve and the phase to settle on the wizard.
Future<void> _settleApplyScreen(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Without this, DeveloperApplyScreen's bootstrap awaits the real
    // (platform-channel/FFI-backed) FlutterSecureStorage, which never
    // resolves in a widget test and leaves the screen stuck on its loading
    // spinner forever.
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    globalSessionStorage = await SessionStorage.open();
  });

  tearDown(() {
    globalSessionStorage = null;
  });

  group('desktop auth hero panel', () {
    testWidgets(
      'login screen shows the hero panel once the window is desktop-wide',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(_wrap(const LoginScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(AuthHeroPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('login screen hides the hero panel on a phone-width window', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AuthHeroPanel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('otp screen shows the hero panel on a desktop-wide window', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        _wrap(const OtpScreen(phone: '+998901234567', requestId: 'req-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthHeroPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'the developer apply wizard shows the hero panel on a desktop-wide window',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          _wrap(
            const DeveloperApplyScreen(),
            adminApi: _FreshApplicantAdminApi(),
          ),
        );
        await _settleApplyScreen(tester);

        expect(find.byType(AuthHeroPanel), findsOneWidget);
        expect(find.text('Get started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'the developer apply wizard hides the hero panel on a phone-width window',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          _wrap(
            const DeveloperApplyScreen(),
            adminApi: _FreshApplicantAdminApi(),
          ),
        );
        await _settleApplyScreen(tester);

        expect(find.byType(AuthHeroPanel), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
