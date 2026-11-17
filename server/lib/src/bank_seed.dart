import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'db.dart';
import 'passwords.dart';

const _navoiBankInn = '300000010';
const _chilonzorBankInn = '300000011';
const _portfolioInn = '300000012';

/// Adds the Bank Navoi cabinet on top of the developer pilot.
/// Existing observer logins stay on their projects and also become bank staff.
/// A second run does nothing.
Future<void> ensureBankCabinet(AppDatabase db, String password) async {
  final existing = await db.companyIdByInn(_navoiBankInn);
  if (existing != null) {
    await _decisionData(db);
    await _moreStaff(db, existing, password);
    await ensureApprovalRoutes(db);
    await ensureBankInspections(db);
    return;
  }
  if (password.isEmpty) {
    throw StateError('SEED_PASSWORD is required to create the bank cabinet');
  }
  final navoi = await db.companyIdByInn('300000001');
  final navoiProject = navoi == null ? null : await db.projectIdByName(navoi, 'Navoi Residences');
  final specialist = await db.userIdByLogin('a.observer');
  final other = await db.userIdByLogin('b.observer');
  if (navoiProject == null || specialist == null || other == null) return;

  final hash = hashPassword(password);
  final bank = await db.insertCompany(
    name: 'Navoi Bank',
    inn: _navoiBankInn,
    contact: 'pf@navoi-bank.uz',
  );
  final otherBank = await db.insertCompany(
    name: 'Chilanzar Bank',
    inn: _chilonzorBankInn,
    contact: 'credit@chilonzor-bank.uz',
  );
  final portfolio = await db.insertCompany(
    name: 'Bank Portfolio',
    inn: _portfolioInn,
    contact: 'portfolio@ibuild.uz',
  );
  await _profile(db, bank, 'project finance department');
  await _profile(db, otherBank, 'credit department');

  final expert = await _person(db, bank, hash, 'a.expert', 'A. Karimov', 'expert', 'Technical expert', 'Tashkent');
  final heads = [
    await _person(db, bank, hash, 'a.head1', 'A. Usmanov', 'head', 'Head of department', 'Tashkent, head office'),
    await _person(db, bank, hash, 'a.head2', 'N. Li', 'head', 'Head of department', 'Tashkent, Yunusabad'),
    await _person(db, bank, hash, 'a.head3', 'R. Akhmedov', 'head', 'Head of department', 'Tashkent, Chilanzar'),
  ];
  final committee = [
    await _person(db, bank, hash, 'a.committee1', 'Committee Chair', 'committee', 'Committee chair', 'Tashkent'),
    await _person(db, bank, hash, 'a.committee2', 'Deputy Chair', 'committee', 'Deputy chair', 'Tashkent'),
    await _person(db, bank, hash, 'a.committee3', 'Chief Risk Officer', 'committee', 'Chief risk officer', 'Tashkent'),
    await _person(db, bank, hash, 'a.committee4', 'Lending Director', 'committee', 'Lending director', 'Tashkent', leaveUntil: _inAWeek()),
    await _person(db, bank, hash, 'a.committee5', 'Bank Lawyer', 'committee', 'Bank lawyer', 'Tashkent'),
  ];
  await _staff(db, bankId: bank, userId: specialist, role: 'specialist', title: 'Credit specialist', branch: 'Tashkent, head office');
  await _staff(db, bankId: otherBank, userId: other, role: 'specialist', title: 'Credit specialist', branch: 'Tashkent');

  final headGroup = await _group(db, bank, 'heads', 'Heads of project finance departments', 1);
  final committeeGroup = await _group(db, bank, 'committee', 'Credit committee', 3);
  for (var i = 0; i < heads.length; i++) {
    await _member(db, headGroup, heads[i].id, heads[i].title, heads[i].branch);
  }
  for (final person in committee) {
    await _member(db, committeeGroup, person.id, person.title, person.branch);
  }

  await _moreStaff(db, bank, password);
  final rules = await _rules(db, bank);
  await _facility(
    db,
    projectId: navoiProject,
    bankId: bank,
    developer: 'Navoi Development',
    limit: '17500000000.00',
    issued: '1240100000.00',
    until: '2027-06-30',
  );

  final tranche = await _tranche(db, _Tranche(
    projectId: navoiProject,
    bankId: bank,
    rulesId: rules,
    no: 2,
    amount: '2260000000.00',
    confirmed: '2083900000.00',
    blocked: '360000000.00',
    issue: '1723900000.00',
    stage: 'specialist',
    stageLabel: 'Решение специалиста',
    sort: 1,
    holder: specialist,
    holderLabel: 'D. Rakhimov',
    days: 1,
    hours: 4,
    sla: 2,
    problems: '1 block · 3 warnings',
    signal: 'block',
    techConfirmed: '2026-10-24',
  ));
  await _navoiLines(db, tranche);
  await _navoiChecks(db, tranche);
  await _navoiSteps(db, tranche);
  await _decisionData(db);

  // Stage labels such as 'Согласование' stay as the server writes them: the app
  // translates them by that text (`trancheStageLabel`). Everything else is
  // demo data and is in English.
  const others = <_Site>[
    _Site('Sergeli Nur', 'Nur Invest Build', 'Sergeli, Tashkent', 3, '980000000.00', 'approval', 'Credit committee', 2, 'Committee', 4, 0, 3, false, 'Accepted with a reason: 1', 'warning'),
    _Site('Yunusabad Garden', 'YG Development', 'Yunusabad, Tashkent', 5, '1450000000.00', 'docs', 'Проверка документов', 3, 'D. Rakhimov', 0, 3, 1, false, '2 documents missing', 'warning'),
    _Site('Chilanzar Bahor', 'Bahor Qurilish', 'Chilanzar, Tashkent', 4, '3100000000.00', 'inspection', 'Inspection 27.10', 4, 'A. Karimov, expert', 2, 0, 5, false, 'Awaiting inspection', 'inspection'),
    _Site('Mirzo-Ulugbek Residences', 'MU Group', 'Mirzo-Ulugbek, Tashkent', 6, '2700000000.00', 'specialist', 'Возвращена застройщику', 5, 'Developer', 6, 0, 2, true, '2 lines to rework', 'developer'),
    _Site('Yangiabad Residences', 'Yangiobod Qurilish', 'Yangiabad, Tashkent', 1, '1000000000.00', 'approval', 'Согласование', 6, 'Head of department', 1, 0, 2, false, '', 'none'),
    _Site('Sergeli Residences 2', 'Nur Invest Build', 'Sergeli, Tashkent', 2, '1100000000.00', 'docs', 'Проверка документов', 7, 'Colleague', 0, 4, 1, false, '', 'none'),
    _Site('Almazar Residences', 'Almazar Stroy', 'Almazar, Tashkent', 1, '1200000000.00', 'inspection', 'Осмотр эксперта', 8, 'A. Karimov, expert', 1, 0, 5, false, 'Awaiting inspection', 'inspection'),
    _Site('Uchtepa Residences', 'Uchtepa House', 'Uchtepa, Tashkent', 1, '1300000000.00', 'payout', 'Выплата', 9, 'Payments department', 0, 6, 1, false, '', 'none'),
    _Site('Bektemir Residences', 'Bektemir Development', 'Bektemir, Tashkent', 1, '1400000000.00', 'specialist', 'Возвращена застройщику', 10, 'Developer', 2, 0, 2, true, '1 line to rework', 'developer'),
    _Site('Yakkasaray Residences', 'Yakkasaroy Build', 'Yakkasaray, Tashkent', 1, '1150000000.00', 'submitted', 'Submitted', 11, 'Developer', 1, 0, 1, true, 'Awaiting the document set', 'developer'),
    _Site('Shaykhantakhur Residences', 'Shaykhantahur Group', 'Shaykhantakhur, Tashkent', 1, '1100000000.00', 'approval', 'Согласование', 12, 'Head of department', 1, 2, 2, false, '', 'none'),
  ];
  for (final site in others) {
    final projectId = await db.insertProject(companyId: portfolio, name: site.name, address: site.address);
    await _facility(
      db,
      projectId: projectId,
      bankId: bank,
      developer: site.developer,
      limit: '5000000000.00',
      issued: '0.00',
      until: '2027-12-31',
    );
    final String? holder = site.name == 'Yunusabad Garden'
        ? specialist
        : site.name == 'Almazar Residences'
            ? expert.id
            : null;
    await _tranche(db, _Tranche(
      projectId: projectId,
      bankId: bank,
      rulesId: rules,
      no: site.no,
      amount: site.amount,
      confirmed: site.amount,
      blocked: '0.00',
      issue: site.amount,
      stage: site.stage,
      stageLabel: site.stageLabel,
      sort: site.sort,
      holder: holder,
      holderLabel: site.holderLabel,
      days: site.days,
      hours: site.hours,
      sla: site.sla,
      waiting: site.waiting,
      problems: site.problems,
      signal: site.signal,
    ));
  }
}

