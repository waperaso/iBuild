import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void main() {
  testWidgets('login, six screens, and logout', (tester) async {
    await pumpIBuild(tester);

    expect(find.text('Войти'), findsOneWidget);
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();
    expect(find.text('Введите логин и пароль.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-field')),
      'a.contractor',
    );
    await tester.enterText(find.byKey(const Key('password-field')), 'wrong');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();
    expect(find.text('Неверный логин или пароль.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password-field')), 'secret');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('Главная'), findsWidgets);
    expect(find.byKey(const Key('dashboard-tiles')), findsOneWidget);
    expect(find.text('Объекты'), findsWidgets);
    expect(find.text('ЖК Навои'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-projects')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-table')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('project-table')),
        matching: find.text('ЖК Навои'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Лимит'), findsWidgets);
    expect(find.text('Ждёт выплаты'), findsWidgets);
    expect(find.text('Выплачено'), findsWidgets);
    expect(find.text('Можно запросить'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    expect(find.text('Транши'), findsWidgets);
    expect(find.text('Черновик'), findsWidgets);

    await tester.tap(find.byKey(const Key('open-request-draft-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request-card')), findsOneWidget);
    expect(find.text('Черновик'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-request')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request-form')), findsOneWidget);
    expect(find.text('Сумма'), findsOneWidget);
    expect(find.text('Вид работ'), findsOneWidget);
    expect(find.text('Что сделано'), findsOneWidget);
    expect(find.text('Фото работы'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('empty project list', (tester) async {
    await pumpIBuild(
      tester,
      user: demoUser(AppRole.observer),
      projects: const [],
    );
    expect(find.byKey(const Key('empty-projects')), findsOneWidget);
    expect(find.text('Объектов пока нет'), findsOneWidget);
  });

  testWidgets('language switch covers English and Uzbek', (tester) async {
    await pumpIBuild(tester);
    expect(find.text('Войти'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-uz')));
    await tester.pumpAndSettle();
    expect(find.text('Kirish'), findsWidgets);
    expect(find.text('Parol'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-ru')));
    await tester.pumpAndSettle();
    expect(find.text('Войти'), findsOneWidget);
  });
}
