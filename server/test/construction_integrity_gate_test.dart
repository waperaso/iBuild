import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../lib/src/ai/construction_integrity_gate.dart';
import '../lib/src/ai/openai_client.dart';

Uint8List _png({required int seed, int w = 64, int h = 64}) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final v = (x * 3 + y * 5 + seed * 17) % 256;
      image.setPixelRgba(x, y, v, (v + 40) % 256, (v + 80) % 256, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('runConstructionIntegrityGate', () {
    test('identical checksum fails and blocks Vision', () async {
      final bytes = _png(seed: 1);
      final result = await runConstructionIntegrityGate(
        fileA: OpenAiImageFile(bytes: bytes, filename: 'a.png'),
        fileB: OpenAiImageFile(bytes: bytes, filename: 'b.png'),
      );
      expect(result.passed, isFalse);
      expect(result.flags, contains('possible_staging'));
      expect(
        result.findings.any((f) => f['code'] == 'checksum_duplicate_a_b'),
        isTrue,
      );
      expect(result.payload['passed'], isFalse);
    });

    test('unreadable bytes fail the gate', () async {
      final result = await runConstructionIntegrityGate(
        fileA: OpenAiImageFile(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'a.bin',
        ),
        fileB: OpenAiImageFile(bytes: _png(seed: 2), filename: 'b.png'),
      );
      expect(result.passed, isFalse);
      expect(result.flags, contains('image_unusable'));
    });

    test('distinct images pass (missing EXIF is soft only)', () async {
      final result = await runConstructionIntegrityGate(
        fileA: OpenAiImageFile(bytes: _png(seed: 10), filename: 'a.png'),
        fileB: OpenAiImageFile(bytes: _png(seed: 99), filename: 'b.png'),
        projectLat: 41.31,
        projectLng: 69.25,
      );
      expect(result.passed, isTrue);
      expect(
        result.findings.any((f) => (f['code'] as String).contains('geotag_missing')),
        isTrue,
      );
      expect(result.payload['photoAFingerprintSha256'], isNotNull);
      expect(
        result.payload['photoAFingerprintSha256'],
        isNot(result.payload['photoBFingerprintSha256']),
      );
    });

    test('near-identical pixels fail perceptual duplicate', () async {
      final a = _png(seed: 5, w: 48, h: 48);
      // Same pattern → same perceptual hash for this tiny synthetic PNG.
      final result = await runConstructionIntegrityGate(
        fileA: OpenAiImageFile(bytes: a, filename: 'a.png'),
        fileB: OpenAiImageFile(bytes: a, filename: 'b.png'),
      );
      expect(result.passed, isFalse);
      expect(
        result.findings.any(
          (f) =>
              f['code'] == 'checksum_duplicate_a_b' ||
              f['code'] == 'perceptual_duplicate_a_b',
        ),
        isTrue,
      );
    });
  });
}
