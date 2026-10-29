import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild/models.dart';

import 'bank_fixtures.dart';
import 'support.dart';

UserProfile _bankAs(String role) {
  return UserProfile(
    id: 'user-$role',
    name: 'Тест $role',
    login: 'a.$role',
    companyId: 'company-1',
    companyName: 'Банк Навои',
    active: true,
    memberships: const [Membership(projectId: 'project-1', role: AppRole.observer)],
    bank: BankProfile(
      id: 'bank-1',
      name: 'Банк Навои',
      department: 'отдел',
      role: role,
      title: role,
      branch: 'Ташкент',
      queueCount: 0,
      trancheCount: 0,
      waitingAmount: '0.00',
    ),
  );
}

UserProfile _platformAdmin() {
  return const UserProfile(
    id: 'user-admin',
    name: 'Админ iBuild',
    login: 'a.admin',
    companyId: 'company-0',
    companyName: 'iBuild',
    active: true,
    memberships: [],
    platformAdmin: true,
  );
}

final _portfolio = <String, dynamic>{
  'bankName': 'Банк Навои',
  'issued': '18740000000.00',
  'limit': '60000000000.00',
  'kpi': {'objects': 3, 'attention': 2, 'tranchesInWork': 4, 'averageDays': 5.5},
  'signals': [
    {
      'projectId': 'p1',
      'projectName': 'ЖК Навои',
      'level': 'warning',
      'code': 'sales_report',
      'title': 'x',
      'basis': 'ГС п. 5.9',
      'action': 'remind',
      'params': {'date': '2026-10-28'},
    },
    {
      'projectId': 'p2',
      'projectName': 'ЖК Сергели',
      'level': 'block',
      'code': 'paused',
      'title': 'x',
      'basis': 'ГС п. 4.10',
      'action': 'open',
      'params': <String, dynamic>{},
    },
  ],
  'moreObjects': 1,
  'stageDays': [
    {'code': 'docs', 'days': 1.0},
    {'code': 'inspection', 'days': 3.5},
    {'code': 'specialist', 'days': 1.0},
    {'code': 'approval', 'days': 0.0},
    {'code': 'payout', 'days': 0.0},
  ],
  'deadlines': [
    {'day': '2026-11-02', 'kind': 'inspection', 'title': 'Осмотр ЖК Навои', 'note': 'А. Каримов'},
  ],
};

final _objects = <String, dynamic>{
  'items': [
    {'id': 'p1', 'name': 'ЖК Навои', 'address': 'Ташкент', 'developer': 'Навои Девелопмент', 'paused': false, 'until': '2027-06-01', 'credit_limit': '60000000000.00', 'issued': '18000000000.00', 'level': 'warning', 'signalCount': 1},
    {'id': 'p2', 'name': 'ЖК Сергели', 'address': 'Ташкент', 'developer': 'Сергели Строй', 'paused': true, 'until': '2027-01-01', 'credit_limit': '9000000000.00', 'issued': '1000000000.00', 'level': 'block', 'signalCount': 1},
    {'id': 'p3', 'name': 'ЖК Тихий', 'address': 'Самарканд', 'developer': 'Тихий Дом', 'paused': false, 'until': null, 'credit_limit': '5000000000.00', 'issued': '0.00', 'level': 'ok', 'signalCount': 0},
  ],
};

