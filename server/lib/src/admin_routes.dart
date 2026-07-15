import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'auth_context.dart';
import 'env_loader.dart';
import 'http_helpers.dart';
import 'rate_limiter.dart';
import 'store.dart';
import 'user_roles.dart';
import 'validation.dart';

const _uuid = Uuid();

/// Legacy default bootstrap secret. Kept only to *reject* it — it must never
/// be accepted, so an operator who forgot to set BOOTSTRAP_ADMIN_SECRET can't
/// be privilege-escalated with a well-known value.
const kDefaultBootstrapSecret = 'ibuild-dev';

/// Whether `POST /v1/platform/bootstrap-admin` is reachable. Enabled by
/// default outside production; in production it is disabled unless the
/// operator explicitly opts in with `BOOTSTRAP_ADMIN_ENABLED=true`.
bool get bootstrapAdminEnabled {
  if (!isProduction) return true;
  return (appEnv()['BOOTSTRAP_ADMIN_ENABLED'] ?? '').trim().toLowerCase() ==
      'true';
}

/// Whether the manual/dev subscription checkout may activate publishing for
/// free. Allowed outside production; in production a real payment is required
/// unless the operator explicitly opts in with `ALLOW_DEV_CHECKOUT=true`.
bool get devCheckoutAllowed {
  if (!isProduction) return true;
  return (appEnv()['ALLOW_DEV_CHECKOUT'] ?? '').trim().toLowerCase() == 'true';
}

const kAdminLeadStatuses = {
  'new',
  'contacted',
  'scheduled',
  'visited',
  'qualified',
  'won',
  'lost',
};

