import 'package:shelf/shelf.dart';

import 'store.dart';

/// Demo reviewers fetch the same live catalogue as a real system admin.
/// Empty-looking admin surfaces (CRM, tickets, notifications, …) are filled
/// with placeholder rows by [DemoOverlay] on those GET handlers — never by
/// replacing the whole response. Mutating requests remain blocked by
/// [demoGuardMiddleware] — this middleware is intentionally a no-op.
Middleware demoReadIsolationMiddleware(Store store) {
  return (Handler inner) => inner;
}
