import 'package:shelf/shelf.dart';

import 'http_helpers.dart';
import 'store.dart';
import 'user_roles.dart';

/// Authenticated caller resolved from `Authorization: Bearer <token>`.
class AuthContext {
  const AuthContext({required this.accessToken, required this.user});

  final String accessToken;
  final Map<String, dynamic> user;

  String get userId => user['id'] as String;
  String get phone => user['phone'] as String;
  String get role => user['role'] as String? ?? UserRole.ordinaryUser;

  bool get isSystemAdmin => role == UserRole.systemAdmin;
  bool get isResidenceAdmin => role == UserRole.residenceAdmin;
  bool get isAdmin => isSystemAdmin || isResidenceAdmin;

  bool get isBanned => user['banned'] == true;
  bool get isDemo => user['isDemo'] == true;
  String? get banReason => user['banReason'] as String?;
  String? get bannedByName => user['bannedByName'] as String?;
}

/// Request context key for [AuthContext].
const authContextKey = 'ibuild.auth';

extension AuthRequest on Request {
  AuthContext? get auth => context[authContextKey] as AuthContext?;
}

/// Attach [AuthContext] for a valid Bearer token. Does not reject anonymous
/// callers — use [requireAuth] for that.
Middleware authMiddleware(Store store) {
  return (Handler inner) {
    return (Request request) async {
      final header = request.headers['authorization'];
      AuthContext? auth;
      if (header != null && header.toLowerCase().startsWith('bearer ')) {
        final token = header.substring(7).trim();
        final user = store.userForAccessToken(token);
        if (user != null) {
          auth = AuthContext(accessToken: token, user: user);
          request = request.change(
            context: {...request.context, authContextKey: auth},
          );
        }
      }
      // FORCE RLS: bind DB session to caller (or service).
      final persistence = store.persistence;
      if (persistence != null) {
        await persistence.setRequestContext(
          userId: auth?.userId,
          role: auth?.role ?? 'service',
        );
      }
      try {
        return await inner(request);
      } finally {
        // Ignore reset failures so the response still returns.
        if (persistence != null) {
          try {
            await persistence.setRequestContext(role: 'service');
          } catch (_) {}
        }
      }
    };
  };
}

/// Banned accounts may still hit these (profile + sign-out).
const _banAllowedPaths = {'v1/users/me', 'v1/auth/logout', 'v1/auth/refresh'};

/// 403 authenticated actions for banned users. Run after [authMiddleware].
/// Anonymous/public requests are unchanged.
Middleware banGuardMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final auth = request.auth;
      if (auth != null &&
          auth.isBanned &&
          !_banAllowedPaths.contains(request.url.path)) {
        final reason = auth.banReason ?? 'No reason provided';
        final by = auth.bannedByName;
        return jsonError(
          'ACCOUNT_BANNED',
          by != null
              ? 'Your account was banned by $by: $reason'
              : 'Your account has been banned: $reason',
          status: 403,
          data: {
            'banned': true,
            'banReason': auth.banReason,
            'bannedByName': by,
            'bannedAt': auth.user['bannedAt'],
          },
        );
      }
      return inner(request);
    };
  };
}
