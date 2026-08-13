import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../lib/src/ai/readiness_engine.dart';

/// Solid-color synthetic image (no texture at all).
img.Image _solidImage(int r, int g, int b, {int size = 128}) {
  final image = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return image;
}

/// Horizontal-band grayscale stripes — a period small enough to survive the
/// 8x8/9x8/32x32 downsampling the hash functions use, and (separately) tuned
/// to read as heavy vertical-gradient / "frame_floors" texture once resized
/// to the 128px feature-extraction width.
img.Image _stripedGrayImage({
  int band = 16,
  int light = 220,
  int dark = 20,
  int size = 128,
}) {
  final image = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    final v = ((y ~/ band) % 2 == 0) ? light : dark;
    for (var x = 0; x < size; x++) {
      image.setPixelRgb(x, y, v, v, v);
    }
  }
  return image;
}

void main() {
  group('perceptual hash + Hamming distance', () {
    test('the same image hashes identically (distance 0)', () {
      final a = combinedPerceptualHash(_stripedGrayImage());
      final b = combinedPerceptualHash(_stripedGrayImage());
      expect(a.length, 16); // 64 bits as hex, always unsigned/zero-padded
      expect(a, isNot(startsWith('-')));
      expect(hammingDistanceHex(a, b), 0);
    });

    test('two visibly different images hash far apart', () {
      final striped = combinedPerceptualHash(_stripedGrayImage());
      final inverted = combinedPerceptualHash(
        _stripedGrayImage(light: 20, dark: 220),
      );
      final distance = hammingDistanceHex(striped, inverted);
      expect(distance, greaterThan(12)); // above the "near-duplicate" band
    });

    test('malformed hex compares as maximally different, not a crash', () {
      expect(hammingDistanceHex('not-a-hash', 'also-not-one'), 64);
      expect(hammingDistanceHex('', ''), 64);
    });

    test('a hash with the top bit set round-trips without going negative', () {
      // Regression test: Dart's native `int` is 64-bit signed, so a hash
      // with bit 63 set is a *negative* int; naive toRadixString()/
      // toUnsigned(64) mishandled this (wrong digits, or a leading '-'),
      // and a naive "shift until zero" Hamming-distance loop never
      // terminated on a negative XOR. Both are fixed; assert the fix holds.
      // This exact image is known (empirically) to produce a hash with its
      // top nibble >= 8, i.e. bit 63 set.
      final hash = combinedPerceptualHash(
        _stripedGrayImage(light: 20, dark: 220),
      );
      expect(hash, isNot(startsWith('-')));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(hash), isTrue);
      expect(
        int.parse(hash.substring(0, 1), radix: 16),
        greaterThanOrEqualTo(8),
      );
      // Self-distance must still be computed (not hang, not throw).
      expect(hammingDistanceHex(hash, hash), 0);
    });
  });

  group('extractFeatureVector + classifyStage', () {
    test(
      'a mostly-blue (sky) image scores low on earthworks-defining features',
      () {
        final features = extractFeatureVector(_solidImage(135, 206, 250));
        expect(features['soilRatio'], 0);
        expect(features['concreteRatio'], 0);
        expect(features['skyRatio'], greaterThan(0.3));
        // earthworks is driven almost entirely by soil/low-edge signal, which
        // this image has none of.
        final classification = classifyStage(features);
        expect(classification.stage, isNot('earthworks'));
      },
    );

    test(
      'a mostly-brown/earth image classifies as earthworks with high confidence',
      () {
        final features = extractFeatureVector(_solidImage(130, 90, 50));
        expect(features['soilRatio'], greaterThan(0.8));
        final classification = classifyStage(features);
        expect(classification.stage, 'earthworks');
        expect(classification.confidence, greaterThanOrEqualTo(50));
      },
    );

    test(
      'a gray, vertical-edge-heavy (scaffolding-like) image scores high on frame_floors',
      () {
        final features = extractFeatureVector(
          _stripedGrayImage(band: 2, light: 140, dark: 60),
        );
        expect(features['verticalEdgeDensity'], greaterThan(0.5));
        expect(features['concreteRatio'], greaterThan(0.4));
        final classification = classifyStage(features);
        expect(classification.stage, 'frame_floors');
        expect(classification.confidence, greaterThanOrEqualTo(50));
      },
    );

    test(
      'a flat, featureless image is not confidently a construction site',
      () {
        final features = extractFeatureVector(
          _solidImage(60, 140, 50),
        ); // vegetation
        final classification = classifyStage(features);
        expect(classification.confidence, lessThan(50));
      },
    );
  });

  group('haversineKm', () {
    test('distance to self is zero', () {
      expect(haversineKm(41.31, 69.28, 41.31, 69.28), 0);
    });

    test('roughly matches a known short Tashkent-scale distance', () {
      // ~0.01 degrees of latitude is close to 1.11 km.
      final d = haversineKm(41.30, 69.28, 41.31, 69.28);
      expect(d, closeTo(1.11, 0.05));
    });
  });

  group('ReadinessEngine.analyze end-to-end', () {
    test(
      'a classifiable image with a matching declared stage runs through all stages',
      () async {
        final engine = ReadinessEngine();
        final bytes = img.encodePng(
          _stripedGrayImage(band: 2, light: 140, dark: 60),
        );
        final result = await engine.analyze(
          imageBytes: bytes,
          objectId: 'p-test',
          reportId: 'phr-test-1',
          userLanguage: 'en',
          declaredStage: 'frame_floors',
        );

        expect(result.json['object_id'], 'p-test');
        expect(result.json['report_id'], 'phr-test-1');
        expect(result.json['detected_stage'], 'frame_floors');
        expect(result.json['declared_stage'], 'frame_floors');
        expect(result.phash.length, 16);
        final checks = result.json['checks'] as List;
        expect(checks, isNotEmpty);
        final stages = checks.map((c) => (c as Map)['stage']).toList();
        // No EXIF on a synthetically-generated PNG, so stage_1 only warns
        // (metadataMissing) — every later stage still runs.
        expect(stages, contains('stage_1'));
        expect(stages, contains('stage_7'));
        expect([
          'confirmed',
          'requires_manual_review',
          'discrepancy_found',
          'violation_found',
        ], contains(result.json['overall_status']));
      },
    );

    test(
      'an unreadable image fails fast at stage_1 with no later checks',
      () async {
        final engine = ReadinessEngine();
        final result = await engine.analyze(
          imageBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
          objectId: 'p-test',
          reportId: 'phr-test-2',
          userLanguage: 'en',
        );
        expect(result.json['stopped_at'], 'stage_1');
        final checks = result.json['checks'] as List;
        expect(checks, hasLength(1));
        expect((checks.first as Map)['findingCode'], 'stage1.imageUnreadable');
        expect(result.json['overall_status'], 'discrepancy_found');
      },
    );

    test('a duplicate of a prior report fails at stage_2', () async {
      final engine = ReadinessEngine();
      final source = _stripedGrayImage(band: 2, light: 140, dark: 60);
      final bytes = img.encodePng(source);
      final priorHash = combinedPerceptualHash(source);

      final result = await engine.analyze(
        imageBytes: bytes,
        objectId: 'p-test',
        reportId: 'phr-test-3',
        userLanguage: 'en',
        priorReports: [
          PriorReport(
            id: 'phr-prior-1',
            phash: priorHash,
            takenAt: DateTime.now(),
          ),
        ],
      );
      expect(result.json['stopped_at'], 'stage_2');
      final checks = result.json['checks'] as List;
      expect((checks.last as Map)['findingCode'], 'stage2.duplicateFound');
    });
  });
}
