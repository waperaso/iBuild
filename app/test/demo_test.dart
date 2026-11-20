import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  testWidgets('without the demo switched on there are no demo buttons', (tester) async {
    await pumpIBuild(tester);
    expect(find.byKey(const Key('login-button')), findsOneWidget);
    expect(find.byKey(const Key('demo-developer')), findsNothing);
  });

  testWidgets('demo buttons enter as a role and a strip says it is a demo', (tester) async {
    final api = FakeApi(demoOn: true);
    await pumpIBuildWith(tester, api);
    for (final role in ['developer', 'bank', 'admin']) {
      expect(find.byKey(Key('demo-$role')), findsOneWidget, reason: role);
    }
    // The contractor and site inspector demos are kept in the code but hidden for now.
    for (final role in ['contractor', 'tech']) {
      expect(find.byKey(Key('demo-$role')), findsNothing, reason: role);
    }
    expect(find.byKey(const Key('demo-strip')), findsNothing);

    await tester.tap(find.byKey(const Key('demo-developer')));
    await tester.pumpAndSettle();
    expect(api.demoRoles, ['developer']);
    expect(find.byKey(const Key('demo-strip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('demo-exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('demo-strip')), findsNothing);
    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });
}
