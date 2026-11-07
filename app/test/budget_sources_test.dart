import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/models.dart';
import 'package:ibuild/widgets.dart';

import 'support.dart';

void main() {
  testWidgets('adding a work item stays disabled until a contractor exists', (tester) async {
    await pumpIBuild(tester, user: demoUser(AppRole.director), size: const Size(1280, 900));
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ЖК Навои'));
    await tester.pumpAndSettle();

    final button = tester.widget<PrimaryButton>(find.byKey(const Key('add-budget-line')));
    expect(button.onPressed, isNull);
    expect(find.byKey(const Key('add-line-needs-firm')), findsOneWidget);
    expect(find.text('Подрядчик'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-firm')),
      200,
      scrollable: find.ancestor(
        of: find.byKey(const Key('add-firm')),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.tap(find.byKey(const Key('add-firm')));
    await tester.pumpAndSettle();
    expect(find.text('Подрядчик'), findsOneWidget);
    expect(find.byKey(const Key('budget-title')), findsNothing);
  });

  testWidgets('with a contractor the work-item button opens the work-item dialog', (tester) async {
    final api = await pumpIBuild(tester, user: demoUser(AppRole.director), size: const Size(1280, 900));
    api.storedFirms = const [
      ContractorFirm(id: 'firm-1', name: 'Навои Строй', inn: '123456789', contact: 'Офис'),
    ];
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ЖК Навои'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-budget-line')),
      200,
      scrollable: find.ancestor(
        of: find.byKey(const Key('add-budget-line')),
        matching: find.byType(Scrollable),
      ).first,
    );
    final button = tester.widget<PrimaryButton>(find.byKey(const Key('add-budget-line')));
    expect(button.onPressed, isNotNull);
    expect(find.byKey(const Key('add-line-needs-firm')), findsNothing);
    await tester.tap(find.byKey(const Key('add-budget-line')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Вид работ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('ИНН')),
      findsNothing,
    );
  });

  testWidgets('a tranche without money sources explains the next step', (tester) async {
    final api = await pumpIBuild(tester, user: demoUser(AppRole.director), size: const Size(1280, 900));
    api.desk = const LoanDesk(
      lines: [
        LoanLine(id: 'line-1', code: '01', title: 'Фундамент', kind: 'hard', side: 'use', amount: '100.00'),
      ],
      sources: [],
      checklist: [],
      draws: [
        LoanDraw(
          id: 'draw-1',
          name: 'Черновик',
          status: 'draft',
          amount: '0.00',
          requested: '50000000.00',
          recommended: '',
          confirmed: '',
        ),
      ],
      firms: [],
      inspections: [],
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/projects/project-1?tab=1');
    await tester.pumpAndSettle();
    expect(find.text('Запрошено'), findsOneWidget);
    expect(find.text('50\u00a0000\u00a0000.00 UZS'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/projects/project-1/draw');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('draw-no-sources')), findsOneWidget);
    expect(
      find.text('На объекте ещё нет источников денег. Добавьте источник в бюджете объекта, затем отправьте транш.'),
      findsOneWidget,
    );

    final contractor = await pumpIBuild(tester, user: demoUser(AppRole.contractor), size: const Size(1280, 900));
    contractor.desk = api.desk;
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/projects/project-1/draw');
    await tester.pumpAndSettle();
    expect(
      find.text('Источники денег задаёт застройщик в бюджете объекта. Попросите добавить источник, затем отправьте транш.'),
      findsOneWidget,
    );
  });
}