/// Registers B2B admin + platform routes on [router].
void mountAdminRoutes(Router router, Store store, {RateLimiter? refreshLimiter}) {
  final refreshRateLimiter =
      refreshLimiter ?? RateLimiter(30, const Duration(minutes: 5));

  // --- Auth helpers (refresh / logout / me) --------------------------------

  router.post('/v1/auth/refresh', (Request req) async {
    final key = clientKeyFor(req);
    if (!refreshRateLimiter.allow(key)) {
      final retryAfter = refreshRateLimiter.retryAfterSeconds(key);
      return jsonError(
        'RATE_LIMITED',
        'Too many token refreshes, please try again later',
        status: 429,
        extraHeaders: {'Retry-After': '$retryAfter'},
      );
    }
    final body = await req.readJson();
    final refreshToken = body['refreshToken'] as String?;
    if (refreshToken == null || refreshToken.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'refreshToken is required',
        status: 422,
      );
    }
    final result = store.refreshSession(refreshToken);
    if (result == null) {
      return jsonError('UNAUTHENTICATED', 'Invalid refresh token', status: 401);
    }
    return jsonOk({
      'accessToken': result.accessToken,
      'refreshToken': result.refreshToken,
      'user': result.user,
    });
  });

  router.post('/v1/auth/logout', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    store.revokeAccessToken(auth.accessToken);
    return jsonOk({'ok': true});
  });

  router.get('/v1/users/me', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    return jsonOk(auth.user);
  });

  router.get('/v1/users/me/leads', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final items = store.leadsForUser(auth.userId);
    return jsonOk(items, meta: {'total': items.length});
  });

  // --- Support tickets (any authenticated user) ---------------------------

  router.get('/v1/users/me/tickets', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final items = store.ticketsForUser(auth.userId);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.post('/v1/support/tickets', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final body = await req.readJson();
    final subject = body['subject'] as String?;
    final message = body['message'] as String?;
    if (subject == null || subject.trim().isEmpty) {
      return jsonError('VALIDATION_ERROR', 'subject is required', status: 422);
    }
    if (message == null || message.trim().isEmpty) {
      return jsonError('VALIDATION_ERROR', 'message is required', status: 422);
    }
    final category = body['category'] as String? ?? 'other';
    if (!Store.kTicketCategories.contains(category)) {
      return jsonError(
        'VALIDATION_ERROR',
        'category must be one of ${Store.kTicketCategories.join(', ')}',
        status: 422,
      );
    }
    final ticket = store.createTicket(
      userId: auth.userId,
      userName: auth.user['name'] as String?,
      userPhone: auth.phone,
      subject: subject,
      message: message,
      category: category,
    );
    return jsonOk(ticket, status: 201);
  });

  router.post('/v1/support/tickets/<id>/replies', (
    Request req,
    String id,
  ) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final ticket = store.ticketById(id);
    if (ticket == null) {
      return jsonError('NOT_FOUND', 'Ticket $id not found', status: 404);
    }
    if (!auth.isSystemAdmin && ticket['userId'] != auth.userId) {
      return jsonError('FORBIDDEN', 'Not your ticket', status: 403);
    }
    final body = await req.readJson();
    final message = body['message'] as String?;
    if (message == null || message.trim().isEmpty) {
      return jsonError('VALIDATION_ERROR', 'message is required', status: 422);
    }
    final updated = store.addTicketReply(
      id,
      message: message,
      authorName: (auth.user['name'] as String?) ?? auth.phone,
      isAdmin: auth.isSystemAdmin,
    );
    return jsonOk(updated);
  });

  // Favorites
  router.get('/v1/users/me/favorites', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    return jsonOk(store.favoritesForUser(auth.userId));
  });

  router.post('/v1/users/me/favorites', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final body = await req.readJson();
    final projectId = body['projectId'] as String?;
    if (projectId == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'projectId is required',
        status: 422,
      );
    }
    store.addFavorite(auth.userId, projectId);
    return jsonOk({'projectId': projectId}, status: 201);
  });

  router.delete('/v1/users/me/favorites/<projectId>', (
    Request req,
    String projectId,
  ) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    store.removeFavorite(auth.userId, projectId);
    return jsonOk({'ok': true});
  });

  // Saved searches
  router.get('/v1/users/me/saved-searches', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    return jsonOk(store.savedSearchesForUser(auth.userId));
  });

  router.post('/v1/users/me/saved-searches', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final body = await req.readJson();
    final label = body['label'] as String?;
    if (label == null || label.isEmpty) {
      return jsonError('VALIDATION_ERROR', 'label is required', status: 422);
    }
    final search = store.createSavedSearch(
      userId: auth.userId,
      label: label,
      filters: (body['filters'] as Map?)?.cast<String, dynamic>() ?? {},
      notifyOnMatch: body['notify'] as bool? ?? false,
    );
    return jsonOk(search, status: 201);
  });

  router.delete('/v1/users/me/saved-searches/<id>', (Request req, String id) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    store.deleteSavedSearch(auth.userId, id);
    return jsonOk({'ok': true});
  });

  // --- Developer registration (residence admin aspirants) -----------------

  router.post('/v1/developers', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final body = await req.readJson();

    String? requireString(String key, {int maxLen = 200}) {
      final v = sanitizeText(capString(body[key] as String?, maxLen));
      if (v == null || v.isEmpty) return null;
      return v;
    }

    final name = requireString('name', maxLen: 120);
    final legalName = requireString('legalName', maxLen: 200);
    final innRaw = requireString('inn', maxLen: 9);
    final accountKind = requireString('accountKind', maxLen: 64);
    final legalForm = requireString('legalForm', maxLen: 64);
    final legalAddress = requireString('legalAddress', maxLen: 300);
    final directorFullName = requireString('directorFullName', maxLen: 120);
    final directorPinfl = requireString('directorPinfl', maxLen: 14);
    final uboDeclared = body['uboDeclared'] == true;

    if (name == null ||
        legalName == null ||
        innRaw == null ||
        accountKind == null ||
        legalForm == null ||
        legalAddress == null ||
        directorFullName == null ||
        directorPinfl == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'name, legalName, inn, accountKind, legalForm, legalAddress, '
            'directorFullName, directorPinfl are required',
        status: 422,
      );
    }
    if (!isValidInn(innRaw)) {
      return jsonError(
        'VALIDATION_ERROR',
        'inn must be a 9-digit Uzbekistan STIR/INN',
        status: 422,
      );
    }
    if (!isValidPinfl(directorPinfl)) {
      return jsonError(
        'VALIDATION_ERROR',
        'directorPinfl must be a 14-digit PINFL',
        status: 422,
      );
    }
    if (!uboDeclared) {
      return jsonError(
        'VALIDATION_ERROR',
        'uboDeclared must be true (beneficial-owner acknowledgement)',
        status: 422,
      );
    }
    if (!{'property_developer', 'construction_company'}.contains(accountKind)) {
      return jsonError(
        'VALIDATION_ERROR',
        'accountKind must be property_developer or construction_company',
        status: 422,
      );
    }

    try {
      final developer = store.registerDeveloper(
        ownerUserId: auth.userId,
        name: name,
        legalName: legalName,
        inn: innRaw,
        phone: body['phone'] as String? ?? auth.phone,
        accountKind: accountKind,
        legalForm: legalForm,
        legalAddress: legalAddress,
        directorFullName: directorFullName,
        directorPinfl: directorPinfl,
        uboDeclared: uboDeclared,
        registrationNumber: capString(
          body['registrationNumber'] as String?,
          64,
        ),
        officeAddress: capString(body['officeAddress'] as String?, 300),
        region: capString(body['region'] as String?, 80),
        email: capString(body['email'] as String?, 120),
        website: capString(body['website'] as String?, 200),
        okedCode: capString(body['okedCode'] as String?, 16),
        directorPassport: capString(body['directorPassport'] as String?, 32),
        directorPhone: capString(body['directorPhone'] as String?, 32),
        directorEmail: capString(body['directorEmail'] as String?, 120),
        uboFullName: capString(body['uboFullName'] as String?, 120),
        constructionLicense: capString(
          body['constructionLicense'] as String?,
          64,
        ),
      );
      return jsonOk(developer, status: 201);
    } on StateError catch (e) {
      if (e.message == 'INN_TAKEN') {
        return jsonError(
          'CONFLICT',
          'This INN is already registered',
          status: 409,
        );
      }
      if (e.message == 'APPLICATION_EXISTS') {
        return jsonError(
          'CONFLICT',
          'You already have an application in review',
          status: 409,
        );
      }
      return jsonError('VALIDATION_ERROR', e.message, status: 422);
    }
  });

  router.get('/v1/developers/me', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final developer = store.developerForOwner(auth.userId);
    if (developer == null) {
      return jsonError('NOT_FOUND', 'No developer profile', status: 404);
    }
    final id = developer['id'] as String;
    return jsonOk({
      ...developer,
      'paymentStatus': store.paymentStatusForDeveloper(id),
      'subscription': store.subscriptionForDeveloper(id),
      'canPublish': store.hasActiveSubscription(id),
      'subscriptionPriceUsd': kBusinessSubscriptionUsd,
    });
  });

  router.patch('/v1/developers/me', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isResidenceAdmin && !auth.isSystemAdmin) {
      return jsonError('FORBIDDEN', 'Residence admin required', status: 403);
    }
    final body = await req.readJson();
    try {
      final updated = store.updateDeveloperProfile(auth.userId, body);
      if (updated == null) {
        return jsonError('NOT_FOUND', 'No developer profile', status: 404);
      }
      return jsonOk(updated);
    } on StateError catch (e) {
      final code = e.message;
      if (code == 'INN_TAKEN') {
        return jsonError(
          'CONFLICT',
          'This INN is already registered',
          status: 409,
        );
      }
      return jsonError('VALIDATION_ERROR', code, status: 422);
    }
  });

  router.post('/v1/developers/me/submit-for-review', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    try {
      final developer = store.submitDeveloperForReview(auth.userId);
      if (developer == null) {
        return jsonError('NOT_FOUND', 'No developer application', status: 404);
      }
      store.notifyAdmins(
        type: 'developer_submitted',
        title: 'Developer application submitted: ${developer['name']}',
        body: '${developer['name']} submitted their KYC application for review.',
        developerId: developer['id'] as String?,
        targetType: 'developer',
        targetId: developer['id'] as String?,
        actorUserId: auth.userId,
      );
      return jsonOk(developer);
    } on StateError catch (e) {
      if (e.message == 'INVALID_STATE') {
        return jsonError(
          'CONFLICT',
          'Application is not in a submittable state',
          status: 409,
        );
      }
      rethrow;
    }
  });

  router.get(
    '/v1/subscription-plans',
    (Request req) => jsonOk(kSubscriptionPlans),
  );

  // --- Documents API (developer verification / trust layer) --------------

  router.post('/v1/developers/me/documents', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    // Deliberately no `isResidenceAdmin` gate here (unlike `PATCH
    // /v1/developers/me`, which edits the post-approval public profile):
    // verification documents must be uploadable *before* approval — a
    // developer only becomes `residence_admin` once approved, and approval
    // itself requires these documents to already be accepted. Ownership via
    // `developerForOwner` below is the real access boundary, matching the
    // `GET` of this same resource.
    final developer = store.developerForOwner(auth.userId);
    if (developer == null) {
      return jsonError('NOT_FOUND', 'No developer profile', status: 404);
    }
    final developerId = developer['id'] as String;

    final contentType = req.headers['content-type'] ?? '';
    if (contentType.contains('multipart/form-data')) {
      final doc = await _handleMultipartDocument(
        req,
        store,
        developerId: developerId,
        uploadedBy: auth.userId,
      );
      if (doc == null) {
        return jsonError(
          'VALIDATION_ERROR',
          'file and a valid type '
              '(${kAllowedDocumentTypes.join(', ')}) are required',
          status: 422,
        );
      }
      store.notifyAdmins(
        type: 'document_uploaded',
        title: 'Document submitted: ${doc['type']}',
        body: '${developer['name']} uploaded a "${doc['type']}" document for review.',
        developerId: developerId,
        targetType: 'document',
        targetId: doc['id'] as String?,
        actorUserId: auth.userId,
      );
      return jsonOk(doc, status: 201);
    }

    final body = await req.readJson();
    final type = body['type'] as String?;
    final fileUrl = body['fileUrl'] as String?;
    if (type == null ||
        !kAllowedDocumentTypes.contains(type) ||
        fileUrl == null ||
        fileUrl.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'type (one of ${kAllowedDocumentTypes.join(', ')}) and fileUrl '
            'are required',
        status: 422,
      );
    }
    final doc = store.addDocument(
      developerId: developerId,
      projectId: body['projectId'] as String?,
      type: type,
      fileUrl: fileUrl,
      uploadedBy: auth.userId,
    );
    store.notifyAdmins(
      type: 'document_uploaded',
      title: 'Document submitted: $type',
      body: '${developer['name']} uploaded a "$type" document for review.',
      developerId: developerId,
      targetType: 'document',
      targetId: doc['id'] as String?,
      actorUserId: auth.userId,
    );
    return jsonOk(doc, status: 201);
  });

  router.get('/v1/developers/me/documents', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final developer = store.developerForOwner(auth.userId);
    if (developer == null) {
      return jsonError('NOT_FOUND', 'No developer profile', status: 404);
    }
    final items = store.documentsForDeveloper(developer['id'] as String);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.get('/v1/platform/developers/<id>/documents', (
    Request req,
    String id,
  ) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    if (store.developerById(id) == null) {
      return jsonError('NOT_FOUND', 'Developer $id not found', status: 404);
    }
    final items = store.documentsForDeveloper(id);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.patch('/v1/platform/documents/<id>', (Request req, String id) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final status = body['status'] as String?;
    if (status == null || !kDocumentStatuses.contains(status)) {
      return jsonError(
        'VALIDATION_ERROR',
        'status must be one of ${kDocumentStatuses.join(', ')}',
        status: 422,
      );
    }
    final rejectReason = capString(body['rejectReason'] as String?, 500)
        ?.trim();
    if (status == 'rejected' &&
        (rejectReason == null || rejectReason.isEmpty)) {
      return jsonError(
        'VALIDATION_ERROR',
        'rejectReason is required when rejecting a document',
        status: 422,
      );
    }
    final doc = store.reviewDocument(
      id,
      status: status,
      rejectReason: rejectReason,
      reviewedBy: req.auth!.userId,
    );
    if (doc == null) {
      return jsonError('NOT_FOUND', 'Document $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'document.$status',
      targetType: 'document',
      targetId: id,
      detail: rejectReason,
    );
    return jsonOk(doc);
  });

  router.post('/v1/developers/me/subscription/checkout', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isResidenceAdmin && !auth.isSystemAdmin) {
      return jsonError('FORBIDDEN', 'Residence admin required', status: 403);
    }
    final body = await req.readJson();
    final planId = body['planId'] as String?;
    if (planId != null && subscriptionPlanById(planId) == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'planId must be one of ${kSubscriptionPlans.map((p) => p['id']).join(', ')}',
        status: 422,
      );
    }
    // Manual/dev checkout stub — Payme/Click can replace this later. Free
    // activation is gated: in production it requires a completed payment
    // (or an explicit ALLOW_DEV_CHECKOUT opt-in), so publishing can't be
    // unlocked for free by hitting this endpoint.
    if (!devCheckoutAllowed) {
      return jsonError(
        'PAYMENT_REQUIRED',
        'Online payment is required to activate a subscription',
        status: 402,
      );
    }
    final subscription = store.activateSubscription(
      auth.userId,
      planId: planId,
    );
    if (subscription == null) {
      return jsonError(
        'FORBIDDEN',
        'Approved organization profile required',
        status: 403,
      );
    }
    store.audit(
      actorUserId: auth.userId,
      action: 'subscription.activate',
      targetType: 'subscription',
      targetId: subscription['id'] as String?,
      detail: '${subscription['planId']} \$${subscription['amountUsd']}',
    );
    return jsonOk({
      'subscription': subscription,
      'amountUsd': subscription['amountUsd'],
      'message': 'Subscription active for 30 days. Publishing is unlocked.',
    });
  });

  router.get('/v1/developers/me/projects', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isResidenceAdmin) {
      return jsonError('FORBIDDEN', 'Residence admin required', status: 403);
    }
    final items = store.projectsForDeveloperOwner(auth.userId);
    return jsonOk(
      items.map(store.summarize).toList(),
      meta: {'total': items.length},
    );
  });

  router.post('/v1/developers/me/projects', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isResidenceAdmin) {
      return jsonError('FORBIDDEN', 'Residence admin required', status: 403);
    }
    final body = await req.readJson();
    final name = body['name'] as String?;
    if (name == null || name.isEmpty) {
      return jsonError('VALIDATION_ERROR', 'name is required', status: 422);
    }
    final project = store.createProjectForOwner(
      ownerUserId: auth.userId,
      input: body,
    );
    if (project == null) {
      return jsonError(
        'FORBIDDEN',
        'Approved developer profile required',
        status: 403,
      );
    }
    final devName = (project['developer'] as Map?)?['name']?.toString();
    store.notifyAdmins(
      type: 'project_created',
      title: 'New project created: ${project['name']}',
      body: devName == null
          ? 'A new project draft was created.'
          : '$devName created a new project draft.',
      developerId: (project['developer'] as Map?)?['id'] as String?,
      projectId: project['id'] as String?,
      targetType: 'project',
      targetId: project['id'] as String?,
      actorUserId: auth.userId,
    );
    return jsonOk(project, status: 201);
  });

  // --- Project admin ------------------------------------------------------

  router.get('/v1/admin/projects/<id>', (Request req, String id) {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    return jsonOk(project);
  });

  router.patch('/v1/admin/projects/<id>', (Request req, String id) async {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final body = await req.readJson();
    try {
      final updated = store.updateProject(id, body);
      // Only notify when a residence admin edits their own project — a
      // system admin's own moderation actions (approve/reject/publish/...)
      // already surface via the audit log and shouldn't self-notify.
      if (!auth.isSystemAdmin && updated != null) {
        store.notifyAdmins(
          type: 'project_updated',
          title: 'Project updated: ${updated['name']}',
          body: 'Changed fields: ${body.keys.join(', ')}',
          developerId: (updated['developer'] as Map?)?['id'] as String?,
          projectId: id,
          targetType: 'project',
          targetId: id,
          actorUserId: auth.userId,
        );
      }
      return jsonOk(updated);
    } on StateError catch (e) {
      if (e.message == 'SUBSCRIPTION_REQUIRED') {
        return jsonError(
          'PAYMENT_REQUIRED',
          'Active \$$kBusinessSubscriptionUsd/mo subscription required to publish',
          status: 402,
        );
      }
      rethrow;
    }
  });

  router.delete('/v1/admin/projects/<id>', (Request req, String id) async {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    try {
      final deleted = await store.deleteProject(id);
      if (deleted == null) {
        return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
      }
      store.audit(
        actorUserId: auth.userId,
        action: 'project.delete',
        targetType: 'project',
        targetId: id,
        detail: deleted['name']?.toString(),
      );
      return jsonOk({'id': id, 'deleted': true});
    } catch (e) {
      final hint = store.persistenceRequired && !store.hasPersistence
          ? 'PostgreSQL is configured but the API is in-memory only — '
                'restart the API after the database is ready.'
          : null;
      return jsonError(
        'PERSISTENCE_ERROR',
        hint == null
            ? 'Failed to permanently delete project: $e'
            : '$hint ($e)',
        status: 500,
      );
    }
  });

  router.post('/v1/admin/projects/<id>/unpublish', (Request req, String id) {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final updated = store.updateProject(id, {'isPublished': false});
    store.audit(
      actorUserId: auth.userId,
      action: 'project.unpublish',
      targetType: 'project',
      targetId: id,
    );
    return jsonOk(updated);
  });

  router.post('/v1/admin/projects/<id>/publish', (Request req, String id) {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final status = project['moderationStatus'] as String? ?? 'draft';
    if (status != 'approved') {
      return jsonError(
        'CONFLICT',
        'Only approved projects can be published directly — submit for review first',
        status: 409,
      );
    }
    try {
      final updated = store.updateProject(id, {'isPublished': true});
      store.audit(
        actorUserId: auth.userId,
        action: 'project.publish',
        targetType: 'project',
        targetId: id,
      );
      return jsonOk(updated);
    } on StateError catch (e) {
      if (e.message == 'SUBSCRIPTION_REQUIRED') {
        return jsonError(
          'PAYMENT_REQUIRED',
          'Active \$$kBusinessSubscriptionUsd/mo subscription required to publish',
          status: 402,
        );
      }
      rethrow;
    }
  });

  router.post('/v1/admin/projects/<id>/submit-for-review', (
    Request req,
    String id,
  ) {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    try {
      final updated = store.submitProjectForReview(id);
      if (updated == null) {
        return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
      }
      final devName = (updated['developer'] as Map?)?['name']?.toString();
      store.notifyAdmins(
        type: 'project_submitted',
        title: 'Project submitted for review: ${updated['name']}',
        body: devName == null
            ? 'A project was submitted for moderation.'
            : '$devName submitted this project for moderation.',
        developerId: (updated['developer'] as Map?)?['id'] as String?,
        projectId: id,
        targetType: 'project',
        targetId: id,
        actorUserId: auth.userId,
      );
      return jsonOk(updated);
    } on StateError catch (e) {
      if (e.message == 'INVALID_STATE') {
        return jsonError(
          'CONFLICT',
          'Project is not in a submittable state',
          status: 409,
        );
      }
      rethrow;
    }
  });

  router.post('/v1/admin/projects/<id>/buildings', (
    Request req,
    String id,
  ) async {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final body = await req.readJson();
    final building = store.addBuilding(id, body);
    return jsonOk(building, status: 201);
  });

  router.post('/v1/admin/projects/<id>/units', (Request req, String id) async {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final body = await req.readJson();
    final unit = store.addUnit(id, body);
    if (unit == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'buildingId is required',
        status: 422,
      );
    }
    return jsonOk(unit, status: 201);
  });

  router.patch('/v1/admin/units/<uid>', (Request req, String uid) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final found = store.unitById(uid);
    if (found == null) {
      return jsonError('NOT_FOUND', 'Unit $uid not found', status: 404);
    }
    if (!_canManageProject(store, auth, found.project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final body = await req.readJson();
    try {
      final unit = store.updateUnit(uid, body);
      return jsonOk(unit);
    } on UnitConflictException catch (e) {
      return jsonError(
        'UNIT_CONFLICT',
        'This unit was modified by someone else — reload and retry',
        status: 409,
        data: {'currentVersion': e.currentVersion, 'unit': e.unit},
      );
    }
  });

  router.post('/v1/admin/units/<uid>/media', (Request req, String uid) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final found = store.unitById(uid);
    if (found == null) {
      return jsonError('NOT_FOUND', 'Unit $uid not found', status: 404);
    }
    if (!_canManageProject(store, auth, found.project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }

    final contentType = req.headers['content-type'] ?? '';
    if (contentType.contains('multipart/form-data')) {
      final media = await _handleMultipartMedia(req, store, unitId: uid);
      if (media == null) {
        return jsonError('VALIDATION_ERROR', 'file is required', status: 422);
      }
      return jsonOk(media, status: 201);
    }

    final body = await req.readJson();
    final url = body['url'] as String?;
    if (url == null || url.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'url or multipart file required',
        status: 422,
      );
    }
    final media = store.addUnitMedia(
      uid,
      url: url,
      type: body['type'] as String? ?? 'photo',
      isCover: body['isCover'] as bool? ?? false,
    );
    return jsonOk(media, status: 201);
  });

  // --- Photo reports API (construction progress) --------------------------

  router.post('/v1/admin/projects/<id>/photo-reports', (
    Request req,
    String id,
  ) async {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }

    String? url;
    String? takenAtRaw;
    int? progressPercent;
    String? buildingId;

    final contentType = req.headers['content-type'] ?? '';
    if (contentType.contains('multipart/form-data')) {
      final parsed = await _handleMultipartPhotoReport(req);
      if (parsed == null) {
        return jsonError('VALIDATION_ERROR', 'file is required', status: 422);
      }
      url = parsed.url;
      takenAtRaw = parsed.takenAt;
      progressPercent = parsed.progressPercent;
      buildingId = parsed.buildingId;
    } else {
      final body = await req.readJson();
      url = body['url'] as String?;
      takenAtRaw = body['takenAt'] as String?;
      progressPercent = (body['progressPercent'] as num?)?.toInt();
      buildingId = body['buildingId'] as String?;
    }

    if (url == null || url.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'url or multipart file required',
        status: 422,
      );
    }

    DateTime takenAt;
    bool takenAtIsManual;
    if (takenAtRaw != null && takenAtRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(takenAtRaw);
      if (parsed == null) {
        return jsonError(
          'VALIDATION_ERROR',
          'takenAt must be a valid date',
          status: 422,
        );
      }
      takenAt = parsed;
      takenAtIsManual = true;
    } else {
      takenAt = DateTime.now();
      takenAtIsManual = false;
    }
    if (progressPercent != null &&
        (progressPercent < 0 || progressPercent > 100)) {
      return jsonError(
        'VALIDATION_ERROR',
        'progressPercent must be between 0 and 100',
        status: 422,
      );
    }

    final report = store.addPhotoReport(
      projectId: id,
      buildingId: buildingId,
      photoUrl: url,
      takenAt: takenAt,
      takenAtIsManual: takenAtIsManual,
      progressPercent: progressPercent,
      uploadedBy: auth.userId,
    );
    return jsonOk(report, status: 201);
  });

  router.delete('/v1/admin/photo-reports/<id>', (Request req, String id) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final report = store.photoReportById(id);
    if (report == null) {
      return jsonError('NOT_FOUND', 'Photo report $id not found', status: 404);
    }
    final project = store.projectById(report['projectId'] as String);
    if (project == null || !_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    store.deletePhotoReport(id);
    return jsonOk({'id': id, 'deleted': true});
  });

  router.get('/v1/admin/projects/<id>/offers', (Request req, String id) {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    return jsonOk(project['offers']);
  });

  router.put('/v1/admin/projects/<id>/offers', (Request req, String id) async {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final body = await req.readJson();
    final offers = (body['offers'] as List?)
        ?.cast<Map>()
        .map((o) => o.cast<String, dynamic>())
        .toList();
    if (offers == null) {
      return jsonError(
        'VALIDATION_ERROR',
        'offers array is required',
        status: 422,
      );
    }
    const allowedTypes = {'discount', 'installment', 'rent_promo'};
    for (final offer in offers) {
      if (!allowedTypes.contains(offer['type'])) {
        return jsonError(
          'VALIDATION_ERROR',
          'offer type must be one of ${allowedTypes.join(', ')}',
          status: 422,
        );
      }
    }
    final updated = store.setProjectOffers(id, offers);
    return jsonOk(updated?['offers']);
  });

  router.get('/v1/admin/projects/<id>/analytics', (Request req, String id) {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    return jsonOk(store.projectAnalytics(id));
  });

  router.get('/v1/admin/projects/<id>/leads', (Request req, String id) {
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
    if (!_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final ownerFilter = req.url.queryParameters['owner'];
    final items = store.filterLeadsByOwner(
      store.leadsForProject(id),
      ownerFilter: ownerFilter,
      currentUserId: auth.userId,
    );
    return jsonOk(items, meta: {'total': items.length});
  });

  router.get('/v1/admin/crm-assignees', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isSystemAdmin && !auth.isResidenceAdmin) {
      return jsonError('FORBIDDEN', 'Admin access required', status: 403);
    }
    final items = store.crmAssignees();
    return jsonOk(items, meta: {'total': items.length});
  });

  router.get('/v1/admin/leads/<lid>/events', (Request req, String lid) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final lead = store.leadById(lid);
    if (lead == null) {
      return jsonError('NOT_FOUND', 'Lead $lid not found', status: 404);
    }
    final project = store.projectById(lead['projectId'] as String);
    if (project == null || !_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final items = await store.fetchLeadEvents(lid);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.post('/v1/admin/leads/<lid>/transfer', (
    Request req,
    String lid,
  ) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final lead = store.leadById(lid);
    if (lead == null) {
      return jsonError('NOT_FOUND', 'Lead $lid not found', status: 404);
    }
    final project = store.projectById(lead['projectId'] as String);
    if (project == null || !_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final body = await req.readJson();
    final toUserId = (body['toUserId'] as String?)?.trim();
    if (toUserId == null || toUserId.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'toUserId is required',
        status: 422,
      );
    }
    try {
      final updated = await store.transferLead(
        lid,
        toUserId: toUserId,
        actorUserId: auth.userId,
        note: body['note'] as String?,
      );
      store.audit(
        actorUserId: auth.userId,
        action: 'lead.transfer',
        targetType: 'lead',
        targetId: lid,
        detail: 'to $toUserId',
      );
      return jsonOk(updated);
    } on StateError catch (e) {
      if (e.message == 'USER_NOT_FOUND') {
        return jsonError('NOT_FOUND', 'Manager user not found', status: 404);
      }
      rethrow;
    }
  });

  router.patch('/v1/admin/leads/<lid>', (Request req, String lid) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final lead = store.leadById(lid);
    if (lead == null) {
      return jsonError('NOT_FOUND', 'Lead $lid not found', status: 404);
    }
    final project = store.projectById(lead['projectId'] as String);
    if (project == null || !_canManageProject(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }
    final body = await req.readJson();
    final status = body['status'] as String?;
    if (status != null && !isOneOf(status, kAdminLeadStatuses)) {
      return jsonError(
        'VALIDATION_ERROR',
        'status must be one of ${kAdminLeadStatuses.join(', ')}',
        status: 422,
      );
    }
    const allowedScores = {'hot', 'warm', 'cold'};
    final score = body['score'] as String?;
    if (score != null && !allowedScores.contains(score)) {
      return jsonError(
        'VALIDATION_ERROR',
        'score must be one of ${allowedScores.join(', ')}',
        status: 422,
      );
    }
    try {
      final updated = await store.updateLeadAdmin(
        lid,
        status: status,
        assignedManager: body['assignedManager'] as String?,
        ownerUserId: body.containsKey('ownerUserId')
            ? body['ownerUserId'] as String?
            : null,
        clearOwner:
            body.containsKey('ownerUserId') && body['ownerUserId'] == null,
        actorUserId: auth.userId,
        notes: body['notes'] as String?,
        tags: (body['tags'] as List?)?.cast<String>(),
        score: score,
      );
      if (body.containsKey('ownerUserId')) {
        store.audit(
          actorUserId: auth.userId,
          action: body['ownerUserId'] == null ? 'lead.unassign' : 'lead.assign',
          targetType: 'lead',
          targetId: lid,
          detail: body['ownerUserId']?.toString(),
        );
      }
      return jsonOk(updated);
    } on StateError catch (e) {
      if (e.message == 'USER_NOT_FOUND') {
        return jsonError('NOT_FOUND', 'Manager user not found', status: 404);
      }
      rethrow;
    }
  });

  // --- Platform admin -----------------------------------------------------

  router.get('/v1/platform/developers/pending', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.pendingDevelopers();
    return jsonOk(items, meta: {'total': items.length});
  });

  router.patch('/v1/platform/developers/<id>/approve', (
    Request req,
    String id,
  ) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    if (store.developerById(id) == null) {
      return jsonError('NOT_FOUND', 'Developer $id not found', status: 404);
    }
    // Documents API contract: approval requires every required document
    // type to be reviewed and accepted — this is what makes the "Verified"
    // badge on B2C actually mean "documents checked".
    if (!store.hasAllRequiredDocumentsAccepted(id)) {
      return jsonError(
        'VALIDATION_ERROR',
        'All required documents '
            '(${kRequiredDocumentTypes.join(', ')}) must be accepted '
            'before approval',
        status: 422,
      );
    }
    final developer = store.setDeveloperVerification(id, 'approved');
    if (developer == null) {
      return jsonError('NOT_FOUND', 'Developer $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'developer.approve',
      targetType: 'developer',
      targetId: id,
    );
    return jsonOk(developer);
  });

  router.patch('/v1/platform/developers/<id>/reject', (
    Request req,
    String id,
  ) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final reason = body['reason'] as String? ?? 'Rejected';
    final developer = store.setDeveloperVerification(
      id,
      'rejected',
      rejectionReason: reason,
    );
    if (developer == null) {
      return jsonError('NOT_FOUND', 'Developer $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'developer.reject',
      targetType: 'developer',
      targetId: id,
      detail: reason,
    );
    return jsonOk(developer);
  });

  // Free-form transition across the whole review pipeline (pending ->
  // in_review -> approved/rejected, and back again if an admin changes their
  // mind) — the generalization of the two endpoints above, driving the B2B
  // "change status" control instead of just a binary approve/reject.
  router.patch('/v1/platform/developers/<id>/status', (
    Request req,
    String id,
  ) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final status = body['status'] as String?;
    if (status == null || !kDeveloperVerificationStatuses.contains(status)) {
      return jsonError(
        'VALIDATION_ERROR',
        'status must be one of ${kDeveloperVerificationStatuses.join(', ')}',
        status: 422,
      );
    }
    final reason = capString(body['reason'] as String?, 500)?.trim();
    if (status == 'rejected' && (reason == null || reason.isEmpty)) {
      return jsonError(
        'VALIDATION_ERROR',
        'reason is required when declining an application',
        status: 422,
      );
    }
    final developer = store.setDeveloperVerification(
      id,
      status,
      rejectionReason: status == 'rejected' ? reason : null,
    );
    if (developer == null) {
      return jsonError('NOT_FOUND', 'Developer $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'developer.status.$status',
      targetType: 'developer',
      targetId: id,
      detail: status == 'rejected' ? reason : null,
    );
    return jsonOk(developer);
  });

  router.get('/v1/platform/projects/pending', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.pendingProjects();
    return jsonOk(
      items.map(store.summarize).toList(),
      meta: {'total': items.length},
    );
  });

  router.get('/v1/platform/projects/published', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.publishedProjects;
    return jsonOk(
      items.map(store.summarize).toList(),
      meta: {'total': items.length},
    );
  });

  // Full ЖК/business-centre roster — any status — for the platform admin's
  // "ЖК" oversight list (Konseptsiya: admins inspect how a listing is
  // furnished/attached rather than owning projects of their own).
  router.get('/v1/platform/projects', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.projects;
    return jsonOk(
      items.map(store.summarize).toList(),
      meta: {'total': items.length},
    );
  });

  // Platform-wide lead CRM — every lead across every project, for the
  // "CRM" section (as opposed to `/admin/projects/:id/leads`, which is
  // scoped to one residence admin's own project).
  router.get('/v1/platform/leads', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final ownerFilter = req.url.queryParameters['owner'];
    final items = store.filterLeadsByOwner(
      store.leads,
      ownerFilter: ownerFilter,
      currentUserId: req.auth!.userId,
    );
    return jsonOk(items, meta: {'total': items.length});
  });

  router.patch('/v1/platform/projects/<id>/moderate', (
    Request req,
    String id,
  ) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final decision = body['decision'] as String?;
    const allowed = {'approve', 'reject', 'unpublish', 'warn'};
    if (decision == null || !allowed.contains(decision)) {
      return jsonError(
        'VALIDATION_ERROR',
        'decision must be one of: approve, reject, unpublish, warn',
        status: 422,
      );
    }
    try {
      final project = store.moderateProject(
        id,
        decision: decision,
        note: body['note'] as String?,
        platformOverride: true,
      );
      if (project == null) {
        return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
      }
      store.audit(
        actorUserId: req.auth!.userId,
        action: 'project.$decision',
        targetType: 'project',
        targetId: id,
        detail: body['note'] as String?,
      );
      return jsonOk(project);
    } on StateError catch (e) {
      if (e.message == 'SUBSCRIPTION_REQUIRED') {
        return jsonError(
          'PAYMENT_REQUIRED',
          'Business must have an active \$$kBusinessSubscriptionUsd/mo '
              'subscription before publishing',
          status: 402,
        );
      }
      if (e.message == 'NOTE_REQUIRED') {
        return jsonError(
          'VALIDATION_ERROR',
          'note is required for warn',
          status: 422,
        );
      }
      if (e.message == 'INVALID_DECISION') {
        return jsonError(
          'VALIDATION_ERROR',
          'decision must be one of: approve, reject, unpublish, warn',
          status: 422,
        );
      }
      rethrow;
    }
  });

  router.get('/v1/platform/businesses', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.platformBusinesses();
    return jsonOk(items, meta: {'total': items.length});
  });

  router.get('/v1/platform/users', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.allUsers();
    return jsonOk(items, meta: {'total': items.length});
  });

  router.patch('/v1/platform/users/<id>/role', (Request req, String id) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final role = body['role'] as String?;
    const allowed = {
      UserRole.ordinaryUser,
      UserRole.systemAdmin,
      UserRole.residenceAdmin,
    };
    if (role == null || !allowed.contains(role)) {
      return jsonError('VALIDATION_ERROR', 'Invalid role', status: 422);
    }
    final user = store.setUserRole(id, role);
    if (user == null) {
      return jsonError('NOT_FOUND', 'User $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'user.role',
      targetType: 'user',
      targetId: id,
      detail: role,
    );
    return jsonOk(user);
  });

  router.patch('/v1/platform/users/<id>/ban', (Request req, String id) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final reason = (body['reason'] as String?)?.trim();
    final bannedByName = (body['bannedByName'] as String?)?.trim();
    if (reason == null || reason.isEmpty) {
      return jsonError('VALIDATION_ERROR', 'reason is required', status: 422);
    }
    if (bannedByName == null || bannedByName.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'bannedByName is required',
        status: 422,
      );
    }
    final user = store.banUser(id, reason: reason, bannedByName: bannedByName);
    if (user == null) {
      return jsonError('NOT_FOUND', 'User $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'user.ban',
      targetType: 'user',
      targetId: id,
      detail: '$bannedByName: $reason',
    );
    return jsonOk(user);
  });

  router.patch('/v1/platform/users/<id>/unban', (Request req, String id) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final user = store.unbanUser(id);
    if (user == null) {
      return jsonError('NOT_FOUND', 'User $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'user.unban',
      targetType: 'user',
      targetId: id,
    );
    return jsonOk(user);
  });

  router.get('/v1/platform/analytics', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    return jsonOk(store.platformAnalytics());
  });

  // --- Admin notifications (developer changes / submitted docs) -----------

  router.get('/v1/platform/notifications', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final unreadOnly =
        req.url.queryParameters['unreadOnly']?.toLowerCase() == 'true';
    final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 200;
    final items = store.adminNotifications(unreadOnly: unreadOnly, limit: limit);
    return jsonOk(
      items,
      meta: {
        'total': items.length,
        'unread': store.unreadNotificationCount(),
      },
    );
  });

  router.get('/v1/platform/notifications/unread-count', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    return jsonOk({'count': store.unreadNotificationCount()});
  });

  router.post('/v1/platform/notifications/<id>/read', (
    Request req,
    String id,
  ) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final n = store.markNotificationRead(id);
    if (n == null) {
      return jsonError('NOT_FOUND', 'Notification $id not found', status: 404);
    }
    return jsonOk(n);
  });

  router.post('/v1/platform/notifications/read-all', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final count = store.markAllNotificationsRead();
    return jsonOk({'marked': count});
  });

  // --- Reviews moderation (Konseptsiya §9) --------------------------------

  router.get('/v1/platform/reviews/pending', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.reviewsForModeration();
    return jsonOk(items, meta: {'total': items.length});
  });

  router.patch('/v1/platform/reviews/<id>/moderate', (
    Request req,
    String id,
  ) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final decision = body['decision'] as String?; // keep | remove
    if (decision != 'keep' && decision != 'remove') {
      return jsonError(
        'VALIDATION_ERROR',
        'decision must be keep or remove',
        status: 422,
      );
    }
    final review = store.moderateReview(id, remove: decision == 'remove');
    if (review == null) {
      return jsonError('NOT_FOUND', 'Review $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'review.$decision',
      targetType: 'review',
      targetId: id,
    );
    return jsonOk(review);
  });

  router.post('/v1/reviews/<id>/flag', (Request req, String id) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final review = store.flagReview(id);
    if (review == null) {
      return jsonError('NOT_FOUND', 'Review $id not found', status: 404);
    }
    return jsonOk(review);
  });

  // --- Owner rental listings moderation (Konseptsiya §5, §8) --------------

  router.get('/v1/platform/rental-listings/pending', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final items = store.pendingRentalListings();
    return jsonOk(items, meta: {'total': items.length});
  });

  router.patch('/v1/platform/rental-listings/<id>/moderate', (
    Request req,
    String id,
  ) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final decision = body['decision'] as String?; // approve | reject
    if (decision != 'approve' && decision != 'reject') {
      return jsonError(
        'VALIDATION_ERROR',
        'decision must be approve or reject',
        status: 422,
      );
    }
    final listing = store.moderateRentalListing(
      id,
      approve: decision == 'approve',
      note: body['note'] as String?,
    );
    if (listing == null) {
      return jsonError(
        'NOT_FOUND',
        'Rental listing $id not found',
        status: 404,
      );
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'rental_listing.$decision',
      targetType: 'rental_listing',
      targetId: id,
      detail: body['note'] as String?,
    );
    return jsonOk(listing);
  });

  router.get('/v1/platform/audit-log', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 100;
    final items = store.auditLog.take(limit).toList();
    return jsonOk(items, meta: {'total': store.auditLog.length});
  });

  // --- Support tickets (platform admin triage) ----------------------------

  router.get('/v1/platform/tickets', (Request req) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final status = req.url.queryParameters['status'];
    final items = store.allTickets(status: status);
    return jsonOk(items, meta: {'total': items.length});
  });

  router.get('/v1/platform/tickets/<id>', (Request req, String id) {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final ticket = store.ticketById(id);
    if (ticket == null) {
      return jsonError('NOT_FOUND', 'Ticket $id not found', status: 404);
    }
    return jsonOk(ticket);
  });

  router.patch('/v1/platform/tickets/<id>', (Request req, String id) async {
    final denied = _requireSystemAdmin(req);
    if (denied != null) return denied;
    final body = await req.readJson();
    final status = body['status'] as String?;
    if (status != null && !Store.kTicketStatuses.contains(status)) {
      return jsonError(
        'VALIDATION_ERROR',
        'status must be one of ${Store.kTicketStatuses.join(', ')}',
        status: 422,
      );
    }
    final reply = body['reply'] as String?;
    Map<String, dynamic>? ticket;
    if (reply != null && reply.trim().isNotEmpty) {
      ticket = store.addTicketReply(
        id,
        message: reply,
        authorName: (req.auth!.user['name'] as String?) ?? req.auth!.phone,
        isAdmin: true,
        status: status,
      );
    } else {
      ticket = store.updateTicket(
        id,
        status: status,
        assignedToName: body['assignedToName'] as String?,
      );
    }
    if (ticket == null) {
      return jsonError('NOT_FOUND', 'Ticket $id not found', status: 404);
    }
    store.audit(
      actorUserId: req.auth!.userId,
      action: 'ticket.update',
      targetType: 'ticket',
      targetId: id,
      detail: status,
    );
    return jsonOk(ticket);
  });

  // Seed bootstrap: promote a phone to system admin. This is a privilege-
  // escalation endpoint, so it is disabled entirely in production unless
  // explicitly enabled, and always requires a strong, operator-configured
  // BOOTSTRAP_ADMIN_SECRET — the legacy `ibuild-dev` default is never
  // accepted.
  router.post('/v1/platform/bootstrap-admin', (Request req) async {
    if (!bootstrapAdminEnabled) {
      return jsonError('NOT_FOUND', 'Not found', status: 404);
    }
    final configuredSecret = appEnv()['BOOTSTRAP_ADMIN_SECRET']?.trim();
    if (configuredSecret == null ||
        configuredSecret.isEmpty ||
        configuredSecret == kDefaultBootstrapSecret) {
      return jsonError(
        'FORBIDDEN',
        'Bootstrap admin is not configured (set a strong '
            'BOOTSTRAP_ADMIN_SECRET)',
        status: 403,
      );
    }
    final body = await req.readJson();
    final provided = body['secret'] as String?;
    if (provided == null || !constantTimeEquals(provided, configuredSecret)) {
      return jsonError('FORBIDDEN', 'Invalid bootstrap secret', status: 403);
    }
    final phone = body['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      return jsonError('VALIDATION_ERROR', 'phone is required', status: 422);
    }
    final user = store.ensureUser(phone: phone, role: UserRole.systemAdmin);
    return jsonOk(user);
  });
}

