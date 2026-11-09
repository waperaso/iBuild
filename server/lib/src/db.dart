import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'money.dart';
import 'passwords.dart' show sha256Hex;

class UserRecord {
  const UserRecord({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.login,
    required this.passwordHash,
    required this.active,
    this.platformAdmin = false,
    this.mustChangePassword = false,
    this.isDemo = false,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String name;
  final String login;
  final String passwordHash;
  final bool active;
  final bool platformAdmin;
  final bool mustChangePassword;
  final bool isDemo;
}

class Membership {
  const Membership({required this.projectId, required this.role});

  final String projectId;
  final String role;
}

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.active,
    required this.myRole,
    this.plan = moneyZero,
    this.reserved = moneyZero,
    this.paid = moneyZero,
    this.available = moneyZero,
    this.budgetLocked = false,
    this.fundingPaused = false,
    this.hasPhoto = false,
    this.companyName = '',
    this.description = '',
    this.bankName = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String companyId;
  final String name;
  final String address;
  final bool active;
  final String myRole;
  final String plan;
  final String reserved;
  final String paid;
  final String available;
  final bool budgetLocked;
  final bool fundingPaused;
  final bool hasPhoto;
  final String companyName;
  final String description;
  final String bankName;
  final String? latitude;
  final String? longitude;

  ProjectRecord withMoney(MoneySnapshot money) {
    return ProjectRecord(
      id: id,
      companyId: companyId,
      name: name,
      address: address,
      active: active,
      myRole: myRole,
      plan: money.plan,
      reserved: money.reserved,
      paid: money.paid,
      available: money.available,
      budgetLocked: money.locked,
      fundingPaused: fundingPaused,
      hasPhoto: hasPhoto,
      companyName: companyName,
      description: description,
      bankName: bankName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'companyId': companyId,
    'name': name,
    'address': address,
    'active': active,
    'myRole': myRole,
    'plan': plan,
    'reserved': reserved,
    'paid': paid,
    'available': available,
    'budgetLocked': budgetLocked,
    'fundingPaused': fundingPaused,
    'hasPhoto': hasPhoto,
    'companyName': companyName,
    'description': description,
    'bankName': bankName,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class MoneySnapshot {
  const MoneySnapshot({
    required this.plan,
    required this.reserved,
    required this.paid,
    required this.available,
    required this.locked,
  });

  final String plan;
  final String reserved;
  final String paid;
  final String available;
  final bool locked;

  static const zero = MoneySnapshot(
    plan: moneyZero,
    reserved: moneyZero,
    paid: moneyZero,
    available: moneyZero,
    locked: false,
  );
}

class BudgetLine {
  const BudgetLine({
    required this.id,
    required this.title,
    required this.amount,
    required this.contractorFirmId,
    required this.contractorFirmName,
    this.reserved = moneyZero,
    this.paid = moneyZero,
    this.available = moneyZero,
    this.planSet = true,
  });

  final String id;
  final String title;
  final String amount;
  final String contractorFirmId;
  final String contractorFirmName;
  final String reserved;
  final String paid;
  final String available;
  final bool planSet;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'reserved': reserved,
    'paid': paid,
    'available': available,
    'contractorFirmId': contractorFirmId,
    'contractorFirmName': contractorFirmName,
    'planSet': planSet,
  };
}

class MemberRecord {
  const MemberRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.login,
    required this.role,
    this.contractorFirmId,
    this.contractorFirmName,
  });

  final String id;
  final String userId;
  final String name;
  final String login;
  final String role;
  final String? contractorFirmId;
  final String? contractorFirmName;

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'login': login,
    'role': role,
    'contractorFirmId': contractorFirmId,
    'contractorFirmName': contractorFirmName,
  };
}

class ContractorFirm {
  const ContractorFirm({
    required this.id,
    required this.name,
    required this.inn,
    required this.contact,
  });

  final String id;
  final String name;
  final String inn;
  final String contact;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'inn': inn,
    'contact': contact,
  };
}

class CompanyUser {
  const CompanyUser({
    required this.id,
    required this.name,
    required this.login,
    required this.active,
  });

  final String id;
  final String name;
  final String login;
  final bool active;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'login': login,
    'active': active,
  };
}

enum SessionState { missing, expired, inactive, ok }

class SessionLookup {
  const SessionLookup(
    this.state, [
    this.user,
    this.csrfToken,
    this.memberships = const [],
    this.demoSession = false,
  ]);

  final SessionState state;
  final UserRecord? user;
  final String? csrfToken;
  final List<Membership> memberships;

  /// True only for a session started from the demo buttons on the sign-in
  /// page. Being read-only belongs to the session, not to the account.
  final bool demoSession;
}

class RlsPool {
  RlsPool(this.app, this.owner);

  final Pool<void> app;
  final Pool<void> owner;

  static const zoneKey = #ibuildRlsSession;

  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) {
    final session = Zone.current[zoneKey] as Session?;
    final target = session ?? owner;
    return target.execute(
      query,
      parameters: parameters,
      ignoreRows: ignoreRows,
      queryMode: queryMode,
      timeout: timeout,
    );
  }

  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
  }) {
    final session = Zone.current[zoneKey] as Session?;
    if (session is SessionExecutor) {
      return (session as SessionExecutor).runTx(fn, settings: settings);
    }
    return owner.runTx(fn, settings: settings);
  }
}

class AppDatabase {
  AppDatabase(this.owner, String databaseUrl)
      : _databaseUrl = databaseUrl,
        pool = RlsPool(owner, owner);

  final Pool<void> owner;
  final String _databaseUrl;
  Pool<void>? _app;
  RlsPool pool;

  static Future<AppDatabase> open(String databaseUrl) async {
    final url = _withPoolDefaults(databaseUrl);
    final owner = Pool<void>.withUrl(url);
    return AppDatabase(owner, url);
  }

  Future<void> close() async {
    await _app?.close();
    await owner.close();
  }

  Future<T> asUser<T>(String userId, Future<T> Function() body) {
    final bound = Zone.current[RlsPool.zoneKey];
    if (bound != null) return body();
    final app = _app;
    if (app == null) return body();
    return app.withConnection((connection) async {
      await connection.execute(
        Sql.named("SELECT set_config('app.user_id', @id, false)"),
        parameters: {'id': userId},
      );
      try {
        return await runZoned(
          body,
          zoneValues: {RlsPool.zoneKey: connection},
        );
      } finally {
        try {
          await connection.execute("SELECT set_config('app.user_id', '', false)");
        } catch (_) {}
      }
    });
  }

  Future<int> visibleProjectCount({String? userId}) async {
    Future<int> read(Session session) async {
      final rows = await session.execute('SELECT count(*) FROM projects');
      return _asInt(rows.first[0]);
    }

    final app = _app;
    if (app == null) {
      final rows = await owner.execute('SELECT count(*) FROM projects');
      return _asInt(rows.first[0]);
    }
    if (userId == null) {
      return app.withConnection(read);
    }
    return asUser(userId, () {
      final session = Zone.current[RlsPool.zoneKey]! as Session;
      return read(session);
    });
  }

