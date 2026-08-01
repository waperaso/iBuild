import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'admin_routes.dart';
import 'auth_context.dart';
import 'calculators.dart';
import 'env_loader.dart';
import 'http_helpers.dart';
import 'rate_limiter.dart';
import 'sms_service.dart';
import 'static_files.dart';
import 'store.dart';
import 'validation.dart';

/// Allowed values for `PATCH /v1/leads/:id/status`.
const kAllowedLeadStatuses = {
  'new',
  'contacted',
  'scheduled',
  'visited',
  'qualified',
  'won',
  'lost',
};

/// Allowed values for the `mode` query param on `GET /v1/projects`.
const kAllowedProjectModes = {'buy', 'rent', 'newBuilds'};

/// Canonical construction-stage values for a project. Kept as a fixed
/// vocabulary rather than derived from whatever the catalogue happens to hold,
/// so filtering by a legitimate status keeps working even when no project is
/// currently in that stage.
const kAllowedProjectStatuses = {
  'planned',
  'under_construction',
  'ready',
  'handed_over',
};

/// Upper bound on `?limit=` for paginated list routes, so a single request
/// cannot ask the server to serialize the entire catalogue.
const kMaxPageLimit = 100;

/// Whether [project] may be exposed to [req]: it must be published +
/// moderation-approved, unless the caller is an admin (system/residence).
/// Applied uniformly across every public project/unit read route so
/// unpublished/under-moderation inventory can't be scraped via a sub-route
/// (units/buildings/grid/offers/unit-by-id) — the IDOR gap the plan flags.
bool _isProjectVisible(Map<String, dynamic> project, Request req) {
  final published =
      (project['isPublished'] as bool? ?? true) &&
      (project['moderationStatus'] as String? ?? 'approved') == 'approved';
  return published || req.auth?.isAdmin == true;
}

