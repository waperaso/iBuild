import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

import '../env_loader.dart';
import '../rate_limiter.dart';
import '../store.dart';

/// What the quota is being spent on. Persisted as the `kind` discriminator in
/// `ai_usage`, so one table serves all three budgets.
enum AiQuotaKind {
  /// Upstream chat completions — the only kind that costs money per call.
  chat('chat', Duration(days: 1)),

  /// Local smart-search engine; hourly window, no upstream call.
  search('search', Duration(hours: 1)),

  /// Local photo readiness analysis.
  verify('verify', Duration(days: 1)),

  /// Upstream chat completions for the B2B admin assistant
  /// (`POST /v1/ai/b2b/chat`) — a separate budget from the b2c [chat] kind
  /// since it is a working tool for admins, not idle buyer chat.
  b2bChat('b2b_chat', Duration(days: 1));

  const AiQuotaKind(this.wireName, this.window);

  final String wireName;
  final Duration window;

  bool get isHourly => window.inHours < 24;
}

/// Outcome of a quota evaluation. [used]/[limit]/[resetAt] are safe to return
/// to clients; they describe the caller's own budget and nothing global.
class AiQuotaDecision {
  const AiQuotaDecision({
    required this.allowed,
    required this.used,
    required this.limit,
    required this.resetAt,
    this.blockedBy,
  });

  final bool allowed;
  final int used;
  final int limit;

  /// Start of the next window (UTC) — the client shows this, routes send it as
  /// `Retry-After`.
  final DateTime resetAt;

  /// Which layer refused: `ip`, `user`, or `global`. Null when [allowed].
  final String? blockedBy;

  int get remaining => limit - used < 0 ? 0 : limit - used;

  int get retryAfterSeconds {
    final seconds = resetAt.difference(DateTime.now().toUtc()).inSeconds;
    return seconds < 0 ? 0 : seconds + 1;
  }

  /// Client-facing `quota` object on every AI response.
  Map<String, dynamic> toJson() => {
    'used': used,
    'limit': limit,
    'remaining': remaining,
    'resetAt': resetAt.toIso8601String(),
  };
}

/// Restart-proof AI quota. Counts live in `ai_usage` keyed by
/// `sha256(ip + AI_QUOTA_SALT)` (a raw IP is never stored), a UTC bucket, and
/// the [AiQuotaKind]. Three layers are enforced, strictest first: per IP, per
/// authenticated user (so rotating IPs buys nothing), and a daily global cap.
///
/// Without Postgres it degrades to the in-memory [RateLimiter], which resets on
/// deploy — that gap is the whole reason the table exists.
class AiQuota {
  AiQuota(this._store);

  final Store _store;

  /// Reserved `ip_hash` value for the global counter. No sha256 hex can collide.
  static const _globalKey = 'global';

  /// Fallback enforcement, one limiter per kind (see class doc).
  final Map<AiQuotaKind, RateLimiter> _fallbackLimiters = {};

  /// Fallback display counters, mirroring the DB bucket shape.
  final Map<String, int> _fallbackCounts = {};

  bool _warnedAboutSalt = false;

  /// Per-caller budget for [kind]. The per-user layer shares the same number:
  /// one user is never allowed more than one IP.
  int limitFor(AiQuotaKind kind) => switch (kind) {
    AiQuotaKind.chat => _intEnv('AI_CHAT_DAILY_LIMIT', 5),
    AiQuotaKind.search => _intEnv('AI_SEARCH_HOURLY_LIMIT', 60),
    AiQuotaKind.verify => _intEnv('AI_VERIFY_DAILY_LIMIT', 100),
    AiQuotaKind.b2bChat => _intEnv('AI_B2B_CHAT_DAILY_LIMIT', 30),
  };

  /// Daily hard stop across all callers, per kind. `0` (or unset) disables it.
  int get globalDailyLimit => _intEnv('AI_DAILY_GLOBAL_LIMIT', 0);

  /// Would one more [kind] call be allowed? Never writes — call before the
  /// upstream request, then [consume] once it succeeded.
  Future<AiQuotaDecision> check(
    Request request, {
    required AiQuotaKind kind,
    String? userId,
  }) async {
    final now = DateTime.now().toUtc();
    final limit = limitFor(kind);
    final resetAt = _resetAt(kind, now);

    final ipUsed = await _read(_ipKey(request), kind, now);
    if (ipUsed >= limit) {
      return AiQuotaDecision(
        allowed: false,
        used: ipUsed,
        limit: limit,
        resetAt: resetAt,
        blockedBy: 'ip',
      );
    }

    var used = ipUsed;
    if (userId != null) {
      final userUsed = await _read(_userKey(userId), kind, now);
      // Whichever layer is closer to the ceiling is the one shown/enforced.
      if (userUsed > used) used = userUsed;
      if (userUsed >= limit) {
        return AiQuotaDecision(
          allowed: false,
          used: userUsed,
          limit: limit,
          resetAt: resetAt,
          blockedBy: 'user',
        );
      }
    }

    final globalLimit = globalDailyLimit;
    if (globalLimit > 0) {
      final globalUsed = await _read(_globalKey, kind, now);
      if (globalUsed >= globalLimit) {
        return AiQuotaDecision(
          allowed: false,
          used: used,
          limit: limit,
          // Global is always a daily cap regardless of the kind's window.
          resetAt: _nextUtcMidnight(now),
          blockedBy: 'global',
        );
      }
    }

    return AiQuotaDecision(
      allowed: true,
      used: used,
      limit: limit,
      resetAt: resetAt,
    );
  }

