import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/models.dart';
import 'package:ibuild/registration_models.dart';
import 'package:ibuild/registration_spec.dart';

import 'support.dart';

const _tall = Size(1280, 5200);
const _veryTall = Size(1280, 8000);

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
}

Future<void> _pickChoice(WidgetTester tester, String key, String label) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _fillBank(WidgetTester tester) async {
  await _type(tester, 'reg-org_full_name', 'АКБ «Тест»');
  await _type(tester, 'reg-inn', '200111222');
  await _type(tester, 'reg-bank_mfo', '00999');
  await _type(tester, 'reg-license_number', '№ 55');
  await tester.tap(find.byKey(const Key('reg-license_date')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(DatePickerDialog), matching: find.byType(TextButton)).last,
  );
  await tester.pumpAndSettle();
  await _type(tester, 'reg-legal_address', 'г. Ташкент');
  await _pickChoice(tester, 'reg-region', 'город Ташкент');
  await _type(tester, 'reg-org_phone', '712000000');
  await _type(tester, 'reg-org_email', 'bank@example.uz');
  await _type(tester, 'reg-contact_name', 'Дилноза');
  await _type(tester, 'reg-contact_position', 'Начальник отдела');
  await _type(tester, 'reg-contact_phone', '+998 90 111 22 33');
  await _type(tester, 'reg-contact_email', 'dilnoza@example.uz');
  await _pickChoice(tester, 'reg-authority_basis', 'Доверенности');
  await _pickChoice(tester, 'reg-call_time', 'В любое время');
  await _pickChoice(tester, 'reg-language', 'Русский');
  await tester.tap(find.byKey(const Key('interest-escrow')));
  await tester.pump();
}

ApplicationDetail _detail({
  String status = 'calling',
  bool checked = false,
  List<String> missing = const [],
}) {
  return ApplicationDetail(
    id: 'app-1',
    code: 'IB-00001',
    kind: 'developer',
    status: status,
    orgName: 'ООО «Тест Девелопмент»',
    inn: '301234567',
    contactName: 'Пётр Контактов',
    phone: '+998901112233',
    email: 'petr@example.uz',
    data: const {
      'org_full_name': 'ООО «Тест Девелопмент»',
      'legal_form': 'llc',
      'charter_capital': '500000000',
      'object_name': 'ЖК «Тестовый»',
      'owners': [
        {'kind': 'person', 'name': 'Иван', 'tax_id': '31205880120045', 'share': '100'},
      ],
    },
    checks: {for (final key in developerCheckKeys) key: checked},
    checkKeys: developerCheckKeys,
    requestNote: '',
    decisionNote: '',
    nextCallOn: null,
    createdAt: DateTime(2026, 10, 20),
    consentAt: DateTime(2026, 10, 20, 10),
    consentVersion: '2026-10',
    documents: const [ApplicationFile(id: 'f1', type: 'charter', name: 'ustav.pdf')],
    requiredTypes: const ['charter'],
    missing: missing,
    events: [
      ApplicationEvent(
        kind: 'created',
        outcome: '',
        body: '',
        createdAt: DateTime(2026, 10, 20),
        author: '',
      ),
    ],
  );
}

const developerCheckKeys = [
  'registry',
  'director',
  'owners',
  'screening',
  'land_permit',
  'expertise',
  'bank_account',
  'callback',
];

