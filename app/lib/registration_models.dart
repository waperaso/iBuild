class ApplicationReceipt {
  const ApplicationReceipt({required this.id, required this.code, required this.token});

  final String id;
  final String code;
  final String token;

  factory ApplicationReceipt.fromJson(Map<String, dynamic> json) => ApplicationReceipt(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    token: json['token'] as String? ?? '',
  );
}

class ApplicationFile {
  const ApplicationFile({required this.id, required this.type, required this.name});

  final String id;
  final String type;
  final String name;

  factory ApplicationFile.fromJson(Map<String, dynamic> json) => ApplicationFile(
    id: json['id'] as String? ?? '',
    type: json['type'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );
}

/// What the applicant sees on the status page.
class ApplicationStatusView {
  const ApplicationStatusView({
    required this.id,
    required this.code,
    required this.kind,
    required this.status,
    required this.orgName,
    required this.requestNote,
    required this.decisionNote,
    required this.documents,
    required this.missing,
    required this.canUpload,
  });

  final String id;
  final String code;
  final String kind;
  final String status;
  final String orgName;
  final String requestNote;
  final String decisionNote;
  final List<ApplicationFile> documents;
  final List<String> missing;
  final bool canUpload;

  factory ApplicationStatusView.fromJson(Map<String, dynamic> json) => ApplicationStatusView(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    kind: json['kind'] as String? ?? 'developer',
    status: json['status'] as String? ?? 'new',
    orgName: json['orgName'] as String? ?? '',
    requestNote: json['requestNote'] as String? ?? '',
    decisionNote: json['decisionNote'] as String? ?? '',
    documents: [
      for (final item in json['documents'] as List<dynamic>? ?? const [])
        ApplicationFile.fromJson(item as Map<String, dynamic>),
    ],
    missing: [for (final item in json['missing'] as List<dynamic>? ?? const []) item as String],
    canUpload: json['canUpload'] as bool? ?? false,
  );
}

class ApplicationItem {
  const ApplicationItem({
    required this.id,
    required this.code,
    required this.kind,
    required this.status,
    required this.orgName,
    required this.inn,
    required this.contactName,
    required this.phone,
    required this.createdAt,
    required this.nextCallOn,
    required this.documents,
    required this.missingDocs,
  });

  final String id;
  final String code;
  final String kind;
  final String status;
  final String orgName;
  final String inn;
  final String contactName;
  final String phone;
  final DateTime createdAt;
  final String? nextCallOn;
  final int documents;
  final int missingDocs;

  bool get isOpen => !const ['approved', 'rejected'].contains(status);

  factory ApplicationItem.fromJson(Map<String, dynamic> json) => ApplicationItem(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    kind: json['kind'] as String? ?? 'developer',
    status: json['status'] as String? ?? 'new',
    orgName: json['orgName'] as String? ?? '',
    inn: json['inn'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    nextCallOn: json['nextCallOn'] as String?,
    documents: (json['documents'] as num?)?.toInt() ?? 0,
    missingDocs: (json['missingDocs'] as num?)?.toInt() ?? 0,
  );
}

class ApplicationBoard {
  const ApplicationBoard({required this.counts, required this.items});

  final Map<String, int> counts;
  final List<ApplicationItem> items;

  factory ApplicationBoard.fromJson(Map<String, dynamic> json) => ApplicationBoard(
    counts: {
      for (final entry in (json['counts'] as Map<String, dynamic>? ?? const {}).entries)
        entry.key: (entry.value as num).toInt(),
    },
    items: [
      for (final item in json['items'] as List<dynamic>? ?? const [])
        ApplicationItem.fromJson(item as Map<String, dynamic>),
    ],
  );
}

class ApplicationEvent {
  const ApplicationEvent({
    required this.kind,
    required this.outcome,
    required this.body,
    required this.createdAt,
    required this.author,
  });

  final String kind;
  final String outcome;
  final String body;
  final DateTime createdAt;
  final String author;

  factory ApplicationEvent.fromJson(Map<String, dynamic> json) => ApplicationEvent(
    kind: json['kind'] as String? ?? '',
    outcome: json['outcome'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    author: json['author'] as String? ?? '',
  );
}

class ApplicationDetail {
  const ApplicationDetail({
    required this.id,
    required this.code,
    required this.kind,
    required this.status,
    required this.orgName,
    required this.inn,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.data,
    required this.checks,
    required this.checkKeys,
    required this.requestNote,
    required this.decisionNote,
    required this.nextCallOn,
    required this.createdAt,
    required this.consentAt,
    required this.consentVersion,
    required this.documents,
    required this.requiredTypes,
    required this.missing,
    required this.events,
  });

  final String id;
  final String code;
  final String kind;
  final String status;
  final String orgName;
  final String inn;
  final String contactName;
  final String phone;
  final String email;
  final Map<String, dynamic> data;
  final Map<String, bool> checks;
  final List<String> checkKeys;
  final String requestNote;
  final String decisionNote;
  final String? nextCallOn;
  final DateTime createdAt;
  final DateTime? consentAt;
  final String consentVersion;
  final List<ApplicationFile> documents;
  final List<String> requiredTypes;
  final List<String> missing;
  final List<ApplicationEvent> events;

  bool get isOpen => !const ['approved', 'rejected'].contains(status);
  bool get allChecked => checkKeys.every((key) => checks[key] == true);

  factory ApplicationDetail.fromJson(Map<String, dynamic> json) => ApplicationDetail(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    kind: json['kind'] as String? ?? 'developer',
    status: json['status'] as String? ?? 'new',
    orgName: json['orgName'] as String? ?? '',
    inn: json['inn'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    data: (json['data'] as Map<String, dynamic>?) ?? const {},
    checks: {
      for (final entry in (json['checks'] as Map<String, dynamic>? ?? const {}).entries)
        entry.key: entry.value == true,
    },
    checkKeys: [for (final item in json['checkKeys'] as List<dynamic>? ?? const []) item as String],
    requestNote: json['requestNote'] as String? ?? '',
    decisionNote: json['decisionNote'] as String? ?? '',
    nextCallOn: json['nextCallOn'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    consentAt: DateTime.tryParse(json['consentAt'] as String? ?? ''),
    consentVersion: json['consentVersion'] as String? ?? '',
    documents: [
      for (final item in json['documents'] as List<dynamic>? ?? const [])
        ApplicationFile.fromJson(item as Map<String, dynamic>),
    ],
    requiredTypes: [
      for (final item in json['docRules'] as List<dynamic>? ?? const [])
        if ((item as Map<String, dynamic>)['required'] == true) item['type'] as String,
    ],
    missing: [for (final item in json['missing'] as List<dynamic>? ?? const []) item as String],
    events: [
      for (final item in json['events'] as List<dynamic>? ?? const [])
        ApplicationEvent.fromJson(item as Map<String, dynamic>),
    ],
  );
}

class ApprovedAccount {
  const ApprovedAccount({
    required this.login,
    required this.password,
    required this.company,
    required this.project,
  });

  final String login;
  final String password;
  final String company;
  final String project;
}

class ApprovalResult {
  const ApprovalResult({required this.application, this.account});

  final ApplicationDetail application;
  final ApprovedAccount? account;

  factory ApprovalResult.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>?;
    return ApprovalResult(
      application: ApplicationDetail.fromJson(json['application'] as Map<String, dynamic>),
      account: account == null
          ? null
          : ApprovedAccount(
              login: account['login'] as String? ?? '',
              password: account['password'] as String? ?? '',
              company: account['company'] as String? ?? '',
              project: account['project'] as String? ?? '',
            ),
    );
  }
}
