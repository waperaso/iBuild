import 'bank_card.dart' show bankCents;

/// The rules of the bank applied to what the developer really sent. No database
/// here: the input is plain facts, the output is the list of checks of the card.

class RuleLine {
  const RuleLine({
    required this.itemId,
    required this.title,
    required this.requested,
    required this.confirmed,
    required this.storedMaterials,
    required this.inspected,
    required this.firmName,
    required this.firmLicenseUntil,
    required this.firmInsuranceUntil,
  });

  final String itemId;
  final String title;

  /// Net amount asked for this line, decimal string.
  final String requested;

  /// What the expert confirmed, null while there was no inspection of this line.
  final String? confirmed;
  final String storedMaterials;
  final bool inspected;
  final String? firmName;
  final DateTime? firmLicenseUntil;
  final DateTime? firmInsuranceUntil;
}

class RulePayable {
  const RulePayable({required this.number, required this.signed});

  final String number;
  final bool signed;
}

class RuleInput {
  const RuleInput({
    required this.today,
    required this.rules,
    required this.lines,
    required this.payables,
    required this.requirements,
    required this.limitLeft,
    required this.issue,
    required this.fundingPaused,
    required this.inspected,
  });

  final DateTime today;
  final Map<String, Object?> rules;
  final List<RuleLine> lines;
  final List<RulePayable> payables;

  /// Status of every document of the checklist: missing, attached, na, resolved.
  final Map<String, String> requirements;

  /// What is left in the credit limit before this tranche, decimal string.
  final String limitLeft;

  /// What the tranche would pay out as it stands, decimal string.
  final String issue;
  final bool fundingPaused;
  final bool inspected;
}

class RuleResult {
  const RuleResult({
    required this.code,
    required this.level,
    required this.basis,
    required this.title,
    required this.detail,
    required this.passed,
    required this.sort,
    this.lineIds = const [],
  });

  final String code;
  final String level;
  final String basis;
  final String title;
  final String detail;
  final bool passed;
  final int sort;

  /// Budget items this check stops.
  final List<String> lineIds;
}

/// 1 000 000 UZS = one million. Rounds half up to one decimal: 867 900 000 → "867,9".
String bankMillions(BigInt cents) {
  final tenths = (cents + BigInt.from(5000000)) ~/ BigInt.from(10000000);
  final whole = (tenths ~/ BigInt.from(10)).toString();
  final fraction = (tenths % BigInt.from(10)).toString();
  final groups = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) groups.write(' ');
    groups.write(whole[i]);
  }
  return '$groups,$fraction';
}

String _millionsOf(String amount) => bankMillions(bankCents(amount));

String _day(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}

bool _expired(DateTime? until, DateTime today) {
  if (until == null) return false;
  return until.isBefore(DateTime.utc(today.year, today.month, today.day));
}

