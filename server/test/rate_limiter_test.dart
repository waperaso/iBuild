import 'package:test/test.dart';

import '../lib/src/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('allows up to maxRequests within the window', () {
      final limiter = RateLimiter(3, const Duration(minutes: 1));
      expect(limiter.allow('ip-1'), isTrue);
      expect(limiter.allow('ip-1'), isTrue);
      expect(limiter.allow('ip-1'), isTrue);
      expect(limiter.allow('ip-1'), isFalse);
    });

    test('tracks separate keys independently', () {
      final limiter = RateLimiter(1, const Duration(minutes: 1));
      expect(limiter.allow('ip-a'), isTrue);
      expect(limiter.allow('ip-b'), isTrue);
      expect(limiter.allow('ip-a'), isFalse);
      expect(limiter.allow('ip-b'), isFalse);
    });

    test('retryAfterSeconds is positive once the limit is breached', () {
      final limiter = RateLimiter(1, const Duration(seconds: 30));
      expect(limiter.allow('ip-1'), isTrue);
      expect(limiter.allow('ip-1'), isFalse);
      final retryAfter = limiter.retryAfterSeconds('ip-1');
      expect(retryAfter, greaterThan(0));
      expect(retryAfter, lessThanOrEqualTo(31));
    });

    test('allows again once the window elapses', () async {
      final limiter = RateLimiter(1, const Duration(milliseconds: 50));
      expect(limiter.allow('ip-1'), isTrue);
      expect(limiter.allow('ip-1'), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(limiter.allow('ip-1'), isTrue);
    });
  });
}
