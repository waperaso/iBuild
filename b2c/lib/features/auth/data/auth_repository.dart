import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/env.dart';
import '../../../core/network/auth_token_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../models/user_role.dart';

/// Secure storage key for the persisted [AuthUser] (JSON-encoded), kept
/// alongside — but separate from — the token keys in [AuthStorageKeys].
const _authUserStorageKey = 'auth_user';

/// Dev-mode OTP code the server accepts (mirrors `kDevOtpCode` in
/// `server/lib/src/store.dart`) — used only to fabricate a realistic mock
/// response when [Env.useMockData] is true.
const kMockOtpCode = '123456';

/// A signed-in user, restored from secure storage or returned by
/// `/v1/auth/otp/verify`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    this.name,
    this.role = UserRole.ordinaryUser,
    this.banned = false,
    this.banReason,
    this.bannedByName,
    this.bannedAt,
  });

  final String id;
  final String phone;
  final String? name;

  /// B2C accounts are always [UserRole.ordinaryUser] for now.
  final String role;

  /// Set by a platform admin in iBuild for Business (see
  /// `Store.banUser`) — surfaced on the Profile screen so the account
  /// itself always shows why and by whom it was frozen.
  final bool banned;
  final String? banReason;
  final String? bannedByName;
  final String? bannedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    role: json['role'] as String? ?? UserRole.ordinaryUser,
    banned: json['banned'] as bool? ?? false,
    banReason: json['banReason'] as String?,
    bannedByName: json['bannedByName'] as String?,
    bannedAt: json['bannedAt'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    if (name != null) 'name': name,
    'role': role,
    'banned': banned,
    if (banReason != null) 'banReason': banReason,
    if (bannedByName != null) 'bannedByName': bannedByName,
    if (bannedAt != null) 'bannedAt': bannedAt,
  };
}

/// Phone-OTP auth (plan §5) — live `/v1/auth/otp/*` calls or a mock fallback,
/// matching the seam used by `LeadsRepository`. Persists the token pair and
/// the signed-in user to secure storage so a session survives app restarts.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final _rand = Random();

  /// Requests a code for [phone]; returns the opaque `requestId` the next
  /// `verifyOtp` call must echo back.
  Future<String> sendOtp(String phone) async {
    if (Env.useMockData) {
      return 'mock-request-${DateTime.now().millisecondsSinceEpoch}';
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/send',
      data: {'phone': phone},
    );
    return response.data!['requestId'] as String;
  }

  /// Verifies [code] for [requestId], persists the resulting session, and
  /// returns the signed-in [AuthUser].
  ///
  /// [phone] is the number the user entered on the login screen — used by the
  /// dev placeholder OTP so the persisted profile matches what they typed.
  Future<AuthUser> verifyOtp({
    required String requestId,
    required String code,
    String? phone,
  }) async {
    // Mock seam only — live mode always goes through the server so sessions
    // land in PostgreSQL with a stable user id + role.
    if (Env.useMockData && code.trim() == kMockOtpCode) {
      return _establishSession(
        accessToken: 'dev-access-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'dev-refresh-${_rand.nextInt(4294967296)}',
        user: AuthUser(
          id: 'dev-user-${phone?.hashCode ?? 1}',
          phone: phone ?? '+998 90 123 45 67',
          role: UserRole.ordinaryUser,
        ),
      );
    }

    if (Env.useMockData) {
      throw const AuthException('Invalid or expired code');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      data: {'requestId': requestId, 'code': code},
    );
    final data = response.data!;
    return _establishSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthUser> _establishSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    // Best-effort persistence: some web browsers/profiles restrict the
    // storage backend flutter_secure_storage relies on (e.g. IndexedDB
    // disabled in a private/locked-down profile). A write failure there
    // must not surface as "invalid code" — the user *did* verify — it
    // should just mean the session won't survive a page reload.
    try {
      await Future.wait([
        _storage.write(key: AuthStorageKeys.accessToken, value: accessToken),
        _storage.write(key: AuthStorageKeys.refreshToken, value: refreshToken),
        _storage.write(
          key: _authUserStorageKey,
          value: jsonEncode(user.toJson()),
        ),
      ]);
      AuthTokenCache.setAccessToken(accessToken);
    } catch (error, stack) {
      debugPrint('AuthRepository: failed to persist session: $error\n$stack');
    }
    AuthTokenCache.setAccessToken(accessToken);
    return user;
  }

  /// Re-fetches the signed-in account from `GET /v1/users/me` and refreshes
  /// the cached copy — used by the Profile screen to pick up a ban applied
  /// server-side (in iBuild for Business) after this session was
  /// established. Returns `null` on any failure (including mock mode, which
  /// has no live account to refresh) so callers can just keep the cached
  /// [AuthUser] as a fallback.
  ///
  /// Also used during [restoreSession] to reject tokens the server no longer
  /// recognizes (e.g. after a restart in in-memory mode).
  Future<AuthUser?> fetchMe() async {
    if (Env.useMockData) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      final user = AuthUser.fromJson(response.data!);
      await _storage.write(
        key: _authUserStorageKey,
        value: jsonEncode(user.toJson()),
      );
      return user;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await signOut();
      }
      debugPrint('AuthRepository: fetchMe failed: $error');
      return null;
    } catch (error, stack) {
      debugPrint('AuthRepository: fetchMe failed: $error\n$stack');
      return null;
    }
  }

  /// Restores a previously persisted session, or `null` if the user is a
  /// guest (never signed in, signed out, or the server rejected the token).
  Future<AuthUser?> restoreSession() async {
    try {
      final token = await _storage.read(key: AuthStorageKeys.accessToken);
      final userJson = await _storage.read(key: _authUserStorageKey);
      if (token == null || token.isEmpty || userJson == null) {
        AuthTokenCache.setAccessToken(null);
        return null;
      }
      AuthTokenCache.setAccessToken(token);
      if (Env.useMockData) {
        return AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
      final live = await fetchMe();
      return live;
    } catch (error, stack) {
      debugPrint('AuthRepository: failed to restore session: $error\n$stack');
      AuthTokenCache.setAccessToken(null);
      return null;
    }
  }

  Future<void> signOut() async {
    AuthTokenCache.setAccessToken(null);
    await Future.wait([
      _storage.delete(key: AuthStorageKeys.accessToken),
      _storage.delete(key: AuthStorageKeys.refreshToken),
      _storage.delete(key: _authUserStorageKey),
    ]);
  }
}

/// Thrown by [AuthRepository.verifyOtp] when the mock seam rejects a code
/// (mirrors the server's `INVALID_CODE` error in live mode, which surfaces
/// as a [DioException] instead).
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});
