import 'dart:io';

import 'package:shelf/shelf.dart';

/// Simple in-memory fixed-window rate limiter, keyed by an arbitrary string
/// (typically a client IP). Dependency-free stand-in for a Redis-backed
/// limiter in the future production backend.
class RateLimiter {
  RateLimiter(this.maxRequests, this.window);

  final int maxRequests;
  final Duration window;

  final Map<String, List<DateTime>> _hits = {};

  /// Records a hit for [key] and returns `true` if it's still within the
  /// limit for the current window, or `false` (without recording) if the
  /// window's request budget is already exhausted.
  bool allow(String key) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);
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
}

/// Best-effort client identifier for rate limiting: the first hop of an
/// `X-Forwarded-For` header if present (reverse-proxy deployments), else the
/// underlying socket's remote address, else a constant fallback.
String clientKeyFor(Request request) {
  final forwardedFor = request.headers['x-forwarded-for'];
  if (forwardedFor != null && forwardedFor.isNotEmpty) {
    return forwardedFor.split(',').first.trim();
  }
  final connectionInfo =
      request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
  return connectionInfo?.remoteAddress.address ?? 'unknown';
}
