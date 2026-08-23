import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild_core/ibuild_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ibuild_b2b/core/theme/app_theme.dart';
import 'package:ibuild_b2b/core/theme/theme_controller.dart';
import 'package:ibuild_b2b/features/admin/admin_api.dart';
import 'package:ibuild_b2b/features/platform/platform_site_photos.dart';
import 'package:ibuild_b2b/features/residence/site_photo_cycle_card.dart';
import 'package:ibuild_b2b/l10n/gen/app_localizations.dart';

class _FakeAdminApi extends AdminApi {
  _FakeAdminApi({required this.cycle, this.platformRows = const []})
    : super(Dio());

  final SitePhotoCycle cycle;
  final List<Map<String, dynamic>> platformRows;

  @override
  Future<SitePhotoCycle> sitePhotoCycle(String projectId) async => cycle;

  @override
  Future<List<Map<String, dynamic>>> platformSitePhotoCycles({
    String? status,
    String? query,
  }) async {
    if (status == null || status.isEmpty) return platformRows;
    return platformRows.where((r) => r['status'] == status).toList();
  }
}

const _phone = Size(390, 844);
const _se = Size(375, 667);

SitePhotoCycle _sampleCycle() => const SitePhotoCycle(
  id: 'spc-1',
  projectId: 'prj-1',
  status: 'awaiting_a',
  intervalDays: 14,
  canUploadA: true,
  projectName: 'Cycle Towers',
  result: {
    'verdict': 'needs_review',
    'summary': 'Submitted for review.',
    'sameViewpoint': null,
    'progressDelta': null,
    'flags': <String>[],
  },
);

Widget _wrap(Widget home, _FakeAdminApi api) {
  return ProviderScope(
    overrides: [adminApiProvider.overrideWithValue(api)],
    child: Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeControllerProvider);
        return MaterialApp(
          theme: buildAppTheme(theme.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: home),
        );
      },
    ),
  );
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('developer cycle card fits a phone and shows upload A', (
    tester,
  ) async {
    _setSurface(tester, _phone);
    final api = _FakeAdminApi(cycle: _sampleCycle());
    await tester.pumpWidget(
      _wrap(const SitePhotoCycleCard(projectId: 'prj-1'), api),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Site photos'), findsOneWidget);
    expect(find.text('Upload photo 1'), findsOneWidget);
    expect(find.text('Photo 1'), findsWidgets);
    expect(find.text('Decision'), findsOneWidget);
    expect(find.text('Check result'), findsNothing);
  });

  testWidgets('inspector card uses human copy instead of raw flags', (
    tester,
  ) async {
    _setSurface(tester, _phone);
    final api = _FakeAdminApi(
      cycle: const SitePhotoCycle(
        id: 'spc-1',
        projectId: 'prj-1',
        status: 'inspector',
        intervalDays: 14,
        projectName: 'Cycle Towers',
        result: {
          'verdict': 'needs_review',
          'vendorVerdict': 'needs_review',
          'summary': 'Photo checks passed.',
          'sameViewpoint': null,
          'progressDelta': null,
          'flags': <String>['verify_error', 'documentation_gap'],
          'integrity': {'passed': true},
        },
      ),
    );
    await tester.pumpWidget(
      _wrap(
        const SingleChildScrollView(
          child: SitePhotoCycleCard(projectId: 'prj-1', showIntro: false),
        ),
        api,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Photo checks passed.'), findsNothing);
    expect(find.text('verify_error, documentation_gap'), findsNothing);
    expect(find.textContaining('automatic check did not finish'), findsOneWidget);
    expect(find.textContaining('no capture date or location'), findsOneWidget);
    expect(find.text('AI: needs review'), findsOneWidget);
  });

  testWidgets('inspector card renders markdown and Get JSON', (tester) async {
    _setSurface(tester, _phone);
    final api = _FakeAdminApi(
      cycle: SitePhotoCycle(
        id: 'spc-1',
        projectId: 'prj-1',
        status: 'inspector',
        intervalDays: 14,
        projectName: 'Cycle Towers',
        result: const {
          'verdict': 'needs_review',
          'vendorVerdict': 'confirm',
          'summary': '## Viewpoint\n\nSame camera height.\n\n- progress visible',
          'sameViewpoint': true,
          'progressDelta': 2,
          'flags': <String>[],
        },
        verifyExport: const {
          'request': {'user_language': 'en'},
          'response': {'verdict': 'confirm'},
        },
      ),
    );
    await tester.pumpWidget(
      _wrap(
        const SingleChildScrollView(
          child: SitePhotoCycleCard(projectId: 'prj-1', showIntro: false),
        ),
        api,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('AI: confirm'), findsOneWidget);
    expect(find.text('Viewpoint'), findsOneWidget);
    expect(find.text('Get JSON'), findsOneWidget);
  });

  testWidgets('developer cycle card fits iPhone SE height', (tester) async {
    _setSurface(tester, _se);
    final api = _FakeAdminApi(cycle: _sampleCycle());
    await tester.pumpWidget(
      _wrap(
        const SingleChildScrollView(
          child: SitePhotoCycleCard(projectId: 'prj-1'),
        ),
        api,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Upload photo 1'), findsOneWidget);
  });

  testWidgets('platform site photos list and inspector dialog fit a phone', (
    tester,
  ) async {
    _setSurface(tester, _phone);
    final cycle = SitePhotoCycle(
      id: 'spc-1',
      projectId: 'prj-1',
      status: 'inspector',
      intervalDays: 14,
      projectName: 'Cycle Towers',
      developerName: 'Acme Dev',
    );
    final api = _FakeAdminApi(
      cycle: cycle,
      platformRows: [
        {
          'id': 'spc-1',
          'projectId': 'prj-1',
          'projectName': 'Cycle Towers',
          'developerName': 'Acme Dev',
          'status': 'inspector',
        },
      ],
    );
    await tester.pumpWidget(_wrap(const PlatformSitePhotos(), api));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Site photos'), findsOneWidget);
    expect(find.text('Cycle Towers'), findsOneWidget);

    await tester.tap(find.text('Cycle Towers'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });
}
