import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

Future<void> openDemoProject(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-projects')));
  await tester.pumpAndSettle();
  final table = find.byKey(const Key('project-table'));
  final scope = table.evaluate().isNotEmpty
      ? table
      : find.byKey(const Key('project-cards'));
  await tester.tap(
    find.descendant(of: scope, matching: find.text('ЖК Навои')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop budget is a table and the director can add a line', (
    tester,
  ) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      size: const Size(1280, 900),
    );
    await openDemoProject(tester);
    expect(find.byKey(const Key('budget-table')), findsOneWidget);
    expect(find.byKey(const Key('budget-cards')), findsNothing);
    expect(find.byKey(const Key('add-budget-line')), findsOneWidget);
    expect(find.text('Лимит'), findsWidgets);
    expect(find.text('Участники'), findsWidgets);
  });

  testWidgets('phone budget is cards and a contractor cannot add a line', (
    tester,
  ) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.contractor),
      size: const Size(390, 900),
    );
    await openDemoProject(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('budget-cards')), 200);
    expect(find.byKey(const Key('budget-cards')), findsOneWidget);
    expect(find.byKey(const Key('budget-table')), findsNothing);
    expect(find.byKey(const Key('add-budget-line')), findsNothing);
    expect(find.text('Видов работ пока нет'), findsOneWidget);
  });

  testWidgets('director can remove a line and an assignment', (tester) async {
    final api = await pumpIBuild(
      tester,
      user: demoUser(AppRole.director),
      size: const Size(1280, 900),
      lines: const [
        BudgetLine(
          id: 'line-1',
          title: 'Кладка',
          amount: '1000.00',
          contractorFirmId: 'firm-1',
          contractorFirmName: 'Навои Строй',
        ),
      ],
      members: const [
        ProjectMember(
          id: 'member-1',
          userId: 'user-2',
          name: 'Технадзор Навои',
          login: 'a.tech',
          role: 'tech',
        ),
      ],
    );
    await openDemoProject(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('remove-line-line-1')),
      200,
    );
    await tester.tap(find.byKey(const Key('remove-line-line-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-remove')));
    await tester.pumpAndSettle();
    expect(api.deletedLineId, 'line-1');
    expect(find.text('Кладка'), findsNothing);

    await tester.tap(find.byKey(const Key('project-tab-4')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('remove-member-member-1')),
      200,
    );
    await tester.tap(find.byKey(const Key('remove-member-member-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-remove')));
    await tester.pumpAndSettle();
    expect(api.removedMemberId, 'member-1');
    expect(find.text('Технадзор Навои'), findsNothing);
  });
}