Response? _requireSystemAdmin(Request req) {
  final auth = req.auth;
  if (auth == null) {
    return jsonError('UNAUTHENTICATED', 'Authentication required', status: 401);
  }
  if (!auth.isSystemAdmin) {
    return jsonError('FORBIDDEN', 'System admin required', status: 403);
  }
  return null;
}

bool _canManageProject(Store store, AuthContext auth, Map project) {
  if (auth.isSystemAdmin) return true;
  if (!auth.isResidenceAdmin) return false;
  return store.ownsProject(auth.userId, project);
}

Future<Map<String, dynamic>?> _handleMultipartMedia(
  Request req,
  Store store, {
  required String unitId,
}) async {
  final contentType = req.headers['content-type']!;
  final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
  if (boundaryMatch == null) return null;
  final boundary = boundaryMatch.group(1)!.trim();
  final bytes = await req.read().expand((c) => c).toList();
  final parts = _parseMultipart(Uint8List.fromList(bytes), boundary);
  final filePart = parts.where((p) => p.filename != null).firstOrNull;
  if (filePart == null) return null;

  final uploadsDir = Directory('uploads');
  if (!uploadsDir.existsSync()) {
    uploadsDir.createSync(recursive: true);
  }
  final ext = filePart.filename!.contains('.')
      ? filePart.filename!.split('.').last
      : 'bin';
  final fileName = '${_uuid.v4()}.$ext';
  final file = File('${uploadsDir.path}/$fileName');
  await file.writeAsBytes(filePart.data);

  final url = '/v1/static/uploads/$fileName';
  return store.addUnitMedia(unitId, url: url, type: 'photo');
}

