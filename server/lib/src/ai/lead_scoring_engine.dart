/// Deterministic CRM lead scoring — plan Part 3. No LLM: pure computation
/// over `store.leads`, feeding `GET /v1/ai/crm/leads` and
/// `POST /v1/ai/crm/query`. Reason codes and the `metrics` shape match the
/// doc comments above those routes in `ai_routes.dart` exactly.
library;

import '../env_loader.dart';
import '../store.dart';

/// hot >= 70, warm >= 40, else cold.
const _kHotThreshold = 70;
const _kWarmThreshold = 40;

/// How long a `new` lead may sit untouched before it is an SLA breach.
const _kSlaMinutes = 120;

/// Funnel order used for `metrics.conversion` (mirrors `kAllowedLeadStatuses`
/// in `app.dart`, minus the terminal `lost`).
const _kFunnelOrder = [
  'new',
  'contacted',
  'scheduled',
  'visited',
  'qualified',
  'won',
];

/// Multilingual urgency/finance keywords (ru/uz/en), each mapped to the
/// reason code it contributes.
const Map<String, List<String>> _keywordReasons = {
  'mortgageInterest': ['ипотек', 'kredit', 'mortgage', 'ипотечн'],
  'cashBuyer': ['наличными', 'naqd', 'cash', 'нал '],
  'urgentKeyword': ['срочно', 'shoshilinch', 'urgent', 'asap', 'тезда'],
};

class LeadBand {
  static const hot = 'hot';
  static const warm = 'warm';
  static const cold = 'cold';
}

/// One scored lead's computed fields, kept separate from the mutated map so
/// callers decide when/whether to write it back.
class LeadScore {
  const LeadScore({
    required this.score,
    required this.band,
    required this.reasons,
  });
  final int score;
  final String band;
  final List<String> reasons;
}

class LeadScoringEngine {
  /// Scores [lead] against the rest of [store.leads] (for repeat-contact and
  /// project-heat signals) and, unless [persist] is false, writes
  /// `aiScore`/`aiBand`/`aiReasons`/`aiScoredAt` onto the lead map in place —
  /// the manual `score` field is never touched, so it keeps winning in the UI.
  LeadScore score(
    Map<String, dynamic> lead,
    Store store, {
    bool persist = true,
  }) {
    final reasons = <String>[];
    double points = 0;

    final intent = lead['intent'] as String? ?? '';
    final subject = lead['subject'] as String? ?? '';
    switch (intent) {
      case 'buy_offplan':
        points += 22;
        reasons.add('highIntent');
        reasons.add('offplanInterest');
      case 'buy':
        points += 18;
        reasons.add('highIntent');
      case 'viewing':
        points += 20;
        reasons.add('viewingRequested');
      case 'rent':
        points += 10;
        reasons.add('rentIntent');
      case 'callback':
        points += 8;
      default:
        points += 6;
    }
    if (subject == 'mortgage') {
      points += 6;
      reasons.add('mortgageInterest');
    }

    var specificity = 0;
    if (lead['unitId'] != null) {
      points += 15;
      reasons.add('specificUnit');
      specificity++;
    }
    if (lead['preferredAt'] != null) {
      points += 10;
      reasons.add('preferredTimeSet');
      specificity++;
    }
    final message = (lead['message'] as String? ?? '');
    if (message.trim().length >= 40) {
      points += 8;
      reasons.add('longMessage');
      specificity++;
    }
    if (specificity == 0) {
      reasons.add('lowSpecificity');
      points -= 5;
    }

    final lowerMessage = message.toLowerCase();
    for (final entry in _keywordReasons.entries) {
      if (entry.value.any(lowerMessage.contains)) {
        points += entry.key == 'urgentKeyword' ? 10 : 6;
        reasons.add(entry.key);
      }
    }

    final createdAt = DateTime.tryParse(lead['createdAt'] as String? ?? '');
    final now = DateTime.now();
    if (createdAt != null) {
      final age = now.difference(createdAt);
      if (age.inHours < 2) {
        points += 8;
        reasons.add('recentActivity');
      }
      final status = lead['status'] as String? ?? 'new';
      final lastContactAt = DateTime.tryParse(
        lead['lastContactAt'] as String? ?? '',
      );
      final stillWaiting = status == 'new' || status == 'contacted';
      if (status == 'new' && age.inMinutes > _kSlaMinutes) {
        points += 15;
        reasons.add('slaBreach');
      }
      if (stillWaiting && lastContactAt == null) {
        if (age.inDays >= 3) {
          points += 18;
          reasons.add('noResponse3d');
        } else if (age.inHours >= 24) {
          points += 10;
          reasons.add('noResponse24h');
        }
      }
      if (const {'scheduled', 'visited', 'qualified', 'won'}.contains(status)) {
        points += 12;
        reasons.add('funnelAdvanced');
      } else if (stillWaiting && age.inDays >= 3) {
        points += 8; // stuck, not just quiet — needs attention either way
        reasons.add('stalled');
      }
    }

    final phone = lead['contactPhone'] as String?;
    if (phone != null && phone.trim().isNotEmpty) {
      final sameContact = store.leads.where(
        (l) => l['contactPhone'] == phone && l['id'] != lead['id'],
      );
      if (sameContact.isNotEmpty) {
        points += 10;
        reasons.add('repeatContact');
      }
    }

    final projectId = lead['projectId'] as String?;
    if (projectId != null) {
      final project = store.projectById(projectId);
      if (project != null) {
        final units = [
          for (final b
              in (project['buildings'] as List? ?? const []).cast<Map>())
            ...(b['units'] as List? ?? const []).cast<Map>(),
        ];
        if (units.isNotEmpty) {
          final available = units
              .where((u) => u['status'] == 'available')
              .length;
          if (available / units.length < 0.15) {
            points += 8;
            reasons.add('unitScarcity');
          }
        }
        final recentProjectLeads = store.leads.where((l) {
          if (l['projectId'] != projectId) return false;
          final created = DateTime.tryParse(l['createdAt'] as String? ?? '');
          return created != null && now.difference(created).inDays <= 7;
        }).length;
        if (recentProjectLeads >= 5) {
          points += 6;
          reasons.add('hotProject');
        }
      }
    }

    final clamped = points.clamp(0, 100).round();
    final band = clamped >= _kHotThreshold
        ? LeadBand.hot
        : (clamped >= _kWarmThreshold ? LeadBand.warm : LeadBand.cold);
    final uniqueReasons = reasons.toSet().toList();

    if (persist) {
      lead['aiScore'] = clamped;
      lead['aiBand'] = band;
      lead['aiReasons'] = uniqueReasons;
      lead['aiScoredAt'] = now.toIso8601String();
    }
    return LeadScore(score: clamped, band: band, reasons: uniqueReasons);
  }

