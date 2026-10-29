import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

UserProfile _forced() => const UserProfile(
      id: 'u1',
      name: 'Новый пользователь',
      login: 'new@dev.uz',
      companyId: 'c1',
      companyName: 'Компания',
      active: true,
      memberships: [],
      mustChangePassword: true,
    );

UserProfile _admin() => const UserProfile(
      id: 'user-admin',
      name: 'Админ iBuild',
      login: 'a.admin',
      companyId: 'company-0',
      companyName: 'iBuild',
      active: true,
      memberships: [],
      platformAdmin: true,
    );

void main() {
  testWidgets('a temporary password must be changed before anything else', (tester) async {
    final api = FakeApi(user: _forced());
    await pumpIBuildWith(tester, api);
    expect(find.byKey(const Key('password-frame')), findsOneWidget);
    expect(find.byKey(const Key('pw-cancel')), findsNothing);

    await tester.enterText(find.byKey(const Key('pw-current')), 'Temp-pass-14');
    await tester.enterText(find.byKey(const Key('pw-new')), 'short');
    await tester.enterText(find.byKey(const Key('pw-repeat')), 'short');
    await tester.tap(find.byKey(const Key('pw-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('не короче 10'), findsOneWidget);
    expect(api.passwordCalls, isEmpty);

    await tester.enterText(find.byKey(const Key('pw-new')), 'A-long-new-pass-1');
    await tester.enterText(find.byKey(const Key('pw-repeat')), 'A-long-new-pass-2');
    await tester.tap(find.byKey(const Key('pw-save')));
    await tester.pumpAndSettle();
    expect(find.text('Пароли не совпадают.'), findsOneWidget);
    expect(api.passwordCalls, isEmpty);

    await tester.enterText(find.byKey(const Key('pw-repeat')), 'A-long-new-pass-1');
    await tester.tap(find.byKey(const Key('pw-save')));
    await tester.pumpAndSettle();
    expect(api.passwordCalls, [('Temp-pass-14', 'A-long-new-pass-1')]);
    expect(find.byKey(const Key('password-frame')), findsNothing);
  });

  testWidgets('a wrong current password shows the server message', (tester) async {
    final api = FakeApi(user: _forced());
    await pumpIBuildWith(tester, api);
    await tester.enterText(find.byKey(const Key('pw-current')), 'wrong');
    await tester.enterText(find.byKey(const Key('pw-new')), 'A-long-new-pass-1');
    await tester.enterText(find.byKey(const Key('pw-repeat')), 'A-long-new-pass-1');
    await tester.tap(find.byKey(const Key('pw-save')));
    await tester.pumpAndSettle();
    expect(find.text('Текущий пароль указан неверно.'), findsOneWidget);
    expect(find.byKey(const Key('password-frame')), findsOneWidget);
  });

  testWidgets('the platform admin sees the mail queue and can send a test', (tester) async {
    final api = FakeApi(user: _admin())
      ..jsonAnswers['/api/admin/overview'] = {
        'applications': <String, dynamic>{},
        'counts': <String, dynamic>{},
        'recent': <dynamic>[],
      }
      ..jsonAnswers['/api/admin/mail'] = {
        'connected': false,
        'from': '',
        'counts': {'queued': 1},
        'items': [
          {'id': 'm1', 'kind': 'report', 'to': 'risk@bank.uz', 'subject': 'Отчёт: сроки', 'status': 'queued', 'error': '', 'attachment': 'x.xlsx', 'at': '2026-10-28T08:00:00Z', 'bank': 'Банк Навои'},
        ],
      };
    await pumpIBuildWith(tester, api, size: const Size(1280, 1000));
    await tester.tap(find.byKey(const Key('nav-admin-mail')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-mail-frame')), findsOneWidget);
    expect(find.textContaining('Почта не подключена'), findsOneWidget);
    expect(find.text('Отчёт: сроки'), findsOneWidget);
    expect(find.text('В очереди'), findsWidgets);

    api.jsonAnswers['/api/admin/mail/test'] = {'ok': true, 'mail': 'queued'};
    await tester.enterText(find.byKey(const Key('mail-test-to')), 'me@example.com');
    await tester.tap(find.byKey(const Key('mail-test')));
    await tester.pumpAndSettle();
    expect(api.jsonCalls.any((c) => c.$1 == '/api/admin/mail/test' && c.$2?['to'] == 'me@example.com'), isTrue);
  });
}
