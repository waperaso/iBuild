import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

UserProfile _bankUser() {
  return UserProfile(
    id: 'user-bank',
    name: 'Д. Рахимов',
    login: 'a.observer',
    companyId: 'company-1',
    companyName: 'Навои Девелопмент',
    active: true,
    memberships: const [Membership(projectId: 'project-1', role: AppRole.observer)],
    bank: const BankProfile(
      id: 'bank-1',
      name: 'Банк Навои',
      department: 'отдел проектного финансирования',
      role: 'specialist',
      title: 'Кредитный специалист',
      branch: 'Ташкент',
      queueCount: 2,
      trancheCount: 12,
      waitingAmount: '18740000000.00',
    ),
  );
}

void main() {
  testWidgets('director can open create, contractor can open a new request', (
    tester,
  ) async {
    await pumpIBuild(tester, user: demoUser(AppRole.director));
    expect(find.byKey(const Key('create-project')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-request')), findsOneWidget);

    await pumpIBuild(tester, user: demoUser(AppRole.contractor));
    expect(find.byKey(const Key('create-project')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-request')), findsOneWidget);
  });

  testWidgets('tech supervision and the observer get no create actions', (
    tester,
  ) async {
    for (final role in [AppRole.tech, AppRole.observer]) {
      await pumpIBuild(tester, user: demoUser(role));
      expect(find.byKey(const Key('create-project')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-requests')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('new-request')), findsNothing);
    }
  });

  testWidgets('observer opening the form is told the server will refuse it', (
    tester,
  ) async {
    await pumpIBuild(tester, user: demoUser(AppRole.observer));
    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-request')), findsNothing);
    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go('/requests/new');
    await tester.pumpAndSettle();
    expect(find.text('У вашей роли нет права создавать транш'), findsOneWidget);
    expect(find.text('Транш запрашивает застройщик'), findsNothing);
    expect(find.text('Банк только рассматривает транши и сам их не создаёт.'), findsNothing);
  });

  testWidgets('a bank specialist gets the bank cabinet and a director does not', (tester) async {
    final bankApi = FakeApi(user: _bankUser())
      ..jsonAnswers['/api/bank/portfolio'] = {
        'bankName': 'Банк Навои',
        'issued': '0.00',
        'limit': '0.00',
        'kpi': {'objects': 0, 'attention': 0, 'tranchesInWork': 0, 'averageDays': null},
        'signals': <dynamic>[],
        'stageDays': <dynamic>[],
        'deadlines': <dynamic>[],
      };
    await pumpIBuildWith(tester, bankApi);
    expect(find.byKey(const Key('bank-queue-frame')), findsOneWidget);
    expect(find.byKey(const Key('bank-cabinet-label')), findsOneWidget);
    expect(find.byKey(const Key('bank-queue-badge')), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.byKey(const Key('bank-queue-summary')), findsOneWidget);
    expect(find.text('12 траншей · 18 740,0 млн UZS'), findsOneWidget);
    expect(find.byKey(const Key('bank-account-role')), findsOneWidget);
    expect(find.text('Кредитный специалист · Банк Навои'), findsOneWidget);
    expect(find.byKey(const Key('nav-home')), findsNothing);
    expect(find.byKey(const Key('project-rail')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-bank-portfolio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-portfolio-frame')), findsOneWidget);

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/projects');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-queue-frame')), findsOneWidget);

    await pumpIBuild(tester, user: demoUser(AppRole.director));
    expect(find.byKey(const Key('nav-home')), findsOneWidget);
    expect(find.byKey(const Key('nav-bank-queue')), findsNothing);
    expect(find.byKey(const Key('project-rail')), findsOneWidget);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/bank/queue');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-queue-frame')), findsNothing);
    expect(find.byKey(const Key('nav-home')), findsOneWidget);
  });

  testWidgets('adding a person to a project offers technical supervision and does not assume director', (tester) async {
    final api = await pumpIBuild(tester, user: demoUser(AppRole.director), size: const Size(1280, 900));
    api.storedCompanyUsers = const [
      CompanyUser(id: 'user-9', name: 'Новый сотрудник', login: 'new.person', active: true),
    ];
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ЖК Навои'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-tab-4')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('add-member')),
      200,
      scrollable: find.ancestor(of: find.byKey(const Key('add-member')), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();

    final button = tester.widget<TextButton>(find.byKey(const Key('assign-confirm')));
    expect(button.onPressed, isNull);
    await tester.tap(find.byKey(const Key('assign-role')));
    await tester.pumpAndSettle();
    expect(find.text('Технадзор'), findsWidgets);
    expect(find.text('Застройщик'), findsWidgets);
    expect(find.text('Подрядчик'), findsWidgets);
    await tester.tap(find.text('Технадзор').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();
    expect(api.addedMember?.role, 'tech');
    expect(api.addedMember?.userId, 'user-9');
  });
}