class _Person {
  const _Person(this.id, this.title, this.branch);
  final String id;
  final String title;
  final String branch;
}

class _Site {
  const _Site(
    this.name,
    this.developer,
    this.address,
    this.no,
    this.amount,
    this.stage,
    this.stageLabel,
    this.sort,
    this.holderLabel,
    this.days,
    this.hours,
    this.sla,
    this.waiting,
    this.problems,
    this.signal,
  );
  final String name;
  final String developer;
  final String address;
  final int no;
  final String amount;
  final String stage;
  final String stageLabel;
  final int sort;
  final String holderLabel;
  final int days;
  final int hours;
  final int sla;
  final bool waiting;
  final String problems;
  final String signal;
}

class _Tranche {
  const _Tranche({
    required this.projectId,
    required this.bankId,
    required this.rulesId,
    required this.no,
    required this.amount,
    required this.confirmed,
    required this.blocked,
    required this.issue,
    required this.stage,
    required this.stageLabel,
    required this.sort,
    required this.holderLabel,
    required this.days,
    required this.hours,
    required this.sla,
    required this.problems,
    required this.signal,
    this.holder,
    this.waiting = false,
    this.techConfirmed,
  });
  final String projectId;
  final String bankId;
  final String rulesId;
  final int no;
  final String amount;
  final String confirmed;
  final String blocked;
  final String issue;
  final String stage;
  final String stageLabel;
  final int sort;
  final String? holder;
  final String holderLabel;
  final int days;
  final int hours;
  final int sla;
  final bool waiting;
  final String problems;
  final String signal;
  final String? techConfirmed;
}

