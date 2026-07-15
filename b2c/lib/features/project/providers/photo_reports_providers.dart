import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../data/photo_reports_repository.dart';

/// Photo reports for one project's construction-progress timeline (plan
/// section 11), newest-first from [PhotoReportsRepository].
final photoReportsProvider = FutureProvider.autoDispose
    .family<List<PhotoReport>, String>((ref, projectId) {
      return ref
          .watch(photoReportsRepositoryProvider)
          .fetchForProject(projectId);
    });
