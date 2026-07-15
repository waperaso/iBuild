import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/features/units/providers/compare_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('toggle adds and removes unit ids', () {
    final notifier = container.read(compareProvider.notifier);

    notifier.toggle('unit-1');
    expect(container.read(compareProvider), ['unit-1']);
    expect(notifier.contains('unit-1'), isTrue);

    notifier.toggle('unit-1');
    expect(container.read(compareProvider), isEmpty);
    expect(notifier.contains('unit-1'), isFalse);
  });

  test('selecting a 4th unit drops the oldest selection', () {
    final notifier = container.read(compareProvider.notifier);

    notifier.toggle('unit-1');
    notifier.toggle('unit-2');
    notifier.toggle('unit-3');
    expect(container.read(compareProvider), ['unit-1', 'unit-2', 'unit-3']);

    notifier.toggle('unit-4');
    expect(container.read(compareProvider), ['unit-2', 'unit-3', 'unit-4']);
    expect(container.read(compareProvider).length, 3);
  });

  test('clear empties the selection', () {
    final notifier = container.read(compareProvider.notifier);
    notifier.toggle('unit-1');
    notifier.toggle('unit-2');

    notifier.clear();
    expect(container.read(compareProvider), isEmpty);
  });
}
