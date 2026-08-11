import 'package:shelf/shelf.dart';

import 'store.dart';

/// Previously served synthetic [DemoSnapshot] payloads for demo sessions.
///
/// Demo reviewers now fetch the same live catalogue / admin / CRM data as a
/// real system admin. Mutating requests remain blocked by
/// [demoGuardMiddleware] — this middleware is intentionally a no-op.
Middleware demoReadIsolationMiddleware(Store store) {
  return (Handler inner) => inner;
}