List<RuleResult> evaluateBankRules(RuleInput input) {
  final results = <RuleResult>[];
  final tolerance = (input.rules['issuedAbovePercent'] as num?)?.toInt() ?? 0;

  // The document rules of the bank. `act` and `invoice` are backed by the
  // checklist of the draw, `certificate` by the stored-materials log.
  final documentRules = <String, Map>{
    for (final item in (input.rules['documents'] as List? ?? const []))
      if (item is Map) item['code'].toString(): item,
  };
  String effectOf(String code) => documentRules[code]?['effect'] == 'warning' ? 'warning' : 'block';
  var documentSort = 7;
  for (final code in const ['act', 'invoice']) {
    final rule = documentRules[code];
    if (rule == null || input.requirements[code] != 'missing') continue;
    results.add(RuleResult(
      code: 'doc_$code',
      level: effectOf(code),
      basis: (rule['basis'] ?? '').toString(),
      title: 'Нет документа: ${rule['title']}',
      detail: 'Нужен: ${rule['when']}.',
      passed: false,
      sort: documentSort++,
    ));
  }

  // Stored materials without their documents stop the line. ГС п. 3.5.
  final storedMissing = input.requirements['stored_log'] == null ||
      input.requirements['stored_log'] == 'missing';
  final stored = [
    for (final line in input.lines)
      if (bankCents(line.storedMaterials) > BigInt.zero) line,
  ];
  if (stored.isNotEmpty && storedMissing) {
    results.add(RuleResult(
      code: 'certificate',
      level: effectOf('certificate'),
      basis: 'ГС п. 3.5',
      title: 'Нет документов на материалы на площадке',
      detail: 'Статьи: ${stored.map((line) => '«${line.title}»').join(', ')}. '
          'Без ведомости и сертификатов платёж по ним не принимается.',
      passed: false,
      sort: 1,
      lineIds: [for (final line in stored) line.itemId],
    ));
  }

  // Asked more than the expert confirmed. ГС п. 3.6.
  final above = <String>[];
  for (final line in input.lines) {
    final confirmed = line.confirmed;
    if (confirmed == null) continue;
    final asked = bankCents(line.requested);
    final allowed = bankCents(confirmed);
    final limit = allowed + allowed * BigInt.from(tolerance) ~/ BigInt.from(100);
    if (asked > limit) {
      above.add('${line.title}: ${_millionsOf(line.requested)} против ${_millionsOf(confirmed)}');
    }
  }
  if (above.isNotEmpty) {
    results.add(RuleResult(
      code: 'above_confirmed',
      level: 'warning',
      basis: 'ГС п. 3.6',
      title: 'Запрошено больше, чем подтвердил эксперт',
      detail: '${above.join('. ')}. По умолчанию к выдаче стоит подтверждённая сумма.',
      passed: false,
      sort: 2,
    ));
  }

  // The contractor has no valid license or insurance. ГС п. 3.4.
  final lapsed = <String>[];
  for (final line in input.lines) {
    final name = line.firmName;
    if (name == null) continue;
    final problems = <String>[
      if (_expired(line.firmLicenseUntil, input.today)) 'лицензия до ${_day(line.firmLicenseUntil!)}',
      if (_expired(line.firmInsuranceUntil, input.today)) 'страховка до ${_day(line.firmInsuranceUntil!)}',
    ];
    if (problems.isNotEmpty) lapsed.add('$name, ${line.title}: ${problems.join(', ')}');
  }
  if (lapsed.isNotEmpty) {
    results.add(RuleResult(
      code: 'subcontractor',
      level: 'warning',
      basis: 'ГС п. 3.4',
      title: 'У подрядчика истекли разрешительные документы',
      detail: '${lapsed.join('. ')}. Оплата допускается только за выполненные работы.',
      passed: false,
      sort: 3,
    ));
  }

  // An invoice without the waiver of claims. ГС п. 4.12.
  final unsigned = [
    for (final payable in input.payables)
      if (!payable.signed) payable.number,
  ];
  if (unsigned.isNotEmpty) {
    results.add(RuleResult(
      code: 'payable_waiver',
      level: 'warning',
      basis: 'ГС п. 4.12',
      title: 'Нет отказа от претензий по счетам',
      detail: 'Счета: ${unsigned.join(', ')}.',
      passed: false,
      sort: 4,
    ));
  }

  // The limit has to cover the tranche. ГС п. 3.7.
  final over = bankCents(input.issue) > bankCents(input.limitLeft);
  if (over) {
    results.add(RuleResult(
      code: 'limit',
      level: 'block',
      basis: 'ГС п. 3.7',
      title: 'Сумма транша больше остатка лимита',
      detail: 'К выдаче ${_millionsOf(input.issue)}, в лимите осталось ${_millionsOf(input.limitLeft)}.',
      passed: false,
      sort: 5,
    ));
  }

  if (input.fundingPaused) {
    results.add(const RuleResult(
      code: 'paused',
      level: 'block',
      basis: 'ГС п. 4.10',
      title: 'Финансирование объекта приостановлено',
      detail: '',
      passed: false,
      sort: 6,
    ));
  }

  // What is fine is shown on request. The same codes, always the same order.
  void passed(String code, String basis, String title, int sort) {
    if (results.any((result) => result.code == code)) return;
    results.add(RuleResult(
      code: code,
      level: 'reminder',
      basis: basis,
      title: title,
      detail: '',
      passed: true,
      sort: sort,
    ));
  }

  bool attached(String code) {
    final status = input.requirements[code];
    return status == 'attached' || status == 'resolved' || status == 'na';
  }

  if (attached('act')) passed('passed_act', 'ГС п. 3.5', 'Акт выполненных работ приложен', 11);
  if (attached('invoice')) passed('passed_invoice', 'ГС п. 3.5', 'Счёт приложен', 12);
  if (input.inspected) passed('passed_inspection', 'ГС п. 4.2', 'Осмотр эксперта проведён', 13);
  if (stored.isEmpty || !storedMissing) {
    passed('passed_stored', 'ГС п. 3.5', 'Материалы на площадке подтверждены документами', 14);
  }
  if (lapsed.isEmpty) passed('passed_contractor', 'ГС п. 3.4', 'Лицензия и страховка подрядчика действуют', 15);
  if (unsigned.isEmpty) passed('passed_waiver', 'ГС п. 4.12', 'Отказ от претензий есть по каждому счёту', 16);
  if (!over) passed('passed_limit', 'ГС п. 3.7', 'Остаток лимита покрывает транш', 17);
  if (!input.fundingPaused) passed('passed_paused', 'ГС п. 4.10', 'Финансирование объекта не приостановлено', 18);
  return results;
}

