import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void main() {
  testWidgets('an object inspection shows a written date and hides an empty gate code', (tester) async {
    final api = await pumpIBuild(tester, user: demoUser(AppRole.director), size: const Size(1280, 900));
    api.desk = const LoanDesk(
      lines: [],
      sources: [],
      checklist: [],
      draws: [],
      firms: [],
      inspections: [
        InspectionCard(
          id: 'i1',
          status: 'requested',
          scheduledOn: '2026-10-24',
          gateCode: '',
          note: '',
          requestId: '',
        ),
        InspectionCard(
          id: 'i2',
          status: 'reported',
          scheduledOn: '2026-09-18',
          gateCode: '4412',
          note: 'Ворота открыты',
          requestId: '',
        ),
      ],
    );
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ЖК Навои'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-tab-2')));
    await tester.pumpAndSettle();

    expect(find.text('24.10.2026'), findsOneWidget);
    expect(find.text('18.09.2026'), findsOneWidget);
    expect(find.text('2026-10-24'), findsNothing);
    expect(find.text('2026-09-18'), findsNothing);
    expect(find.text('Код от ворот: 4412'), findsOneWidget);
    expect(find.text('Код от ворот:'), findsNothing);
    expect(find.text('Код от ворот: '), findsNothing);
    expect(find.byKey(const Key('empty-inspections')), findsNothing);
  });

  testWidgets('a project with no inspections explains the empty tab', (tester) async {
    await pumpIBuild(tester, user: demoUser(AppRole.director), size: const Size(1280, 900));
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ЖК Навои'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-tab-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-inspections')), findsOneWidget);
    expect(find.text('Осмотров пока нет'), findsOneWidget);
    expect(
      find.text('Здесь появятся осмотры по вашим объектам.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('gate-code')), findsNothing);
  });
}