final _object = <String, dynamic>{
  'object': {'id': 'p1', 'name': 'ЖК Навои', 'address': 'Ташкент', 'developer': 'Навои Девелопмент', 'paused': false, 'until': '2027-06-01', 'credit_limit': '60000000000.00', 'issued': '18000000000.00', 'left': '42000000000.00'},
  'signals': (_portfolio['signals'] as List).take(1).toList(),
  'budget': [
    {'title': 'Кладка', 'plan': '1000000000.00', 'issued': '300000000.00', 'percent': '40', 'confirmed': '400000000.00'},
    {'title': 'Отделка', 'plan': null, 'issued': '0.00', 'percent': null, 'confirmed': null},
  ],
  'tranches': [
    {'id': 't1', 'no': 3, 'stage': 'inspection', 'stage_label': 'Осмотр эксперта', 'requested': '500000000.00', 'issue': '0.00', 'signal': 'none', 'submitted': '2026-10-20T05:00:00Z'},
  ],
  'inspections': [
    {'id': 'i1', 'kind': 'control', 'status': 'done', 'scheduled': '2026-10-10', 'completed': '2026-10-10', 'expert': 'А. Каримов', 'risk': 'watch', 'recommendation': 'withhold', 'note': 'Отстаём от графика', 'finish': '2027-08-01'},
  ],
  'documents': [
    {'title': 'Разрешение на строительство', 'number': '№ 12', 'issued': '2025-01-10', 'note': ''},
  ],
  'filings': [
    {'kind': 'sales', 'period': '2026-09-28', 'filed': '2026-09-29'},
  ],
};

final _inspections = <String, dynamic>{
  'items': [
    {'id': 'i-plan', 'project_id': 'p1', 'project_name': 'ЖК Навои', 'kind': 'control', 'status': 'planned', 'scheduled': '2027-01-10', 'completed': null, 'expert': 'Test expert', 'expert_id': 'user-expert', 'risk': null, 'recommendation': null, 'note': '', 'finish': null},
    {'id': 'i-late', 'project_id': 'p2', 'project_name': 'ЖК Сергели', 'kind': 'regular', 'status': 'overdue', 'scheduled': '2026-09-01', 'completed': null, 'expert': 'Другой эксперт', 'expert_id': 'user-other', 'risk': null, 'recommendation': null, 'note': '', 'finish': null},
    {'id': 'i-done', 'project_id': 'p1', 'project_name': 'ЖК Навои', 'kind': 'control', 'status': 'done', 'scheduled': '2026-10-10', 'completed': '2026-10-10', 'expert': 'А. Каримов', 'expert_id': 'user-x', 'risk': 'ok', 'recommendation': 'issue', 'note': '', 'finish': null},
  ],
  'counts': {'planned': 1, 'done': 1, 'overdue': 1},
  'experts': [
    {'id': 'user-expert', 'name': 'Test expert'},
  ],
  'objects': [
    {'id': 'p1', 'name': 'ЖК Навои'},
  ],
  'canPlan': true,
  'canComplete': true,
};

final _developer = <String, dynamic>{
  'id': 'd1',
  'name': 'Навои Девелопмент',
  'contact': '+998 71 000 00 00',
  'limit': '60000000000.00',
  'issued': '18000000000.00',
  'objects': [
    {'id': 'p1', 'name': 'ЖК Навои'},
  ],
  'salesReport': {'period': '2026-10-28', 'filed': 0, 'of': 1},
  'quarterly': {'period': '2026-Q3', 'filed': 1, 'of': 1},
  'supervision': {'regular': 1, 'of': 1},
  'returns': {'total': 4, 'returned': 1},
  'responseHours': '30.0',
  'reasons': [
    {'reason': 'Нет акта', 'n': 2},
  ],
  'salesPeriod': '2026-10-28',
  'recentReturns': <dynamic>[],
  'canFile': true,
};

