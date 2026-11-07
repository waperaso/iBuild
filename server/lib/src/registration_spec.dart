/// What a company must tell us, and which papers it must send, to join iBuild.
///
/// The lists follow the Uzbek rules for knowing your customer
/// (Law ZRU-660-II of 26.08.2004 on fighting money laundering and terrorist
/// financing), the personal-data law (ZRU-547 of 02.07.2019) and the rules for
/// building housing with buyers' money (Presidential Decree UP-11 of
/// 27.01.2025). The client has the same list in `registration_spec.dart`;
/// `registration_spec_test.dart` keeps the two in step.
library;

/// Version of the consent text shown to the applicant. Raise it when the text
/// or the purpose of processing changes: the law asks for a new consent then.
const consentVersion = '2026-10';

enum FieldType {
  text,
  long,
  digits,
  phone,
  email,
  date,
  pastDate,
  money,
  number,
  percent,
  choice,
  yesNo,
}

class FieldRule {
  const FieldRule(
    this.key,
    this.type, {
    this.required = true,
    this.max = 200,
    this.length = 0,
    this.choices = const [],
  });

  final String key;
  final FieldType type;
  final bool required;
  final int max;
  final int length;
  final List<String> choices;
}

const regions = [
  'karakalpakstan',
  'andijan',
  'bukhara',
  'jizzakh',
  'kashkadarya',
  'navoi',
  'namangan',
  'samarkand',
  'surkhandarya',
  'syrdarya',
  'tashkent_region',
  'fergana',
  'khorezm',
  'tashkent_city',
];

const _callTimes = ['morning', 'day', 'evening', 'any'];
const _languages = ['ru', 'uz', 'en'];
const _yesNo = ['yes', 'no'];

const developerFields = <FieldRule>[
  // Organisation
  FieldRule('org_full_name', FieldType.text, max: 300),
  FieldRule('org_short_name', FieldType.text, required: false),
  FieldRule('legal_form', FieldType.choice, choices: ['llc', 'jsc', 'private', 'other']),
  FieldRule('inn', FieldType.digits, length: 9),
  FieldRule('oked', FieldType.digits, required: false, length: 5),
  FieldRule('reg_number', FieldType.text, max: 60),
  FieldRule('reg_date', FieldType.pastDate),
  FieldRule('reg_authority', FieldType.text),
  FieldRule('charter_capital', FieldType.money),
  FieldRule('legal_address', FieldType.text, max: 500),
  FieldRule('actual_address', FieldType.text, max: 500),
  FieldRule('region', FieldType.choice, choices: regions),
  FieldRule('website', FieldType.text, required: false),
  FieldRule('org_phone', FieldType.phone),
  FieldRule('org_email', FieldType.email),
  // Director
  FieldRule('dir_name', FieldType.text),
  FieldRule('dir_position', FieldType.text),
  FieldRule('dir_pinfl', FieldType.digits, length: 14),
  FieldRule('dir_passport', FieldType.text, max: 12),
  FieldRule('dir_passport_issued', FieldType.pastDate),
  FieldRule('dir_passport_authority', FieldType.text),
  FieldRule('dir_citizenship', FieldType.text, max: 80),
  FieldRule('dir_phone', FieldType.phone),
  FieldRule('dir_email', FieldType.email),
  FieldRule('dir_basis', FieldType.choice, choices: ['charter', 'poa']),
  // Beneficial owner and public officials
  FieldRule('beneficial_name', FieldType.text),
  FieldRule('beneficial_id', FieldType.text, max: 40),
  FieldRule('pdl', FieldType.yesNo, choices: _yesNo),
  FieldRule('pdl_note', FieldType.long, required: false, max: 500),
  // First object
  FieldRule('object_name', FieldType.text),
  FieldRule('object_address', FieldType.text, max: 500),
  FieldRule('object_cadastre', FieldType.text, max: 60),
  FieldRule('land_basis', FieldType.choice, choices: ['lease', 'use', 'ownership', 'other']),
  FieldRule('land_doc_no', FieldType.text, max: 120),
  FieldRule('permit_number', FieldType.text, max: 60),
  FieldRule('permit_date', FieldType.pastDate),
  FieldRule('expertise_number', FieldType.text, max: 60),
  FieldRule('expertise_date', FieldType.pastDate),
  FieldRule('object_cost', FieldType.money),
  FieldRule('object_area', FieldType.number),
  FieldRule('object_floors', FieldType.number, required: false),
  FieldRule('object_flats', FieldType.number, required: false),
  FieldRule('commissioning_date', FieldType.date),
  FieldRule('own_funds_percent', FieldType.percent),
  FieldRule('escrow_status', FieldType.choice, choices: ['none', 'planned', 'opened']),
  FieldRule('partner_bank', FieldType.text, required: false),
  // Bank account
  FieldRule('bank_name', FieldType.text),
  FieldRule('bank_mfo', FieldType.digits, length: 5),
  FieldRule('bank_account', FieldType.digits, length: 20),
  FieldRule('bank_inn', FieldType.digits, required: false, length: 9),
  FieldRule('bank_oked', FieldType.digits, required: false, length: 5),
  FieldRule('acc_usd', FieldType.digits, required: false, length: 20),
  FieldRule('acc_cny', FieldType.digits, required: false, length: 20),
  FieldRule('acc_eur', FieldType.digits, required: false, length: 20),
  FieldRule('acc_rub', FieldType.digits, required: false, length: 20),
  // Contact for the call
  FieldRule('contact_name', FieldType.text),
  FieldRule('contact_position', FieldType.text),
  FieldRule('contact_phone', FieldType.phone),
  FieldRule('contact_email', FieldType.email),
  FieldRule('call_time', FieldType.choice, choices: _callTimes),
  FieldRule('language', FieldType.choice, choices: _languages),
  FieldRule('comment', FieldType.long, required: false, max: 1500),
];

