import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Signed-in user (or `null` for a guest), restored from secure storage on
/// boot. Guest browsing stays fully available regardless of this state —
/// nothing in the shell/discovery flow gates on it (plan §5 role model).
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() =>
      ref.watch(authRepositoryProvider).restoreSession();

  /// Step 1 of the OTP flow — requests a code for [phone] and returns the
  /// `requestId` the OTP screen must pass to [signIn]. Doesn't change
  /// [state] since no session exists yet.
  Future<String> sendOtp(String phone) {
    return ref.read(authRepositoryProvider).sendOtp(phone);
  }

  /// Step 2 of the OTP flow — verifies [code] for [requestId] and, on
  /// success, establishes the session.
  Future<void> signIn({
    required String requestId,
    required String code,
    String? phone,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .verifyOtp(requestId: requestId, code: code, phone: phone);
    state = AsyncData(user);
  }

  /// Read-only demo for awards reviewers — no DB writes.
  Future<void> signInAsDemo() async {
    final user = await ref.read(authRepositoryProvider).signInAsDemo();
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  /// Pulls the latest account state from the server (if signed in and not
  /// in mock mode) so a ban applied after this session started — with its
  /// reason and who imposed it — shows up next time Profile is opened.
  Future<void> refreshMe() async {
    if (state.value == null) return;
    final refreshed = await ref.read(authRepositoryProvider).fetchMe();
    if (refreshed != null) state = AsyncData(refreshed);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

/// Side-effect-only provider: triggers [AuthController.refreshMe] once per
/// Profile screen mount. Watch it (ignoring its value) instead of calling
/// the refresh directly in `build()`, since [ProfileScreen] is stateless.
final profileRefreshProvider = FutureProvider.autoDispose<void>((ref) {
  return ref.read(authControllerProvider.notifier).refreshMe();
});
