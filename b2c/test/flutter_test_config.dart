import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Maximum fraction of pixels allowed to differ before a golden test fails.
/// The committed golden PNGs are generated on a developer machine, but CI runs
/// on Linux; a small tolerance absorbs minor cross-platform anti-aliasing/font
/// rasterization differences while still catching real visual regressions.
const double _goldenDiffTolerance = 0.02;

/// Golden comparator that passes when the pixel difference is within
/// [_goldenDiffTolerance]. Delegates path resolution to [LocalFileComparator]
/// so goldens keep resolving relative to each test file's directory.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _goldenDiffTolerance) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    // Rebuild a comparator with the same basedir (the running test file's
    // directory) but a tolerant `compare`.
    goldenFileComparator = _TolerantGoldenComparator(
      Uri.parse('${current.basedir}test.dart'),
    );
  }
  await testMain();
}