const bankFields = <FieldRule>[
  FieldRule('org_full_name', FieldType.text, max: 300),
  FieldRule('inn', FieldType.digits, length: 9),
  FieldRule('bank_mfo', FieldType.digits, length: 5),
  FieldRule('license_number', FieldType.text, max: 60),
  FieldRule('license_date', FieldType.pastDate),
  FieldRule('legal_address', FieldType.text, max: 500),
  FieldRule('region', FieldType.choice, choices: regions),
  FieldRule('website', FieldType.text, required: false),
  FieldRule('org_phone', FieldType.phone),
  FieldRule('org_email', FieldType.email),
  FieldRule('branch', FieldType.text, required: false),
  FieldRule('contact_name', FieldType.text),
  FieldRule('contact_position', FieldType.text),
  FieldRule('contact_phone', FieldType.phone),
  FieldRule('contact_email', FieldType.email),
  FieldRule('authority_basis', FieldType.choice, choices: ['poa', 'order', 'charter']),
  FieldRule('call_time', FieldType.choice, choices: _callTimes),
  FieldRule('language', FieldType.choice, choices: _languages),
  FieldRule('active_projects', FieldType.number, required: false),
  FieldRule('comment', FieldType.long, required: false, max: 1500),
];

/// Pick-many answers: `interests` for banks.
const bankInterests = [
  'project_finance',
  'escrow',
  'tranche_control',
  'monitoring',
  'other',
];

class DocRule {
  const DocRule(this.type, {this.required = true});

  final String type;
  final bool required;
}

const developerDocs = <DocRule>[
  DocRule('registration_cert'),
  DocRule('charter'),
  DocRule('director_id'),
  DocRule('owners_proof'),
  DocRule('bank_details'),
  DocRule('land_rights'),
  DocRule('construction_permit'),
  DocRule('expertise_conclusion'),
  DocRule('tax_clearance'),
  DocRule('ecology_approval'),
  DocRule('financials', required: false),
  DocRule('license', required: false),
  DocRule('poa', required: false),
  DocRule('bank_letter', required: false),
  DocRule('other', required: false),
];

