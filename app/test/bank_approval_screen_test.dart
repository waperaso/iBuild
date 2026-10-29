import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/api.dart';

import 'bank_fixtures.dart';
import 'support.dart';

Future<FakeApi> _openApproval(
  WidgetTester tester, {
  bool canAct = true,
  String? blocker,
  bool committee = false,
  String? outcome,
  Size size = const Size(1280, 900),
}) async {
  final api = FakeApi(user: bankUser());
  api.bankApprovalCard = sampleBankApproval(
    canAct: canAct,
    blocker: blocker,
    committee: committee,
    outcome: outcome,
  );
  await pumpIBuildWith(tester, api, size: size);
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/bank/tranches/t-navoi/approval');
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
  testWidgets('the route shows who is done, who is next and what is outside', (tester) async {
    await _openApproval(tester);

    expect(_text(tester, 'bank-approval-title'), 'Транш №2 · согласование');
    expect(_text(tester, 'bank-step-expert-status'), 'Готово');
    expect(_text(tester, 'bank-step-expert-note'), 'Заключение по осмотру 23.10.2026 подписано');
    expect(
      _text(tester, 'bank-step-specialist-note'),
      'Подготовил решение: 1 723,9 млн UZS, принято с обоснованием: 0',
    );
    expect(_text(tester, 'bank-step-head-status'), 'Сейчас');
    expect(
      _text(tester, 'bank-step-head-note'),
      'Группа из 3 человек · нужно 1 согласие\nТот, кто готовил решение, согласовать его не может',
    );
    expect(_text(tester, 'bank-step-committee-status'), 'Не требуется');
    expect(
      _text(tester, 'bank-step-committee-note'),
      'Сумма 1 723,9 млн UZS меньше порога 2 000,0 млн UZS, блоков с обоснованием нет',
    );
  });

  testWidgets('the signature and the payment are locked and have no buttons', (tester) async {
    await _openApproval(tester);

    expect(_text(tester, 'bank-step-sign-note'), 'Доступна только после всех согласований');
    expect(_text(tester, 'bank-step-payment-note'), contains('Платёжные поручения создаёт АБС'));
    for (final code in ['sign', 'payment']) {
      expect(
        find.descendant(
          of: find.byKey(Key('bank-step-$code')),
          matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    }
  });

  testWidgets('the decision card and the lines going back to the developer', (tester) async {
    await _openApproval(tester);

    expect(_text(tester, 'bank-card-issue'), '1 723,9');
    expect(_text(tester, 'bank-card-returned'), '536,1');
    expect(_text(tester, 'bank-card-waived'), '0');
    expect(find.text('Срок на доработку: 5 рабочих дней'), findsOneWidget);
    expect(find.text('Объём в акте больше подтверждённого (ГС п. 3.6)'), findsOneWidget);
    expect(find.text('Нет сертификата соответствия (ГС п. 3.5)'), findsOneWidget);
  });

  testWidgets('a waived block shows the committee with who is on leave', (tester) async {
    await _openApproval(tester, committee: true);

    expect(_text(tester, 'bank-step-committee-status'), 'Ждёт');
    final note = _text(tester, 'bank-step-committee-note');
    expect(note, contains('Есть блок, принятый с обоснованием'));
    expect(note, contains('Группа из 5 человек · нужно 3 согласия'));
    expect(note, contains('Доступно 4, в отпуске: Директор по кредитованию'));
  });

  testWidgets('approve goes straight, return and reject ask for a reason', (tester) async {
    final api = await _openApproval(tester);

    await _tap(tester, 'bank-vote-approve');
    expect(api.bankCalls, ['vote:approve:']);

    await _tap(tester, 'bank-vote-return');
    await _tap(tester, 'bank-confirm-submit');
    expect(find.text('Опишите причину'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('bank-confirm-reason')), 'Приложите сертификат');
    await _tap(tester, 'bank-confirm-submit');
    expect(api.bankCalls.last, 'vote:return:Приложите сертификат');

    await _tap(tester, 'bank-vote-reject');
    await tester.enterText(find.byKey(const Key('bank-confirm-reason')), 'Не соответствует');
    await _tap(tester, 'bank-confirm-submit');
    expect(api.bankCalls.last, 'vote:reject:Не соответствует');
  });

  testWidgets('who cannot vote sees why and has no live buttons', (tester) async {
    for (final blocker in ['preparer', 'on_leave', 'not_member']) {
      await _openApproval(tester, canAct: false, blocker: blocker);
      for (final name in ['approve', 'return', 'reject']) {
        expect(_pressed(tester, 'bank-vote-$name'), isNull);
      }
      expect(find.byKey(const Key('bank-approval-blocker')), findsOneWidget);
    }
    await _openApproval(tester, canAct: false, blocker: 'on_leave');
    expect(find.text('Вы в отпуске и не участвуете в согласовании'), findsOneWidget);
  });

  testWidgets('a rejected tranche has no vote buttons', (tester) async {
    await _openApproval(tester, canAct: false, blocker: 'closed', outcome: 'rejected');
    expect(find.byKey(const Key('bank-approval-rejected')), findsOneWidget);
    expect(find.byKey(const Key('bank-vote-approve')), findsNothing);
  });

  testWidgets('a refusal is shown and the route is read again', (tester) async {
    final api = await _openApproval(tester);
    api.bankActionFails = const ApiException(409, 'Вы уже проголосовали');
    await _tap(tester, 'bank-vote-approve');
    expect(find.text('Вы уже проголосовали'), findsOneWidget);
  });

  testWidgets('the phone shows the route and then the card in one column', (tester) async {
    await _openApproval(tester, size: const Size(390, 844));
    expect(find.byKey(const Key('bank-route')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('bank-decision-card')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('back goes to the tranche card', (tester) async {
    await _openApproval(tester);
    await _tap(tester, 'bank-approval-back');
    expect(find.byKey(const Key('bank-tranche-frame')), findsOneWidget);
  });
}
