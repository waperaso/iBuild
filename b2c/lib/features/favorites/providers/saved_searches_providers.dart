import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/saved_search.dart';
import '../data/saved_searches_repository.dart';

final savedSearchesRepositoryProvider = Provider<SavedSearchesRepository>(
  (ref) => SavedSearchesRepository(),
);

/// Saved discovery filter snapshots, restored from local storage on boot and
/// persisted back on every change (see `favorites_providers.dart` for the
/// same restore/persist pattern applied to favorite project ids).
class SavedSearchesController extends Notifier<List<SavedSearch>> {
  @override
  List<SavedSearch> build() {
    const restored = <SavedSearch>[];
    _restore();
    return restored;
  }

  Future<void> _restore() async {
    final searches = await ref.read(savedSearchesRepositoryProvider).restore();
    if (searches.isEmpty) return;
    state = searches;
  }

  Future<void> add(SavedSearch search) async {
    state = [search, ...state];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _persist();
  }

  Future<void> toggleAlert(String id) async {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(notifyOnMatch: !s.notifyOnMatch) else s,
    ];
    await _persist();
  }

  Future<void> _persist() =>
      ref.read(savedSearchesRepositoryProvider).persist(state);
}

final savedSearchesProvider =
    NotifierProvider<SavedSearchesController, List<SavedSearch>>(
      SavedSearchesController.new,
    );
