import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'bank_referral_service.dart';
import 'db/database.dart';
import 'db/pg_config.dart';
import 'db/pg_persistence.dart';
import 'env_loader.dart';
import 'sms_service.dart';
import 'user_roles.dart';
import 'seed_data.dart';
import 'validation.dart';

/// Monthly B2B publish subscription (USD). Kept for backward compatibility —
/// equal to the `growth` tier below, which is the default plan assigned on
/// developer approval.
const kBusinessSubscriptionUsd = 299.0;
const kBusinessSubscriptionPlanId = 'growth';

/// Developer application review pipeline: new applications are saved as `draft`
/// until the applicant explicitly submits for review (`pending` — "waiting for
/// review"). A platform admin may move one into `in_review` ("on review")
/// while investigating, then finalize as `approved` or `rejected` (with a
/// reason). A `rejected` applicant may edit and save a new `draft`, then
/// submit again.
const kDeveloperVerificationStatuses = {
  'draft',
  'pending',
  'in_review',
  'approved',
  'rejected',
};

/// Subscription tier ladder (Konseptsiya §11.A.1 — "линейка тарифов" instead
/// of the single $199/299 plan the original presentation proposed). Each
/// tier caps how many projects/units a developer may publish and how many
/// leads are included before pay-per-lead overage applies.
const kSubscriptionPlans = <Map<String, dynamic>>[
  {
    'id': 'start',
    'name': 'Start',
    'priceUsd': 99.0,
    'maxProjects': 3,
    'maxUnits': 300,
    'includedLeadsPerMonth': 50,
    'payPerLeadUsd': 3.0,
  },
  {
    'id': 'growth',
    'name': 'Growth',
    'priceUsd': 299.0,
    'maxProjects': 10,
    'maxUnits': 2000,
    'includedLeadsPerMonth': 250,
    'payPerLeadUsd': 2.5,
  },
  {
    'id': 'corporate',
    'name': 'Corporate',
    'priceUsd': 799.0,
    'maxProjects': -1, // unlimited
    'maxUnits': -1, // unlimited
    'includedLeadsPerMonth': 1000,
    'payPerLeadUsd': 2.0,
  },
];

Map<String, dynamic>? subscriptionPlanById(String id) {
  for (final plan in kSubscriptionPlans) {
    if (plan['id'] == id) return plan;
  }
  return null;
}

/// The 4 document types a developer must have `accepted` before a platform
/// admin can approve their organization (frozen contract — Documents API).
const kRequiredDocumentTypes = {
  'license',
  'construction_permit',
  'land_rights',
  'project_declaration',
};

/// Uploadable alongside the required 4, but never checked by
/// [Store.hasAllRequiredDocumentsAccepted] or [Store.documentStatusSummary] —
/// purely informational (e.g. cadastral extract) and never blocks approval.
const kOptionalDocumentTypes = {'cadastre'};

/// Every type accepted by the upload endpoints — required ∪ optional.
const kAllowedDocumentTypes = {
  ...kRequiredDocumentTypes,
  ...kOptionalDocumentTypes,
};

const kDocumentStatuses = {'pending', 'accepted', 'rejected'};

/// Thrown by [Store.updateUnit] when the caller's `expectedVersion` no
/// longer matches the row's current `version` (optimistic locking — see
/// `PATCH /v1/admin/units/:uid` in admin_routes.dart, which maps this to a
/// `409 UNIT_CONFLICT`).
class UnitConflictException implements Exception {
  UnitConflictException(this.currentVersion, this.unit);

  final int currentVersion;
  final Map<String, dynamic> unit;

  @override
  String toString() => 'UnitConflictException(currentVersion: $currentVersion)';
}

/// Sanitizes [v] only when it is a String (see [sanitizeText]); numbers,
/// bools, lists and `null` pass through untouched. Used to scrub stored
/// free-text fields as they are copied out of untyped request-body maps
/// without disturbing structured fields.
Object? _clean(Object? v) => v is String ? sanitizeText(v) : v;

/// Dev-mode fixed OTP code, used ONLY outside production (see
/// [Store.createOtpRequest]). In production a cryptographically-random code
/// is always generated instead, and this constant is never sent.
const kDevOtpCode = '123456';

/// How long a `requestId` from `/v1/auth/otp/send` stays valid.
const _otpTtl = Duration(minutes: 5);

/// Maximum wrong `otp/verify` attempts per `requestId` before it is
/// invalidated, to keep the ~1M-code space from being brute-forced.
const kMaxOtpAttempts = 5;

/// Access-token / refresh-token lifetimes. Opaque tokens now carry an
/// expiry so a leaked/stale token cannot be replayed forever; the refresh
/// flow rotates and re-issues both with fresh TTLs.
const _accessTokenTtl = Duration(hours: 12);
const _refreshTokenTtl = Duration(days: 30);

class _OtpRequest {
  _OtpRequest(this.phone, this.code) : expiresAt = DateTime.now().add(_otpTtl);

  final String phone;
  final String code;
  final DateTime expiresAt;
  int attempts = 0;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Outcome of [Store.verifyOtp]: either a minted token pair or a typed
/// failure so the route can map it to the right status/message.
enum OtpVerifyError { notFound, invalidCode, tooManyAttempts }

class OtpVerifyResult {
  OtpVerifyResult.success({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  }) : error = null;

  OtpVerifyResult.failure(this.error)
    : accessToken = null,
      refreshToken = null,
      user = null;

  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final OtpVerifyError? error;

  bool get isSuccess => error == null;
}

/// An issued session (opaque token -> phone) with an absolute expiry.
class _Session {
  _Session(this.phone, this.expiresAt);

  final String phone;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory data store + live WebSocket broadcast, standing in for
/// PostgreSQL + Redis pub/sub (plan §6.3) in this dev server.
///
/// Persistence is opt-in and purely additive: the plain [Store] constructor
/// below is unchanged from before PostgreSQL support existed, and stays
/// fully synchronous/in-memory — every existing test keeps using it as-is.
/// [Store.create] is the only entry point that may attach a PostgreSQL-backed
/// [PgPersistence] layer underneath the same in-memory model, based on
/// [PgConfig.fromEnv].
class Store {
  Store() : projects = buildProjectsSeed() {
    for (final project in projects) {
      project.putIfAbsent('isPublished', () => true);
      project.putIfAbsent('moderationStatus', () => 'approved');
      project.putIfAbsent('moderationNote', () => null);
      final developer = project['developer'] as Map<String, dynamic>?;
      if (developer != null) {
        final id = developer['id'] as String;
        if (!developersRegistry.any((d) => d['id'] == id)) {
          developersRegistry.add({
            ...developer,
            'verificationStatus': 'approved',
            'rejectionReason': null,
            'ownerUserId': null,
            'legalName': null,
            'inn': null,
            'website': null,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }
    _seedDefaultAdmins();
    _seedLeads();
    _seedReviewsAndRentalListings();
    _startLiveUpdates();
  }

  void _seedReviewsAndRentalListings() {
    final p1 = projects[0];
    final p2 = projects[1];
    reviews.addAll([
      {
        'id': 'rev-seed-1',
        'userId': 'user-seed-1',
        'userName': 'Aziz K.',
        'projectId': p1['id'],
        'developerId': (p1['developer'] as Map)['id'],
        'ratingOverall': 5,
        'ratingLocation': 5,
        'ratingQuality': 4,
        'ratingValue': 4,
        'body':
            'Moved in last year — the pool deck and concierge are '
            'genuinely as advertised. Construction quality is solid.',
        'status': 'published',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 40))
            .toIso8601String(),
      },
      {
        'id': 'rev-seed-2',
        'userId': 'user-seed-2',
        'userName': 'Malika T.',
        'projectId': p2['id'],
        'developerId': (p2['developer'] as Map)['id'],
        'ratingOverall': 4,
        'ratingLocation': 4,
        'ratingQuality': 4,
        'ratingValue': 5,
        'body':
            'Installment terms were exactly as promised, no hidden fees. '
            'Still under construction but progress updates are frequent.',
        'status': 'published',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 12))
            .toIso8601String(),
      },
    ]);
    for (final p in [p1, p2]) {
      _recomputeProjectRating(p['id'] as String);
    }

    rentalListings.addAll([
      {
        'id': 'rl-seed-1',
        'ownerUserId': 'user-seed-owner-1',
        'title': 'Cozy 2-room flat near Chorsu bazaar',
        'description':
            'Second-hand apartment, recently renovated, 5 minutes to metro. '
            'Long-term tenants preferred.',
        'district': 'Shayxontohur',
        'address': 'Chorsu maydoni 6, Tashkent',
        'lat': 41.3269,
        'lng': 69.2350,
        'propertyKind': 'apartment',
        'dealType': 'rent',
        'areaTotal': 54.0,
        'rooms': 2,
        'rentMonthly': 320.0,
        'minLeaseMonths': 12,
        'contactPhone': '+998 90 123 00 11',
        'photos': [
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Skyline_of_Tashkent.jpg/1280px-Skyline_of_Tashkent.jpg',
        ],
        'isSecondary': true,
        'moderationStatus': 'approved',
        'moderationNote': null,
        'isFeatured': false,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
      },
    ]);
  }

  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> leads = [];
  final List<Map<String, dynamic>> leadEvents = [];
  final List<Map<String, dynamic>> developersRegistry = [];

  /// developerId -> subscription record
  final Map<String, Map<String, dynamic>> subscriptionsByDeveloperId = {};
  final Map<String, Set<String>> favoritesByUser = {};
  final Map<String, List<Map<String, dynamic>>> savedSearchesByUser = {};
  final List<Map<String, dynamic>> auditLog = [];

  /// Developer verification documents (Documents API — trust layer).
  final List<Map<String, dynamic>> documents = [];

  /// Construction-progress photo reports (Photo Reports API).
  final List<Map<String, dynamic>> photoReports = [];

  /// Admin notification inbox — every developer-side change that needs a
  /// system admin's attention (see [notifyAdmins]).
  final List<Map<String, dynamic>> notifications = [];

  /// Reviews left by buyers/renters on a project + its developer
  /// (Konseptsiya §9 "честные отзывы"). Published immediately; a system
  /// admin may flag/remove abusive ones via the platform moderation queue.
  final List<Map<String, dynamic>> reviews = [];

  /// Secondary-market and developer-primary **rental** listings submitted by
  /// private owners without a full developer dashboard (Konseptsiya §5, §8:
  /// "упрощённая форма размещения объявления без полноценного дашборда
  /// застройщика"). Never used for sale — the platform never lists secondary
  /// housing for purchase, only for rent.
  final List<Map<String, dynamic>> rentalListings = [];

  /// Connected live-update sockets, mapped to whether the authenticated
  /// subscriber is an admin (system/residence). Lead events — which carry
  /// CRM/PII metadata — are only pushed to admin sockets (see [_broadcast]).
  final Map<WebSocketChannel, bool> _sockets = {};
  final Random _rand = Random();

  /// Cryptographically-secure RNG used for OTP codes (never `Random()`).
  final Random _secureRand = Random.secure();
  final Uuid _uuid = const Uuid();
  final SmsService sms = SmsService();
  final BankReferralService bankReferrals = BankReferralService();
  int _leadSeq = 100241;
  Timer? _ticker;
  Timer? _offerTicker;

  Database? _db;
  PgPersistence? _persistence;

  /// `DB_HOST` was set but [create] could not attach PostgreSQL (startup
  /// still serves in-memory seed for read-only demos, but destructive writes
  /// must fail loudly instead of pretending to persist).
  bool _persistenceRequired = false;

  /// Tombstone set: blocks late fire-and-forget `saveProject` calls from
  /// re-inserting a row after [deleteProject] has removed it from the DB.
  final Set<String> _deletedProjectIds = {};

  /// Whether a PostgreSQL persistence layer is attached (see [create]).
  bool get hasPersistence => _persistence != null;

  /// Whether `DB_*` env was set so mutations are expected to hit PostgreSQL.
  bool get persistenceRequired => _persistenceRequired;

  /// Exposed for request-scoped RLS context binding.
  PgPersistence? get persistence => _persistence;

