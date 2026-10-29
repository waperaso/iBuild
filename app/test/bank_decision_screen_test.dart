import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/widgets.dart';
import 'package:ibuild/api.dart';
import 'package:ibuild/screens/bank/bank_models.dart';

import 'bank_fixtures.dart';
import 'support.dart';

Future<FakeApi> _open(
  WidgetTester tester, {
  BankTranche? card,
  Size size = const Size(1280, 800),
}) async {
  final api = FakeApi(user: bankUser());
  api.bankCard = card;
  await pumpIBuildWith(tester, api, size: size);
  await tester.tap(find.byKey(const Key('bank-open-t-navoi')));
  await tester.pumpAndSettle();
  return api;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

VoidCallback? _pressed(WidgetTester tester, String key) {
  final widget = tester.widget(find.byKey(Key(key)));
  if (widget is PrimaryButton) return widget.onPressed;
  return (widget as ButtonStyleButton).onPressed;
}

String _text(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('an opened line shows the expert, the count, the photos and the payments', (tester) async {
    await _open(tester);
    expect(find.byKey(const Key('bank-line-l2-detail')), findsNothing);

    await _tap(tester, 'bank-line-toggle-l2');

    expect(find.byKey(const Key('bank-line-l2-detail')), findsOneWidget);
    expect(find.textContaining('Осмотр эксперта: А. Каримов, 23.10.2026, подписано'), findsOneWidget);
    expect(_text(tester, 'bank-line-l2-readiness'), 'Готовность 62% (было 26%)');
    expect(_text(tester, 'bank-line-l2-risk'), 'Признак риска: да');
    expect(
      _text(tester, 'bank-line-l2-formula'),
      '62% × 2 400,0 = 1 488,0 − выдано ранее 620,1 = 867,9',
    );
    expect(find.text('Секция А, плита'), findsOneWidget);
    expect(find.textContaining('Транш №1 (аванс), 02.09.2026'), findsOneWidget);

    await _tap(tester, 'bank-line-toggle-l2');
    expect(find.byKey(const Key('bank-line-l2-detail')), findsNothing);
  });

  testWidgets('a line without the expert says where the sum comes from', (tester) async {
    await _open(tester);
    await _tap(tester, 'bank-line-toggle-l1');
    expect(find.byKey(const Key('bank-line-l1-no-expert')), findsOneWidget);
  });

  testWidgets('requested is off while it is above confirmed, withhold is sent', (tester) async {
    final api = await _open(tester);
    await _tap(tester, 'bank-line-toggle-l2');

    FilledButton? filled(String key) => tester.widgetList<FilledButton>(find.byKey(Key(key))).firstOrNull;
    expect(filled('bank-choice-l2-confirmed'), isNotNull);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('bank-choice-l2-requested'))).onPressed, isNull);
    expect(find.byKey(const Key('bank-line-l2-above')), findsOneWidget);

    await _tap(tester, 'bank-choice-l2-withhold');
    expect(api.bankCalls, ['choose:l2:withhold']);
  });

  testWidgets('a stopped line can only be left unpaid', (tester) async {
    await _open(tester);
    await _tap(tester, 'bank-line-toggle-l4');

    expect(find.byKey(const Key('bank-line-l4-blocked')), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('bank-choice-l4-requested'))).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('bank-choice-l4-confirmed'))).onPressed, isNull);
    expect(find.byKey(const Key('bank-choice-l4-withhold')), findsOneWidget);
    expect(find.textContaining('не предъявлен'), findsOneWidget);
  });

  testWidgets('accepting with a reason needs a comment and sends the reason', (tester) async {
    final api = await _open(tester);

    await _tap(tester, 'bank-action-subcontractor-waive');
    expect(find.byKey(const Key('bank-waive-dialog')), findsOneWidget);
    expect(find.byKey(const Key('bank-waive-block-warning')), findsNothing);

    await _tap(tester, 'bank-waive-submit');
    expect(find.text('Опишите обоснование: оно останется в журнале'), findsOneWidget);
    expect(api.bankCalls, isEmpty);

    await _tap(tester, 'bank-waive-reason-fixed_elsewhere');
    await tester.enterText(find.byKey(const Key('bank-waive-comment')), 'Учтено в смете каркаса');
    await _tap(tester, 'bank-waive-submit');

    expect(api.bankCalls, ['waive:c3:fixed_elsewhere:Учтено в смете каркаса']);
    expect(find.byKey(const Key('bank-waive-dialog')), findsNothing);
  });

  testWidgets('a block warns that the committee will join, cancel changes nothing', (tester) async {
    final api = await _open(tester);

    await _tap(tester, 'bank-action-certificate-waive');
    expect(find.byKey(const Key('bank-waive-block-warning')), findsOneWidget);
    expect(find.text('Документ получен вне системы'), findsOneWidget);
    await _tap(tester, 'bank-waive-cancel');

    expect(api.bankCalls, isEmpty);
  });

  testWidgets('a request for a document is sent from the check', (tester) async {
    final api = await _open(tester);
    await _tap(tester, 'bank-action-certificate-request_document');
    expect(api.bankCalls, ['request:c1']);
  });

  testWidgets('the partial decision is confirmed first and carries a key', (tester) async {
    final api = await _open(tester);

    await _tap(tester, 'bank-decide-approve');
    expect(find.byKey(const Key('bank-confirm-dialog')), findsOneWidget);
    expect(find.textContaining('К выплате 1 723,9 млн UZS'), findsOneWidget);
    expect(find.byKey(const Key('bank-confirm-reason')), findsNothing);
    await _tap(tester, 'bank-confirm-submit');

    expect(api.bankCalls.length, 1);
    expect(api.bankCalls.single, matches(RegExp(r'^decide:partial::[0-9a-f]{32}$')));
  });

  testWidgets('return all asks for a reason, and a lost answer is retried with the same key', (tester) async {
    final api = await _open(tester);

    await _tap(tester, 'bank-decide-return');
    await _tap(tester, 'bank-confirm-submit');
    expect(find.text('Опишите причину'), findsOneWidget);
    expect(api.bankCalls, isEmpty);

    api.bankActionFails = const ApiException(0, 'Нет связи');
    await tester.enterText(find.byKey(const Key('bank-confirm-reason')), 'Нужен новый комплект');
    await _tap(tester, 'bank-confirm-submit');
    expect(find.text('Не получилось сохранить. Попробуйте ещё раз.'), findsOneWidget);

    api.bankActionFails = null;
    await _tap(tester, 'bank-decide-return');
    await tester.enterText(find.byKey(const Key('bank-confirm-reason')), 'Нужен новый комплект');
    await _tap(tester, 'bank-confirm-submit');

    expect(api.bankCalls.length, 2);
    final keys = api.bankCalls.map((call) => call.split(':').last).toSet();
    expect(keys.length, 1);
    expect(api.bankCalls.first, startsWith('decide:return_all:Нужен новый комплект:'));
  });

  testWidgets('a refusal of the server is shown as it is', (tester) async {
    final api = await _open(tester);
    api.bankActionFails = const ApiException(409, 'Выдать больше подтверждённого нельзя');

    await _tap(tester, 'bank-line-toggle-l2');
    await _tap(tester, 'bank-choice-l2-withhold');

    expect(find.text('Выдать больше подтверждённого нельзя'), findsOneWidget);
  });

  testWidgets('without the right to decide every action is off', (tester) async {
    await _open(
      tester,
      card: sampleBankTranche(permissions: const BankPermissions()),
    );

    for (final name in ['approve', 'return', 'measure', 'suspend']) {
      expect(_pressed(tester, 'bank-decide-$name'), isNull);
    }
    for (final key in ['certificate-waive', 'certificate-request_document', 'forecast-request_schedule']) {
      expect(tester.widget<OutlinedButton>(find.byKey(Key('bank-action-$key'))).onPressed, isNull);
    }
    expect(find.byKey(const Key('bank-decision-note')), findsOneWidget);
    expect(find.textContaining('Решение сейчас недоступно'), findsOneWidget);

    await _tap(tester, 'bank-line-toggle-l2');
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('bank-choice-l2-withhold'))).onPressed, isNull);
  });

  testWidgets('a tranche at the developer can be put back to work', (tester) async {
    final api = await _open(
      tester,
      card: sampleBankTranche(
        waiting: true,
        permissions: const BankPermissions(canResume: true, canSuspend: true),
      ),
    );

    expect(find.byKey(const Key('bank-banner-waiting')), findsOneWidget);
    await _tap(tester, 'bank-resume');
    expect(api.bankCalls, ['resume']);
  });

  testWidgets('after the decision the card links to the sign-off route', (tester) async {
    final moved = BankTranche.fromJson({
      'id': 't-navoi',
      'stage': 'approval',
      'stageLabel': 'Согласование',
      'projectName': 'ЖК Навои',
    });
    await _open(tester, card: moved);

    expect(find.byKey(const Key('bank-banner-sent')), findsOneWidget);
    await _tap(tester, 'bank-open-approval');

    expect(find.byKey(const Key('bank-approval-frame')), findsOneWidget);
  });

  testWidgets('an opened line and the dialogs fit a phone', (tester) async {
    await _open(tester, size: const Size(390, 844));
    await _tap(tester, 'bank-line-toggle-l2');
    expect(find.byKey(const Key('bank-line-l2-detail')), findsOneWidget);
    await _tap(tester, 'bank-action-certificate-waive');
    expect(find.byKey(const Key('bank-waive-dialog')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