Future<void> _profile(AppDatabase db, String bankId, String department) {
  return db.pool.execute(
    Sql.named('''
      INSERT INTO bank_profiles (company_id, department)
      VALUES (@bank::uuid, @department)
    '''),
    parameters: {'bank': bankId, 'department': department},
  );
}

Future<_Person> _person(
  AppDatabase db,
  String bankId,
  String hash,
  String login,
  String name,
  String role,
  String title,
  String branch, {
  String? leaveUntil,
}) async {
  final id = await db.insertUser(companyId: bankId, name: name, login: login, passwordHash: hash);
  await _staff(db, bankId: bankId, userId: id, role: role, title: title, branch: branch, leaveUntil: leaveUntil);
  return _Person(id, title, branch);
}

Future<void> _staff(
  AppDatabase db, {
  required String bankId,
  required String userId,
  required String role,
  required String title,
  required String branch,
  String? leaveUntil,
}) {
  return db.pool.execute(
    Sql.named('''
      INSERT INTO bank_staff (bank_id, user_id, role, title, branch, on_leave_until)
      VALUES (@bank::uuid, @user::uuid, @role, @title, @branch, @leave::date)
    '''),
    parameters: {
      'bank': bankId,
      'user': userId,
      'role': role,
      'title': title,
      'branch': branch,
      'leave': leaveUntil,
    },
  );
}