  /// Builds a [Store] exactly like the plain constructor (in-memory seed
  /// data, tickers running), then — only if [PgConfig.fromEnv] finds
  /// `DB_HOST` set — connects to PostgreSQL, runs migrations, and either
  /// seeds the database from the freshly-built in-memory data (first run,
  /// gated by `app_meta.catalogue_seeded` so an admin wipe is not undone)
  /// or replaces the in-memory `projects`/`leads` with what's already
  /// persisted (subsequent runs resume state instead of re-seeding).
  ///
  /// If `DB_HOST` is unset, this returns the same plain in-memory [Store]
  /// with zero behavior change. If a database *is* configured but fails to
  /// connect/migrate, the error is logged to stderr and the store still
  /// falls back to pure in-memory mode rather than crashing startup.
  static Future<Store> create() async {
    final store = Store();

    final config = PgConfig.fromEnv();
    if (config == null) {
      store.stageDemoTrustDataIfEnabled();
      return store;
    }

    store._persistenceRequired = true;

    final db = Database(config);
    try {
      await db.connect();
      await db.migrate();
      final persistence = PgPersistence(db);
      // RLS: startup/seed runs as service role (FORCE RLS on tenant tables).
      await persistence.setRequestContext(role: 'service');

      if (await persistence.needsCatalogueSeed()) {
        // First boot against an unseeded database: persist the in-memory seed.
        await persistence.seedFrom(store.projects);
        for (final lead in store.leads) {
          await persistence.saveLead(lead);
        }
        await persistence.seedAuxiliary(
          reviews: store.reviews,
          rentalListings: store.rentalListings,
        );
      } else {
        // Subsequent boots (including after an intentional catalogue wipe):
        // resume persisted state instead of re-seeding.
        store.projects
          ..clear()
          ..addAll(await persistence.loadAllProjects());
        store.leads
          ..clear()
          ..addAll(await persistence.loadAllLeads());
        final loadedReviews = await persistence.loadAllReviews();
        final loadedRentals = await persistence.loadAllRentalListings();
        if (loadedReviews.isEmpty && loadedRentals.isEmpty) {
          // Database predates review/rental persistence: seed them once.
          await persistence.seedAuxiliary(
            reviews: store.reviews,
            rentalListings: store.rentalListings,
          );
        } else {
          store.reviews
            ..clear()
            ..addAll(loadedReviews);
          store.rentalListings
            ..clear()
            ..addAll(loadedRentals);
        }
      }

      store._db = db;
      store._persistence = persistence;
      store.tickets
        ..clear()
        ..addAll(await persistence.loadAllTickets());
      store._ingestUsers(await persistence.loadAllUsers());
      final sessions = await persistence.loadAllSessions();
      final nowUtc = DateTime.now();
      for (final s in sessions) {
        final phone = normalizePhone(s.phone);
        final accessExpiry = s.expiresAt ?? nowUtc.add(_accessTokenTtl);
        if (!nowUtc.isAfter(accessExpiry)) {
          store._sessionsByToken[s.accessToken] = _Session(phone, accessExpiry);
        }
        final refresh = s.refreshToken;
        if (refresh != null && refresh.isNotEmpty) {
          final refreshExpiry =
              s.refreshExpiresAt ?? nowUtc.add(_refreshTokenTtl);
          if (!nowUtc.isAfter(refreshExpiry)) {
            store._refreshTokens[refresh] = _Session(phone, refreshExpiry);
          }
        }
      }
      final loadedDevs = await persistence.loadAllDevelopers();
      if (loadedDevs.isNotEmpty) {
        // Keep seed catalogue developers that have no owner; replace owned ones.
        store.developersRegistry.removeWhere((d) => d['ownerUserId'] != null);
        final existingIds = store.developersRegistry
            .map((d) => d['id'])
            .toSet();
        for (final d in loadedDevs) {
          if (existingIds.contains(d['id'])) {
            final i = store.developersRegistry.indexWhere(
              (x) => x['id'] == d['id'],
            );
            if (i >= 0) store.developersRegistry[i] = d;
          } else {
            store.developersRegistry.add(d);
          }
        }
      }
      store._hydrateAllProjectDevelopers();
      store.subscriptionsByDeveloperId
        ..clear()
        ..addAll(await persistence.loadAllSubscriptions());
      store.favoritesByUser
        ..clear()
        ..addAll(await persistence.loadAllFavorites());
      store.savedSearchesByUser
        ..clear()
        ..addAll(await persistence.loadAllSavedSearches());
      store.auditLog
        ..clear()
        ..addAll(await persistence.loadAuditLog());
      store.documents
        ..clear()
        ..addAll(await persistence.loadAllDocuments());
      store.photoReports
        ..clear()
        ..addAll(await persistence.loadAllPhotoReports());
      store.notifications
        ..clear()
        ..addAll(await persistence.loadAllNotifications());
      // Re-apply after DB load so platform admin phones keep system_admin
      // even if an earlier OTP created them as ordinary_user.
      store._seedDefaultAdmins();
      store.stageDemoTrustDataIfEnabled();
    } catch (error, stackTrace) {
      stderr.writeln(
        '\n'
        '!!! ======================================================== !!!\n'
        '!!! [Store] PostgreSQL persistence FAILED to initialize.     !!!\n'
        '!!! The server is running IN-MEMORY ONLY: accounts, projects !!!\n'
        '!!! and units will ALL BE LOST when the server restarts.     !!!\n'
        '!!! Config: $config\n'
        '!!! Error:  $error\n'
        '!!! ======================================================== !!!\n'
        '$stackTrace',
      );
      unawaited(db.close().catchError((_) {}));
      store._clearSeedCatalogueOnPersistenceFailure();
      store.stageDemoTrustDataIfEnabled();
    }

    return store;
  }

  /// When `DEMO_STAGE_TRUST=true`, ensures the first published residential
  /// project has all 4 KYC docs accepted + a few construction photo reports
  /// so the B2C "Verified" badge and Progress tab work in investor demos
  /// without manual staging. Idempotent — skips if that developer already
  /// has accepted docs.
  void stageDemoTrustDataIfEnabled() {
    final enabled =
        (appEnv()['DEMO_STAGE_TRUST'] ?? '').trim().toLowerCase() == 'true';
    if (!enabled) return;
    if (projects.isEmpty) {
      stderr.writeln(
        '[Store] DEMO_STAGE_TRUST=true but no projects loaded — skip trust staging.',
      );
      return;
    }

    final showcase = projects.firstWhere(
      (p) =>
          (p['type'] == 'residential_complex' ||
              p['type'] == 'residential') &&
          (p['isPublished'] as bool? ?? true),
      orElse: () => projects.first,
    );
    final developer = showcase['developer'] as Map?;
    final developerId = developer?['id'] as String?;
    final projectId = showcase['id'] as String?;
    if (developerId == null || projectId == null) return;

    if (hasAllRequiredDocumentsAccepted(developerId)) {
      stderr.writeln(
        '[Store] DEMO_STAGE_TRUST: $developerId already fully verified — skip docs.',
      );
    } else {
      const adminId = 'demo-trust-stager';
      for (final type in kRequiredDocumentTypes) {
        final existing = documentsForDeveloper(developerId).any(
          (d) => d['type'] == type && d['status'] == 'accepted',
        );
        if (existing) continue;
        final doc = addDocument(
          developerId: developerId,
          projectId: projectId,
          type: type,
          fileUrl: '/v1/static/demo/$type.pdf',
          uploadedBy: adminId,
        );
        reviewDocument(
          doc['id'] as String,
          status: 'accepted',
          reviewedBy: adminId,
        );
      }
      // Keep registry status aligned with a reviewed org.
      final reg = developerById(developerId);
      if (reg != null) {
        reg['verificationStatus'] = 'approved';
        _persistDeveloper(reg);
      }
      stderr.writeln(
        '[Store] DEMO_STAGE_TRUST: accepted KYC docs for $developerId '
        '(${showcase['name']}).',
      );
    }

    final existingReports = photoReportsForProject(projectId);
    if (existingReports.length >= 2) {
      stderr.writeln(
        '[Store] DEMO_STAGE_TRUST: photo reports already present for $projectId.',
      );
      return;
    }
    final now = DateTime.now();
    addPhotoReport(
      projectId: projectId,
      photoUrl: 'https://picsum.photos/seed/ibuild-progress-1/800/600',
      takenAt: now.subtract(const Duration(days: 60)),
      takenAtIsManual: true,
      progressPercent: 45,
      uploadedBy: 'demo-trust-stager',
    );
    addPhotoReport(
      projectId: projectId,
      photoUrl: 'https://picsum.photos/seed/ibuild-progress-2/800/600',
      takenAt: now.subtract(const Duration(days: 20)),
      takenAtIsManual: true,
      progressPercent: 68,
      uploadedBy: 'demo-trust-stager',
    );
    addPhotoReport(
      projectId: projectId,
      photoUrl: 'https://picsum.photos/seed/ibuild-progress-3/800/600',
      takenAt: now.subtract(const Duration(days: 3)),
      takenAtIsManual: true,
      progressPercent: 75,
      uploadedBy: 'demo-trust-stager',
    );
    stderr.writeln(
      '[Store] DEMO_STAGE_TRUST: photo reports staged for ${showcase['name']}.',
    );
  }

  /// requestId -> pending OTP request (plan §5, dev/demo phone-OTP auth).
  final Map<String, _OtpRequest> _otpRequests = {};

  /// phone -> user record, created on first successful OTP verification.
  final Map<String, Map<String, dynamic>> _usersByPhone = {};

  /// accessToken -> session (phone + expiry)
  final Map<String, _Session> _sessionsByToken = {};

  /// refreshToken -> session (phone + expiry)
  final Map<String, _Session> _refreshTokens = {};

  /// Phones that must always be [UserRole.systemAdmin] (platform operators).
  ///
  /// In production these MUST come from `SYSTEM_ADMIN_PHONES` — there is no
  /// hardcoded default (the server refuses to start without it, see
  /// `assertProductionSecrets`). Outside production the historical operator
  /// number stays seeded for zero-config local dev/tests.
  Set<String> get _systemAdminPhones {
    final defaults = isProduction
        ? const <String>[]
        : const ['+998903306416'];
    final fromEnv =
        appEnv()['SYSTEM_ADMIN_PHONES']
            ?.split(',')
            .map((p) => normalizePhone(p))
            .where((p) => p.isNotEmpty) ??
        const <String>[];
    return {...defaults.map(normalizePhone), ...fromEnv};
  }

  void _seedDefaultAdmins() {
    for (final phone in _systemAdminPhones) {
      ensureUser(phone: phone, role: UserRole.systemAdmin);
    }
  }

  /// Loads persisted users under normalized phone keys (merging duplicates).
  void _ingestUsers(Map<String, Map<String, dynamic>> loaded) {
    for (final entry in loaded.entries) {
      final phone = normalizePhone(entry.key);
      final incoming = Map<String, dynamic>.from(entry.value);
      incoming['phone'] = phone;
      final existing = _usersByPhone[phone];
      if (existing == null) {
        _usersByPhone[phone] = incoming;
        continue;
      }
      // Prefer elevated roles if the same number was stored under variants.
      if (incoming['role'] == UserRole.systemAdmin ||
          (incoming['role'] == UserRole.residenceAdmin &&
              existing['role'] != UserRole.systemAdmin)) {
        existing['role'] = incoming['role'];
      }
      if (existing['name'] == null && incoming['name'] != null) {
        existing['name'] = incoming['name'];
      }
    }
  }

