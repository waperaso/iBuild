import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

void main() {
  testWidgets('only a developer, director or contractor can start a tranche from home', (tester) async {
    for (final role in [AppRole.director, AppRole.contractor, AppRole.developer]) {
      await pumpIBuild(tester, user: demoUser(role), size: const Size(1280, 900));
      expect(find.byKey(const Key('home-ask-shortcut')), findsOneWidget, reason: role.name);
      expect(find.byKey(const Key('home-ask-link')), findsOneWidget, reason: role.name);
      expect(find.text('Запросить транш'), findsWidgets, reason: role.name);
      await tester.tap(find.byKey(const Key('home-ask-shortcut')));
      await tester.pumpAndSettle();
      expect(find.text('Новый транш'), findsOneWidget, reason: role.name);
      expect(find.text('У вашей роли нет права создавать транш'), findsNothing, reason: role.name);
    }

    for (final role in [AppRole.tech, AppRole.observer]) {
      await pumpIBuild(tester, user: demoUser(role), size: const Size(1280, 900));
      expect(find.byKey(const Key('home-ask-shortcut')), findsNothing, reason: role.name);
      expect(find.byKey(const Key('home-ask-link')), findsNothing, reason: role.name);
      expect(find.text('Запросить транш'), findsNothing, reason: role.name);
      expect(find.byKey(const Key('home-tranche-shortcut')), findsOneWidget, reason: role.name);
      expect(find.byKey(const Key('home-tranche-link')), findsOneWidget, reason: role.name);
      await tester.tap(find.byKey(const Key('home-tranche-link')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('new-request')), findsNothing, reason: role.name);
      expect(find.text('Транши'), findsWidgets, reason: role.name);
    }
  });

  testWidgets('a direct link to the new tranche explains the role, for tech and for the bank', (tester) async {
    for (final role in [AppRole.tech, AppRole.observer]) {
      await pumpIBuild(tester, user: demoUser(role), size: const Size(1280, 900));
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/requests/new');
      await tester.pumpAndSettle();
      expect(find.text('У вашей роли нет права создавать транш'), findsOneWidget, reason: role.name);
      expect(find.text('Транш запрашивает застройщик'), findsNothing, reason: role.name);
      expect(find.text('Банк только рассматривает транши и сам их не создаёт.'), findsNothing, reason: role.name);
      expect(find.byKey(const Key('request-form')), findsNothing, reason: role.name);
    }
  });
}
