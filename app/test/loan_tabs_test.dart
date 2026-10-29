import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void main() {
  testWidgets('the loan card shows cabinets and the three draw amounts', (tester) async {
    final api = await pumpIBuild(tester, user: demoUser(AppRole.director));
    api.desk = const LoanDesk(
      lines: [
        LoanLine(id: 'line-1', code: '03', title: 'Бетон', kind: 'hard', side: 'use', amount: '600.00'),
      ],
      sources: [
        LoanSource(id: 'source-1', name: 'Кредитная линия', kind: 'loan', amount: '600.00'),
      ],
      checklist: [
        ChecklistItem(id: 'check-1', code: 'act', title: 'Акт выполненных работ', required: true),
      ],
      draws: [
        LoanDraw(
          id: 'draw-1',
          name: 'Транш 1',
          status: 'tech_approved',
          amount: '500.00',
          requested: '600.00',
          recommended: '400.00',
          confirmed: '500.00',
        ),
      ],
      inspections: [],
      firms: [],
    );
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('project-table')),
        matching: find.text('ЖК Навои'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Бюджет'), findsWidgets);
    expect(find.byKey(const Key('project-tab-1')), findsOneWidget);
    expect(find.text('Осмотры'), findsWidgets);
    expect(find.text('Документы'), findsWidgets);
    expect(find.text('Участники'), findsWidgets);
    expect(find.text('Бетон'), findsOneWidget);
    expect(find.text('hard'), findsOneWidget);
    expect(find.text('600.00 UZS'), findsWidgets);
    await tester.tap(find.byKey(const Key('project-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('Запрошено'), findsOneWidget);
    expect(find.text('Рекомендует инспектор'), findsOneWidget);
    expect(find.text('Одобрено банком'), findsOneWidget);
    expect(find.text('400.00 UZS'), findsOneWidget);
    expect(find.text('500.00 UZS'), findsOneWidget);
  });

  testWidgets('a bank user opens a portfolio instead of the project list title', (tester) async {
    await pumpIBuild(tester, user: demoUser(AppRole.observer));
    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    expect(find.text('Портфель'), findsOneWidget);
  });
}