  Future<void> migrate(String directoryPath) async {
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version text PRIMARY KEY,
        applied_at timestamptz NOT NULL DEFAULT now()
      )
    ''');
    await pool.execute(
      'ALTER TABLE schema_migrations ADD COLUMN IF NOT EXISTS checksum text',
    );
    final files = Directory(directoryPath)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final version = file.uri.pathSegments.last;
      final existing = await pool.execute(
        Sql.named('SELECT 1 FROM schema_migrations WHERE version = @version'),
        parameters: {'version': version},
      );
      final text = file.readAsStringSync();
      final checksum = sha256Hex(text.replaceAll('\r\n', '\n'));
      if (existing.isNotEmpty) {
        // An applied migration must never change. A file that was applied before
        // checksums existed takes its present text as the baseline.
        final stored = await pool.execute(
          Sql.named('SELECT checksum FROM schema_migrations WHERE version = @version'),
          parameters: {'version': version},
        );
        final known = stored.first[0] as String?;
        if (known == null) {
          await pool.execute(
            Sql.named('UPDATE schema_migrations SET checksum = @checksum WHERE version = @version'),
            parameters: {'checksum': checksum, 'version': version},
          );
        } else if (known != checksum) {
          throw StateError(
            'Migration $version was changed after it was applied. '
            'Add a new migration file instead of editing an applied one.',
          );
        }
        continue;
      }
      final statements = _splitSql(text);
      await pool.runTx((session) async {
        for (final statement in statements) {
          await session.execute(statement);
        }
        await session.execute(
          Sql.named(
            'INSERT INTO schema_migrations (version, checksum) VALUES (@version, @checksum)',
          ),
          parameters: {'version': version, 'checksum': checksum},
        );
      });
    }
    await _openAppRole();
  }

  Future<void> _openAppRole() async {
    final password = _databasePassword(_databaseUrl).replaceAll("'", "''");
    await owner.execute("ALTER ROLE ibuild_app WITH PASSWORD '$password'");
    final appUrl = _appDatabaseUrl(_databaseUrl);
    if (_app == null) {
      _app = Pool<void>.withUrl(appUrl);
      pool = RlsPool(_app!, owner);
    }
  }

  Future<void> truncateAll() async {
    await pool.execute('''
      TRUNCATE TABLE
        idempotency_keys,
        project_documents,
        project_changes,
        audit_events,
        request_files,
        funding_requests,
        budget_items,
        sessions,
        login_attempts,
        project_members,
        projects,
        users,
        contractor_firms,
        companies
      RESTART IDENTITY CASCADE
    ''');
  }

  Future<int> companyCount() async {
    final rows = await pool.execute('SELECT count(*) AS n FROM companies');
    return _asInt(rows.first[0]);
  }

  Future<int> countOf(String table) async {
    const allowed = {
      'budget_items',
      'funding_requests',
      'request_files',
      'audit_events',
    };
    if (!allowed.contains(table)) {
      throw ArgumentError('Unexpected table');
    }
    final rows = await pool.execute('SELECT count(*) AS n FROM $table');
    return _asInt(rows.first[0]);
  }

  Future<String> insertCompany({
    required String name,
    required String inn,
    required String contact,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO companies (name, inn, contact)
        VALUES (@name, @inn, @contact)
        RETURNING id::text
      '''),
      parameters: {'name': name, 'inn': inn, 'contact': contact},
    );
    return rows.first[0]! as String;
  }

  Future<String?> companyIdByInn(String inn) async {
    final rows = await pool.execute(
      Sql.named('SELECT id::text FROM companies WHERE inn = @inn'),
      parameters: {'inn': inn},
    );
    if (rows.isEmpty) return null;
    return rows.first[0]! as String;
  }

  Future<String> insertUser({
    required String companyId,
    required String name,
    required String login,
    required String passwordHash,
    bool active = true,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO users (company_id, name, login, password_hash, active)
        VALUES (@companyId::uuid, @name, @login, @passwordHash, @active)
        RETURNING id::text
      '''),
      parameters: {
        'companyId': companyId,
        'name': name,
        'login': login,
        'passwordHash': passwordHash,
        'active': active,
      },
    );
    return rows.first[0]! as String;
  }

  Future<void> setPasswordHash(String login, String passwordHash) async {
    await pool.execute(
      Sql.named('''
        UPDATE users SET password_hash = @passwordHash WHERE login = @login
      '''),
      parameters: {'login': login, 'passwordHash': passwordHash},
    );
  }

  Future<void> setPlatformAdmin(String login, bool enabled) async {
    await pool.execute(
      Sql.named('''
        UPDATE users SET platform_admin = @enabled WHERE login = @login
      '''),
      parameters: {'login': login, 'enabled': enabled},
    );
  }

  Future<void> setActive(String login, bool active) async {
    await pool.execute(
      Sql.named('UPDATE users SET active = @active WHERE login = @login'),
      parameters: {'login': login, 'active': active},
    );
  }

  Future<UserRecord?> userByLogin(String login) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT u.id::text AS id,
               u.company_id::text AS company_id,
               c.name AS company_name,
               u.name AS name,
               u.login AS login,
               u.password_hash AS password_hash,
               u.active AS active,
               u.platform_admin AS platform_admin,
               u.must_change_password AS must_change_password,
               u.is_demo AS is_demo
        FROM users u
        JOIN companies c ON c.id = u.company_id
        WHERE u.login = @login
      '''),
      parameters: {'login': login},
    );
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first.toColumnMap());
  }

  Future<int> recentFailures(String login, DateTime since) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT count(*) AS n
        FROM login_attempts
        WHERE login = @login AND success = false AND created_at > @since
      '''),
      parameters: {'login': login, 'since': since.toUtc()},
    );
    return _asInt(rows.first[0]);
  }

  Future<void> recordAttempt({required String login, required bool success}) {
    return pool.execute(
      Sql.named('''
        INSERT INTO login_attempts (login, success) VALUES (@login, @success)
      '''),
      parameters: {'login': login, 'success': success},
    );
  }

  Future<void> insertSession({
    required String userId,
    required String tokenHash,
    required String csrfToken,
    required DateTime expiresAt,
    bool demo = false,
  }) {
    return pool.execute(
      Sql.named('''
        INSERT INTO sessions (user_id, token_hash, csrf_token, expires_at, demo)
        VALUES (@userId::uuid, @tokenHash, @csrfToken, @expiresAt, @demo)
      '''),
      parameters: {
        'userId': userId,
        'tokenHash': tokenHash,
        'csrfToken': csrfToken,
        'expiresAt': expiresAt.toUtc(),
        'demo': demo,
      },
    );
  }

  Future<void> deleteSessionByHash(String tokenHash) {
    return pool.execute(
      Sql.named('DELETE FROM sessions WHERE token_hash = @tokenHash'),
      parameters: {'tokenHash': tokenHash},
    );
  }

  Future<void> expireSessionByHash(String tokenHash) {
    return pool.execute(
      Sql.named('''
        UPDATE sessions
        SET expires_at = now() - interval '1 minute'
        WHERE token_hash = @tokenHash
      '''),
      parameters: {'tokenHash': tokenHash},
    );
  }

  Future<SessionLookup> lookupSession(String tokenHash) async {
    final rows = await owner.execute(
      Sql.named('''
        SELECT s.csrf_token AS csrf_token,
               s.expires_at > now() AS valid,
               u.id::text AS id,
               u.company_id::text AS company_id,
               c.name AS company_name,
               u.name AS name,
               u.login AS login,
               u.password_hash AS password_hash,
               u.active AS active,
               u.platform_admin AS platform_admin,
               u.must_change_password AS must_change_password,
               u.is_demo AS is_demo,
               s.demo AS session_demo
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        JOIN companies c ON c.id = u.company_id
        WHERE s.token_hash = @tokenHash
      '''),
      parameters: {'tokenHash': tokenHash},
    );
    if (rows.isEmpty) return const SessionLookup(SessionState.missing);
    final map = rows.first.toColumnMap();
    if (_asBool(map['valid']) == false) {
      return const SessionLookup(SessionState.expired);
    }
    final user = _userFromRow(map);
    if (!user.active) return SessionLookup(SessionState.inactive, user);
    final memberships = await membershipsOf(user.id);
    return SessionLookup(
      SessionState.ok,
      user,
      map['csrf_token'] as String,
      memberships,
      _asBool(map['session_demo']),
    );
  }

  Future<List<Membership>> membershipsOf(String userId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT project_id::text AS project_id, role
        FROM project_members
        WHERE user_id = @userId::uuid
        ORDER BY role
      '''),
      parameters: {'userId': userId},
    );
    return [
      for (final row in rows)
        Membership(
          projectId: row.toColumnMap()['project_id'] as String,
          role: row.toColumnMap()['role'] as String,
        ),
    ];
  }

  Future<List<ProjectRecord>> projectsForUser(String userId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT p.id::text AS id,
               p.company_id::text AS company_id,
               c.name AS company_name,
               p.name AS name,
               p.address AS address,
               p.description AS description,
               p.bank_name AS bank_name,
               to_char(p.latitude, 'FM990.000000') AS latitude,
               to_char(p.longitude, 'FM990.000000') AS longitude,
               p.active AS active,
               p.funding_paused AS funding_paused,
               (p.photo_path IS NOT NULL AND btrim(p.photo_path) <> '') AS has_photo,
               COALESCE(m.role, 'platform') AS role
        FROM projects p
        JOIN companies c ON c.id = p.company_id
        LEFT JOIN project_members m
          ON m.project_id = p.id AND m.user_id = @userId::uuid
        WHERE m.user_id IS NOT NULL
           OR EXISTS (
             SELECT 1 FROM users u
             WHERE u.id = @userId::uuid AND u.platform_admin
           )
        ORDER BY p.name
      '''),
      parameters: {'userId': userId},
    );
    final projects = [for (final row in rows) _projectFromMap(row.toColumnMap())];
    final enriched = <ProjectRecord>[];
    for (final project in projects) {
      enriched.add(project.withMoney(await moneyForViewer(userId, project.id)));
    }
    return enriched;
  }

  Future<ProjectRecord?> projectForUser(String userId, String projectId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT p.id::text AS id,
               p.company_id::text AS company_id,
               c.name AS company_name,
               p.name AS name,
               p.address AS address,
               p.description AS description,
               p.bank_name AS bank_name,
               to_char(p.latitude, 'FM990.000000') AS latitude,
               to_char(p.longitude, 'FM990.000000') AS longitude,
               p.active AS active,
               p.funding_paused AS funding_paused,
               (p.photo_path IS NOT NULL AND btrim(p.photo_path) <> '') AS has_photo,
               COALESCE(m.role, 'platform') AS role
        FROM projects p
        JOIN companies c ON c.id = p.company_id
        LEFT JOIN project_members m
          ON m.project_id = p.id AND m.user_id = @userId::uuid
        WHERE p.id = @projectId::uuid
          AND (
            m.user_id IS NOT NULL
            OR EXISTS (
              SELECT 1 FROM users u
              WHERE u.id = @userId::uuid AND u.platform_admin
            )
          )
      '''),
      parameters: {'userId': userId, 'projectId': projectId},
    );
    if (rows.isEmpty) return null;
    final project = _projectFromMap(rows.first.toColumnMap());
    return project.withMoney(await moneyForViewer(userId, project.id));
  }

  Future<MoneySnapshot> moneyForViewer(String userId, String projectId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT
          to_char(COALESCE(SUM(s.planned_amount), 0), 'FM999999999999990.00') AS plan,
          to_char(COALESCE(SUM(s.reserved_amount), 0), 'FM999999999999990.00') AS reserved,
          to_char(COALESCE(SUM(s.paid_amount), 0), 'FM999999999999990.00') AS paid,
          to_char(
            COALESCE(SUM(s.planned_amount), 0)
              - COALESCE(SUM(s.reserved_amount), 0)
              - COALESCE(SUM(s.paid_amount), 0),
            'FM999999999999990.00'
          ) AS available,
          EXISTS (
            SELECT 1 FROM funding_requests fr
            WHERE fr.project_id = @projectId::uuid AND fr.status <> 'draft'
          ) AS locked
        FROM (
          SELECT
            CASE WHEN bi.plan_set THEN bi.planned_amount ELSE 0 END AS planned_amount,
            CASE WHEN bi.plan_set THEN line_hold(bi.id, ARRAY['submitted', 'tech_approved', 'approved']) ELSE 0 END AS reserved_amount,
            CASE WHEN bi.plan_set THEN line_hold(bi.id, ARRAY['paid']) ELSE 0 END AS paid_amount
          FROM budget_items bi
          WHERE bi.project_id = @projectId::uuid
            AND bi.budget_side = 'use'
            AND (
              EXISTS (
                SELECT 1 FROM users u
                WHERE u.id = @userId::uuid AND u.platform_admin
              )
              OR EXISTS (
                SELECT 1 FROM project_members m
                WHERE m.project_id = bi.project_id
                  AND m.user_id = @userId::uuid
                  AND (
                    m.role <> 'contractor'
                    OR bi.contractor_company_id = m.contractor_company_id
                  )
              )
            )
        ) s
      '''),
      parameters: {'userId': userId, 'projectId': projectId},
    );
    if (rows.isEmpty) return MoneySnapshot.zero;
    final map = rows.first.toColumnMap();
    return MoneySnapshot(
      plan: map['plan'] as String,
      reserved: map['reserved'] as String,
      paid: map['paid'] as String,
      available: map['available'] as String,
      locked: _asBool(map['locked']),
    );
  }

  Future<String> insertProject({
    required String companyId,
    required String name,
    required String address,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO projects (company_id, name, address)
        VALUES (@companyId::uuid, @name, @address)
        RETURNING id::text
      '''),
      parameters: {'companyId': companyId, 'name': name, 'address': address},
    );
    return rows.first[0]! as String;
  }

  Future<void> insertMember({
    required String projectId,
    required String userId,
    required String role,
    String? contractorFirmId,
  }) {
    return pool.execute(
      Sql.named('''
        INSERT INTO project_members (project_id, user_id, role, contractor_company_id)
        VALUES (@projectId::uuid, @userId::uuid, @role, @firmId::uuid)
      '''),
      parameters: {
        'projectId': projectId,
        'userId': userId,
        'role': role,
        'firmId': contractorFirmId,
      },
    );
  }

  Future<void> setMemberFirm({
    required String projectId,
    required String userId,
    required String contractorFirmId,
  }) {
    return pool.execute(
      Sql.named('''
        UPDATE project_members
        SET contractor_company_id = @firmId::uuid
        WHERE project_id = @projectId::uuid AND user_id = @userId::uuid
      '''),
      parameters: {
        'projectId': projectId,
        'userId': userId,
        'firmId': contractorFirmId,
      },
    );
  }

  Future<void> renameUserByLogin(String login, String name) async {
    await pool.execute(
      Sql.named('UPDATE users SET name = @name WHERE login = @login'),
      parameters: {'login': login, 'name': name},
    );
  }

  Future<String?> userIdByLogin(String login) async {
    final rows = await pool.execute(
      Sql.named('SELECT id::text FROM users WHERE login = @login'),
      parameters: {'login': login},
    );
    if (rows.isEmpty) return null;
    return rows.first[0]! as String;
  }

  Future<String?> projectIdByName(String companyId, String name) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT id::text FROM projects
        WHERE company_id = @companyId::uuid AND name = @name
      '''),
      parameters: {'companyId': companyId, 'name': name},
    );
    if (rows.isEmpty) return null;
    return rows.first[0]! as String;
  }

  Future<UserRecord?> userInCompany(String userId, String companyId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT u.id::text AS id,
               u.company_id::text AS company_id,
               c.name AS company_name,
               u.name AS name,
               u.login AS login,
               '' AS password_hash,
               u.active AS active,
               u.platform_admin AS platform_admin,
               u.must_change_password AS must_change_password,
               u.is_demo AS is_demo
        FROM users u
        JOIN companies c ON c.id = u.company_id
        WHERE u.id = @userId::uuid AND u.company_id = @companyId::uuid
      '''),
      parameters: {'userId': userId, 'companyId': companyId},
    );
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first.toColumnMap());
  }

  Future<List<CompanyUser>> companyUsers(String companyId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT id::text AS id, name, login, active
        FROM users
        WHERE company_id = @companyId::uuid
        ORDER BY name
      '''),
      parameters: {'companyId': companyId},
    );
    return [
      for (final row in rows)
        CompanyUser(
          id: row.toColumnMap()['id'] as String,
          name: row.toColumnMap()['name'] as String,
          login: row.toColumnMap()['login'] as String,
          active: _asBool(row.toColumnMap()['active']),
        ),
    ];
  }

  Future<List<ContractorFirm>> firmsOf(String companyId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT id::text AS id, name, inn, contact
        FROM contractor_firms
        WHERE owner_company_id = @companyId::uuid
        ORDER BY name
      '''),
      parameters: {'companyId': companyId},
    );
    return [
      for (final row in rows)
        ContractorFirm(
          id: row.toColumnMap()['id'] as String,
          name: row.toColumnMap()['name'] as String,
          inn: row.toColumnMap()['inn'] as String,
          contact: row.toColumnMap()['contact'] as String,
        ),
    ];
  }

  Future<ContractorFirm?> firmInCompany(String firmId, String companyId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT id::text AS id, name, inn, contact
        FROM contractor_firms
        WHERE id = @firmId::uuid AND owner_company_id = @companyId::uuid
      '''),
      parameters: {'firmId': firmId, 'companyId': companyId},
    );
    if (rows.isEmpty) return null;
    final map = rows.first.toColumnMap();
    return ContractorFirm(
      id: map['id'] as String,
      name: map['name'] as String,
      inn: map['inn'] as String,
      contact: map['contact'] as String,
    );
  }

  Future<String> insertFirm({
    required String companyId,
    required String name,
    required String inn,
    required String contact,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO contractor_firms (owner_company_id, name, inn, contact)
        VALUES (@companyId::uuid, @name, @inn, @contact)
        RETURNING id::text
      '''),
      parameters: {
        'companyId': companyId,
        'name': name,
        'inn': inn,
        'contact': contact,
      },
    );
    return rows.first[0]! as String;
  }

  Future<bool> firmInnTaken(String companyId, String inn) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT 1 FROM contractor_firms
        WHERE owner_company_id = @companyId::uuid AND inn = @inn
      '''),
      parameters: {'companyId': companyId, 'inn': inn},
    );
    return rows.isNotEmpty;
  }

  Future<List<MemberRecord>> membersOf(String projectId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT m.id::text AS id,
               u.id::text AS user_id,
               u.name AS name,
               u.login AS login,
               m.role AS role,
               f.id::text AS firm_id,
               f.name AS firm_name
        FROM project_members m
        JOIN users u ON u.id = m.user_id
        LEFT JOIN contractor_firms f ON f.id = m.contractor_company_id
        WHERE m.project_id = @projectId::uuid
        ORDER BY u.name
      '''),
      parameters: {'projectId': projectId},
    );
    return [
      for (final row in rows)
        MemberRecord(
          id: row.toColumnMap()['id'] as String,
          userId: row.toColumnMap()['user_id'] as String,
          name: row.toColumnMap()['name'] as String,
          login: row.toColumnMap()['login'] as String,
          role: row.toColumnMap()['role'] as String,
          contractorFirmId: row.toColumnMap()['firm_id'] as String?,
          contractorFirmName: row.toColumnMap()['firm_name'] as String?,
        ),
    ];
  }

  Future<bool> memberExists(String projectId, String userId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT 1 FROM project_members
        WHERE project_id = @projectId::uuid AND user_id = @userId::uuid
      '''),
      parameters: {'projectId': projectId, 'userId': userId},
    );
    return rows.isNotEmpty;
  }

  Future<int> directorCount(String projectId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT count(*) FROM project_members
        WHERE project_id = @projectId::uuid AND role = 'director'
      '''),
      parameters: {'projectId': projectId},
    );
    return _asInt(rows.first[0]);
  }

  Future<MemberRecord?> memberById(String projectId, String memberId) async {
    final members = await membersOf(projectId);
    for (final member in members) {
      if (member.id == memberId) return member;
    }
    return null;
  }

  Future<void> deleteMember(String projectId, String memberId) {
    return pool.execute(
      Sql.named('''
        DELETE FROM project_members
        WHERE project_id = @projectId::uuid AND id = @memberId::uuid
      '''),
      parameters: {'projectId': projectId, 'memberId': memberId},
    );
  }

  Future<List<BudgetLine>> budgetLinesFor({
    required String projectId,
    required String role,
    String? contractorFirmId,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT bi.id::text AS id,
               bi.title AS title,
               to_char(CASE WHEN bi.plan_set THEN bi.planned_amount ELSE 0 END, 'FM999999999999990.00') AS amount,
               to_char(CASE WHEN bi.plan_set THEN line_hold(bi.id, ARRAY['submitted', 'tech_approved', 'approved']) ELSE 0 END, 'FM999999999999990.00') AS reserved,
               to_char(CASE WHEN bi.plan_set THEN line_hold(bi.id, ARRAY['paid']) ELSE 0 END, 'FM999999999999990.00') AS paid,
               to_char(
                 CASE WHEN bi.plan_set THEN
                   bi.planned_amount
                     - line_hold(bi.id, ARRAY['submitted', 'tech_approved', 'approved'])
                     - line_hold(bi.id, ARRAY['paid'])
                 ELSE 0 END,
                 'FM999999999999990.00'
               ) AS available,
               f.id::text AS firm_id,
               f.name AS firm_name,
               bi.plan_set AS plan_set
        FROM budget_items bi
        JOIN contractor_firms f ON f.id = bi.contractor_company_id
        WHERE bi.project_id = @projectId::uuid
          AND (
            @role <> 'contractor'
            OR bi.contractor_company_id = @firmId::uuid
          )
        ORDER BY bi.title
      '''),
      parameters: {
        'projectId': projectId,
        'role': role,
        'firmId': contractorFirmId,
      },
    );
    return [
      for (final row in rows)
        BudgetLine(
          id: row.toColumnMap()['id'] as String,
          title: row.toColumnMap()['title'] as String,
          amount: row.toColumnMap()['amount'] as String,
          reserved: row.toColumnMap()['reserved'] as String,
          paid: row.toColumnMap()['paid'] as String,
          available: row.toColumnMap()['available'] as String,
          contractorFirmId: row.toColumnMap()['firm_id'] as String,
          contractorFirmName: row.toColumnMap()['firm_name'] as String,
          planSet: _asBool(row.toColumnMap()['plan_set']),
        ),
    ];
  }

  Future<String?> viewerFirmId(String userId, String projectId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT contractor_company_id::text
        FROM project_members
        WHERE user_id = @userId::uuid AND project_id = @projectId::uuid
      '''),
      parameters: {'userId': userId, 'projectId': projectId},
    );
    if (rows.isEmpty) return null;
    return rows.first[0] as String?;
  }

  Future<bool> budgetLocked(String projectId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT EXISTS (
          SELECT 1 FROM funding_requests
          WHERE project_id = @projectId::uuid AND status <> 'draft'
        ) AS locked
      '''),
      parameters: {'projectId': projectId},
    );
    return _asBool(rows.first.toColumnMap()['locked']);
  }

  Future<String?> insertUnsetPlanLine({
    required String projectId,
    required String companyId,
    required String title,
  }) async {
    final firms = await pool.execute(
      Sql.named('''
        SELECT id::text FROM contractor_firms
        WHERE owner_company_id = @company::uuid
        ORDER BY name
        LIMIT 1
      '''),
      parameters: {'company': companyId},
    );
    if (firms.isEmpty) return null;
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO budget_items (
          project_id, title, planned_amount, contractor_company_id, plan_set
        ) VALUES (
          @projectId::uuid, @title, 0, @firmId::uuid, false
        )
        RETURNING id::text
      '''),
      parameters: {
        'projectId': projectId,
        'title': title,
        'firmId': firms.first[0],
      },
    );
    return rows.first[0]! as String;
  }

  Future<String> insertBudgetLine({
    required String projectId,
    required String title,
    required String amount,
    required String contractorFirmId,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO budget_items (project_id, title, planned_amount, contractor_company_id, plan_set)
        VALUES (@projectId::uuid, @title, @amount::numeric(18,2), @firmId::uuid, true)
        RETURNING id::text
      '''),
      parameters: {
        'projectId': projectId,
        'title': title,
        'amount': amount,
        'firmId': contractorFirmId,
      },
    );
    return rows.first[0]! as String;
  }

  Future<bool> updateBudgetLine({
    required String projectId,
    required String itemId,
    required String title,
    required String amount,
    required String contractorFirmId,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        UPDATE budget_items
        SET title = @title,
            planned_amount = @amount::numeric(18,2),
            contractor_company_id = @firmId::uuid,
            plan_set = true
        WHERE id = @itemId::uuid AND project_id = @projectId::uuid
        RETURNING id::text
      '''),
      parameters: {
        'projectId': projectId,
        'itemId': itemId,
        'title': title,
        'amount': amount,
        'firmId': contractorFirmId,
      },
    );
    return rows.isNotEmpty;
  }

  Future<bool> deleteBudgetLine(String projectId, String itemId) async {
    final rows = await pool.execute(
      Sql.named('''
        DELETE FROM budget_items
        WHERE id = @itemId::uuid AND project_id = @projectId::uuid
        RETURNING id::text
      '''),
      parameters: {'projectId': projectId, 'itemId': itemId},
    );
    return rows.isNotEmpty;
  }

  Future<ProjectRecord> createProjectForDirector({
    required UserRecord director,
    required String name,
    required String address,
  }) async {
    return pool.runTx((session) async {
      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO projects (company_id, name, address)
          VALUES (@companyId::uuid, @name, @address)
          RETURNING id::text
        '''),
        parameters: {
          'companyId': director.companyId,
          'name': name,
          'address': address,
        },
      );
      final projectId = inserted.first[0]! as String;
      await session.execute(
        Sql.named('''
          INSERT INTO project_members (project_id, user_id, role)
          VALUES (@projectId::uuid, @userId::uuid, 'director')
        '''),
        parameters: {'projectId': projectId, 'userId': director.id},
      );
      return ProjectRecord(
        id: projectId,
        companyId: director.companyId,
        name: name,
        address: address,
        active: true,
        myRole: 'director',
      );
    });
  }

  Future<bool> lineBelongsToContractor({
    required String userId,
    required String projectId,
    required String itemId,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT 1
        FROM budget_items bi
        JOIN project_members m
          ON m.project_id = bi.project_id AND m.user_id = @userId::uuid
        WHERE bi.id = @itemId::uuid
          AND bi.project_id = @projectId::uuid
          AND (
            m.role IN ('director', 'developer')
            OR (
              m.role = 'contractor'
              AND bi.contractor_company_id = m.contractor_company_id
            )
          )
      '''),
      parameters: {'userId': userId, 'projectId': projectId, 'itemId': itemId},
    );
    return rows.isNotEmpty;
  }

  Future<List<RequestRecord>> requestsForUser(String userId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT $_requestColumns
        FROM funding_requests fr
        JOIN projects p ON p.id = fr.project_id
        JOIN budget_items bi ON bi.id = fr.budget_item_id
        LEFT JOIN project_members m
          ON m.project_id = fr.project_id AND m.user_id = @userId::uuid
        WHERE $_requestVisible
        ORDER BY fr.created_at DESC
      '''),
      parameters: {'userId': userId},
    );
    return [
      for (final row in rows) _requestFromMap(row.toColumnMap(), userId),
    ];
  }

  Future<List<RegistryRow>> requestRegistry({
    required String userId,
    required String status,
    required String projectId,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT p.name AS project_name,
               bi.title AS line_title,
               f.name AS firm_name,
               fr.id::text AS id,
               to_char(fr.amount, 'FM999999999999990.00') AS amount,
               fr.status AS status,
               COALESCE(to_char((
                 SELECT min(ae.created_at) FROM audit_events ae
                 WHERE ae.request_id = fr.id AND ae.action = 'submitted'
               ) AT TIME ZONE 'Asia/Tashkent', 'YYYY-MM-DD'), '') AS submitted_on,
               COALESCE(to_char(fr.paid_on, 'YYYY-MM-DD'), '') AS paid_on,
               COALESCE(fr.payment_number, '') AS payment_number
        FROM funding_requests fr
        JOIN projects p ON p.id = fr.project_id
        JOIN budget_items bi ON bi.id = fr.budget_item_id
        JOIN contractor_firms f ON f.id = bi.contractor_company_id
        LEFT JOIN project_members m
          ON m.project_id = fr.project_id AND m.user_id = @userId::uuid
        WHERE $_requestVisible
          AND (@status = '' OR fr.status = @status)
          AND (@projectId = '' OR fr.project_id::text = @projectId)
        ORDER BY fr.created_at, fr.id
      '''),
      parameters: {'userId': userId, 'status': status, 'projectId': projectId},
    );
    return [
      for (final row in rows)
        RegistryRow(
          projectName: row.toColumnMap()['project_name'] as String,
          lineTitle: row.toColumnMap()['line_title'] as String,
          firmName: row.toColumnMap()['firm_name'] as String,
          id: row.toColumnMap()['id'] as String,
          amount: row.toColumnMap()['amount'] as String,
          status: row.toColumnMap()['status'] as String,
          submittedOn: row.toColumnMap()['submitted_on'] as String,
          paidOn: row.toColumnMap()['paid_on'] as String,
          paymentNumber: row.toColumnMap()['payment_number'] as String,
        ),
    ];
  }

  Future<RequestRecord?> requestForUser(String userId, String requestId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT $_requestColumns
        FROM funding_requests fr
        JOIN projects p ON p.id = fr.project_id
        JOIN budget_items bi ON bi.id = fr.budget_item_id
        LEFT JOIN project_members m
          ON m.project_id = fr.project_id AND m.user_id = @userId::uuid
        WHERE fr.id = @requestId::uuid AND $_requestVisible
      '''),
      parameters: {'userId': userId, 'requestId': requestId},
    );
    if (rows.isEmpty) return null;
    final request = _requestFromMap(rows.first.toColumnMap(), userId);
    request.files.addAll(await _filesOf(request.id));
    request.events.addAll(await _eventsOf(request.id));
    return request;
  }

  Future<RequestRecord> insertDraft({
    required String userId,
    required String projectId,
    required String itemId,
    required String amount,
    required String description,
  }) async {
    final id = await pool.runTx((session) async {
      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO funding_requests (
            project_id, budget_item_id, contractor_user_id, author_user_id,
            amount, description, status
          ) VALUES (
            @projectId::uuid, @itemId::uuid, @userId::uuid, @userId::uuid,
            @amount::numeric, @description, 'draft'
          )
          RETURNING id::text
        '''),
        parameters: {
          'projectId': projectId,
          'itemId': itemId,
          'userId': userId,
          'amount': amount,
          'description': description,
        },
      );
      final requestId = inserted.first[0]! as String;
      await session.execute(
        Sql.named('''
          INSERT INTO audit_events (
            project_id, request_id, action, new_status, author_user_id, amount
          ) VALUES (
            @projectId::uuid, @requestId::uuid, 'draft_saved', 'draft',
            @userId::uuid, @amount::numeric
          )
        '''),
        parameters: {
          'projectId': projectId,
          'requestId': requestId,
          'userId': userId,
          'amount': amount,
        },
      );
      return requestId;
    });
    return (await requestForUser(userId, id))!;
  }

  Future<RequestRecord?> updateDraft({
    required String userId,
    required String requestId,
    required String itemId,
    required String amount,
    required String description,
  }) async {
    final rows = await pool.execute(
      Sql.named('''
        UPDATE funding_requests fr
        SET amount = @amount::numeric,
            description = @description,
            budget_item_id = @itemId::uuid,
            version = fr.version + 1,
            updated_at = now()
        FROM project_members m
        WHERE fr.id = @requestId::uuid
          AND fr.status = 'draft'
          AND m.project_id = fr.project_id
          AND m.user_id = @userId::uuid
          AND (
            m.role = 'developer'
            OR (
              fr.contractor_user_id = @userId::uuid
              AND m.role IN ('contractor', 'director')
            )
          )
        RETURNING fr.id::text
      '''),
      parameters: {
        'userId': userId,
        'requestId': requestId,
        'itemId': itemId,
        'amount': amount,
        'description': description,
      },
    );
    if (rows.isEmpty) return null;
    await pool.execute(
      Sql.named('''
        INSERT INTO audit_events (
          project_id, request_id, action, new_status, author_user_id, amount
        )
        SELECT fr.project_id, fr.id, 'draft_edited', 'draft', @userId::uuid, fr.amount
        FROM funding_requests fr
        WHERE fr.id = @requestId::uuid
      '''),
      parameters: {'userId': userId, 'requestId': requestId},
    );
    return requestForUser(userId, requestId);
  }

  Future<RequestFileRecord> addRequestFile({
    required String userId,
    required String requestId,
    required String contentType,
    required String kind,
    required int sizeBytes,
    required String fileRoot,
    String purpose = 'material',
  }) {
    return pool.runTx((session) async {
      final locked = await session.execute(
        Sql.named('''
          SELECT fr.status, fr.project_id::text
          FROM funding_requests fr
          JOIN project_members m
            ON m.project_id = fr.project_id AND m.user_id = @userId::uuid
          WHERE fr.id = @requestId::uuid
            AND (
              m.role = 'developer'
              OR (
                fr.contractor_user_id = @userId::uuid
                AND m.role IN ('contractor', 'director')
              )
            )
          FOR UPDATE OF fr
        '''),
        parameters: {'userId': userId, 'requestId': requestId},
      );
      if (locked.isEmpty) throw RequestRule('Транш не найден.');
      if (locked.first[0] != 'draft') {
        throw RequestRule('Файлы можно добавлять только в черновик.');
      }
      final counts = await session.execute(
        Sql.named('''
          SELECT
            COUNT(*) FILTER (WHERE purpose = 'material' AND content_type LIKE 'image/%') AS photos,
            COUNT(*) FILTER (WHERE purpose = 'material' AND content_type = 'application/pdf') AS pdfs
          FROM request_files
          WHERE request_id = @requestId::uuid
        '''),
        parameters: {'requestId': requestId},
      );
      final tally = counts.first.toColumnMap();
      if (kind == 'photo' && _asInt(tally['photos']) >= 5) {
        throw RequestRule('Можно добавить не больше 5 фото.');
      }
      if (kind == 'pdf' && _asInt(tally['pdfs']) >= 1) {
        throw RequestRule('PDF уже добавлен.');
      }
      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO request_files (
            request_id, storage_path, content_type, size_bytes, author_user_id, purpose
          )           VALUES (
            @requestId::uuid, '', @contentType, @size, @userId::uuid, @purpose
          )
          RETURNING id::text
        '''),
        parameters: {
          'requestId': requestId,
          'contentType': contentType,
          'size': sizeBytes,
          'userId': userId,
          'purpose': purpose,
        },
      );
      final fileId = inserted.first[0]! as String;
      final storagePath = '$fileRoot/$requestId/$fileId';
      await session.execute(
        Sql.named('''
          UPDATE request_files SET storage_path = @path WHERE id = @fileId::uuid
        '''),
        parameters: {'path': storagePath, 'fileId': fileId},
      );
      final projectId = locked.first[1]! as String;
      await session.execute(
        Sql.named('''
          INSERT INTO audit_events (
            project_id, request_id, action, author_user_id, reason
          ) VALUES (
            @projectId::uuid, @requestId::uuid, 'file_added', @userId::uuid, @kind
          )
        '''),
        parameters: {
          'projectId': projectId,
          'requestId': requestId,
          'userId': userId,
          'kind': kind,
        },
      );
      return RequestFileRecord(
        id: fileId,
        requestId: requestId,
        storagePath: storagePath,
        contentType: contentType,
        sizeBytes: sizeBytes,
        kind: kind,
        purpose: purpose,
      );
    });
  }

  Future<RequestFileRecord> addPaymentFile({
    required String userId,
    required String requestId,
    required String contentType,
    required String kind,
    required int sizeBytes,
    required String fileRoot,
  }) {
    return pool.runTx((session) async {
      final locked = await session.execute(
        Sql.named('''
          SELECT fr.status, fr.project_id::text
          FROM funding_requests fr
          JOIN project_members m
            ON m.project_id = fr.project_id AND m.user_id = @userId::uuid
          WHERE fr.id = @requestId::uuid AND m.role IN ('observer', 'developer')
          FOR UPDATE OF fr
        '''),
        parameters: {'userId': userId, 'requestId': requestId},
      );
      if (locked.isEmpty) throw RequestRule('Транш не найден.');
      if (locked.first[0] != 'approved') {
        throw RequestRule('Подтверждение можно добавить, когда банк одобрил транш.');
      }
      final counts = await session.execute(
        Sql.named('''
          SELECT COUNT(*) FROM request_files
          WHERE request_id = @requestId::uuid AND purpose = 'payment'
        '''),
        parameters: {'requestId': requestId},
      );
      if (_asInt(counts.first[0]) >= 1) {
        throw RequestRule('Подтверждение уже добавлено.');
      }
      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO request_files (
            request_id, storage_path, content_type, size_bytes, author_user_id, purpose
          ) VALUES (
            @requestId::uuid, '', @contentType, @size, @userId::uuid, 'payment'
          )
          RETURNING id::text
        '''),
        parameters: {
          'requestId': requestId,
          'contentType': contentType,
          'size': sizeBytes,
          'userId': userId,
        },
      );
      final fileId = inserted.first[0]! as String;
      final storagePath = '$fileRoot/$requestId/$fileId';
      await session.execute(
        Sql.named('UPDATE request_files SET storage_path = @path WHERE id = @fileId::uuid'),
        parameters: {'path': storagePath, 'fileId': fileId},
      );
      await session.execute(
        Sql.named('''
          INSERT INTO audit_events (
            project_id, request_id, action, author_user_id, reason
          ) VALUES (
            @projectId::uuid, @requestId::uuid, 'payment_file_added', @userId::uuid, @kind
          )
        '''),
        parameters: {
          'projectId': locked.first[1]! as String,
          'requestId': requestId,
          'userId': userId,
          'kind': kind,
        },
      );
      return RequestFileRecord(
        id: fileId,
        requestId: requestId,
        storagePath: storagePath,
        contentType: contentType,
        sizeBytes: sizeBytes,
        kind: kind,
        purpose: 'payment',
      );
    });
  }

  Future<String?> removePaymentFile({
    required String userId,
    required String requestId,
    required String fileId,
  }) {
    return pool.runTx((session) async {
      final rows = await session.execute(
        Sql.named('''
          DELETE FROM request_files rf
          USING funding_requests fr, project_members m
          WHERE rf.id = @fileId::uuid
            AND rf.request_id = @requestId::uuid
            AND rf.purpose = 'payment'
            AND fr.id = rf.request_id
            AND fr.status = 'approved'
            AND m.project_id = fr.project_id
            AND m.user_id = @userId::uuid
            AND m.role IN ('observer', 'developer')
          RETURNING rf.storage_path
        '''),
        parameters: {'userId': userId, 'requestId': requestId, 'fileId': fileId},
      );
      if (rows.isEmpty) return null;
      return rows.first[0] as String?;
    });
  }

  Future<String?> removeRequestFile({
    required String userId,
    required String requestId,
    required String fileId,
  }) {
    return pool.runTx((session) async {
      final rows = await session.execute(
        Sql.named('''
          DELETE FROM request_files rf
          USING funding_requests fr, project_members m
          WHERE rf.id = @fileId::uuid
            AND rf.request_id = @requestId::uuid
            AND fr.id = rf.request_id
            AND fr.status = 'draft'
            AND m.project_id = fr.project_id
            AND m.user_id = @userId::uuid
            AND (
              m.role = 'developer'
              OR (
                fr.contractor_user_id = @userId::uuid
                AND m.role IN ('contractor', 'director')
              )
            )
          RETURNING rf.storage_path, fr.project_id::text
        '''),
        parameters: {'userId': userId, 'requestId': requestId, 'fileId': fileId},
      );
      if (rows.isEmpty) return null;
      final path = rows.first[0]! as String;
      final projectId = rows.first[1]! as String;
      await session.execute(
        Sql.named('''
          INSERT INTO audit_events (
            project_id, request_id, action, author_user_id
          ) VALUES (
            @projectId::uuid, @requestId::uuid, 'file_removed', @userId::uuid
          )
        '''),
        parameters: {
          'projectId': projectId,
          'requestId': requestId,
          'userId': userId,
        },
      );
      return path;
    });
  }

  Future<RequestFileRecord?> fileForUser(
    String userId,
    String requestId,
    String fileId,
  ) async {
    final request = await requestForUser(userId, requestId);
    if (request == null) return null;
    for (final file in request.files) {
      if (file.id == fileId) return file;
    }
    return null;
  }

  Future<List<RequestFileRecord>> _filesOf(String requestId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT id::text AS id,
               request_id::text AS request_id,
               storage_path,
               content_type,
               size_bytes,
               purpose
        FROM request_files
        WHERE request_id = @requestId::uuid
        ORDER BY created_at
      '''),
      parameters: {'requestId': requestId},
    );
    return [
      for (final row in rows) RequestFileRecord.fromMap(row.toColumnMap()),
    ];
  }

  Future<List<RequestEventRecord>> _eventsOf(String requestId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT ae.action AS action,
               ae.old_status AS old_status,
               ae.new_status AS new_status,
               COALESCE(ae.reason, '') AS reason,
               to_char(ae.amount, 'FM999999999999990.00') AS amount,
               ae.created_at AS created_at,
               COALESCE(u.name, '') AS author_name
        FROM audit_events ae
        LEFT JOIN users u ON u.id = ae.author_user_id
        WHERE ae.request_id = @requestId::uuid
        ORDER BY ae.created_at, ae.id
      '''),
      parameters: {'requestId': requestId},
    );
    return [
      for (final row in rows) RequestEventRecord.fromMap(row.toColumnMap()),
    ];
  }
}

