import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void main() {
  testWidgets('the cabinet shows a dashboard, eight sections, and the open project', (
    tester,
  ) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      projects: [
        ProjectSummary(
          id: 'project-1',
          companyId: 'company-1',
          name: 'ЖК Навои',
          address: 'Ташкент, улица Бабура, 12',
          active: true,
          myRole: AppRole.director,
          plan: '1500.00',
          reserved: '370.00',
          paid: '0.00',
          available: '1130.00',
        ),
      ],
      size: const Size(1280, 900),
    );

    expect(find.byKey(const Key('dashboard-tiles')), findsOneWidget);
    expect(find.text('1\u00a0130.00 UZS'), findsWidgets);
    expect(find.byKey(const Key('nav-home')), findsOneWidget);
    expect(find.byKey(const Key('nav-budget')), findsOneWidget);
    expect(find.byKey(const Key('nav-inspections')), findsOneWidget);
    expect(find.byKey(const Key('nav-documents')), findsOneWidget);
    expect(find.byKey(const Key('nav-people')), findsOneWidget);
    expect(find.byKey(const Key('nav-queue')), findsOneWidget);
    expect(find.byKey(const Key('project-rail')), findsOneWidget);
    expect(find.byKey(const Key('project-topbar')), findsOneWidget);
    expect(find.text('Выберите объект'), findsWidgets);
    expect(find.byKey(const Key('hub-services')), findsOneWidget);
    expect(find.byKey(const Key('currency-switch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('project-table')),
        matching: find.text('ЖК Навои'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('project-rail')),
        matching: find.text('ЖК Навои'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('budget-table')), findsOneWidget);
  });
}
