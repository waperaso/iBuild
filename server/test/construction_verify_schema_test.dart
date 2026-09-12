import 'package:test/test.dart';

import '../lib/src/ai/construction_verify_job.dart';
import '../lib/src/ai/construction_verify_schema.dart';
import '../lib/src/ai/normative_check.dart';
import '../lib/src/ai/temporal_check.dart';

void main() {
  test('accepts a valid vendor object', () {
    final parsed = parseConstructionVerifyJson(
      '{"verdict":"needs_review","confidence":0.4,"summary":"ok",'
      '"sameViewpoint":true,"progressDelta":2,"flags":["dust"]}',
    );
    expect(parsed, isNotNull);
    expect(parsed!['verdict'], 'needs_review');
    expect(parsed['confidence'], 0.4);
  });

  test('rejects unknown verdicts and out-of-range confidence', () {
    expect(
      parseConstructionVerifyJson(
        '{"verdict":"maybe","confidence":0.2,"summary":"x"}',
      ),
      isNull,
    );
    expect(
      parseConstructionVerifyJson(
        '{"verdict":"confirm","confidence":1.4,"summary":"x"}',
      ),
      isNull,
    );
    expect(parseConstructionVerifyJson('not-json'), isNull);
  });

  test('rejects empty summary, bad flags, and missing required keys', () {
    expect(
      parseConstructionVerifyJson(
        '{"verdict":"confirm","confidence":0.9,"summary":"   "}',
      ),
      isNull,
    );
    expect(
      parseConstructionVerifyJson(
        '{"verdict":"confirm","confidence":0.9,"summary":"ok","flags":[1]}',
      ),
      isNull,
    );
    expect(
      parseConstructionVerifyJson('{"verdict":"confirm","confidence":0.5}'),
      isNull,
    );
    expect(
      parseConstructionVerifyJson(
        '{"verdict":"reject","confidence":0,"summary":"wrong site",'
        '"sameViewpoint":false,"progressDelta":null,"flags":["wrong_site"]}',
      ),
      isNotNull,
    );
  });

  test('safe export strips fingerprints and keeps the verdict', () {
    final export = buildSafeVerifyExport(
      requestPayload: {
        'photoA': {'id': 'a', 'takenAt': '2026-01-01'},
        'photoB': {'id': 'b', 'takenAt': '2026-01-15'},
        'user_language': 'ru',
        'integrity': {
          'passed': true,
          'photoAFingerprintSha256': 'abc123',
          'photoAPhash': 'def456',
          'findings': [
            {'code': 'documentation_gap', 'severity': 'soft', 'detail': 'x'},
          ],
        },
      },
      parsedFields: {
        'verdict': 'confirm',
        'confidence': 0.9,
        'summary': '## Ok',
        'flags': <String>[],
      },
      promptVersion: 'v0',
      model: 'gpt-4o',
      httpStatus: 200,
      latencyMs: 12,
    );
    expect(export['response']['verdict'], 'confirm');
    expect(export['request']['user_language'], 'ru');
    expect(
      (export['request'] as Map)['integrity'],
      isNot(contains('photoAFingerprintSha256')),
    );
    expect('${export['request']}', isNot(contains('abc123')));
    expect('${export['request']}', isNot(contains('def456')));
  });

  test('accepts markdown paragraphs inside summary', () {
    final parsed = parseConstructionVerifyJson(
      '{"verdict":"confirm","confidence":0.8,'
      '"summary":"## Viewpoint\\n\\nSame frame.\\n\\n- progress visible"}',
    );
    expect(parsed, isNotNull);
    expect(parsed!['summary'], contains('## Viewpoint'));
  });

  test('strips markdown fences around vendor JSON', () {
    final parsed = parseConstructionVerifyJson(
      '```json\n{"verdict":"needs_review","confidence":0.5,"summary":"ok"}\n```',
    );
    expect(parsed, isNotNull);
    expect(parsed!['verdict'], 'needs_review');
  });

  test('accepts and passes through the structured report fields', () {
    final parsed = parseConstructionVerifyJson('''
      {
        "verdict": "reject",
        "confidence": 0.9,
        "summary": "Different rooms.",
        "sameViewpoint": false,
        "progressDelta": null,
        "overallConclusion": "Фото A и Фото B показывают разные помещения.",
        "photoFindings": [
          {"role": "a", "stage": "Каркас", "description": "Открытое пространство."},
          {"role": "b", "stage": "Отделка", "description": "Готовая комната."}
        ],
        "risks": [
          {
            "description": "Разные помещения на A и B",
            "level": "high",
            "normReference": null,
            "recommendation": "Запросить пересъёмку одного места."
          }
        ],
        "recommendations": ["Запросить повторную загрузку фото B."],
        "flags": ["different_location"]
      }
    ''');
    expect(parsed, isNotNull);
    expect(parsed!['overallConclusion'], contains('разные помещения'));
    final findings = parsed['photoFindings'] as List;
    expect(findings, hasLength(2));
    expect((findings[0] as Map)['role'], 'a');
    final risks = parsed['risks'] as List;
    expect(risks, hasLength(1));
    expect((risks[0] as Map)['level'], 'high');
    expect((risks[0] as Map)['normReference'], isNull);
    expect(parsed['recommendations'], contains('Запросить повторную загрузку фото B.'));
  });

  test('drops malformed structured items instead of failing the whole parse', () {
    final parsed = parseConstructionVerifyJson('''
      {
        "verdict": "needs_review",
        "confidence": 0.5,
        "summary": "ok",
        "photoFindings": [
          {"role": "a", "stage": "Каркас", "description": "Ok."},
          {"role": "c", "stage": "Bad role", "description": "Dropped."},
          {"role": "b", "stage": "", "description": "Dropped: empty stage."}
        ],
        "risks": [
          {"description": "Valid", "level": "low", "recommendation": "Ok"},
          {"description": "Bad level", "level": "critical", "recommendation": "Dropped"}
        ]
      }
    ''');
    expect(parsed, isNotNull);
    final findings = parsed!['photoFindings'] as List;
    expect(findings, hasLength(1));
    final risks = parsed['risks'] as List;
    expect(risks, hasLength(1));
    expect((risks[0] as Map)['level'], 'low');
  });

  test('rejects the response only when a structured field is the wrong type', () {
    expect(
      parseConstructionVerifyJson(
        '{"verdict":"confirm","confidence":0.9,"summary":"ok","risks":"nope"}',
      ),
      isNull,
    );
    expect(
      parseConstructionVerifyJson(
        '{"verdict":"confirm","confidence":0.9,"summary":"ok",'
        '"overallConclusion":123}',
      ),
      isNull,
    );
  });

  test('omits structured keys entirely for legacy vendor responses', () {
    final parsed = parseConstructionVerifyJson(
      '{"verdict":"confirm","confidence":0.9,"summary":"ok"}',
    );
    expect(parsed, isNotNull);
    expect(parsed!.containsKey('overallConclusion'), isFalse);
    expect(parsed.containsKey('photoFindings'), isFalse);
    expect(parsed.containsKey('risks'), isFalse);
  });

  test('temporal check flags short intervals and B-before-A', () {
    final a = DateTime.utc(2026, 1, 1);
    final early = temporalCheck(
      takenA: a,
      takenB: a.add(const Duration(days: 3)),
      intervalDays: 14,
    );
    expect(early['ok'], isFalse);
    expect(early['reason'], 'interval_too_short');

    final backwards = temporalCheck(
      takenA: a.add(const Duration(days: 5)),
      takenB: a,
      intervalDays: 14,
    );
    expect(backwards['ok'], isFalse);
    expect(backwards['reason'], 'b_before_a');

    final ok = temporalCheck(
      takenA: a,
      takenB: a.add(const Duration(days: 14)),
      intervalDays: 14,
    );
    expect(ok['ok'], isTrue);
    expect(ok['reason'], 'interval_ok');
  });

  test('temporal and normative helpers remain available', () {
    expect(temporalPassThrough()['reason'], 'passThrough');
    expect(normativePassThrough()['reason'], 'passThrough');
    expect(normativeCheck(plannedProgress: 80)['plannedProgress'], 80);
  });
}
