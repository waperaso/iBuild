import 'package:ibuild/models.dart';
import 'package:ibuild/screens/bank/bank_models.dart';

UserProfile bankUser() {
  return const UserProfile(
    id: 'user-bank',
    name: 'Д. Рахимов',
    login: 'a.observer',
    companyId: 'company-1',
    companyName: 'Навои Девелопмент',
    active: true,
    memberships: [Membership(projectId: 'project-1', role: AppRole.observer)],
    bank: bankSpecialist,
  );
}

const bankSpecialist = BankProfile(
  id: 'bank-1',
  name: 'Банк Навои',
  department: 'отдел проектного финансирования',
  role: 'specialist',
  title: 'Кредитный специалист',
  branch: 'Ташкент, главный офис',
  queueCount: 2,
  trancheCount: 12,
  waitingAmount: '18740000000.00',
);

BankQueueItem _item(
  String id,
  String name, {
  required int no,
  required String amount,
  required String stage,
  required String stageLabel,
  required int days,
  required int hours,
  required int sla,
  required String problems,
  required String holder,
  required String signal,
  bool waiting = false,
  bool overdue = false,
  bool mine = false,
}) {
  return BankQueueItem(
    id: id,
    projectName: name,
    developerName: 'Застройщик $name',
    trancheNo: no,
    requestedAmount: amount,
    stage: stage,
    stageLabel: stageLabel,
    elapsedDays: days,
    elapsedHours: hours,
    slaDays: sla,
    problemsLabel: problems,
    holderLabel: holder,
    signal: signal,
    waitingDeveloper: waiting,
    overdue: overdue,
    mine: mine,
  );
}

List<BankQueueItem> sampleBankItems() => [
  _item('t-navoi', 'ЖК Навои',
      no: 2, amount: '2260000000.00', stage: 'specialist', stageLabel: 'Решение специалиста',
      days: 1, hours: 4, sla: 2, problems: '1 блок · 3 предупреждения', holder: 'Д. Рахимов',
      signal: 'block', mine: true),
  _item('t-sergeli', 'ЖК Сергели Нур',
      no: 3, amount: '980000000.00', stage: 'approval', stageLabel: 'Кредитный комитет',
      days: 4, hours: 0, sla: 3, problems: 'Принято с обоснованием: 1', holder: 'Комитет',
      signal: 'warning', overdue: true),
  _item('t-yunusabad', 'ЖК Юнусабад Гарден',
      no: 5, amount: '1450000000.00', stage: 'docs', stageLabel: 'Проверка документов',
      days: 0, hours: 3, sla: 1, problems: 'Нет 2 документов', holder: 'Д. Рахимов',
      signal: 'warning', mine: true),
  _item('t-chilanzar', 'ЖК Чиланзар Бахор',
      no: 4, amount: '3100000000.00', stage: 'inspection', stageLabel: 'Осмотр 27.10',
      days: 2, hours: 0, sla: 5, problems: 'Ждёт осмотра', holder: 'А. Каримов, эксперт',
      signal: 'inspection'),
  _item('t-mirzo', 'ЖК Мирзо-Улугбек',
      no: 6, amount: '2700000000.00', stage: 'specialist', stageLabel: 'Возвращена застройщику',
      days: 6, hours: 0, sla: 2, problems: '2 строки на доработку', holder: 'Застройщик',
      signal: 'developer', waiting: true),
];

BankQueue sampleBankQueue(String tab, [List<BankQueueItem>? source]) {
  final items = source ?? sampleBankItems();
  final shown = items.where((item) {
    return switch (tab) {
      'mine' => item.mine,
      'developer' => item.waitingDeveloper,
      'overdue' => item.overdue,
      _ => true,
    };
  }).toList();
  return BankQueue(
    bankName: 'Банк Навои',
    department: 'отдел проектного финансирования',
    tab: tab,
    counts: BankQueueCounts(
      mine: items.where((item) => item.mine).length,
      all: items.length,
      developer: items.where((item) => item.waitingDeveloper).length,
      overdue: items.where((item) => item.overdue).length,
    ),
    waitingAmount: '18740000000.00',
    items: shown,
  );
}

