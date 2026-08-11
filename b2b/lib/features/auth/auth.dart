import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../core/api_client.dart';
import '../../core/session_storage.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.phone,
    required this.role,
    this.name,
    this.banned = false,
    this.banReason,
    this.bannedByName,
    this.bannedAt,
    this.isDemo = false,
  });

  final String id;
  final String phone;
  final String role;
  final String? name;
  final bool banned;
  final String? banReason;
  final String? bannedByName;
  final String? bannedAt;
  final bool isDemo;

  bool get isSystemAdmin => role == 'system_admin';
  bool get isResidenceAdmin => role == 'residence_admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    role: json['role'] as String? ?? 'ordinary_user',
    name: json['name'] as String?,
    banned: json['banned'] as bool? ?? false,
    banReason: json['banReason'] as String?,
    bannedByName: json['bannedByName'] as String?,
    bannedAt: json['bannedAt'] as String?,
    isDemo: json['isDemo'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'role': role,
    if (name != null) 'name': name,
    'banned': banned,
    if (banReason != null) 'banReason': banReason,
    if (bannedByName != null) 'bannedByName': bannedByName,
    if (bannedAt != null) 'bannedAt': bannedAt,
    'isDemo': isDemo,
  };

  AdminUser copyWith({
    bool? banned,
    String? banReason,
    String? bannedByName,
    String? bannedAt,
  }) => AdminUser(
    id: id,
    phone: phone,
    role: role,
    name: name,
    banned: banned ?? this.banned,
    banReason: banReason ?? this.banReason,
    bannedByName: bannedByName ?? this.bannedByName,
    bannedAt: bannedAt ?? this.bannedAt,
  );
}

/// Extracts the API error `code` from a Dio 4xx/5xx envelope body.
String? apiErrorCode(Object? error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is Map) {
    final nested = data['error'];
    if (nested is Map && nested['code'] is String) {
      return nested['code'] as String;
    }
    if (data['code'] is String) return data['code'] as String;
  }
  return null;
}

bool isAccountBannedError(Object? error) =>
    apiErrorCode(error) == 'ACCOUNT_BANNED' ||
    (error is DioException &&
        error.response?.statusCode == 403 &&
        (error.response?.data?.toString().contains('ACCOUNT_BANNED') == true ||
            error.message?.contains('banned') == true));

/// Ban payload attached to `ACCOUNT_BANNED` responses (see banGuardMiddleware).
Map<String, dynamic>? accountBannedPayload(Object? error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  final nested = data['error'];
  if (nested is Map && nested['data'] is Map) {
    return Map<String, dynamic>.from(nested['data'] as Map);
  }
  if (data['data'] is Map) {
    return Map<String, dynamic>.from(data['data'] as Map);
  }
  return null;
}

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  Future<String> sendOtp(String phone) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/send',
      data: {'phone': phone},
    );
    return res.data!['requestId'] as String;
  }

  Future<AdminUser> verifyOtp({
    required String requestId,
    required String code,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      data: {'requestId': requestId, 'code': code},
    );
    final data = res.data!;
    final user = AdminUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.write(
      key: AuthStorageKeys.accessToken,
      value: data['accessToken'] as String,
    );
    await _storage.write(
      key: AuthStorageKeys.refreshToken,
      value: data['refreshToken'] as String,
    );
    await _storage.write(
      key: AuthStorageKeys.userJson,
      value: jsonEncode(user.toJson()),
    );
    setAccessTokenCache(data['accessToken'] as String);
    _syncDemoSession(user);
    return user;
  }

  Future<AdminUser> signInAsDemo() async {
    // Drop any restored demo Bearer so the server guard doesn't treat this
    // re-entry POST as a blocked demo write.
    DemoSession.deactivate();
    setAccessTokenCache(null);
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/demo',
      data: {'profile': 'b2b_platform'},
    );
    final data = res.data!;
    final user = AdminUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.write(
      key: AuthStorageKeys.accessToken,
      value: data['accessToken'] as String,
    );
    await _storage.write(
      key: AuthStorageKeys.refreshToken,
      value: data['refreshToken'] as String,
    );
    await _storage.write(
      key: AuthStorageKeys.userJson,
      value: jsonEncode(user.toJson()),
    );
    setAccessTokenCache(data['accessToken'] as String);
    _syncDemoSession(user);
    return user;
  }

  void _syncDemoSession(AdminUser user) {
    if (user.isDemo) {
      DemoSession.activate();
    } else {
      DemoSession.deactivate();
    }
  }

  Future<AdminUser?> restore() async {
    final token = await _storage.read(key: AuthStorageKeys.accessToken);
    if (token == null || token.isEmpty) return null;
    setAccessTokenCache(token);
    try {
      return await fetchMe();
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await signOut();
      }
      return null;
    }
  }

  /// Refreshes cached user from `GET /users/me` (role flips, bans).
  Future<AdminUser> fetchMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me');
    final user = AdminUser.fromJson(res.data!);
    await _storage.write(
      key: AuthStorageKeys.userJson,
      value: jsonEncode(user.toJson()),
    );
    _syncDemoSession(user);
    return user;
  }

  Future<void> signOut() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    DemoSession.deactivate();
    await clearStoredSession(_storage);
  }
}

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  ),
);

