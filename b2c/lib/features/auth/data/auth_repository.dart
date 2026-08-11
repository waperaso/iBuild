import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/auth_token_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../models/user_role.dart';

/// Secure-storage key for the persisted [AuthUser] JSON.
const _authUserStorageKey = 'auth_user';

/// Mock OTP accepted in client-only mock mode (matches server `kDevOtpCode`).
const kMockOtpCode = '123456';

/// Signed-in user from `/v1/auth/otp/verify` or restored session.
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
    this.isDemo = false,
  });

  final String id;
  final String phone;
  final String? name;

  /// B2C accounts are always [UserRole.ordinaryUser] for now.
  final String role;

  /// Awards / reviewer demo — read-only; no DB writes.
  final bool isDemo;

  /// Ban flag/metadata from platform admin (`Store.banUser`).
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
    isDemo: json['isDemo'] as bool? ?? false,
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
    'isDemo': isDemo,
  };
}

/// Phone-OTP auth: live `/v1/auth/otp/*` or mock; persists session to secure storage.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final _rand = Random();

  /// Sends OTP; returns `requestId` for [verifyOtp].
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

  /// Verifies [code] for [requestId] and persists the session.
  /// [phone] is used only by the mock OTP path.
  Future<AuthUser> verifyOtp({
    required String requestId,
    required String code,
    String? phone,
  }) async {
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

  /// Read-only reviewer session for awards demos — `POST /v1/auth/demo`.
  Future<AuthUser> signInAsDemo() async {
    if (Env.useMockData) {
      return _establishSession(
        accessToken: 'demo-access-mock',
        refreshToken: 'demo-refresh-mock',
        user: const AuthUser(
          id: 'demo-user-b2c',
          phone: '+998900000000',
          name: 'Demo Reviewer',
          isDemo: true,
        ),
      );
    }
    // Drop any restored demo Bearer so the server guard doesn't treat this
    // re-entry POST as a blocked demo write.
    DemoSession.deactivate();
    AuthTokenCache.setAccessToken(null);
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/demo',
      data: {'profile': 'b2c'},
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
    // Storage write can fail on restricted web profiles; keep the in-memory session.
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
    if (user.isDemo) {
      DemoSession.activate();
    } else {
      DemoSession.deactivate();
    }
    return user;
  }

  /// Refreshes cached user from `GET /v1/users/me`. Returns null on failure/mock.
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

  /// Restores a persisted session, or null for guests / rejected tokens.
  Future<AuthUser?> restoreSession() async {
    try {
      final token = await _storage.read(key: AuthStorageKeys.accessToken);
      final userJson = await _storage.read(key: _authUserStorageKey);
      if (token == null || token.isEmpty || userJson == null) {
        AuthTokenCache.setAccessToken(null);
        return null;
      }
      AuthTokenCache.setAccessToken(token);
      final user = AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      if (user.isDemo) {
        DemoSession.activate();
      } else {
        DemoSession.deactivate();
      }
      if (Env.useMockData) {
        return user;
      }
      final live = await fetchMe();
      if (live != null) return live;
      // fetchMe null = 401 (session cleared) or a transient network error.
      // If the token is gone, stay signed out and clear any leaked demo flag.
      final stillHasToken =
          await _storage.read(key: AuthStorageKeys.accessToken);
      if (stillHasToken == null || stillHasToken.isEmpty) {
        DemoSession.deactivate();
        AuthTokenCache.setAccessToken(null);
        return null;
      }
      // Keep cached session (incl. demo) when /users/me is briefly unreachable.
      return user;
    } catch (error, stack) {
      debugPrint('AuthRepository: failed to restore session: $error\n$stack');
      AuthTokenCache.setAccessToken(null);
      return null;
    }
  }

  Future<void> signOut() async {
    DemoSession.deactivate();
    AuthTokenCache.setAccessToken(null);
    await Future.wait([
      _storage.delete(key: AuthStorageKeys.accessToken),
      _storage.delete(key: AuthStorageKeys.refreshToken),
      _storage.delete(key: _authUserStorageKey),
    ]);
  }
}

/// Mock-mode OTP rejection (live mode uses [DioException] / `INVALID_CODE`).
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
