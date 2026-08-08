import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/features/developer/data/documents_repository.dart';
import 'package:ibuild_client/features/project/data/photo_reports_repository.dart';

/// Mock-data mode with an empty bundled catalogue.
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test(
    'DocumentsRepository returns null when no documents are bundled',
    () async {
      final repo = container.read(documentsRepositoryProvider);
      final documents = await repo.fetchDeveloperDocuments('any-dev');
      expect(documents, isNull);
    },
  );

  test(
    'PhotoReportsRepository returns an empty list when none are bundled',
    () async {
      final repo = container.read(photoReportsRepositoryProvider);
      final reports = await repo.fetchForProject('any-project');
      expect(reports, isEmpty);
    },
  );
}