final _rules = <String, dynamic>{
  'version': 7,
  'effectiveFrom': '2026-10-20',
  'rules': {
    'committeeAmount': '2000000000.00',
    'issuedAbovePercent': 1,
    'scheduleLagMonths': 3,
    'forecastWarningDays': 30,
    'forecastRedMonths': 6,
    'salesReportDays': [15, 28],
    'remindGroup': true,
    'stages': [
      {'code': 'docs', 'days': 1, 'owner': 'specialist'},
      {'code': 'inspection', 'days': 5, 'owner': 'expert'},
      {'code': 'specialist', 'days': 2, 'owner': 'specialist'},
      {'code': 'approval', 'days': 2, 'owner': 'head'},
      {'code': 'payout', 'days': 1, 'owner': 'payment'},
    ],
    'documents': [
      {'code': 'act', 'title': 'Акт выполненных работ', 'when': 'каждый транш', 'obligation': 'Обязателен', 'effect': 'block', 'basis': 'ГС п. 3.5'},
    ],
  },
  'history': [
    {'version': 7, 'effectiveFrom': '2026-10-20', 'author': 'Е. Ким', 'note': 'Первая версия', 'changed': <dynamic>[]},
  ],
  'groups': [
    {
      'code': 'heads',
      'name': 'Начальники отделов',
      'required': 1,
      'members': [
        {'userId': 'u1', 'name': 'А. Усманов', 'title': 'Начальник отдела', 'branch': 'Ташкент', 'onLeaveUntil': null, 'active': true},
        {'userId': 'u2', 'name': 'Н. Ли', 'title': 'Начальник отдела', 'branch': 'Ташкент', 'onLeaveUntil': '2026-11-02', 'active': true},
      ],
    },
  ],
  'changes': <dynamic>[],
};

final _reports = <String, dynamic>{
  'catalog': [
    {'group': 'money', 'code': 'portfolio_summary', 'title': 'Сводка по портфелю', 'subtitle': 'x'},
    {'group': 'time', 'code': 'stage_time', 'title': 'Время транша по этапам', 'subtitle': 'x'},
    {'group': 'control', 'code': 'returns', 'title': 'Возвраты', 'subtitle': 'x'},
    {'group': 'audit', 'code': 'waived', 'title': 'Принято', 'subtitle': 'x'},
  ],
  'branches': ['Ташкент'],
  'objects': [
    {'id': 'p1', 'name': 'ЖК Навои'},
  ],
  'schedules': <dynamic>[],
  'canSchedule': true,
};

final _report = <String, dynamic>{
  'code': 'portfolio_summary',
  'title': 'Сводка по портфелю',
  'summary': [
    {'label': 'Объектов', 'value': '3', 'tone': ''},
  ],
  'columns': [
    {'key': 'name', 'label': 'Объект', 'kind': 'text'},
    {'key': 'limit', 'label': 'Лимит', 'kind': 'money'},
  ],
  'rows': [
    {'name': 'ЖК Навои', 'limit': '60000000000.00'},
  ],
  'note': '',
  'schedule': {'enabled': false, 'recipients': ''},
};

