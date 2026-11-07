import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/models.dart';

import 'support.dart';

UserProfile _user() => const UserProfile(
      id: 'u1',
      name: 'Директор',
      login: 'dir@dev.uz',
      companyId: 'c1',
      companyName: 'Компания',
      active: true,
      memberships: [],
    );

void main() {
  testWidgets('mail: unread badge, reading marks it, a reply goes to the sender in the same thread', (tester) async {
    final api = FakeApi(user: _user())
      ..jsonAnswers['/api/mail/unread'] = {'count': 2}
      ..jsonAnswers['/api/mail/messages'] = {
        'folder': 'inbox',
        'items': [
          {'id': 'm1', 'thread_id': 't1', 'subject': 'Напоминание по объекту', 'at': '2026-10-28T08:00:00Z', 'unread': true, 'people': 'Банк Ким'},
        ],
      }
      ..jsonAnswers['/api/mail/messages/m1'] = {
        'id': 'm1',
        'threadId': 't1',
        'subject': 'Напоминание по объекту',
        'messages': [
          {'id': 'm1', 'sender_id': 'b1', 'sender': 'Банк Ким', 'subject': 'Напоминание по объекту', 'body': 'Просим передать отчёт', 'at': '2026-10-28T08:00:00Z', 'people': 'Директор', 'mine': false, 'recipient_ids': ['u1']},
        ],
      }
      ..jsonAnswers['/api/mail/contacts'] = {
        'items': [
          {'id': 'b1', 'name': 'Банк Ким', 'company': 'Банк', 'title': 'Администратор банка'},
          {'id': 'c2', 'name': 'Коллега', 'company': 'Компания', 'title': ''},
        ],
      };
    await pumpIBuildWith(tester, api);
    expect(find.byKey(const Key('mail-badge')), findsOneWidget);
    expect(find.text('2'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-mail')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mail-unread-m1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mail-item-m1')));
    await tester.pumpAndSettle();
    expect(find.text('Просим передать отчёт'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mail-reply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mail-to-b1')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('mail-body')), 'Отправим завтра');
    await tester.tap(find.byKey(const Key('mail-send')));
    await tester.pumpAndSettle();
    final sent = api.jsonCalls.lastWhere((c) => c.$1 == '/api/mail/messages' && c.$2 != null).$2!;
    expect(sent['to'], ['b1']);
    expect(sent['threadId'], 't1');
    expect(sent['subject'], 'Re: Напоминание по объекту');
    expect(sent['body'], 'Отправим завтра');
  });

  testWidgets('mail: a new letter needs a recipient', (tester) async {
    final api = FakeApi(user: _user())
      ..jsonAnswers['/api/mail/unread'] = {'count': 0}
      ..jsonAnswers['/api/mail/messages'] = {'folder': 'inbox', 'items': <dynamic>[]}
      ..jsonAnswers['/api/mail/contacts'] = {
        'items': [
          {'id': 'c2', 'name': 'Коллега', 'company': 'Компания', 'title': ''},
        ],
      };
    await pumpIBuildWith(tester, api);
    expect(find.byKey(const Key('mail-badge')), findsNothing);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/mail');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mail-compose')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mail-subject')), 'Тема');
    await tester.enterText(find.byKey(const Key('mail-body')), 'Текст');
    await tester.tap(find.byKey(const Key('mail-send')));
    await tester.pumpAndSettle();
    expect(api.jsonCalls.where((c) => c.$1 == '/api/mail/messages' && c.$2 != null), isEmpty);
    await tester.tap(find.byKey(const Key('mail-to-c2')));
    await tester.tap(find.byKey(const Key('mail-send')));
    await tester.pumpAndSettle();
    expect(api.jsonCalls.lastWhere((c) => c.$2 != null).$2!['to'], ['c2']);
  });

  testWidgets('admin creates an account and sees the temporary password once', (tester) async {
    final api = FakeApi(
      user: const UserProfile(
        id: 'user-admin', name: 'Админ iBuild', login: 'a.admin', companyId: 'c0', companyName: 'iBuild',
        active: true, memberships: [], platformAdmin: true,
      ),
    )
      ..jsonAnswers['/api/mail/unread'] = {'count': 0}
      ..jsonAnswers['/api/admin/overview'] = {'applications': <String, dynamic>{}, 'counts': <String, dynamic>{}, 'recent': <dynamic>[]}
      ..jsonAnswers['/api/admin/users'] = {'items': <dynamic>[], 'ok': true, 'password': 'Zq7wLm2PxK9tRb'}
      ..jsonAnswers['/api/admin/companies'] = {
        'items': [
          {
            'id': 'co1',
            'name': 'Застройщик',
            'kind': 'developer',
            'projects': [
              {'id': 'p1', 'name': 'ЖК Навои'},
              {'id': 'p2', 'name': 'ЖК Чиланзар'},
            ],
            'firms': <Map<String, dynamic>>[],
          },
        ],
      };
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-admin-users')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('user-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-company')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Застройщик').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('create-name')), 'Новый Человек');
    await tester.enterText(find.byKey(const Key('create-login')), 'new.man');
    expect(find.byKey(const Key('create-role')), findsNothing);
    expect(find.byKey(const Key('create-access-note')), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-project-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-role-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Технадзор').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-confirm')));
    await tester.pumpAndSettle();
    final sent = api.jsonCalls.lastWhere((c) => c.$1 == '/api/admin/users' && c.$2 != null).$2!;
    expect(sent['companyId'], 'co1');
    expect(sent['name'], 'Новый Человек');
    expect(sent['login'], 'new.man');
    expect(sent.containsKey('role'), isFalse);
    expect(sent['assignments'], [
      {'projectId': 'p1', 'role': 'tech'},
    ]);
    expect(find.text('Zq7wLm2PxK9tRb'), findsOneWidget);
  });
}
