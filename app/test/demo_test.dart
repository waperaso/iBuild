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
    for (final role in ['developer', 'contractor', 'tech', 'bank', 'admin']) {
      expect(find.byKey(Key('demo-$role')), findsOneWidget, reason: role);
    }
    expect(find.byKey(const Key('demo-strip')), findsNothing);

    await tester.tap(find.byKey(const Key('demo-contractor')));
    await tester.pumpAndSettle();
    expect(api.demoRoles, ['contractor']);
    expect(find.byKey(const Key('demo-strip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('demo-exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('demo-strip')), findsNothing);
    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });
}
