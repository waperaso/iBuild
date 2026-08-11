import 'package:shelf/shelf.dart';

import 'auth_context.dart';
import 'http_helpers.dart';

/// Paths demo sessions may still POST to (sign-out / token rotation /
/// re-enter demo after a page reload that still holds the old Bearer token).
const _demoAllowedWritePaths = {
  'v1/auth/logout',
  'v1/auth/refresh',
  'v1/auth/demo',
};

/// Blocks mutating API calls for demo reviewer accounts ([AuthContext.isDemo]).
Middleware demoGuardMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final auth = request.auth;
      if (auth != null && auth.isDemo) {
        final method = request.method.toUpperCase();
        if (method != 'GET' && method != 'HEAD' && method != 'OPTIONS') {
          final path = request.url.path;
          if (!_demoAllowedWritePaths.contains(path)) {
            return jsonError(
              'DEMO_READ_ONLY',
              'Demo mode is view-only — changes are not saved.',
              status: 403,
            );
          }
        }
      }
      return inner(request);
    };
  };
}
