/// Wire models for the server AI module (`server/lib/src/ai/ai_routes.dart`).
/// Every shape here mirrors the Dart-doc comments on that file exactly — see
/// the doc comment above each route for the authoritative contract.
library;

/// One turn in a chat transcript, `role` is `user` or `assistant`.
class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// `{used, limit, remaining, resetAt}`, optionally `available` (only present
/// on `GET /ai/chat/quota`).
class AiQuota {
  const AiQuota({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.resetAt,
    this.available,
  });

  final int used;
  final int limit;
  final int remaining;
  final DateTime resetAt;
  final bool? available;

  bool get isExhausted => remaining <= 0;

  factory AiQuota.fromJson(Map<String, dynamic> json) => AiQuota(
    used: (json['used'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    resetAt:
        DateTime.tryParse(json['resetAt'] as String? ?? '') ??
        DateTime.now().toUtc(),
    available: json['available'] as bool?,
  );
}

/// `POST /v1/ai/chat` response: `{reply, quota}`.
class AiChatReply {
  const AiChatReply({required this.reply, required this.quota});

  final String reply;
  final AiQuota quota;

  factory AiChatReply.fromJson(Map<String, dynamic> json) => AiChatReply(
    reply: json['reply'] as String? ?? '',
    quota: AiQuota.fromJson(json['quota'] as Map<String, dynamic>? ?? const {}),
  );
}

/// Normalized error for every AI call — maps the `{success:false, error:
/// {code, message, data}}` envelope (see `server/lib/src/http_helpers.dart`)
/// plus Dio-level failures (timeout, offline, demo read-only guard) into one
/// shape the UI can switch on without ever showing a raw error string.
class AiException implements Exception {
  const AiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.quota,
    this.retryAfterSeconds,
  });

  /// Server error code (`RATE_LIMITED`, `AI_UNAVAILABLE`, `NOT_IMPLEMENTED`,
  /// `VALIDATION_ERROR`, ...) or a client-side one (`NETWORK`,
  /// `DEMO_READ_ONLY`, `UNKNOWN`).
  final String code;
  final String message;
  final int? statusCode;

  /// Present on `RATE_LIMITED` — the 429 payload carries a full quota
  /// snapshot (`used`, `limit`, `remaining`, `resetAt`).
  final AiQuota? quota;
  final int? retryAfterSeconds;

  bool get isRateLimited => code == 'RATE_LIMITED';
  bool get isUnavailable => code == 'AI_UNAVAILABLE';
  bool get isNotImplemented => code == 'NOT_IMPLEMENTED';
  bool get isDemoReadOnly => code == 'DEMO_READ_ONLY';

  @override
  String toString() => 'AiException($code: $message)';
}

/// One `{code, params}` entry of the smart-search `steps[]` traversal log.
/// `params` carries real counts only — never prose (the client renders
/// localized text from ARB, see `ai_search_steps.dart`).
class AiSearchStep {
  const AiSearchStep({required this.code, required this.params});

  final String code;
  final Map<String, dynamic> params;