  /// Re-scores every lead in [store] and returns how many were updated.
  /// Exposed for a periodic sweep — this dev server does not itself run one
  /// on a timer (see the phase report), but a deploy can call this from a
  /// cron/isolate on `AI_LEAD_SWEEP_INTERVAL_MINUTES` without touching this
  /// file.
  int sweepAll(Store store) {
    var count = 0;
    for (final lead in store.leads) {
      score(lead, store);
      count++;
    }
    return count;
  }

  /// `metrics` aggregate for [leads] (already scoped to the caller's
  /// authorization — system admin sees all, residence admin only their own
  /// projects). Every lead is (re-)scored fresh so the numbers are always
  /// consistent with what `leads[]` on the same response shows.
  Map<String, dynamic> metrics(List<Map<String, dynamic>> leads, Store store) {
    final now = DateTime.now();
    int countSince(Duration d) => leads.where((l) {
      final created = DateTime.tryParse(l['createdAt'] as String? ?? '');
      return created != null && now.difference(created) <= d;
    }).length;

    final byBand = {'hot': 0, 'warm': 0, 'cold': 0};
    for (final lead in leads) {
      final result = score(lead, store, persist: false);
      byBand[result.band] = (byBand[result.band] ?? 0) + 1;
    }

    final perManager = <Map<String, dynamic>>[];
    for (final manager in store.crmAssignees()) {
      final managerId = manager['id'] as String;
      final owned = leads.where((l) => l['ownerUserId'] == managerId).toList();
      final open = owned
          .where((l) => !const {'won', 'lost'}.contains(l['status']))
          .length;
      final hot = owned
          .where((l) => score(l, store, persist: false).band == LeadBand.hot)
          .length;
      final responseTimes = <double>[];
      for (final lead in owned) {
        final created = DateTime.tryParse(lead['createdAt'] as String? ?? '');
        final contacted = DateTime.tryParse(
          lead['lastContactAt'] as String? ?? '',
        );
        if (created != null && contacted != null) {
          responseTimes.add(contacted.difference(created).inMinutes.toDouble());
        }
      }
      final avg = responseTimes.isEmpty
          ? null
          : responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      perManager.add({
        'userId': managerId,
        'name': manager['displayLabel'],
        'openLeads': open,
        'hotLeads': hot,
        'avgResponseMinutes': avg == null
            ? null
            : double.parse(avg.toStringAsFixed(1)),
      });
    }

    final responseTimes = <double>[];
    var breached = 0;
    for (final lead in leads) {
      final created = DateTime.tryParse(lead['createdAt'] as String? ?? '');
      if (created == null) continue;
      final contacted = DateTime.tryParse(
        lead['lastContactAt'] as String? ?? '',
      );
      if (contacted != null) {
        final minutes = contacted.difference(created).inMinutes.toDouble();
        responseTimes.add(minutes);
        if (minutes > _kSlaMinutes) breached++;
      } else if (lead['status'] == 'new' &&
          now.difference(created).inMinutes > _kSlaMinutes) {
        breached++;
      }
    }
    responseTimes.sort();
    final median = responseTimes.isEmpty
        ? null
        : responseTimes[responseTimes.length ~/ 2];

    final funnel = <String, int>{};
    for (final status in const [
      'new',
      'contacted',
      'scheduled',
      'visited',
      'qualified',
      'won',
      'lost',
    ]) {
      funnel[status] = leads.where((l) => l['status'] == status).length;
    }

    final conversion = <Map<String, dynamic>>[];
    for (var i = 0; i < _kFunnelOrder.length - 1; i++) {
      final from = _kFunnelOrder[i];
      final to = _kFunnelOrder[i + 1];
      final reachedFrom = leads
          .where((l) => _funnelReached(l['status'] as String? ?? 'new', from))
          .length;
      final reachedTo = leads
          .where((l) => _funnelReached(l['status'] as String? ?? 'new', to))
          .length;
      conversion.add({
        'from': from,
        'to': to,
        'rate': reachedFrom == 0
            ? 0.0
            : double.parse((reachedTo / reachedFrom).toStringAsFixed(2)),
      });
    }

    final planCap = _intEnv('AI_CRM_LEAD_PLAN_CAP', 100);
    final monthCount = countSince(const Duration(days: 30));

    return {
      'leadVolume': {
        'today': countSince(const Duration(hours: 24)),
        'week': countSince(const Duration(days: 7)),
        'month': monthCount,
        'planCap': planCap,
        'usedPercent': planCap == 0
            ? 0.0
            : double.parse((monthCount / planCap * 100).toStringAsFixed(1)),
      },
      'byBand': byBand,
      'perManager': perManager,
      'responseSla': {
        'targetMinutes': _kSlaMinutes,
        'medianMinutes': median,
        'breachedCount': breached,
        'breachedPercent': leads.isEmpty
            ? 0.0
            : double.parse((breached / leads.length * 100).toStringAsFixed(1)),
      },
      'funnel': funnel,
      'conversion': conversion,
    };
  }

