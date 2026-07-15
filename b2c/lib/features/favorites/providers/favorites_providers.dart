import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/favorites_repository.dart';

/// Set of favorited project IDs, restored from local (+ server) storage on
/// boot and persisted back on every change.
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    const restored = <String>{};
    _restore();
    return restored;
  }

  Future<void> _restore() async {
    final ids = await ref.read(favoritesRepositoryProvider).restore();
    if (ids.isEmpty) return;
    state = ids;
  }

  bool isFavorite(String projectId) => state.contains(projectId);

  Future<void> toggle(String projectId) async {
    final next = {...state};
    final repo = ref.read(favoritesRepositoryProvider);
    if (!next.remove(projectId)) {
      next.add(projectId);
      await repo.addRemote(projectId);
    } else {
      await repo.removeRemote(projectId);
    }
    state = next;
    await repo.persist(next);
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);
