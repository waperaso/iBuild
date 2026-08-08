import 'dart:io';

import 'package:shelf/shelf.dart';

import 'env_loader.dart';

/// In-memory fixed-window rate limiter keyed by an arbitrary string (usually IP).
class RateLimiter {
  RateLimiter(this.maxRequests, this.window, {this.maxTrackedKeys = 10000});

  final int maxRequests;
  final Duration window;

  /// Cap on distinct keys in memory (spoofed `X-Forwarded-For` / botnet OOM guard).
  final int maxTrackedKeys;

  final Map<String, List<DateTime>> _hits = {};

  /// Record a hit; `false` if [key] is already over the window budget.
  bool allow(String key) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);
    if (_hits.length >= maxTrackedKeys && !_hits.containsKey(key)) {
      _evictExpired(windowStart);
    }
    final hits = _hits.putIfAbsent(key, () => <DateTime>[]);
    hits.removeWhere((t) => t.isBefore(windowStart));
    if (hits.length >= maxRequests) return false;
    hits.add(now);
    return true;
  }

  /// Seconds until [key]'s oldest hit leaves the window (`Retry-After`).
  int retryAfterSeconds(String key) {
    final hits = _hits[key];
    if (hits == null || hits.isEmpty) return window.inSeconds;
    final resetAt = hits.first.add(window);
    final remaining = resetAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining + 1;
  }

  /// Distinct keys held (tests assert the bound).
  int get debugTrackedKeyCount => _hits.length;

  /// Drop expired keys when at [maxTrackedKeys].
  void _evictExpired(DateTime windowStart) {
    _hits.removeWhere((_, hits) {
      hits.removeWhere((t) => t.isBefore(windowStart));
      return hits.isEmpty;
    });
    // Still full: drop oldest half to stay under the cap.
    if (_hits.length >= maxTrackedKeys) {
      final byAge = _hits.keys.toList()
        ..sort((a, b) => _hits[a]!.first.compareTo(_hits[b]!.first));
      for (final key in byAge.take(_hits.length ~/ 2)) {
        _hits.remove(key);
      }
    }
  }
}

/// True only with `TRUST_PROXY=true`. Blind XFF trust bypasses rate limits.
bool get trustProxyHeaders =>
    (appEnv()['TRUST_PROXY'] ?? '').trim().toLowerCase() == 'true';

/// Rate-limit client key: XFF first hop if trusted proxy, else socket address.
String clientKeyFor(Request request) {
  if (trustProxyHeaders) {
    final forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      final first = forwardedFor.split(',').first.trim();
      if (first.isNotEmpty) return first;
    }
  }
  final connectionInfo =
      request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
  return connectionInfo?.remoteAddress.address ?? 'unknown';
}
