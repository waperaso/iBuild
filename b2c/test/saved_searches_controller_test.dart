import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ibuild_client/features/favorites/providers/saved_searches_providers.dart';
import 'package:ibuild_client/models/saved_search.dart';
import 'package:ibuild_core/ibuild_core.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  SavedSearch buildSearch(String id) => SavedSearch(
    id: id,
    label: '2-room · Yunusabad · under \$85k',
    mode: DiscoveryMode.buy,
    district: 'Yunusabad',
    maxPrice: 85000,
    createdAt: DateTime(2026, 1, 1),
  );

  test('add appends a saved search and persists it', () async {
    final notifier = container.read(savedSearchesProvider.notifier);

    await notifier.add(buildSearch('ss-1'));
    expect(container.read(savedSearchesProvider).map((s) => s.id), ['ss-1']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ibuild.saved_searches'), isNotNull);
  });

  test('remove drops a saved search by id', () async {
    final notifier = container.read(savedSearchesProvider.notifier);
    await notifier.add(buildSearch('ss-1'));
    await notifier.add(buildSearch('ss-2'));

    await notifier.remove('ss-1');

    expect(container.read(savedSearchesProvider).map((s) => s.id), ['ss-2']);
  });

  test('toggleAlert flips notifyOnMatch for the matching search', () async {
    final notifier = container.read(savedSearchesProvider.notifier);
    await notifier.add(buildSearch('ss-1'));
    expect(container.read(savedSearchesProvider).first.notifyOnMatch, isFalse);

    await notifier.toggleAlert('ss-1');
    expect(container.read(savedSearchesProvider).first.notifyOnMatch, isTrue);

    await notifier.toggleAlert('ss-1');
    expect(container.read(savedSearchesProvider).first.notifyOnMatch, isFalse);
  });

  test('a persisted saved search round-trips through JSON restore', () async {
    final notifier = container.read(savedSearchesProvider.notifier);
    await notifier.add(buildSearch('ss-1'));

    // A fresh container simulates an app relaunch: build() restores from
    // the same SharedPreferences-backed storage asynchronously.
    final restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);
    restoredContainer.read(savedSearchesProvider);
    await Future<void>.delayed(Duration.zero);

    expect(restoredContainer.read(savedSearchesProvider).map((s) => s.id), [
      'ss-1',
    ]);
  });
}
