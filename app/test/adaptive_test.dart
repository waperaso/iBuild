import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void main() {
  testWidgets('desktop shows a table and a side nav', (tester) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      size: const Size(1280, 800),
    );
    expect(find.byKey(const Key('side-nav')), findsOneWidget);
    expect(find.byKey(const Key('bottom-nav')), findsNothing);
    expect(find.byKey(const Key('project-rail')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-table')), findsOneWidget);
    expect(find.byKey(const Key('project-cards')), findsNothing);
    expect(find.text('Идёт стройка'), findsWidgets);
    expect(find.text('Деньги банка на стройку выплачиваются по мере готовности работ.'), findsOneWidget);
  });

  testWidgets('a tablet keeps a side rail and a readable project table', (tester) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      size: const Size(834, 1112),
    );
    expect(find.byKey(const Key('side-nav')), findsOneWidget);
    expect(find.byKey(const Key('bottom-nav')), findsNothing);
    expect(find.byKey(const Key('project-rail')), findsNothing);
    expect(find.byKey(const Key('collapse-nav')), findsNothing);
    expect(find.text('director'), findsOneWidget);
    expect(find.byKey(const Key('language-ru')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-table')), findsOneWidget);
    expect(find.byKey(const Key('project-cards')), findsNothing);
    expect(find.text('ЖК Навои'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      size: const Size(1194, 834),
    );
    expect(find.byKey(const Key('side-nav')), findsOneWidget);
    expect(find.byKey(const Key('bottom-nav')), findsNothing);
    expect(find.byKey(const Key('project-rail')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-table')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a large phone keeps cards instead of a crushed table', (tester) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      size: const Size(560, 900),
    );
    expect(find.byKey(const Key('bottom-nav')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-cards')), findsOneWidget);
    expect(find.byKey(const Key('project-table')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone shows cards and a bottom nav', (tester) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.contractor),
      size: const Size(390, 800),
    );
    expect(find.byKey(const Key('bottom-nav')), findsOneWidget);
    expect(find.byKey(const Key('side-nav')), findsNothing);
    expect(find.byKey(const Key('project-rail')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-cards')), findsOneWidget);
    expect(find.byKey(const Key('project-table')), findsNothing);
    expect(find.text('Идёт стройка'), findsWidgets);
  });

  testWidgets('a status filter with no rows shows an empty list', (
    tester,
  ) async {
    await pumpIBuild(tester, user: demoUser(AppRole.tech));
    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выплачен'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-requests')), findsOneWidget);
  });
}
