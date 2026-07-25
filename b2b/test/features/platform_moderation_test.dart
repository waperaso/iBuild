import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ibuild_b2b/core/theme/app_theme.dart';
import 'package:ibuild_b2b/core/theme/theme_controller.dart';
import 'package:ibuild_b2b/core/widgets/section_header.dart';
import 'package:ibuild_b2b/features/admin/admin_api.dart';
import 'package:ibuild_b2b/features/platform/platform_moderation.dart';
import 'package:ibuild_b2b/l10n/gen/app_localizations.dart';

/// Records every mutation call so tests can assert on decisions/notes sent
/// to the (never actually hit) network layer, and serves canned data for the
/// lists/detail endpoints [PlatformModeration] and its review dialog read.
class FakeAdminApi extends AdminApi {
  FakeAdminApi({
    this.projects = const [],
    this.reviews = const [],
    this.rentalListings = const [],
    this.allProjectsList = const [],
    this.adminProjectDetail,
    this.documents = const [],
  }) : super(Dio());

  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> reviews;
  final List<Map<String, dynamic>> rentalListings;
  final List<Map<String, dynamic>> allProjectsList;
  final Map<String, dynamic>? adminProjectDetail;
  final List<Map<String, dynamic>> documents;

  final List<String> moderateProjectCalls = [];
  final List<String> moderateReviewCalls = [];
  final List<String> moderateRentalListingCalls = [];
  final List<String> reviewDocumentCalls = [];

  @override
  Future<List<Map<String, dynamic>>> pendingProjects() async => projects;

  @override
  Future<List<Map<String, dynamic>>> pendingReviews() async => reviews;

  @override
  Future<List<Map<String, dynamic>>> pendingRentalListings() async =>
      rentalListings;

  @override
  Future<List<Map<String, dynamic>>> allProjects() async => allProjectsList;

  @override
  Future<Map<String, dynamic>> getAdminProject(String id) async =>
      adminProjectDetail ?? {'id': id, 'buildings': <Map<String, dynamic>>[]};

  @override
  Future<List<Map<String, dynamic>>> developerDocuments(
    String developerId,
  ) async => documents;

  @override
  Future<void> moderateProject(
    String id, {
    required String decision,
    String? note,
  }) async {
    moderateProjectCalls.add(
      note == null ? '$id:$decision' : '$id:$decision:$note',
    );
  }

  @override
  Future<void> moderateReview(String id, {required bool keep}) async {
    moderateReviewCalls.add('$id:$keep');
  }

  @override
  Future<void> moderateRentalListing(
    String id, {
    required bool approve,
    String? note,
  }) async {
    moderateRentalListingCalls.add(
      note == null ? '$id:$approve' : '$id:$approve:$note',
    );
  }

  @override
  Future<void> reviewDocument(
    String id, {
    required String status,
    String? rejectReason,
  }) async {
    reviewDocumentCalls.add('$id:$status');
  }
}

