import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/session.dart';
import 'package:ibuild/theme.dart';

import 'inspector_fixtures.dart';
import 'support.dart';

Future<void> _open(WidgetTester tester, String route) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the visit list reads as a table: counts, a filter and the day of each visit', (
    tester,
  ) async {
    await pumpIBuildWith(tester, InspectorApi(), size: const Size(1280, 810));
    await _open(tester, '/inspections');

    expect(find.byKey(const Key('inspections-frame')), findsOneWidget);
    expect(find.byKey(const Key('visits-list')), findsOneWidget);
    expect(find.text('28.10.2026'), findsOneWidget);
    expect(find.text('14.10.2026'), findsOneWidget);
    expect(find.byKey(const Key('visits-filter-requested')), findsOneWidget);
    // The engineer is sent to the project page, where the report is written.
    expect(find.byKey(const Key('visit-ins-1')), findsOneWidget);
    expect(find.byKey(const Key('visit-ins-2')), findsNothing);

    await tester.tap(find.byKey(const Key('visits-filter-reported')));
    await tester.pumpAndSettle();
    expect(find.text('28.10.2026'), findsNothing);
    expect(find.text('14.10.2026'), findsOneWidget);
  });

  testWidgets('the queue is a list of rows that open the tranche, and says it waits for this person', (
    tester,
  ) async {
    await pumpIBuildWith(tester, InspectorApi(), size: const Size(1280, 810));
    await _open(tester, '/queue');

    expect(find.byKey(const Key('queue-frame')), findsOneWidget);
    expect(find.byKey(const Key('queue-list')), findsOneWidget);
    expect(find.text('Ждут вашей проверки'), findsOneWidget);
    expect(find.text('Ждёт решения банка'), findsNothing);

    await tester.tap(find.byKey(const Key('queue-open-req-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request-card')), findsOneWidget);
    // The tranche itself says it waits for this person, not for the bank.
    expect(find.text('Ждёт вашей проверки'), findsOneWidget);
    expect(find.text('Ждёт решения банка'), findsNothing);
  });

  testWidgets('the decision sits in a card above the evidence, not past the bottom of the page', (
    tester,
  ) async {
    await pumpIBuildWith(tester, InspectorApi(), size: const Size(1280, 810));
    await _open(tester, '/requests/req-1');

    final decision = find.byKey(const Key('tech-decision'));
    expect(decision, findsOneWidget);
    expect(find.byKey(const Key('tech-approve')), findsOneWidget);
    // Photos are the evidence for the decision, so they come after it.
    expect(
      tester.getTopLeft(decision).dy,
      lessThan(tester.getTopLeft(find.text('Фото и документы')).dy),
    );
    expect(tester.getBottomLeft(decision).dy, lessThan(810));

    // Reject needs a reason; confirm does not.
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('tech-reject'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('decision-reason')), 'Объём не подтверждён');
    await tester.pumpAndSettle();
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('tech-reject'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('the rail offers the projects instead of standing empty, and the name is readable in the dark theme', (
    tester,
  ) async {
    await pumpIBuildWith(tester, InspectorApi(), size: const Size(1280, 810));
    await _open(tester, '/queue');

    expect(find.byKey(const Key('rail-projects')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rail-project-project-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rail-projects')), findsNothing);

    await _open(tester, '/queue');
    await tester.tap(find.byKey(const Key('theme-switch')).first);
    await tester.pumpAndSettle();

    final element = tester.element(find.byKey(const Key('side-nav')));
    final rail = element.findAncestorWidgetOfExactType<Scaffold>();
    expect(rail, isNotNull);
    final name = tester.widget<Text>(
      find.descendant(of: find.byKey(const Key('side-nav')), matching: find.text('А. Каримов')),
    );
    final colors = Theme.of(element).extension<IBuildColors>()!;
    expect(name.style?.color, colors.onHeroSurface);
    expect(name.style?.color, isNot(colors.heroSurface));
  });

  testWidgets('the inspector screens hold together from a phone up to a wide desktop', (
    tester,
  ) async {
    for (final size in const [Size(390, 844), Size(834, 1112), Size(1280, 810), Size(1680, 1050)]) {
      final api = InspectorApi();
      final session = SessionController(api);
      await session.restore();
      await pumpIBuildWith(tester, api, size: size);
      for (final route in ['/queue', '/inspections', '/requests', '/requests/req-1', '/projects']) {
        await _open(tester, route);
        expect(tester.takeException(), isNull, reason: '$route at $size');
      }
      session.dispose();
    }
  });
}