class RequestRule implements Exception {
  RequestRule(this.message);

  final String message;
}

class RequestFileRecord {
  RequestFileRecord({
    required this.id,
    required this.requestId,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    required this.kind,
    this.purpose = 'material',
  });

  final String id;
  final String requestId;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final String kind;
  final String purpose;

  factory RequestFileRecord.fromMap(Map<String, dynamic> map) {
    final contentType = map['content_type'] as String;
    return RequestFileRecord(
      id: map['id'] as String,
      requestId: map['request_id'] as String,
      storagePath: map['storage_path'] as String,
      contentType: contentType,
      sizeBytes: _asInt(map['size_bytes']),
      kind: contentType == 'application/pdf' ? 'pdf' : 'photo',
      purpose: map['purpose'] as String? ?? 'material',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'contentType': contentType,
    'sizeBytes': sizeBytes,
    'kind': kind,
    'purpose': purpose,
  };
}

class RequestRecord {
  RequestRecord({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.budgetItemId,
    required this.lineTitle,
    required this.amount,
    required this.description,
    required this.status,
    required this.mine,
    this.version = 1,
    this.paidOn,
    this.paymentNumber,
    this.addresseeUserId,
    this.addresseeName,
    this.addresseeRole,
    this.forBank = false,
    this.bankSent = false,
    this.trancheNo,
    this.confirmedAmount,
    this.decision,
    this.fundingPaused = false,
    this.linePlan = moneyZero,
    this.lineReserved = moneyZero,
    this.linePaid = moneyZero,
    this.lineAvailable = moneyZero,
    this.planSet = true,
    this.hasAct = false,
    this.hasInvoice = false,
    List<RequestFileRecord>? files,
    List<RequestEventRecord>? events,
  }) : files = files ?? <RequestFileRecord>[],
       events = events ?? <RequestEventRecord>[];

