import 'package:ibuild_server/src/bank_rules.dart';
import 'package:test/test.dart';

RuleInput _input(String effect, Map<String, String> requirements) => RuleInput(
      today: DateTime.utc(2026, 10, 29),
      rules: {
        'documents': [
          {'code': 'act', 'title': 'Акт выполненных работ', 'when': 'каждый транш', 'effect': effect, 'basis': 'ГС п. 3.5'},
        ],
      },
      lines: const [],
      payables: const [],
      requirements: requirements,
      limitLeft: '1000.00',
      issue: '10.00',
      fundingPaused: false,
      inspected: true,
    );

void main() {
  test('a missing act follows the effect set in the document rules', () {
    final block = evaluateBankRules(_input('block', {'act': 'missing'})).firstWhere((r) => r.code == 'doc_act');
    expect(block.level, 'block');
    final warn = evaluateBankRules(_input('warning', {'act': 'missing'})).firstWhere((r) => r.code == 'doc_act');
    expect(warn.level, 'warning');
  });

  test('an attached act, or no rule for it, raises nothing', () {
    expect(evaluateBankRules(_input('block', {'act': 'attached'})).any((r) => r.code == 'doc_act'), isFalse);
    final noRule = RuleInput(
      today: DateTime.utc(2026, 10, 29),
      rules: const {'documents': []},
      lines: const [],
      payables: const [],
      requirements: const {'act': 'missing'},
      limitLeft: '1000.00',
      issue: '10.00',
      fundingPaused: false,
      inspected: true,
    );
    expect(evaluateBankRules(noRule).any((r) => r.code == 'doc_act'), isFalse);
  });
}
