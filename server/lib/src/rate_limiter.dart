import 'dart:io';

import 'package:shelf/shelf.dart';

import 'env_loader.dart';

/// Simple in-memory fixed-window rate limiter, keyed by an arbitrary string
/// (typically a client IP). Dependency-free stand-in for a Redis-backed
/// limiter in the future production backend.
class RateLimiter {
  RateLimiter(this.maxRequests, this.window, {this.maxTrackedKeys = 10000});

  final int maxRequests;
  final Duration window;

  /// Upper bound on distinct keys held in memory. Without it an attacker who
  /// rotates the client key (spoofed `X-Forwarded-For`, or simply a large
  /// botnet) grows [_hits] without limit until the process is OOM-killed.
  final int maxTrackedKeys;

  final Map<String, List<DateTime>> _hits = {};

  /// Records a hit for [key] and returns `true` if it's still within the
  /// limit for the current window, or `false` (without recording) if the
  /// window's request budget is already exhausted.
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

  /// Seconds until the oldest hit for [key] falls out of the current
  /// window — suitable for a `Retry-After` header on a 429 response.
  int retryAfterSeconds(String key) {
    final hits = _hits[key];
    if (hits == null || hits.isEmpty) return window.inSeconds;
    final resetAt = hits.first.add(window);
    final remaining = resetAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining + 1;
  }

  /// Number of distinct keys currently held — exposed so tests can assert the
  /// map stays bounded.
  int get debugTrackedKeyCount => _hits.length;

  /// Drops keys whose hits have all aged out of the window. Runs only when
  /// the map hits [maxTrackedKeys], so the common path stays allocation-free.
  void _evictExpired(DateTime windowStart) {
    _hits.removeWhere((_, hits) {
      hits.removeWhere((t) => t.isBefore(windowStart));
      return hits.isEmpty;
    });
    // Still full of live entries (a genuine traffic spike): drop the oldest
    // half rather than letting the map grow past the cap.
    if (_hits.length >= maxTrackedKeys) {
      final byAge = _hits.keys.toList()
        ..sort((a, b) => _hits[a]!.first.compareTo(_hits[b]!.first));
      for (final key in byAge.take(_hits.length ~/ 2)) {
        _hits.remove(key);
      }
    }
  }
}

/// Whether `X-Forwarded-For` may be believed. Only true when the operator
/// explicitly opts in with `TRUST_PROXY=true`, because the header is
/// attacker-controlled on any directly reachable port: trusting it
/// unconditionally lets a single client mint a fresh rate-limit bucket per
/// request and walk straight through the OTP brute-force guard.
bool get trustProxyHeaders =>
    (appEnv()['TRUST_PROXY'] ?? '').trim().toLowerCase() == 'true';

/// Best-effort client identifier for rate limiting: the first hop of an
/// `X-Forwarded-For` header when running behind a trusted reverse proxy
/// (`TRUST_PROXY=true`), else the underlying socket's remote address, else a
/// constant fallback.
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
