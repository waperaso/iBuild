import 'dart:typed_data';

import 'fx.dart';
import 'models.dart';
import 'registration_models.dart';
import 'screens/bank/bank_models.dart';

class ApiException implements Exception {
  const ApiException(this.status, this.message, {this.field});

  final int status;
  final String message;

  /// The form field the server did not accept, when it says so.
  final String? field;

  @override
  String toString() => message;
}

abstract class Api {
  Future<UserProfile?> me();
  Future<UserProfile> login(String login, String password);
  Future<bool> demoEnabled();
  Future<UserProfile> demoLogin(String role);
  Future<void> logout();
  Future<void> changePassword(String current, String next);
  Future<List<ProjectSummary>> projects();
  Future<ProjectSummary> project(String id);
  Future<List<ProjectDocument>> projectDocuments(String projectId);
  Future<ProjectSummary> createProject({
    required String name,
    required String address,
  });
  Future<BudgetSnapshot> budget(String projectId);
  Future<List<ProjectMember>> members(String projectId);
  Future<List<ContractorFirm>> firms();
  Future<List<CompanyUser>> companyUsers();
  Future<void> createBudgetLine({
    required String projectId,
    required String title,
    required String amount,
    required String contractorFirmId,
  });
  Future<void> updateBudgetLine({
    required String projectId,
    required String itemId,
    required String title,
    required String amount,
    required String contractorFirmId,
  });
  Future<void> deleteBudgetLine({
    required String projectId,
    required String itemId,
  });
  Future<void> removeMember({
    required String projectId,
    required String memberId,
  });
  Future<void> createFirm({
    required String name,
    required String inn,
    required String contact,
  });
  Future<void> addMember({
    required String projectId,
    required String userId,
    required String role,
    String? contractorFirmId,
  });
  Future<List<FundingRequest>> requests();
  Future<FundingRequest> request(String id);
  Future<void> contactRequest({required String id, required String message});
  Future<FundingRequest> createRequest({
    required String projectId,
    required String budgetItemId,
    required String amount,
    required String description,
    String? customTitle,
  });
  Future<FundingRequest> updateRequest({
    required String id,
    required String budgetItemId,
    required String amount,
    required String description,
  });
  Future<RequestFile> uploadRequestFile({
    required String requestId,
    required Uint8List bytes,
  });
  Future<Uint8List> requestFile({
    required String requestId,
    required String fileId,
  });
  Future<void> deleteRequestFile({
    required String requestId,
    required String fileId,
  });
  Future<FundingRequest> submitRequest({
    required String id,
    required int version,
    required String idempotencyKey,
    String? addresseeUserId,
  });
  Future<FundingRequest> deliverRequest({
    required String id,
    required int version,
    required String addresseeUserId,
    required String idempotencyKey,
  });
  Future<FundingRequest> cancelRequest({
    required String id,
    required int version,
    required String idempotencyKey,
  });
  Future<FundingRequest> techDecision({
    required String id,
    required int version,
    required String decision,
    required String reason,
    required String idempotencyKey,
  });
  Future<FundingRequest> approveRequest({
    required String id,
    required int version,
    required String idempotencyKey,
  });
  Future<FundingRequest> rejectRequest({
    required String id,
    required int version,
    required String reason,
    required String idempotencyKey,
  });
  Future<FundingRequest> recordPayment({
    required String id,
    required int version,
    required String paidOn,
    required String paymentNumber,
    required String idempotencyKey,
  });
  Future<FundingRequest> withdrawApproval({
    required String id,
    required int version,
    required String reason,
    required String idempotencyKey,
  });
  Future<FundingRequest> copyRejected({
    required String id,
    required int version,
    required String idempotencyKey,
  });
  Future<RequestFile> uploadPaymentFile({
    required String requestId,
    required Uint8List bytes,
  });
  Future<void> deletePaymentFile({
    required String requestId,
    required String fileId,
  });
  Future<List<NoticeItem>> notices();
  Future<UsdQuote> usdRate();
  Future<List<InspectionOrder>> inspections();
  Future<void> requestInspection({
    required String projectId,
    required String scheduledOn,
    required String note,
    String? requestId,
  });
  Future<void> reportInspection({
    required String id,
    required String note,
    required List<Map<String, String>> lines,
  });
  Future<LoanDesk> loan(String projectId);
  Future<void> importBudget({
    required String projectId,
    required String contractorFirmId,
    required String csv,
  });
  Future<void> copyBudget({
    required String projectId,
    required String fromProjectId,
  });
  Future<String> addSource({
    required String projectId,
    required String name,
    required String kind,
    required String amount,
  });
  Future<String> saveBudgetTemplate({
    required String projectId,
    required String name,
  });
  Future<void> applyBudgetTemplate({
    required String projectId,
    required String templateId,
    required String contractorFirmId,
  });
  Future<String> createDraw({required String projectId, required String name});
  Future<DrawDetail> draw(String id);
  Future<DrawDetail> saveDraw({
    required String id,
    required String name,
    required bool finalDraw,
    required String signedName,
    required List<DrawLineInput> lines,
    required List<Map<String, String>> sources,
    required List<Map<String, String>> requirements,
  });
  Future<DrawDetail> submitDraw(String id);
  Future<DrawDetail> decideDraw({
    required String id,
    required List<Map<String, String>> lines,
  });
  Future<void> inspect({
    required String projectId,
    required String requestId,
    required String scheduledOn,
    required String gateCode,
    required String note,
    required List<Map<String, String>> lines,
  });
  Future<void> commentDraw({required String id, required String body});
  Future<void> addPayable({
    required String id,
    required String budgetItemId,
    required String firmId,
    required String number,
    required String amount,
    required String waiver,
  });
  Future<String> drawPackage(String id);
  Future<void> updateCompliance({
    required String firmId,
    required String insuranceUntil,
    required String licenseUntil,
  });
  Future<List<ProjectChange>> projectChanges(String projectId);
  Future<ProjectChange> proposeProjectChange({
    required String projectId,
    required String name,
    required String address,
    Uint8List? photo,
  });
  Future<Uint8List?> projectPhoto(String projectId);
  Future<Uint8List?> changePhoto(String changeId);
  Future<List<ProjectChange>> moderationQueue();
  Future<void> approveProjectChange(String id);
  Future<void> rejectProjectChange({required String id, required String note});
  Future<BankQueue> bankQueue(String tab);
  Future<BankTranche> bankTranche(String id);

