enum AppRole {
  director,
  contractor,
  tech,
  observer,
  developer,
  platform;

  static AppRole parse(String raw) {
    return switch (raw) {
      'director' => AppRole.director,
      'contractor' => AppRole.contractor,
      'tech' => AppRole.tech,
      'observer' => AppRole.observer,
      'developer' => AppRole.developer,
      'platform' => AppRole.platform,
      _ => throw FormatException('Unknown role: $raw'),
    };
  }

  String get wire => switch (this) {
    AppRole.director => 'director',
    AppRole.contractor => 'contractor',
    AppRole.tech => 'tech',
    AppRole.observer => 'observer',
    AppRole.developer => 'developer',
    AppRole.platform => 'platform',
  };
}

class Membership {
  const Membership({required this.projectId, required this.role});

  final String projectId;
  final AppRole role;

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      projectId: json['projectId'] as String,
      role: AppRole.parse(json['role'] as String),
    );
  }
}

class BankProfile {
  const BankProfile({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.title,
    required this.branch,
    required this.queueCount,
    required this.trancheCount,
    required this.waitingAmount,
  });

  final String id;
  final String name;
  final String department;
  final String role;
  final String title;
  final String branch;
  final int queueCount;
  final int trancheCount;
  final String waitingAmount;

  factory BankProfile.fromJson(Map<String, dynamic> json) {
    return BankProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String? ?? '',
      role: json['role'] as String,
      title: json['title'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      queueCount: json['queueCount'] as int? ?? 0,
      trancheCount: json['trancheCount'] as int? ?? 0,
      waitingAmount: json['waitingAmount'] as String? ?? '0.00',
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.login,
    required this.companyId,
    required this.companyName,
    required this.active,
    required this.memberships,
    this.platformAdmin = false,
    this.mustChangePassword = false,
    this.isDemo = false,
    this.bank,
  });

  final String id;
  final String name;
  final String login;
  final String companyId;
  final String companyName;
  final bool active;
  final List<Membership> memberships;
  final bool platformAdmin;
  final bool mustChangePassword;
  final bool isDemo;
  final BankProfile? bank;

  bool get isBank => bank != null;

  bool get isDirector => memberships.any(
    (item) => item.role == AppRole.director || item.role == AppRole.developer,
  );

  bool get isContractor => memberships.any(
    (item) => item.role == AppRole.contractor || item.role == AppRole.developer,
  );

  bool get isDeveloper =>
      memberships.any((item) => item.role == AppRole.developer);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final raw = json['memberships'] as List<dynamic>? ?? const [];
    final bank = json['bank'];
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      login: json['login'] as String,
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String,
      active: json['active'] as bool? ?? true,
      platformAdmin: json['platformAdmin'] as bool? ?? false,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      isDemo: json['demo'] as bool? ?? false,
      bank: bank is Map<String, dynamic>
          ? BankProfile.fromJson(bank)
          : bank is Map
              ? BankProfile.fromJson(bank.map((key, value) => MapEntry(key.toString(), value)))
              : null,
      memberships: [
        for (final item in raw)
          Membership.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.active,
    required this.myRole,
    this.plan,
    this.reserved,
    this.paid,
    this.available,
    this.budgetLocked = false,
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
  final AppRole myRole;
  final String? plan;
  final String? reserved;
  final String? paid;
  final String? available;
  final bool budgetLocked;
  final bool hasPhoto;
  final String companyName;
  final String description;
  final String bankName;
  final String? latitude;
  final String? longitude;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      active: json['active'] as bool? ?? true,
      myRole: AppRole.parse(json['myRole'] as String),
      plan: _moneyField(json['plan']),
      reserved: _moneyField(json['reserved']),
      paid: _moneyField(json['paid']),
      available: _moneyField(json['available']),
      budgetLocked: json['budgetLocked'] as bool? ?? false,
      hasPhoto: json['hasPhoto'] as bool? ?? false,
      companyName: json['companyName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      latitude: _blank(json['latitude']),
      longitude: _blank(json['longitude']),
    );
  }
}

String? _blank(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return text;
}

class ProjectDocument {
  const ProjectDocument({
    required this.id,
    required this.title,
    this.number = '',
    this.issuedOn = '',
    this.note = '',
  });