/// Multipart handler for `POST /v1/developers/me/documents`, mirroring
/// [_handleMultipartMedia]'s upload-to-local-`uploads/` pattern. Expects a
/// file part plus a `type` field (one of [kAllowedDocumentTypes]).
Future<Map<String, dynamic>?> _handleMultipartDocument(
  Request req,
  Store store, {
  required String developerId,
  required String uploadedBy,
}) async {
  final contentType = req.headers['content-type']!;
  final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
  if (boundaryMatch == null) return null;
  final boundary = boundaryMatch.group(1)!.trim();
  final bytes = await req.read().expand((c) => c).toList();
  final parts = _parseMultipart(Uint8List.fromList(bytes), boundary);
  final filePart = parts.where((p) => p.filename != null).firstOrNull;
  if (filePart == null) return null;
  final typePart = parts
      .where((p) => p.filename == null && p.name == 'type')
      .firstOrNull;
  final type = typePart == null ? null : utf8.decode(typePart.data);
  if (type == null || !kAllowedDocumentTypes.contains(type)) return null;

  final uploadsDir = Directory('uploads');
  if (!uploadsDir.existsSync()) {
    uploadsDir.createSync(recursive: true);
  }
  final ext = filePart.filename!.contains('.')
      ? filePart.filename!.split('.').last
      : 'bin';
  final fileName = '${_uuid.v4()}.$ext';
  final file = File('${uploadsDir.path}/$fileName');
  await file.writeAsBytes(filePart.data);

  final url = '/v1/static/uploads/$fileName';
  return store.addDocument(
    developerId: developerId,
    type: type,
    fileUrl: url,
    uploadedBy: uploadedBy,
  );
}

