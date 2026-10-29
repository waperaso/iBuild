import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/api.dart';
import 'package:ibuild/app.dart';
import 'package:ibuild/fx.dart';
import 'package:ibuild/models.dart';
import 'package:ibuild/registration_models.dart';
import 'package:ibuild/screens/bank/bank_models.dart';
import 'package:ibuild/session.dart';

import 'bank_fixtures.dart';

class FakeApi implements Api {
  FakeApi({
    this.user,
    List<ProjectSummary>? projects,
    this.rejectPassword = false,
    List<BudgetLine>? lines,
    List<ProjectMember>? members,
    List<ContractorFirm>? firms,
  }) : stored = List.of(projects ?? const []),
       lines = List.of(lines ?? const []),
       storedMembers = List.of(members ?? const []),
       storedFirms = List.of(firms ?? const []);

  static const _draft = FundingRequest(
    id: 'draft-1',
    projectId: 'project-1',
    projectName: 'ЖК Навои',
    budgetItemId: 'line-1',
    lineTitle: 'Кладка',
    amount: '1000.00',
    description: 'Кладка секции А',
    status: 'draft',
    mine: true,
    version: 1,
    files: [],
  );

  UserProfile? user;
  List<ProjectSummary> stored;
  List<BudgetLine> lines;
  List<ProjectMember> storedMembers;
  List<ContractorFirm> storedFirms;
  bool rejectPassword;
  String? deletedLineId;
  String? removedMemberId;
  final submissions = <({String kind, Map<String, Object?> data, String trap})>[];
  final uploadedDocs = <String>[];
  final applicationActions = <String>[];
  ApiException? submitError;
  ApplicationBoard board = const ApplicationBoard(counts: {}, items: []);
  ApplicationDetail? detailFixture;
  ApplicationStatusView? statusFixture;
  ApprovalResult? approvalFixture;

  @override
  Future<UserProfile?> me() async => user;

  @override
  Future<UserProfile> login(String login, String password) async {
    if (rejectPassword || password == 'wrong') {
      throw const ApiException(401, 'Неверный логин или пароль.');
    }
    user = demoUser(AppRole.contractor);
    stored = [demoProject(AppRole.contractor)];
    return user!;
  }

  @override
  Future<void> changePassword(String current, String next) async {
    passwordCalls.add((current, next));
    if (current == 'wrong') throw const ApiException(400, 'Текущий пароль указан неверно.');
    final old = user;
    if (old != null) {
      user = UserProfile(
        id: old.id,
        name: old.name,
        login: old.login,
        companyId: old.companyId,
        companyName: old.companyName,
        active: old.active,
        memberships: old.memberships,
        platformAdmin: old.platformAdmin,
        bank: old.bank,
      );
    }
  }

  final passwordCalls = <(String, String)>[];

  @override
  Future<void> logout() async {
    user = null;
  }

  @override
  Future<List<ProjectSummary>> projects() async => stored;

  @override
  Future<List<ProjectDocument>> projectDocuments(String projectId) async => const [];

  @override
  Future<ProjectSummary> project(String id) async {
    for (final item in stored) {
      if (item.id == id) return item;
    }
    throw const ApiException(404, 'Объект не найден.');
  }

  @override
  Future<BudgetSnapshot> budget(String projectId) async {
    return BudgetSnapshot(
      locked: false,
      plan: null,
      reserved: null,
      paid: null,
      available: null,
      items: lines,
    );
  }

  @override
  Future<List<ProjectMember>> members(String projectId) async => storedMembers;

  @override
  Future<List<ContractorFirm>> firms() async => storedFirms;

  @override
  Future<List<CompanyUser>> companyUsers() async => const [];

  @override
  Future<void> createBudgetLine({
    required String projectId,
    required String title,
    required String amount,
    required String contractorFirmId,
  }) async {}

  @override
  Future<void> updateBudgetLine({
    required String projectId,
    required String itemId,
    required String title,
    required String amount,
    required String contractorFirmId,
  }) async {
    lines = [
      for (final line in lines)
        if (line.id == itemId)
          BudgetLine(
            id: line.id,
            title: title,
            amount: amount,
            contractorFirmId: contractorFirmId,
            contractorFirmName: line.contractorFirmName,
          )
        else
          line,
    ];
  }

  @override
  Future<void> deleteBudgetLine({
    required String projectId,
    required String itemId,
  }) async {
    deletedLineId = itemId;
    lines = [
      for (final line in lines)
        if (line.id != itemId) line,
    ];
  }

