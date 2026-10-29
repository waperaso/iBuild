/// What the bank queue and the tranche card receive from the server.
/// Amounts stay decimal strings, for example "2260000000.00".
library;

const bankQueueTabs = ['mine', 'all', 'developer', 'overdue'];

Map<String, dynamic> _map(Object? value) {
  return value is Map
      ? value.map((key, item) => MapEntry(key.toString(), item))
      : const <String, dynamic>{};
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) read) {
  return [
    for (final item in value as List<dynamic>? ?? const [])
      if (item is Map) read(_map(item)),
  ];
}


class BankQueueCounts {
  const BankQueueCounts({
    required this.mine,
    required this.all,
    required this.developer,
    required this.overdue,
  });

  final int mine;
  final int all;
  final int developer;
  final int overdue;

  int forTab(String tab) {
    return switch (tab) {
      'all' => all,
      'developer' => developer,
      'overdue' => overdue,
      _ => mine,
    };
  }

  factory BankQueueCounts.fromJson(Map<String, dynamic> json) {
    return BankQueueCounts(
      mine: json['mine'] as int? ?? 0,
      all: json['all'] as int? ?? 0,
      developer: json['developer'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
    );
  }
}

class BankQueueItem {
  const BankQueueItem({
    required this.id,
    required this.projectName,
    required this.developerName,
    required this.trancheNo,
    required this.requestedAmount,
    required this.stage,
    required this.stageLabel,
    required this.elapsedDays,
    required this.elapsedHours,
    required this.slaDays,
    required this.problemsLabel,
    required this.holderLabel,
    required this.signal,
    required this.waitingDeveloper,
    required this.overdue,
    required this.mine,
  });

  final String id;
  final String projectName;
  final String developerName;
  final int trancheNo;
  final String requestedAmount;
  final String stage;
  final String stageLabel;
  final int elapsedDays;
  final int elapsedHours;
  final int slaDays;
  final String problemsLabel;
  final String holderLabel;
  final String signal;
  final bool waitingDeveloper;
  final bool overdue;
  final bool mine;

  factory BankQueueItem.fromJson(Map<String, dynamic> json) {
    return BankQueueItem(
      id: json['id'] as String,
      projectName: json['projectName'] as String? ?? '',
      developerName: json['developerName'] as String? ?? '',
      trancheNo: json['trancheNo'] as int? ?? 0,
      requestedAmount: json['requestedAmount'] as String? ?? '0.00',
      stage: json['stage'] as String? ?? '',
      stageLabel: json['stageLabel'] as String? ?? '',
      elapsedDays: json['elapsedDays'] as int? ?? 0,
      elapsedHours: json['elapsedHours'] as int? ?? 0,
      slaDays: json['slaDays'] as int? ?? 0,
      problemsLabel: json['problemsLabel'] as String? ?? '',
      holderLabel: json['holderLabel'] as String? ?? '',
      signal: json['signal'] as String? ?? 'none',
      waitingDeveloper: json['waitingDeveloper'] as bool? ?? false,
      overdue: json['overdue'] as bool? ?? false,
      mine: json['mine'] as bool? ?? false,
    );
  }
}

class BankQueue {
  const BankQueue({
    required this.bankName,
    required this.department,
    required this.tab,
    required this.counts,
    required this.waitingAmount,
    required this.items,
  });

  final String bankName;
  final String department;
  final String tab;
  final BankQueueCounts counts;
  final String waitingAmount;
  final List<BankQueueItem> items;

  factory BankQueue.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return BankQueue(
      bankName: json['bankName'] as String? ?? '',
      department: json['department'] as String? ?? '',
      tab: json['tab'] as String? ?? 'mine',
      counts: BankQueueCounts.fromJson(
        (json['counts'] as Map?)?.map((key, value) => MapEntry(key.toString(), value)) ??
            const <String, dynamic>{},
      ),
      waitingAmount: json['waitingAmount'] as String? ?? '0.00',
      items: [
        for (final item in raw)
          if (item is Map)
            BankQueueItem.fromJson(item.map((key, value) => MapEntry(key.toString(), value))),
      ],
    );
  }
}

class BankStage {
  const BankStage({required this.code, required this.state});

  final String code;

  /// done, current or pending.
  final String state;

  factory BankStage.fromJson(Map<String, dynamic> json) {
    return BankStage(
      code: json['code'] as String? ?? '',
      state: json['state'] as String? ?? 'pending',
    );
  }
}