  /// [check], then bill every layer. Returns the post-charge state, or the
  /// refusal unchanged when the budget was already spent.
  Future<AiQuotaDecision> consume(
    Request request, {
    required AiQuotaKind kind,
    String? userId,
  }) async {
    final decision = await check(request, kind: kind, userId: userId);
    if (!decision.allowed) return decision;

    final now = DateTime.now().toUtc();
    final ipUsed = await _bump(_ipKey(request), kind, now);
    var used = ipUsed;
    if (userId != null) {
      final userUsed = await _bump(_userKey(userId), kind, now);
      if (userUsed > used) used = userUsed;
    }
    if (globalDailyLimit > 0) {
      await _bump(_globalKey, kind, now);
    }
    return AiQuotaDecision(
      allowed: true,
      used: used,
      limit: decision.limit,
      resetAt: decision.resetAt,
    );
  }

  /// Read-only snapshot of the caller's own budget, for the quota endpoint and
  /// the `(i)` info sheet. Ignores the global cap: it is not this user's number.
  Future<AiQuotaDecision> peek(
    Request request, {
    required AiQuotaKind kind,
    String? userId,
  }) async {
    final now = DateTime.now().toUtc();
    final limit = limitFor(kind);
    var used = await _read(_ipKey(request), kind, now);
    if (userId != null) {
      final userUsed = await _read(_userKey(userId), kind, now);
      if (userUsed > used) used = userUsed;
    }
    return AiQuotaDecision(
      allowed: used < limit,
      used: used,
      limit: limit,
      resetAt: _resetAt(kind, now),
    );
  }

  // --- Storage -------------------------------------------------------------

  Future<int> _read(String key, AiQuotaKind kind, DateTime now) async {
    final persistence = _store.persistence;
    if (persistence == null)
      return _fallbackCounts[_memoryKey(key, kind, now)] ?? 0;
    try {
      return await persistence.readAiUsage(
        key: key,
        day: _dayOf(now),
        kind: _kindColumn(kind, now),
      );
    } catch (error) {
      stderr.writeln('[AiQuota] Failed to read usage: $error');
      // Fail closed on the paid kind, open on the local engines.
      return kind == AiQuotaKind.chat ? limitFor(kind) : 0;
    }
  }

  Future<int> _bump(String key, AiQuotaKind kind, DateTime now) async {
    final persistence = _store.persistence;
    if (persistence == null) {
      final limiter = _fallbackLimiters.putIfAbsent(
        kind,
        () => RateLimiter(limitFor(kind), kind.window),
      );
      final memoryKey = _memoryKey(key, kind, now);
      if (!limiter.allow(memoryKey)) return limitFor(kind);
      return _fallbackCounts[memoryKey] = (_fallbackCounts[memoryKey] ?? 0) + 1;
    }
    try {
      return await persistence.bumpAiUsage(
        key: key,
        day: _dayOf(now),
        kind: _kindColumn(kind, now),
      );
    } catch (error) {
      stderr.writeln('[AiQuota] Failed to record usage: $error');
      // Unbilled call: better than refusing a request that already succeeded.
      return 0;
    }
  }

  // --- Keys and buckets ----------------------------------------------------

  String _ipKey(Request request) => _hash(clientKeyFor(request));

  String _userKey(String userId) => 'user:${_hash(userId)}';

  String _hash(String value) =>
      sha256.convert(utf8.encode('$value${_salt()}')).toString();

  String _salt() {
    final salt = appEnv()['AI_QUOTA_SALT']?.trim() ?? '';
    if (salt.isEmpty && !_warnedAboutSalt) {
      _warnedAboutSalt = true;
      stderr.writeln(
        '[AiQuota] AI_QUOTA_SALT is not set — usage keys are unsalted hashes '
        'of low-entropy addresses and can be brute-forced. Set it in '
        'server/.env.',
      );
    }
    return salt;
  }

  /// The `day` column: always the UTC date, even for hourly kinds (the hour
  /// rides along in [_kindColumn] so the primary key stays `(hash, day, kind)`).
  String _dayOf(DateTime now) => now.toIso8601String().split('T').first;

  String _kindColumn(AiQuotaKind kind, DateTime now) => kind.isHourly
      ? '${kind.wireName}_h${now.hour.toString().padLeft(2, '0')}'
      : kind.wireName;

  String _memoryKey(String key, AiQuotaKind kind, DateTime now) =>
      '$key|${_dayOf(now)}|${_kindColumn(kind, now)}';

  DateTime _resetAt(AiQuotaKind kind, DateTime now) => kind.isHourly
      ? DateTime.utc(now.year, now.month, now.day, now.hour + 1)
      : _nextUtcMidnight(now);

  DateTime _nextUtcMidnight(DateTime now) =>
      DateTime.utc(now.year, now.month, now.day + 1);

  int _intEnv(String name, int fallback) {
    final raw = appEnv()[name]?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    return int.tryParse(raw) ?? fallback;
  }
}
