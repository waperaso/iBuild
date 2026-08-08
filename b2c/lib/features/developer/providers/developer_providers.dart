import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../discovery/providers/discovery_providers.dart';
import '../data/documents_repository.dart';

/// A developer plus every catalogue project they built.
typedef DeveloperCatalogEntry = ({Developer developer, List<Project> projects});

/// All developers derived from the currently loaded project catalogue.
final developerCatalogProvider = Provider<Map<String, DeveloperCatalogEntry>>((
  ref,
) {
  final projects = ref.watch(projectsProvider).value;
  if (projects == null) return const {};

  final byId = <String, DeveloperCatalogEntry>{};
  for (final project in projects) {
    final dev = project.developer;
    if (dev == null) continue;
    final existing = byId[dev.id];
    if (existing == null) {
      byId[dev.id] = (developer: dev, projects: [project]);
    } else {
      byId[dev.id] = (
        developer: dev,
        projects: [...existing.projects, project],
      );
    }
  }
  return byId;
});

/// Looks up one developer (and their projects) by id from the loaded catalogue.
final developerByIdProvider = Provider.family<DeveloperCatalogEntry?, String>((
  ref,
  id,
) {
  return ref.watch(developerCatalogProvider)[id];
});

/// Verification docs for the badge breakdown; null → badge + disclaimer only.
final developerDocumentsProvider =
    FutureProvider.autoDispose.family<List<Document>?, String>((ref, id) {
      return ref.watch(documentsRepositoryProvider).fetchDeveloperDocuments(id);
    });
