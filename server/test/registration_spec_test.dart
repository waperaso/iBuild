import 'dart:io';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:test/test.dart';

/// The form in the app and the rules on the server must ask for the same
/// things. The app file is plain text, so read the keys out of it.
void main() {
  final source = File('../app/lib/registration_spec.dart').readAsStringSync();

  Set<String> keysBetween(String start, String end) {
    final from = source.indexOf(start);
    final to = source.indexOf(end, from);
    final block = source.substring(from, to);
    return RegExp(r"RegField\(\s*'([a-z_]+)'").allMatches(block).map((m) => m.group(1)!).toSet();
  }

  test('developer form keys match the server', () {
    final app = keysBetween('const developerSections', 'const bankInterestChoices');
    final server = developerFields.map((f) => f.key).toSet();
    expect(app, server);
  });

  test('bank form keys match the server', () {
    final app = keysBetween('const bankSections', 'const developerDocs');
    final server = bankFields.map((f) => f.key).toSet();
    expect(app, server);
  });

  Map<String, bool> docRules(String start, String end) {
    final from = source.indexOf(start);
    final to = source.indexOf(end, from);
    final rules = <String, bool>{};
    for (final line in source.substring(from, to).split('\n')) {
      final match = RegExp(r"RegDoc\('([a-z_]+)'").firstMatch(line);
      if (match != null) rules[match.group(1)!] = !line.contains('required: false');
    }
    return rules;
  }

  test('papers match the server, and required ones agree', () {
    expect(
      docRules('const developerDocs', 'const bankDocs'),
      {for (final d in developerDocs) d.type: d.required},
    );
    expect(
      docRules('const bankDocs', 'List<RegSection> sectionsFor'),
      {for (final d in bankDocs) d.type: d.required},
    );
  });

  test('every check the server knows has a label in the app', () {
    for (final key in {...developerChecks, ...bankChecks}) {
      expect(source, contains("'$key': ("), reason: key);
    }
  });

  test('form rules', () {
    expect(normalizePhone('90 111 22 33'), '+998901112233');
    expect(normalizePhone('+998 (90) 111-22-33'), '+998901112233');
    expect(normalizePhone('12345'), isNull);
    expect(parseDay('2026-02-30'), isNull);
    expect(parseDay('2026-02-28'), isNotNull);
    final result = readForm('bank', {'inn': '12'});
    expect(result.error, 'org_full_name');
  });
}
