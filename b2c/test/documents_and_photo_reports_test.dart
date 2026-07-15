import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/features/developer/data/documents_repository.dart';
import 'package:ibuild_client/features/project/data/photo_reports_repository.dart';
import 'package:ibuild_client/models/mock_data.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// These exercise the mock-data seam (`Env.useMockData` — see
/// `test/projects_repository_test.dart` for why `flutter test` is invoked
/// with `--dart-define=USE_MOCK_DATA=true`) for the Documents and Photo
/// Reports repositories added for the B2C verification card and
/// construction-progress timeline (plan section 11).
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test(
    'DocumentsRepository returns a fully-verified breakdown for dev-1',
    () async {
      final repo = container.read(documentsRepositoryProvider);
      final documents = await repo.fetchDeveloperDocuments('dev-1');
      expect(documents, isNotNull);
      expect(documents!.isFullyVerified, isTrue);
      for (final type in requiredDocumentTypes) {
        expect(documents.latestOfType(type)?.status, DocumentStatus.accepted);
      }
    },
  );

  test(
    'DocumentsRepository returns a partial breakdown for dev-2 (not fully verified)',
    () async {
      final repo = container.read(documentsRepositoryProvider);
      final documents = await repo.fetchDeveloperDocuments('dev-2');
      expect(documents, isNotNull);
      expect(documents!.isNotEmpty, isTrue);
      expect(documents.isFullyVerified, isFalse);
    },
  );

  test(
    'DocumentsRepository falls back to null when a developer has no documents on file',
    () async {
      final repo = container.read(documentsRepositoryProvider);
      final documents = await repo.fetchDeveloperDocuments('dev-3');
      expect(documents, isNull);
    },
  );

  test(
    'PhotoReportsRepository returns the seeded reports for an under-construction project',
    () async {
      final repo = container.read(photoReportsRepositoryProvider);
      final reports = await repo.fetchForProject('prj-1');
      expect(reports, isNotEmpty);
      expect(reports.every((r) => r.projectId == 'prj-1'), isTrue);
      expect(
        reports,
        MockData.photoReportsByProject['prj-1'],
      );
    },
  );

  test(
    'PhotoReportsRepository returns an empty list for a project with no reports yet',
    () async {
      final repo = container.read(photoReportsRepositoryProvider);
      final reports = await repo.fetchForProject('prj-2');
      expect(reports, isEmpty);
    },
  );
}