  factory AiSearchStep.fromJson(Map<String, dynamic> json) => AiSearchStep(
    code: json['code'] as String? ?? '',
    params: (json['params'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  int? paramInt(String key) => (params[key] as num?)?.toInt();
  String? paramString(String key) => params[key] as String?;
}

/// Real traversal counters returned alongside the search results.
class AiSearchTotals {
  const AiSearchTotals({
    required this.projectsScanned,
    required this.projectsMatched,
    required this.unitsScanned,
    required this.unitsMatched,
    required this.bookedFiltered,
    required this.returned,
    required this.elapsedMs,
  });

  final int projectsScanned;
  final int projectsMatched;
  final int unitsScanned;
  final int unitsMatched;
  final int bookedFiltered;
  final int returned;
  final int elapsedMs;

  factory AiSearchTotals.fromJson(Map<String, dynamic> json) => AiSearchTotals(
    projectsScanned: (json['projectsScanned'] as num?)?.toInt() ?? 0,
    projectsMatched: (json['projectsMatched'] as num?)?.toInt() ?? 0,
    unitsScanned: (json['unitsScanned'] as num?)?.toInt() ?? 0,
    unitsMatched: (json['unitsMatched'] as num?)?.toInt() ?? 0,
    bookedFiltered: (json['bookedFiltered'] as num?)?.toInt() ?? 0,
    returned: (json['returned'] as num?)?.toInt() ?? 0,
    elapsedMs: (json['elapsedMs'] as num?)?.toInt() ?? 0,
  );
}

/// One ranked unit result from `POST /v1/ai/search`.
class AiSearchResult {
  const AiSearchResult({
    required this.unitId,
    required this.projectId,
    required this.projectName,
    this.buildingId,
    required this.district,
    this.coverUrl,
    this.number,
    this.kind,
    this.dealType,
    this.status,
    this.isOffplan = false,
    this.rooms,
    this.floor,
    this.floorsTotal,
    this.areaTotal,
    this.price,
    this.priceM2,
    this.rentMonthly,
    this.projectStatus,
    this.constructionProgress,
    this.plannedProgress,
    this.trustIndex,
    required this.matchScore,
    this.matchReasons = const [],
  });

  final String? unitId;
  final String projectId;
  final String projectName;
  final String? buildingId;
  final String district;
  final String? coverUrl;
  final String? number;
  final String? kind;
  final String? dealType;
  final String? status;
  final bool isOffplan;
  final int? rooms;
  final int? floor;
  final int? floorsTotal;
  final double? areaTotal;
  final double? price;
  final double? priceM2;
  final double? rentMonthly;
  final String? projectStatus;
  final int? constructionProgress;
  final int? plannedProgress;
  final double? trustIndex;
  final int matchScore;
  final List<String> matchReasons;

  /// Whether the tap target should be the unit card or the project screen.
  bool get isUnitScoped => unitId != null && unitId!.isNotEmpty;

  factory AiSearchResult.fromJson(Map<String, dynamic> json) => AiSearchResult(
    unitId: json['unitId'] as String?,
    projectId: json['projectId'] as String? ?? '',
    projectName: json['projectName'] as String? ?? '',
    buildingId: json['buildingId'] as String?,
    district: json['district'] as String? ?? '',
    coverUrl: json['coverUrl'] as String?,
    number: json['number'] as String?,
    kind: json['kind'] as String?,
    dealType: json['dealType'] as String?,
    status: json['status'] as String?,
    isOffplan: json['isOffplan'] as bool? ?? false,
    rooms: (json['rooms'] as num?)?.toInt(),
    floor: (json['floor'] as num?)?.toInt(),
    floorsTotal: (json['floorsTotal'] as num?)?.toInt(),
    areaTotal: (json['areaTotal'] as num?)?.toDouble(),
    price: (json['price'] as num?)?.toDouble(),
    priceM2: (json['priceM2'] as num?)?.toDouble(),
    rentMonthly: (json['rentMonthly'] as num?)?.toDouble(),
    projectStatus: json['projectStatus'] as String?,
    constructionProgress: (json['constructionProgress'] as num?)?.toInt(),
    plannedProgress: (json['plannedProgress'] as num?)?.toInt(),
    trustIndex: (json['trustIndex'] as num?)?.toDouble(),
    matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
    matchReasons:
        (json['matchReasons'] as List?)?.map((e) => e as String).toList() ??
        const [],
  );
}

/// Every field the server can return in `constraints` is nullable; absent
/// means "not constrained". Kept as a raw map (rather than a fixed set of
/// typed fields) so a chip's "remove" action is just "drop this key and
/// resend" — see [withoutKeys].
class AiSearchConstraints {
  const AiSearchConstraints(this.raw);

  final Map<String, dynamic> raw;

  static const empty = AiSearchConstraints({});

  List<int>? get rooms =>
      (raw['rooms'] as List?)?.map((e) => (e as num).toInt()).toList();
  double? get priceMin => (raw['priceMin'] as num?)?.toDouble();
  double? get priceMax => (raw['priceMax'] as num?)?.toDouble();
  String? get currency => raw['currency'] as String?;
  double? get areaMin => (raw['areaMin'] as num?)?.toDouble();
  double? get areaMax => (raw['areaMax'] as num?)?.toDouble();
  String? get district => raw['district'] as String?;
  String? get dealType => raw['dealType'] as String?;
  String? get unitKind => raw['unitKind'] as String?;
  String? get projectStatus => raw['projectStatus'] as String?;
  bool? get isOffplan => raw['isOffplan'] as bool?;
  int? get floorMin => (raw['floorMin'] as num?)?.toInt();
  int? get floorMax => (raw['floorMax'] as num?)?.toInt();
  bool? get notFirstFloor => raw['notFirstFloor'] as bool?;
  bool? get notLastFloor => raw['notLastFloor'] as bool?;
  bool? get availableOnly => raw['availableOnly'] as bool?;
  List<String>? get amenities =>
      (raw['amenities'] as List?)?.map((e) => e as String).toList();

  /// Amenities the query explicitly rules out ("без лифта") — same canonical
  /// vocabulary as [amenities]. Optional server-side addition: absent until
  /// the parser supports negation, so `null`/missing must render as "none".
  List<String>? get excludedAmenities =>
      (raw['excludedAmenities'] as List?)?.map((e) => e as String).toList();
  String? get developerName => raw['developerName'] as String?;
  String? get projectName => raw['projectName'] as String?;
  List<String>? get unrecognized =>
      (raw['unrecognized'] as List?)?.map((e) => e as String).toList();

  bool get isEmpty => activeKeys.isEmpty;

  /// Keys with a "set" value — used to decide which removable chips to show.
  /// `currency` and `unrecognized` are not constraints on their own (the
  /// first only qualifies price, the second is diagnostic), so they are
  /// excluded from the chip row.
  static const _chipKeys = {
    'rooms',
    'priceMin',
    'priceMax',
    'areaMin',
    'areaMax',
    'district',
    'dealType',
    'unitKind',
    'projectStatus',
    'isOffplan',
    'floorMin',
    'floorMax',
    'notFirstFloor',
    'notLastFloor',
    'availableOnly',
    'amenities',
    'excludedAmenities',
    'developerName',
    'projectName',
  };

  Set<String> get activeKeys => raw.entries
      .where((e) => _chipKeys.contains(e.key) && _isSet(e.value))
      .map((e) => e.key)
      .toSet();

  bool _isSet(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  AiSearchConstraints withoutKeys(Set<String> keys) {
    final next = Map<String, dynamic>.of(raw);
    for (final key in keys) {
      next.remove(key);
    }
    return AiSearchConstraints(next);
  }

  Map<String, dynamic> toJson() => raw;

  factory AiSearchConstraints.fromJson(Map<String, dynamic>? json) =>
      AiSearchConstraints(json ?? const {});
}

/// One "did you mean" hint from `POST /v1/ai/search`: [term] is the token the
/// server could not place, [suggestion] its closest known replacement and
/// [query] the full query text with that swap already applied, ready to be
/// re-submitted verbatim.
class AiSearchSuggestion {
  const AiSearchSuggestion({
    required this.term,
    required this.suggestion,
    required this.query,
    this.kind,
    this.confidence,
  });

  final String term;
  final String suggestion;
  final String query;

  /// Which vocabulary the replacement came from (`rooms`, `district`, ...).
  final String? kind;
  final double? confidence;

  factory AiSearchSuggestion.fromJson(Map<String, dynamic> json) =>
      AiSearchSuggestion(
        term: json['term'] as String? ?? '',
        suggestion: json['suggestion'] as String? ?? '',
        query: json['query'] as String? ?? '',
        kind: json['kind'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble(),
      );
}

/// `POST /v1/ai/search` response `data`.
///
/// [blocked] means the server deliberately skipped the catalogue traversal
/// because it understood nothing: [results] is empty, every [totals] counter
/// is `0` and [steps] ends with `noMatchIntent`. [suggestions] on a
/// non-blocked response are non-blocking hints shown above real results.
class AiSearchResponse {
  const AiSearchResponse({
    required this.steps,
    required this.results,
    required this.constraints,
    required this.totals,
    this.understood = true,
    this.blocked = false,
    this.suggestions = const [],
    this.unknownTerms = const [],
  });

  final List<AiSearchStep> steps;
  final List<AiSearchResult> results;
  final AiSearchConstraints constraints;
  final AiSearchTotals totals;
  final bool understood;
  final bool blocked;
  final List<AiSearchSuggestion> suggestions;
  final List<String> unknownTerms;

  factory AiSearchResponse.fromJson(Map<String, dynamic> json) =>
      AiSearchResponse(
        steps: (json['steps'] as List? ?? const [])
            .map((e) => AiSearchStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        results: (json['results'] as List? ?? const [])
            .map((e) => AiSearchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        constraints: AiSearchConstraints.fromJson(
          json['constraints'] as Map<String, dynamic>?,
        ),
        totals: AiSearchTotals.fromJson(
          json['totals'] as Map<String, dynamic>? ?? const {},
        ),
        understood: json['understood'] as bool? ?? true,
        blocked: json['blocked'] as bool? ?? false,
        suggestions: (json['suggestions'] as List? ?? const [])
            .map((e) => AiSearchSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        unknownTerms:
            (json['unknownTerms'] as List?)?.map((e) => e as String).toList() ??
            const [],
      );
}

/// One full-query candidate from `POST /v1/ai/search/suggest`. [tail] is the
/// part that would be appended to what the user has typed so far; [text] is
/// the whole resulting query.
class AiCompletionSuggestion {
  const AiCompletionSuggestion({
    required this.text,
    this.tail,
    this.kind,
    this.score,
  });

  final String text;
  final String? tail;
  final String? kind;
  final double? score;

  factory AiCompletionSuggestion.fromJson(Map<String, dynamic> json) =>
      AiCompletionSuggestion(
        text: json['text'] as String? ?? '',
        tail: json['tail'] as String?,
        kind: json['kind'] as String?,
        score: (json['score'] as num?)?.toDouble(),
      );
}

/// `POST /v1/ai/search/suggest` response `data` — the cheap, deterministic,
/// quota-free companion to `/ai/search` that powers the inline ghost-text
/// completion while the user is still typing.
///
/// [completion] is the tail to append to the current query verbatim (it may
/// start with a space), [completionFull] the same completion as a whole query.
/// Either may be `null` when the server has nothing to offer.
class AiSearchSuggestResponse {
  const AiSearchSuggestResponse({
    this.completion,
    this.completionFull,
    this.suggestions = const [],
  });

  final String? completion;
  final String? completionFull;
  final List<AiCompletionSuggestion> suggestions;

  factory AiSearchSuggestResponse.fromJson(Map<String, dynamic> json) =>
      AiSearchSuggestResponse(
        completion: json['completion'] as String?,
        completionFull: json['completionFull'] as String?,
        suggestions: (json['suggestions'] as List? ?? const [])
            .map(
              (e) => AiCompletionSuggestion.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}