/// Builds the full request-handling [Handler] (routes + CORS/logging
/// middleware + rate limiting + auth) for [store].
Handler createHandler(
  Store store, {
  RateLimiter? otpLimiter,
  RateLimiter? otpVerifyLimiter,
  RateLimiter? refreshLimiter,
  RateLimiter? leadsLimiter,
}) {
  final otpRateLimiter =
      otpLimiter ?? RateLimiter(5, const Duration(minutes: 5));
  // Verify allows a few more hits than send (a user may retype a wrong
  // code), while the per-requestId attempt cap (kMaxOtpAttempts) is the real
  // brute-force guard.
  final otpVerifyRateLimiter =
      otpVerifyLimiter ?? RateLimiter(15, const Duration(minutes: 5));
  final refreshRateLimiter =
      refreshLimiter ?? RateLimiter(30, const Duration(minutes: 5));
  final leadsRateLimiter =
      leadsLimiter ?? RateLimiter(10, const Duration(minutes: 1));

  // Districts are data-driven, so they must be read per request: computing
  // them once at startup made every project created later (in a district not
  // present in the seed) unfilterable — `?district=` returned 422.
  Set<String> allowedDistricts() => store.projects
      .map((p) => (p['district'] as String).toLowerCase())
      .toSet();

  final router = Router();

  router.get('/v1/health', (Request req) => jsonOk({'status': 'ok'}));

  router.get('/v1/static/residences/<file>', residencesStaticHandler());

  router.get('/v1/static/uploads/<file>', uploadsStaticHandler());

  // GET /v1/projects — public catalogue (published only)
  router.get('/v1/projects', (Request req) {
    final qp = req.url.queryParameters;
    var items = store.publishedProjects;

    final mode = qp['mode'];
    if (mode != null && mode.isNotEmpty) {
      if (!isOneOf(mode, kAllowedProjectModes)) {
        return jsonError('VALIDATION_ERROR', 'Invalid mode', status: 422);
      }
      // Konseptsiya §5: "Купить" = только первичка от застройщика (any
      // segment — ЖК/БЦ/стрит-ритейл — as long as it has sale inventory).
      // "Снять" = первичка И вторичка, across every segment — never gated
      // by project type. This mirrors the aggregate priceMin/rentMin
      // computed per-project in seed_data.dart / addUnit, so it stays
      // correct as new segments (street retail) are added.
      if (mode == 'buy') {
        items = items
            .where((p) => p['priceMin'] != null || p['priceMax'] != null)
            .toList();
      } else if (mode == 'rent') {
        items = items
            .where((p) => p['rentMin'] != null || p['rentMax'] != null)
            .toList();
      } else if (mode == 'newBuilds') {
        items = items
            .where((p) => p['status'] == 'under_construction')
            .toList();
      }
    }

    final type = qp['type'];
    if (type != null && type.isNotEmpty) {
      items = items.where((p) => p['type'] == type).toList();
    }
    final status = qp['status'];
    if (status != null && status.isNotEmpty) {
      if (!isOneOf(status, kAllowedProjectStatuses)) {
        return jsonError('VALIDATION_ERROR', 'Invalid status', status: 422);
      }
      items = items.where((p) => p['status'] == status).toList();
    }
    final district = qp['district'];
    if (district != null && district.isNotEmpty) {
      if (!allowedDistricts().contains(district.toLowerCase())) {
        return jsonError('VALIDATION_ERROR', 'Invalid district', status: 422);
      }
      items = items
          .where(
            (p) =>
                (p['district'] as String).toLowerCase() ==
                district.toLowerCase(),
          )
          .toList();
    }
    final search = qp['search'];
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      items = items
          .where(
            (p) =>
                (p['name'] as String).toLowerCase().contains(q) ||
                (p['district'] as String).toLowerCase().contains(q) ||
                (p['address'] as String).toLowerCase().contains(q),
          )
          .toList();
    }

    final priceMin = double.tryParse(qp['priceMin'] ?? '');
    final priceMax = double.tryParse(qp['priceMax'] ?? '');
    if (priceMin != null || priceMax != null) {
      items = items.where((p) {
        final min = (p['priceMin'] as num?)?.toDouble();
        final max = (p['priceMax'] as num?)?.toDouble() ?? min;
        // A project with no sale price cannot satisfy a sale-price range —
        // excluded, mirroring the rent filter below (it used to be included,
        // so `?priceMax=…` leaked rent-only projects into "Купить" results).
        if (min == null && max == null) return false;
        final low = min ?? max!;
        final high = max ?? min!;
        if (priceMin != null && high < priceMin) return false;
        if (priceMax != null && low > priceMax) return false;
        return true;
      }).toList();
    }

    final rentMin = double.tryParse(qp['rentMin'] ?? '');
    final rentMax = double.tryParse(qp['rentMax'] ?? '');
    if (rentMin != null || rentMax != null) {
      items = items.where((p) {
        final min = (p['rentMin'] as num?)?.toDouble();
        final max = (p['rentMax'] as num?)?.toDouble() ?? min;
        if (min == null && max == null) return false;
        final low = min ?? max!;
        final high = max ?? min!;
        if (rentMin != null && high < rentMin) return false;
        if (rentMax != null && low > rentMax) return false;
        return true;
      }).toList();
    }

    // rooms / areaMin / offplan filter on the flattened unit list — a
    // project matches if *any* of its units satisfies the constraint
    // (docs/08-api.md `GET /projects` params).
    final roomsParam = qp['rooms'];
    final areaMin = double.tryParse(qp['areaMin'] ?? '');
    final offplanParam = qp['offplan'];
    if (roomsParam != null || areaMin != null || offplanParam != null) {
      final rooms = roomsParam
          ?.split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toSet();
      final offplan = offplanParam == null ? null : offplanParam == 'true';
      items = items.where((p) {
        final units = [
          for (final b in (p['buildings'] as List).cast<Map>())
            ...(b['units'] as List).cast<Map>(),
        ];
        return units.any((u) {
          if (rooms != null &&
              rooms.isNotEmpty &&
              !rooms.contains(u['rooms'] as int? ?? -1)) {
            return false;
          }
          if (areaMin != null && (u['areaTotal'] as num? ?? 0) < areaMin) {
            return false;
          }
          if (offplan != null &&
              (u['isOffplan'] as bool? ?? false) != offplan) {
            return false;
          }
          return true;
        });
      }).toList();
    }

    final total = items.length;
    final page = int.tryParse(qp['page'] ?? '') ?? 1;
    final limit = int.tryParse(qp['limit'] ?? '') ?? 20;
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1
        ? 20
        : (limit > kMaxPageLimit ? kMaxPageLimit : limit);
    final start = (safePage - 1) * safeLimit;
    final paged = start >= items.length
        ? const <Map<String, dynamic>>[]
        : items.sublist(start, min(start + safeLimit, items.length));

    return jsonOk(
      paged.map(store.summarize).toList(),
      meta: {'total': total, 'page': safePage, 'limit': safeLimit},
    );
  });

  router.get('/v1/projects/<id>', (Request req, String id) {
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    return jsonOk(project);
  });

  router.get('/v1/projects/<id>/units', (Request req, String id) {
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    final units = [
      for (final b in (project['buildings'] as List).cast<Map>())
        ...(b['units'] as List).cast<Map>(),
    ];
    return jsonOk(units, meta: {'total': units.length});
  });

  router.get('/v1/projects/<id>/buildings', (Request req, String id) {
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    final buildings = (project['buildings'] as List)
        .cast<Map>()
        .map((b) => {...b}..remove('units'))
        .toList();
    return jsonOk(buildings, meta: {'total': buildings.length});
  });

  // "Шахматка" — buildings with just position + status per unit, cheaper
  // than fetching the full project payload just to render the grid.
  router.get('/v1/projects/<id>/units/grid', (Request req, String id) {
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    final buildings = (project['buildings'] as List).cast<Map>().map((b) {
      final units = (b['units'] as List).cast<Map>().map(
        (u) => {
          'id': u['id'],
          'number': u['number'],
          'floor': u['floor'],
          'planColumn': u['planColumn'],
          'planRow': u['planRow'],
          'status': u['status'],
          'dealType': u['dealType'],
          'kind': u['kind'],
          'rooms': u['rooms'],
          'areaTotal': u['areaTotal'],
          'price': u['price'],
          'rentMonthly': u['rentMonthly'],
        },
      );
      return {
        'id': b['id'],
        'name': b['name'],
        'floors': b['floors'],
        'units': units.toList(),
      };
    }).toList();
    return jsonOk({'projectId': id, 'buildings': buildings});
  });

  router.get('/v1/projects/<id>/offers', (Request req, String id) {
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    return jsonOk(project['offers']);
  });

  // --- Developer verification summary (public, privacy-safe) --------------

  // Buyer-facing counterpart to the moderator-only
  // `GET /v1/platform/developers/:id/documents`: exposes just enough for the
  // B2C "Verified" badge breakdown (overall status + per-required-type
  // status) without leaking fileUrl/rejectReason/reviewer identity.
  router.get('/v1/developers/<id>/verification', (Request req, String id) {
    final developer = store.developerById(id);
    if (developer == null) {
      return jsonError('NOT_FOUND', 'Developer $id not found', status: 404);
    }
    return jsonOk({
      'developerId': id,
      'verificationStatus': developer['verificationStatus'],
      'documents': store.documentStatusSummary(id),
    });
  });

  // --- Photo reports (construction progress) -------------------------------

  router.get('/v1/projects/<id>/photo-reports', (Request req, String id) {
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    final items = store.photoReportsForProject(id);
    return jsonOk(items, meta: {'total': items.length});
  });

  // --- Reviews (Konseptsiya §9) -------------------------------------------

  router.get('/v1/projects/<id>/reviews', (Request req, String id) {
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    final items = store.reviewsForProject(id);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.post('/v1/projects/<id>/reviews', (Request req, String id) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_isProjectVisible(project, req)) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    final body = await req.readJson();
    final text = sanitizeText(capString(body['body'] as String?, 2000));
    if (text == null || text.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'body is required (max 2000 chars)',
        status: 422,
      );
    }
    // Ratings feed the project's aggregate score, so an out-of-range value
    // would permanently skew it. Reject rather than clamp so the client can
    // show the user what went wrong.
    final ratingOverall = (body['ratingOverall'] as num?)?.toInt() ?? 5;
    final subRatings = {
      'ratingLocation': (body['ratingLocation'] as num?)?.toInt(),
      'ratingQuality': (body['ratingQuality'] as num?)?.toInt(),
      'ratingValue': (body['ratingValue'] as num?)?.toInt(),
    };
    bool outOfRange(int? v) => v != null && (v < 1 || v > 5);
    if (outOfRange(ratingOverall) || subRatings.values.any(outOfRange)) {
      return jsonError(
        'VALIDATION_ERROR',
        'ratings must be integers between 1 and 5',
        status: 422,
      );
    }
    final review = store.createReview(
      userId: auth.userId,
      userName: (auth.user['name'] as String?) ?? auth.phone,
      projectId: id,
      ratingOverall: ratingOverall,
      ratingLocation: subRatings['ratingLocation'],
      ratingQuality: subRatings['ratingQuality'],
      ratingValue: subRatings['ratingValue'],
      body: text,
    );
    return jsonOk(review, status: 201);
  });

  // --- Owner rental listings (Konseptsiya §5, §8) -------------------------

  router.get('/v1/rental-listings', (Request req) {
    final qp = req.url.queryParameters;
    final items = store.approvedRentalListings(
      district: qp['district'],
      propertyKind: qp['propertyKind'],
      priceMax: double.tryParse(qp['priceMax'] ?? ''),
      roomsMin: int.tryParse(qp['roomsMin'] ?? ''),
    );
    return jsonOk(items, meta: {'total': items.length});
  });

  router.get('/v1/rental-listings/mine', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final items = store.rentalListingsForOwner(auth.userId);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.post('/v1/rental-listings', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final body = await req.readJson();
    const allowedKinds = {'apartment', 'office', 'retail'};
    final propertyKind = body['propertyKind'] as String?;
    final title = sanitizeText(capString(body['title'] as String?, 120));
    final description = sanitizeText(
      capString(body['description'] as String?, 2000),
    );
    final district = sanitizeText(body['district'] as String?);
    final address = sanitizeText(capString(body['address'] as String?, 300));
    final contactPhone = body['contactPhone'] as String?;
    final rentMonthly = (body['rentMonthly'] as num?)?.toDouble();
    final areaTotal = (body['areaTotal'] as num?)?.toDouble();
    if (title == null ||
        description == null ||
        district == null ||
        address == null ||
        propertyKind == null ||
        !allowedKinds.contains(propertyKind) ||
        contactPhone == null ||
        !isValidPhone(contactPhone) ||
        rentMonthly == null ||
        rentMonthly <= 0 ||
        areaTotal == null ||
        areaTotal <= 0) {
      return jsonError(
        'VALIDATION_ERROR',
        'title, description, district, address, propertyKind '
            '(apartment|office|retail), contactPhone, rentMonthly, areaTotal are required',
        status: 422,
      );
    }
    final listing = store.createRentalListing(
      ownerUserId: auth.userId,
      title: title,
      description: description,
      district: district,
      address: address,
      lat: (body['lat'] as num?)?.toDouble(),
      lng: (body['lng'] as num?)?.toDouble(),
      propertyKind: propertyKind,
      areaTotal: areaTotal,
      rooms: (body['rooms'] as num?)?.toInt(),
      rentMonthly: rentMonthly,
      minLeaseMonths: (body['minLeaseMonths'] as num?)?.toInt() ?? 12,
      contactPhone: contactPhone,
      photoUrls: (body['photoUrls'] as List?)?.cast<String>() ?? const [],
    );
    return jsonOk(listing, status: 201);
  });

  // --- Calculators (Konseptsiya §7, §11.C) --------------------------------

  router.post('/v1/calculators/mortgage', (Request req) async {
    final body = await req.readJson();
    final price = (body['price'] as num?)?.toDouble();
    final downPaymentPercent = (body['downPaymentPercent'] as num?)?.toDouble();
    final termYears = (body['termYears'] as num?)?.toInt();
    final annualRatePercent = (body['annualRatePercent'] as num?)?.toDouble();
    if (price == null ||
        price <= 0 ||
        downPaymentPercent == null ||
        downPaymentPercent < 0 ||
        downPaymentPercent >= 1 ||
        termYears == null ||
        termYears <= 0 ||
        termYears > kMaxTermYears ||
        annualRatePercent == null ||
        annualRatePercent < 0) {
      return jsonError(
        'VALIDATION_ERROR',
        'price, downPaymentPercent (0-1), '
            'termYears (1-$kMaxTermYears), annualRatePercent are required',
        status: 422,
      );
    }
    final quote = quoteMortgage(
      price: price,
      downPaymentPercent: downPaymentPercent,
      termYears: termYears,
      annualRatePercent: annualRatePercent,
    );
    return jsonOk(quote.toJson());
  });

  router.post('/v1/calculators/rental-yield', (Request req) async {
    final body = await req.readJson();
    final price = (body['price'] as num?)?.toDouble();
    final monthlyRent = (body['monthlyRent'] as num?)?.toDouble();
    if (price == null ||
        price <= 0 ||
        monthlyRent == null ||
        monthlyRent <= 0) {
      return jsonError(
        'VALIDATION_ERROR',
        'price and monthlyRent are required',
        status: 422,
      );
    }
    final quote = quoteRentalYield(
      price: price,
      monthlyRent: monthlyRent,
      areaTotal: (body['areaTotal'] as num?)?.toDouble(),
    );
    return jsonOk(quote.toJson());
  });

  router.post('/v1/mortgage-referrals', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final body = await req.readJson();
    final price = (body['price'] as num?)?.toDouble();
    final downPayment = (body['downPayment'] as num?)?.toDouble();
    final termYears = (body['termYears'] as num?)?.toInt();
    final contactPhone = body['contactPhone'] as String?;
    if (price == null ||
        price <= 0 ||
        downPayment == null ||
        downPayment < 0 ||
        downPayment > price ||
        termYears == null ||
        termYears <= 0 ||
        termYears > kMaxTermYears ||
        contactPhone == null ||
        !isValidPhone(contactPhone)) {
      return jsonError(
        'VALIDATION_ERROR',
        'price (> 0), downPayment (0..price), '
            'termYears (1-$kMaxTermYears), contactPhone are required',
        status: 422,
      );
    }
    final referralId = 'mref-${DateTime.now().millisecondsSinceEpoch}';
    final providerRef = await store.bankReferrals.submitReferral(
      referralId: referralId,
      contactPhone: contactPhone,
      price: price,
      downPayment: downPayment,
      termYears: termYears,
      projectId: body['projectId'] as String?,
      unitId: body['unitId'] as String?,
      bankName: body['bankName'] as String?,
    );
    store.audit(
      actorUserId: auth.userId,
      action: 'mortgage_referral.submit',
      targetType: 'mortgage_referral',
      targetId: referralId,
      detail: providerRef,
    );
    return jsonOk({
      'referralId': referralId,
      'providerRef': providerRef,
      'status': 'submitted',
      'message': 'A bank partner representative will contact you shortly.',
    }, status: 201);
  });

  router.get(
    '/v1/subscription-plans',
    (Request req) => jsonOk(kSubscriptionPlans),
  );

  router.get('/v1/units/<id>', (Request req, String id) {
    final found = store.unitById(id);
    if (found == null) {
      return jsonError('NOT_FOUND', 'Unit $id not found', status: 404);
    }
    if (!_isProjectVisible(found.project, req)) {
      return jsonError('NOT_FOUND', 'Unit $id not found', status: 404);
    }
    return jsonOk(found.unit);
  });

  // Deprecated public dump — redirects clients to /users/me/leads.
  // Kept as 401 so old clients fail closed instead of leaking all leads.
  router.get('/v1/leads', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Use GET /users/me/leads with Bearer token',
        status: 401,
      );
    }
    if (auth.isSystemAdmin) {
      return jsonOk(store.leads, meta: {'total': store.leads.length});
    }
    final items = store.leadsForUser(auth.userId);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.post('/v1/leads', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }

    final key = clientKeyFor(req);
    if (!leadsRateLimiter.allow(key)) {
      final retryAfter = leadsRateLimiter.retryAfterSeconds(key);
      return jsonError(
        'RATE_LIMITED',
        'Too many lead submissions, please try again later',
        status: 429,
        extraHeaders: {'Retry-After': '$retryAfter'},
      );
    }

    final body = await req.readJson();
    if (body['projectId'] == null || body['intent'] == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'projectId and intent are required',
        status: 422,
      );
    }
    if (body['consent'] != true) {
      return jsonError(
        'VALIDATION_ERROR',
        'consent is required and must be true',
        status: 422,
      );
    }
    final contactPhone = body['contactPhone'] as String?;
    if (contactPhone != null && !isValidPhone(contactPhone)) {
      return jsonError(
        'VALIDATION_ERROR',
        'contactPhone is not a valid phone number',
        status: 422,
      );
    }
    final message = body['message'] as String?;
    if (message != null && capString(message, 500) == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'message must be at most 500 characters',
        status: 422,
      );
    }

    final lead = store.createLead(body, userId: auth.userId);
    return jsonOk(lead, status: 201);
  });

  router.patch('/v1/leads/<id>/status', (Request req, String id) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final body = await req.readJson();
    final status = body['status'] as String?;
    if (!isOneOf(status, kAllowedLeadStatuses)) {
      return jsonError(
        'VALIDATION_ERROR',
        'status must be one of ${kAllowedLeadStatuses.join(', ')}',
        status: 422,
      );
    }
    final existing = store.leadById(id);
    if (existing == null) {
      return jsonError('NOT_FOUND', 'Lead $id not found', status: 404);
    }
    // Ownership: the buyer who created the lead, a system admin, or the
    // residence admin who owns the lead's project. A residence admin must NOT
    // be able to touch leads belonging to another developer's project
    // (previously `auth.isAdmin` let *any* residence admin edit *any* lead).
    final ownsLead = existing['userId'] == auth.userId;
    final project = store.projectById(existing['projectId'] as String? ?? '');
    final managesProjectLead =
        auth.isSystemAdmin ||
        (auth.isResidenceAdmin &&
            project != null &&
            store.ownsProject(auth.userId, project));
    if (!ownsLead && !managesProjectLead) {
      return jsonError('FORBIDDEN', 'Not your lead', status: 403);
    }
    final lead = store.updateLeadStatus(id, status!);
    return jsonOk(lead);
  });

  router.post('/v1/auth/otp/send', (Request req) async {
    final key = clientKeyFor(req);
    if (!otpRateLimiter.allow(key)) {
      final retryAfter = otpRateLimiter.retryAfterSeconds(key);
      return jsonError(
        'RATE_LIMITED',
        'Too many OTP requests, please try again later',
        status: 429,
        extraHeaders: {'Retry-After': '$retryAfter'},
      );
    }

    final body = await req.readJson();
    final rawPhone = (body['phone'] as String?)?.trim();
    if (rawPhone == null || rawPhone.isEmpty) {
      return jsonError('VALIDATION_ERROR', 'phone is required', status: 422);
    }
    if (!isValidPhone(rawPhone)) {
      return jsonError(
        'VALIDATION_ERROR',
        'phone is not a valid phone number',
        status: 422,
      );
    }
    final phone = normalizePhone(rawPhone);
    final requestId = await store.createOtpRequest(phone);
    // Security: the OTP is NEVER returned in the HTTP response. In dev the
    // fixed code is logged to stderr by SmsService; production always sends
    // it over SMS via Eskiz.
    return jsonOk(<String, dynamic>{'requestId': requestId});
  });

  router.post('/v1/auth/otp/verify', (Request req) async {
    final key = clientKeyFor(req);
    if (!otpVerifyRateLimiter.allow(key)) {
      final retryAfter = otpVerifyRateLimiter.retryAfterSeconds(key);
      return jsonError(
        'RATE_LIMITED',
        'Too many verification attempts, please try again later',
        status: 429,
        extraHeaders: {'Retry-After': '$retryAfter'},
      );
    }

    final body = await req.readJson();
    final requestId = body['requestId'] as String?;
    final code = body['code'] as String?;
    if (requestId == null || code == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'requestId and code are required',
        status: 422,
      );
    }
    final result = store.verifyOtp(requestId: requestId, code: code);
    if (!result.isSuccess) {
      if (result.error == OtpVerifyError.tooManyAttempts) {
        return jsonError(
          'TOO_MANY_ATTEMPTS',
          'Too many incorrect codes. Request a new code.',
          status: 429,
        );
      }
      return jsonError('INVALID_CODE', 'Invalid or expired code', status: 401);
    }
    return jsonOk({
      'accessToken': result.accessToken,
      'refreshToken': result.refreshToken,
      'user': result.user,
    });
  });

  mountAdminRoutes(router, store, refreshLimiter: refreshRateLimiter);

  // Live-update WebSocket. Requires a valid Bearer token (via the
  // `Authorization` header resolved by authMiddleware, or an `access_token`
  // query param since browsers can't set headers on the WS handshake). The
  // subscriber's admin status is captured so lead (CRM/PII) events are only
  // delivered to admins — see Store._broadcast.
  router.get('/v1/ws', (Request req) {
    var auth = req.auth;
    if (auth == null) {
      final token =
          req.url.queryParameters['access_token'] ??
          req.url.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        final user = store.userForAccessToken(token);
        if (user != null) {
          auth = AuthContext(accessToken: token, user: user);
        }
      }
    }
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required for the live-update socket',
        status: 401,
      );
    }
    final isAdmin = auth.isAdmin;
    final wsHandler = webSocketHandler((webSocket, protocol) {
      store.addSocket(webSocket, isAdmin: isAdmin);
    });
    return wsHandler(req);
  });

  return Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      // Outermost handler-side guard: everything below it (auth, ban check,
      // routes) is guaranteed to answer with the JSON envelope.
      .addMiddleware(errorEnvelopeMiddleware())
      .addMiddleware(authMiddleware(store))
      .addMiddleware(banGuardMiddleware())
      .addHandler(router.call);
}