const bankDocs = <DocRule>[
  DocRule('bank_license'),
  DocRule('bank_registration'),
  DocRule('charter'),
  DocRule('authority'),
  DocRule('representative_id'),
  DocRule('aml_policy', required: false),
  DocRule('lending_terms', required: false),
  DocRule('escrow_template', required: false),
  DocRule('financials', required: false),
  DocRule('other', required: false),
];

/// What the admin ticks while calling and reading the papers.
const developerChecks = [
  'registry',
  'director',
  'owners',
  'screening',
  'land_permit',
  'expertise',
  'bank_account',
  'callback',
];

const bankChecks = ['registry', 'license', 'person', 'callback'];

List<FieldRule> fieldsFor(String kind) => kind == 'bank' ? bankFields : developerFields;
List<DocRule> docsFor(String kind) => kind == 'bank' ? bankDocs : developerDocs;
List<String> checksFor(String kind) => kind == 'bank' ? bankChecks : developerChecks;

/// Result of reading a submitted form: the cleaned data, or the first problem.
class FormResult {
  const FormResult.ok(this.data) : error = null;
  const FormResult.fail(this.error) : data = const {};

  final Map<String, Object?> data;
  final String? error;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
final _moneyPattern = RegExp(r'^\d{1,15}(\.\d{1,2})?$');

/// +998 and nine digits, written as `+998901234567`; null when it is not one.
String? normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 9) digits = '998$digits';
  if (digits.length != 12 || !digits.startsWith('998')) return null;
  return '+$digits';
}

DateTime? parseDay(String raw) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final text = '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  return text == raw ? parsed : null;
}

/// Reads one field. Returns the cleaned value, null for an empty optional
/// field, or throws [FormProblem] with the field key.
Object? _readField(FieldRule rule, Object? raw, DateTime today) {
  final text = raw is String ? raw.trim() : (raw is num ? raw.toString() : '');
  if (text.isEmpty) {
    if (rule.required) throw FormProblem(rule.key);
    return null;
  }
  switch (rule.type) {
    case FieldType.text:
    case FieldType.long:
      if (text.length > rule.max) throw FormProblem(rule.key);
      if (rule.key == 'dir_passport') {
        final passport = text.replaceAll(' ', '').toUpperCase();
        if (!RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(passport)) throw FormProblem(rule.key);
        return passport;
      }
      return text;
    case FieldType.digits:
      final digits = text.replaceAll(RegExp(r'[\s-]'), '');
      if (!RegExp(r'^\d+$').hasMatch(digits)) throw FormProblem(rule.key);
      if (rule.length > 0 && digits.length != rule.length) throw FormProblem(rule.key);
      return digits;
    case FieldType.phone:
      final phone = normalizePhone(text);
      if (phone == null) throw FormProblem(rule.key);
      return phone;
    case FieldType.email:
      final email = text.toLowerCase();
      if (email.length > 64 || !_emailPattern.hasMatch(email)) throw FormProblem(rule.key);
      return email;
    case FieldType.date:
    case FieldType.pastDate:
      final day = parseDay(text);
      if (day == null || day.year < 1900 || day.year > 2100) throw FormProblem(rule.key);
      if (rule.type == FieldType.pastDate && day.isAfter(today)) throw FormProblem(rule.key);
      return text;
    case FieldType.money:
      final money = text.replaceAll(RegExp(r'\s'), '');
      if (!_moneyPattern.hasMatch(money) || double.parse(money) <= 0) {
        throw FormProblem(rule.key);
      }
      return money;
    case FieldType.number:
      final number = text.replaceAll(RegExp(r'\s'), '');
      if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(number)) throw FormProblem(rule.key);
      if (rule.required && double.parse(number) <= 0) throw FormProblem(rule.key);
      return number;
    case FieldType.percent:
      final percent = text.replaceAll(RegExp(r'\s'), '');
      if (!RegExp(r'^\d{1,3}(\.\d{1,2})?$').hasMatch(percent)) throw FormProblem(rule.key);
      if (double.parse(percent) > 100) throw FormProblem(rule.key);
      return percent;
    case FieldType.choice:
    case FieldType.yesNo:
      if (!rule.choices.contains(text)) throw FormProblem(rule.key);
      return text;
  }
}