void main() {
  testWidgets('the portfolio shows numbers, the attention list in the language and the days per stage', (tester) async {
    final api = FakeApi(user: _bankAs('specialist'))..jsonAnswers['/api/bank/portfolio'] = _portfolio;
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-portfolio')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bank-portfolio-frame')), findsOneWidget);
    expect(find.text('Требуют внимания'), findsOneWidget);
    expect(find.text('Не сдан отчёт о продажах за 28.10.2026'), findsOneWidget);
    expect(find.text('Финансирование приостановлено'), findsOneWidget);
    expect(find.textContaining('Основание: ГС п. 5.9'), findsOneWidget);
    expect(find.byKey(const Key('portfolio-stage-days')), findsOneWidget);
    expect(find.text('3.5 дн.'), findsOneWidget);
    expect(find.text('02.11.2026'), findsOneWidget);

    // The reminder goes to the server and says that no mail leaves.
    api.jsonAnswers['/api/bank/objects/p1/remind'] = {'ok': true, 'mail': 'queued'};
    await tester.tap(find.byKey(const Key('signal-p1-sales_report')));
    await tester.pumpAndSettle();
    expect(api.jsonCalls.any((c) => c.$1 == '/api/bank/objects/p1/remind' && c.$2?['kind'] == 'sales_report'), isTrue);
    expect(find.textContaining('Письмо ждёт в очереди'), findsOneWidget);
  });

  testWidgets('the portfolio tells an empty bank that all is well', (tester) async {
    final calm = {..._portfolio, 'signals': <dynamic>[], 'kpi': {'objects': 0, 'attention': 0, 'tranchesInWork': 0, 'averageDays': null}};
    final api = FakeApi(user: _bankAs('specialist'))..jsonAnswers['/api/bank/portfolio'] = calm;
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-portfolio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('portfolio-no-signals')), findsOneWidget);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('a failed load shows the error and a retry', (tester) async {
    final api = FakeApi(user: _bankAs('specialist'));
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-portfolio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reload')), findsOneWidget);
    api.jsonAnswers['/api/bank/portfolio'] = _portfolio;
    await tester.tap(find.byKey(const Key('reload')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-portfolio-frame')), findsOneWidget);
  });

  testWidgets('objects: filter and open the personal file', (tester) async {
    final api = FakeApi(user: _bankAs('specialist'))
      ..jsonAnswers['/api/bank/objects'] = _objects
      ..jsonAnswers['/api/bank/objects/p1'] = _object;
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-objects')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('object-p1')), findsOneWidget);
    expect(find.byKey(const Key('object-p3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('objects-filter-paused')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('object-p2')), findsOneWidget);
    expect(find.byKey(const Key('object-p1')), findsNothing);

    await tester.tap(find.byKey(const Key('objects-filter-all')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('objects-search')), 'Тихий');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('object-p3')), findsOneWidget);
    expect(find.byKey(const Key('object-p1')), findsNothing);

    await tester.enterText(find.byKey(const Key('objects-search')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('object-p1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-object-frame')), findsOneWidget);
    expect(find.byKey(const Key('object-budget')), findsOneWidget);
    expect(find.text('Кладка'), findsOneWidget);
    expect(find.text('нет данных'), findsOneWidget);
    expect(find.text('Отстаём от графика'), findsOneWidget);
    expect(find.text('Разрешение на строительство'), findsOneWidget);
    expect(find.byKey(const Key('object-tranche-t1')), findsOneWidget);
  });

  testWidgets('inspections: counts, filters, the expert closes only his own visit', (tester) async {
    final api = FakeApi(user: _bankAs('expert'))..jsonAnswers['/api/bank/inspections'] = _inspections;
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-inspections')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-inspection')), findsOneWidget);
    expect(find.byKey(const Key('complete-i-plan')), findsOneWidget);
    // The default view is the planned ones; the overdue one belongs to another expert.
    await tester.tap(find.byKey(const Key('inspections-filter-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('complete-i-late')), findsNothing);
    expect(find.byKey(const Key('complete-i-done')), findsNothing);

    await tester.tap(find.byKey(const Key('complete-i-plan')));
    await tester.pumpAndSettle();
    // Nothing chosen: the form refuses and sends nothing.
    await tester.tap(find.byKey(const Key('complete-save')));
    await tester.pumpAndSettle();
    expect(find.text('Укажите риск и рекомендацию'), findsOneWidget);
    expect(api.jsonCalls.where((c) => c.$2 != null), isEmpty);

    await tester.tap(find.byKey(const Key('risk-watch')));
    await tester.tap(find.byKey(const Key('recommendation-withhold')));
    await tester.enterText(find.byKey(const Key('complete-note')), 'Отстаём');
    await tester.pump();
    await tester.tap(find.byKey(const Key('complete-save')));
    await tester.pumpAndSettle();
    final sent = api.jsonCalls.lastWhere((c) => c.$2 != null);
    expect(sent.$1, '/api/bank/inspections/i-plan/complete');
    expect(sent.$2, {'risk': 'watch', 'recommendation': 'withhold', 'note': 'Отстаём'});
  });

  testWidgets('a specialist cannot close a visit and an admin can close any', (tester) async {
    final specialist = FakeApi(user: _bankAs('specialist'))..jsonAnswers['/api/bank/inspections'] = {..._inspections, 'canComplete': false};
    await pumpIBuildWith(tester, specialist);
    await tester.tap(find.byKey(const Key('nav-bank-inspections')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('complete-i-plan')), findsNothing);

    final admin = FakeApi(user: _bankAs('admin'))..jsonAnswers['/api/bank/inspections'] = _inspections;
    await pumpIBuildWith(tester, admin);
    await tester.tap(find.byKey(const Key('nav-bank-inspections')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inspections-filter-overdue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('complete-i-late')), findsOneWidget);
  });

  testWidgets('developers: a summary of facts, and the detail with the report form', (tester) async {
    final api = FakeApi(user: _bankAs('specialist'))
      ..jsonAnswers['/api/bank/developers'] = {
        'items': [
          {..._developer, 'objects': 1},
        ],
      }
      ..jsonAnswers['/api/bank/developers/d1'] = _developer;
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-developers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('developer-d1')), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('developer-d1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-developer-frame')), findsOneWidget);
    expect(find.text('Нет акта'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('file-report')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.descendant(of: find.byKey(const Key('filing-save')), matching: find.byType(FilledButton))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('filing-project')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ЖК Навои').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filing-save')));
    await tester.pumpAndSettle();
    final sent = api.jsonCalls.lastWhere((c) => c.$2 != null);
    expect(sent.$1, '/api/bank/developers/d1/filings');
    expect(sent.$2, {'projectId': 'p1', 'kind': 'sales', 'period': '2026-10-28'});
  });

  testWidgets('reports: catalog in four groups, a table, export and the schedule', (tester) async {
    final api = FakeApi(user: _bankAs('head'))
      ..jsonAnswers['/api/bank/reports'] = _reports
      ..jsonAnswers['/api/bank/reports/portfolio_summary'] = _report
      ..jsonAnswers['/api/bank/reports/portfolio_summary/schedule'] = {'ok': true};
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-reports')));
    await tester.pumpAndSettle();
    for (final code in ['portfolio_summary', 'stage_time', 'returns', 'waived']) {
      expect(find.byKey(Key('report-$code')), findsOneWidget);
    }
    expect(find.text('Деньги'), findsOneWidget);
    expect(find.text('Аудит'), findsOneWidget);

    await tester.tap(find.byKey(const Key('report-portfolio_summary')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-report-frame')), findsOneWidget);
    expect(find.byKey(const Key('report-table')), findsOneWidget);
    expect(find.text('ЖК Навои'), findsOneWidget);
    expect(find.text('60 000,0'), findsOneWidget);
    for (final format in ['xlsx', 'pdf', 'csv']) {
      expect(find.byKey(Key('export-$format')), findsOneWidget);
    }
    // The period and the filters go to the server in the query.
    expect(api.jsonCalls.any((c) => c.$1.startsWith('/api/bank/reports/portfolio_summary?from=') && c.$1.contains('&to=')), isTrue);

    await tester.ensureVisible(find.byKey(const Key('schedule-switch')));
    await tester.tap(find.byKey(const Key('schedule-switch')));
    await tester.enterText(find.byKey(const Key('schedule-recipients')), 'risk@bank.uz');
    await tester.ensureVisible(find.byKey(const Key('schedule-save')));
    await tester.tap(find.byKey(const Key('schedule-save')));
    await tester.pumpAndSettle();
    final sent = api.jsonCalls.lastWhere((c) => c.$2 != null);
    expect(sent.$2, {'enabled': true, 'recipients': 'risk@bank.uz'});
    expect(find.byKey(const Key('schedule-saved')), findsOneWidget);
    expect(find.textContaining('По понедельникам с 9:00'), findsOneWidget);
  });

  testWidgets('rules are for the administrator only; others see no menu item', (tester) async {
    final api = FakeApi(user: _bankAs('specialist'));
    await pumpIBuildWith(tester, api);
    expect(find.byKey(const Key('nav-bank-rules')), findsNothing);
    expect(find.byKey(const Key('nav-bank-journal')), findsNothing);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/bank/rules');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rules-denied')), findsOneWidget);
    expect(api.jsonCalls, isEmpty);
  });

  testWidgets('rules: change a threshold and a stage, save as a new version', (tester) async {
    final api = FakeApi(user: _bankAs('admin'))
      ..jsonAnswers['/api/bank/rules'] = _rules;
    await pumpIBuildWith(tester, api, size: const Size(1280, 1800));
    await tester.tap(find.byKey(const Key('nav-bank-rules')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rules-thresholds')), findsOneWidget);
    expect(find.textContaining('Версия 7'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('rule-above')), '3');
    await tester.ensureVisible(find.byKey(const Key('stage-more-inspection')));
    await tester.tap(find.byKey(const Key('stage-more-inspection')));
    await tester.pump();
    expect(find.text('6 раб. дн.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('rules-note')), 'Ослабили допуск');
    await tester.ensureVisible(find.byKey(const Key('rules-save')));
    await tester.pumpAndSettle();
    expect(find.text('Сохранить как версию 8'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rules-save')));
    await tester.pumpAndSettle();
    final sent = api.jsonCalls.lastWhere((c) => c.$2 != null);
    expect(sent.$1, '/api/bank/rules');
    expect(sent.$2!['issuedAbovePercent'], 3);
    expect(sent.$2!['note'], 'Ослабили допуск');
    expect(sent.$2!['committeeAmount'], '2000000000');
    expect(((sent.$2!['stages'] as List).firstWhere((s) => (s as Map)['code'] == 'inspection') as Map)['days'], 6);
  });

  testWidgets('rules: a bad number is refused on the screen, nothing is sent', (tester) async {
    final api = FakeApi(user: _bankAs('admin'))..jsonAnswers['/api/bank/rules'] = _rules;
    await pumpIBuildWith(tester, api, size: const Size(1280, 1800));
    await tester.tap(find.byKey(const Key('nav-bank-rules')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rule-lag')), 'abc');
    await tester.ensureVisible(find.byKey(const Key('rules-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rules-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Проверьте числа'), findsOneWidget);
    expect(api.jsonCalls.where((c) => c.$2 != null), isEmpty);
  });

  testWidgets('rules: documents are edited, groups and leave, the log of versions', (tester) async {
    final api = FakeApi(user: _bankAs('admin'))..jsonAnswers['/api/bank/rules'] = _rules;
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-bank-rules')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rules-tab-documents')));
    await tester.pumpAndSettle();
    expect(find.text('Акт выполненных работ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('doc-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('doc-title-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('doc-remove-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('doc-title-1')), findsNothing);

    await tester.tap(find.byKey(const Key('rules-tab-groups')));
    await tester.pumpAndSettle();
    expect(find.text('А. Усманов'), findsOneWidget);
    expect(find.textContaining('в отпуске до 02.11.2026'), findsOneWidget);
    api.jsonAnswers['/api/bank/rules/members/u2'] = {'ok': true};
    await tester.tap(find.byKey(const Key('leave-u2')));
    await tester.pumpAndSettle();
    final sent = api.jsonCalls.lastWhere((c) => c.$2 != null);
    expect(sent.$1, '/api/bank/rules/members/u2');
    expect(sent.$2, {'onLeaveUntil': null});

    await tester.tap(find.byKey(const Key('rules-tab-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rules-history')), findsOneWidget);
    expect(find.text('Первая версия'), findsWidgets);
  });

  testWidgets('the journal of the bank is in the menu for the audit roles', (tester) async {
    final api = FakeApi(user: _bankAs('risk'))
      ..jsonAnswers['/api/bank/audit'] = {
        'items': [
          {'id': 'e1', 'action': 'rules_saved', 'actor': 'Е. Ким', 'at': '2026-10-28T08:00:00Z', 'tranche_id': null, 'project': ''},
          {'id': 'e2', 'action': 'decision', 'actor': 'А. Усманов', 'at': '2026-10-28T09:00:00Z', 'tranche_id': 't1', 'project': 'ЖК Навои'},
        ],
        'actions': ['decision', 'rules_saved'],
      };
    await pumpIBuildWith(tester, api);
    expect(find.byKey(const Key('nav-bank-rules')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-bank-journal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audit-list')), findsOneWidget);
    expect(find.text('Сохранена новая версия правил'), findsOneWidget);
    expect(find.text('Решение по траншу'), findsOneWidget);
    expect(find.text('Е. Ким'), findsOneWidget);
  });

  testWidgets('a platform administrator gets a workspace of their own', (tester) async {
    final api = FakeApi(user: _platformAdmin())
      ..jsonAnswers['/api/admin/overview'] = {
        'applications': {'new': 2, 'in_review': 1, 'approved': 5},
        'counts': {'banks': 1, 'developers': 4, 'users_active': 20, 'users_disabled': 1, 'projects': 6, 'changes_pending': 2, 'tranches': 9, 'tranches_blocked': 1, 'failed_logins': 3, 'sessions': 4},
        'oldestOpenApplication': '2026-10-20T05:00:00Z',
        'recent': [
          {'action': 'users.reset-password', 'actor': 'Админ iBuild', 'target': 'x', 'at': '2026-10-28T08:00:00Z'},
        ],
      };
    await pumpIBuildWith(tester, api);
    expect(find.byKey(const Key('admin-overview-frame')), findsOneWidget);
    expect(find.byKey(const Key('nav-home')), findsNothing);
    expect(find.byKey(const Key('project-rail')), findsNothing);
    for (final key in ['nav-admin-overview', 'nav-applications', 'nav-moderation', 'nav-admin-companies', 'nav-admin-users', 'nav-admin-events', 'nav-admin-system']) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.text('Панель администратора'), findsOneWidget);
    expect(find.byKey(const Key('todo-applications')), findsOneWidget);
    expect(find.text('Заявки на регистрацию: 3'), findsOneWidget);
    expect(find.text('Правки объектов на проверке: 2'), findsOneWidget);
    expect(find.text('Выдан новый пароль'), findsOneWidget);

    // A developer page sends the administrator back to the workspace.
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-overview-frame')), findsOneWidget);
  });

  testWidgets('admin users: switch off asks first, a new password is shown once', (tester) async {
    final users = {
      'items': [
        {'id': 'user-admin', 'name': 'Админ iBuild', 'login': 'a.admin', 'active': true, 'platform_admin': true, 'company': 'iBuild', 'bank_role': null, 'last_seen': null},
        {'id': 'u-tech', 'name': 'Технадзор', 'login': 'a.tech', 'active': true, 'platform_admin': false, 'company': 'Навои', 'bank_role': null, 'last_seen': '2026-10-28T08:00:00Z'},
      ],
    };
    final api = FakeApi(user: _platformAdmin())
      ..jsonAnswers['/api/admin/overview'] = {'applications': <String, dynamic>{}, 'counts': <String, dynamic>{}, 'recent': <dynamic>[]}
      ..jsonAnswers['/api/admin/users'] = users
      ..jsonAnswers['/api/admin/users/u-tech/active'] = {'ok': true}
      ..jsonAnswers['/api/admin/users/u-tech/reset-password'] = {'password': 'Xk3mP9qRtW4zNb'};
    await pumpIBuildWith(tester, api);
    await tester.tap(find.byKey(const Key('nav-admin-users')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('user-toggle-user-admin')), findsNothing, reason: 'nobody turns themself off');
    expect(find.byKey(const Key('user-toggle-u-tech')), findsOneWidget);

    await tester.tap(find.byKey(const Key('user-toggle-u-tech')));
    await tester.pumpAndSettle();
    expect(api.jsonCalls.where((c) => c.$2 != null), isEmpty, reason: 'it asks first');
    await tester.tap(find.byKey(const Key('user-confirm')));
    await tester.pumpAndSettle();
    expect(api.jsonCalls.lastWhere((c) => c.$2 != null).$2, {'active': false});

    await tester.tap(find.byKey(const Key('user-reset-u-tech')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-password')), findsOneWidget);
    expect(find.text('Xk3mP9qRtW4zNb'), findsOneWidget);
    await tester.tap(find.byKey(const Key('password-close')));
    await tester.pumpAndSettle();
    expect(find.text('Xk3mP9qRtW4zNb'), findsNothing);
  });

  testWidgets('admin companies, journal and system show what the server sends', (tester) async {
    final api = FakeApi(user: _platformAdmin())
      ..jsonAnswers['/api/admin/overview'] = {'applications': <String, dynamic>{}, 'counts': <String, dynamic>{}, 'recent': <dynamic>[]}
      ..jsonAnswers['/api/admin/companies'] = {
        'items': [
          {'id': 'c1', 'name': 'Навои Девелопмент', 'inn': '300000001', 'kind': 'developer', 'users': 6, 'users_active': 5, 'projects': 2, 'created_at': '2026-01-10T05:00:00Z'},
          {'id': 'c2', 'name': 'Банк Навои', 'inn': '300000099', 'kind': 'bank', 'users': 9, 'users_active': 9, 'projects': 0, 'created_at': '2026-01-11T05:00:00Z'},
        ],
      }
      ..jsonAnswers['/api/admin/events'] = {
        'items': [
          {'id': 'a1', 'action': 'applications.approve', 'actor': 'Админ iBuild', 'target': 'x', 'at': '2026-10-28T08:00:00Z', 'target_name': 'ООО Тест'},
        ],
        'actions': ['applications.approve'],
      }
      ..jsonAnswers['/api/admin/system'] = {
        'database': {'ok': true, 'latencyMs': 4, 'version': 'PostgreSQL 16.4', 'sizeBytes': 12 * 1024 * 1024},
        'migrations': {'n': 25, 'last': '025_bank_modules'},
        'tables': [
          {'name': 'bank_audit_events', 'rows': 120},
        ],
        'server': {'startedAt': '2026-10-28T00:00:00Z', 'uptimeSeconds': 7200, 'environment': 'production', 'version': '1'},
        'backup': {'file': 'ibuild.dump', 'at': DateTime.now().toUtc().toIso8601String(), 'sizeBytes': 2048},
      };
    await pumpIBuildWith(tester, api);

    await tester.tap(find.byKey(const Key('nav-admin-companies')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('company-c1')), findsOneWidget);
    expect(find.text('Банк'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-admin-events')));
    await tester.pumpAndSettle();
    expect(find.text('Заявка одобрена, компания создана'), findsWidgets);
    expect(find.text('ООО Тест'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-admin-system')));
    await tester.pumpAndSettle();
    expect(find.text('Работает'), findsOneWidget);
    expect(find.text('Свежая'), findsOneWidget);
    expect(find.text('bank_audit_events'), findsOneWidget);
  });

  testWidgets('a bank user is kept out of the admin pages, a developer too', (tester) async {
    final api = FakeApi(user: bankUser());
    await pumpIBuildWith(tester, api);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/admin');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-queue-frame')), findsOneWidget);
    expect(api.jsonCalls.where((c) => c.$1.startsWith('/api/admin')), isEmpty);

    await pumpIBuild(tester, user: demoUser(AppRole.director));
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/admin/users');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav-home')), findsOneWidget);
    expect(find.byKey(const Key('admin-users-frame')), findsNothing);
  });
}
