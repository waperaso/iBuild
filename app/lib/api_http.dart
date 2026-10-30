import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'fx.dart';
import 'models.dart';
import 'registration_models.dart';
import 'screens/bank/bank_models.dart';

class HttpApiClient implements Api {
  HttpApiClient(this._client);

  final http.Client _client;
  String? _csrf;

  Uri _uri(String path) => Uri.base.resolve(path);

  @override
  Future<UserProfile?> me() async {
    final response = await _send('GET', '/api/auth/me');
    if (response.statusCode == 401 || response.statusCode == 403) return null;
    final json = _ok(response);
    _csrf = json['csrfToken'] as String?;
    return UserProfile.fromJson(json);
  }

  @override
  Future<UserProfile> login(String login, String password) async {
    final csrf = await _send('GET', '/api/auth/csrf');
    final csrfJson = _ok(csrf);
    _csrf = csrfJson['csrfToken'] as String?;
    final response = await _send(
      'POST',
      '/api/auth/login',
      body: {'login': login, 'password': password},
      csrf: true,
    );
    final json = _ok(response);
    _csrf = json['csrfToken'] as String?;
    return UserProfile.fromJson(json);
  }

  @override
  Future<bool> demoEnabled() async {
    try {
      final response = await _send('GET', '/api/config');
      if (response.statusCode != 200) return false;
      return _ok(response)['demoEnabled'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserProfile> demoLogin(String role) async {
    final csrf = await _send('GET', '/api/auth/csrf');
    _csrf = _ok(csrf)['csrfToken'] as String?;
    final response = await _send('POST', '/api/demo/login', body: {'role': role}, csrf: true);
    final json = _ok(response);
    _csrf = json['csrfToken'] as String?;
    return UserProfile.fromJson(json);
  }

  @override
  Future<void> changePassword(String current, String next) async {
    _ok(await _send('POST', '/api/auth/password', body: {'current': current, 'next': next}, csrf: true));
  }

  @override
  Future<void> logout() async {
    final response = await _send(
      'POST',
      '/api/auth/logout',
      body: const {},
      csrf: true,
    );
    if (response.statusCode != 204 && response.statusCode != 401) {
      _ok(response);
    }
    _csrf = null;
  }

  @override
  Future<List<ProjectSummary>> projects() async {
    final json = _ok(await _send('GET', '/api/projects'));
    final list = json['projects'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        ProjectSummary.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<ProjectSummary> project(String id) async {
    return ProjectSummary.fromJson(
      _ok(await _send('GET', '/api/projects/$id')),
    );
  }

  @override
  Future<List<ProjectDocument>> projectDocuments(String projectId) async {
    final json = _ok(await _send('GET', '/api/projects/$projectId/documents'));
    final list = json['documents'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        ProjectDocument.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<ProjectSummary> createProject({
    required String name,
    required String address,
  }) async {
    final response = await _send(
      'POST',
      '/api/projects',
      body: {'name': name, 'address': address},
      csrf: true,
    );
    return ProjectSummary.fromJson(_ok(response));
  }

  @override
  Future<BudgetSnapshot> budget(String projectId) async {
    return BudgetSnapshot.fromJson(
      _ok(await _send('GET', '/api/projects/$projectId/budget')),
    );
  }

  @override
  Future<List<ProjectMember>> members(String projectId) async {
    final json = _ok(await _send('GET', '/api/projects/$projectId/members'));
    final list = json['members'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        ProjectMember.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<ContractorFirm>> firms() async {
    final json = _ok(await _send('GET', '/api/contractor-firms'));
    final list = json['firms'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        ContractorFirm.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CompanyUser>> companyUsers() async {
    final json = _ok(await _send('GET', '/api/company/users'));
    final list = json['users'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        CompanyUser.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> createBudgetLine({
    required String projectId,
    required String title,
    required String amount,
    required String contractorFirmId,
  }) async {
    _ok(
      await _send(
        'POST',
        '/api/projects/$projectId/budget',
        body: {
          'title': title,
          'amount': amount,
          'contractorFirmId': contractorFirmId,
        },
        csrf: true,
      ),
    );
  }

  @override
  Future<void> updateBudgetLine({
    required String projectId,
    required String itemId,
    required String title,
    required String amount,
    required String contractorFirmId,
  }) async {
    _ok(
      await _send(
        'PATCH',
        '/api/projects/$projectId/budget/$itemId',
        body: {
          'title': title,
          'amount': amount,
          'contractorFirmId': contractorFirmId,
        },
        csrf: true,
      ),
    );
  }

  @override
  Future<void> deleteBudgetLine({
    required String projectId,
    required String itemId,
  }) async {
    final response = await _send(
      'DELETE',
      '/api/projects/$projectId/budget/$itemId',
      csrf: true,
    );
    if (response.statusCode >= 400) _ok(response);
  }

  @override
  Future<void> removeMember({
    required String projectId,
    required String memberId,
  }) async {
    final response = await _send(
      'DELETE',
      '/api/projects/$projectId/members/$memberId',
      csrf: true,
    );
    if (response.statusCode >= 400) _ok(response);
  }

  @override
  Future<void> createFirm({
    required String name,
    required String inn,
    required String contact,
  }) async {
    _ok(
      await _send(
        'POST',
        '/api/contractor-firms',
        body: {'name': name, 'inn': inn, 'contact': contact},
        csrf: true,
      ),
    );
  }

  @override
  Future<void> addMember({
    required String projectId,
    required String userId,
    required String role,
    String? contractorFirmId,
  }) async {
    _ok(
      await _send(
        'POST',
        '/api/projects/$projectId/members',
        body: {
          'userId': userId,
          'role': role,
          'contractorFirmId': ?contractorFirmId,
        },
        csrf: true,
      ),
    );
  }

  @override
  Future<List<FundingRequest>> requests() async {
    final json = _ok(await _send('GET', '/api/requests'));
    final list = json['requests'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        FundingRequest.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<FundingRequest> request(String id) async {
    return FundingRequest.fromJson(_ok(await _send('GET', '/api/requests/$id')));
  }

  @override
  @override
  Future<void> contactRequest({required String id, required String message}) async {
    _ok(await _send('POST', '/api/requests/$id/contact', body: {'message': message}, csrf: true));
  }

  @override
  Future<FundingRequest> createRequest({
    required String projectId,
    required String budgetItemId,
    required String amount,
    required String description,
    String? customTitle,
  }) async {
    final custom = customTitle?.trim() ?? '';
    return FundingRequest.fromJson(
      _ok(
        await _send(
          'POST',
          '/api/requests',
          body: {
            'projectId': projectId,
            if (custom.isEmpty) 'budgetItemId': budgetItemId,
            if (custom.isNotEmpty) 'customTitle': custom,
            'amount': amount,
            'description': description,
          },
          csrf: true,
        ),
      ),
    );
  }

  @override
  Future<FundingRequest> updateRequest({
    required String id,
    required String budgetItemId,
    required String amount,
    required String description,
  }) async {
    return FundingRequest.fromJson(
      _ok(
        await _send(
          'PATCH',
          '/api/requests/$id',
          body: {
            'budgetItemId': budgetItemId,
            'amount': amount,
            'description': description,
          },
          csrf: true,
        ),
      ),
    );
  }

  @override
  Future<RequestFile> uploadRequestFile({
    required String requestId,
    required Uint8List bytes,
  }) async {
    final response = await _client.post(
      _uri('/api/requests/$requestId/files'),
      headers: {
        'content-type': 'application/octet-stream',
        'x-csrf-token': ?_csrf,
      },
      body: bytes,
    );
    return RequestFile.fromJson(_ok(response));
  }

  @override
  Future<Uint8List> requestFile({
    required String requestId,
    required String fileId,
  }) async {
    final response = await _send('GET', '/api/requests/$requestId/files/$fileId');
    if (response.statusCode >= 400) _ok(response);
    return response.bodyBytes;
  }

  @override
  Future<void> deleteRequestFile({
    required String requestId,
    required String fileId,
  }) async {
    final response = await _send(
      'DELETE',
      '/api/requests/$requestId/files/$fileId',
      csrf: true,
    );
    if (response.statusCode >= 400) _ok(response);
  }

  @override
  Future<FundingRequest> submitRequest({
    required String id,
    required int version,
    required String idempotencyKey,
    String? addresseeUserId,
  }) {
    return _transition('/api/requests/$id/submit', {
      'version': version,
      if (addresseeUserId != null && addresseeUserId.isNotEmpty)
        'addresseeUserId': addresseeUserId,
    }, idempotencyKey);
  }

  @override
  Future<FundingRequest> deliverRequest({
    required String id,
    required int version,
    required String addresseeUserId,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/deliver', {
      'version': version,
      'addresseeUserId': addresseeUserId,
    }, idempotencyKey);
  }

  @override
  Future<FundingRequest> cancelRequest({
    required String id,
    required int version,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/cancel', {'version': version}, idempotencyKey);
  }

  @override
  Future<FundingRequest> techDecision({
    required String id,
    required int version,
    required String decision,
    required String reason,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/tech', {
      'version': version,
      'decision': decision,
      'reason': reason,
    }, idempotencyKey);
  }

  @override
  Future<FundingRequest> approveRequest({
    required String id,
    required int version,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/approve', {'version': version}, idempotencyKey);
  }

  @override
  Future<FundingRequest> rejectRequest({
    required String id,
    required int version,
    required String reason,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/reject', {
      'version': version,
      'reason': reason,
    }, idempotencyKey);
  }

  @override
  Future<FundingRequest> recordPayment({
    required String id,
    required int version,
    required String paidOn,
    required String paymentNumber,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/pay', {
      'version': version,
      'paidOn': paidOn,
      'paymentNumber': paymentNumber,
    }, idempotencyKey);
  }

  @override
  Future<FundingRequest> withdrawApproval({
    required String id,
    required int version,
    required String reason,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/withdraw', {
      'version': version,
      'reason': reason,
      'unpaidConfirmed': true,
    }, idempotencyKey);
  }

  @override
  Future<FundingRequest> copyRejected({
    required String id,
    required int version,
    required String idempotencyKey,
  }) {
    return _transition('/api/requests/$id/copy', {'version': version}, idempotencyKey);
  }

  @override
  Future<RequestFile> uploadPaymentFile({
    required String requestId,
    required Uint8List bytes,
  }) async {
    final response = await _client.post(
      _uri('/api/requests/$requestId/payment-file'),
      headers: {
        'content-type': 'application/octet-stream',
        'x-csrf-token': ?_csrf,
      },
      body: bytes,
    );
    return RequestFile.fromJson(_ok(response));
  }

  @override
  Future<void> deletePaymentFile({
    required String requestId,
    required String fileId,
  }) async {
    final response = await _send(
      'DELETE',
      '/api/requests/$requestId/payment-file/$fileId',
      csrf: true,
    );
    if (response.statusCode != 204) _ok(response);
  }

  Future<FundingRequest> _transition(
    String path,
    Map<String, Object?> body,
    String idempotencyKey,
  ) async {
    return FundingRequest.fromJson(
      _ok(await _send('POST', path, body: body, csrf: true, idempotencyKey: idempotencyKey)),
    );
  }

  @override
  Future<UsdQuote> usdRate() async {
    final json = _ok(await _send('GET', '/api/fx/usd'));
    return UsdQuote(
      rate: json['rate'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  @override
  Future<List<InspectionOrder>> inspections() async {
    final json = _ok(await _send('GET', '/api/inspections'));
    final raw = json['inspections'] as List? ?? const [];
    return [
      for (final item in raw)
        if (item is Map)
          InspectionOrder.fromJson(item.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  @override
  Future<void> requestInspection({
    required String projectId,
    required String scheduledOn,
    required String note,
    String? requestId,
  }) async {
    _ok(await _send('POST', '/api/inspections', body: {
      'projectId': projectId,
      'scheduledOn': scheduledOn,
      'note': note,
      if (requestId != null && requestId.isNotEmpty) 'requestId': requestId,
    }, csrf: true));
  }

  @override
  Future<void> reportInspection({
    required String id,
    required String note,
    required List<Map<String, String>> lines,
  }) async {
    _ok(await _send('POST', '/api/inspections/$id/report', body: {
      'note': note,
      'lines': lines,
    }, csrf: true));
  }

  @override
  Future<List<NoticeItem>> notices() async {
    final json = _ok(await _send('GET', '/api/notices'));
    final queue = json['queue'] as List? ?? const [];
    return [
      for (final item in queue)
        if (item is Map)
          NoticeItem.fromJson(item.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  @override
  Future<LoanDesk> loan(String projectId) async {
    final response = await _send('GET', '/api/projects/$projectId/loan');
    return LoanDesk.fromJson(_ok(response));
  }

  @override
  Future<void> importBudget({
    required String projectId,
    required String contractorFirmId,
    required String csv,
  }) async {
    _ok(await _send('POST', '/api/projects/$projectId/budget/import', body: {
      'contractorFirmId': contractorFirmId,
      'csv': csv,
    }, csrf: true));
  }

  @override
  Future<void> copyBudget({
    required String projectId,
    required String fromProjectId,
  }) async {
    _ok(await _send('POST', '/api/projects/$projectId/budget/copy', body: {
      'fromProjectId': fromProjectId,
    }, csrf: true));
  }

  @override
  Future<String> addSource({
    required String projectId,
    required String name,
    required String kind,
    required String amount,
  }) async {
    final json = _ok(await _send('POST', '/api/projects/$projectId/sources', body: {
      'name': name,
      'kind': kind,
      'amount': amount,
    }, csrf: true));
    return json['id'] as String;
  }

  @override
  Future<String> saveBudgetTemplate({
    required String projectId,
    required String name,
  }) async {
    final json = _ok(await _send('POST', '/api/budget-templates', body: {
      'projectId': projectId,
      'name': name,
    }, csrf: true));
    return json['id'] as String;
  }

  @override
  Future<void> applyBudgetTemplate({
    required String projectId,
    required String templateId,
    required String contractorFirmId,
  }) async {
    _ok(await _send('POST', '/api/projects/$projectId/budget/from-template', body: {
      'templateId': templateId,
      'contractorFirmId': contractorFirmId,
    }, csrf: true));
  }

  @override
  Future<String> createDraw({required String projectId, required String name}) async {
    final json = _ok(await _send('POST', '/api/draws', body: {
      'projectId': projectId,
      'name': name,
    }, csrf: true));
    return json['id'] as String;
  }

  @override
  Future<DrawDetail> draw(String id) async {
    final response = await _send('GET', '/api/draws/$id');
    return DrawDetail.fromJson(_ok(response));
  }

  @override
  Future<DrawDetail> saveDraw({
    required String id,
    required String name,
    required bool finalDraw,
    required String signedName,
    required List<DrawLineInput> lines,
    required List<Map<String, String>> sources,
    required List<Map<String, String>> requirements,
  }) async {
    final response = await _send('PATCH', '/api/draws/$id', body: {
      'name': name,
      'finalDraw': finalDraw,
      'signedName': signedName,
      'lines': [for (final line in lines) line.toJson()],
      'sources': sources,
      'requirements': requirements,
    }, csrf: true);
    return DrawDetail.fromJson(_ok(response));
  }

  @override
  Future<DrawDetail> submitDraw(String id) async {
    final response = await _send('POST', '/api/draws/$id/submit', body: const {}, csrf: true);
    return DrawDetail.fromJson(_ok(response));
  }

  @override
  Future<DrawDetail> decideDraw({
    required String id,
    required List<Map<String, String>> lines,
  }) async {
    final response = await _send('POST', '/api/draws/$id/decide', body: {
      'lines': lines,
    }, csrf: true);
    return DrawDetail.fromJson(_ok(response));
  }

  @override
  Future<void> inspect({
    required String projectId,
    required String requestId,
    required String scheduledOn,
    required String gateCode,
    required String note,
    required List<Map<String, String>> lines,
  }) async {
    _ok(await _send('POST', '/api/projects/$projectId/inspections', body: {
      'requestId': requestId,
      'scheduledOn': scheduledOn,
      'gateCode': gateCode,
      'note': note,
      'lines': lines,
    }, csrf: true));
  }

  @override
  Future<void> commentDraw({required String id, required String body}) async {
    _ok(await _send('POST', '/api/draws/$id/comments', body: {'body': body}, csrf: true));
  }

  @override
  Future<void> addPayable({
    required String id,
    required String budgetItemId,
    required String firmId,
    required String number,
    required String amount,
    required String waiver,
  }) async {
    _ok(await _send('POST', '/api/draws/$id/payables', body: {
      'budgetItemId': budgetItemId,
      'firmId': firmId,
      'number': number,
      'amount': amount,
      'waiver': waiver,
    }, csrf: true));
  }

  @override
  Future<String> drawPackage(String id) async {
    final response = await _send('GET', '/api/draws/$id/package');
    if (response.statusCode >= 400) {
      _ok(response);
    }
    return response.body;
  }

  @override
  Future<List<ProjectChange>> projectChanges(String projectId) async {
    final json = _ok(await _send('GET', '/api/projects/$projectId/changes'));
    final list = json['changes'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        ProjectChange.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<ProjectChange> proposeProjectChange({
    required String projectId,
    required String name,
    required String address,
    Uint8List? photo,
  }) async {
    if (photo == null) {
      return ProjectChange.fromJson(
        _ok(
          await _send(
            'POST',
            '/api/projects/$projectId/changes',
            body: {'name': name, 'address': address},
            csrf: true,
          ),
        ),
      );
    }
    final uri = _uri('/api/projects/$projectId/changes');
    final message = http.MultipartRequest('POST', uri);
    if (_csrf != null) message.headers['x-csrf-token'] = _csrf!;
    message.fields['name'] = name;
    message.fields['address'] = address;
    message.files.add(
      http.MultipartFile.fromBytes('photo', photo, filename: 'photo.jpg'),
    );
    final streamed = await _client.send(message);
    final response = await http.Response.fromStream(streamed);
    return ProjectChange.fromJson(_ok(response));
  }

  @override
  Future<Uint8List?> projectPhoto(String projectId) async {
    final response = await _send('GET', '/api/projects/$projectId/photo');
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 400) _ok(response);
    return response.bodyBytes;
  }

  @override
  Future<Uint8List?> changePhoto(String changeId) async {
    final response = await _send('GET', '/api/project-changes/$changeId/photo');
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 400) _ok(response);
    return response.bodyBytes;
  }

  @override
  Future<List<ProjectChange>> moderationQueue() async {
    final json = _ok(await _send('GET', '/api/admin/changes'));
    final list = json['changes'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        ProjectChange.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> approveProjectChange(String id) async {
    _ok(
      await _send('POST', '/api/admin/changes/$id/approve', body: const {}, csrf: true),
    );
  }

  @override
  Future<void> rejectProjectChange({required String id, required String note}) async {
    _ok(
      await _send(
        'POST',
        '/api/admin/changes/$id/reject',
        body: {'note': note},
        csrf: true,
      ),
    );
  }

  @override
  Future<void> updateCompliance({
    required String firmId,
    required String insuranceUntil,
    required String licenseUntil,
  }) async {
    _ok(await _send('PATCH', '/api/contractor-firms/$firmId', body: {
      'insuranceUntil': insuranceUntil,
      'licenseUntil': licenseUntil,
    }, csrf: true));
  }

  @override
  Future<BankQueue> bankQueue(String tab) async {
    return BankQueue.fromJson(_ok(await _send('GET', '/api/bank/queue?tab=$tab')));
  }

  @override
  Future<BankTranche> bankTranche(String id) async {
    return BankTranche.fromJson(_ok(await _send('GET', '/api/bank/tranches/$id')));
  }

  BankTranche _card(http.Response response) {
    final json = _ok(response);
    return BankTranche.fromJson(Map<String, dynamic>.from(json['card'] as Map));
  }

  @override
  Future<BankTranche> bankChoose({
    required String trancheId,
    required String lineId,
    required String choice,
  }) async {
    return _card(await _send(
      'POST',
      '/api/bank/tranches/$trancheId/lines/$lineId/choice',
      body: {'choice': choice},
      csrf: true,
    ));
  }

  @override
  Future<BankTranche> bankWaive({
    required String trancheId,
    required String checkId,
    required String reason,
    required String comment,
  }) async {
    return _card(await _send(
      'POST',
      '/api/bank/tranches/$trancheId/checks/$checkId/waive',
      body: {'reason': reason, 'comment': comment},
      csrf: true,
    ));
  }

  @override
  Future<BankTranche> bankRequest({required String trancheId, required String checkId}) async {
    return _card(await _send(
      'POST',
      '/api/bank/tranches/$trancheId/checks/$checkId/request',
      body: const {},
      csrf: true,
    ));
  }

  @override
  Future<BankTranche> bankResume(String trancheId) async {
    return _card(await _send(
      'POST',
      '/api/bank/tranches/$trancheId/resume',
      body: const {},
      csrf: true,
    ));
  }

  @override
  Future<BankTranche> bankDecide({
    required String trancheId,
    required String kind,
    required String idempotencyKey,
    String note = '',
  }) async {
    return _card(await _send(
      'POST',
      '/api/bank/tranches/$trancheId/decision',
      body: {'kind': kind, 'note': note},
      csrf: true,
      idempotencyKey: idempotencyKey,
    ));
  }

  @override
  Future<List<BankJournalEntry>> bankJournal(String trancheId) async {
    final json = _ok(await _send('GET', '/api/bank/tranches/$trancheId/journal'));
    return [
      for (final item in json['events'] as List<dynamic>? ?? const [])
        if (item is Map) BankJournalEntry.fromJson(item.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  @override
  Future<BankApproval> bankApproval(String trancheId) async {
    return BankApproval.fromJson(_ok(await _send('GET', '/api/bank/tranches/$trancheId/approval')));
  }

  @override
  Future<BankApproval> bankVote({
    required String trancheId,
    required String vote,
    String comment = '',
  }) async {
    final json = _ok(await _send(
      'POST',
      '/api/bank/tranches/$trancheId/approval',
      body: {'vote': vote, 'comment': comment},
      csrf: true,
    ));
    return BankApproval.fromJson(Map<String, dynamic>.from(json['approval'] as Map));
  }

  @override
  Future<ApplicationReceipt> submitApplication({
    required String kind,
    required Map<String, Object?> data,
    String trap = '',
  }) async {
    final csrf = _ok(await _send('GET', '/api/auth/csrf'));
    _csrf = csrf['csrfToken'] as String?;
    final response = await _send(
      'POST',
      '/api/applications',
      body: {
        'kind': kind,
        'data': data,
        'consents': const ['personal_data', 'truth'],
        'website_url': trap,
      },
      csrf: true,
    );
    return ApplicationReceipt.fromJson(_ok(response));
  }

  @override
  Future<void> uploadApplicationDocument({
    required String id,
    required String token,
    required String type,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final uri = _uri('/api/applications/$id/documents').replace(
      queryParameters: {'type': type, 'name': fileName},
    );
    try {
      final response = await _client.post(
        uri,
        headers: {
          'content-type': 'application/octet-stream',
          'x-application-token': token,
          'x-csrf-token': ?_csrf,
        },
        body: bytes,
      );
      _ok(response);
    } on http.ClientException {
      throw const ApiException(0, 'Нет связи с сервером.');
    }
  }

  @override
  Future<ApplicationStatusView> applicationStatus(String token) async {
    final csrf = _ok(await _send('GET', '/api/auth/csrf'));
    _csrf = csrf['csrfToken'] as String?;
    try {
      final response = await _client.get(
        _uri('/api/applications/status'),
        headers: {'x-application-token': token},
      );
      return ApplicationStatusView.fromJson(_ok(response));
    } on http.ClientException {
      throw const ApiException(0, 'Нет связи с сервером.');
    }
  }

  @override
  Future<ApplicationBoard> applications({
    String kind = '',
    String status = '',
    String query = '',
  }) async {
    final path = Uri(path: '/api/admin/applications', queryParameters: {
      if (kind.isNotEmpty) 'kind': kind,
      if (status.isNotEmpty) 'status': status,
      if (query.isNotEmpty) 'q': query,
    }).toString();
    return ApplicationBoard.fromJson(_ok(await _send('GET', path)));
  }

  @override
  Future<ApplicationDetail> applicationDetail(String id) async {
    return ApplicationDetail.fromJson(_ok(await _send('GET', '/api/admin/applications/$id')));
  }

  @override
  Future<ApplicationDetail> setApplicationStatus({
    required String id,
    required String status,
    String note = '',
  }) async {
    final response = await _send(
      'POST',
      '/api/admin/applications/$id/status',
      body: {'status': status, 'note': note},
      csrf: true,
    );
    return ApplicationDetail.fromJson(_ok(response));
  }

  @override
  Future<ApplicationDetail> logApplicationCall({
    required String id,
    required String outcome,
    String note = '',
    String nextCallOn = '',
  }) async {
    final response = await _send(
      'POST',
      '/api/admin/applications/$id/calls',
      body: {'outcome': outcome, 'note': note, 'nextCallOn': nextCallOn},
      csrf: true,
    );
    return ApplicationDetail.fromJson(_ok(response));
  }

  @override
  Future<ApplicationDetail> addApplicationNote({required String id, required String body}) async {
    final response = await _send(
      'POST',
      '/api/admin/applications/$id/notes',
      body: {'body': body},
      csrf: true,
    );
    return ApplicationDetail.fromJson(_ok(response));
  }

  @override
  Future<ApplicationDetail> setApplicationCheck({
    required String id,
    required String key,
    required bool done,
  }) async {
    final response = await _send(
      'POST',
      '/api/admin/applications/$id/checks',
      body: {'key': key, 'done': done},
      csrf: true,
    );
    return ApplicationDetail.fromJson(_ok(response));
  }

  @override
  Future<ApprovalResult> approveApplication(String id) async {
    final response = await _send(
      'POST',
      '/api/admin/applications/$id/approve',
      body: const {},
      csrf: true,
    );
    return ApprovalResult.fromJson(_ok(response));
  }

  @override
  Future<Map<String, dynamic>> getJson(String path) async => _ok(await _send('GET', path));

  @override
  Future<Map<String, dynamic>> postJson(String path, Map<String, Object?> body) async {
    return _ok(await _send('POST', path, body: body, csrf: true));
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool csrf = false,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      if (body != null) 'content-type': 'application/json',
      if (csrf && _csrf != null) 'x-csrf-token': _csrf!,
      'idempotency-key': ?idempotencyKey,
    };
    final uri = _uri(path);
    final encoded = body == null ? null : jsonEncode(body);
    try {
      return await switch (method) {
        'POST' => _client.post(uri, headers: headers, body: encoded),
        'PATCH' => _client.patch(uri, headers: headers, body: encoded),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => _client.get(uri, headers: headers),
      };
    } on http.ClientException {
      // The server could not be reached at all.
      throw const ApiException(0, 'Нет связи с сервером.');
    }
  }

  Map<String, dynamic> _ok(http.Response response) {
    Map<String, dynamic> json = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        json = decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        json['message'] as String? ?? 'Что-то пошло не так. Попробуйте ещё раз.',
        field: json['field'] as String?,
      );
    }
    return json;
  }
}