  /// True if a lead currently at [status] has passed through (or reached)
  /// [stage] in the funnel, treating `won` as having passed every stage and
  /// excluding `lost` from progression entirely (denominator-neutral).
  bool _funnelReached(String status, String stage) {
    if (status == 'lost') return false;
    if (status == 'won') return true;
    final statusIdx = _kFunnelOrder.indexOf(status);
    final stageIdx = _kFunnelOrder.indexOf(stage);
    if (statusIdx < 0 || stageIdx < 0) return false;
    return statusIdx >= stageIdx;
  }

  int _intEnv(String name, int fallback) {
    final raw = appEnv()[name]?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    return int.tryParse(raw) ?? fallback;
  }
}

/// Guided option-tree backend for `POST /v1/ai/crm/query` (plan Part 3 "b2b
/// assistant" — not free chat). Every node is a pure function of
/// `(node, params, leadsInScope)`; the tree is fixed and shallow enough that
/// `breadcrumb` can be derived structurally, so the server stays stateless.
class CrmQueryEngine {
  CrmQueryEngine(this._scorer);

  final LeadScoringEngine _scorer;

  static const _nodeIds = {
    'root',
    'hotLeads',
    'byProject',
    'byImportance',
    'todaySummary',
    'whatNext',
    'needsResponse',
    'unassigned',
    'byManager',
    'managerLeads',
    'analytics',
    'weekSummary',
    'conversion',
    'demand',
    'projectMenu',
    'projectHot',
    'projectNoResponse48h',
    'projectNewToday',
    'projectFunnel',
    'projectDemand',
  };

  bool isValidNode(String node) => _nodeIds.contains(node);

  /// [leadsInScope] and [projectsInScope] are already authorization-scoped
  /// by the caller (system admin: everything; residence admin: their own
  /// projects only).
  Map<String, dynamic> handle({
    required String node,
    required Map<String, dynamic> params,
    required List<Map<String, dynamic>> leadsInScope,
    required List<Map<String, dynamic>> projectsInScope,
    required Store store,
  }) {
    // Score once per request instead of once per comparison: several nodes
    // rank the whole scope, and `score()` walks `store.leads` for the
    // repeat-contact and project-heat signals.
    final scores = <String, LeadScore>{
      for (final lead in leadsInScope)
        '${lead['id']}': _scorer.score(lead, store, persist: false),
    };

    final answer = switch (node) {
      'hotLeads' => _hotLeads(leadsInScope, scores),
      'byProject' => _byProject(projectsInScope, leadsInScope, scores),
      'byImportance' => _byImportance(leadsInScope, scores),
      'todaySummary' => _todaySummary(leadsInScope, store),
      'whatNext' => _whatNext(leadsInScope, scores),
      'needsResponse' => _needsResponse(leadsInScope, scores),
      'unassigned' => _unassigned(leadsInScope, scores),
      'byManager' => _byManager(leadsInScope, store),
      'managerLeads' => _managerLeads(params, leadsInScope, store, scores),
      'analytics' => _analytics(),
      'weekSummary' => _weekSummary(leadsInScope, store),
      'conversion' => _conversion(leadsInScope, store),
      'demand' => _demand(leadsInScope, store),
      'projectMenu' => _projectMenu(params, projectsInScope),
      'projectHot' => _projectLeads(
        params,
        projectsInScope,
        leadsInScope,
        scores,
        node: 'projectHot',
        filter: (l) => scores['${l['id']}']?.band == LeadBand.hot,
      ),
      'projectNoResponse48h' => _projectLeads(
        params,
        projectsInScope,
        leadsInScope,
        scores,
        node: 'projectNoResponse48h',
        filter: _noResponse48h,
      ),
      'projectNewToday' => _projectLeads(
        params,
        projectsInScope,
        leadsInScope,
        scores,
        node: 'projectNewToday',
        filter: _createdToday,
      ),
      'projectFunnel' => _projectFunnel(params, projectsInScope, leadsInScope),
      'projectDemand' => _projectDemand(
        params,
        projectsInScope,
        leadsInScope,
        store,
      ),
      _ => _root(),
    };

    return _withExampleFallback(
      answer,
      hasLeads: leadsInScope.isNotEmpty,
      hasProjects: projectsInScope.isNotEmpty,
    );
  }

  /// A brand-new (or demo) workspace has nothing to report, which used to make
  /// every branch of the assistant answer "0". Rather than showing an empty
  /// shell, the same answer is filled with clearly flagged sample cards so the
  /// tool can still be understood at a glance; `isExample` tells the client to
  /// label them and hide the actions that would target real leads.
  Map<String, dynamic> _withExampleFallback(
    Map<String, dynamic> answer, {
    required bool hasLeads,
    required bool hasProjects,
  }) {
    final node = answer['node'] as String? ?? 'root';
    if (hasLeads) return answer;
    if (node == 'byProject' && hasProjects) return answer;
    final cards = _exampleCards(node);
    if (cards == null) return answer;
    return {
      ...answer,
      'messageCode': 'crmBot.example.message',
      'messageParams': const {},
      'isExample': true,
      'cards': cards,
    };
  }

