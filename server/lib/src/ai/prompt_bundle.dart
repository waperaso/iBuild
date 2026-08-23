import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../env_loader.dart';

/// On-disk construction-verify prompt pack (`v0` until a real prompt ships).
class PromptBundle {
  const PromptBundle({
    required this.id,
    required this.systemText,
    required this.schema,
    required this.sha256hex,
  });

  final String id;
  final String systemText;
  final Map<String, dynamic> schema;
  final String sha256hex;

  /// False while `v0.system.txt` is the placeholder — callers must not hit
  /// the vendor even if `AI_VISION_ENABLED=true`.
  bool get isShipped {
    final trimmed = systemText.trim();
    return trimmed.isNotEmpty && trimmed != 'PROMPT_NOT_SHIPPED';
  }
}

Directory _promptDir() {
  final sep = Platform.pathSeparator;
  final candidates = <Directory>[
    Directory('lib${sep}src${sep}ai${sep}prompts${sep}construction_verify'),
    Directory(
      '${File(Platform.script.toFilePath()).parent.path}'
      '${sep}lib${sep}src${sep}ai${sep}prompts${sep}construction_verify',
    ),
    Directory(
      '${Directory.current.path}${sep}server${sep}lib${sep}src${sep}ai'
      '${sep}prompts${sep}construction_verify',
    ),
  ];
  for (final dir in candidates) {
    if (dir.existsSync()) return dir;
  }
  return candidates.first;
}

/// Loads `lib/src/ai/prompts/construction_verify/`.
///
/// Resolves the pack from CWD, `Platform.script`, or `server/` under CWD so
/// a wrong working directory does not silently disable Vision.
///
/// [systemFileOverride] (or `CONSTRUCTION_VERIFY_PROMPT_FILE`) points at a
/// gitignored overlay. The committed `v0.system.txt` stays `PROMPT_NOT_SHIPPED`.
PromptBundle loadPromptBundle({
  String version = 'v0',
  String? systemFileOverride,
}) {
  final id = 'construction_verify/$version';
  final dir = _promptDir();
  final envPath = appEnv()['CONSTRUCTION_VERIFY_PROMPT_FILE']?.trim();
  final override =
      (systemFileOverride != null && systemFileOverride.trim().isNotEmpty)
      ? systemFileOverride.trim()
      : (envPath != null && envPath.isNotEmpty ? envPath : null);
  final systemFile = (override != null)
      ? File(override)
      : File('${dir.path}${Platform.pathSeparator}$version.system.txt');
  final schemaFile =
      File('${dir.path}${Platform.pathSeparator}$version.schema.json');
  final systemText = systemFile.existsSync()
      ? systemFile.readAsStringSync().trim()
      : 'PROMPT_NOT_SHIPPED';
  final schema = schemaFile.existsSync()
      ? jsonDecode(schemaFile.readAsStringSync()) as Map<String, dynamic>
      : const <String, dynamic>{};
  final sha = sha256.convert(utf8.encode(systemText)).toString();
  return PromptBundle(
    id: id,
    systemText: systemText,
    schema: schema,
    sha256hex: sha,
  );
}