  final String id;
  final String projectId;
  final String projectName;
  final String budgetItemId;
  final String lineTitle;
  final String amount;
  final String description;
  final String status;
  final bool mine;
  final int version;
  final String? paidOn;
  final String? paymentNumber;
  final String? addresseeUserId;
  final String? addresseeName;
  final String? addresseeRole;
  final bool forBank;
  final bool bankSent;
  final int? trancheNo;
  final String? confirmedAmount;
  final String? decision;
  final bool fundingPaused;
  final String linePlan;
  final String lineReserved;
  final String linePaid;
  final String lineAvailable;
  final bool planSet;
  final bool hasAct;
  final bool hasInvoice;
  final List<RequestFileRecord> files;
  final List<RequestEventRecord> events;

  Map<String, Object?> toJson() => {
    'id': id,
    'projectId': projectId,
    'projectName': projectName,
    'budgetItemId': budgetItemId,
    'lineTitle': lineTitle,
    'amount': amount,
    'description': description,
    'status': status,
    'mine': mine,
    'version': version,
    'paidOn': paidOn,
    'paymentNumber': paymentNumber,
    'addresseeUserId': addresseeUserId,
    'addresseeName': addresseeName,
    'addresseeRole': addresseeRole,
    'forBank': forBank,
    'bankSent': bankSent,
    'trancheNo': trancheNo,
    'confirmedAmount': confirmedAmount,
    'decision': decision,
    'fundingPaused': fundingPaused,
    'linePlan': linePlan,
    'lineReserved': lineReserved,
    'linePaid': linePaid,
    'lineAvailable': lineAvailable,
    'planSet': planSet,
    'hasAct': hasAct,
    'hasInvoice': hasInvoice,
    'files': [for (final file in files) file.toJson()],
    'events': [for (final event in events) event.toJson()],
  };
}

class RequestEventRecord {
  RequestEventRecord({
    required this.action,
    required this.oldStatus,
    required this.newStatus,
    required this.reason,
    required this.amount,
    required this.at,
    required this.authorName,
  });

