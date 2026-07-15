import 'package:test/test.dart';

import '../lib/src/app.dart';
import '../lib/src/env_loader.dart';

void main() {
  tearDown(resetAppEnvCache);

  test('assertProductionSecrets is a no-op outside production', () {
    resetAppEnvCache();
    expect(isProduction, isFalse);
    expect(assertProductionSecrets, returnsNormally);
  });
}