/// Multipart handler for `POST /v1/admin/projects/:id/photo-reports`.
/// Expects a file part plus optional `takenAt`/`progressPercent`/
/// `buildingId` fields; returns the uploaded file's URL alongside the raw
/// field values so the route can apply the same validation it uses for the
/// JSON-body variant.
Future<
  ({String url, String? takenAt, int? progressPercent, String? buildingId})?
>
_handleMultipartPhotoReport(Request req) async {
  final contentType = req.headers['content-type']!;
  final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
  if (boundaryMatch == null) return null;
  final boundary = boundaryMatch.group(1)!.trim();
  final bytes = await req.read().expand((c) => c).toList();
  final parts = _parseMultipart(Uint8List.fromList(bytes), boundary);
  final filePart = parts.where((p) => p.filename != null).firstOrNull;
  if (filePart == null) return null;

  final uploadsDir = Directory('uploads');
  if (!uploadsDir.existsSync()) {
    uploadsDir.createSync(recursive: true);
  }
  final ext = filePart.filename!.contains('.')
      ? filePart.filename!.split('.').last
      : 'bin';
  final fileName = '${_uuid.v4()}.$ext';
  final file = File('${uploadsDir.path}/$fileName');
  await file.writeAsBytes(filePart.data);
  final url = '/v1/static/uploads/$fileName';

  String? field(String name) {
    final part = parts
        .where((p) => p.filename == null && p.name == name)
        .firstOrNull;
    return part == null ? null : utf8.decode(part.data);
  }

  final progressRaw = field('progressPercent');
  return (
    url: url,
    takenAt: field('takenAt'),
    progressPercent: progressRaw == null ? null : int.tryParse(progressRaw),
    buildingId: field('buildingId'),
  );
}