void main() {
  testWidgets('the sign-in page offers registration and a bank can apply', (tester) async {
    final api = await pumpIBuild(tester, size: _tall);
    await tester.tap(find.byKey(const Key('register-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-kind-developer')), findsOneWidget);
    expect(find.byKey(const Key('register-kind-bank')), findsOneWidget);

    await tester.tap(find.byKey(const Key('register-kind-bank')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-section-org')), findsOneWidget);
    expect(find.byKey(const Key('doc-bank_license')), findsOneWidget);

    // Nothing filled: the form points at what is missing and sends nothing.
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Проверьте отмеченные поля.'), findsOneWidget);
    expect(find.text('Заполните это поле'), findsWidgets);
    expect(api.submissions, isEmpty);

    await _fillBank(tester);
    // Both consents are still needed.
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Поставьте обе галочки, чтобы отправить заявку.'), findsOneWidget);
    expect(api.submissions, isEmpty);

    await tester.tap(find.byKey(const Key('consent-data')));
    await tester.tap(find.byKey(const Key('consent-truth')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

    expect(api.submissions, hasLength(1));
    final sent = api.submissions.single;
    expect(sent.kind, 'bank');
    expect(sent.data['contact_phone'], '+998901112233');
    expect(sent.data['inn'], '200111222');
    expect(sent.data['interests'], ['escrow']);
    expect(sent.data['license_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(find.byKey(const Key('register-sent')), findsOneWidget);
    expect(find.text('IB-00001'), findsOneWidget);

    // The link on this page opens the applicant's own status.
    api.statusFixture = const ApplicationStatusView(
      id: 'app-1',
      code: 'IB-00001',
      kind: 'bank',
      status: 'docs_requested',
      orgName: 'АКБ «Тест»',
      requestNote: 'Пришлите приказ о назначении.',
      decisionNote: '',
      documents: [],
      missing: ['bank_license', 'authority'],
      canUpload: true,
    );
    await tester.tap(find.byKey(const Key('sent-open-status')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-status')), findsOneWidget);
    expect(find.text('Нужны документы'), findsOneWidget);
    expect(find.text('Пришлите приказ о назначении.'), findsOneWidget);
    expect(find.byKey(const Key('status-add-bank_license')), findsOneWidget);
  });

  testWidgets('the developer form is long and asks for owners and papers', (tester) async {
    await pumpIBuild(tester, size: _veryTall);
    await tester.tap(find.byKey(const Key('register-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-kind-developer')));
    await tester.pumpAndSettle();

    for (final id in ['org', 'director', 'owners', 'licenses', 'object', 'bank', 'contact', 'documents']) {
      expect(find.byKey(Key('register-section-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('doc-land_rights')), findsOneWidget);
    expect(find.byKey(const Key('doc-expertise_conclusion')), findsOneWidget);

    // Shares above 100% are caught before anything is sent.
    await tester.tap(find.byKey(const Key('add-owner')));
    await tester.pump();
    await _type(tester, 'owner-name-0', 'Иван');
    await _type(tester, 'owner-tax-0', '31205880120045');
    await _type(tester, 'owner-share-0', '70');
    await _type(tester, 'owner-name-1', 'ООО «Холдинг»');
    await _type(tester, 'owner-tax-1', '304112233');
    await _type(tester, 'owner-share-1', '45');
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Доли вместе больше 100%'), findsOneWidget);
  });

  testWidgets('the admin works an application from call to approval', (tester) async {
    final admin = UserProfile(
      id: 'admin-1',
      name: 'Админ',
      login: 'a.admin',
      companyId: 'company-0',
      companyName: 'iBuild',
      active: true,
      platformAdmin: true,
      memberships: const [],
    );
    final api = FakeApi(user: admin);
    api.board = ApplicationBoard(
      counts: const {'new': 1, 'calling': 1, 'docs_requested': 0, 'in_review': 0, 'approved': 0, 'rejected': 0},
      items: [
        ApplicationItem(
          id: 'app-1',
          code: 'IB-00001',
          kind: 'developer',
          status: 'calling',
          orgName: 'ООО «Тест Девелопмент»',
          inn: '301234567',
          contactName: 'Пётр Контактов',
          phone: '+998901112233',
          createdAt: DateTime.now(),
          nextCallOn: null,
          documents: 1,
          missingDocs: 3,
        ),
      ],
    );
    api.detailFixture = _detail(missing: const ['land_rights']);
    await pumpIBuildWith(tester, api, size: const Size(1400, 2400));

    await tester.tap(find.byKey(const Key('nav-applications')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('application-app-1')), findsOneWidget);
    expect(find.text('Не хватает документов: 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('application-app-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('application-status')), findsOneWidget);
    expect(find.text('ЖК «Тестовый»'), findsOneWidget);
    expect(find.textContaining('Иван · 31205880120045 · 100%'), findsOneWidget);

    // Approval is shut while checks are open and a paper is missing.
    final approve = tester.widget<FilledButton>(
      find.descendant(of: find.byKey(const Key('app-approve')), matching: find.byType(FilledButton)),
    );
    expect(approve.onPressed, isNull);
    expect(find.byKey(const Key('approve-blocker')), findsOneWidget);

    await tester.tap(find.byKey(const Key('check-registry')));
    await tester.pumpAndSettle();
    expect(api.applicationActions, contains('check:registry:true'));

    await tester.tap(find.byKey(const Key('app-log-call')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('call-note')), 'Подтвердили');
    await tester.tap(find.byKey(const Key('call-save')));
    await tester.pumpAndSettle();
    expect(api.applicationActions, contains('call:reached:Подтвердили:'));

    await tester.tap(find.byKey(const Key('app-request-docs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text-dialog-save')));
    await tester.pumpAndSettle();
    expect(find.text('Заполните это поле'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('request-note-field')), 'Нужна экспертиза');
    await tester.tap(find.byKey(const Key('text-dialog-save')));
    await tester.pumpAndSettle();
    expect(api.applicationActions, contains('status:docs_requested:Нужна экспертиза'));

    // Everything checked and nothing missing: approve and see the new login.
    api.detailFixture = _detail(checked: true);
    api.approvalFixture = ApprovalResult(
      application: _detail(status: 'approved', checked: true),
      account: const ApprovedAccount(
        login: 'petr@example.uz',
        password: 'Abcd2345Xy',
        company: 'ООО «Тест Девелопмент»',
        project: 'ЖК «Тестовый»',
      ),
    );
    await tester.tap(find.byKey(const Key('app-add-note')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('app-note')), 'Всё хорошо');
    await tester.tap(find.byKey(const Key('app-add-note')));
    await tester.pumpAndSettle();
    expect(api.applicationActions, contains('note:Всё хорошо'));

    await tester.tap(find.byKey(const Key('app-approve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approve-confirm')));
    await tester.pumpAndSettle();
    expect(api.applicationActions, contains('approve'));
    expect(find.byKey(const Key('account-dialog')), findsOneWidget);
    expect(find.text('Abcd2345Xy'), findsOneWidget);
    expect(find.text('petr@example.uz'), findsWidgets);
    await tester.tap(find.byKey(const Key('account-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-dialog')), findsNothing);
  });

  test('every form field has a label in all three languages', () {
    for (final kind in ['developer', 'bank']) {
      for (final field in allFields(kind)) {
        expect(field.label.$1, isNotEmpty, reason: field.key);
        expect(field.label.$2, isNotEmpty, reason: field.key);
        expect(field.label.$3, isNotEmpty, reason: field.key);
        for (final choice in field.choices) {
          expect(choice.label.$3, isNotEmpty, reason: '${field.key}/${choice.code}');
        }
      }
      for (final doc in docsFor(kind)) {
        expect(doc.title.$3, isNotEmpty, reason: doc.type);
        expect(doc.hint.$3, isNotEmpty, reason: doc.type);
      }
    }
    for (final entry in checkLabels.entries) {
      expect(entry.value.$3, isNotEmpty, reason: entry.key);
    }
  });
}
