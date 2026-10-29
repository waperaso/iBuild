import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/screens/bank/bank_models.dart';
import 'package:ibuild/theme.dart';

import 'bank_fixtures.dart';
import 'support.dart';

IBuildColors _colors(WidgetTester tester) {
  return Theme.of(tester.element(find.byKey(const Key('bank-tranche-frame')))).extension<IBuildColors>()!;
}

String _text(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

Color? _textColor(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).style?.color;
}

Color _boxColor(WidgetTester tester, String key) {
  final box = tester.widget<DecoratedBox>(find.byKey(Key(key)));
  return (box.decoration as BoxDecoration).color!;
}

Future<FakeApi> _openNavoi(WidgetTester tester, {Size size = const Size(1280, 800)}) async {
  final api = await pumpIBuild(tester, user: bankUser(), projects: const [], size: size);
  await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('the header names the object, the developer, the dates and the facility', (tester) async {
    await _openNavoi(tester);

    expect(_text(tester, 'bank-tranche-object'), 'ЖК Навои');
    expect(find.textContaining('Навои Девелопмент'), findsWidgets);
    expect(_text(tester, 'bank-tranche-title'), 'Транш №2');
    expect(find.text('Решение специалиста'), findsWidgets);
    expect(
      _text(tester, 'bank-tranche-meta'),
      'Подан 24.10.2026 в 18:10 · технадзор проверил 24.10 · Прошло 1 дн. 4 ч · срок банка 2 дн. · правила банка, версия 7',
    );
    expect(_text(tester, 'bank-limit'), '17 500,0 / 1 240,1 млн UZS');
  });

  testWidgets('the stage strip: three done, one current, two ahead', (tester) async {
    await _openNavoi(tester);
    final colors = _colors(tester);

    for (final code in ['submitted', 'docs', 'inspection']) {
      expect(_boxColor(tester, 'bank-stage-$code'), colors.success);
    }
    expect(_boxColor(tester, 'bank-stage-specialist'), isNot(colors.success));
    expect(_boxColor(tester, 'bank-stage-specialist'), isNot(colors.outline));
    expect(_boxColor(tester, 'bank-stage-approval'), colors.outline);
    expect(_boxColor(tester, 'bank-stage-payout'), colors.outline);
    expect(find.text('Согласование'), findsOneWidget);
    expect(find.text('Выплата'), findsOneWidget);
  });

  testWidgets('five numbers: requested, confirmed, blocked, to issue, limit left', (tester) async {
    await _openNavoi(tester);
    final colors = _colors(tester);

    expect(_text(tester, 'bank-sum-requested-value'), '2 260,0');
    expect(_text(tester, 'bank-sum-confirmed-value'), '2 083,9');
    expect(_text(tester, 'bank-sum-blocked-value'), '360,0');
    expect(_text(tester, 'bank-sum-issue-value'), '1 723,9');
    expect(_text(tester, 'bank-sum-remaining-value'), '14 536,0');
    expect(_textColor(tester, 'bank-sum-blocked-value'), colors.danger);
    expect(_textColor(tester, 'bank-sum-issue-value'), colors.success);
    expect(_textColor(tester, 'bank-sum-requested-value'), isNot(colors.danger));
  });

  testWidgets('a tranche with nothing blocked does not paint the blocked sum red', (tester) async {
    final api = FakeApi(user: bankUser());
    api.bankCard = sampleBankTranche(blocked: '0.00');
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
    await tester.pumpAndSettle();

    expect(_text(tester, 'bank-sum-blocked-value'), '0,0');
    expect(_textColor(tester, 'bank-sum-blocked-value'), isNot(_colors(tester).danger));
  });

  testWidgets('four open checks come first, in order, with the level colour', (tester) async {
    await _openNavoi(tester);
    final colors = _colors(tester);

    for (final code in ['certificate', 'above_confirmed', 'subcontractor', 'forecast']) {
      expect(find.byKey(Key('bank-check-$code')), findsOneWidget);
    }
    final order = [
      for (final code in ['certificate', 'above_confirmed', 'subcontractor', 'forecast'])
        tester.getTopLeft(find.byKey(Key('bank-check-$code'))).dy,
    ];
    expect(order, [...order]..sort());
    expect(find.text('Нет сертификата соответствия на арматуру'), findsOneWidget);
    expect(find.text('ГС п. 3.5'), findsOneWidget);

    Color dot(String code) {
      final decorated = find.descendant(
        of: find.byKey(Key('bank-check-dot-$code')),
        matching: find.byType(DecoratedBox),
      );
      return ((tester.widget<DecoratedBox>(decorated).decoration) as BoxDecoration).color!;
    }

    expect(dot('certificate'), colors.danger);
    expect(dot('above_confirmed'), colors.warning);
    expect(dot('forecast'), colors.warning);
  });

  testWidgets('the passed checks stay folded until asked', (tester) async {
    await _openNavoi(tester);

    expect(find.byKey(const Key('bank-passed-list')), findsNothing);
    expect(find.text('Показать, что в порядке (8)'), findsOneWidget);
    expect(find.text('Пройденная проверка номер 1'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('bank-passed-toggle')));
    await tester.tap(find.byKey(const Key('bank-passed-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-passed-list')), findsOneWidget);
    expect(find.text('Пройденная проверка номер 1'), findsOneWidget);
    expect(find.text('Пройденная проверка номер 8'), findsOneWidget);
    expect(find.text('Скрыть то, что в порядке'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bank-passed-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-passed-list')), findsNothing);
  });

  testWidgets('each check offers its own actions', (tester) async {
    await _openNavoi(tester);

    Finder action(String code, String name) => find.byKey(Key('bank-action-$code-$name'));
    expect(action('certificate', 'request_document'), findsOneWidget);
    expect(action('certificate', 'waive'), findsOneWidget);
    expect(action('above_confirmed', 'waive'), findsOneWidget);
    expect(action('above_confirmed', 'request_document'), findsNothing);
    expect(action('subcontractor', 'waive'), findsOneWidget);
    expect(action('forecast', 'request_schedule'), findsOneWidget);
    expect(action('forecast', 'waive'), findsNothing);

    expect(find.text('Запросить документ'), findsOneWidget);
    expect(find.text('Запросить график работ'), findsOneWidget);
    expect(find.text('Принять с обоснованием'), findsNWidgets(3));
    for (final button in tester.widgetList<OutlinedButton>(find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is OutlinedButton && key is ValueKey<String> && key.value.startsWith('bank-action-');
    }))) {
      expect(button.onPressed, isNotNull);
    }
  });

  testWidgets('the lines: rebar is stopped, the slab is confirmed below the request', (tester) async {
    await _openNavoi(tester);
    final colors = _colors(tester);

    for (final id in ['l1', 'l2', 'l3', 'l4']) {
      expect(find.byKey(Key('bank-line-$id')), findsOneWidget);
    }
    expect(find.text('Фундаментная плита'), findsOneWidget);
    expect(find.text('Арматура A500C и бетон на площадке'), findsOneWidget);

    expect(_text(tester, 'bank-line-l4-issue'), '0,0');
    expect(_textColor(tester, 'bank-line-l4-issue'), colors.danger);
    expect(_text(tester, 'bank-line-l2-issue'), '867,9');
    expect(_textColor(tester, 'bank-line-l2-issue'), isNot(colors.danger));
    expect(_text(tester, 'bank-line-l2-confirmed'), '867,9');
    expect(_textColor(tester, 'bank-line-l2-confirmed'), colors.warning);
    expect(_textColor(tester, 'bank-line-l1-confirmed'), isNot(colors.warning));

    final row = find.byKey(const Key('bank-line-l2'));
    expect(find.descendant(of: row, matching: find.text('980,0')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('620,1')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('62%')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('+36% с прошлого')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('bank-line-l4')), matching: find.text('склад')), findsOneWidget);
  });

  testWidgets('the total row repeats the totals of the tranche', (tester) async {
    await _openNavoi(tester);

    final total = find.byKey(const Key('bank-lines-total'));
    expect(find.descendant(of: total, matching: find.text('Итого')), findsOneWidget);
    expect(find.descendant(of: total, matching: find.text('2 260,0')), findsOneWidget);
    expect(find.descendant(of: total, matching: find.text('2 083,9')), findsOneWidget);
    expect(find.descendant(of: total, matching: find.text('1 723,9')), findsOneWidget);
  });

  testWidgets('the decision buttons are live for the specialist', (tester) async {
    await _openNavoi(tester);

    expect(
      find.text('Одобрить 1 723,9 млн UZS, а 536,1 млн UZS вернуть на доработку'),
      findsOneWidget,
    );
    expect(find.text('Вернуть застройщику целиком'), findsOneWidget);
    expect(find.text('Заказать проверку на месте'), findsOneWidget);
    expect(find.text('Приостановить финансирование'), findsOneWidget);
    for (final name in ['return', 'measure', 'suspend']) {
      expect(tester.widget<OutlinedButton>(find.byKey(Key('bank-decide-$name'))).onPressed, isNotNull);
    }
  });

  testWidgets('back returns to the queue', (tester) async {
    await _openNavoi(tester);

    await tester.tap(find.byKey(const Key('bank-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bank-queue-frame')), findsOneWidget);
    expect(find.byKey(const Key('bank-tranche-frame')), findsNothing);
  });

  testWidgets('a tranche the server does not know says so', (tester) async {
    final api = FakeApi(user: bankUser());
    api.bankCard = sampleBankTranche(id: 'another');
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
    await tester.pumpAndSettle();

    expect(find.text('Транш не найден'), findsOneWidget);
    expect(find.byKey(const Key('bank-sum-requested')), findsNothing);
    expect(find.byKey(const Key('bank-back')), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    final api = FakeApi(user: bankUser());
    await pumpIBuildWith(tester, api);
    api.bankFails = true;
    await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-retry')), findsOneWidget);

    api.bankFails = false;
    await tester.tap(find.byKey(const Key('bank-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-sum-requested')), findsOneWidget);
  });

  testWidgets('on a phone the card stacks without overflow', (tester) async {
    await _openNavoi(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('bank-sum-issue')), findsOneWidget);
    expect(find.byKey(const Key('bank-check-certificate')), findsOneWidget);
    expect(find.byKey(const Key('bank-line-l4')), findsOneWidget);
    expect(_text(tester, 'bank-line-l4-issue'), '0,0');

    await tester.ensureVisible(find.byKey(const Key('bank-passed-toggle')));
    await tester.tap(find.byKey(const Key('bank-passed-toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('bank-passed-list')), findsOneWidget);
  });

  testWidgets('the journal is folded, opens on request and tells who did what', (tester) async {
    final api = FakeApi(user: bankUser());
    api.bankJournalEntries = [
      BankJournalEntry(
        id: 'e2',
        action: 'decision',
        actor: 'Д. Рахимов',
        at: DateTime.utc(2026, 10, 28, 7, 30),
        detail: const {'kind': 'partial'},
      ),
      BankJournalEntry(
        id: 'e1',
        action: 'choose',
        actor: 'Д. Рахимов',
        at: DateTime.utc(2026, 10, 28, 7, 10),
        detail: const {'line': 'Каркас', 'from': 'confirmed', 'to': 'withhold'},
      ),
    ];
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bank-journal')), findsOneWidget);
    expect(find.byKey(const Key('bank-journal-e1')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('bank-journal-toggle')));
    await tester.tap(find.byKey(const Key('bank-journal-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-journal-e1')), findsOneWidget);
    expect(find.textContaining('Статья «Каркас»: подтверждённая → не выдавать'), findsOneWidget);
    expect(find.textContaining('Решение: выдать часть'), findsOneWidget);
    expect(find.text('Д. Рахимов'), findsWidgets);
  });

  testWidgets('an empty journal says so', (tester) async {
    final api = FakeApi(user: bankUser());
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('bank-journal-toggle')));
    await tester.tap(find.byKey(const Key('bank-journal-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-journal-empty')), findsOneWidget);
  });
}
