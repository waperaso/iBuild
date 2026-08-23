import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../lib/src/ai/prompt_bundle.dart';

void main() {
  test('default load stays on the committed PROMPT_NOT_SHIPPED stub', () {
    final bundle = loadPromptBundle(
      systemFileOverride:
          'lib/src/ai/prompts/construction_verify/v0.system.txt',
    );
    expect(bundle.systemText, contains('PROMPT_NOT_SHIPPED'));
    expect(bundle.isShipped, isFalse);
    expect(bundle.sha256hex.length, 64);
    expect(bundle.systemText.toLowerCase(), isNot(contains('sk-')));
  });

  test('overlay file ships PKM 321 text and hashes that file', () {
    final overlay = File(
      'lib/src/ai/prompts/construction_verify/v0.system.local.txt',
    );
    expect(overlay.existsSync(), isTrue, reason: 'local overlay must exist on disk');
    final text = overlay.readAsStringSync().trim();
    expect(text, isNot(contains('PROMPT_NOT_SHIPPED')));
    expect(text, contains('Resolution No. 321'));
    expect(text, contains('Appendix No. 4'));
    expect(text, contains('MULTIPLE CHECKS'));
    expect(text, contains('IMAGE FILES'));
    expect(text, contains('needs_review'));
    expect(text, contains('user_language'));
    expect(text, contains('Markdown'));
    expect(text.toLowerCase(), isNot(contains('sk-')));

    final bundle = loadPromptBundle(systemFileOverride: overlay.path);
    expect(bundle.isShipped, isTrue);
    expect(bundle.systemText, contains('kontrolniy obmer'));
    expect(
      bundle.sha256hex,
      sha256.convert(utf8.encode(text)).toString(),
    );
  });

  test('missing overlay path falls back to PROMPT_NOT_SHIPPED', () {
    final bundle = loadPromptBundle(
      systemFileOverride: 'lib/src/ai/prompts/construction_verify/missing.local.txt',
    );
    expect(bundle.isShipped, isFalse);
    expect(bundle.systemText, 'PROMPT_NOT_SHIPPED');
  });
}