  @override
  Future<void> removeMember({
    required String projectId,
    required String memberId,
  }) async {
    removedMemberId = memberId;
    storedMembers = [
      for (final member in storedMembers)
        if (member.id != memberId) member,
    ];
  }

  @override
  Future<void> createFirm({
    required String name,
    required String inn,
    required String contact,
  }) async {}

  @override
  Future<void> addMember({
    required String projectId,
    required String userId,
    required String role,
    String? contractorFirmId,
  }) async {}

  @override
  Future<List<FundingRequest>> requests() async => [_draft];

  FundingRequest? shownRequest;

  @override
  Future<FundingRequest> request(String id) async {
    if (shownRequest != null && shownRequest!.id == id) return shownRequest!;
    if (id == _draft.id) return _draft;
    throw const ApiException(404, 'Транш не найден.');
  }

  @override
  @override
  Future<void> contactRequest({required String id, required String message}) async {}

  @override
  Future<FundingRequest> createRequest({
    required String projectId,
    required String budgetItemId,
    required String amount,
    required String description,
    String? customTitle,
  }) async {
    return FundingRequest(
      id: 'request-1',
      projectId: projectId,
      projectName: 'ЖК Навои',
      budgetItemId: budgetItemId,
      lineTitle: 'Кладка',
      amount: amount,
      description: description,
      status: 'draft',
      mine: true,
      version: 1,
      files: const [],
    );
  }

  @override
  Future<FundingRequest> updateRequest({
    required String id,
    required String budgetItemId,
    required String amount,
    required String description,
  }) async {
    return FundingRequest(
      id: id,
      projectId: 'project-1',
      projectName: 'ЖК Навои',
      budgetItemId: budgetItemId,
      lineTitle: 'Кладка',
      amount: amount,
      description: description,
      status: 'draft',
      mine: true,
      version: 1,
      files: const [],
    );
  }

  @override
  Future<FundingRequest> submitRequest({
    required String id,
    required int version,
    required String idempotencyKey,
    String? addresseeUserId,
  }) async {
    return _moved(id, 'submitted', version + 1);
  }

  @override
  Future<FundingRequest> deliverRequest({
    required String id,
    required int version,
    required String addresseeUserId,
    required String idempotencyKey,
  }) async {
    return _moved(id, 'approved', version + 1);
  }

  @override
  Future<FundingRequest> cancelRequest({
    required String id,
    required int version,
    required String idempotencyKey,
  }) async {
    return _moved(id, 'cancelled', version + 1);
  }

  @override
  Future<FundingRequest> techDecision({
    required String id,
    required int version,
    required String decision,
    required String reason,
    required String idempotencyKey,
  }) async {
    return _moved(id, decision == 'approve' ? 'tech_approved' : 'rejected', version + 1);
  }

  @override
  Future<FundingRequest> approveRequest({
    required String id,
    required int version,
    required String idempotencyKey,
  }) async {
    return _moved(id, 'approved', version + 1);
  }

  @override
  Future<FundingRequest> rejectRequest({
    required String id,
    required int version,
    required String reason,
    required String idempotencyKey,
  }) async {
    return _moved(id, 'rejected', version + 1);
  }

  @override
  Future<FundingRequest> recordPayment({
    required String id,
    required int version,
    required String paidOn,
    required String paymentNumber,
    required String idempotencyKey,
  }) async {
    return _moved(id, 'paid', version + 1);
  }

  @override
  Future<FundingRequest> withdrawApproval({
    required String id,
    required int version,
    required String reason,
    required String idempotencyKey,
  }) async {
    return _moved(id, 'cancelled', version + 1);
  }

  @override
  Future<FundingRequest> copyRejected({
    required String id,
    required int version,
    required String idempotencyKey,
  }) async {
    return _moved('copied-$id', 'draft', 1);
  }

  @override
  Future<RequestFile> uploadPaymentFile({
    required String requestId,
    required Uint8List bytes,
  }) async {
    return RequestFile(
      id: 'payment-file',
      contentType: 'image/jpeg',
      sizeBytes: bytes.length,
      kind: 'photo',
      purpose: 'payment',
    );
  }

  @override
  Future<void> deletePaymentFile({
    required String requestId,
    required String fileId,
  }) async {}