  void _seedLeads() {
    final p1 = projects[0];
    final firstUnit =
        (p1['buildings'] as List).cast<Map>().first['units'] as List;
    final unit = firstUnit.cast<Map>().first;
    leads.addAll([
      _lead(
        project: p1,
        unit: unit,
        intent: 'viewing',
        status: 'scheduled',
        contactPhone: '+998 90 123 45 67',
        message: 'Prefer a weekend viewing.',
        preferredAt: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _lead(
        project: projects[1],
        unit: null,
        intent: 'callback',
        status: 'contacted',
        contactPhone: '+998 90 123 45 67',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      _lead(
        project: projects[12],
        unit: null,
        intent: 'rent',
        status: 'won',
        contactPhone: '+998 90 123 45 67',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ]);
  }

  Map<String, dynamic> _lead({
    required Map project,
    Map? unit,
    required String intent,
    required String status,
    required String contactPhone,
    String? message,
    DateTime? preferredAt,
    required DateTime createdAt,
  }) {
    _leadSeq += _rand.nextInt(12) + 1;
    return {
      'id': 'lead-${_leadSeq}',
      'number': 'LD-$_leadSeq',
      'projectId': project['id'],
      'projectName': project['name'],
      'unitId': unit?['id'],
      'unitLabel': unit == null
          ? null
          : '${_unitKindLabel(unit)} ${unit['number']}',
      'intent': intent,
      'status': status,
      'contactPhone': contactPhone,
      'message': message,
      'preferredAt': preferredAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String _unitKindLabel(Map unit) => switch (unit['kind']) {
    'office' => 'Office',
    'retail' => 'Retail unit',
    _ => 'Apartment',
  };

  Map<String, dynamic>? projectById(String id) {
    for (final p in projects) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  ({
    Map<String, dynamic> project,
    Map<String, dynamic> building,
    Map<String, dynamic> unit,
  })?
  unitById(String id) {
    for (final p in projects) {
      for (final b in (p['buildings'] as List).cast<Map<String, dynamic>>()) {
        for (final u in (b['units'] as List).cast<Map<String, dynamic>>()) {
          if (u['id'] == id) return (project: p, building: b, unit: u);
        }
      }
    }
    return null;
  }

  static bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return fallback;
  }

  /// Catalogue-facing developer snapshot embedded on projects (no KYC fields).
  Map<String, dynamic> _catalogueDeveloperSnapshot(
    Map<String, dynamic> developer,
  ) =>
      Map<String, dynamic>.from(developer)
        ..remove('verificationStatus')
        ..remove('rejectionReason')
        ..remove('ownerUserId')
        ..remove('legalName')
        ..remove('inn')
        ..remove('website')
        ..remove('createdAt')
        ..remove('directorPinfl')
        ..remove('directorPassport')
        ..remove('uboDeclared')
        ..remove('uboFullName')
        ..remove('registrationNumber')
        ..remove('okedCode')
        ..remove('legalForm')
        ..remove('accountKind')
        ..remove('constructionLicense')
        ..remove('profileComplete');

  /// Refreshes the embedded `developer` block from the live registry so list
  /// endpoints never return a stale or partial snapshot (e.g. after PG reload
  /// or developer profile updates).
  void _refreshProjectDeveloper(Map<String, dynamic> project) {
    final embedded = project['developer'];
    final devId = embedded is Map ? embedded['id'] as String? : null;
    if (devId == null) return;
    final fresh = developerById(devId);
    if (fresh != null) {
      project['developer'] = _catalogueDeveloperSnapshot(fresh);
    }
  }

  void _hydrateAllProjectDevelopers() {
    for (final project in projects) {
      _refreshProjectDeveloper(project);
    }
  }

  void _refreshProjectsForDeveloper(String developerId) {
    for (final project in projects) {
      final dev = project['developer'] as Map?;
      if (dev?['id'] == developerId) {
        _refreshProjectDeveloper(project);
      }
    }
  }

  /// A shallow copy of [project] without the heavy `buildings` list, used
  /// for the list/search endpoint payload.
  Map<String, dynamic> summarize(Map<String, dynamic> project) {
    final copy = Map<String, dynamic>.from(project);
    copy.remove('buildings');
    _refreshProjectDeveloper(copy);
    return copy;
  }

  Map<String, dynamic> createLead(
    Map<String, dynamic> input, {
    String? userId,
  }) {
    final project = projectById(input['projectId'] as String? ?? '');
    Map<String, dynamic>? unit;
    if (input['unitId'] != null) {
      unit = unitById(input['unitId'] as String)?.unit;
    }
    _leadSeq += 1;
    final lead = {
      'id': 'lead-${DateTime.now().millisecondsSinceEpoch}',
      'number': 'LD-$_leadSeq',
      'projectId': input['projectId'],
      'projectName': project?['name'] ?? input['projectId'],
      'unitId': input['unitId'],
      'unitLabel': unit == null
          ? null
          : '${_unitKindLabel(unit)} ${unit['number']}',
      'intent': input['intent'],
      'status': 'new',
      'contactPhone': input['contactPhone'],
      'message': sanitizeText(input['message'] as String?),
      'preferredAt': input['preferredAt'],
      'userId': userId,
      'ownerUserId': null,
      'assignedManager': null,
      'notes': null,
      'createdAt': DateTime.now().toIso8601String(),
    };
    leads.insert(0, lead);
    _broadcast('leadCreated', lead, adminOnly: true);
    final persistence = _persistence;
    if (persistence != null) {
      unawaited(
        persistence.saveLead(lead).catchError((error) {
          stderr.writeln(
            '[Store] Failed to persist new lead ${lead['id']}: $error',
          );
        }),
      );
    }
    return lead;
  }

  Map<String, dynamic>? leadById(String id) {
    for (final lead in leads) {
      if (lead['id'] == id) return lead;
    }
    return null;
  }

  List<Map<String, dynamic>> leadsForUser(String userId) =>
      leads.where((l) => l['userId'] == userId).toList();

  List<Map<String, dynamic>> leadsForProject(String projectId) =>
      leads.where((l) => l['projectId'] == projectId).toList();

  /// CRM assignee candidates: active system/residence admins (not banned).
  List<Map<String, dynamic>> crmAssignees() {
    return allUsers()
        .where((u) {
          final role = u['role'] as String? ?? '';
          final banned = u['banned'] == true;
          return !banned &&
              (role == UserRole.systemAdmin || role == UserRole.residenceAdmin);
        })
        .map(
          (u) => {
            'id': u['id'],
            'name': u['name'],
            'phone': u['phone'],
            'role': u['role'],
            'displayLabel': _managerDisplayLabel(u),
          },
        )
        .toList()
      ..sort(
        (a, b) => (a['displayLabel'] as String).compareTo(
          b['displayLabel'] as String,
        ),
      );
  }

  String _managerDisplayLabel(Map<String, dynamic> user) {
    final name = (user['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user['phone'] as String? ?? user['id'] as String;
  }

  List<Map<String, dynamic>> filterLeadsByOwner(
    List<Map<String, dynamic>> source, {
    String? ownerFilter,
    String? currentUserId,
  }) {
    final filter = ownerFilter?.trim();
    if (filter == null || filter.isEmpty || filter == 'all') return source;
    if (filter == 'me') {
      if (currentUserId == null) return const [];
      return source
          .where((l) => l['ownerUserId'] == currentUserId)
          .toList();
    }
    if (filter == 'unassigned') {
      return source.where((l) => l['ownerUserId'] == null).toList();
    }
    return source.where((l) => l['ownerUserId'] == filter).toList();
  }

  List<Map<String, dynamic>> leadEventsForLead(String leadId) {
    final items = leadEvents.where((e) => e['leadId'] == leadId).toList();
    items.sort(
      (a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String),
    );
    return items;
  }

  Future<List<Map<String, dynamic>>> fetchLeadEvents(String leadId) async {
    final persistence = _persistence;
    if (persistence != null) {
      return persistence.loadLeadEvents(leadId);
    }
    return leadEventsForLead(leadId);
  }

  void _appendLeadEvent(Map<String, dynamic> event) {
    leadEvents.insert(0, event);
    final persistence = _persistence;
    if (persistence != null) {
      unawaited(
        persistence.saveLeadEvent(event).catchError((Object error) {
          stderr.writeln('[Store] Failed to persist lead event: $error');
        }),
      );
    }
  }

  Future<Map<String, dynamic>?> setLeadOwner(
    String leadId, {
    required String? ownerUserId,
    required String actorUserId,
    String? transferNote,
    bool asTransfer = false,
  }) async {
    final lead = leadById(leadId);
    if (lead == null) return null;

    final previousOwner = lead['ownerUserId'] as String?;
    if (ownerUserId == previousOwner) return lead;

    if (ownerUserId != null && _userById(ownerUserId) == null) {
      throw StateError('USER_NOT_FOUND');
    }

    lead['ownerUserId'] = ownerUserId;
    if (ownerUserId == null) {
      lead['assignedManager'] = null;
    } else {
      lead['assignedManager'] = _managerDisplayLabel(_userById(ownerUserId)!);
    }
    lead['lastContactAt'] = DateTime.now().toIso8601String();

    final eventType = ownerUserId == null
        ? 'unassigned'
        : (asTransfer && previousOwner != null
              ? 'transferred'
              : 'assigned');

    _appendLeadEvent({
      'id': 'lev-${_uuid.v4()}',
      'leadId': leadId,
      'actorUserId': actorUserId,
      'type': eventType,
      'fromUserId': previousOwner,
      'toUserId': ownerUserId,
      'detail': transferNote,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await _persistLead(lead);

    _broadcast('leadOwnerChanged', {
      'leadId': leadId,
      'projectId': lead['projectId'],
      'ownerUserId': ownerUserId,
      'assignedManager': lead['assignedManager'],
    }, adminOnly: true);

    return lead;
  }

  Future<Map<String, dynamic>?> transferLead(
    String leadId, {
    required String toUserId,
    required String actorUserId,
    String? note,
  }) => setLeadOwner(
    leadId,
    ownerUserId: toUserId,
    actorUserId: actorUserId,
    transferNote: note,
    asTransfer: true,
  );

  Future<void> _persistLead(Map<String, dynamic> lead) async {
    final persistence = _persistence;
    if (persistence != null) {
      await persistence.saveLead(lead);
    }
  }

  /// Public catalogue: only published + approved projects.
  ///
  /// Recomputes [priceMin]/[priceMax]/[rentMin]/[rentMax] from units before
  /// returning — B2B `addUnit` historically left those null, and B2C
  /// `GET /v1/projects?mode=buy` drops any project without sale prices.
  List<Map<String, dynamic>> get publishedProjects {
    final list = <Map<String, dynamic>>[];
    for (final p in projects) {
      if (_asBool(p['isPublished'], fallback: false) &&
          (p['moderationStatus'] as String? ?? 'approved') == 'approved') {
        _recomputeProjectPricing(p);
        list.add(p);
      }
    }
    return list;
  }

  /// Derives project-level sale/rent price bounds from nested building units.
  void _recomputeProjectPricing(Map<String, dynamic> project) {
    final buildings = project['buildings'];
    if (buildings is! List) {
      project['priceMin'] = null;
      project['priceMax'] = null;
      project['rentMin'] = null;
      project['rentMax'] = null;
      return;
    }
    final allUnits = <Map>[
      for (final b in buildings.cast<Map>())
        ...(b['units'] as List? ?? const []).cast<Map>(),
    ];
    final saleUnits = allUnits.where((u) => u['dealType'] == 'sale');
    final rentUnits = allUnits.where((u) => u['dealType'] == 'rent');

    double? minOf(Iterable<Map> units, String key) {
      final vals = <double>[];
      for (final u in units) {
        final raw = u[key];
        if (raw is num) vals.add(raw.toDouble());
      }
      if (vals.isEmpty) return null;
      return vals.reduce((a, b) => a < b ? a : b);
    }

    double? maxOf(Iterable<Map> units, String key) {
      final vals = <double>[];
      for (final u in units) {
        final raw = u[key];
        if (raw is num) vals.add(raw.toDouble());
      }
      if (vals.isEmpty) return null;
      return vals.reduce((a, b) => a > b ? a : b);
    }

    project['priceMin'] = minOf(saleUnits, 'price');
    project['priceMax'] = maxOf(saleUnits, 'price');
    project['rentMin'] = minOf(rentUnits, 'rentMonthly');
    project['rentMax'] = maxOf(rentUnits, 'rentMonthly');
  }

  /// Mutates the `status` of lead [id] and broadcasts `leadStatusChanged`.
  /// Returns the updated lead, or `null` if no lead with that id exists.
  Map<String, dynamic>? updateLeadStatus(String id, String status) {
    for (final lead in leads) {
      if (lead['id'] == id) {
        lead['status'] = status;
        _broadcast('leadStatusChanged', {
          'leadId': lead['id'],
          'projectId': lead['projectId'],
          'status': status,
        }, adminOnly: true);
        final persistence = _persistence;
        if (persistence != null) {
          unawaited(
            persistence.updateLeadStatus(id, status).catchError((error) {
              stderr.writeln(
                '[Store] Failed to persist lead status for $id: $error',
              );
            }),
          );
        }
        return lead;
      }
    }
    return null;
  }

  // --- Phone-OTP auth ----------------------------------------------------

  /// Creates a pending OTP request for [phone] and returns its `requestId`.
  /// Sends SMS via [SmsService] (Eskiz when configured; otherwise logs the
  /// fixed [kDevOtpCode]).
  Future<String> createOtpRequest(String phone) async {
    final normalized = normalizePhone(phone);
    _otpRequests.removeWhere((_, r) => r.phone == normalized);
    final requestId = _uuid.v4();
    // The fixed dev code is a convenience for local dev/tests only. In
    // production it is never used: OTPs are always generated with a
    // cryptographically-secure RNG (and the server refuses to start without
    // Eskiz creds, so `isDevMode` is false there anyway).
    final code = (sms.isDevMode && !isProduction)
        ? kDevOtpCode
        : (100000 + _secureRand.nextInt(900000)).toString();
    _otpRequests[requestId] = _OtpRequest(normalized, code);
    await sms.sendOtp(phone: normalized, code: code);
    return requestId;
  }

  /// Whether the fixed dev OTP is currently in effect (only true outside
  /// production when Eskiz is not configured). Route layer uses this to
  /// decide whether a debug hint may be surfaced.
  bool get devOtpEnabled => sms.isDevMode && !isProduction;

  /// Resolves a Bearer access token to the user record, or null. Expired
  /// sessions are rejected (and evicted) so a stale/leaked token can't be
  /// replayed after its TTL.
  Map<String, dynamic>? userForAccessToken(String accessToken) {
    final session = _sessionsByToken[accessToken];
    if (session == null) return null;
    if (session.isExpired) {
      revokeAccessToken(accessToken);
      return null;
    }
    return _usersByPhone[session.phone];
  }

  void revokeAccessToken(String accessToken) {
    _sessionsByToken.remove(accessToken);
    final persistence = _persistence;
    if (persistence != null) {
      unawaited(
        persistence.deleteSessionByAccessToken(accessToken).catchError((
          Object error,
        ) {
          stderr.writeln('[Store] Failed to delete session: $error');
        }),
      );
    }
  }

  /// Rotates tokens given a valid, unexpired refresh token. The old refresh
  /// token is consumed (single-use rotation) and a fresh access+refresh pair
  /// with new TTLs is issued.
  ({String accessToken, String refreshToken, Map<String, dynamic> user})?
  refreshSession(String refreshToken) {
    final session = _refreshTokens.remove(refreshToken);
    if (session == null) return null;
    if (session.isExpired) {
      final persistence = _persistence;
      if (persistence != null) {
        unawaited(
          persistence.deleteSessionByRefreshToken(refreshToken).catchError((
            Object _,
          ) {}),
        );
      }
      return null;
    }
    final phone = session.phone;
    final user = _usersByPhone[phone];
    if (user == null) return null;
    final now = DateTime.now();
    final accessExpiry = now.add(_accessTokenTtl);
    final refreshExpiry = now.add(_refreshTokenTtl);
    final accessToken = _uuid.v4();
    final newRefresh = _uuid.v4();
    _sessionsByToken[accessToken] = _Session(phone, accessExpiry);
    _refreshTokens[newRefresh] = _Session(phone, refreshExpiry);
    final persistence = _persistence;
    if (persistence != null) {
      unawaited(
        persistence
            .deleteSessionByRefreshToken(refreshToken)
            .then(
              (_) => persistence.saveSession(
                accessToken: accessToken,
                refreshToken: newRefresh,
                phone: phone,
                expiresAt: accessExpiry,
                refreshExpiresAt: refreshExpiry,
              ),
            )
            .catchError((Object error) {
              stderr.writeln(
                '[Store] Failed to persist refresh session: $error',
              );
            }),
      );
    }
    return (accessToken: accessToken, refreshToken: newRefresh, user: user);
  }

  Map<String, dynamic> ensureUser({
    required String phone,
    String role = UserRole.ordinaryUser,
    String? name,
  }) {
    final normalized = normalizePhone(phone);
    final existing = _usersByPhone[normalized];
    if (existing != null) {
      existing['role'] = role;
      existing['phone'] = normalized;
      if (name != null) existing['name'] = name;
      _persistUser(existing);
      return existing;
    }
    final user = {
      'id': 'user-${_uuid.v4()}',
      'phone': normalized,
      'name': name,
      'role': role,
    };
    _usersByPhone[normalized] = user;
    _persistUser(user);
    return user;
  }

  void _persistUser(Map<String, dynamic> user) {
    _persist('user', (p) => p.upsertUser(user));
  }

  /// Fire-and-forget write-through: runs [op] against the persistence layer
  /// (when attached), logging — never throwing — on failure, so the
  /// in-memory mutation that already happened stays authoritative for the
  /// current process either way.
  void _persist(String what, Future<void> Function(PgPersistence p) op) {
    final persistence = _persistence;
    if (persistence == null) return;
    unawaited(
      op(persistence).catchError((Object error) {
        stderr.writeln('[Store] Failed to persist $what: $error');
      }),
    );
  }

  void _assertPersistenceForWrite(String action) {
    if (_persistenceRequired && _persistence == null) {
      throw StateError(
        'PostgreSQL is configured (server/.env DB_HOST) but the API is running '
        'in-memory only — $action was not saved to the database. Restart the '
        'API after PostgreSQL is ready (see scripts/launch-stack.ps1).',
      );
    }
  }

  void _persistProject(String what, Map<String, dynamic> project) {
    final id = project['id'] as String?;
    if (id != null && _deletedProjectIds.contains(id)) return;
    _persist(what, (p) => p.saveProject(project));
  }

  void _clearSeedCatalogueOnPersistenceFailure() {
    stderr.writeln(
      '[Store] Clearing in-memory seed catalogue because PostgreSQL is '
      'configured but unavailable — the admin UI will not mirror database '
      'rows until the connection succeeds.',
    );
    projects.clear();
    leads.clear();
    reviews.clear();
    rentalListings.clear();
    documents.clear();
    photoReports.clear();
    notifications.clear();
    developersRegistry.removeWhere((d) => d['ownerUserId'] == null);
  }

  /// Verifies [code] for [requestId]; on success, creates the user on first
  /// sign-in (keyed by phone) and mints a fresh opaque token pair.
  ///
  /// Wrong codes are counted per `requestId`; after [kMaxOtpAttempts] the
  /// request is invalidated so the ~1M-code space can't be brute-forced. The
  /// code comparison is constant-time to avoid a timing side-channel.
  OtpVerifyResult verifyOtp({
    required String requestId,
    required String code,
  }) {
    final request = _otpRequests[requestId];
    if (request == null) {
      return OtpVerifyResult.failure(OtpVerifyError.notFound);
    }
    if (request.isExpired) {
      _otpRequests.remove(requestId);
      return OtpVerifyResult.failure(OtpVerifyError.notFound);
    }
    if (!constantTimeEquals(code, request.code)) {
      request.attempts += 1;
      if (request.attempts >= kMaxOtpAttempts) {
        _otpRequests.remove(requestId);
        return OtpVerifyResult.failure(OtpVerifyError.tooManyAttempts);
      }
      return OtpVerifyResult.failure(OtpVerifyError.invalidCode);
    }

    _otpRequests.remove(requestId);
    final phone = normalizePhone(request.phone);
    final isPlatformAdmin = _systemAdminPhones.contains(phone);
    final user = _usersByPhone.putIfAbsent(
      phone,
      () => {
        'id': 'user-${_uuid.v4()}',
        'phone': phone,
        'name': null,
        'role': isPlatformAdmin ? UserRole.systemAdmin : UserRole.ordinaryUser,
      },
    );
    if (isPlatformAdmin && user['role'] != UserRole.systemAdmin) {
      user['role'] = UserRole.systemAdmin;
    }
    user['phone'] = phone;

    final now = DateTime.now();
    final accessExpiry = now.add(_accessTokenTtl);
    final refreshExpiry = now.add(_refreshTokenTtl);
    final accessToken = _uuid.v4();
    final refreshToken = _uuid.v4();
    _sessionsByToken[accessToken] = _Session(phone, accessExpiry);
    _refreshTokens[refreshToken] = _Session(phone, refreshExpiry);

    final persistence = _persistence;
    if (persistence != null) {
      unawaited(
        persistence
            .upsertUser(user)
            .then(
              (_) => persistence.saveSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                phone: phone,
                expiresAt: accessExpiry,
                refreshExpiresAt: refreshExpiry,
              ),
            )
            .catchError((Object error, StackTrace stack) {
              stderr.writeln(
                '[Store] Failed to persist auth session for $phone: '
                '$error\n$stack',
              );
            }),
      );
    }

    return OtpVerifyResult.success(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  // --- Favorites / saved searches ----------------------------------------

  List<String> favoritesForUser(String userId) =>
      (favoritesByUser[userId] ?? {}).toList();

  void addFavorite(String userId, String projectId) {
    (favoritesByUser[userId] ??= {}).add(projectId);
    _persist('favorite', (p) => p.saveFavorite(userId, projectId));
  }

  void removeFavorite(String userId, String projectId) {
    favoritesByUser[userId]?.remove(projectId);
    _persist('favorite removal', (p) => p.deleteFavorite(userId, projectId));
  }

  List<Map<String, dynamic>> savedSearchesForUser(String userId) =>
      List.of(savedSearchesByUser[userId] ?? const []);

  Map<String, dynamic> createSavedSearch({
    required String userId,
    required String label,
    required Map<String, dynamic> filters,
    bool notifyOnMatch = false,
  }) {
    final search = {
      'id': 'ss-${_uuid.v4()}',
      'label': sanitizeText(label),
      'filters': filters,
      'notifyOnMatch': notifyOnMatch,
      'createdAt': DateTime.now().toIso8601String(),
    };
    (savedSearchesByUser[userId] ??= []).insert(0, search);
    _persist('saved search', (p) => p.saveSavedSearch(userId, search));
    return search;
  }

  void deleteSavedSearch(String userId, String id) {
    savedSearchesByUser[userId]?.removeWhere((s) => s['id'] == id);
    _persist('saved search removal', (p) => p.deleteSavedSearch(userId, id));
  }

  // --- Reviews (Konseptsiya §9 trust layer) -------------------------------

  List<Map<String, dynamic>> reviewsForProject(String projectId) => reviews
      .where((r) => r['projectId'] == projectId && r['status'] == 'published')
      .toList();

  List<Map<String, dynamic>> reviewsForModeration() =>
      reviews.where((r) => r['status'] == 'flagged').toList();

  Map<String, dynamic> createReview({
    required String userId,
    required String userName,
    required String projectId,
    int ratingOverall = 5,
    int? ratingLocation,
    int? ratingQuality,
    int? ratingValue,
    required String body,
  }) {
    final project = projectById(projectId);
    final review = {
      'id': 'rev-${_uuid.v4()}',
      'userId': userId,
      'userName': sanitizeText(userName),
      'projectId': projectId,
      'developerId': (project?['developer'] as Map?)?['id'],
      'ratingOverall': ratingOverall.clamp(1, 5),
      'ratingLocation': ratingLocation?.clamp(1, 5),
      'ratingQuality': ratingQuality?.clamp(1, 5),
      'ratingValue': ratingValue?.clamp(1, 5),
      'body': sanitizeText(body),
      'status': 'published',
      'createdAt': DateTime.now().toIso8601String(),
    };
    reviews.insert(0, review);
    _recomputeProjectRating(projectId);
    _persist('review', (p) => p.saveReview(review));
    if (project != null) {
      // Recomputed rating lives on the project row.
      _persistProject('project rating', project);
    }
    return review;
  }

  void _recomputeProjectRating(String projectId) {
    final project = projectById(projectId);
    if (project == null) return;
    final published = reviewsForProject(projectId);
    if (published.isEmpty) return;
    final avg =
        published
            .map((r) => (r['ratingOverall'] as num).toDouble())
            .reduce((a, b) => a + b) /
        published.length;
    project['rating'] = double.parse(avg.toStringAsFixed(2));
  }

  Map<String, dynamic>? moderateReview(String id, {required bool remove}) {
    for (final review in reviews) {
      if (review['id'] == id) {
        review['status'] = remove ? 'removed' : 'published';
        _persist('review moderation', (p) => p.saveReview(review));
        return review;
      }
    }
    return null;
  }

  Map<String, dynamic>? flagReview(String id) {
    for (final review in reviews) {
      if (review['id'] == id) {
        review['status'] = 'flagged';
        _persist('review flag', (p) => p.saveReview(review));
        return review;
      }
    }
    return null;
  }

  // --- Support tickets (any user -> platform admin triage) ---------------
  //
  // Deliberately not scoped to a project/developer: a buyer, renter,
  // residence admin, or developer can all open one (billing question,
  // moderation appeal, bug report, ...), and only a system admin triages
  // the whole inbox from the B2B "Тикеты" section.
  final List<Map<String, dynamic>> tickets = [];

  static const kTicketCategories = {
    'billing',
    'moderation',
    'technical',
    'other',
  };
  static const kTicketStatuses = {'open', 'in_progress', 'resolved', 'closed'};

  Map<String, dynamic> createTicket({
    required String userId,
    String? userName,
    String? userPhone,
    required String subject,
    required String message,
    String category = 'other',
  }) {
    final now = DateTime.now().toIso8601String();
    final ticket = {
      'id': 'tkt-${_uuid.v4()}',
      'userId': userId,
      'userName': sanitizeText(userName),
      'userPhone': userPhone,
      'subject': sanitizeText(subject) ?? '',
      'category': kTicketCategories.contains(category) ? category : 'other',
      'status': 'open',
      'assignedToName': null,
      'replies': <Map<String, dynamic>>[
        {
          'authorName': sanitizeText(userName) ?? userPhone ?? 'User',
          'isAdmin': false,
          'message': sanitizeText(message) ?? '',
          'createdAt': now,
        },
      ],
      'createdAt': now,
      'updatedAt': now,
    };
    tickets.insert(0, ticket);
    _persist('ticket', (p) => p.saveTicket(ticket));
    return ticket;
  }

  Map<String, dynamic>? ticketById(String id) {
    for (final ticket in tickets) {
      if (ticket['id'] == id) return ticket;
    }
    return null;
  }

  List<Map<String, dynamic>> ticketsForUser(String userId) =>
      tickets.where((t) => t['userId'] == userId).toList();

  List<Map<String, dynamic>> allTickets({String? status}) => tickets
      .where((t) => status == null || t['status'] == status)
      .toList();

  /// Appends one message to the ticket thread — from either the ticket
  /// owner (`isAdmin: false`) or a platform admin (`isAdmin: true`, who may
  /// also move [status] forward in the same call).
  Map<String, dynamic>? addTicketReply(
    String id, {
    required String message,
    required String authorName,
    required bool isAdmin,
    String? status,
  }) {
    final ticket = ticketById(id);
    if (ticket == null) return null;
    final replies = ticket['replies'] as List;
    replies.add(<String, dynamic>{
      'authorName': sanitizeText(authorName) ?? (isAdmin ? 'Admin' : 'User'),
      'isAdmin': isAdmin,
      'message': sanitizeText(message) ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (status != null && kTicketStatuses.contains(status)) {
      ticket['status'] = status;
    } else if (isAdmin && ticket['status'] == 'open') {
      ticket['status'] = 'in_progress';
    }
    ticket['updatedAt'] = DateTime.now().toIso8601String();
    _persist('ticket reply', (p) => p.saveTicket(ticket));
    return ticket;
  }

  Map<String, dynamic>? updateTicket(
    String id, {
    String? status,
    String? assignedToName,
  }) {
    final ticket = ticketById(id);
    if (ticket == null) return null;
    if (status != null && kTicketStatuses.contains(status)) {
      ticket['status'] = status;
    }
    if (assignedToName != null) {
      ticket['assignedToName'] = sanitizeText(assignedToName);
    }
    ticket['updatedAt'] = DateTime.now().toIso8601String();
    _persist('ticket update', (p) => p.saveTicket(ticket));
    return ticket;
  }

  // --- Owner secondary/primary rental listings (Konseptsiya §5, §8) ------
  //
  // Deliberately a *separate*, lighter-weight collection from
  // `projects`/`units`: an owner submitting a rental listing never gets a
  // full developer dashboard, and — critically — this collection is never
  // exposed for `dealType: sale`, enforcing the platform-wide rule that
  // secondary housing may only ever be rented, never bought/sold here.
  List<Map<String, dynamic>> approvedRentalListings({
    String? district,
    String? propertyKind,
    double? priceMax,
    int? roomsMin,
  }) {
    var items = rentalListings
        .where((l) => l['moderationStatus'] == 'approved')
        .toList();
    if (district != null && district.isNotEmpty) {
      items = items
          .where(
            (l) =>
                (l['district'] as String).toLowerCase() ==
                district.toLowerCase(),
          )
          .toList();
    }
    if (propertyKind != null && propertyKind.isNotEmpty) {
      items = items.where((l) => l['propertyKind'] == propertyKind).toList();
    }
    if (priceMax != null) {
      items = items
          .where((l) => (l['rentMonthly'] as num? ?? 0) <= priceMax)
          .toList();
    }
    if (roomsMin != null) {
      items = items
          .where((l) => (l['rooms'] as int? ?? 0) >= roomsMin)
          .toList();
    }
    return items;
  }

  Map<String, dynamic>? rentalListingById(String id) {
    for (final l in rentalListings) {
      if (l['id'] == id) return l;
    }
    return null;
  }

  List<Map<String, dynamic>> rentalListingsForOwner(String ownerUserId) =>
      rentalListings.where((l) => l['ownerUserId'] == ownerUserId).toList();

  List<Map<String, dynamic>> pendingRentalListings() =>
      rentalListings.where((l) => l['moderationStatus'] == 'pending').toList();

  Map<String, dynamic> createRentalListing({
    required String ownerUserId,
    required String title,
    required String description,
    required String district,
    required String address,
    double? lat,
    double? lng,
    required String propertyKind, // apartment | office | retail
    required double areaTotal,
    int? rooms,
    required double rentMonthly,
    int minLeaseMonths = 12,
    required String contactPhone,
    List<String> photoUrls = const [],
    bool isSecondary = true,
  }) {
    final listing = {
      'id': 'rl-${_uuid.v4()}',
      'ownerUserId': ownerUserId,
      'title': sanitizeText(title),
      'description': sanitizeText(description),
      'district': sanitizeText(district),
      'address': sanitizeText(address),
      'lat': lat,
      'lng': lng,
      'propertyKind': propertyKind,
      'dealType': 'rent', // enforced — never 'sale'
      'areaTotal': areaTotal,
      'rooms': rooms,
      'rentMonthly': rentMonthly,
      'minLeaseMonths': minLeaseMonths,
      'contactPhone': contactPhone,
      'photos': photoUrls,
      'isSecondary': isSecondary,
      'moderationStatus': 'pending',
      'moderationNote': null,
      'isFeatured': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    rentalListings.insert(0, listing);
    _persist('rental listing', (p) => p.saveRentalListing(listing));
    return listing;
  }

  Map<String, dynamic>? moderateRentalListing(
    String id, {
    required bool approve,
    String? note,
  }) {
    final listing = rentalListingById(id);
    if (listing == null) return null;
    listing['moderationStatus'] = approve ? 'approved' : 'rejected';
    listing['moderationNote'] = sanitizeText(note);
    _persist('rental listing moderation', (p) => p.saveRentalListing(listing));
    return listing;
  }

  // --- Developers / projects admin ---------------------------------------

  bool innTaken(String inn, {String? exceptDeveloperId}) {
    final normalized = normalizeInn(inn);
    if (normalized == null) return false;
    for (final d in developersRegistry) {
      if (exceptDeveloperId != null && d['id'] == exceptDeveloperId) continue;
      if (normalizeInn(d['inn'] as String?) == normalized) return true;
    }
    return false;
  }

  void _persistDeveloper(Map<String, dynamic> developer) {
    final persistence = _persistence;
    if (persistence == null) return;
    unawaited(
      persistence.upsertDeveloper(developer).catchError((Object error) {
        stderr.writeln('[Store] Failed to persist developer: $error');
      }),
    );
  }

  void _persistSubscription(Map<String, dynamic> subscription) {
    final persistence = _persistence;
    if (persistence == null) return;
    unawaited(
      persistence.upsertSubscription(subscription).catchError((Object error) {
        stderr.writeln('[Store] Failed to persist subscription: $error');
      }),
    );
  }

  Map<String, dynamic>? subscriptionForDeveloper(String developerId) =>
      subscriptionsByDeveloperId[developerId];

  bool hasActiveSubscription(String developerId) {
    final sub = subscriptionsByDeveloperId[developerId];
    if (sub == null) return false;
    if (sub['status'] != 'active') return false;
    final end = sub['currentPeriodEnd'] as String?;
    if (end == null) return true;
    final endAt = DateTime.tryParse(end);
    if (endAt == null) return true;
    return !DateTime.now().toUtc().isAfter(endAt.toUtc());
  }

  String paymentStatusForDeveloper(String developerId) {
    final sub = subscriptionsByDeveloperId[developerId];
    if (sub == null) return 'none';
    if (sub['status'] == 'active' && !hasActiveSubscription(developerId)) {
      return 'past_due';
    }
    return sub['status'] as String? ?? 'none';
  }

  Map<String, dynamic> registerDeveloper({
    required String ownerUserId,
    required String name,
    required String legalName,
    required String inn,
    required String phone,
    required String accountKind,
    required String legalForm,
    required String legalAddress,
    required String directorFullName,
    required String directorPinfl,
    required bool uboDeclared,
    String? registrationNumber,
    String? officeAddress,
    String? region,
    String? email,
    String? website,
    String? okedCode,
    String? directorPassport,
    String? directorPhone,
    String? directorEmail,
    String? uboFullName,
    String? constructionLicense,
  }) {
    final existing = developerForOwner(ownerUserId);
    if (existing != null) {
      final existingStatus = existing['verificationStatus'] as String?;
      if (existingStatus != 'rejected' && existingStatus != 'draft') {
        throw StateError('APPLICATION_EXISTS');
      }
    }
    final normalizedInn = normalizeInn(inn)!;
    if (innTaken(
      normalizedInn,
      exceptDeveloperId: existing?['id'] as String?,
    )) {
      throw StateError('INN_TAKEN');
    }
    final developer = {
      'id': (existing?['id'] as String?) ?? 'dev-${_uuid.v4()}',
      'name': sanitizeText(name),
      'legalName': sanitizeText(legalName),
      'inn': normalizedInn,
      'logoUrl': existing?['logoUrl'],
      'rating': (existing?['rating'] as num?)?.toDouble() ?? 0.0,
      'projectsCount': existing?['projectsCount'] as int? ?? 0,
      'phone': phone,
      'agentName': sanitizeText(directorFullName),
      'agentPhone': directorPhone ?? phone,
      'agentAvatarUrl': null,
      'website': sanitizeText(website),
      'verificationStatus': 'draft',
      'rejectionReason': null,
      'ownerUserId': ownerUserId,
      'createdAt': DateTime.now().toIso8601String(),
      'accountKind': accountKind,
      'legalForm': sanitizeText(legalForm),
      'registrationNumber': sanitizeText(registrationNumber),
      'okedCode': okedCode,
      'legalAddress': sanitizeText(legalAddress),
      'officeAddress': sanitizeText(officeAddress),
      'region': sanitizeText(region),
      'email': sanitizeText(email),
      'description': null,
      'brandColor': null,
      'coverImageUrl': null,
      'directorFullName': sanitizeText(directorFullName),
      'directorPinfl': normalizePinfl(directorPinfl),
      'directorPassport': directorPassport,
      'directorPhone': directorPhone ?? phone,
      'directorEmail': sanitizeText(directorEmail),
      'uboDeclared': uboDeclared,
      'uboFullName': sanitizeText(uboFullName),
      'constructionLicense': sanitizeText(constructionLicense),
      'profileComplete': false,
    };
    if (existing != null) {
      developersRegistry.remove(existing);
    }
    developersRegistry.add(developer);
    _persistDeveloper(developer);
    _refreshProjectsForDeveloper(developer['id'] as String);
    final subscription = _blankSubscription(
      developer['id'] as String,
      kBusinessSubscriptionPlanId,
    );
    subscriptionsByDeveloperId[developer['id'] as String] = subscription;
    _persistSubscription(subscription);
    return developer;
  }

  /// Moves a saved developer application from `draft` or `rejected` into the
  /// platform review queue (`pending`).
  Map<String, dynamic>? submitDeveloperForReview(String ownerUserId) {
    final developer = developerForOwner(ownerUserId);
    if (developer == null) return null;
    final status = developer['verificationStatus'] as String? ?? 'draft';
    if (status != 'draft' && status != 'rejected') {
      throw StateError('INVALID_STATE');
    }
    developer['verificationStatus'] = 'pending';
    developer['rejectionReason'] = null;
    _persistDeveloper(developer);
    return developer;
  }

  /// Moves a ЖК/project from `draft` or `rejected` into the moderation queue.
  Map<String, dynamic>? submitProjectForReview(String projectId) {
    final project = projectById(projectId);
    if (project == null) return null;
    final status = project['moderationStatus'] as String? ?? 'approved';
    if (status != 'draft' && status != 'rejected') {
      throw StateError('INVALID_STATE');
    }
    project['moderationStatus'] = 'pending';
    project['isPublished'] = false;
    project['moderationNote'] = null;
    project['updatedAt'] = DateTime.now().toIso8601String();
    _persistProject('project submit for review', project);
    return project;
  }

  Map<String, dynamic> _blankSubscription(String developerId, String planId) {
    final plan =
        subscriptionPlanById(planId) ?? subscriptionPlanById('growth')!;
    return {
      'id': 'sub-${_uuid.v4()}',
      'developerId': developerId,
      'planId': plan['id'],
      'amountUsd': plan['priceUsd'],
      'currency': 'USD',
      'status': 'none',
      'provider': 'manual',
      'providerRef': null,
      'currentPeriodStart': null,
      'currentPeriodEnd': null,
      'lastPaymentAt': null,
      'leadsUsedThisPeriod': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic>? updateDeveloperProfile(
    String ownerUserId,
    Map<String, dynamic> patch,
  ) {
    final developer = developerForOwner(ownerUserId);
    if (developer == null) return null;
    if (developer['verificationStatus'] != 'approved' &&
        developer['verificationStatus'] != 'pending' &&
        developer['verificationStatus'] != 'in_review' &&
        developer['verificationStatus'] != 'draft') {
      return null;
    }
    for (final key in [
      'name',
      'legalName',
      'website',
      'logoUrl',
      'email',
      'description',
      'brandColor',
      'coverImageUrl',
      'legalAddress',
      'officeAddress',
      'region',
      'registrationNumber',
      'okedCode',
      'legalForm',
      'accountKind',
      'directorFullName',
      'directorPassport',
      'directorPhone',
      'directorEmail',
      'uboFullName',
      'constructionLicense',
      'agentName',
      'agentPhone',
      'agentAvatarUrl',
    ]) {
      if (patch.containsKey(key)) developer[key] = _clean(patch[key]);
    }
    if (patch.containsKey('directorPinfl')) {
      final pinfl = normalizePinfl(patch['directorPinfl'] as String?);
      if (pinfl != null && !isValidPinfl(pinfl)) {
        throw StateError('INVALID_PINFL');
      }
      developer['directorPinfl'] = pinfl;
    }
    if (patch.containsKey('inn')) {
      final inn = normalizeInn(patch['inn'] as String?);
      if (inn == null || !isValidInn(inn)) {
        throw StateError('INVALID_INN');
      }
      if (innTaken(inn, exceptDeveloperId: developer['id'] as String)) {
        throw StateError('INN_TAKEN');
      }
      developer['inn'] = inn;
    }
    if (patch.containsKey('uboDeclared')) {
      developer['uboDeclared'] = patch['uboDeclared'] == true;
    }
    developer['profileComplete'] = _isProfileComplete(developer);
    developer['updatedAt'] = DateTime.now().toIso8601String();
    _persistDeveloper(developer);
    return developer;
  }

  bool _isProfileComplete(Map<String, dynamic> d) {
    bool filled(String key) {
      final v = d[key];
      return v is String && v.trim().isNotEmpty;
    }

    return filled('name') &&
        filled('legalName') &&
        filled('inn') &&
        filled('legalAddress') &&
        filled('directorFullName') &&
        filled('directorPinfl') &&
        d['uboDeclared'] == true &&
        filled('description') &&
        filled('officeAddress');
  }

  /// Starts or renews a subscription tier (manual/dev checkout — Payme/Click
  /// can replace `provider` later without changing this contract). Defaults
  /// to the caller's existing plan, or `growth` for a first activation.
  Map<String, dynamic>? activateSubscription(
    String ownerUserId, {
    String? planId,
  }) {
    final developer = developerForOwner(ownerUserId);
    if (developer == null || developer['verificationStatus'] != 'approved') {
      return null;
    }
    final id = developer['id'] as String;
    final now = DateTime.now().toUtc();
    final end = now.add(const Duration(days: 30));
    final existing = subscriptionsByDeveloperId[id];
    final resolvedPlanId =
        planId ?? existing?['planId'] as String? ?? kBusinessSubscriptionPlanId;
    final plan =
        subscriptionPlanById(resolvedPlanId) ?? subscriptionPlanById('growth')!;
    final subscription = {
      'id': existing?['id'] ?? 'sub-${_uuid.v4()}',
      'developerId': id,
      'planId': plan['id'],
      'amountUsd': plan['priceUsd'],
      'currency': 'USD',
      'status': 'active',
      'provider': 'manual',
      'providerRef': 'dev-checkout-${_uuid.v4()}',
      'currentPeriodStart': now.toIso8601String(),
      'currentPeriodEnd': end.toIso8601String(),
      'lastPaymentAt': now.toIso8601String(),
      'leadsUsedThisPeriod': 0,
      'createdAt': existing?['createdAt'] ?? now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    subscriptionsByDeveloperId[id] = subscription;
    _persistSubscription(subscription);
    return subscription;
  }

  Map<String, dynamic>? developerForOwner(String ownerUserId) {
    for (final d in developersRegistry) {
      if (d['ownerUserId'] == ownerUserId) return d;
    }
    return null;
  }

  Map<String, dynamic>? developerById(String id) {
    for (final d in developersRegistry) {
      if (d['id'] == id) return d;
    }
    return null;
  }

  /// Applications still awaiting a final decision — both freshly submitted
  /// (`pending`) and those an admin has started investigating (`in_review`).
  List<Map<String, dynamic>> pendingDevelopers() => developersRegistry
      .where(
        (d) =>
            d['verificationStatus'] == 'pending' ||
            d['verificationStatus'] == 'in_review',
      )
      .toList();

  /// All owned businesses for platform billing visibility.
  List<Map<String, dynamic>> platformBusinesses() {
    return developersRegistry.where((d) => d['ownerUserId'] != null).map((d) {
      final id = d['id'] as String;
      final sub = subscriptionsByDeveloperId[id];
      return {
        ...d,
        'paymentStatus': paymentStatusForDeveloper(id),
        'subscription': sub,
        'canPublish': hasActiveSubscription(id),
      };
    }).toList();
  }

  Map<String, dynamic>? setDeveloperVerification(
    String id,
    String status, {
    String? rejectionReason,
  }) {
    final developer = developerById(id);
    if (developer == null) return null;
    developer['verificationStatus'] = status;
    developer['rejectionReason'] = sanitizeText(rejectionReason);
    if (status == 'approved') {
      final ownerId = developer['ownerUserId'] as String?;
      if (ownerId != null) {
        final user = _userById(ownerId);
        if (user != null) {
          user['role'] = UserRole.residenceAdmin;
          _persistUser(user);
        }
      }
      subscriptionsByDeveloperId.putIfAbsent(id, () {
        final sub = _blankSubscription(id, kBusinessSubscriptionPlanId);
        _persistSubscription(sub);
        return sub;
      });
    }
    _persistDeveloper(developer);
    _refreshProjectsForDeveloper(id);
    return developer;
  }

  Map<String, dynamic>? _userById(String id) {
    for (final user in _usersByPhone.values) {
      if (user['id'] == id) return user;
    }
    return null;
  }

  List<Map<String, dynamic>> allUsers() => _usersByPhone.values.toList();

  Map<String, dynamic>? setUserRole(String userId, String role) {
    final user = _userById(userId);
    if (user == null) return null;
    user['role'] = role;
    _persistUser(user);
    return user;
  }

  /// Freezes [userId]'s account: every authenticated action except reading
  /// `/v1/users/me` and signing out is rejected (see `banGuardMiddleware`)
  /// until an admin lifts the ban. [reason] and [bannedByName] are shown
  /// back on the user's own account so they know why and by whom.
  Map<String, dynamic>? banUser(
    String userId, {
    required String reason,
    required String bannedByName,
  }) {
    final user = _userById(userId);
    if (user == null) return null;
    user['banned'] = true;
    user['banReason'] = sanitizeText(reason);
    user['bannedByName'] = sanitizeText(bannedByName);
    user['bannedAt'] = DateTime.now().toIso8601String();
    _persistUser(user);
    return user;
  }

  Map<String, dynamic>? unbanUser(String userId) {
    final user = _userById(userId);
    if (user == null) return null;
    user['banned'] = false;
    user['banReason'] = null;
    user['bannedByName'] = null;
    user['bannedAt'] = null;
    _persistUser(user);
    return user;
  }

  bool ownsProject(String ownerUserId, Map project) {
    final developer = project['developer'] as Map?;
    if (developer == null) return false;
    final reg = developerById(developer['id'] as String);
    return reg != null && reg['ownerUserId'] == ownerUserId;
  }

  List<Map<String, dynamic>> projectsForDeveloperOwner(String ownerUserId) {
    final developer = developerForOwner(ownerUserId);
    if (developer == null) return const [];
    final id = developer['id'];
    return projects.where((p) {
      final d = p['developer'] as Map?;
      return d != null && d['id'] == id;
    }).toList();
  }

  Map<String, dynamic>? createProjectForOwner({
    required String ownerUserId,
    required Map<String, dynamic> input,
  }) {
    final developer = developerForOwner(ownerUserId);
    if (developer == null || developer['verificationStatus'] != 'approved') {
      return null;
    }
    final project = {
      'id': 'prj-${_uuid.v4()}',
      'name': _clean(input['name']),
      'type': input['type'] ?? 'residential_complex',
      'status': input['status'] ?? 'under_construction',
      'district': _clean(input['district']) ?? 'Yunusabad',
      'address': _clean(input['address']) ?? '',
      'lat': (input['lat'] as num?)?.toDouble() ?? 41.3111,
      'lng': (input['lng'] as num?)?.toDouble() ?? 69.2797,
      'developer': _catalogueDeveloperSnapshot(developer),
      'description': _clean(input['description']) ?? '',
      'amenities': sanitizeTextList(input['amenities']) ?? <String>[],
      'tags': sanitizeTextList(input['tags']) ?? <String>[],
      'priceMin': input['priceMin'],
      'priceMax': input['priceMax'],
      'rentMin': input['rentMin'],
      'rentMax': input['rentMax'],
      'constructionProgress': input['constructionProgress'],
      'completionDate': input['completionDate'],
      'rating': 0.0,
      'availableUnits': 0,
      'totalUnits': 0,
      'isFeatured': false,
      'isPublished': false,
      'moderationStatus': 'draft',
      'moderationNote': null,
      'gallery': <Map<String, dynamic>>[],
      'buildings': <Map<String, dynamic>>[],
      'offers': <Map<String, dynamic>>[],
    };
    projects.insert(0, project);
    developer['projectsCount'] = (developer['projectsCount'] as int? ?? 0) + 1;
    _persistProject('new project', project);
    _persistDeveloper(developer);
    return project;
  }

  Map<String, dynamic>? updateProject(String id, Map<String, dynamic> patch) {
    final project = projectById(id);
    if (project == null) return null;
    for (final key in [
      'name',
      'status',
      'district',
      'address',
      'description',
      'amenities',
      'tags',
      'priceMin',
      'priceMax',
      'rentMin',
      'rentMax',
      'constructionProgress',
      'completionDate',
      'lat',
      'lng',
      'isPublished',
    ]) {
      if (!patch.containsKey(key)) continue;
      if (key == 'amenities' || key == 'tags') {
        project[key] = sanitizeTextList(patch[key]) ?? patch[key];
      } else if (key == 'lat' || key == 'lng') {
        final value = patch[key];
        if (value is num) {
          project[key] = value.toDouble();
        }
      } else {
        project[key] = _clean(patch[key]);
      }
    }
    if (patch['isPublished'] == true) {
      final developer = project['developer'] as Map?;
      final developerId = developer?['id'] as String?;
      if (developerId == null || !hasActiveSubscription(developerId)) {
        throw StateError('SUBSCRIPTION_REQUIRED');
      }
      // Re-publishing an already-approved listing goes live immediately.
      // Anything else still needs platform review.
      final status = project['moderationStatus'] as String? ?? 'draft';
      if (status != 'approved') {
        project['moderationStatus'] = 'pending';
      }
      project['isPublished'] = true;
    }
    if (patch['isPublished'] == false) {
      project['isPublished'] = false;
    }
    _persistProject('project update', project);
    return project;
  }

  /// Removes a project (and cascaded inventory) from persistence first, then
  /// from memory. Awaits the DB DELETE so a restart cannot resurrect the row
  /// (fire-and-forget `_persist` was racing process shutdown / RLS no-ops).
  /// Returns the removed project, or `null` if it did not exist.
  Future<Map<String, dynamic>?> deleteProject(String id) async {
    _assertPersistenceForWrite('project delete');
    final index = projects.indexWhere((p) => p['id'] == id);
    if (index < 0) return null;
    final project = projects[index];

    _deletedProjectIds.add(id);

    final persistence = _persistence;
    if (persistence != null) {
      await persistence.deleteProject(id);
    }

    projects.removeAt(index);
    final developer = project['developer'] as Map?;
    final developerId = developer?['id'] as String?;
    if (developerId != null) {
      final reg = developerById(developerId);
      if (reg != null) {
        final count = (reg['projectsCount'] as int? ?? 1) - 1;
        reg['projectsCount'] = count < 0 ? 0 : count;
        _persistDeveloper(reg);
      }
    }
    leads.removeWhere((l) => l['projectId'] == id);
    reviews.removeWhere((r) => r['projectId'] == id);
    rentalListings.removeWhere((l) => l['projectId'] == id);
    for (final entry in favoritesByUser.entries) {
      entry.value.remove(id);
    }
    return project;
  }

  /// Replaces a project's promotions/installment/rent-terms list wholesale
  /// (Konseptsiya §8 "управление акциями, скидками и условиями
  /// рассрочки/аренды"). `PUT` semantics — developer submits the full list.
  Map<String, dynamic>? setProjectOffers(
    String projectId,
    List<Map<String, dynamic>> offers,
  ) {
    final project = projectById(projectId);
    if (project == null) return null;
    final normalized = offers.map((o) {
      return {
        'id': o['id'] ?? 'off-${_uuid.v4()}',
        'projectId': projectId,
        'type': o['type'] ?? 'discount',
        'title': _clean(o['title']) ?? '',
        'description': _clean(o['description']),
        'startsAt': o['startsAt'],
        'endsAt': o['endsAt'],
        'downPaymentPercent': o['downPaymentPercent'],
        'termMonths': o['termMonths'],
        'interestRate': o['interestRate'],
      };
    }).toList();
    project['offers'] = normalized;
    _persist(
      'project offers',
      (p) => p.replaceProjectOffers(projectId, normalized),
    );
    for (final offer in normalized) {
      _broadcast('newOffer', {
        'projectId': projectId,
        'offerId': offer['id'],
        'title': offer['title'],
      });
    }
    return project;
  }

  Map<String, dynamic> addBuilding(
    String projectId,
    Map<String, dynamic> input,
  ) {
    final project = projectById(projectId)!;
    final building = {
      'id': 'bld-${_uuid.v4()}',
      'projectId': projectId,
      'name': _clean(input['name']) ?? 'Building',
      'floors': input['floors'] ?? 1,
      'constructionProgress': input['constructionProgress'],
      'completionDate': input['completionDate'],
      'units': <Map<String, dynamic>>[],
    };
    final buildings = project['buildings'] as List;
    buildings.add(building);
    _persist(
      'new building',
      (p) => p.saveBuilding(building, sortOrder: buildings.length - 1),
    );
    return building;
  }

  Map<String, dynamic>? addUnit(String projectId, Map<String, dynamic> input) {
    final project = projectById(projectId);
    if (project == null) return null;
    final buildingId = input['buildingId'] as String?;
    if (buildingId == null) return null;
    Map? building;
    for (final b in (project['buildings'] as List).cast<Map>()) {
      if (b['id'] == buildingId) {
        building = b;
        break;
      }
    }
    if (building == null) return null;
    final unit = {
      'id': 'unt-${_uuid.v4()}',
      'buildingId': buildingId,
      'number': _clean(input['number']) ?? '1',
      'kind': input['kind'] ?? 'apartment',
      'dealType': input['dealType'] ?? 'sale',
      'status': input['status'] ?? 'available',
      'floor': input['floor'] ?? 1,
      'isOffplan': input['isOffplan'] ?? false,
      'areaTotal': input['areaTotal'] ?? 50.0,
      'areaLiving': input['areaLiving'],
      'rooms': input['rooms'],
      'layout': _clean(input['layout']),
      'price': input['price'],
      'priceM2': input['priceM2'],
      'rentMonthly': input['rentMonthly'],
      'rentM2': input['rentM2'],
      'minLeaseMonths': input['minLeaseMonths'],
      'finishing': _clean(input['finishing']),
      'view': _clean(input['view']),
      'planColumn': input['planColumn'],
      'planRow': input['planRow'],
      'version': 1,
      'media': <Map<String, dynamic>>[],
    };
    final units = building['units'] as List;
    units.add(unit);
    project['totalUnits'] = (project['totalUnits'] as int? ?? 0) + 1;
    if (unit['status'] == 'available') {
      project['availableUnits'] = (project['availableUnits'] as int? ?? 0) + 1;
    }
    _recomputeProjectPricing(project);
    _persist(
      'new unit',
      (p) =>
          p.saveUnit(unit, projectId: projectId, sortOrder: units.length - 1),
    );
    // Unit totals + price aggregates live on the project row.
    _persistProject('project unit counts', project);
    return unit;
  }

  /// Applies [patch] to unit [unitId]. If [patch] carries an
  /// `expectedVersion` field and it no longer matches the row's current
  /// `version`, throws [UnitConflictException] instead of applying the
  /// patch (optimistic locking — see `PATCH /v1/admin/units/:uid`).
  /// On success, `version` is incremented and returned on the unit.
  Map<String, dynamic>? updateUnit(String unitId, Map<String, dynamic> patch) {
    final found = unitById(unitId);
    if (found == null) return null;
    final unit = found.unit;
    final currentVersion = (unit['version'] as int?) ?? 1;
    final expectedVersionRaw = patch['expectedVersion'];
    if (expectedVersionRaw != null) {
      final expectedVersion = (expectedVersionRaw as num).toInt();
      if (expectedVersion != currentVersion) {
        throw UnitConflictException(
          currentVersion,
          Map<String, dynamic>.from(unit),
        );
      }
    }
    final prevStatus = unit['status'];
    for (final key in [
      'status',
      'price',
      'priceM2',
      'rentMonthly',
      'rentM2',
      'dealType',
      'number',
      'floor',
      'areaTotal',
      'rooms',
      'finishing',
      'view',
      'isOffplan',
    ]) {
      if (patch.containsKey(key)) unit[key] = _clean(patch[key]);
    }
    if (patch.containsKey('status') && patch['status'] != prevStatus) {
      _broadcast('unitStatusChanged', {
        'projectId': found.project['id'],
        'buildingId': found.building['id'],
        'unitId': unitId,
        'status': unit['status'],
      });
    }
    unit['version'] = currentVersion + 1;
    _recomputeProjectPricing(found.project);
    _persist(
      'unit update',
      (p) => p.saveUnit(
        unit,
        projectId: found.project['id'] as String,
        sortOrder: (found.building['units'] as List).indexOf(unit),
      ),
    );
    _persistProject('project pricing', found.project);
    return unit;
  }

  Map<String, dynamic> addUnitMedia(
    String unitId, {
    required String url,
    String type = 'photo',
    bool isCover = false,
  }) {
    final found = unitById(unitId)!;
    final media = {
      'id': 'med-${_uuid.v4()}',
      'type': type,
      'url': url,
      'sortOrder': (found.unit['media'] as List).length,
      'isCover': isCover,
    };
    (found.unit['media'] as List).add(media);
    _persist('unit media', (p) => p.saveUnitMedia(media, unitId: unitId));
    return media;
  }

  List<Map<String, dynamic>> pendingProjects() => projects
      .where(
        (p) => (p['moderationStatus'] as String? ?? 'approved') == 'pending',
      )
      .toList();

  Map<String, dynamic>? moderateProject(
    String id, {
    required String decision,
    String? note,
    bool platformOverride = false,
  }) {
    final project = projectById(id);
    if (project == null) return null;
    switch (decision) {
      case 'approve':
        if (!platformOverride) {
          final developer = project['developer'] as Map?;
          final developerId = developer?['id'] as String?;
          if (developerId == null || !hasActiveSubscription(developerId)) {
            throw StateError('SUBSCRIPTION_REQUIRED');
          }
        }
        project['moderationStatus'] = 'approved';
        project['isPublished'] = true;
        if (note != null) {
          project['moderationNote'] = sanitizeText(note);
        }
        // Ensure sale/rent aggregates exist so B2C `mode=buy|rent` can see it.
        _recomputeProjectPricing(project);
      case 'reject':
        project['moderationStatus'] = 'rejected';
        project['isPublished'] = false;
        project['moderationNote'] = sanitizeText(note);
      case 'unpublish':
        project['isPublished'] = false;
        if (note != null) {
          project['moderationNote'] = sanitizeText(note);
        }
      case 'warn':
        if (note == null || note.trim().isEmpty) {
          throw StateError('NOTE_REQUIRED');
        }
        project['moderationNote'] = sanitizeText(note);
      default:
        throw StateError('INVALID_DECISION');
    }
    _refreshProjectDeveloper(project);
    _persistProject('project moderation', project);
    return project;
  }

  Future<Map<String, dynamic>?> updateLeadAdmin(
    String id, {
    String? status,
    String? assignedManager,
    String? ownerUserId,
    bool clearOwner = false,
    String? actorUserId,
    String? notes,
    List<String>? tags,
    String? score, // hot | warm | cold
  }) async {
    var lead = leadById(id);
    if (lead == null) return null;

    if (clearOwner || ownerUserId != null) {
      final actor = actorUserId?.trim();
      if (actor == null || actor.isEmpty) {
        throw StateError('ACTOR_REQUIRED');
      }
      lead = await setLeadOwner(
        id,
        ownerUserId: clearOwner ? null : ownerUserId,
        actorUserId: actor,
      );
      if (lead == null) return null;
    } else if (assignedManager != null) {
      lead['assignedManager'] = sanitizeText(assignedManager);
    }

    if (status != null && lead['status'] != status) {
      final previous = lead['status'];
      lead['status'] = status;
      _broadcast('leadStatusChanged', {
        'leadId': lead['id'],
        'projectId': lead['projectId'],
        'status': status,
      }, adminOnly: true);
      if (actorUserId != null) {
        _appendLeadEvent({
          'id': 'lev-${_uuid.v4()}',
          'leadId': id,
          'actorUserId': actorUserId,
          'type': 'status_changed',
          'fromUserId': null,
          'toUserId': null,
          'detail': '$previous -> $status',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
    if (notes != null) {
      lead['notes'] = sanitizeText(notes);
      if (actorUserId != null && notes.trim().isNotEmpty) {
        _appendLeadEvent({
          'id': 'lev-${_uuid.v4()}',
          'leadId': id,
          'actorUserId': actorUserId,
          'type': 'note',
          'fromUserId': null,
          'toUserId': null,
          'detail': sanitizeText(notes),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
    if (tags != null) {
      lead['tags'] = tags.map((t) => sanitizeText(t)!).toList();
    }
    if (score != null) lead['score'] = score;
    lead['lastContactAt'] = DateTime.now().toIso8601String();
    await _persistLead(lead);
    return lead;
  }

  /// Demand/CRM analytics for one project (Konseptsiya §8 "аналитика
  /// спроса", "воронка, прогресс продаж"). Computed on the fly from the
  /// in-memory model — no separate event-tracking pipeline yet.
  Map<String, dynamic> projectAnalytics(String projectId) {
    final project = projectById(projectId)!;
    final projectLeads = leadsForProject(projectId);
    final funnel = <String, int>{};
    for (final lead in projectLeads) {
      final status = lead['status'] as String? ?? 'new';
      funnel[status] = (funnel[status] ?? 0) + 1;
    }
    final units = [
      for (final b in (project['buildings'] as List).cast<Map>())
        ...(b['units'] as List).cast<Map>(),
    ];
    final byStatus = <String, int>{};
    final byRooms = <String, int>{};
    final byFloor = <String, int>{};
    for (final unit in units) {
      final status = unit['status'] as String? ?? 'available';
      byStatus[status] = (byStatus[status] ?? 0) + 1;
      final rooms =
          unit['rooms']?.toString() ?? unit['layout']?.toString() ?? '—';
      byRooms[rooms] = (byRooms[rooms] ?? 0) + 1;
      final floor = 'floor_${unit['floor']}';
      byFloor[floor] = (byFloor[floor] ?? 0) + 1;
    }
    final sold = units
        .where((u) => u['status'] == 'sold' || u['status'] == 'rented')
        .length;
    final total = units.length;
    final sellThroughPercent = total == 0 ? 0.0 : (sold / total) * 100;
    final now = DateTime.now();
    final leadsLast30Days = projectLeads.where((l) {
      final created = DateTime.tryParse(l['createdAt'] as String? ?? '');
      return created != null && now.difference(created).inDays <= 30;
    }).length;
    // Naive linear sell-out projection from the last-30-day pace.
    final remaining = total - sold;
    final monthlyPace = sold == 0
        ? 0.0
        : sold / 6.0; // seed data has no real history
    final estimatedMonthsToSellOut = monthlyPace <= 0
        ? null
        : (remaining / monthlyPace).ceil();
    return {
      'projectId': projectId,
      'leadFunnel': funnel,
      'leadsTotal': projectLeads.length,
      'leadsLast30Days': leadsLast30Days,
      'unitsByStatus': byStatus,
      'unitsByRooms': byRooms,
      'unitsByFloor': byFloor,
      'totalUnits': total,
      'soldOrRentedUnits': sold,
      'sellThroughPercent': double.parse(sellThroughPercent.toStringAsFixed(1)),
      'estimatedMonthsToSellOut': estimatedMonthsToSellOut,
    };
  }

  void audit({
    required String actorUserId,
    required String action,
    String? targetType,
    String? targetId,
    String? detail,
  }) {
    final entry = {
      'id': 'aud-${_uuid.v4()}',
      'actorUserId': actorUserId,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'detail': detail,
      'createdAt': DateTime.now().toIso8601String(),
    };
    auditLog.insert(0, entry);
    _persist('audit entry', (p) => p.saveAuditEntry(entry));
  }

  // --- Documents (developer verification / trust layer) ------------------

  Map<String, dynamic> addDocument({
    required String developerId,
    String? projectId,
    required String type,
    required String fileUrl,
    required String uploadedBy,
  }) {
    final doc = {
      'id': 'doc-${_uuid.v4()}',
      'developerId': developerId,
      'projectId': projectId,
      'type': type,
      'fileUrl': fileUrl,
      'status': 'pending',
      'rejectReason': null,
      'uploadedBy': uploadedBy,
      'createdAt': DateTime.now().toIso8601String(),
      'reviewedBy': null,
      'reviewedAt': null,
    };
    documents.insert(0, doc);
    _persist('document', (p) => p.saveDocument(doc));
    return doc;
  }

  List<Map<String, dynamic>> documentsForDeveloper(String developerId) =>
      documents.where((d) => d['developerId'] == developerId).toList();

  Map<String, dynamic>? documentById(String id) {
    for (final d in documents) {
      if (d['id'] == id) return d;
    }
    return null;
  }

  /// Moderator review of one document. [status] must be one of
  /// [kDocumentStatuses]; [rejectReason] is only kept when rejecting.
  Map<String, dynamic>? reviewDocument(
    String id, {
    required String status,
    String? rejectReason,
    required String reviewedBy,
  }) {
    final doc = documentById(id);
    if (doc == null) return null;
    doc['status'] = status;
    doc['rejectReason'] = status == 'rejected' ? sanitizeText(rejectReason) : null;
    doc['reviewedBy'] = reviewedBy;
    doc['reviewedAt'] = DateTime.now().toIso8601String();
    _persist('document review', (p) => p.saveDocument(doc));
    return doc;
  }

  /// Whether every entry in [kRequiredDocumentTypes] has at least one
  /// `accepted` document for [developerId] — the precondition for
  /// `PATCH /v1/platform/developers/:id/approve` (Documents API contract).
  bool hasAllRequiredDocumentsAccepted(String developerId) {
    final devDocs = documentsForDeveloper(developerId);
    for (final type in kRequiredDocumentTypes) {
      final accepted = devDocs.any(
        (d) => d['type'] == type && d['status'] == 'accepted',
      );
      if (!accepted) return false;
    }
    return true;
  }

  /// Privacy-safe per-type status for [developerId], for the public
  /// `GET /v1/developers/:id/verification` route: one `{type, status}` entry
  /// per [kRequiredDocumentTypes] (using `missing` when nothing's been
  /// uploaded yet), deliberately excluding `fileUrl`/`rejectReason`/reviewer
  /// identity, which stay moderator-only via the platform documents routes.
  List<Map<String, String>> documentStatusSummary(String developerId) {
    // documentsForDeveloper returns newest-first (see addDocument), so the
    // first match per type is that type's latest submission.
    final devDocs = documentsForDeveloper(developerId);
    return [
      for (final type in kRequiredDocumentTypes)
        {
          'type': type,
          'status':
              devDocs.firstWhere(
                (d) => d['type'] == type,
                orElse: () => const {'status': 'missing'},
              )['status']
              as String,
        },
    ];
  }

  // --- Admin notifications --------------------------------------------------

  /// Records a change that needs a system admin's attention (new/updated/
  /// submitted project, uploaded document, developer application) and pushes
  /// it live to every connected admin socket. Called explicitly from the
  /// route layer next to the matching [audit] call, mirroring how audit
  /// entries are recorded — see `admin_routes.dart`.
  Map<String, dynamic> notifyAdmins({
    required String type,
    required String title,
    String? body,
    String? developerId,
    String? projectId,
    String? targetType,
    String? targetId,
    String? actorUserId,
  }) {
    final n = {
      'id': 'ntf-${_uuid.v4()}',
      'type': type,
      'title': title,
      'body': body,
      'developerId': developerId,
      'projectId': projectId,
      'targetType': targetType,
      'targetId': targetId,
      'actorUserId': actorUserId,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    notifications.insert(0, n);
    _persist('notification', (p) => p.saveNotification(n));
    _broadcast('adminNotification', n, adminOnly: true);
    return n;
  }

  /// Newest-first, optionally filtered to unread only.
  List<Map<String, dynamic>> adminNotifications({
    bool unreadOnly = false,
    int limit = 200,
  }) {
    final items = unreadOnly
        ? notifications.where((n) => n['isRead'] != true)
        : notifications;
    return items.take(limit).toList();
  }

  int unreadNotificationCount() =>
      notifications.where((n) => n['isRead'] != true).length;

  Map<String, dynamic>? markNotificationRead(String id) {
    for (final n in notifications) {
      if (n['id'] == id) {
        n['isRead'] = true;
        _persist('notification read', (p) => p.saveNotification(n));
        return n;
      }
    }
    return null;
  }

  /// Marks every unread notification read; returns how many were changed.
  int markAllNotificationsRead() {
    var count = 0;
    for (final n in notifications) {
      if (n['isRead'] != true) {
        n['isRead'] = true;
        count++;
        _persist('notification read', (p) => p.saveNotification(n));
      }
    }
    return count;
  }

  // --- Photo reports (construction progress) ------------------------------

  String _dateOnly(DateTime dt) => dt.toIso8601String().split('T').first;

  Map<String, dynamic> addPhotoReport({
    required String projectId,
    String? buildingId,
    required String photoUrl,
    required DateTime takenAt,
    required bool takenAtIsManual,
    int? progressPercent,
    required String uploadedBy,
  }) {
    final report = {
      'id': 'phr-${_uuid.v4()}',
      'projectId': projectId,
      'buildingId': buildingId,
      'photoUrl': photoUrl,
      'takenAt': _dateOnly(takenAt),
      'takenAtIsManual': takenAtIsManual,
      'progressPercent': progressPercent,
      'uploadedBy': uploadedBy,
      'createdAt': DateTime.now().toIso8601String(),
    };
    photoReports.insert(0, report);
    _persist('photo report', (p) => p.savePhotoReport(report));
    if (progressPercent != null) {
      final project = projectById(projectId);
      if (project != null) {
        project['constructionProgress'] = progressPercent;
        _persistProject('project construction progress', project);
      }
    }
    return report;
  }

  /// Entries for [projectId], newest-first by `takenAt` (client groups the
  /// result by month — see Photo Reports API contract).
  List<Map<String, dynamic>> photoReportsForProject(String projectId) {
    final items = photoReports.where((r) => r['projectId'] == projectId).toList();
    items.sort(
      (a, b) => (b['takenAt'] as String).compareTo(a['takenAt'] as String),
    );
    return items;
  }

  Map<String, dynamic>? photoReportById(String id) {
    for (final r in photoReports) {
      if (r['id'] == id) return r;
    }
    return null;
  }

  Map<String, dynamic>? deletePhotoReport(String id) {
    final index = photoReports.indexWhere((r) => r['id'] == id);
    if (index < 0) return null;
    final removed = photoReports.removeAt(index);
    _persist('photo report delete', (p) => p.deletePhotoReport(id));
    return removed;
  }

  Map<String, dynamic> platformAnalytics() {
    final owned = developersRegistry.where((d) => d['ownerUserId'] != null);
    var activeSubs = 0;
    var unpaid = 0;
    for (final d in owned) {
      final id = d['id'] as String;
      if (hasActiveSubscription(id)) {
        activeSubs++;
      } else {
        unpaid++;
      }
    }
    final byPlan = <String, int>{};
    for (final sub in subscriptionsByDeveloperId.values) {
      if (sub['status'] != 'active') continue;
      final planId = sub['planId'] as String? ?? 'growth';
      byPlan[planId] = (byPlan[planId] ?? 0) + 1;
    }
    return {
      'usersTotal': _usersByPhone.length,
      'projectsTotal': projects.length,
      'publishedProjects': publishedProjects.length,
      'leadsTotal': leads.length,
      'developersPending': pendingDevelopers().length,
      'projectsPending': pendingProjects().length,
      'developersTotal': developersRegistry.length,
      'subscriptionsActive': activeSubs,
      'subscriptionsByPlan': byPlan,
      'businessesUnpaid': unpaid,
      'subscriptionPriceUsd': kBusinessSubscriptionUsd,
      'reviewsPendingModeration': reviewsForModeration().length,
      'reviewsTotal': reviews.length,
      'rentalListingsPending': pendingRentalListings().length,
      'rentalListingsApproved': rentalListings
          .where((l) => l['moderationStatus'] == 'approved')
          .length,
    };
  }

  // --- Live WebSocket ---------------------------------------------------

  /// Registers an authenticated live-update [socket]. [isAdmin] gates
  /// delivery of admin-only events (lead CRM/PII) to this subscriber.
  void addSocket(WebSocketChannel socket, {bool isAdmin = false}) {
    _sockets[socket] = isAdmin;
    socket.stream.listen(
      (
        _,
      ) {}, // client -> server messages (subscribeProject/ping) are advisory only here.
      onDone: () => _sockets.remove(socket),
      onError: (_) => _sockets.remove(socket),
    );
  }

  /// Broadcasts an [event] to connected sockets. When [adminOnly] is set the
  /// frame is only delivered to admin subscribers — used for lead events,
  /// which expose CRM/PII metadata that ordinary users must not receive.
  void _broadcast(String event, Object? data, {bool adminOnly = false}) {
    final frame = jsonEncode({'event': event, 'data': data});
    for (final entry in _sockets.entries.toList()) {
      if (adminOnly && !entry.value) continue;
      try {
        entry.key.sink.add(frame);
      } catch (_) {
        _sockets.remove(entry.key);
      }
    }
  }

  /// Periodically flips a random unit's status to simulate the live
  /// availability grid. **Off by default** — it steals the "I clicked Sold"
  /// demo moment. Enable only with `LIVE_DEMO_TICKER=true` in the environment
  /// / `.env` (see `docs/HOSTING_AHOST.md` and `PRESENTATION_READINESS.md`).
  void _startLiveUpdates() {
    final tickerOn =
        (appEnv()['LIVE_DEMO_TICKER'] ?? '').trim().toLowerCase() == 'true';
    if (!tickerOn) {
      stderr.writeln(
        '[Store] Live unit ticker OFF (set LIVE_DEMO_TICKER=true to enable).',
      );
      return;
    }
    stderr.writeln(
      '[Store] Live unit ticker ON — random status flips every 8s '
      '(disable for investor demos).',
    );
    _ticker = Timer.periodic(const Duration(seconds: 8), (_) {
      if (projects.isEmpty) return;
      final project = projects[_rand.nextInt(projects.length)];
      final buildings = (project['buildings'] as List).cast<Map>();
      if (buildings.isEmpty) return;
      final building = buildings[_rand.nextInt(buildings.length)];
      final units = (building['units'] as List).cast<Map<String, dynamic>>();
      if (units.isEmpty) return;
      final unit = units[_rand.nextInt(units.length)];

      final next = switch (unit['status']) {
        'available' => 'reserved',
        'reserved' => unit['dealType'] == 'rent' ? 'rented' : 'sold',
        _ => 'available',
      };
      unit['status'] = next;

      _broadcast('unitStatusChanged', {
        'projectId': project['id'],
        'buildingId': building['id'],
        'unitId': unit['id'],
        'status': next,
      });

      final persistence = _persistence;
      if (persistence != null) {
        final unitId = unit['id'] as String;
        unawaited(
          persistence.saveUnitStatus(unitId, next).catchError((error) {
            stderr.writeln(
              '[Store] Failed to persist unit status for $unitId: $error',
            );
          }),
        );
      }
    });

    // Simulated "flash offer" push, purely for client engagement/demo
    // purposes — reuses an existing seeded offer rather than modeling a
    // full offers-management system.
    _offerTicker = Timer.periodic(const Duration(seconds: 45), (_) {
      final withOffers = projects
          .where((p) => (p['offers'] as List).isNotEmpty)
          .toList();
      if (withOffers.isEmpty) return;
      final project = withOffers[_rand.nextInt(withOffers.length)];
      final offers = (project['offers'] as List).cast<Map<String, dynamic>>();
      final offer = offers[_rand.nextInt(offers.length)];

      _broadcast('newOffer', {
        'projectId': project['id'],
        'offerId': offer['id'],
        'title': offer['title'],
      });
    });
  }

  void dispose() {
    _ticker?.cancel();
    _offerTicker?.cancel();
    for (final s in _sockets.keys) {
      s.sink.close();
    }
    final db = _db;
    if (db != null) {
      unawaited(db.close().catchError((_) {}));
    }
  }
}
