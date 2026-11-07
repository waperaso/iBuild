import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_seed.dart';
import 'db.dart';
import 'env.dart';
import 'http_util.dart';
import 'passwords.dart';
import 'registration.dart';
import 'seed.dart';

/// The demo is a separate, read-only world inside the same instance. Its
/// companies, users and applications carry `is_demo`, nobody can sign in to it
/// with a password, and every change attempt by a demo session is refused.

/// Role button -> demo login.
const demoLogins = <String, String>{
  'developer': 'a.director',
  'contractor': 'a.contractor',
  'tech': 'a.tech',
  'bank': 'a.observer',
  'admin': 'a.admin',
};

/// Company INNs written by the demo seed. Real companies never use them.
const _demoInns = [
  '300000000',
  '300000001',
  '300000002',
  '300000010',
  '300000011',
  '300000012',
];

const demoBlockedMessage = 'Это демо: данные учебные, изменения не сохраняются.';

/// Builds the demo world when it is missing. Safe to run on every start.
Future<void> seedDemoWorld(AppDatabase db) async {
  final existing = await db.companyIdByInn('300000001');
  if (existing == null) {
    // Nobody can sign in with this password: it is thrown away.
    final password = randomToken();
    await seedDemo(db, password);
    await seedPilotBudgetIfMissing(db, password);
    await ensurePlatformAdmin(db, password);
    await ensureBankCabinet(db, password);
  }
  await db.owner.execute(
    Sql.named('UPDATE companies SET is_demo = true WHERE inn = ANY(@inns)'),
    parameters: {'inns': _demoInns},
  );
  await db.owner.execute('UPDATE users SET is_demo = true WHERE company_id IN (SELECT id FROM companies WHERE is_demo)');
  // A local stand seeded before the demo existed already holds these samples.
  await db.owner.execute(
    "UPDATE applications SET is_demo = true WHERE inn IN ('307412558', '305998114', '200950123')",
  );
  await seedDemoApplications(db, demo: true);
}

/// Refuses every change a demo session tries to make. Returns null when the
/// request may go on.
Future<Response?> demoGuard(Request request, AppDatabase db) async {
  final method = request.method;
  if (method == 'GET' || method == 'HEAD' || method == 'OPTIONS') return null;
  final path = request.url.path;
  if (path == 'api/auth/logout' || path == 'api/demo/login') return null;
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) return null;
  final lookup = await db.lookupSession(sha256Hex(token));
  final user = lookup.user;
  if (lookup.state != SessionState.ok || user == null || !user.isDemo) return null;
  return jsonError(403, 'demo_read_only', demoBlockedMessage);
}

class _DemoLimiter {
  final _hits = <String, List<DateTime>>{};

  bool allow(String key, {int perMinute = 20}) {
    final now = DateTime.now();
    final recent = (_hits[key] ?? const <DateTime>[]).where((time) => now.difference(time) < const Duration(minutes: 1)).toList();
    if (recent.length >= perMinute) {
      _hits[key] = recent;
      return false;
    }
    recent.add(now);
    _hits[key] = recent;
    if (_hits.length > 2000) _hits.removeWhere((_, value) => value.isEmpty);
    return true;
  }
}

void mountDemo(
  Router router,
  AppDatabase db,
  AppEnv env,
  Future<Response> Function(UserRecord user, String sessionToken, String csrf) signedIn,
) {
  final limiter = _DemoLimiter();
  router
    ..get('/api/config', (Request request) => jsonResponse(200, {'demoEnabled': env.demoEnabled}))
    ..post('/api/demo/login', (Request request) async {
      if (!env.demoEnabled) return jsonError(404, 'not_found', 'Ничего не найдено.');
      final cookieToken = readCookies(request)[csrfCookieName] ?? '';
      final header = request.headers['x-csrf-token'] ?? '';
      if (header.isEmpty || cookieToken.isEmpty || !tokensEqual(header, cookieToken)) {
        return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова.');
      }
      if (!limiter.allow(clientAddress(request, trustProxy: env.trustProxy))) {
        return jsonError(429, 'rate_limited', 'Слишком много попыток. Подождите и попробуйте снова.');
      }
      final body = await readJsonObject(request);
      if (body is String) {
        return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
      }
      final login = demoLogins[(body as Map<String, dynamic>)['role']];
      if (login == null) return jsonError(400, 'validation', 'Выберите роль для демо.');
      final user = await db.userByLogin(login);
      if (user == null || !user.isDemo || !user.active) {
        return jsonError(404, 'not_found', 'Демо сейчас недоступно.');
      }
      final sessionToken = randomToken();
      final csrf = randomToken();
      await db.insertSession(
        userId: user.id,
        tokenHash: sha256Hex(sessionToken),
        csrfToken: csrf,
        expiresAt: DateTime.now().toUtc().add(env.demoSessionTtl),
      );
      return signedIn(user, sessionToken, csrf);
    });
}