  /// What to pay out for one line: confirmed, requested or withhold.
  Future<BankTranche> bankChoose({
    required String trancheId,
    required String lineId,
    required String choice,
  });
  Future<BankTranche> bankWaive({
    required String trancheId,
    required String checkId,
    required String reason,
    required String comment,
  });
  Future<BankTranche> bankRequest({required String trancheId, required String checkId});
  Future<BankTranche> bankResume(String trancheId);

  /// kind: partial, return_all, control_measure or suspend. The key makes a repeated send harmless.
  Future<BankTranche> bankDecide({
    required String trancheId,
    required String kind,
    required String idempotencyKey,
    String note = '',
  });
  Future<BankApproval> bankApproval(String trancheId);
  Future<List<BankJournalEntry>> bankJournal(String trancheId);
  Future<BankApproval> bankVote({
    required String trancheId,
    required String vote,
    String comment = '',
  });

  // Sign-up of new companies (public) and the admin's CRM for it.
  Future<ApplicationReceipt> submitApplication({
    required String kind,
    required Map<String, Object?> data,
    String trap = '',
  });
  Future<void> uploadApplicationDocument({
    required String id,
    required String token,
    required String type,
    required String fileName,
    required Uint8List bytes,
  });
  Future<ApplicationStatusView> applicationStatus(String token);
  Future<ApplicationBoard> applications({String kind = '', String status = '', String query = ''});
  Future<ApplicationDetail> applicationDetail(String id);
  Future<ApplicationDetail> setApplicationStatus({
    required String id,
    required String status,
    String note = '',
  });
  Future<ApplicationDetail> logApplicationCall({
    required String id,
    required String outcome,
    String note = '',
    String nextCallOn = '',
  });
  Future<ApplicationDetail> addApplicationNote({required String id, required String body});
  Future<ApplicationDetail> setApplicationCheck({
    required String id,
    required String key,
    required bool done,
  });
  Future<ApprovalResult> approveApplication(String id);

  /// The modules of the bank cabinet and the platform admin read and write plain
  /// JSON; each screen picks out what it shows. Both calls throw [ApiException].
  Future<Map<String, dynamic>> getJson(String path);
  Future<Map<String, dynamic>> postJson(String path, Map<String, Object?> body);
}
