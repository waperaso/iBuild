import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class AdminApi {
  AdminApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> analytics() async {
    final res = await _dio.get<Map<String, dynamic>>('/platform/analytics');
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> pendingDevelopers() async {
    final res = await _dio.get<List<dynamic>>('/platform/developers/pending');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Moves a developer application across the review pipeline: `pending`
  /// ("waiting for review") -> `in_review` ("on review") ->
  /// `approved`/`rejected` (the latter requires [reason]). Freely movable in
  /// either direction so an admin can walk a decision back if needed.
  Future<Map<String, dynamic>> setDeveloperStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/platform/developers/$id/status',
      data: {'status': status, 'reason': ?reason},
    );
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> pendingProjects() async {
    final res = await _dio.get<List<dynamic>>('/platform/projects/pending');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> publishedProjects() async {
    final res = await _dio.get<List<dynamic>>('/platform/projects/published');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Every ЖК/business-centre regardless of moderation status — the
  /// "administration" roster a system admin browses to inspect how a
  /// listing is furnished/attached (buildings, units, media, offers)
  /// without ever owning a project themselves.
  Future<List<Map<String, dynamic>>> allProjects() async {
    final res = await _dio.get<List<dynamic>>('/platform/projects');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Platform-wide lead CRM — every lead across every project (as opposed
  /// to [projectLeads], which is scoped to one project).
  Future<List<Map<String, dynamic>>> platformLeads({String? owner}) async {
    final res = await _dio.get<List<dynamic>>(
      '/platform/leads',
      queryParameters: owner == null ? null : {'owner': owner},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Managers who can own CRM leads (system_admin + residence_admin).
  Future<List<Map<String, dynamic>>> crmAssignees() async {
    final res = await _dio.get<List<dynamic>>('/admin/crm-assignees');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> leadEvents(String leadId) async {
    final res = await _dio.get<List<dynamic>>('/admin/leads/$leadId/events');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> transferLead(
    String leadId, {
    required String toUserId,
    String? note,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/leads/$leadId/transfer',
      data: {'toUserId': toUserId, 'note': ?note},
    );
    return res.data!;
  }

  Future<void> moderateProject(
    String id, {
    required String decision,
    String? note,
  }) =>
      _dio.patch(
        '/platform/projects/$id/moderate',
        data: {
          'decision': decision,
          'note': ?note,
        },
      );

  Future<List<Map<String, dynamic>>> users() async {
    final res = await _dio.get<List<dynamic>>('/platform/users');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> setUserRole(String id, String role) =>
      _dio.patch('/platform/users/$id/role', data: {'role': role});

  /// Freezes the account: [reason] and [bannedByName] are echoed back on
  /// the user's own profile so they see why and by whom.
  Future<Map<String, dynamic>> banUser(
    String id, {
    required String reason,
    required String bannedByName,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/platform/users/$id/ban',
      data: {'reason': reason, 'bannedByName': bannedByName},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> unbanUser(String id) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/platform/users/$id/unban',
    );
    return res.data!;
  }

  /// Permanently removes a platform-admin (`system_admin`) account — the
  /// server rejects this for any other role, for the caller's own account,
  /// and for the platform's last remaining admin.
  Future<void> deleteUser(String id) => _dio.delete('/platform/users/$id');

  Future<List<Map<String, dynamic>>> myProjects() async {
    final res = await _dio.get<List<dynamic>>('/developers/me/projects');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProject(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/developers/me/projects',
      data: body,
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> submitProjectForReview(String projectId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/projects/$projectId/submit-for-review',
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> unpublishAdminProject(String projectId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/projects/$projectId/unpublish',
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> publishAdminProject(String projectId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/projects/$projectId/publish',
    );
    return res.data!;
  }

  Future<void> deleteAdminProject(String projectId) =>
      _dio.delete('/admin/projects/$projectId');

  Future<Map<String, dynamic>> submitDeveloperForReview() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/developers/me/submit-for-review',
    );
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> projectLeads(
    String projectId, {
    String? owner,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/admin/projects/$projectId/leads',
      queryParameters: owner == null ? null : {'owner': owner},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> updateLeadStatus(String leadId, String status) =>
      _dio.patch('/admin/leads/$leadId', data: {'status': status});

  Future<Map<String, dynamic>> registerDeveloper({
    required String name,
    required String legalName,
    required String inn,
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
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/developers',
      data: {
        'name': name,
        'legalName': legalName,
        'inn': inn,
        'accountKind': accountKind,
        'legalForm': legalForm,
        'legalAddress': legalAddress,
        'directorFullName': directorFullName,
        'directorPinfl': directorPinfl,
        'uboDeclared': uboDeclared,
        'registrationNumber': ?registrationNumber,
        'officeAddress': ?officeAddress,
        'region': ?region,
        'email': ?email,
        'website': ?website,
        'okedCode': ?okedCode,
        'directorPassport': ?directorPassport,
        'directorPhone': ?directorPhone,
        'directorEmail': ?directorEmail,
        'uboFullName': ?uboFullName,
        'constructionLicense': ?constructionLicense,
      },
    );
    return res.data!;
  }

  Future<Map<String, dynamic>?> myDeveloper() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/developers/me');
      return res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMyDeveloper(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/developers/me',
      data: body,
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> checkoutSubscription({String? planId}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/developers/me/subscription/checkout',
      data: {'planId': ?planId},
    );
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> subscriptionPlans() async {
    final res = await _dio.get<List<dynamic>>('/subscription-plans');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> projectOffers(String projectId) async {
    final res = await _dio.get<List<dynamic>>(
      '/admin/projects/$projectId/offers',
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> setProjectOffers(
    String projectId,
    List<Map<String, dynamic>> offers,
  ) => _dio.put('/admin/projects/$projectId/offers', data: {'offers': offers});

  Future<Map<String, dynamic>> projectAnalytics(String projectId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/projects/$projectId/analytics',
    );
    return res.data!;
  }

  Future<void> updateLead(
    String leadId, {
    String? status,
    List<String>? tags,
    String? score,
    String? assignedManager,
    String? ownerUserId,
    bool clearOwner = false,
    String? notes,
  }) => _dio.patch(
    '/admin/leads/$leadId',
    data: {
      'status': ?status,
      'tags': ?tags,
      'score': ?score,
      'assignedManager': ?assignedManager,
      if (ownerUserId != null || clearOwner) 'ownerUserId': ownerUserId,
      'notes': ?notes,
    },
  );

  Future<List<Map<String, dynamic>>> pendingReviews() async {
    final res = await _dio.get<List<dynamic>>('/platform/reviews/pending');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> moderateReview(String id, {required bool keep}) => _dio.patch(
    '/platform/reviews/$id/moderate',
    data: {'decision': keep ? 'keep' : 'remove'},
  );

  Future<List<Map<String, dynamic>>> pendingRentalListings() async {
    final res = await _dio.get<List<dynamic>>(
      '/platform/rental-listings/pending',
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> moderateRentalListing(
    String id, {
    required bool approve,
    String? note,
  }) => _dio.patch(
    '/platform/rental-listings/$id/moderate',
    data: {
      'decision': approve ? 'approve' : 'reject',
      'note': ?note,
    },
  );

  Future<List<Map<String, dynamic>>> auditLog({int limit = 100}) async {
    final res = await _dio.get<List<dynamic>>(
      '/platform/audit-log',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> platformBusinesses() async {
    final res = await _dio.get<List<dynamic>>('/platform/businesses');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> patchUnit(String unitId, Map<String, dynamic> body) =>
      _dio.patch('/admin/units/$unitId', data: body);

  Future<Map<String, dynamic>> addUnitMediaUrl(
    String unitId,
    String url,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/units/$unitId/media',
      data: {'url': url, 'type': 'photo'},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> getAdminProject(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/admin/projects/$id');
    return res.data!;
  }

  Future<Map<String, dynamic>> updateAdminProject(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/admin/projects/$id',
      data: body,
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> addBuilding(
    String projectId,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/projects/$projectId/buildings',
      data: body,
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> addUnit(
    String projectId,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/projects/$projectId/units',
      data: body,
    );
    return res.data!;
  }

  // --- Support tickets ------------------------------------------------

  Future<List<Map<String, dynamic>>> myTickets() async {
    final res = await _dio.get<List<dynamic>>('/users/me/tickets');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String message,
    String category = 'other',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/support/tickets',
      data: {'subject': subject, 'message': message, 'category': category},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> replyToTicket(String id, String message) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/support/tickets/$id/replies',
      data: {'message': message},
    );
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> platformTickets({String? status}) async {
    final res = await _dio.get<List<dynamic>>(
      '/platform/tickets',
      queryParameters: {'status': ?status},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> platformReplyToTicket(
    String id, {
    String? reply,
    String? status,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/platform/tickets/$id',
      data: {'reply': ?reply, 'status': ?status},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> setTicketStatus(String id, String status) =>
      platformReplyToTicket(id, status: status);

  // --- Documents (developer verification) ------------------------------
  //
  // Frozen contract (see the Trust-MVP hardening plan): `type` is one of
  // license | construction_permit | land_rights | project_declaration;
  // `status` is pending | accepted | rejected.

  /// Multipart verification-document upload (`type` as a form field).
  Future<Map<String, dynamic>> uploadDeveloperDocument({
    required String type,
    required List<int> bytes,
    required String filename,
    String? projectId,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'type': type,
      'projectId': ?projectId,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/developers/me/documents',
      data: form,
      onSendProgress: onSendProgress,
    );
    return res.data!;
  }

  /// Lists the signed-in developer's own documents.
  Future<List<Map<String, dynamic>>> myDocuments() async {
    final res = await _dio.get<List<dynamic>>('/developers/me/documents');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Moderator view of one developer's documents (KYC review dialog).
  Future<List<Map<String, dynamic>>> developerDocuments(
    String developerId,
  ) async {
    final res = await _dio.get<List<dynamic>>(
      '/platform/developers/$developerId/documents',
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Moderator accept/reject decision on a single document.
  Future<void> reviewDocument(
    String id, {
    required String status,
    String? rejectReason,
  }) => _dio.patch(
    '/platform/documents/$id',
    data: {'status': status, 'rejectReason': ?rejectReason},
  );

  // --- Photo reports (construction progress) ----------------------------

  /// Multipart site photo upload; optional [progressPercent] updates construction %.
  Future<Map<String, dynamic>> uploadPhotoReport(
    String projectId, {
    required List<int> bytes,
    required String filename,
    required DateTime takenAt,
    int? progressPercent,
    String? buildingId,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'takenAt': takenAt.toIso8601String().split('T').first,
      'progressPercent': ?progressPercent,
      'buildingId': ?buildingId,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/projects/$projectId/photo-reports',
      data: form,
      onSendProgress: onSendProgress,
    );
    return res.data!;
  }

  /// Public listing, newest-first — the client groups these by month.
  Future<List<Map<String, dynamic>>> projectPhotoReports(
    String projectId,
  ) async {
    final res = await _dio.get<List<dynamic>>(
      '/projects/$projectId/photo-reports',
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> deletePhotoReport(String id) =>
      _dio.delete('/admin/photo-reports/$id');

  // --- Admin notifications (developer changes / submitted docs) ---------

  /// Every developer-side change that needs a system admin's attention —
  /// new/updated/submitted projects and uploaded verification documents.
  Future<List<Map<String, dynamic>>> notifications({
    bool unreadOnly = false,
    int limit = 200,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/platform/notifications',
      queryParameters: {
        'unreadOnly': unreadOnly,
        'limit': limit,
      },
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> markNotificationRead(String id) =>
      _dio.post('/platform/notifications/$id/read');

  Future<void> markAllNotificationsRead() =>
      _dio.post('/platform/notifications/read-all');
}

final adminApiProvider = Provider(
  (ref) => AdminApi(ref.watch(apiClientProvider)),
);
