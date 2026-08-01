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

  group('requiresTrustedProxyHeaders', () {
    test('a container needs X-Forwarded-For even bound to all interfaces', () {
      // The Docker case: the app binds 0.0.0.0 because the container is the
      // isolation boundary, but nginx on the host is still in front of it.
      expect(
        requiresTrustedProxyHeaders(bindAddress: '0.0.0.0', inContainer: true),
        isTrue,
      );
      expect(
        requiresTrustedProxyHeaders(bindAddress: '', inContainer: true),
        isTrue,
      );
    });

    test('a loopback bind needs X-Forwarded-For outside a container', () {
      for (final bind in ['127.0.0.1', 'localhost', '::1', ' 127.0.0.1 ']) {
        expect(
          requiresTrustedProxyHeaders(bindAddress: bind, inContainer: false),
          isTrue,
          reason: 'BIND_ADDRESS=$bind implies a reverse proxy',
        );
      }
    });

    test('binding a public interface directly does not require it', () {
      expect(
        requiresTrustedProxyHeaders(bindAddress: '0.0.0.0', inContainer: false),
        isFalse,
      );
      expect(
        requiresTrustedProxyHeaders(
          bindAddress: '203.0.113.10',
          inContainer: false,
        ),
        isFalse,
      );
    });
  });
}