/// Whether the process is running inside a container. Docker creates
/// `/.dockerenv`; Podman creates `/run/.containerenv`.
bool runningInContainer() {
  if (Platform.isWindows) return false;
  return File('/.dockerenv').existsSync() ||
      File('/run/.containerenv').existsSync();
}

/// Whether the deployment must read the client IP from `X-Forwarded-For`.
///
/// True when requests cannot arrive directly: binding loopback puts a reverse
/// proxy in front, and a container sees the bridge gateway (or, under host
/// networking, nginx on loopback) instead of the caller. In both cases an
/// untrusted `X-Forwarded-For` collapses every caller into a single rate-limit
/// bucket, so the first five OTP requests lock out the whole platform.
///
/// Split out from [assertProductionSecrets] so it can be tested without
/// touching the filesystem or the process environment.
bool requiresTrustedProxyHeaders({
  required String bindAddress,
  required bool inContainer,
}) {
  final bind = bindAddress.trim();
  final boundToLoopback =
      bind == '127.0.0.1' || bind == 'localhost' || bind == '::1';
  // A container binds 0.0.0.0 (the container is itself the boundary), so the
  // loopback check alone cannot catch it.
  return boundToLoopback || inContainer;
}

/// Fails fast (throws [StateError]) when `APP_ENV=production` but the secrets
/// required for a safe production deployment are missing or left at insecure
/// defaults. Called from `bin/server.dart` before the server starts serving.
/// A no-op outside production.
void assertProductionSecrets({SmsService? sms}) {
  if (!isProduction) return;
  final env = appEnv();
  final smsService = sms ?? SmsService();
  final problems = <String>[];

  if (smsService.isDevMode) {
    problems.add(
      'Eskiz SMS credentials (ESKIZ_TOKEN, or ESKIZ_EMAIL + ESKIZ_PASSWORD)',
    );
  }
  final adminPhones = env['SYSTEM_ADMIN_PHONES']?.trim();
  if (adminPhones == null || adminPhones.isEmpty) {
    problems.add('SYSTEM_ADMIN_PHONES');
  }
  if (bootstrapAdminEnabled) {
    final secret = env['BOOTSTRAP_ADMIN_SECRET']?.trim();
    if (secret == null ||
        secret.isEmpty ||
        secret == kDefaultBootstrapSecret) {
      problems.add(
        'a strong BOOTSTRAP_ADMIN_SECRET (bootstrap-admin is enabled)',
      );
    }
  }

  final dbHost = env['DB_HOST']?.trim() ?? '';
  if (dbHost.isEmpty) {
    problems.add('DB_HOST (production must not run in-memory-only)');
  }
  final dbPassword = env['DB_PASSWORD']?.trim() ?? '';
  if (dbPassword.isEmpty ||
      dbPassword == 'changeme' ||
      dbPassword.toUpperCase().startsWith('CHANGE_ME')) {
    problems.add('a strong DB_PASSWORD (not changeme / CHANGE_ME_*)');
  }
  final dbSsl = (env['DB_SSL'] ?? '').trim().toLowerCase();
  final isLoopbackDb =
      dbHost == 'localhost' || dbHost == '127.0.0.1' || dbHost == '::1';
  if (dbHost.isNotEmpty && !isLoopbackDb && dbSsl != 'true') {
    problems.add('DB_SSL=true (required for non-localhost PostgreSQL)');
  }

  final origins = env['ALLOWED_ORIGINS']?.trim() ?? '';
  if (origins.isEmpty || origins == '*') {
    problems.add(
      'ALLOWED_ORIGINS (comma-separated https:// origins; not empty and not *)',
    );
  }

  final inContainer = runningInContainer();
  final needsForwardedFor = requiresTrustedProxyHeaders(
    bindAddress: env['BIND_ADDRESS'] ?? '',
    inContainer: inContainer,
  );
  if (needsForwardedFor && !trustProxyHeaders) {
    final reason = inContainer
        ? 'running in a container, so requests never arrive directly'
        : 'BIND_ADDRESS is loopback, so the API is behind a reverse proxy';
    problems.add(
      'TRUST_PROXY=true ($reason and the client IP must come from '
      'X-Forwarded-For; make sure the proxy overwrites that header rather '
      'than appending to it)',
    );
  }

  if (problems.isNotEmpty) {
    throw StateError(
      'Refusing to start in production (APP_ENV=production): missing or '
      'insecure ${problems.join('; ')}. Configure these via the environment '
      'or server/.env before deploying. See docs/HOSTING_AHOST.md.',
    );
  }
}