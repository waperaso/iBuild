import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void main() {
  testWidgets('only the developer can edit the pinned object', (tester) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      projects: [_navoi(AppRole.director)],
      size: const Size(1280, 900),
    );
    await _open(tester);
    expect(find.byKey(const Key('edit-object')), findsOneWidget);

    await pumpIBuild(
      tester,
      user: demoUser(AppRole.observer),
      projects: [_navoi(AppRole.observer)],
      size: const Size(1280, 900),
    );
    await _open(tester);
    expect(find.byKey(const Key('edit-object')), findsNothing);
  });
}

ProjectSummary _navoi(AppRole role) {
  return ProjectSummary(
    id: 'project-1',
    companyId: 'company-1',
    name: 'ЖК Навои',
    address: 'Ташкент, улица Бабура, 12',
    active: true,
    myRole: role,
    plan: '0.00',
    reserved: '0.00',
    paid: '0.00',
    available: '0.00',
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-projects')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('project-table')),
      matching: find.text('ЖК Навои'),
    ),
  );
  await tester.pumpAndSettle();
}