  bool _noResponse48h(Map<String, dynamic> lead) {
    if (lead['lastContactAt'] != null) return false;
    final created = DateTime.tryParse(lead['createdAt'] as String? ?? '');
    return created != null && DateTime.now().difference(created).inHours >= 48;
  }

  bool _createdToday(Map<String, dynamic> lead) {
    final created = DateTime.tryParse(lead['createdAt'] as String? ?? '');
    if (created == null) return false;
    final now = DateTime.now();
    return created.year == now.year &&
        created.month == now.month &&
        created.day == now.day;
  }

  Map<String, dynamic> _root() => {
    'node': 'root',
    'messageCode': 'crmBot.root.message',
    'messageParams': const {},
    'options': [
      _option('hotLeads', 'crmBot.option.hotLeads'),
      _option('whatNext', 'crmBot.option.whatNext'),
      _option('needsResponse', 'crmBot.option.needsResponse'),
      _option('unassigned', 'crmBot.option.unassigned'),
      _option('todaySummary', 'crmBot.option.todaySummary'),
      _option('byProject', 'crmBot.option.byProject'),
      _option('byManager', 'crmBot.option.byManager'),
      _option('analytics', 'crmBot.option.analytics'),
    ],
    'cards': const [],
    'breadcrumb': [_crumb('root', 'crmBot.node.root')],
  };