class BankTotals {
  const BankTotals({
    required this.requested,
    required this.confirmed,
    required this.blocked,
    required this.issue,
    required this.returned,
    required this.remaining,
  });

  final String requested;
  final String confirmed;
  final String blocked;
  final String issue;
  final String returned;
  final String remaining;

  factory BankTotals.fromJson(Map<String, dynamic> json) {
    String read(String key) => json[key] as String? ?? '0.00';
    return BankTotals(
      requested: read('requested'),
      confirmed: read('confirmed'),
      blocked: read('blocked'),
      issue: read('issue'),
      returned: read('returned'),
      remaining: read('remaining'),
    );
  }
}

class BankCheck {
  const BankCheck({
    required this.id,
    required this.code,
    required this.level,
    required this.basis,
    required this.title,
    required this.detail,
    required this.passed,
    required this.actions,
    this.requested,
    this.waiver,
  });

  final String id;
  final String code;

  /// block, warning, signal or reminder.
  final String level;
  final String basis;
  final String title;
  final String detail;
  final bool passed;

  /// request_document, request_schedule or waive.
  final List<String> actions;

  /// A document or a schedule was already requested from the developer.
  final BankRequested? requested;

  /// The check was accepted with a reason. The original mark stays in the card.
  final BankWaiver? waiver;

  factory BankCheck.fromJson(Map<String, dynamic> json) {
    return BankCheck(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      level: json['level'] as String? ?? 'warning',
      basis: json['basis'] as String? ?? '',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      passed: json['passed'] as bool? ?? false,
      actions: [
        for (final action in json['actions'] as List<dynamic>? ?? const [])
          action.toString(),
      ],
      requested: json['requested'] is Map ? BankRequested.fromJson(_map(json['requested'])) : null,
      waiver: json['waiver'] is Map ? BankWaiver.fromJson(_map(json['waiver'])) : null,
    );
  }
}

class BankRequested {
  const BankRequested({required this.kind, required this.at});

  /// document or schedule.
  final String kind;
  final String at;

  factory BankRequested.fromJson(Map<String, dynamic> json) {
    return BankRequested(
      kind: json['kind'] as String? ?? 'document',
      at: json['at'] as String? ?? '',
    );
  }
}

class BankWaiver {
  const BankWaiver({
    required this.reason,
    required this.comment,
    required this.by,
    required this.at,
  });

  /// outside_system, fixed_elsewhere, approved_exception or other.
  final String reason;
  final String comment;
  final String by;
  final String at;

  factory BankWaiver.fromJson(Map<String, dynamic> json) {
    return BankWaiver(
      reason: json['reason'] as String? ?? 'other',
      comment: json['comment'] as String? ?? '',
      by: json['by'] as String? ?? '',
      at: json['at'] as String? ?? '',
    );
  }
}

class BankExpert {
  const BankExpert({
    required this.name,
    required this.signedOn,
    required this.note,
    required this.readinessPercent,
    required this.previousPercent,
    required this.remaining,
    required this.recommended,
    required this.riskFlag,
  });

  final String name;
  final String signedOn;
  final String note;
  final String? readinessPercent;
  final String? previousPercent;
  final String? remaining;
  final String? recommended;
  final bool riskFlag;

  factory BankExpert.fromJson(Map<String, dynamic> json) {
    return BankExpert(
      name: json['name'] as String? ?? '',
      signedOn: json['signedOn'] as String? ?? '',
      note: json['note'] as String? ?? '',
      readinessPercent: json['readinessPercent'] as String?,
      previousPercent: json['previousPercent'] as String?,
      remaining: json['remaining'] as String?,
      recommended: json['recommended'] as String?,
      riskFlag: json['riskFlag'] as bool? ?? false,
    );
  }
}

/// How the confirmed amount was counted: percent of the plan, minus what was paid before.
class BankFormula {
  const BankFormula({
    required this.percent,
    required this.plan,
    required this.gross,
    required this.issuedBefore,
    required this.result,
  });

  final String percent;
  final String plan;
  final String gross;
  final String issuedBefore;
  final String result;

  factory BankFormula.fromJson(Map<String, dynamic> json) {
    return BankFormula(
      percent: json['percent'] as String? ?? '0',
      plan: json['plan'] as String? ?? '0.00',
      gross: json['gross'] as String? ?? '0.00',
      issuedBefore: json['issuedBefore'] as String? ?? '0.00',
      result: json['result'] as String? ?? '0.00',
    );
  }
}

class BankPhoto {
  const BankPhoto({required this.caption, required this.meta});

  final String caption;
  final String meta;

