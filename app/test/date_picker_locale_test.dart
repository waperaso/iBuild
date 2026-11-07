import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support.dart';

Future<void> _openRegistrationDate(WidgetTester tester) async {
  await tester.tap(find.text('Регистрация'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('register-kind-developer')));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('reg-reg_date')),
    200,
    scrollable: find.ancestor(of: find.byKey(const Key('reg-reg_date')), matching: find.byType(Scrollable)).first,
  );
  await tester.tap(find.byKey(const Key('reg-reg_date')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the registration calendar follows Russian, English and Uzbek', (tester) async {
    await pumpIBuild(tester, size: const Size(1280, 1400));

    await _openRegistrationDate(tester);
    expect(find.text('Switch to input'), findsNothing);
    expect(find.text('Enter Date'), findsNothing);
    expect(find.text('Select date'), findsNothing);
    expect(find.text('OK'), findsNothing);
    expect(find.text('Выберите дату'), findsWidgets);
    expect(find.text('ОК'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(find.byTooltip('Переключиться на ручной ввод'), findsOneWidget);
    await tester.tap(find.byTooltip('Переключиться на ручной ввод'));
    await tester.pumpAndSettle();
    expect(find.text('Введите дату'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/login');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-kind-developer')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('reg-reg_date')),
      200,
      scrollable: find.ancestor(of: find.byKey(const Key('reg-reg_date')), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.byKey(const Key('reg-reg_date')));
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byTooltip('Switch to input'), findsOneWidget);
    expect(find.text('ОК'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/login');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-uz')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ro‘yxatdan o‘tish'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-kind-developer')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('reg-reg_date')),
      200,
      scrollable: find.ancestor(of: find.byKey(const Key('reg-reg_date')), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.byKey(const Key('reg-reg_date')));
    await tester.pumpAndSettle();
    expect(find.text('Sanani tanlang'), findsWidgets);
    expect(find.text('Bekor qilish'), findsOneWidget);
    expect(find.byTooltip('Mustaqil kiritish'), findsOneWidget);
    expect(find.text('ОК'), findsNothing);
    expect(find.text('Выберите дату'), findsNothing);
  });
}