Future<String> _group(AppDatabase db, String bankId, String code, String name, int required) async {
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO bank_groups (bank_id, code, name, required_approvals)
      VALUES (@bank::uuid, @code, @name, @required)
      RETURNING id::text
    '''),
    parameters: {'bank': bankId, 'code': code, 'name': name, 'required': required},
  );
  return rows.first[0]! as String;
}

Future<void> _member(AppDatabase db, String groupId, String userId, String title, String branch) {
  return db.pool.execute(
    Sql.named('''
      INSERT INTO bank_group_members (group_id, user_id, title, branch)
      VALUES (@group::uuid, @user::uuid, @title, @branch)
    '''),
    parameters: {'group': groupId, 'user': userId, 'title': title, 'branch': branch},
  );
}

/// The administrator and the risk manager of the bank, added to a stand that was
/// seeded before these roles existed.
Future<void> _moreStaff(AppDatabase db, String bank, String password) async {
  if (password.isEmpty) return;
  final hash = hashPassword(password);
  if (await db.userIdByLogin('a.bankadmin') == null) {
    await _person(db, bank, hash, 'a.bankadmin', 'E. Kim', 'admin', 'Bank administrator', 'Tashkent, head office');
  }
  if (await db.userIdByLogin('a.risk') == null) {
    await _person(db, bank, hash, 'a.risk', 'S. Aliev', 'risk', 'Risk manager', 'Tashkent, head office');
  }
}

Future<String> _rules(AppDatabase db, String bankId) async {
  final snapshot = jsonEncode({
    'committeeAmount': '2000000000.00',
    'issuedAbovePercent': 1,
    'scheduleLagMonths': 3,
    'forecastWarningDays': 30,
    'forecastRedMonths': 6,
    'salesReportDays': [15, 28],
    'stages': [
      {'code': 'docs', 'days': 1, 'owner': 'specialist'},
      {'code': 'inspection', 'days': 5, 'owner': 'expert'},
      {'code': 'specialist', 'days': 2, 'owner': 'specialist'},
      {'code': 'approval', 'days': 2, 'owner': 'head'},
      {'code': 'payout', 'days': 1, 'owner': 'payment'},
    ],
  });
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO bank_rule_versions (bank_id, version, effective_from, snapshot)
      VALUES (@bank::uuid, 7, DATE '2026-10-20', @snapshot::jsonb)
      RETURNING id::text
    '''),
    parameters: {'bank': bankId, 'snapshot': snapshot},
  );
  return rows.first[0]! as String;
}

Future<void> _facility(
  AppDatabase db, {
  required String projectId,
  required String bankId,
  required String developer,
  required String limit,
  required String issued,
  required String until,
}) {
  return db.pool.execute(
    Sql.named('''
      INSERT INTO project_facilities (
        project_id, bank_id, developer_name, credit_limit, issued_amount, utilize_until
      ) VALUES (
        @project::uuid, @bank::uuid, @developer, @limit::numeric, @issued::numeric, @until::date
      )
    '''),
    parameters: {
      'project': projectId,
      'bank': bankId,
      'developer': developer,
      'limit': limit,
      'issued': issued,
      'until': until,
    },
  );
}