  factory BankPhoto.fromJson(Map<String, dynamic> json) {
    return BankPhoto(
      caption: json['caption'] as String? ?? '',
      meta: json['meta'] as String? ?? '',
    );
  }
}

class BankDocument {
  const BankDocument({required this.title, required this.ok});

  final String title;
  final bool ok;

  factory BankDocument.fromJson(Map<String, dynamic> json) {
    return BankDocument(
      title: json['title'] as String? ?? '',
      ok: json['state'] == 'ok',
    );
  }
}

class BankPayment {
  const BankPayment({required this.label, required this.paidOn, required this.amount});

  final String label;
  final String paidOn;
  final String amount;

  factory BankPayment.fromJson(Map<String, dynamic> json) {
    return BankPayment(
      label: json['label'] as String? ?? '',
      paidOn: json['paidOn'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
    );
  }
}

class BankLine {
  const BankLine({
    required this.id,
    required this.title,
    required this.issuedBefore,
    required this.requested,
    required this.readinessPercent,
    required this.readinessNote,
    required this.confirmed,
    required this.toIssue,
    required this.choice,
    required this.level,
    this.canChooseRequested = true,
    this.blocked = false,
    this.expert,
    this.formula,
    this.photos = const [],
    this.documents = const [],
    this.payments = const [],
  });

  final String id;
  final String title;
  final String issuedBefore;
  final String requested;
  final String? readinessPercent;
  final String readinessNote;
  final String confirmed;
  final String toIssue;
  final String choice;

  /// ok, warning or block.
  final String level;

  /// False when more was requested than the expert confirmed.
  final bool canChooseRequested;
  final bool blocked;
  final BankExpert? expert;
  final BankFormula? formula;
  final List<BankPhoto> photos;
  final List<BankDocument> documents;
  final List<BankPayment> payments;

  factory BankLine.fromJson(Map<String, dynamic> json) {
    return BankLine(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      issuedBefore: json['issuedBefore'] as String? ?? '0.00',
      requested: json['requested'] as String? ?? '0.00',
      readinessPercent: json['readinessPercent'] as String?,
      readinessNote: json['readinessNote'] as String? ?? '',
      confirmed: json['confirmed'] as String? ?? '0.00',
      toIssue: json['toIssue'] as String? ?? '0.00',
      choice: json['choice'] as String? ?? 'confirmed',
      level: json['level'] as String? ?? 'ok',
      canChooseRequested: json['canChooseRequested'] as bool? ?? true,
      blocked: json['blocked'] as bool? ?? false,
      expert: json['expert'] is Map ? BankExpert.fromJson(_map(json['expert'])) : null,
      formula: json['formula'] is Map ? BankFormula.fromJson(_map(json['formula'])) : null,
      photos: _list(json['photos'], BankPhoto.fromJson),
      documents: _list(json['documents'], BankDocument.fromJson),
      payments: _list(json['payments'], BankPayment.fromJson),
    );
  }
}

class BankPermissions {
  const BankPermissions({
    this.canDecide = false,
    this.canRequest = false,
    this.canResume = false,
    this.canSuspend = false,
  });

  final bool canDecide;
  final bool canRequest;
  final bool canResume;
  final bool canSuspend;

  factory BankPermissions.fromJson(Map<String, dynamic> json) {
    return BankPermissions(
      canDecide: json['canDecide'] as bool? ?? false,
      canRequest: json['canRequest'] as bool? ?? false,
      canResume: json['canResume'] as bool? ?? false,
      canSuspend: json['canSuspend'] as bool? ?? false,
    );
  }
}

class BankReturnLine {
  const BankReturnLine({
    required this.title,
    required this.amount,
    required this.reason,
  });

  final String title;
  final String amount;
  final String reason;

  factory BankReturnLine.fromJson(Map<String, dynamic> json) {
    return BankReturnLine(
      title: json['title'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
      reason: json['reason'] as String? ?? '',
    );
  }
}

class BankDecision {
  const BankDecision({
    required this.kind,
    required this.issueAmount,
    required this.returnedAmount,
    required this.waivedCount,
    required this.returnLines,
    required this.note,
    required this.by,
    required this.at,
  });

  /// partial, return_all, control_measure, suspend or resume.
  final String kind;
  final String issueAmount;
  final String returnedAmount;
  final int waivedCount;
  final List<BankReturnLine> returnLines;
  final String note;
  final String by;
  final String at;