  final String action;
  final String? oldStatus;
  final String? newStatus;
  final String reason;
  final String? amount;
  final String at;
  final String authorName;

  factory RequestEventRecord.fromMap(Map<String, dynamic> map) {
    final at = map['created_at'];
    final stamp = at is DateTime ? at.toUtc().toIso8601String() : at.toString();
    final amount = map['amount'] as String?;
    return RequestEventRecord(
      action: map['action'] as String,
      oldStatus: map['old_status'] as String?,
      newStatus: map['new_status'] as String?,
      reason: map['reason'] as String? ?? '',
      amount: amount == null || amount.isEmpty ? null : amount,
      at: stamp,
      authorName: map['author_name'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'action': action,
    'oldStatus': oldStatus,
    'newStatus': newStatus,
    'reason': reason,
    'amount': amount,
    'at': at,
    'authorName': authorName,
  };
}

const _requestColumns = '''
  fr.id::text AS id,
  fr.project_id::text AS project_id,
  p.name AS project_name,
  fr.budget_item_id::text AS budget_item_id,
  bi.title AS line_title,
  to_char(fr.amount, 'FM999999999999990.00') AS amount,
  fr.description AS description,
  fr.status AS status,
  fr.version AS version,
  to_char(fr.paid_on, 'YYYY-MM-DD') AS paid_on,
  fr.payment_number AS payment_number,
  fr.contractor_user_id::text AS contractor_user_id,
  fr.addressee_user_id::text AS addressee_user_id,
  fr.for_bank AS for_bank,
  (fr.bank_sent_at IS NOT NULL) AS bank_sent,
  COALESCE((SELECT u.name FROM users u WHERE u.id = fr.addressee_user_id), '') AS addressee_name,
  COALESCE((
    SELECT pm.role FROM project_members pm
    WHERE pm.project_id = fr.project_id AND pm.user_id = fr.addressee_user_id
  ), '') AS addressee_role,
  $requestTrancheColumns
''';

const requestTrancheColumns = '''
  fr.tranche_no AS tranche_no,
  to_char(fr.confirmed_amount, 'FM999999999999990.00') AS confirmed_amount,
  COALESCE(fr.decision, '') AS decision,
  p.funding_paused AS funding_paused,
  to_char(CASE WHEN bi.plan_set THEN bi.planned_amount ELSE 0 END, 'FM999999999999990.00') AS line_plan,
  to_char(CASE WHEN bi.plan_set THEN line_hold(fr.budget_item_id, ARRAY['submitted', 'tech_approved', 'approved']) ELSE 0 END, 'FM999999999999990.00') AS line_reserved,
  to_char(CASE WHEN bi.plan_set THEN line_hold(fr.budget_item_id, ARRAY['paid']) ELSE 0 END, 'FM999999999999990.00') AS line_paid,
  to_char(
    CASE WHEN bi.plan_set THEN
      bi.planned_amount
        - line_hold(fr.budget_item_id, ARRAY['submitted', 'tech_approved', 'approved'])
        - line_hold(fr.budget_item_id, ARRAY['paid'])
    ELSE 0 END,
    'FM999999999999990.00'
  ) AS line_available,
  bi.plan_set AS plan_set,
  EXISTS (
    SELECT 1 FROM request_files rf
    WHERE rf.request_id = fr.id AND rf.purpose = 'act'
  ) AS has_act,
  EXISTS (
    SELECT 1 FROM request_files rf
    WHERE rf.request_id = fr.id AND rf.purpose = 'invoice'
  ) AS has_invoice
''';

class RegistryRow {
  const RegistryRow({
    required this.projectName,
    required this.lineTitle,
    required this.firmName,
    required this.id,
    required this.amount,
    required this.status,
    required this.submittedOn,
    required this.paidOn,
    required this.paymentNumber,
  });

  final String projectName;
  final String lineTitle;
  final String firmName;
  final String id;
  final String amount;
  final String status;
  final String submittedOn;
  final String paidOn;
  final String paymentNumber;
}

const _requestVisible = '''
  (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = @userId::uuid AND u.platform_admin
    )
    OR (
      m.user_id IS NOT NULL
      AND (
        m.role = 'developer'
        OR fr.contractor_user_id = @userId::uuid
        OR (
          m.role = 'contractor'
          AND fr.status <> 'draft'
          AND bi.contractor_company_id = m.contractor_company_id
        )
        OR (m.role <> 'contractor' AND fr.status <> 'draft')
      )
    )
  )
''';

RequestRecord _requestFromMap(Map<String, dynamic> map, String userId) {
  return RequestRecord(
    id: map['id'] as String,
    projectId: map['project_id'] as String,
    projectName: map['project_name'] as String,
    budgetItemId: map['budget_item_id'] as String,
    lineTitle: map['line_title'] as String,
    amount: map['amount'] as String,
    description: map['description'] as String? ?? '',
    status: map['status'] as String,
    mine: map['contractor_user_id'] == userId,
    version: _asInt(map['version']),
    paidOn: map['paid_on'] as String?,
    paymentNumber: map['payment_number'] as String?,
    addresseeUserId: map['addressee_user_id'] as String?,
    addresseeName: (map['addressee_name'] as String?)?.isEmpty == true
        ? null
        : map['addressee_name'] as String?,
    addresseeRole: (map['addressee_role'] as String?)?.isEmpty == true
        ? null
        : map['addressee_role'] as String?,
    forBank: map['for_bank'] == true,
    bankSent: map['bank_sent'] == true,
    trancheNo: map['tranche_no'] == null ? null : _asInt(map['tranche_no']),
    confirmedAmount: map['confirmed_amount'] as String?,
    decision: (map['decision'] as String?)?.isEmpty == true ? null : map['decision'] as String?,
    fundingPaused: _asBool(map['funding_paused']),
    linePlan: map['line_plan'] as String? ?? moneyZero,
    lineReserved: map['line_reserved'] as String? ?? moneyZero,
    linePaid: map['line_paid'] as String? ?? moneyZero,
    lineAvailable: map['line_available'] as String? ?? moneyZero,
    planSet: map['plan_set'] == null ? true : _asBool(map['plan_set']),
    hasAct: map['has_act'] == true,
    hasInvoice: map['has_invoice'] == true,
  );
}

String _withPoolDefaults(String databaseUrl) {
  final uri = Uri.parse(databaseUrl);
  final params = Map<String, String>.from(uri.queryParameters);
  params.putIfAbsent('sslmode', () => 'disable');
  params.putIfAbsent('max_connection_count', () => '5');
  return uri.replace(queryParameters: params).toString();
}

String _databasePassword(String databaseUrl) {
  final userInfo = Uri.parse(databaseUrl).userInfo;
  final separator = userInfo.indexOf(':');
  if (separator < 0 || separator == userInfo.length - 1) return '';
  return Uri.decodeComponent(userInfo.substring(separator + 1));
}

String _appDatabaseUrl(String databaseUrl) {
  final uri = Uri.parse(databaseUrl);
  final password = _databasePassword(databaseUrl);
  return uri.replace(userInfo: 'ibuild_app:$password').toString();
}

List<String> _splitSql(String sql) {
  final withoutComments = sql
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('--'))
      .join('\n');
  final statements = <String>[];
  final current = StringBuffer();
  var quoted = false;
  for (var i = 0; i < withoutComments.length; i++) {
    final char = withoutComments[i];
    final dollar = char == r'$' &&
        i + 1 < withoutComments.length &&
        withoutComments[i + 1] == r'$';
    if (dollar) {
      quoted = !quoted;
      current.write(r'$$');
      i++;
      continue;
    }
    if (!quoted && char == ';') {
      final statement = current.toString().trim();
      if (statement.isNotEmpty) statements.add(statement);
      current.clear();
      continue;
    }
    current.write(char);
  }
  final tail = current.toString().trim();
  if (tail.isNotEmpty) statements.add(tail);
  return statements;
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.parse(value.toString());
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == 't';
}

UserRecord _userFromRow(Map<String, dynamic> map) {
  return UserRecord(
    id: map['id'] as String,
    companyId: map['company_id'] as String,
    companyName: map['company_name'] as String,
    name: map['name'] as String,
    login: map['login'] as String,
    passwordHash: map['password_hash'] as String,
    active: _asBool(map['active']),
    platformAdmin: _asBool(map['platform_admin']),
    mustChangePassword: _asBool(map['must_change_password']),
    isDemo: _asBool(map['is_demo']),
  );
}

ProjectRecord _projectFromMap(Map<String, dynamic> map) {
  return ProjectRecord(
    id: map['id'] as String,
    companyId: map['company_id'] as String,
    name: map['name'] as String,
    address: map['address'] as String,
    active: _asBool(map['active']),
    myRole: map['role'] as String,
    fundingPaused: _asBool(map['funding_paused']),
    hasPhoto: _asBool(map['has_photo']),
    companyName: map['company_name'] as String? ?? '',
    description: map['description'] as String? ?? '',
    bankName: map['bank_name'] as String? ?? '',
    latitude: _blankToNull(map['latitude']),
    longitude: _blankToNull(map['longitude']),
  );
}

String? _blankToNull(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return text;
}