  FundingRequest _moved(String id, String status, int version) {
    return FundingRequest(
      id: id,
      projectId: 'project-1',
      projectName: 'ЖК Навои',
      budgetItemId: 'line-1',
      lineTitle: 'Кладка',
      amount: '10.00',
      description: '',
      status: status,
      mine: true,
      version: version,
      files: const [],
    );
  }

  @override
  Future<RequestFile> uploadRequestFile({
    required String requestId,
    required Uint8List bytes,
  }) async {
    return RequestFile(
      id: 'file-1',
      contentType: 'image/jpeg',
      sizeBytes: bytes.length,
      kind: 'photo',
    );
  }

  @override
  Future<Uint8List> requestFile({
    required String requestId,
    required String fileId,
  }) async {
    return Uint8List(0);
  }

  @override
  Future<void> deleteRequestFile({
    required String requestId,
    required String fileId,
  }) async {}

  @override
  Future<ProjectSummary> createProject({
    required String name,
    required String address,
  }) async {
    final created = ProjectSummary(
      id: 'project-new',
      companyId: 'company-1',
      name: name,
      address: address,
      active: true,
      myRole: AppRole.director,
    );
    stored = [...stored, created];
    return created;
  }

  LoanDesk desk = LoanDesk.empty;
  DrawDetail? storedDraw;

  @override
  Future<List<NoticeItem>> notices() async => const [];

  @override
  Future<UsdQuote> usdRate() async => const UsdQuote(rate: '12850.50', date: '20.10.2026');

  @override
  Future<List<InspectionOrder>> inspections() async => const [];

  @override
  Future<void> requestInspection({
    required String projectId,
    required String scheduledOn,
    required String note,
    String? requestId,
  }) async {}

  @override
  Future<void> reportInspection({
    required String id,
    required String note,
    required List<Map<String, String>> lines,
  }) async {}

  @override
  Future<LoanDesk> loan(String projectId) async => desk;

  @override
  Future<void> importBudget({
    required String projectId,
    required String contractorFirmId,
    required String csv,
  }) async {}

  @override
  Future<void> copyBudget({
    required String projectId,
    required String fromProjectId,
  }) async {}

  @override
  Future<String> addSource({
    required String projectId,
    required String name,
    required String kind,
    required String amount,
  }) async => 'source-1';

  @override
  Future<String> saveBudgetTemplate({
    required String projectId,
    required String name,
  }) async => 'template-1';

  @override
  Future<void> applyBudgetTemplate({
    required String projectId,
    required String templateId,
    required String contractorFirmId,
  }) async {}

  @override
  Future<String> createDraw({required String projectId, required String name}) async {
    storedDraw = DrawDetail(
      id: 'draw-1',
      projectId: projectId,
      name: name,
      status: 'draft',
      finalDraw: false,
      version: 1,
      amount: '0.01',
      requested: '',
      confirmed: '',
      signedName: '',
      lines: const [],
      sources: const [],
      requirements: const [
        DrawRequirementView(
          itemId: 'item-act',
          code: 'act',
          title: 'Акт выполненных работ',
          required: true,
          status: 'missing',
          note: '',
        ),
      ],
      comments: const [],
    );
    return 'draw-1';
  }