  factory BankDecision.fromJson(Map<String, dynamic> json) {
    return BankDecision(
      kind: json['kind'] as String? ?? 'partial',
      issueAmount: json['issueAmount'] as String? ?? '0.00',
      returnedAmount: json['returnedAmount'] as String? ?? '0.00',
      waivedCount: json['waivedCount'] as int? ?? 0,
      returnLines: _list(json['returnLines'], BankReturnLine.fromJson),
      note: json['note'] as String? ?? '',
      by: json['by'] as String? ?? '',
      at: json['at'] as String? ?? '',
    );
  }
}

class BankTranche {
  const BankTranche({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.projectAddress,
    required this.developerName,
    required this.trancheNo,
    required this.stage,
    required this.stageLabel,
    required this.stages,
    required this.waitingDeveloper,
    required this.submittedDate,
    required this.submittedTime,
    required this.techConfirmed,
    required this.elapsedDays,
    required this.elapsedHours,
    required this.slaDays,
    required this.overdue,
    required this.rulesVersion,
    required this.creditLimit,
    required this.issuedTotal,
    required this.totals,
    required this.openChecks,
    required this.passedChecks,
    required this.lines,
    this.outcome,
    this.fundingPaused = false,
    this.waivedCount = 0,
    this.permissions = const BankPermissions(),
    this.decision,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String projectAddress;
  final String developerName;
  final int trancheNo;
  final String stage;
  final String stageLabel;
  final List<BankStage> stages;
  final bool waitingDeveloper;
  final String submittedDate;
  final String submittedTime;
  final String? techConfirmed;
  final int elapsedDays;
  final int elapsedHours;
  final int slaDays;
  final bool overdue;
  final int rulesVersion;
  final String creditLimit;
  final String issuedTotal;
  final BankTotals totals;
  final List<BankCheck> openChecks;
  final List<BankCheck> passedChecks;
  final List<BankLine> lines;

  /// rejected once the bank closed the tranche, otherwise null.
  final String? outcome;
  final bool fundingPaused;
  final int waivedCount;
  final BankPermissions permissions;
  final BankDecision? decision;

  factory BankTranche.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? value) {
      return value is Map
          ? value.map((key, item) => MapEntry(key.toString(), item))
          : const <String, dynamic>{};
    }

    List<T> list<T>(Object? value, T Function(Map<String, dynamic>) read) {
      return [
        for (final item in value as List<dynamic>? ?? const [])
          if (item is Map) read(map(item)),
      ];
    }

    final checks = map(json['checks']);
    return BankTranche(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      projectAddress: json['projectAddress'] as String? ?? '',
      developerName: json['developerName'] as String? ?? '',
      trancheNo: json['trancheNo'] as int? ?? 0,
      stage: json['stage'] as String? ?? '',
      stageLabel: json['stageLabel'] as String? ?? '',
      stages: list(json['stages'], BankStage.fromJson),
      waitingDeveloper: json['waitingDeveloper'] as bool? ?? false,
      submittedDate: json['submittedDate'] as String? ?? '',
      submittedTime: json['submittedTime'] as String? ?? '',
      techConfirmed: json['techConfirmed'] as String?,
      elapsedDays: json['elapsedDays'] as int? ?? 0,
      elapsedHours: json['elapsedHours'] as int? ?? 0,
      slaDays: json['slaDays'] as int? ?? 0,
      overdue: json['overdue'] as bool? ?? false,
      rulesVersion: json['rulesVersion'] as int? ?? 0,
      creditLimit: json['creditLimit'] as String? ?? '0.00',
      issuedTotal: json['issuedTotal'] as String? ?? '0.00',
      totals: BankTotals.fromJson(map(json['totals'])),
      openChecks: list(checks['open'], BankCheck.fromJson),
      passedChecks: list(checks['passed'], BankCheck.fromJson),
      lines: list(json['lines'], BankLine.fromJson),
      outcome: json['outcome'] as String?,
      fundingPaused: json['fundingPaused'] as bool? ?? false,
      waivedCount: json['waivedCount'] as int? ?? 0,
      permissions: BankPermissions.fromJson(map(json['permissions'])),
      decision: json['decision'] is Map ? BankDecision.fromJson(map(json['decision'])) : null,
    );
  }
}

class BankVote {
  const BankVote({required this.by, required this.vote, required this.comment, required this.at});

  final String by;

  /// approve, return or reject.
  final String vote;
  final String comment;
  final String at;

  factory BankVote.fromJson(Map<String, dynamic> json) {
    return BankVote(
      by: json['by'] as String? ?? '',
      vote: json['vote'] as String? ?? 'approve',
      comment: json['comment'] as String? ?? '',
      at: json['at'] as String? ?? '',
    );
  }
}

class BankGroupInfo {
  const BankGroupInfo({required this.size, required this.available, required this.onLeave});