class _MultipartPart {
  _MultipartPart({required this.data, this.filename, this.name});
  final Uint8List data;
  final String? filename;
  final String? name;
}

List<_MultipartPart> _parseMultipart(Uint8List body, String boundary) {
  final delimiter = utf8.encode('--$boundary');
  final parts = <_MultipartPart>[];
  var start = _indexOf(body, delimiter, 0);
  while (start >= 0) {
    start += delimiter.length;
    if (start < body.length && body[start] == 45 && body[start + 1] == 45) {
      break; // closing --
    }
    if (start < body.length && body[start] == 13) start++;
    if (start < body.length && body[start] == 10) start++;
    final next = _indexOf(body, delimiter, start);
    final end = next < 0 ? body.length : next - 2; // strip \r\n
    final chunk = body.sublist(start, end.clamp(0, body.length));
    final headerEnd = _indexOf(chunk, utf8.encode('\r\n\r\n'), 0);
    if (headerEnd >= 0) {
      final headerText = utf8.decode(chunk.sublist(0, headerEnd));
      final data = chunk.sublist(headerEnd + 4);
      final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(headerText);
      final fileMatch = RegExp(r'filename="([^"]+)"').firstMatch(headerText);
      parts.add(
        _MultipartPart(
          data: data,
          name: nameMatch?.group(1),
          filename: fileMatch?.group(1),
        ),
      );
    }
    start = next;
  }
  return parts;
}

int _indexOf(Uint8List haystack, List<int> needle, int from) {
  outer:
  for (var i = from; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}