Widget _wrap(FakeAdminApi fake) {
  return ProviderScope(
    overrides: [adminApiProvider.overrideWithValue(fake)],
    child: Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeControllerProvider);
        return MaterialApp(
          theme: buildAppTheme(theme.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PlatformModeration()),
        );
      },
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows empty states for all three moderation queues', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(FakeAdminApi()));
    await tester.pumpAndSettle();

    expect(find.text('No projects awaiting moderation'), findsOneWidget);
    expect(
      find.text('No rental listings awaiting moderation'),
      findsOneWidget,
    );
    expect(find.text('No reviews awaiting moderation'), findsOneWidget);
    // Projects, Rentals, and Reviews sections.
    expect(find.byType(SectionHeader), findsNWidgets(3));
  });

  testWidgets('publishing a pending project calls moderateProject(approve)', (
    tester,
  ) async {
    final fake = FakeAdminApi(
      projects: [
        {
          'id': 'prj-1',
          'name': 'Test Residence',
          'district': 'Yunusabad',
          'type': 'residential_complex',
          'developer': {'id': 'dev-1', 'name': 'Acme'},
        },
      ],
    );
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    expect(find.text('Test Residence'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(fake.moderateProjectCalls, ['prj-1:approve']);
  });

  testWidgets(
    'rejecting a pending project prompts for a note and sends it along',
    (tester) async {
      final fake = FakeAdminApi(
        projects: [
          {
            'id': 'prj-1',
            'name': 'Test Residence',
            'district': 'Yunusabad',
            'type': 'residential_complex',
            'developer': {'id': 'dev-1', 'name': 'Acme'},
          },
        ],
      );
      await tester.pumpWidget(_wrap(fake));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Missing floor plans');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
      await tester.pumpAndSettle();

      expect(fake.moderateProjectCalls, ['prj-1:reject:Missing floor plans']);
    },
  );

  testWidgets(
    'the project details dialog shows the unit breakdown and documents',
    (tester) async {
      final fake = FakeAdminApi(
        projects: [
          {
            'id': 'prj-1',
            'name': 'Test Residence',
            'district': 'Yunusabad',
            'type': 'residential_complex',
            'moderationStatus': 'pending',
            'developer': {'id': 'dev-1', 'name': 'Acme'},
          },
        ],
        adminProjectDetail: {
          'id': 'prj-1',
          'buildings': [
            {
              'id': 'b1',
              'units': [
                {'id': 'u1', 'status': 'available'},
                {'id': 'u2', 'status': 'sold'},
              ],
            },
          ],
        },
        documents: [
          {
            'id': 'doc-1',
            'type': 'license',
            'status': 'pending',
            'fileUrl': 'https://example.com/a.pdf',
          },
        ],
      );
      await tester.pumpWidget(_wrap(fake));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('1 buildings · 2 units'), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
    },
  );

  testWidgets(
    'approving a pending rental listing calls moderateRentalListing(approve: true)',
    (tester) async {
      final fake = FakeAdminApi(
        rentalListings: [
          {
            'id': 'rl-1',
            'title': 'Cozy 2-room apartment',
            'district': 'Yunusabad',
            'address': 'Amir Temur 12',
            'propertyKind': 'apartment',
            'areaTotal': 65,
            'rooms': 2,
            'rentMonthly': 4500000,
            'contactPhone': '+998901234567',
          },
        ],
      );
      await tester.pumpWidget(_wrap(fake));
      await tester.pumpAndSettle();

      expect(find.text('Cozy 2-room apartment'), findsOneWidget);
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(fake.moderateRentalListingCalls, ['rl-1:true']);
    },
  );

  testWidgets(
    'rejecting a pending rental listing prompts for a note and sends it along',
    (tester) async {
      final fake = FakeAdminApi(
        rentalListings: [
          {
            'id': 'rl-1',
            'title': 'Cozy 2-room apartment',
            'district': 'Yunusabad',
            'address': 'Amir Temur 12',
            'propertyKind': 'apartment',
            'areaTotal': 65,
            'rooms': 2,
            'rentMonthly': 4500000,
            'contactPhone': '+998901234567',
          },
        ],
      );
      await tester.pumpWidget(_wrap(fake));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fake photos');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
      await tester.pumpAndSettle();

      expect(fake.moderateRentalListingCalls, ['rl-1:false:Fake photos']);
    },
  );

  testWidgets('keeping a flagged review calls moderateReview(keep: true)', (
    tester,
  ) async {
    final fake = FakeAdminApi(
      reviews: [
        {
          'id': 'rev-1',
          'userName': 'Alice',
          'ratingOverall': 4,
          'body': 'Nice place',
          'projectId': 'prj-1',
          'createdAt': '2026-01-05T10:00:00.000Z',
        },
      ],
      allProjectsList: [
        {'id': 'prj-1', 'name': 'Test Residence'},
      ],
    );
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    expect(find.textContaining('Test Residence'), findsOneWidget);
    await tester.ensureVisible(find.text('Keep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();

    expect(fake.moderateReviewCalls, ['rev-1:true']);
  });
}