  @override
  Future<DrawDetail> draw(String id) async => storedDraw!;

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
    storedDraw = DrawDetail(
      id: id,
      projectId: storedDraw?.projectId ?? 'project-1',
      name: name,
      status: 'draft',
      finalDraw: finalDraw,
      version: 2,
      amount: '0.01',
      requested: '',
      confirmed: '',
      signedName: signedName,
      lines: lines,
      sources: const [],
      requirements: storedDraw?.requirements ?? const [],
      comments: const [],
    );
    return storedDraw!;
  }

  @override
  Future<DrawDetail> submitDraw(String id) async {
    final current = storedDraw!;
    storedDraw = DrawDetail(
      id: current.id,
      projectId: current.projectId,
      name: current.name,
      status: 'submitted',
      finalDraw: current.finalDraw,
      version: current.version + 1,
      amount: '100.00',
      requested: '100.00',
      confirmed: '',
      signedName: current.signedName,
      lines: current.lines,
      sources: current.sources,
      requirements: current.requirements,
      comments: current.comments,
    );
    return storedDraw!;
  }

  @override
  Future<DrawDetail> decideDraw({
    required String id,
    required List<Map<String, String>> lines,
  }) async => storedDraw!;

  @override
  Future<void> inspect({
    required String projectId,
    required String requestId,
    required String scheduledOn,
    required String gateCode,
    required String note,
    required List<Map<String, String>> lines,
  }) async {}

  @override
  Future<void> commentDraw({required String id, required String body}) async {}

  @override
  Future<void> addPayable({
    required String id,
    required String budgetItemId,
    required String firmId,
    required String number,
    required String amount,
    required String waiver,
  }) async {}

  @override
  Future<String> drawPackage(String id) async => 'Пакет транша';

  @override
  Future<void> updateCompliance({
    required String firmId,
    required String insuranceUntil,
    required String licenseUntil,
  }) async {}

  List<ProjectChange> changes = const [];

  @override
  Future<List<ProjectChange>> projectChanges(String projectId) async => changes;

  @override
  Future<ApplicationReceipt> submitApplication({
    required String kind,
    required Map<String, Object?> data,
    String trap = '',
  }) async {
    if (submitError != null) throw submitError!;
    submissions.add((kind: kind, data: data, trap: trap));
    return const ApplicationReceipt(id: 'app-1', code: 'IB-00001', token: 'token-1');
  }

  @override
  Future<void> uploadApplicationDocument({
    required String id,
    required String token,
    required String type,
    required String fileName,
    required Uint8List bytes,
  }) async {
    uploadedDocs.add(type);
  }

  @override
  Future<ApplicationStatusView> applicationStatus(String token) async {
    final found = statusFixture;
    if (found == null || token == 'nope') {
      throw const ApiException(404, 'Заявка не найдена. Проверьте ссылку.');
    }
    return found;
  }

  @override
  Future<ApplicationBoard> applications({
    String kind = '',
    String status = '',
    String query = '',
  }) async {
    applicationActions.add('list:$kind:$status:$query');
    return board;
  }

  @override
  Future<ApplicationDetail> applicationDetail(String id) async => detailFixture!;

  @override
  Future<ApplicationDetail> setApplicationStatus({
    required String id,
    required String status,
    String note = '',
  }) async {
    applicationActions.add('status:$status:$note');
    return detailFixture!;
  }

  @override
  Future<ApplicationDetail> logApplicationCall({
    required String id,
    required String outcome,
    String note = '',
    String nextCallOn = '',
  }) async {
    applicationActions.add('call:$outcome:$note:$nextCallOn');
    return detailFixture!;
  }

  @override
  Future<ApplicationDetail> addApplicationNote({required String id, required String body}) async {
    applicationActions.add('note:$body');
    return detailFixture!;
  }

  @override
  Future<ApplicationDetail> setApplicationCheck({
    required String id,
    required String key,
    required bool done,
  }) async {
    applicationActions.add('check:$key:$done');
    return detailFixture!;
  }

  @override
  Future<ApprovalResult> approveApplication(String id) async {
    applicationActions.add('approve');
    return approvalFixture!;
  }

  @override
  Future<ProjectChange> proposeProjectChange({
    required String projectId,
    required String name,
    required String address,
    Uint8List? photo,
  }) async {
    return ProjectChange(
      id: 'change-1',
      projectId: projectId,
      currentName: 'ЖК Навои',
      currentAddress: address,
      name: name,
      address: address,
      status: 'pending',
      hasPhoto: photo != null,
    );
  }

  @override
  Future<Uint8List?> projectPhoto(String projectId) async => null;

  @override
  Future<Uint8List?> changePhoto(String changeId) async => null;

  @override
  Future<List<ProjectChange>> moderationQueue() async => changes;

  @override
  Future<void> approveProjectChange(String id) async {}

  @override
  Future<void> rejectProjectChange({required String id, required String note}) async {}

  List<BankQueueItem>? bankItems;
  BankTranche? bankCard;
  final bankTabsAsked = <String>[];
  bool bankFails = false;

  @override
  Future<BankQueue> bankQueue(String tab) async {
    bankTabsAsked.add(tab);
    if (bankFails) throw const ApiException(500, 'Ошибка сервера');
    return sampleBankQueue(tab, bankItems);
  }

  @override
  Future<BankTranche> bankTranche(String id) async {
    if (bankFails) throw const ApiException(500, 'Ошибка сервера');
    final card = bankCard ?? sampleBankTranche(id: id);
    if (card.id != id) throw const ApiException(404, 'Ничего не найдено.');
    return card;
  }

  /// Every change of the bank cabinet, in order, for example "choose:l2:withhold".
  final bankCalls = <String>[];
  BankTranche? bankAfterAction;
  BankApproval? bankApprovalCard;
  ApiException? bankActionFails;

  BankTranche _afterAction(String call) {
    bankCalls.add(call);
    final failure = bankActionFails;
    if (failure != null) throw failure;
    return bankAfterAction ?? bankCard ?? sampleBankTranche();
  }

  @override
  Future<BankTranche> bankChoose({
    required String trancheId,
    required String lineId,
    required String choice,
  }) async => _afterAction('choose:$lineId:$choice');

  @override
  Future<BankTranche> bankWaive({
    required String trancheId,
    required String checkId,
    required String reason,
    required String comment,
  }) async => _afterAction('waive:$checkId:$reason:$comment');

  @override
  Future<BankTranche> bankRequest({required String trancheId, required String checkId}) async =>
      _afterAction('request:$checkId');

  @override
  Future<BankTranche> bankResume(String trancheId) async => _afterAction('resume');

  @override
  Future<BankTranche> bankDecide({
    required String trancheId,
    required String kind,
    required String idempotencyKey,
    String note = '',
  }) async => _afterAction('decide:$kind:$note:$idempotencyKey');

  /// Answers of the JSON modules by path (without the query). `jsonCalls` keeps what was sent.
  final Map<String, Map<String, dynamic>> jsonAnswers = {};
  final List<(String, Map<String, Object?>?)> jsonCalls = [];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    jsonCalls.add((path, null));
    if (bankFails) throw const ApiException(500, 'Ошибка сервера');
    final answer = jsonAnswers[path] ?? jsonAnswers[path.split('?').first];
    if (answer == null) throw const ApiException(404, 'Не найдено');
    return answer;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, Map<String, Object?> body) async {
    jsonCalls.add((path, body));
    if (bankFails) throw const ApiException(500, 'Ошибка сервера');
    return jsonAnswers[path] ?? {'ok': true};
  }

  List<BankJournalEntry> bankJournalEntries = const [];

  @override
  Future<List<BankJournalEntry>> bankJournal(String trancheId) async {
    if (bankFails) throw const ApiException(500, 'Ошибка сервера');
    return bankJournalEntries;
  }

  @override
  Future<BankApproval> bankApproval(String trancheId) async {
    if (bankFails) throw const ApiException(500, 'Ошибка сервера');
    return bankApprovalCard ?? sampleBankApproval();
  }

  @override
  Future<BankApproval> bankVote({
    required String trancheId,
    required String vote,
    String comment = '',
  }) async {
    bankCalls.add('vote:$vote:$comment');
    final failure = bankActionFails;
    if (failure != null) throw failure;
    return bankApprovalCard ?? sampleBankApproval();
  }
}