  Map<String, dynamic> _hotLeads(
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores,
  ) {
    final hot = _rank(
      leads.where((l) => scores['${l['id']}']?.band == LeadBand.hot),
      scores,
    );
    return {
      'node': 'hotLeads',
      'messageCode': 'crmBot.hotLeads.message',
      'messageParams': {'count': hot.length},
      'options': [_backToRoot()],
      'cards': _leadCards(hot, scores),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('hotLeads', 'crmBot.node.hotLeads'),
      ],
    };
  }

  Map<String, dynamic> _byProject(
    List<Map<String, dynamic>> projects,
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores,
  ) {
    final options =
        projects
            .map(
              (p) => <String, dynamic>{
                'id': 'projectMenu',
                'labelCode': 'crmBot.option.project',
                'labelParams': {'name': p['name']},
                'params': {'projectId': p['id']},
              },
            )
            .toList()
          ..add(_backToRoot());
    return {
      'node': 'byProject',
      'messageCode': 'crmBot.byProject.message',
      'messageParams': {'count': projects.length},
      'options': options,
      'cards': projects
          .map(
            (p) => _projectCard(
              p,
              leads.where((l) => l['projectId'] == p['id']).toList(),
              scores,
            ),
          )
          .toList(),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('byProject', 'crmBot.node.byProject'),
      ],
    };
  }

  Map<String, dynamic> _byImportance(
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores,
  ) {
    final ranked = _rank(leads, scores);
    return {
      'node': 'byImportance',
      'messageCode': 'crmBot.byImportance.message',
      'messageParams': {'count': ranked.length},
      'options': [
        _option('analytics', 'crmBot.option.backToAnalytics'),
        _backToRoot(),
      ],
      'cards': _leadCards(ranked, scores),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('analytics', 'crmBot.node.analytics'),
        _crumb('byImportance', 'crmBot.node.byImportance'),
      ],
    };
  }

  /// Leads the team has not answered yet, oldest pain first — the question
  /// "who is waiting on us right now" asked across every project at once.
  Map<String, dynamic> _needsResponse(
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores,
  ) {
    final waiting = _rank(leads.where(_noResponse48h), scores);
    return {
      'node': 'needsResponse',
      'messageCode': 'crmBot.needsResponse.message',
      'messageParams': {'count': waiting.length},
      'options': [_backToRoot()],
      'cards': _leadCards(waiting, scores),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('needsResponse', 'crmBot.node.needsResponse'),
      ],
    };
  }

  Map<String, dynamic> _unassigned(
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores,
  ) {
    final orphans = _rank(
      leads
          .where((l) {
            final owner = l['ownerUserId'];
            return owner == null || (owner is String && owner.trim().isEmpty);
          })
          .where((l) => !_isClosed(l)),
      scores,
    );
    return {
      'node': 'unassigned',
      'messageCode': 'crmBot.unassigned.message',
      'messageParams': {'count': orphans.length},
      'options': [_backToRoot()],
      'cards': _leadCards(orphans, scores),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('unassigned', 'crmBot.node.unassigned'),
      ],
    };
  }

  /// Team workload: one card per manager with open/hot counts and average
  /// response time, each tappable to see that manager's queue.
  Map<String, dynamic> _byManager(
    List<Map<String, dynamic>> leads,
    Store store,
  ) {
    final perManager = (_scorer.metrics(leads, store)['perManager'] as List)
        .cast<Map<String, dynamic>>();
    final options =
        perManager
            .map(
              (m) => <String, dynamic>{
                'id': 'managerLeads',
                'labelCode': 'crmBot.option.manager',
                'labelParams': {'name': m['name']},
                'params': {'userId': m['userId']},
              },
            )
            .toList()
          ..add(_backToRoot());
    return {
      'node': 'byManager',
      'messageCode': 'crmBot.byManager.message',
      'messageParams': {'count': perManager.length},
      'options': options,
      'cards': perManager
          .map(
            (m) => {
              'type': 'manager',
              'userId': m['userId'],
              'name': m['name'],
              'openLeads': m['openLeads'],
              'hotLeads': m['hotLeads'],
              'avgResponseMinutes': m['avgResponseMinutes'],
            },
          )
          .toList(),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('byManager', 'crmBot.node.byManager'),
      ],
    };
  }

  Map<String, dynamic> _managerLeads(
    Map<String, dynamic> params,
    List<Map<String, dynamic>> leads,
    Store store,
    Map<String, LeadScore> scores,
  ) {
    final userId = params['userId'] as String?;
    if (userId == null) {
      return _byManager(leads, store);
    }
    final assignee = store
        .crmAssignees()
        .cast<Map<String, dynamic>?>()
        .firstWhere((a) => a?['id'] == userId, orElse: () => null);
    final name = assignee?['displayLabel']?.toString() ?? userId;
    final owned = _rank(
      leads.where((l) => l['ownerUserId'] == userId && !_isClosed(l)),
      scores,
    );
    return {
      'node': 'managerLeads',
      'messageCode': 'crmBot.managerLeads.message',
      'messageParams': {'name': name, 'count': owned.length},
      'options': [
        _option('byManager', 'crmBot.option.backToManagers'),
        _backToRoot(),
      ],
      'cards': _leadCards(owned, scores),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('byManager', 'crmBot.node.byManager'),
        _crumb('managerLeads', 'crmBot.node.managerLeads', {'name': name}),
      ],
    };
  }

  Map<String, dynamic> _analytics() => {
    'node': 'analytics',
    'messageCode': 'crmBot.analytics.message',
    'messageParams': const {},
    'options': [
      _option('weekSummary', 'crmBot.option.weekSummary'),
      _option('conversion', 'crmBot.option.conversion'),
      _option('demand', 'crmBot.option.demand'),
      _option('byImportance', 'crmBot.option.byImportance'),
      _backToRoot(),
    ],
    'cards': const [],
    'breadcrumb': [
      _crumb('root', 'crmBot.node.root'),
      _crumb('analytics', 'crmBot.node.analytics'),
    ],
  };

  /// Last 7 days against the 7 before them, so each number carries a
  /// direction instead of sitting there as a bare count.
  Map<String, dynamic> _weekSummary(
    List<Map<String, dynamic>> leads,
    Store store,
  ) {
    final now = DateTime.now();
    int countBetween(Duration from, Duration to) => leads.where((l) {
      final created = DateTime.tryParse(l['createdAt'] as String? ?? '');
      if (created == null) return false;
      final age = now.difference(created);
      return age >= to && age < from;
    }).length;

    final thisWeek = countBetween(const Duration(days: 7), Duration.zero);
    final prevWeek = countBetween(
      const Duration(days: 14),
      const Duration(days: 7),
    );
    final wonThisWeek = leads.where((l) {
      if (l['status'] != 'won') return false;
      final created = DateTime.tryParse(l['createdAt'] as String? ?? '');
      return created != null && now.difference(created).inDays < 7;
    }).length;
    final sla = _scorer.metrics(leads, store)['responseSla'] as Map;

    return {
      'node': 'weekSummary',
      'messageCode': 'crmBot.weekSummary.message',
      'messageParams': {'count': thisWeek},
      'options': [
        _option('analytics', 'crmBot.option.backToAnalytics'),
        _backToRoot(),
      ],
      'cards': [
        _metricCard(
          'crmBot.metric.leadsWeek',
          {'count': thisWeek},
          thisWeek,
          'count',
          trend: _trend(thisWeek, prevWeek),
        ),
        _metricCard(
          'crmBot.metric.leadsPrevWeek',
          {'count': prevWeek},
          prevWeek,
          'count',
        ),
        _metricCard(
          'crmBot.metric.wonWeek',
          {'count': wonThisWeek},
          wonThisWeek,
          'count',
        ),
        _metricCard(
          'crmBot.metric.slaBreached',
          {'count': sla['breachedCount']},
          sla['breachedCount'],
          'count',
          // Fewer breaches is the good direction, so an increase reads "down".
          trend: (sla['breachedCount'] as int? ?? 0) > 0 ? 'down' : 'flat',
        ),
      ],
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('analytics', 'crmBot.node.analytics'),
        _crumb('weekSummary', 'crmBot.node.weekSummary'),
      ],
    };
  }

  Map<String, dynamic> _conversion(
    List<Map<String, dynamic>> leads,
    Store store,
  ) {
    final metrics = _scorer.metrics(leads, store);
    final steps = (metrics['conversion'] as List).cast<Map<String, dynamic>>();
    return {
      'node': 'conversion',
      'messageCode': 'crmBot.conversion.message',
      'messageParams': const {},
      'options': [
        _option('analytics', 'crmBot.option.backToAnalytics'),
        _backToRoot(),
      ],
      'cards': [
        for (final step in steps)
          _metricCard(
            'crmBot.metric.conversionStep',
            {'from': step['from'], 'to': step['to']},
            ((step['rate'] as num? ?? 0) * 100).round(),
            'percent',
          ),
      ],
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('analytics', 'crmBot.node.analytics'),
        _crumb('conversion', 'crmBot.node.conversion'),
      ],
    };
  }

  /// What buyers actually ask for: the room mix behind the leads, so the
  /// developer can compare demand against what is still unsold.
  Map<String, dynamic> _demand(List<Map<String, dynamic>> leads, Store store) {
    final counted = _roomDemand(leads, store);
    final total = counted.values.fold<int>(0, (a, b) => a + b);
    return {
      'node': 'demand',
      'messageCode': 'crmBot.demand.message',
      'messageParams': {'count': total},
      'options': [
        _option('analytics', 'crmBot.option.backToAnalytics'),
        _backToRoot(),
      ],
      'cards': _demandCards(counted),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('analytics', 'crmBot.node.analytics'),
        _crumb('demand', 'crmBot.node.demand'),
      ],
    };
  }

  Map<String, dynamic> _todaySummary(
    List<Map<String, dynamic>> leads,
    Store store,
  ) {
    final metrics = _scorer.metrics(leads, store);
    final volume = metrics['leadVolume'] as Map;
    final byBand = metrics['byBand'] as Map;
    final sla = metrics['responseSla'] as Map;
    return {
      'node': 'todaySummary',
      'messageCode': 'crmBot.todaySummary.message',
      'messageParams': {'today': volume['today'], 'hot': byBand['hot']},
      'options': [_backToRoot()],
      'cards': [
        _metricCard(
          'crmBot.metric.leadsToday',
          {'count': volume['today']},
          volume['today'],
          'count',
        ),
        _metricCard(
          'crmBot.metric.hotLeads',
          {'count': byBand['hot']},
          byBand['hot'],
          'count',
        ),
        _metricCard(
          'crmBot.metric.responseSla',
          {'medianMinutes': sla['medianMinutes']},
          sla['medianMinutes'],
          'minutes',
        ),
      ],
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('todaySummary', 'crmBot.node.todaySummary'),
      ],
    };
  }

  Map<String, dynamic> _whatNext(
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores,
  ) {
    final top = _rank(leads.where((l) => !_isClosed(l)), scores);
    return {
      'node': 'whatNext',
      'messageCode': 'crmBot.whatNext.message',
      'messageParams': {'count': top.length},
      'options': [_backToRoot()],
      'cards': _leadCards(top, scores, take: 5),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('whatNext', 'crmBot.node.whatNext'),
      ],
    };
  }

  Map<String, dynamic> _projectMenu(
    Map<String, dynamic> params,
    List<Map<String, dynamic>> projects,
  ) {
    final project = _findProject(params, projects);
    if (project == null) return _projectNotFound();
    return {
      'node': 'projectMenu',
      'messageCode': 'crmBot.projectMenu.message',
      'messageParams': {'name': project['name']},
      'options': [
        {
          'id': 'projectHot',
          'labelCode': 'crmBot.option.projectHot',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        {
          'id': 'projectNoResponse48h',
          'labelCode': 'crmBot.option.projectNoResponse48h',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        {
          'id': 'projectNewToday',
          'labelCode': 'crmBot.option.projectNewToday',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        {
          'id': 'projectFunnel',
          'labelCode': 'crmBot.option.projectFunnel',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        {
          'id': 'projectDemand',
          'labelCode': 'crmBot.option.projectDemand',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        {
          'id': 'byProject',
          'labelCode': 'crmBot.option.backToProjects',
          'labelParams': const {},
          'params': const {},
        },
        _backToRoot(),
      ],
      'cards': const [],
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('byProject', 'crmBot.node.byProject'),
        _crumb('projectMenu', 'crmBot.node.projectMenu', {
          'name': project['name'],
        }),
      ],
    };
  }

  Map<String, dynamic> _projectLeads(
    Map<String, dynamic> params,
    List<Map<String, dynamic>> projects,
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores, {
    required String node,
    required bool Function(Map<String, dynamic>) filter,
  }) {
    final project = _findProject(params, projects);
    if (project == null) return _projectNotFound();
    final matched = _rank(
      leads.where((l) => l['projectId'] == project['id'] && filter(l)),
      scores,
    );
    return {
      'node': node,
      'messageCode': 'crmBot.$node.message',
      'messageParams': {'name': project['name'], 'count': matched.length},
      'options': [
        {
          'id': 'projectMenu',
          'labelCode': 'crmBot.option.backToProjectMenu',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        _backToRoot(),
      ],
      'cards': _leadCards(matched, scores, take: 15),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('byProject', 'crmBot.node.byProject'),
        _crumb('projectMenu', 'crmBot.node.projectMenu', {
          'name': project['name'],
        }),
        _crumb(node, 'crmBot.node.$node'),
      ],
    };
  }

  Map<String, dynamic> _projectFunnel(
    Map<String, dynamic> params,
    List<Map<String, dynamic>> projects,
    List<Map<String, dynamic>> leads,
  ) {
    final project = _findProject(params, projects);
    if (project == null) return _projectNotFound();
    final projectLeads = leads
        .where((l) => l['projectId'] == project['id'])
        .toList();
    final funnel = <String, int>{};
    for (final status in const [
      'new',
      'contacted',
      'scheduled',
      'visited',
      'qualified',
      'won',
      'lost',
    ]) {
      funnel[status] = projectLeads.where((l) => l['status'] == status).length;
    }
    return {
      'node': 'projectFunnel',
      'messageCode': 'crmBot.projectFunnel.message',
      'messageParams': {'name': project['name']},
      'options': [
        {
          'id': 'projectMenu',
          'labelCode': 'crmBot.option.backToProjectMenu',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        _backToRoot(),
      ],
      'cards': funnel.entries
          .map(
            (e) => _metricCard(
              'crmBot.metric.funnel.${e.key}',
              {'count': e.value},
              e.value,
              'count',
            ),
          )
          .toList(),
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('byProject', 'crmBot.node.byProject'),
        _crumb('projectMenu', 'crmBot.node.projectMenu', {
          'name': project['name'],
        }),
        _crumb('projectFunnel', 'crmBot.node.projectFunnel'),
      ],
    };
  }

  /// Room mix asked for inside a single project, next to how many of those
  /// homes are still available there — demand and supply side by side.
  Map<String, dynamic> _projectDemand(
    Map<String, dynamic> params,
    List<Map<String, dynamic>> projects,
    List<Map<String, dynamic>> leads,
    Store store,
  ) {
    final project = _findProject(params, projects);
    if (project == null) return _projectNotFound();
    final projectLeads = leads
        .where((l) => l['projectId'] == project['id'])
        .toList();
    final counted = _roomDemand(projectLeads, store);
    final available = <int, int>{};
    for (final building
        in (project['buildings'] as List? ?? const []).cast<Map>()) {
      for (final unit in (building['units'] as List? ?? const []).cast<Map>()) {
        if (unit['status'] != 'available') continue;
        final rooms = (unit['rooms'] as num?)?.toInt();
        if (rooms == null) continue;
        available[rooms] = (available[rooms] ?? 0) + 1;
      }
    }
    return {
      'node': 'projectDemand',
      'messageCode': 'crmBot.projectDemand.message',
      'messageParams': {'name': project['name']},
      'options': [
        {
          'id': 'projectMenu',
          'labelCode': 'crmBot.option.backToProjectMenu',
          'labelParams': const {},
          'params': {'projectId': project['id']},
        },
        _backToRoot(),
      ],
      'cards': [
        ..._demandCards(counted),
        for (final rooms in (available.keys.toList()..sort()))
          _metricCard(
            'crmBot.metric.availableRooms',
            {'rooms': rooms, 'count': available[rooms]},
            available[rooms],
            'count',
          ),
      ],
      'breadcrumb': [
        _crumb('root', 'crmBot.node.root'),
        _crumb('byProject', 'crmBot.node.byProject'),
        _crumb('projectMenu', 'crmBot.node.projectMenu', {
          'name': project['name'],
        }),
        _crumb('projectDemand', 'crmBot.node.projectDemand'),
      ],
    };
  }

  Map<String, dynamic>? _findProject(
    Map<String, dynamic> params,
    List<Map<String, dynamic>> projects,
  ) {
    final id = params['projectId'] as String?;
    if (id == null) return null;
    for (final p in projects) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  Map<String, dynamic> _projectNotFound() => {
    'node': 'byProject',
    'messageCode': 'crmBot.error.projectNotFound',
    'messageParams': const {},
    'options': [_backToRoot()],
    'cards': const [],
    'breadcrumb': [_crumb('root', 'crmBot.node.root')],
  };

  bool _isClosed(Map<String, dynamic> lead) =>
      const {'won', 'lost'}.contains(lead['status']);

  /// Highest score first, using the per-request score map.
  List<Map<String, dynamic>> _rank(
    Iterable<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores,
  ) {
    int scoreOf(Map<String, dynamic> lead) =>
        scores['${lead['id']}']?.score ?? 0;
    return leads.toList()..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
  }

  List<Map<String, dynamic>> _leadCards(
    List<Map<String, dynamic>> leads,
    Map<String, LeadScore> scores, {
    int take = 10,
  }) => leads.take(take).map((l) => _leadCard(l, scores)).toList();

  Map<String, dynamic> _leadCard(
    Map<String, dynamic> lead,
    Map<String, LeadScore> scores,
  ) {
    final result = scores['${lead['id']}'];
    return {
      'type': 'lead',
      'leadId': lead['id'],
      'number': lead['number'],
      'projectName': lead['projectName'],
      'contactPhone': lead['contactPhone'],
      'status': lead['status'],
      'createdAt': lead['createdAt'],
      'aiScore': result?.score,
      'aiBand': result?.band,
      'aiReasons': result?.reasons ?? const <String>[],
      'actions': const ['openLead', 'assignToMe', 'markContacted'],
    };
  }

  Map<String, dynamic> _projectCard(
    Map<String, dynamic> project,
    List<Map<String, dynamic>> projectLeads,
    Map<String, LeadScore> scores,
  ) {
    final units = [
      for (final b in (project['buildings'] as List? ?? const []).cast<Map>())
        ...(b['units'] as List? ?? const []).cast<Map>(),
    ];
    final hotLeads = projectLeads
        .where((l) => scores['${l['id']}']?.band == LeadBand.hot)
        .length;
    return {
      'type': 'project',
      'projectId': project['id'],
      'projectName': project['name'],
      'hotLeads': hotLeads,
      'openLeads': projectLeads.where((l) => !_isClosed(l)).length,
      'availableUnits': units.where((u) => u['status'] == 'available').length,
    };
  }

  /// Counts how many leads point at a unit of each room count. Leads that
  /// never named a unit carry no room signal and are left out of the mix.
  Map<int, int> _roomDemand(List<Map<String, dynamic>> leads, Store store) {
    final counted = <int, int>{};
    for (final lead in leads) {
      final unitId = lead['unitId'] as String?;
      final projectId = lead['projectId'] as String?;
      if (unitId == null || projectId == null) continue;
      final project = store.projectById(projectId);
      if (project == null) continue;
      for (final building
          in (project['buildings'] as List? ?? const []).cast<Map>()) {
        for (final unit
            in (building['units'] as List? ?? const []).cast<Map>()) {
          if (unit['id'] != unitId) continue;
          final rooms = (unit['rooms'] as num?)?.toInt();
          if (rooms != null) counted[rooms] = (counted[rooms] ?? 0) + 1;
        }
      }
    }
    return counted;
  }

  List<Map<String, dynamic>> _demandCards(Map<int, int> counted) {
    final rooms = counted.keys.toList()
      ..sort((a, b) => counted[b]!.compareTo(counted[a]!));
    return [
      for (final room in rooms.take(6))
        _metricCard(
          'crmBot.metric.demandRooms',
          {'rooms': room, 'count': counted[room]},
          counted[room],
          'count',
        ),
    ];
  }

  String _trend(int current, int previous) {
    if (current > previous) return 'up';
    if (current < previous) return 'down';
    return 'flat';
  }

  Map<String, dynamic> _metricCard(
    String code,
    Map<String, dynamic> params,
    Object? value,
    String unit, {
    String trend = 'flat',
  }) => {
    'type': 'metric',
    'metricCode': code,
    'metricParams': params,
    'value': value,
    'unit': unit,
    'trend': trend,
  };

  /// Sample answer for a workspace that has no leads yet. Returns null for
  /// menu nodes, which read fine empty because their options carry them.
  List<Map<String, dynamic>>? _exampleCards(String node) {
    switch (node) {
      case 'hotLeads':
      case 'whatNext':
      case 'byImportance':
      case 'needsResponse':
      case 'unassigned':
      case 'managerLeads':
      case 'projectHot':
      case 'projectNoResponse48h':
      case 'projectNewToday':
        return _exampleLeads;
      case 'todaySummary':
        return [
          _metricCard('crmBot.metric.leadsToday', {'count': 7}, 7, 'count'),
          _metricCard('crmBot.metric.hotLeads', {'count': 3}, 3, 'count'),
          _metricCard(
            'crmBot.metric.responseSla',
            {'medianMinutes': 42},
            42,
            'minutes',
          ),
        ];
      case 'weekSummary':
        return [
          _metricCard(
            'crmBot.metric.leadsWeek',
            {'count': 31},
            31,
            'count',
            trend: 'up',
          ),
          _metricCard(
            'crmBot.metric.leadsPrevWeek',
            {'count': 24},
            24,
            'count',
          ),
          _metricCard('crmBot.metric.wonWeek', {'count': 4}, 4, 'count'),
          _metricCard(
            'crmBot.metric.slaBreached',
            {'count': 2},
            2,
            'count',
            trend: 'down',
          ),
        ];
      case 'conversion':
        return [
          for (final step in const [
            ['new', 'contacted', 78],
            ['contacted', 'scheduled', 46],
            ['scheduled', 'visited', 61],
            ['visited', 'qualified', 39],
            ['qualified', 'won', 27],
          ])
            _metricCard(
              'crmBot.metric.conversionStep',
              {'from': step[0], 'to': step[1]},
              step[2],
              'percent',
            ),
        ];
      case 'demand':
      case 'projectDemand':
        return _demandCards(const {2: 14, 3: 9, 1: 6, 4: 2});
      case 'byManager':
        return const [
          {
            'type': 'manager',
            'userId': null,
            'name': 'Dilnoza R.',
            'openLeads': 12,
            'hotLeads': 4,
            'avgResponseMinutes': 38.0,
          },
          {
            'type': 'manager',
            'userId': null,
            'name': 'Bekzod A.',
            'openLeads': 9,
            'hotLeads': 2,
            'avgResponseMinutes': 74.0,
          },
        ];
      case 'byProject':
        return const [
          {
            'type': 'project',
            'projectId': null,
            'projectName': 'Yangi Hayot',
            'hotLeads': 3,
            'openLeads': 11,
            'availableUnits': 24,
          },
          {
            'type': 'project',
            'projectId': null,
            'projectName': 'Boulevard Park',
            'hotLeads': 1,
            'openLeads': 6,
            'availableUnits': 41,
          },
        ];
      case 'projectFunnel':
        return [
          for (final stage in const [
            ['new', 8],
            ['contacted', 6],
            ['scheduled', 4],
            ['visited', 3],
            ['qualified', 2],
            ['won', 1],
            ['lost', 2],
          ])
            _metricCard(
              'crmBot.metric.funnel.${stage[0]}',
              {'count': stage[1]},
              stage[1],
              'count',
            ),
        ];
      default:
        return null;
    }
  }

  /// Sample leads shaped exactly like real ones, minus `leadId`/`actions` so
  /// nothing in the UI can try to open or reassign a lead that doesn't exist.
  static final List<Map<String, dynamic>> _exampleLeads = [
    {
      'type': 'lead',
      'leadId': null,
      'number': 'L-1042',
      'projectName': 'Yangi Hayot',
      'contactPhone': '+998 90 123-45-67',
      'status': 'new',
      'createdAt': null,
      'aiScore': 86,
      'aiBand': LeadBand.hot,
      'aiReasons': const ['highIntent', 'specificUnit', 'slaBreach'],
      'actions': const <String>[],
    },
    {
      'type': 'lead',
      'leadId': null,
      'number': 'L-1039',
      'projectName': 'Boulevard Park',
      'contactPhone': '+998 91 555-08-12',
      'status': 'contacted',
      'createdAt': null,
      'aiScore': 72,
      'aiBand': LeadBand.hot,
      'aiReasons': const ['mortgageInterest', 'repeatContact'],
      'actions': const <String>[],
    },
    {
      'type': 'lead',
      'leadId': null,
      'number': 'L-1035',
      'projectName': 'Yangi Hayot',
      'contactPhone': '+998 93 777-21-04',
      'status': 'new',
      'createdAt': null,
      'aiScore': 58,
      'aiBand': LeadBand.warm,
      'aiReasons': const ['viewingRequested', 'noResponse24h'],
      'actions': const <String>[],
    },
  ];

  Map<String, dynamic> _option(String id, String labelCode) => {
    'id': id,
    'labelCode': labelCode,
    'labelParams': const {},
    'params': const {},
  };

  Map<String, dynamic> _backToRoot() =>
      _option('root', 'crmBot.option.backToRoot');

  Map<String, dynamic> _crumb(
    String node,
    String labelCode, [
    Map<String, dynamic> params = const {},
  ]) => {'node': node, 'labelCode': labelCode, 'labelParams': params};
}