BankTranche sampleBankTranche({
  String id = 't-navoi',
  String blocked = '360000000.00',
  BankPermissions permissions = const BankPermissions(
    canDecide: true,
    canRequest: true,
    canSuspend: true,
  ),
  bool waiting = false,
}) {
  return BankTranche(
    permissions: permissions,
    id: id,
    projectId: 'project-navoi',
    projectName: 'ЖК Навои',
    projectAddress: 'Ташкент, улица Бабура, 12',
    developerName: 'Навои Девелопмент',
    trancheNo: 2,
    stage: 'specialist',
    stageLabel: 'Решение специалиста',
    stages: const [
      BankStage(code: 'submitted', state: 'done'),
      BankStage(code: 'docs', state: 'done'),
      BankStage(code: 'inspection', state: 'done'),
      BankStage(code: 'specialist', state: 'current'),
      BankStage(code: 'approval', state: 'pending'),
      BankStage(code: 'payout', state: 'pending'),
    ],
    waitingDeveloper: waiting,
    submittedDate: '24.10.2026',
    submittedTime: '18:10',
    techConfirmed: '24.10',
    elapsedDays: 1,
    elapsedHours: 4,
    slaDays: 2,
    overdue: false,
    rulesVersion: 7,
    creditLimit: '17500000000.00',
    issuedTotal: '1240100000.00',
    totals: BankTotals(
      requested: '2260000000.00',
      confirmed: '2083900000.00',
      blocked: blocked,
      issue: '1723900000.00',
      returned: '536100000.00',
      remaining: '14536000000.00',
    ),
    openChecks: const [
      BankCheck(
        id: 'c1', code: 'certificate', level: 'block', basis: 'ГС п. 3.5',
        title: 'Нет сертификата соответствия на арматуру',
        detail: 'Статья «Арматура A500C и бетон на площадке». Без сертификата платёж не принимается.',
        passed: false, actions: ['request_document', 'waive'],
      ),
      BankCheck(
        id: 'c2', code: 'above_confirmed', level: 'warning', basis: 'ГС п. 3.6',
        title: 'Запрошено больше, чем подтвердил эксперт',
        detail: 'Фундаментная плита: 980,0 против 867,9.',
        passed: false, actions: ['waive'],
      ),
      BankCheck(
        id: 'c3', code: 'subcontractor', level: 'warning', basis: 'ГС п. 3.4',
        title: 'Субподрядчик не в согласованном реестре',
        detail: 'ООО «Монолит Строй Сервис», каркас.',
        passed: false, actions: ['waive'],
      ),
      BankCheck(
        id: 'c4', code: 'forecast', level: 'warning', basis: 'УП-11',
        title: 'Прогноз сдачи позже срока ПСД на 46 дней',
        detail: 'Срок по ПСД — 30.06.2028, прогноз эксперта — 15.08.2028.',
        passed: false, actions: ['request_schedule'],
      ),
    ],
    passedChecks: [
      for (var n = 1; n <= 8; n++)
        BankCheck(
          id: 'p$n', code: 'passed_$n', level: 'reminder', basis: 'ГС п. 3.$n',
          title: 'Пройденная проверка номер $n', detail: '', passed: true, actions: const [],
        ),
    ],
    lines: const [
      BankLine(
        id: 'l1', title: 'Котлован и земляные работы', issuedBefore: '620000000.00',
        requested: '280000000.00', readinessPercent: '100', readinessNote: '+31% с прошлого',
        confirmed: '280000000.00', toIssue: '280000000.00', choice: 'confirmed', level: 'ok',
      ),
      BankLine(
        id: 'l2', title: 'Фундаментная плита', issuedBefore: '620100000.00',
        requested: '980000000.00', readinessPercent: '62', readinessNote: '+36% с прошлого',
        confirmed: '867900000.00', toIssue: '867900000.00', choice: 'confirmed', level: 'warning',
        canChooseRequested: false,
        expert: BankExpert(
          name: 'А. Каримов',
          signedOn: '23.10.2026',
          note: 'Секции А и Б забетонированы.',
          readinessPercent: '62',
          previousPercent: '26',
          remaining: '912000000.00',
          recommended: '867900000.00',
          riskFlag: true,
        ),
        formula: BankFormula(
          percent: '62',
          plan: '2400000000.00',
          gross: '1488000000.00',
          issuedBefore: '620100000.00',
          result: '867900000.00',
        ),
        photos: [BankPhoto(caption: 'Секция А, плита', meta: '23.10 10:42 · 41.3022, 69.2403')],
        documents: [
          BankDocument(title: 'Акт выполненных работ №14', ok: true),
          BankDocument(title: 'Справка ф.3 №14', ok: true),
        ],
        payments: [
          BankPayment(label: 'Транш №1 (аванс)', paidOn: '02.09.2026', amount: '620100000.00'),
        ],
      ),
      BankLine(
        id: 'l3', title: 'Каркас, 1–4 этажи', issuedBefore: '0.00',
        requested: '640000000.00', readinessPercent: '12', readinessNote: '+12% с прошлого',
        confirmed: '576000000.00', toIssue: '576000000.00', choice: 'confirmed', level: 'warning',
        canChooseRequested: false,
      ),
      BankLine(
        id: 'l4', title: 'Арматура A500C и бетон на площадке', issuedBefore: '0.00',
        requested: '360000000.00', readinessPercent: null, readinessNote: 'склад',
        confirmed: '360000000.00', toIssue: '0.00', choice: 'confirmed', level: 'block',
        blocked: true,
        documents: [BankDocument(title: 'Сертификат соответствия на арматуру', ok: false)],
      ),
    ],
  );
}

