import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/theme.dart';

import 'bank_fixtures.dart';
import 'support.dart';

Finder _rows() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('bank-row-');
  });
}

Color _dot(WidgetTester tester, String id) {
  final dot = find.descendant(
    of: find.byKey(Key('bank-dot-$id')),
    matching: find.byType(DecoratedBox),
  );
  return ((tester.widget<DecoratedBox>(dot).decoration) as BoxDecoration).color!;
}

IBuildColors _colors(WidgetTester tester) {
  return Theme.of(tester.element(find.byKey(const Key('bank-queue-frame')))).extension<IBuildColors>()!;
}

Future<FakeApi> _pump(WidgetTester tester, {Size size = const Size(1280, 800)}) {
  return pumpIBuild(tester, user: bankUser(), projects: const [], size: size);
}

void main() {
  testWidgets('the queue opens on my tranches with a count on every tab', (tester) async {
    final api = await _pump(tester);

    expect(find.byKey(const Key('bank-queue-frame')), findsOneWidget);
    expect(_rows(), findsNWidgets(2));
    expect(find.byKey(const Key('bank-row-t-navoi')), findsOneWidget);
    expect(find.byKey(const Key('bank-row-t-yunusabad')), findsOneWidget);
    expect(find.byKey(const Key('bank-row-t-sergeli')), findsNothing);
    expect(api.bankTabsAsked, ['mine']);

    String count(String tab) => tester.widget<Text>(find.byKey(Key('bank-tab-$tab-count'))).data!;
    expect(count('mine'), '2');
    expect(count('all'), '5');
    expect(count('developer'), '1');
    expect(count('overdue'), '1');
    expect(find.text('Мои'), findsOneWidget);
    expect(find.text('Все в работе'), findsOneWidget);
    expect(find.text('У застройщика'), findsOneWidget);
    expect(find.text('Просрочены'), findsOneWidget);
  });

  testWidgets('each tab asks the server and shows its own tranches', (tester) async {
    final api = await _pump(tester);

    await tester.tap(find.byKey(const Key('bank-tab-all')));
    await tester.pumpAndSettle();
    expect(_rows(), findsNWidgets(5));

    await tester.tap(find.byKey(const Key('bank-tab-developer')));
    await tester.pumpAndSettle();
    expect(_rows(), findsOneWidget);
    expect(find.byKey(const Key('bank-row-t-mirzo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bank-tab-overdue')));
    await tester.pumpAndSettle();
    expect(_rows(), findsOneWidget);
    expect(find.byKey(const Key('bank-row-t-sergeli')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bank-tab-mine')));
    await tester.pumpAndSettle();
    expect(_rows(), findsNWidgets(2));
    expect(api.bankTabsAsked, ['mine', 'all', 'developer', 'overdue', 'mine']);
  });

  testWidgets('a row shows the object, the amount in millions and the stage', (tester) async {
    await _pump(tester);

    final row = find.byKey(const Key('bank-row-t-navoi'));
    expect(find.descendant(of: row, matching: find.text('ЖК Навои')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('№2')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('2 260,0')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('Решение специалиста')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('1 блок · 3 предупреждения')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('Д. Рахимов')), findsOneWidget);
    expect(find.byKey(const Key('bank-queue-unit')), findsOneWidget);
    expect(find.text('Суммы в млн UZS'), findsOneWidget);
  });

  testWidgets('the time at the stage reads against the bank limit', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('bank-tab-all')));
    await tester.pumpAndSettle();

    String elapsed(String id) => tester.widget<Text>(find.byKey(Key('bank-elapsed-$id'))).data!;
    expect(elapsed('t-navoi'), 'Прошло 1 дн. 4 ч · срок банка 2 дн.');
    expect(elapsed('t-sergeli'), 'Прошло 4 дн. · срок банка 3 дн.');
    expect(elapsed('t-yunusabad'), 'Прошло 3 ч · срок банка 1 дн.');
    expect(elapsed('t-mirzo'), '6 дн. у застройщика');

    final colors = _colors(tester);
    expect(tester.widget<Text>(find.byKey(const Key('bank-elapsed-t-sergeli'))).style?.color, colors.danger);
    expect(tester.widget<Text>(find.byKey(const Key('bank-elapsed-t-navoi'))).style?.color, isNot(colors.danger));
  });

  testWidgets('the dot: red only when late, yellow for a block, blue for inspection, grey at the developer',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('bank-tab-all')));
    await tester.pumpAndSettle();
    final colors = _colors(tester);

    expect(_dot(tester, 't-sergeli'), colors.danger);
    expect(_dot(tester, 't-navoi'), colors.warning);
    expect(_dot(tester, 't-yunusabad'), colors.warning);
    expect(_dot(tester, 't-chilanzar'), isNot(colors.warning));
    expect(_dot(tester, 't-chilanzar'), isNot(colors.danger));
    expect(_dot(tester, 't-mirzo'), isNot(colors.danger));
    expect(_dot(tester, 't-mirzo'), isNot(_dot(tester, 't-chilanzar')));
  });

  testWidgets('the USD switch recounts the table and the top bar at the bank rate', (tester) async {
    await _pump(tester);
    expect(find.text('2 260,0'), findsOneWidget);
    expect(find.text('12 траншей · 18 740,0 млн UZS'), findsOneWidget);

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    final row = find.byKey(const Key('bank-row-t-navoi'));
    expect(find.descendant(of: row, matching: find.text('175 869')), findsOneWidget);
    expect(find.text('Суммы в USD'), findsOneWidget);
    expect(find.text('12 траншей · 1 458 309 USD'), findsOneWidget);

    await tester.tap(find.text('UZS'));
    await tester.pumpAndSettle();
    expect(find.text('2 260,0'), findsOneWidget);
    expect(find.text('Суммы в млн UZS'), findsOneWidget);
  });

  testWidgets('the legend names the four dots', (tester) async {
    await _pump(tester);

    final legend = find.byKey(const Key('bank-legend'));
    for (final label in [
      'банк не уложился в срок',
      'есть замечание',
      'ждёт осмотра',
      'у застройщика',
    ]) {
      expect(find.descendant(of: legend, matching: find.text(label)), findsOneWidget);
    }
  });

  testWidgets('open leads to the tranche card', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bank-tranche-frame')), findsOneWidget);
    expect(find.text('Транш №2'), findsOneWidget);
  });

  testWidgets('a row tap also opens the card', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('ЖК Юнусабад Гарден'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bank-tranche-frame')), findsOneWidget);
  });

  testWidgets('an empty tab explains itself', (tester) async {
    final api = FakeApi(user: bankUser());
    api.bankItems = const [];
    await pumpIBuildWith(tester, api);

    expect(_rows(), findsNothing);
    expect(find.text('За вами пока нет траншей'), findsOneWidget);
  });

  testWidgets('a failed load shows the error and a retry that works', (tester) async {
    final api = FakeApi(user: bankUser());
    api.bankFails = true;
    await pumpIBuildWith(tester, api);

    expect(find.byKey(const Key('bank-retry')), findsOneWidget);
    expect(find.textContaining('Не получилось загрузить данные'), findsOneWidget);
    expect(_rows(), findsNothing);

    api.bankFails = false;
    await tester.tap(find.byKey(const Key('bank-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-retry')), findsNothing);
    expect(_rows(), findsNWidgets(2));
  });

  testWidgets('on a phone the rows become cards without overflow', (tester) async {
    await _pump(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(_rows(), findsNWidgets(2));
    expect(find.byKey(const Key('bank-open-t-navoi')), findsOneWidget);
    expect(find.text('Объект'), findsNothing);

    await tester.tap(find.byKey(const Key('bank-tab-all')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_rows(), findsNWidgets(5));
  });
}