UserProfile demoUser(AppRole role) {
  return UserProfile(
    id: 'user-1',
    name: role.name,
    login: 'demo',
    companyId: 'company-1',
    companyName: 'Навои Девелопмент',
    active: true,
    memberships: const [],
  ).let(role);
}

extension on UserProfile {
  UserProfile let(AppRole role) {
    return UserProfile(
      id: id,
      name: name,
      login: login,
      companyId: companyId,
      companyName: companyName,
      active: active,
      platformAdmin: platformAdmin,
      bank: bank,
      memberships: [Membership(projectId: 'project-1', role: role)],
    );
  }
}

ProjectSummary demoProject(AppRole role) {
  return ProjectSummary(
    id: 'project-1',
    companyId: 'company-1',
    name: 'ЖК Навои',
    address: 'Ташкент, улица Бабура, 12',
    active: true,
    myRole: role,
  );
}

Future<FakeApi> pumpIBuild(
  WidgetTester tester, {
  UserProfile? user,
  List<ProjectSummary>? projects,
  bool rejectPassword = false,
  List<BudgetLine>? lines,
  List<ProjectMember>? members,
  Size size = const Size(1280, 800),
}) async {
  final api = FakeApi(
    user: user,
    projects:
        projects ??
        (user == null ? const [] : [demoProject(user.memberships.first.role)]),
    rejectPassword: rejectPassword,
    lines: lines,
    members: members,
  );
  await pumpIBuildWith(tester, api, size: size);
  return api;
}

/// Starts the app on an api that the test has already set up.
Future<void> pumpIBuildWith(
  WidgetTester tester,
  FakeApi api, {
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final session = SessionController(api);
  await session.restore();
  await tester.pumpWidget(
    IBuildApp(
      key: UniqueKey(),
      api: api,
      session: session,
      restoreOnStart: false,
    ),
  );
  await tester.pumpAndSettle();
}