Future<String> _tranche(AppDatabase db, _Tranche tranche) async {
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO bank_tranches (
        project_id, bank_id, rules_version_id, tranche_no, stage, stage_label, sort_order,
        holder_user_id, holder_label, waiting_developer, elapsed_days, elapsed_hours, sla_days,
        problems_label, signal, requested_amount, confirmed_amount, blocked_amount, issue_amount,
        submitted_at, tech_confirmed_on
      ) VALUES (
        @project::uuid, @bank::uuid, @rules::uuid, @no, @stage, @stageLabel, @sort,
        @holder::uuid, @holderLabel, @waiting, @days, @hours, @sla,
        @problems, @signal, @amount::numeric, @confirmed::numeric, @blocked::numeric, @issue::numeric,
        TIMESTAMPTZ '2026-10-24 18:10:00+05', @techConfirmed::date
      )
      RETURNING id::text
    '''),
    parameters: {
      'project': tranche.projectId,
      'bank': tranche.bankId,
      'rules': tranche.rulesId,
      'no': tranche.no,
      'stage': tranche.stage,
      'stageLabel': tranche.stageLabel,
      'sort': tranche.sort,
      'holder': tranche.holder,
      'holderLabel': tranche.holderLabel,
      'waiting': tranche.waiting,
      'days': tranche.days,
      'hours': tranche.hours,
      'sla': tranche.sla,
      'problems': tranche.problems,
      'signal': tranche.signal,
      'amount': tranche.amount,
      'confirmed': tranche.confirmed,
      'blocked': tranche.blocked,
      'issue': tranche.issue,
      'techConfirmed': tranche.techConfirmed,
    },
  );
  final id = rows.first[0]! as String;
  await db.pool.execute(
    Sql.named('''
      INSERT INTO bank_tranche_clock (tranche_id, stage, started_at, paused)
      VALUES (@tranche::uuid, @stage, now(), @paused)
    '''),
    parameters: {'tranche': id, 'stage': tranche.stage, 'paused': tranche.waiting},
  );
  return id;
}

Future<void> _navoiLines(AppDatabase db, String trancheId) async {
  const lines = <(int, String, String, String, String, String, String, String)>[
    (1, 'Excavation and earthworks', '620000000.00', '280000000.00', '100.00', '+31% since last', '280000000.00', '280000000.00'),
    (2, 'Foundation slab', '620100000.00', '980000000.00', '62.00', '+36% since last', '867900000.00', '867900000.00'),
    (3, 'Frame works, floors 1–4', '0.00', '640000000.00', '12.00', '+12% since last', '576000000.00', '576000000.00'),
    (4, 'Rebar A500C and concrete on site', '0.00', '360000000.00', '', 'in storage', '360000000.00', '0.00'),
  ];
  for (final line in lines) {
    await db.pool.execute(
      Sql.named('''
        INSERT INTO bank_tranche_lines (
          tranche_id, title, sort_order, issued_before, requested, readiness_percent,
          readiness_note, confirmed, to_issue, choice
        ) VALUES (
          @tranche::uuid, @title, @sort, @issued::numeric, @requested::numeric,
          NULLIF(@percent, '')::numeric, @note, @confirmed::numeric, @issue::numeric,
          CASE WHEN @issue::numeric = 0 THEN 'withhold' ELSE 'confirmed' END
        )
      '''),
      parameters: {
        'tranche': trancheId,
        'title': line.$2,
        'sort': line.$1,
        'issued': line.$3,
        'requested': line.$4,
        'percent': line.$5,
        'note': line.$6,
        'confirmed': line.$7,
        'issue': line.$8,
      },
    );
  }
}

Future<void> _navoiChecks(AppDatabase db, String trancheId) async {
  const open = <(String, String, String, String, String, int)>[
    ('certificate', 'block', 'Rule 3.5', 'No certificate of conformity for the rebar',
        'Line item “Rebar A500C and concrete on site”. Without the certificate the payment is not accepted. A request was sent to the developer on 25.10 at 09:12.', 1),
    ('above_confirmed', 'warning', 'Rule 3.6', 'Requested more than the expert confirmed',
        'Foundation slab: 980.0 vs 867.9. Frame works: 640.0 vs 576.0. By default the confirmed amount is set for payout.', 2),
    ('subcontractor', 'warning', 'Rule 3.4', 'Subcontractor is not on the approved register',
        'Monolit Stroy Servis LLC, frame works. Payment is allowed only for completed work — the expert confirmed 12% readiness.', 3),
    ('forecast', 'warning', 'Decree UP-11', 'Completion forecast is 46 days past the design deadline',
        'Design deadline — 30.06.2028, expert forecast — 15.08.2028. About 4.5 months remain before the six-month threshold after which buyers may terminate their contracts.', 4),
  ];
  for (final check in open) {
    await _check(db, trancheId, check.$1, check.$2, check.$3, check.$4, check.$5, check.$6, false);
  }
  const passed = <(String, String)>[
    ('Certificate of completed work attached', 'Rule 3.5'),
    ('Form 3 statement of work cost', 'Rule 4.12'),
    ('E-invoice or invoice for each payment', 'Rule 3.5'),
    ('Developer’s site supervision report submitted', 'Rule 4.2'),
    ('Contract with the contractor attached', 'Rule 3.5'),
    ('Contractor’s license is valid', 'Rule 3.5'),
    ('Remaining limit covers the tranche', 'Rule 3.7'),
    ('Project financing is not suspended', 'Rule 4.10'),
  ];
  for (var n = 1; n <= passed.length; n++) {
    final check = passed[n - 1];
    await _check(db, trancheId, 'passed_$n', 'reminder', check.$2, check.$1, '', 10 + n, true);
  }
}

Future<void> _check(
  AppDatabase db,
  String trancheId,
  String code,
  String level,
  String basis,
  String title,
  String detail,
  int sort,
  bool passed,
) {
  return db.pool.execute(
    Sql.named('''
      INSERT INTO bank_checks (tranche_id, code, level, basis, title, detail, sort_order, passed)
      VALUES (@tranche::uuid, @code, @level, @basis, @title, @detail, @sort, @passed)
    '''),
    parameters: {
      'tranche': trancheId,
      'code': code,
      'level': level,
      'basis': basis,
      'title': title,
      'detail': detail,
      'sort': sort,
      'passed': passed,
    },
  );
}

/// Every tranche of the portfolio gets the same six-step route the bridge
/// builds for a real one. Without it a tranche parked at the sign-off stage
/// opens on an empty route that nobody can move. Only fills tranches that have
/// no steps at all, so a second run and the Navoi demo route are untouched.
/// A tranche standing at the inspection stage is waiting for an expert to go
/// out and close the visit. Without a row here the "Inspections" screen is
/// empty and those tranches can never move. One planned visit per waiting
/// tranche, plus one that is already closed so the screen shows both states.
Future<void> ensureBankInspections(AppDatabase db) async {
  final seen = await db.owner.execute('SELECT count(*) FROM bank_inspections');
  if ((seen.first[0]! as int) > 0) return;
  final expert = await db.userIdByLogin('a.expert');
  final author = await db.userIdByLogin('a.observer');
  if (expert == null || author == null) return;
  await db.owner.execute(
    Sql.named(
      "INSERT INTO bank_inspections "
      '(tranche_id, project_id, bank_id, kind, status, scheduled_on, '
      'expert_user_id, expert_label, created_by, note) '
      "SELECT t.id, t.project_id, t.bank_id, 'control', 'planned', "
      "(now() AT TIME ZONE 'Asia/Tashkent')::date + 2, "
      "@expert::uuid, 'A. Karimov', @author::uuid, "
      "'Check the volume of completed work and the materials on site.' "
      "FROM bank_tranches t WHERE t.stage = 'inspection'",
    ),
    parameters: {'expert': expert, 'author': author},
  );
  // One finished visit, so the screen opens with both states on it.
  await db.owner.execute(
    Sql.named(
      "INSERT INTO bank_inspections "
      '(tranche_id, project_id, bank_id, kind, status, scheduled_on, '
      'expert_user_id, expert_label, created_by, note, completed_on, risk, recommendation) '
      "SELECT t.id, t.project_id, t.bank_id, 'control', 'done', "
      "(now() AT TIME ZONE 'Asia/Tashkent')::date - 17, "
      "@expert::uuid, 'A. Karimov', @author::uuid, "
      "'Foundation work volume partly confirmed.', "
      "(now() AT TIME ZONE 'Asia/Tashkent')::date - 17, 'watch', 'issue' "
      "FROM bank_tranches t WHERE t.stage = 'specialist' LIMIT 1",
    ),
    parameters: {'expert': expert, 'author': author},
  );
}

Future<void> ensureApprovalRoutes(AppDatabase db) async {
  final rows = await db.owner.execute(
    'SELECT t.id::text AS id, t.stage AS stage FROM bank_tranches t '
    'WHERE NOT EXISTS (SELECT 1 FROM bank_approval_steps s WHERE s.tranche_id = t.id)',
  );
  // How far the route has already run for a tranche standing at this stage.
  const doneThrough = <String, int>{
    'submitted': 0,
    'docs': 0,
    'inspection': 0,
    'specialist': 1,
    'approval': 2,
    'payout': 3,
  };
  const steps = <(String, int, int, String)>[
    ('expert', 1, 1, ''),
    ('specialist', 2, 1, ''),
    ('head', 3, 1, 'Group of 3, 1 approval needed'),
    ('committee', 4, 3, ''),
    ('sign', 5, 1, 'Digital signature (integration in development)'),
    ('payment', 6, 1, 'Payment (integration in development)'),
  ];
  for (final row in rows) {
    final map = row.toColumnMap();
    final id = map['id']! as String;
    final done = doneThrough['${map['stage']}'] ?? 0;
    for (final step in steps) {
      final position = step.$2;
      final status = position <= done
          ? 'done'
          : (step.$1 == 'sign' || step.$1 == 'payment')
              ? 'waiting'
              : 'pending';
      await db.owner.execute(
        Sql.named(
          'INSERT INTO bank_approval_steps '
          '(tranche_id, code, position, status, required_approvals, note) '
          'VALUES (@tranche::uuid, @code, @position, @status, @required, @note)',
        ),
        parameters: {
          'tranche': id,
          'code': step.$1,
          'position': position,
          'status': status,
          'required': step.$3,
          'note': step.$4,
        },
      );
    }
  }
}

Future<void> _navoiSteps(AppDatabase db, String trancheId) async {
  const steps = <(String, int, String, int, String)>[
    ('expert', 1, 'pending', 1, ''),
    ('specialist', 2, 'pending', 1, ''),
    ('head', 3, 'pending', 1, 'Group of 3, 1 approval needed'),
    ('committee', 4, 'skipped', 3, 'Amount below the threshold, no blocks accepted with a reason'),
    ('sign', 5, 'pending', 1, 'Digital signature (integration in development)'),
    ('payment', 6, 'pending', 1, 'Payment (integration in development)'),
  ];
  for (final step in steps) {
    await db.pool.execute(
      Sql.named('''
        INSERT INTO bank_approval_steps (tranche_id, code, position, status, required_approvals, note)
        VALUES (@tranche::uuid, @code, @position, @status, @required, @note)
      '''),
      parameters: {
        'tranche': trancheId,
        'code': step.$1,
        'position': step.$2,
        'status': step.$3,
        'required': step.$4,
        'note': step.$5,
      },
    );
  }
}

/// Evidence, expert conclusion, history of payments and the finished steps of the
/// demo tranche of Bank Navoi. Runs once: on a fresh stand right after the seed
/// and on a stand that was seeded before the decision screens existed.
Future<void> _decisionData(AppDatabase db) async {
  final seen = await db.pool.execute('SELECT count(*) FROM bank_line_photos');
  if ((seen.first[0] as int) > 0) return;
  for (final statement in _decisionSql.split(';')) {
    if (statement.trim().isEmpty) continue;
    await db.pool.execute(statement);
  }
}

const _decisionSql = r'''
UPDATE bank_tranche_lines AS l
SET plan_amount = v.plan_amount,
    previous_percent = v.previous_percent,
    expert_name = 'A. Karimov',
    expert_signed_on = DATE '2026-10-23',
    expert_note = v.note,
    remaining_to_build = v.remaining,
    recommended = l.confirmed,
    risk_flag = v.risk
FROM (
  VALUES
    ('Excavation and earthworks', 900000000.00, 69.00,
     'Excavation is down to the design level. The hidden works certificate is signed.', 0.00, false),
    ('Foundation slab', 2400000000.00, 26.00,
     'Sections A and B are concreted. In section B, pour 3 is not concreted — reinforcement is 80% done.',
     912000000.00, true),
    ('Frame works, floors 1–4', 4800000000.00, 0.00,
     'Frame for floors 1–2 is erected, floors 3–4 are in progress.', 4224000000.00, false),
    ('Rebar A500C and concrete on site', NULL, NULL,
     'Rebar is in the site storage. The batch certificate has not been provided.', NULL, false)
) AS v (title, plan_amount, previous_percent, note, remaining, risk)
WHERE l.title = v.title
  AND l.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

UPDATE bank_tranche_lines AS l
SET block_check_id = c.id,
    choice = 'confirmed'
FROM bank_checks AS c
WHERE c.tranche_id = l.tranche_id
  AND c.code = 'certificate'
  AND l.title = 'Rebar A500C and concrete on site'
  AND l.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

INSERT INTO bank_line_photos (line_id, caption, meta, sort_order)
SELECT l.id, v.caption, v.meta, v.sort_order
FROM bank_tranche_lines AS l
JOIN (
  VALUES
    ('Foundation slab', 'Section A, slab', '23.10 10:42 · 41.3022, 69.2403', 1),
    ('Foundation slab', 'Section B, pour 3', '23.10 10:55 · 41.3018, 69.2409', 2),
    ('Foundation slab', 'Same angle, previous inspection', '26.09 11:03', 3),
    ('Excavation and earthworks', 'Excavation, general view', '23.10 10:20 · 41.3025, 69.2401', 1)
) AS v (line_title, caption, meta, sort_order) ON v.line_title = l.title
WHERE l.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

INSERT INTO bank_line_documents (line_id, title, state, sort_order)
SELECT l.id, v.title, v.state, v.sort_order
FROM bank_tranche_lines AS l
JOIN (
  VALUES
    ('Foundation slab', 'Certificate of completed work No. 14, lines 2.1–2.6', 'ok', 1),
    ('Foundation slab', 'Form 3 statement No. 14', 'ok', 2),
    ('Foundation slab', 'E-invoice from Monolit Servis LLC', 'ok', 3),
    ('Foundation slab', 'Concrete works log, hidden works certificate', 'ok', 4),
    ('Excavation and earthworks', 'Certificate of completed work No. 14, line 1.1', 'ok', 1),
    ('Excavation and earthworks', 'E-invoice from Monolit Servis LLC', 'ok', 2),
    ('Frame works, floors 1–4', 'Certificate of completed work No. 14, lines 3.1–3.4', 'ok', 1),
    ('Frame works, floors 1–4', 'E-invoice from Monolit Stroy Servis LLC', 'ok', 2),
    ('Rebar A500C and concrete on site', 'Certificate of conformity for the rebar', 'missing', 1),
    ('Rebar A500C and concrete on site', 'Delivery note', 'ok', 2)
) AS v (line_title, title, state, sort_order) ON v.line_title = l.title
WHERE l.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

INSERT INTO bank_line_payments (line_id, label, paid_on, amount)
SELECT l.id, 'Tranche No. 1 (advance)', DATE '2026-09-02', l.issued_before
FROM bank_tranche_lines AS l
WHERE l.issued_before > 0
  AND l.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

UPDATE bank_approval_steps AS s
SET status = 'done',
    actor_label = 'A. Karimov',
    decided_at = TIMESTAMPTZ '2026-10-23 17:30:00+05'
WHERE s.code = 'expert'
  AND s.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

UPDATE bank_approval_steps AS s
SET status = 'waiting',
    note = ''
WHERE s.code IN ('sign', 'payment')
  AND s.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

UPDATE bank_approval_steps AS s
SET reason = 'below_threshold',
    note = ''
WHERE s.code = 'committee'
  AND s.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');

UPDATE bank_approval_steps AS s
SET note = ''
WHERE s.code IN ('head', 'expert', 'specialist')
  AND s.tranche_id IN (SELECT id FROM bank_tranches WHERE problems_label = '1 block · 3 warnings');
''';

/// The demo director is always on leave for another week, whatever the date.
String _inAWeek() {
  final day = DateTime.now().toUtc().add(const Duration(hours: 5, days: 7));
  return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