class AuthController extends Notifier<AsyncValue<AdminUser?>> {
  Timer? _banPoll;

  @override
  AsyncValue<AdminUser?> build() {
    // Clear local user when the refresh interceptor ends the session.
    final unsubscribe = addSessionExpiredListener(_onSessionExpired);
    ref.onDispose(() {
      unsubscribe();
      _banPoll?.cancel();
    });
    Future.microtask(_restore);
    return const AsyncValue.loading();
  }

  void _onSessionExpired() {
    _banPoll?.cancel();
    if (state.value == null) return;
    state = const AsyncValue.data(null);
  }

  void _scheduleBanPoll() {
    _banPoll?.cancel();
    final user = state.value;
    if (user == null || user.banned) return;
    // Poll for mid-session bans.
    _banPoll = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(refreshMe());
    });
  }

  Future<void> _restore() async {
    try {
      final user = await ref.read(authRepositoryProvider).restore();
      state = AsyncValue.data(user);
      _scheduleBanPoll();
    } catch (error, stack) {
      // Restore failures → signed-out (don't blank the first frame).
      developer.log(
        'AuthController._restore failed, falling back to signed-out',
        error: error,
        stackTrace: stack,
        name: 'b2b.auth',
      );
      state = const AsyncValue.data(null);
    }
  }

  Future<String> sendOtp(String phone) =>
      ref.read(authRepositoryProvider).sendOtp(phone);

  Future<void> verifyOtp({
    required String requestId,
    required String code,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .verifyOtp(requestId: requestId, code: code);
    state = AsyncValue.data(user);
    _scheduleBanPoll();
  }

  Future<void> signInAsDemo() async {
    final user = await ref.read(authRepositoryProvider).signInAsDemo();
    state = AsyncValue.data(user);
    _scheduleBanPoll();
  }

  Future<void> signOut() async {
    _banPoll?.cancel();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshMe() async {
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe();
      state = AsyncValue.data(user);
      if (user.banned) {
        _banPoll?.cancel();
      } else {
        _scheduleBanPoll();
      }
    } catch (_) {
      // Keep cached user on network failure.
    }
  }

  /// Applies ban fields from an `ACCOUNT_BANNED` response immediately.
  void applyBannedFromError(Object error) {
    final current = state.value;
    if (current == null || current.banned) return;
    final payload = accountBannedPayload(error);
    state = AsyncValue.data(
      current.copyWith(
        banned: true,
        banReason: payload?['banReason'] as String? ?? current.banReason,
        bannedByName:
            payload?['bannedByName'] as String? ?? current.bannedByName,
        bannedAt: payload?['bannedAt'] as String? ?? current.bannedAt,
      ),
    );
    _banPoll?.cancel();
    unawaited(refreshMe());
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AdminUser?>>(
      AuthController.new,
    );
