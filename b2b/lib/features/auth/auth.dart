import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api_client.dart';

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
  });

  final String id;
  final String phone;
  final String role;
  final String? name;
  final bool banned;
  final String? banReason;
  final String? bannedByName;
  final String? bannedAt;

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
  final FlutterSecureStorage _storage;

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
    return user;
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

  /// Re-pulls the signed-in user from the server and refreshes the cached
  /// copy. Used while an application is pending/in review so the moment a
  /// platform admin approves it (role flips to `residence_admin`), the next
  /// poll picks it up and the router redirect out of the apply flow fires
  /// without requiring the applicant to sign out and back in. Also picks up
  /// account bans (`banned` / `banReason` / `bannedByName`).
  Future<AdminUser> fetchMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me');
    final user = AdminUser.fromJson(res.data!);
    await _storage.write(
      key: AuthStorageKeys.userJson,
      value: jsonEncode(user.toJson()),
    );
    return user;
  }

  Future<void> signOut() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    setAccessTokenCache(null);
    await _storage.delete(key: AuthStorageKeys.accessToken);
    await _storage.delete(key: AuthStorageKeys.refreshToken);
    await _storage.delete(key: AuthStorageKeys.userJson);
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
    ref.onDispose(() => _banPoll?.cancel());
    Future.microtask(_restore);
    return const AsyncValue.loading();
  }

  void _scheduleBanPoll() {
    _banPoll?.cancel();
    final user = state.value;
    if (user == null || user.banned) return;
    // Pick up mid-session bans without requiring the user to reload the app.
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
      // Cold-start session restore must never throw during the first build
      // (e.g. corrupted secure storage, offline on refresh) — fall back to
      // signed-out so the login screen renders instead of a blank page.
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
      // Best-effort — keep the previously cached user on network failure.
    }
  }

  /// Marks the current session banned from an `ACCOUNT_BANNED` response so
  /// the shell can show the notice immediately (without waiting for poll).
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
