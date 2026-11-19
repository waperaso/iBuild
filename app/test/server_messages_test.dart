import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/l10n.dart';

/// Every sentence the server can send to a person must have an English
/// and an Uzbek version in the app. This test finds sentences in the server
/// code that the app cannot translate.
void main() {
  test('every server message has all three languages', () {
    final dir = Directory('../server/lib/src');
    expect(dir.existsSync(), isTrue, reason: 'server sources not found');

    final literal = RegExp(r"'((?:[^'\\\n$]|\\.)*[А-Яа-яЁё](?:[^'\\\n$]|\\.)*)'");
    final sentence = RegExp(r'^[А-ЯЁ].*[.!?]$');
    const en = AppCopy(AppLanguage.en);
    const uz = AppCopy(AppLanguage.uz);

    final missing = <String>{};
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      // Demo data is written in Russian on purpose.
      if (file.path.endsWith('seed.dart')) continue;
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//')) continue;
        for (final match in literal.allMatches(line)) {
          final text = match.group(1)!.replaceAll(r"\'", "'");
          if (!sentence.hasMatch(text)) continue;
          if (en.known(text) == text || uz.known(text) == text) {
            missing.add('${file.uri.pathSegments.last}: $text');
          }
        }
      }
    }
    expect(missing, isEmpty);
  });
}
