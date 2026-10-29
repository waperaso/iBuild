import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/models.dart';
import 'package:ibuild/screens/dashboard_screen.dart';

import 'support.dart';

void main() {
  testWidgets('the bank can approve a submitted request and the developer cannot', (tester) async {
    final bank = await pumpIBuild(tester, user: demoUser(AppRole.observer));
    bank.shownRequest = _submitted();
    GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/requests/req-1');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('director-approve')), findsOneWidget);

    final developer = await pumpIBuild(tester, user: demoUser(AppRole.director));
    developer.shownRequest = _submitted();
    GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/requests/req-1');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('director-approve')), findsNothing);
  });
}

FundingRequest _submitted() {
  return const FundingRequest(
    id: 'req-1',
    projectId: 'project-1',
    projectName: 'ЖК Навои',
    budgetItemId: 'line-1',
    lineTitle: 'Фундамент',
    amount: '1000.00',
    description: 'Секция Б',
    status: 'submitted',
    mine: false,
    version: 2,
    files: [],
    planSet: true,
    lineAvailable: '1000.00',
  );
}