class FormProblem implements Exception {
  FormProblem(this.field);

  final String field;
}

/// Checks the whole form for [kind]. Unknown keys are dropped, so nothing the
/// client invents ends up in the database.
FormResult readForm(String kind, Object? raw, {DateTime? now}) {
  if (raw is! Map) return const FormResult.fail('form');
  final today = now ?? DateTime.now();
  final data = <String, Object?>{};
  try {
    for (final rule in fieldsFor(kind)) {
      final value = _readField(rule, raw[rule.key], today);
      if (value != null) data[rule.key] = value;
    }
    if (kind == 'developer') {
      if (data['pdl'] == 'yes' && data['pdl_note'] == null) throw FormProblem('pdl_note');
      data['owners'] = _readOwners(raw['owners']);
      data['licenses'] = _readLicenses(raw['licenses'], today);
    } else {
      final interests = raw['interests'];
      if (interests is! List || interests.isEmpty || interests.length > bankInterests.length) {
        throw FormProblem('interests');
      }
      final picked = <String>{};
      for (final item in interests) {
        if (item is! String || !bankInterests.contains(item)) throw FormProblem('interests');
        picked.add(item);
      }
      data['interests'] = picked.toList();
    }
  } on FormProblem catch (problem) {
    return FormResult.fail(problem.field);
  }
  return FormResult.ok(data);
}

List<Map<String, Object?>> _readOwners(Object? raw) {
  if (raw is! List || raw.isEmpty || raw.length > 20) throw FormProblem('owners');
  final rows = <Map<String, Object?>>[];
  var total = 0.0;
  for (final item in raw) {
    if (item is! Map) throw FormProblem('owners');
    final name = (item['name'] as String? ?? '').trim();
    final taxId = (item['tax_id'] as String? ?? '').replaceAll(RegExp(r'\s'), '');
    final share = (item['share'] as String? ?? '').replaceAll(RegExp(r'\s'), '');
    final kind = item['kind'] as String? ?? '';
    if (name.isEmpty || name.length > 200) throw FormProblem('owners');
    if (!const ['person', 'company'].contains(kind)) throw FormProblem('owners');
    if (!RegExp(r'^(\d{9}|\d{14})$').hasMatch(taxId)) throw FormProblem('owners');
    if (!RegExp(r'^\d{1,3}(\.\d{1,2})?$').hasMatch(share)) throw FormProblem('owners');
    final value = double.parse(share);
    if (value <= 0 || value > 100) throw FormProblem('owners');
    total += value;
    rows.add({'kind': kind, 'name': name, 'tax_id': taxId, 'share': share});
  }
  if (total > 100.0001) throw FormProblem('owners');
  return rows;
}

List<Map<String, Object?>> _readLicenses(Object? raw, DateTime today) {
  if (raw == null) return const [];
  if (raw is! List || raw.length > 10) throw FormProblem('licenses');
  final rows = <Map<String, Object?>>[];
  for (final item in raw) {
    if (item is! Map) throw FormProblem('licenses');
    final activity = (item['activity'] as String? ?? '').trim();
    final number = (item['number'] as String? ?? '').trim();
    final issued = (item['issued_on'] as String? ?? '').trim();
    final until = (item['valid_until'] as String? ?? '').trim();
    if (activity.isEmpty && number.isEmpty && issued.isEmpty && until.isEmpty) continue;
    if (activity.isEmpty || activity.length > 200 || number.isEmpty || number.length > 60) {
      throw FormProblem('licenses');
    }
    if (parseDay(issued) == null) throw FormProblem('licenses');
    if (until.isNotEmpty && parseDay(until) == null) throw FormProblem('licenses');
    rows.add({
      'activity': activity,
      'number': number,
      'issued_on': issued,
      if (until.isNotEmpty) 'valid_until': until,
    });
  }
  return rows;
}