  final int size;
  final int available;
  final List<String> onLeave;

  factory BankGroupInfo.fromJson(Map<String, dynamic> json) {
    return BankGroupInfo(
      size: json['size'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      onLeave: [
        for (final item in json['onLeave'] as List<dynamic>? ?? const [])
          if (item is Map) (item['name'] ?? '').toString(),
      ],
    );
  }
}

class BankApprovalStep {
  const BankApprovalStep({
    required this.code,
    required this.kind,
    required this.status,
    required this.required,
    required this.approved,
    required this.reason,
    required this.by,
    required this.decidedAt,
    required this.group,
    required this.votes,
  });

  /// expert, specialist, head, committee, sign or payment.
  final String code;

  /// person, group or external.
  final String kind;

  /// done, current, pending, skipped or waiting.
  final String status;
  final int required;
  final int approved;

  /// For the committee: below_threshold, amount_over or waived_block.
  final String reason;
  final String by;
  final String decidedAt;
  final BankGroupInfo? group;
  final List<BankVote> votes;

  factory BankApprovalStep.fromJson(Map<String, dynamic> json) {
    return BankApprovalStep(
      code: json['code'] as String? ?? '',
      kind: json['kind'] as String? ?? 'person',
      status: json['status'] as String? ?? 'pending',
      required: json['required'] as int? ?? 1,
      approved: json['approved'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      by: json['by'] as String? ?? '',
      decidedAt: json['decidedAt'] as String? ?? '',
      group: json['group'] is Map ? BankGroupInfo.fromJson(_map(json['group'])) : null,
      votes: _list(json['votes'], BankVote.fromJson),
    );
  }
}

class BankApproval {
  const BankApproval({
    required this.id,
    required this.projectName,
    required this.trancheNo,
    required this.stage,
    required this.stageLabel,
    required this.stages,
    required this.round,
    required this.outcome,
    required this.expertSignedOn,
    required this.threshold,
    required this.issue,
    required this.returned,
    required this.waivedCount,
    required this.returnDays,
    required this.returnLines,
    required this.steps,
    required this.canAct,
    required this.blocker,
  });

  final String id;
  final String projectName;
  final int trancheNo;
  final String stage;
  final String stageLabel;
  final List<BankStage> stages;
  final int round;
  final String? outcome;
  final String? expertSignedOn;
  final String threshold;
  final String issue;
  final String returned;
  final int waivedCount;
  final int returnDays;
  final List<BankReturnLine> returnLines;
  final List<BankApprovalStep> steps;
  final bool canAct;

  /// Why the person cannot vote: not_member, on_leave, preparer, voted, external, not_now or closed.
  final String? blocker;

  BankApprovalStep? step(String code) {
    for (final step in steps) {
      if (step.code == code) return step;
    }
    return null;
  }

  factory BankApproval.fromJson(Map<String, dynamic> json) {
    final totals = _map(json['totals']);
    final permissions = _map(json['permissions']);
    return BankApproval(
      id: json['id'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      trancheNo: json['trancheNo'] as int? ?? 0,
      stage: json['stage'] as String? ?? '',
      stageLabel: json['stageLabel'] as String? ?? '',
      stages: _list(json['stages'], BankStage.fromJson),
      round: json['round'] as int? ?? 1,
      outcome: json['outcome'] as String?,
      expertSignedOn: json['expertSignedOn'] as String?,
      threshold: json['threshold'] as String? ?? '0.00',
      issue: totals['issue'] as String? ?? '0.00',
      returned: totals['returned'] as String? ?? '0.00',
      waivedCount: json['waivedCount'] as int? ?? 0,
      returnDays: json['returnDays'] as int? ?? 5,
      returnLines: _list(json['returnLines'], BankReturnLine.fromJson),
      steps: _list(json['steps'], BankApprovalStep.fromJson),
      canAct: permissions['canAct'] as bool? ?? false,
      blocker: permissions['blocker'] as String?,
    );
  }
}

/// One line of the journal: who did what and when, as the server wrote it.
class BankJournalEntry {
  const BankJournalEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.at,
    required this.detail,
  });

  factory BankJournalEntry.fromJson(Map<String, dynamic> json) {
    return BankJournalEntry(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      actor: json['actor'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      detail: _map(json['detail']),
    );
  }

  final String id;
  final String action;
  final String actor;
  final DateTime at;
  final Map<String, dynamic> detail;
}