BankApproval sampleBankApproval({
  bool canAct = true,
  String? blocker,
  bool committee = false,
  String? outcome,
}) {
  return BankApproval(
    id: 't-navoi',
    projectName: 'ЖК Навои',
    trancheNo: 2,
    stage: 'approval',
    stageLabel: 'Согласование',
    stages: const [
      BankStage(code: 'submitted', state: 'done'),
      BankStage(code: 'docs', state: 'done'),
      BankStage(code: 'inspection', state: 'done'),
      BankStage(code: 'specialist', state: 'done'),
      BankStage(code: 'approval', state: 'current'),
      BankStage(code: 'payout', state: 'pending'),
    ],
    round: 1,
    outcome: outcome,
    expertSignedOn: '23.10.2026',
    threshold: '2000000000.00',
    issue: '1723900000.00',
    returned: '536100000.00',
    waivedCount: 0,
    returnDays: 5,
    returnLines: const [
      BankReturnLine(
        title: 'Фундаментная плита',
        amount: '112100000.00',
        reason: 'Объём в акте больше подтверждённого (ГС п. 3.6)',
      ),
      BankReturnLine(
        title: 'Арматура A500C и бетон на площадке',
        amount: '360000000.00',
        reason: 'Нет сертификата соответствия (ГС п. 3.5)',
      ),
    ],
    steps: [
      const BankApprovalStep(
        code: 'expert', kind: 'person', status: 'done', required: 1, approved: 0,
        reason: '', by: 'А. Каримов', decidedAt: '23.10.2026 17:30', group: null, votes: [],
      ),
      const BankApprovalStep(
        code: 'specialist', kind: 'person', status: 'done', required: 1, approved: 0,
        reason: '', by: 'Д. Рахимов', decidedAt: '25.10.2026 10:00', group: null, votes: [],
      ),
      BankApprovalStep(
        code: 'head', kind: 'group', status: 'current', required: 1, approved: 0,
        reason: '', by: '', decidedAt: '',
        group: const BankGroupInfo(size: 3, available: 3, onLeave: []), votes: const [],
      ),
      BankApprovalStep(
        code: 'committee', kind: 'group', status: committee ? 'pending' : 'skipped',
        required: 3, approved: 0,
        reason: committee ? 'waived_block' : 'below_threshold', by: '', decidedAt: '',
        group: const BankGroupInfo(size: 5, available: 4, onLeave: ['Директор по кредитованию']),
        votes: const [],
      ),
      const BankApprovalStep(
        code: 'sign', kind: 'external', status: 'waiting', required: 1, approved: 0,
        reason: '', by: '', decidedAt: '', group: null, votes: [],
      ),
      const BankApprovalStep(
        code: 'payment', kind: 'external', status: 'waiting', required: 1, approved: 0,
        reason: '', by: '', decidedAt: '', group: null, votes: [],
      ),
    ],
    canAct: canAct,
    blocker: blocker,
  );
}