  final String id;
  final String title;
  final String number;
  final String issuedOn;
  final String note;

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    return ProjectDocument(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      number: json['number'] as String? ?? '',
      issuedOn: json['issuedOn'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class ProjectChange {
  const ProjectChange({
    required this.id,
    required this.projectId,
    required this.currentName,
    required this.currentAddress,
    required this.name,
    required this.address,
    required this.status,
    this.currentHasPhoto = false,
    this.hasPhoto = false,
    this.reviewNote = '',
  });

  final String id;
  final String projectId;
  final String currentName;
  final String currentAddress;
  final String name;
  final String address;
  final String status;
  final bool currentHasPhoto;
  final bool hasPhoto;
  final String reviewNote;

  bool get pending => status == 'pending';

  factory ProjectChange.fromJson(Map<String, dynamic> json) {
    return ProjectChange(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      currentName: json['currentName'] as String? ?? '',
      currentAddress: json['currentAddress'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      currentHasPhoto: json['currentHasPhoto'] as bool? ?? false,
      hasPhoto: json['hasPhoto'] as bool? ?? false,
      reviewNote: json['reviewNote'] as String? ?? '',
    );
  }
}

class BudgetLine {
  const BudgetLine({
    required this.id,
    required this.title,
    required this.amount,
    required this.contractorFirmId,
    required this.contractorFirmName,
    this.reserved = '0.00',
    this.paid = '0.00',
    this.available = '0.00',
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

  factory BudgetLine.fromJson(Map<String, dynamic> json) {
    return BudgetLine(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: _moneyField(json['amount']) ?? '0.00',
      reserved: _moneyField(json['reserved']) ?? '0.00',
      paid: _moneyField(json['paid']) ?? '0.00',
      available: _moneyField(json['available']) ?? '0.00',
      contractorFirmId: json['contractorFirmId'] as String,
      contractorFirmName: json['contractorFirmName'] as String? ?? '',
      planSet: json['planSet'] as bool? ?? true,
    );
  }
}

class ProjectMember {
  const ProjectMember({
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

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      login: json['login'] as String,
      role: json['role'] as String,
      contractorFirmId: json['contractorFirmId'] as String?,
      contractorFirmName: json['contractorFirmName'] as String?,
    );
  }
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

  factory ContractorFirm.fromJson(Map<String, dynamic> json) {
    return ContractorFirm(
      id: json['id'] as String,
      name: json['name'] as String,
      inn: json['inn'] as String,
      contact: json['contact'] as String,
    );
  }
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

  factory CompanyUser.fromJson(Map<String, dynamic> json) {
    return CompanyUser(
      id: json['id'] as String,
      name: json['name'] as String,
      login: json['login'] as String,
      active: json['active'] as bool? ?? true,
    );
  }
}

class BudgetSnapshot {
  const BudgetSnapshot({
    required this.locked,
    required this.plan,
    required this.reserved,
    required this.paid,
    required this.available,
    required this.items,
  });

  final bool locked;
  final String? plan;
  final String? reserved;
  final String? paid;
  final String? available;
  final List<BudgetLine> items;

  factory BudgetSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return BudgetSnapshot(
      locked: json['locked'] as bool? ?? false,
      plan: _moneyField(json['plan']),
      reserved: _moneyField(json['reserved']),
      paid: _moneyField(json['paid']),
      available: _moneyField(json['available']),
      items: [
        for (final item in raw)
          BudgetLine.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

String? _moneyField(Object? value) {
  if (value == null || value is num) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return text;
}

class RequestFile {
  const RequestFile({
    required this.id,
    required this.contentType,
    required this.sizeBytes,
    required this.kind,
    this.purpose = 'material',
  });

  final String id;
  final String contentType;
  final int sizeBytes;
  final String kind;
  final String purpose;

  bool get isPhoto => kind == 'photo';
  bool get isPayment => purpose == 'payment';

  factory RequestFile.fromJson(Map<String, dynamic> json) {
    return RequestFile(
      id: json['id'] as String,
      contentType: json['contentType'] as String? ?? '',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'photo',
      purpose: json['purpose'] as String? ?? 'material',
    );
  }
}

class FundingRequest {
  const FundingRequest({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.budgetItemId,
    required this.lineTitle,
    required this.amount,
    required this.description,
    required this.status,
    required this.mine,
    required this.version,
    required this.files,
    this.events = const [],
    this.paidOn,
    this.paymentNumber,
    this.addresseeUserId,
    this.addresseeName,
    this.addresseeRole,
    this.forBank = false,
    this.bankSent = false,
    this.linePlan,
    this.lineReserved,
    this.linePaid,
    this.lineAvailable,
    this.planSet = true,
  });

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
  final List<RequestFile> files;
  final List<RequestEvent> events;
  final String? paidOn;
  final String? paymentNumber;
  final String? addresseeUserId;
  final String? addresseeName;
  final String? addresseeRole;
  final bool forBank;
  final bool bankSent;
  final String? linePlan;
  final String? lineReserved;
  final String? linePaid;
  final String? lineAvailable;
  final bool planSet;

  factory FundingRequest.fromJson(Map<String, dynamic> json) {
    final raw = json['files'] as List<dynamic>? ?? const [];
    final history = json['events'] as List<dynamic>? ?? const [];
    return FundingRequest(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String? ?? '',
      budgetItemId: json['budgetItemId'] as String,
      lineTitle: json['lineTitle'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      mine: json['mine'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
      paidOn: json['paidOn'] as String?,
      paymentNumber: json['paymentNumber'] as String?,
      addresseeUserId: json['addresseeUserId'] as String?,
      addresseeName: json['addresseeName'] as String?,
      addresseeRole: json['addresseeRole'] as String?,
      forBank: json['forBank'] as bool? ?? false,
      bankSent: json['bankSent'] as bool? ?? false,
      linePlan: json['linePlan'] as String?,
      lineReserved: json['lineReserved'] as String?,
      linePaid: json['linePaid'] as String?,
      lineAvailable: json['lineAvailable'] as String?,
      planSet: json['planSet'] as bool? ?? true,
      files: [
        for (final item in raw) RequestFile.fromJson(item as Map<String, dynamic>),
      ],
      events: [
        for (final item in history) RequestEvent.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

class RequestEvent {
  const RequestEvent({
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

  factory RequestEvent.fromJson(Map<String, dynamic> json) {
    return RequestEvent(
      action: json['action'] as String? ?? '',
      oldStatus: json['oldStatus'] as String?,
      newStatus: json['newStatus'] as String?,
      reason: json['reason'] as String? ?? '',
      amount: json['amount'] as String?,
      at: json['at'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
    );
  }
}

class LoanLine {
  const LoanLine({
    required this.id,
    required this.code,
    required this.title,
    required this.kind,
    required this.side,
    required this.amount,
    this.original = '',
    this.adjusted = '0.00',
    this.revised = '',
    this.funded = '0.00',
    this.remaining = '',
    this.retainagePercent = '0.00',
    this.retainageBalance = '0.00',
    this.percentComplete = '',
    this.risk = '',
  });

  final String id;
  final String code;
  final String title;
  final String kind;
  final String side;
  final String amount;
  final String original;
  final String adjusted;
  final String revised;
  final String funded;
  final String remaining;
  final String retainagePercent;
  final String retainageBalance;
  final String percentComplete;
  final String risk;

  String get shownOriginal => original.isEmpty ? amount : original;
  String get shownRevised => revised.isEmpty ? shownOriginal : revised;
  String get shownRemaining => remaining.isEmpty ? shownRevised : remaining;

  factory LoanLine.fromJson(Map<String, dynamic> json) {
    return LoanLine(
      id: json['id'] as String,
      code: json['cost_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      kind: json['cost_kind'] as String? ?? 'hard',
      side: json['budget_side'] as String? ?? 'use',
      amount: json['amount'] as String? ?? '0.00',
      original: json['original'] as String? ?? '',
      adjusted: json['adjusted'] as String? ?? '0.00',
      revised: json['revised'] as String? ?? '',
      funded: json['funded'] as String? ?? '0.00',
      remaining: json['remaining'] as String? ?? '',
      retainagePercent: json['retainage_percent'] as String? ?? '0.00',
      retainageBalance: json['retainage_balance'] as String? ?? '0.00',
      percentComplete: json['percent_complete'] as String? ?? '',
      risk: json['risk'] as String? ?? '',
    );
  }
}

class LoanSource {
  const LoanSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
  });

  final String id;
  final String name;
  final String kind;
  final String amount;

  factory LoanSource.fromJson(Map<String, dynamic> json) {
    return LoanSource(
      id: json['id'] as String? ?? json['source_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
    );
  }
}

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.code,
    required this.title,
    required this.required,
  });

  final String id;
  final String code;
  final String title;
  final bool required;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      required: json['required'] == true,
    );
  }
}

class LoanDraw {
  const LoanDraw({
    required this.id,
    required this.name,
    required this.status,
    required this.amount,
    required this.requested,
    required this.recommended,
    required this.confirmed,
  });

  final String id;
  final String name;
  final String status;
  final String amount;
  final String requested;
  final String recommended;
  final String confirmed;

  factory LoanDraw.fromJson(Map<String, dynamic> json) {
    return LoanDraw(
      id: json['id'] as String,
      name: json['draw_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      requested: json['requested'] as String? ?? '',
      recommended: json['recommended'] as String? ?? '',
      confirmed: json['confirmed'] as String? ?? '',
    );
  }
}

class NoticeItem {
  const NoticeItem({
    required this.id,
    required this.project,
    required this.line,
    required this.amount,
    required this.status,
  });

  final String id;
  final String project;
  final String line;
  final String amount;
  final String status;

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: json['id'] as String? ?? '',
      project: json['project'] as String? ?? '',
      line: json['line'] as String? ?? json['draw_name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class InspectionOrder {
  const InspectionOrder({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.status,
    required this.scheduledOn,
    required this.note,
    required this.gateCode,
    this.requestId = '',
    this.requestLine = '',
  });

  final String id;
  final String projectId;
  final String projectName;
  final String status;
  final String scheduledOn;
  final String note;
  final String gateCode;
  final String requestId;
  final String requestLine;

  factory InspectionOrder.fromJson(Map<String, dynamic> json) {
    return InspectionOrder(
      id: json['id'] as String,
      projectId: json['project_id'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      scheduledOn: json['scheduled_on'] as String? ?? '',
      note: json['note'] as String? ?? '',
      gateCode: json['gate_code'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      requestLine: json['request_line'] as String? ?? '',
    );
  }
}

class InspectionCard {
  const InspectionCard({
    required this.id,
    required this.status,
    required this.scheduledOn,
    required this.gateCode,
    required this.note,
    required this.requestId,
  });

  final String id;
  final String status;
  final String scheduledOn;
  final String gateCode;
  final String note;
  final String requestId;

  factory InspectionCard.fromJson(Map<String, dynamic> json) {
    return InspectionCard(
      id: json['id'] as String,
      status: json['status'] as String? ?? '',
      scheduledOn: json['scheduled_on'] as String? ?? '',
      gateCode: json['gate_code'] as String? ?? '',
      note: json['note'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
    );
  }
}

class FirmCompliance {
  const FirmCompliance({
    required this.id,
    required this.name,
    required this.insuranceUntil,
    required this.licenseUntil,
  });

  final String id;
  final String name;
  final String insuranceUntil;
  final String licenseUntil;

  factory FirmCompliance.fromJson(Map<String, dynamic> json) {
    return FirmCompliance(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      insuranceUntil: json['insurance_until'] as String? ?? '',
      licenseUntil: json['license_until'] as String? ?? '',
    );
  }
}

class LoanDesk {
  const LoanDesk({
    required this.lines,
    required this.sources,
    required this.checklist,
    required this.draws,
    required this.inspections,
    required this.firms,
  });

  final List<LoanLine> lines;
  final List<LoanSource> sources;
  final List<ChecklistItem> checklist;
  final List<LoanDraw> draws;
  final List<InspectionCard> inspections;
  final List<FirmCompliance> firms;

  static const empty = LoanDesk(
    lines: [],
    sources: [],
    checklist: [],
    draws: [],
    inspections: [],
    firms: [],
  );

  factory LoanDesk.fromJson(Map<String, dynamic> json) {
    List<T> read<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key] as List? ?? const [];
      return [
        for (final item in raw)
          if (item is Map) parse(item.map((key, value) => MapEntry(key.toString(), value))),
      ];
    }

    return LoanDesk(
      lines: read('lines', LoanLine.fromJson),
      sources: read('sources', LoanSource.fromJson),
      checklist: read('checklist', ChecklistItem.fromJson),
      draws: read('draws', LoanDraw.fromJson),
      inspections: read('inspections', InspectionCard.fromJson),
      firms: read('firms', FirmCompliance.fromJson),
    );
  }
}

class DrawLineInput {
  const DrawLineInput({
    required this.budgetItemId,
    required this.requested,
    required this.adjustment,
    required this.retainageWithheld,
    required this.retainageReleased,
    required this.storedMaterials,
    this.inspectorPercent = '',
    this.inspectorRecommend = '',
    this.approved = '',
    this.comment = '',
  });

  final String budgetItemId;
  final String requested;
  final String adjustment;
  final String retainageWithheld;
  final String retainageReleased;
  final String storedMaterials;
  final String inspectorPercent;
  final String inspectorRecommend;
  final String approved;
  final String comment;

  factory DrawLineInput.fromJson(Map<String, dynamic> json) {
    return DrawLineInput(
      budgetItemId: json['budget_item_id'] as String? ?? '',
      requested: json['requested'] as String? ?? '0.00',
      adjustment: json['adjustment'] as String? ?? '0.00',
      retainageWithheld: json['retainage_withheld'] as String? ?? '0.00',
      retainageReleased: json['retainage_released'] as String? ?? '0.00',
      storedMaterials: json['stored_materials'] as String? ?? '0.00',
      inspectorPercent: json['inspector_percent'] as String? ?? '',
      inspectorRecommend: json['inspector_recommend'] as String? ?? '',
      approved: json['approved_amount'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
    );
  }

  Map<String, String> toJson() => {
    'budgetItemId': budgetItemId,
    'requested': requested,
    'adjustment': adjustment,
    'retainageWithheld': retainageWithheld,
    'retainageReleased': retainageReleased,
    'storedMaterials': storedMaterials,
    'comment': comment,
  };
}

class DrawRequirementView {
  const DrawRequirementView({
    required this.itemId,
    required this.code,
    required this.title,
    required this.required,
    required this.status,
    required this.note,
  });

  final String itemId;
  final String code;
  final String title;
  final bool required;
  final String status;
  final String note;

  factory DrawRequirementView.fromJson(Map<String, dynamic> json) {
    return DrawRequirementView(
      itemId: json['item_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      required: json['required'] == true,
      status: json['status'] as String? ?? 'missing',
      note: json['note'] as String? ?? '',
    );
  }
}

class DrawDetail {
  const DrawDetail({
    required this.id,
    required this.projectId,
    required this.name,
    required this.status,
    required this.finalDraw,
    required this.version,
    required this.amount,
    required this.requested,
    required this.confirmed,
    required this.signedName,
    required this.lines,
    required this.sources,
    required this.requirements,
    required this.comments,
  });

  final String id;
  final String projectId;
  final String name;
  final String status;
  final bool finalDraw;
  final int version;
  final String amount;
  final String requested;
  final String confirmed;
  final String signedName;
  final List<DrawLineInput> lines;
  final List<LoanSource> sources;
  final List<DrawRequirementView> requirements;
  final List<String> comments;

  factory DrawDetail.fromJson(Map<String, dynamic> json) {
    List<T> read<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key] as List? ?? const [];
      return [
        for (final item in raw)
          if (item is Map) parse(item.map((key, value) => MapEntry(key.toString(), value))),
      ];
    }

    return DrawDetail(
      id: json['id'] as String,
      projectId: json['project_id'] as String? ?? '',
      name: json['draw_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      finalDraw: json['final_draw'] == true,
      version: json['version'] is int ? json['version'] as int : int.parse('${json['version']}'),
      amount: json['amount'] as String? ?? '',
      requested: json['requested'] as String? ?? '',
      confirmed: json['confirmed'] as String? ?? '',
      signedName: json['signed_name'] as String? ?? '',
      lines: read('lines', DrawLineInput.fromJson),
      sources: read('sources', LoanSource.fromJson),
      requirements: read('requirements', DrawRequirementView.fromJson),
      comments: [
        for (final item in json['comments'] as List? ?? const [])
          if (item is Map) item['body'] as String? ?? '',
      ],
    );
  }
}
