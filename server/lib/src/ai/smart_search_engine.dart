/// Deterministic multilingual (ru/uz/en) smart search — plan Part 2. No
/// OpenAI call: parses free text into structured constraints, walks
/// `store.publishedProjects` -> buildings -> units, and ranks survivors.
///
/// Field names and step/reason codes match the doc comment above
/// `POST /v1/ai/search` in `ai_routes.dart` exactly — that comment is the
/// binding contract for the b2c client built in parallel.
///
/// The vocabulary itself lives in `search_dictionary.dart`; this file is the
/// parser, the traversal and the ranking. A query the dictionary cannot make
/// sense of is *not* searched: it comes back `blocked` with "did you mean"
/// suggestions instead of a result count nobody asked for.
library;

import '../env_loader.dart';
import '../store.dart';
import 'search_dictionary.dart';

export 'search_dictionary.dart'
    show
        CatalogueVocabulary,
        SearchTerm,
        SearchTermKind,
        kSearchDistrictEntries,
        kSearchDistricts,
        normalizeSearchText;

/// Fallback for `в центре` when the catalogue is unknown (a direct
/// [SmartSearchParser.parse] call in a test) — the most central district in
/// [kSearchDistrictEntries].
const String _fallbackCentralDistrict = 'Mirabad';

/// Dart's `\w` is ASCII-only: `комн\w*` matches `комн` and leaves `атная`
/// behind, which is exactly how a perfectly understood query ends up
/// reporting half of itself as unknown. Every suffix wildcard below spells the
/// alphabet out instead.
const String _wordTail = r"[а-яa-z']*";

/// `unitKind` domain in the contract (`apartment | commercial | parking`).
/// The catalogue's real `kind` vocabulary is `apartment | office | retail`
/// (no `parking` inventory yet) — `office`/`retail` both map to
/// `commercial` on the way out, and `commercial` on the way in matches
/// either. See the deviation note in the phase report.
String _publicKind(String? storeKind) =>
    storeKind == 'apartment' ? 'apartment' : 'commercial';

bool _kindMatchesConstraint(String storeKind, String wantedPublicKind) {
  // The parser no longer emits `unitKind: parking` (the dictionary maps
  // parking words to the `parking` *amenity* instead), but a client override
  // may still carry it — and with zero parking inventory the honest answer
  // is "matches nothing".
  if (wantedPublicKind == 'parking') return false;
  return _publicKind(storeKind) == wantedPublicKind;
}

/// Approximate UZS-per-USD used only to compare a UZS-denominated budget
/// against the catalogue's USD-denominated prices (there is no live FX feed
/// in this dev server). Override with `AI_SEARCH_UZS_PER_USD`.
double _uzsPerUsd() {
  final raw = appEnv()['AI_SEARCH_UZS_PER_USD']?.trim();
  final parsed = raw == null ? null : double.tryParse(raw);
  return parsed != null && parsed > 0 ? parsed : 12700.0;
}

/// One parsed/overridden search constraint set. Every field mirrors the
/// `constraints` shape documented above `POST /v1/ai/search`.
class SearchConstraints {
  Set<int>? rooms;
  double? priceMin;
  double? priceMax;
  String? currency; // USD | UZS
  double? areaMin;
  double? areaMax;
  String? district;
  String? dealType; // sale | rent
  String? unitKind; // apartment | commercial | parking
  String? projectStatus;
  bool? isOffplan;
  int? floorMin;
  int? floorMax;
  bool? notFirstFloor;
  bool? notLastFloor;

  /// Specific floors the query refuses («не на 2 этаже», «кроме 5 этажа»).
  /// Distinct from [floorMin]/[floorMax] — those are a range, this is a veto
  /// on exact numbers regardless of where they sit relative to any range.
  Set<int>? excludeFloors;
  bool? availableOnly;
  Set<String> amenities = {};

  /// Amenities the query explicitly does **not** want («без ремонта»,
  /// «mebelsiz», «without parking»). Same canonical ids as [amenities]; a
  /// unit whose project offers an excluded amenity is filtered out.
  Set<String> excludedAmenities = {};

  /// Amenities nothing in the catalogue offers. They rank, they never filter —
  /// see the `softenedAmenity` step.
  Set<String> softAmenities = {};

  /// Soft wishes with no numeric threshold behind them: `недорого`,
  /// `премиум`, `просторная`, `высокий этаж`. They only move the score.
  String? pricePreference; // cheap | premium
  String? areaPreference; // large | small
  String? floorPreference; // high | low | mid
  String? developerName;
  String? projectName;
  List<String> unrecognized = [];

  int get constraintCount {
    var n = 0;
    if (rooms != null && rooms!.isNotEmpty) n++;
    if (priceMin != null) n++;
    if (priceMax != null) n++;
    if (areaMin != null) n++;
    if (areaMax != null) n++;
    if (district != null) n++;
    if (dealType != null) n++;
    if (unitKind != null) n++;
    if (projectStatus != null) n++;
    if (isOffplan != null) n++;
    if (floorMin != null) n++;
    if (floorMax != null) n++;
    if (notFirstFloor == true) n++;
    if (notLastFloor == true) n++;
    if (excludeFloors != null && excludeFloors!.isNotEmpty) n++;
    if (availableOnly == true) n++;
    if (amenities.isNotEmpty) n++;
    if (excludedAmenities.isNotEmpty) n++;
    if (softAmenities.isNotEmpty) n++;
    if (pricePreference != null) n++;
    if (areaPreference != null) n++;
    if (floorPreference != null) n++;
    if (developerName != null) n++;
    if (projectName != null) n++;
    return n;
  }

  Map<String, dynamic> toJson() => {
    'rooms': rooms == null ? null : (rooms!.toList()..sort()),
    'priceMin': priceMin,
    'priceMax': priceMax,
    'currency': currency,
    'areaMin': areaMin,
    'areaMax': areaMax,
    'district': district,
    'dealType': dealType,
    'unitKind': unitKind,
    'projectStatus': projectStatus,
    'isOffplan': isOffplan,
    'floorMin': floorMin,
    'floorMax': floorMax,
    'notFirstFloor': notFirstFloor,
    'notLastFloor': notLastFloor,
    'excludeFloors': excludeFloors == null
        ? null
        : (excludeFloors!.toList()..sort()),
    'availableOnly': availableOnly,
    'amenities': amenities.toList(),
    'excludedAmenities': excludedAmenities.toList(),
    'softAmenities': softAmenities.toList(),
    'pricePreference': pricePreference,
    'areaPreference': areaPreference,
    'floorPreference': floorPreference,
    'developerName': developerName,
    'projectName': projectName,
    'unrecognized': unrecognized,
  };

  /// Field-by-field override from `request.constraints` (already-parsed
  /// shape, e.g. echoed back minus a removed chip). Absent/null keys leave
  /// the current value untouched — callers pass a freshly-built instance so
  /// in practice every recognized key simply sets the field.
  static SearchConstraints fromJson(Map<String, dynamic> json) {
    final c = SearchConstraints();
    final rawRooms = json['rooms'];
    if (rawRooms is List) {
      c.rooms = rawRooms.whereType<num>().map((n) => n.toInt()).toSet();
    }
    c.priceMin = (json['priceMin'] as num?)?.toDouble();
    c.priceMax = (json['priceMax'] as num?)?.toDouble();
    c.currency = json['currency'] as String?;
    c.areaMin = (json['areaMin'] as num?)?.toDouble();
    c.areaMax = (json['areaMax'] as num?)?.toDouble();
    c.district = json['district'] as String?;
    c.dealType = json['dealType'] as String?;
    c.unitKind = json['unitKind'] as String?;
    c.projectStatus = json['projectStatus'] as String?;
    c.isOffplan = json['isOffplan'] as bool?;
    c.floorMin = (json['floorMin'] as num?)?.toInt();
    c.floorMax = (json['floorMax'] as num?)?.toInt();
    c.notFirstFloor = json['notFirstFloor'] as bool?;
    c.notLastFloor = json['notLastFloor'] as bool?;
    final rawExcludeFloors = json['excludeFloors'];
    if (rawExcludeFloors is List) {
      c.excludeFloors = rawExcludeFloors
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet();
    }
    c.availableOnly = json['availableOnly'] as bool?;
    final rawAmenities = json['amenities'];
    if (rawAmenities is List) {
      c.amenities = rawAmenities.whereType<String>().toSet();
    }
    final rawExcludedAmenities = json['excludedAmenities'];
    if (rawExcludedAmenities is List) {
      c.excludedAmenities = rawExcludedAmenities.whereType<String>().toSet();
    }
    final rawSoftAmenities = json['softAmenities'];
    if (rawSoftAmenities is List) {
      c.softAmenities = rawSoftAmenities.whereType<String>().toSet();
    }
    c.pricePreference = json['pricePreference'] as String?;
    c.areaPreference = json['areaPreference'] as String?;
    c.floorPreference = json['floorPreference'] as String?;
    c.developerName = json['developerName'] as String?;
    c.projectName = json['projectName'] as String?;
    final rawUnrecognized = json['unrecognized'];
    if (rawUnrecognized is List) {
      c.unrecognized = rawUnrecognized.whereType<String>().toList();
    }
    return c;
  }
}

/// A single `{code, params}` step, emitted in traversal order with real
/// counts — never prose (the client localizes from ARB).
class SearchStep {
  const SearchStep(this.code, this.params);
  final String code;
  final Map<String, dynamic> params;

  Map<String, dynamic> toJson() => {'code': code, 'params': params};
}

/// A word we read as something else. Surfaced as the `autocorrected` step so
/// the UI can say "read X as Y" instead of quietly changing the query.
class SearchAutocorrection {
  const SearchAutocorrection(this.from, this.to);
  final String from;
  final String to;
}

/// Why a suggestion is being offered: a token we could not resolve, or an
/// amenity the catalogue simply does not have.
enum SuggestionReason { unresolved, softenedAmenity }

/// A "did you mean" candidate before it is rendered into the request
/// language. The parser has no opinion on language or on the raw casing of
/// the query, so both are applied by the engine.
class SearchSuggestionCandidate {
  const SearchSuggestionCandidate({
    required this.term,
    required this.target,
    required this.confidence,
    required this.reason,
  });

  /// The raw token from the query, normalized to lower case.
  final String term;
  final SearchTerm target;
  final double confidence;
  final SuggestionReason reason;

  Map<String, dynamic> toJson(String language, String rawQuery) {
    final replacement = target.labelFor(language);
    // A softened amenity has no better spelling to offer — the catalogue
    // simply does not have it — so the useful re-run is the same query
    // without that wish.
    final swap = reason == SuggestionReason.softenedAmenity ? '' : replacement;
    return {
      'term': term,
      'suggestion': replacement,
      'query': _swapTerm(rawQuery, term, swap),
      'kind': target.kind.wireName,
      'confidence': double.parse(confidence.toStringAsFixed(2)),
    };
  }

  /// The query the client can re-submit verbatim: [rawQuery] with the first
  /// occurrence of [term] replaced. Normalization is length-preserving, so
  /// the index found in the normalized text is valid in the raw one.
  static String _swapTerm(String rawQuery, String term, String replacement) {
    final index = normalizeSearchText(rawQuery).indexOf(term);
    if (index < 0) return rawQuery;
    final swapped =
        rawQuery.substring(0, index) +
        replacement +
        rawQuery.substring(index + term.length);
    return swapped.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }
}

/// Everything the parser learned from one query: the constraints plus the
/// honest bookkeeping the contract needs to explain itself.
class ParsedQuery {
  ParsedQuery({
    required this.constraints,
    required this.suggestions,
    required this.autocorrections,
    required this.meaningfulTokens,
    required this.softenedAmenities,
  });

  /// A structured re-run (chip removal): nothing was parsed, so nothing can
  /// be misunderstood.
  ParsedQuery.fromOverride(this.constraints)
    : suggestions = const [],
      autocorrections = const [],
      meaningfulTokens = const [],
      softenedAmenities = const [];

  final SearchConstraints constraints;
  final List<SearchSuggestionCandidate> suggestions;
  final List<SearchAutocorrection> autocorrections;

  /// Query tokens minus stopwords and minus anything shorter than three
  /// characters. Non-empty with zero constraints is exactly the case that
  /// must not reach the catalogue.
  final List<String> meaningfulTokens;

  /// Amenity keys downgraded from filter to preference.
  final List<String> softenedAmenities;
}

/// Runs the parser + ranking pipeline and returns the exact response `data`
/// documented above `POST /v1/ai/search`.
class SmartSearchEngine {
  Map<String, dynamic> run(
    Store store, {
    required String query,
    required String language,
    Map<String, dynamic>? constraintsOverride,
    int limit = 20,
  }) {
    final sw = Stopwatch()..start();
    final steps = <SearchStep>[];
    final catalogue = CatalogueVocabulary.fromProjects(store.publishedProjects);

    final ParsedQuery parsed;
    if (constraintsOverride != null) {
      // Chip removal / re-run: trust the caller's already-parsed shape and
      // skip re-parsing the free text entirely (plan: "takes priority over
      // re-parsing so a removed chip re-runs cleanly").
      parsed = ParsedQuery.fromOverride(
        SearchConstraints.fromJson(constraintsOverride),
      );
    } else {
      parsed = SmartSearchParser.analyze(query, catalogue: catalogue);
    }
    final constraints = parsed.constraints;
    steps.add(
      SearchStep('parsing', {'constraintCount': constraints.constraintCount}),
    );
    for (final correction in parsed.autocorrections) {
      steps.add(
        SearchStep('autocorrected', {
          'from': correction.from,
          'to': correction.to,
        }),
      );
    }

    final ranked = [...parsed.suggestions]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final suggestions = ranked
        .take(5)
        .map((s) => s.toJson(language, query))
        .toList();

    // The core of the "stop pretending you understood" fix: no constraint at
    // all out of a query that clearly said *something* means we never touch
    // the catalogue and never report a match count.
    final blocked =
        constraintsOverride == null &&
        constraints.constraintCount == 0 &&
        parsed.meaningfulTokens.isNotEmpty;
    if (blocked) {
      final terms = <String>{
        ...ranked.map((s) => s.term),
        ...constraints.unrecognized,
      };
      steps.add(
        SearchStep('noMatchIntent', {
          'terms': terms.isEmpty ? parsed.meaningfulTokens : terms.toList(),
        }),
      );
      sw.stop();
      return {
        'steps': steps.map((s) => s.toJson()).toList(),
        'results': const [],
        'constraints': constraints.toJson(),
        'totals': {
          'projectsScanned': 0,
          'projectsMatched': 0,
          'unitsScanned': 0,
          'unitsMatched': 0,
          'bookedFiltered': 0,
          'returned': 0,
          'elapsedMs': sw.elapsedMilliseconds,
        },
        'understood': false,
        'blocked': true,
        'suggestions': suggestions,
        'unknownTerms': constraints.unrecognized,
      };
    }

    for (final amenity in parsed.softenedAmenities) {
      steps.add(SearchStep('softenedAmenity', {'amenity': amenity}));
    }
    final unresolved = ranked
        .where((s) => s.reason == SuggestionReason.unresolved)
        .toList();
    if (unresolved.isNotEmpty) {
      steps.add(
        SearchStep('lowConfidence', {
          'terms': unresolved.map((s) => s.term).toList(),
          'count': unresolved.length,
        }),
      );
    }

    var projects = store.publishedProjects;
    final projectsScannedTotal = projects.length;

    final district = constraints.district;
    if (district != null) {
      steps.add(
        SearchStep('scanningDistrict', {
          'district': district,
          'projectsScanned': projectsScannedTotal,
        }),
      );
      projects = projects
          .where((p) => (p['district'] as String? ?? '') == district)
          .toList();
      steps.add(
        SearchStep('foundInDistrict', {
          'district': district,
          'count': projects.length,
        }),
      );
    }

    if (constraints.developerName != null) {
      final needle = constraints.developerName!.toLowerCase();
      projects = projects.where((p) {
        final name = ((p['developer'] as Map?)?['name'] as String?) ?? '';
        return name.toLowerCase().contains(needle);
      }).toList();
    }
    if (constraints.projectName != null) {
      final needle = constraints.projectName!.toLowerCase();
      projects = projects
          .where(
            (p) => (p['name'] as String? ?? '').toLowerCase().contains(needle),
          )
          .toList();
    }
    if (constraints.projectStatus != null) {
      projects = projects
          .where((p) => p['status'] == constraints.projectStatus)
          .toList();
    }

    final projectsMatched = projects.length;

    var unitsScanned = 0;
    var unitsAfterHardFilters = 0;
    var bookedFiltered = 0;
    final scored = <_ScoredResult>[];

    for (var i = 0; i < projects.length; i++) {
      final project = projects[i];
      final projectName = project['name'] as String? ?? '';
      steps.add(
        SearchStep('openingProject', {
          'project': projectName,
          'index': i + 1,
          'total': projects.length,
        }),
      );

      final buildings = (project['buildings'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final projectUnits =
          <({Map<String, dynamic> building, Map<String, dynamic> unit})>[];
      for (final building in buildings) {
        for (final unit
            in (building['units'] as List? ?? const [])
                .cast<Map<String, dynamic>>()) {
          projectUnits.add((building: building, unit: unit));
        }
      }
      unitsScanned += projectUnits.length;
      steps.add(
        SearchStep('scanningUnits', {
          'project': projectName,
          'count': projectUnits.length,
        }),
      );

      final matchingRegardlessOfStatus = projectUnits
          .where(
            (e) => _passesHardFilters(constraints, project, e.building, e.unit),
          )
          .length;
      final candidates = projectUnits
          .where(
            (e) =>
                e.unit['status'] == 'available' &&
                _passesHardFilters(constraints, project, e.building, e.unit),
          )
          .toList();
      bookedFiltered += matchingRegardlessOfStatus - candidates.length;
      unitsAfterHardFilters += candidates.length;

      for (final entry in candidates) {
        scored.add(
          _scoreUnit(constraints, project, entry.building, entry.unit),
        );
      }
    }

    if (bookedFiltered < 0) bookedFiltered = 0;
    steps.add(
      SearchStep('filteringBooked', {
        'removed': bookedFiltered,
        'left': unitsAfterHardFilters,
      }),
    );

    scored.sort((a, b) => b.score.compareTo(a.score));
    steps.add(SearchStep('rankingPrice', {'count': scored.length}));

    final safeLimit = limit < 1 ? 1 : (limit > 50 ? 50 : limit);
    final page = scored.take(safeLimit).toList();

    sw.stop();
    steps.add(
      SearchStep('done', {
        'count': page.length,
        'elapsedMs': sw.elapsedMilliseconds,
      }),
    );

    return {
      'steps': steps.map((s) => s.toJson()).toList(),
      'results': page.map((r) => r.toJson()).toList(),
      'constraints': constraints.toJson(),
      'totals': {
        'projectsScanned': projectsScannedTotal,
        'projectsMatched': projectsMatched,
        'unitsScanned': unitsScanned,
        'unitsMatched': unitsAfterHardFilters,
        'bookedFiltered': bookedFiltered,
        'returned': page.length,
        'elapsedMs': sw.elapsedMilliseconds,
      },
      'understood': constraints.constraintCount > 0,
      'blocked': false,
      'suggestions': suggestions,
      'unknownTerms': constraints.unrecognized,
    };
  }

  bool _passesHardFilters(
    SearchConstraints c,
    Map<String, dynamic> project,
    Map<String, dynamic> building,
    Map<String, dynamic> unit,
  ) {
    if (c.dealType != null && unit['dealType'] != c.dealType) return false;
    // The engine only *returns* available units anyway (see the candidates
    // filter in [run]), but an explicit `availableOnly` chip must also hold
    // for a client-supplied constraints override.
    if (c.availableOnly == true && unit['status'] != 'available') return false;
    if (c.unitKind != null &&
        !_kindMatchesConstraint(
          unit['kind'] as String? ?? 'apartment',
          c.unitKind!,
        )) {
      return false;
    }
    if (c.rooms != null && c.rooms!.isNotEmpty) {
      final rooms = unit['rooms'] as int?;
      final isStudio = c.rooms!.contains(0);
      if (rooms == null) {
        if (!isStudio) return false;
      } else if (!c.rooms!.contains(rooms)) {
        return false;
      }
    }
    if (c.isOffplan != null &&
        (unit['isOffplan'] as bool? ?? false) != c.isOffplan) {
      return false;
    }
    final area = (unit['areaTotal'] as num?)?.toDouble();
    if (c.areaMin != null && (area == null || area < c.areaMin!)) return false;
    if (c.areaMax != null && (area == null || area > c.areaMax!)) return false;

    final price = unit['dealType'] == 'rent'
        ? (unit['rentMonthly'] as num?)?.toDouble()
        : (unit['price'] as num?)?.toDouble();
    if (c.priceMin != null || c.priceMax != null) {
      if (price == null) return false;
      final rate = c.currency == 'UZS' ? _uzsPerUsd() : 1.0;
      if (c.priceMin != null && price < c.priceMin! / rate) return false;
      if (c.priceMax != null && price > c.priceMax! / rate) return false;
    }

    final floor = unit['floor'] as int?;
    final floorsTotal = building['floors'] as int?;
    if (floor != null) {
      if (c.floorMin != null && floor < c.floorMin!) return false;
      if (c.floorMax != null && floor > c.floorMax!) return false;
      if (c.notFirstFloor == true && floor == 1) return false;
      if (c.notLastFloor == true &&
          floorsTotal != null &&
          floor == floorsTotal) {
        return false;
      }
      if (c.excludeFloors != null && c.excludeFloors!.contains(floor)) {
        return false;
      }
    }

    if (c.amenities.isNotEmpty || c.excludedAmenities.isNotEmpty) {
      final projectAmenities = (project['amenities'] as List? ?? const [])
          .map((a) => a.toString().toLowerCase())
          .toList();
      for (final wanted in c.amenities) {
        final matches = projectAmenities.any(
          (a) => a.contains(wanted.toLowerCase()),
        );
        if (!matches) return false;
      }
      // Mirror of the positive check: offering an excluded amenity is a veto.
      for (final banned in c.excludedAmenities) {
        final offers = projectAmenities.any(
          (a) => a.contains(banned.toLowerCase()),
        );
        if (offers) return false;
      }
    }
    return true;
  }

  _ScoredResult _scoreUnit(
    SearchConstraints c,
    Map<String, dynamic> project,
    Map<String, dynamic> building,
    Map<String, dynamic> unit,
  ) {
    final reasons = <String>[];
    var score = 50.0;

    if (c.district != null) {
      reasons.add('districtMatch');
      score += 5;
    }
    if (c.rooms != null && c.rooms!.isNotEmpty) {
      reasons.add('roomsMatch');
      score += 8;
    }
    if (c.dealType != null) {
      reasons.add('dealTypeMatch');
      score += 4;
    }
    if (c.unitKind != null) {
      reasons.add('kindMatch');
      score += 4;
    }
    if (c.developerName != null) {
      reasons.add('developerMatch');
      score += 4;
    }
    if (c.projectName != null) {
      reasons.add('projectMatch');
      score += 4;
    }
    if (c.amenities.isNotEmpty) {
      reasons.add('amenityMatch');
      score += 4;
    }

    reasons.add('availableNow'); // already filtered to status == available
    score += 5;

    final price = unit['dealType'] == 'rent'
        ? (unit['rentMonthly'] as num?)?.toDouble()
        : (unit['price'] as num?)?.toDouble();
    if ((c.priceMin != null || c.priceMax != null) && price != null) {
      reasons.add('priceFit');
      score += 15;
      final rate = c.currency == 'UZS' ? _uzsPerUsd() : 1.0;
      final maxUsd = c.priceMax == null ? null : c.priceMax! / rate;
      if (maxUsd != null && price <= maxUsd * 0.9) {
        reasons.add('priceBelowBudget');
        score += 5;
      }
    }
    // `недорого` / `премиум` carry no threshold, so they only tilt the order.
    if (c.pricePreference != null && price != null) {
      final reference = unit['dealType'] == 'rent' ? 3000.0 : 200000.0;
      final position = (price / reference).clamp(0.0, 1.0);
      if (c.pricePreference == 'cheap') {
        reasons.add('budgetPreference');
        score += 10 * (1 - position);
      } else {
        reasons.add('premiumPreference');
        score += 10 * position;
      }
    }

    final area = (unit['areaTotal'] as num?)?.toDouble();
    if ((c.areaMin != null || c.areaMax != null) && area != null) {
      reasons.add('areaFit');
      score += 12;
    }
    if (c.areaPreference != null && area != null) {
      final position = (area / 140).clamp(0.0, 1.0);
      reasons.add('areaPreference');
      score += 8 * (c.areaPreference == 'large' ? position : 1 - position);
    }

    final floor = unit['floor'] as int?;
    final floorsTotal = building['floors'] as int?;
    if (floor != null &&
        (c.floorMin != null ||
            c.floorMax != null ||
            c.notFirstFloor == true ||
            c.notLastFloor == true ||
            (c.excludeFloors != null && c.excludeFloors!.isNotEmpty))) {
      reasons.add('floorPreference');
      score += 8;
    } else if (floor != null && floorsTotal != null && floorsTotal > 2) {
      // Mild, constraint-free preference for a middle floor over ground/top.
      final mid = floor > 1 && floor < floorsTotal;
      if (mid) score += 2;
    }
    if (c.floorPreference != null &&
        floor != null &&
        floorsTotal != null &&
        floorsTotal > 1) {
      final position = (floor - 1) / (floorsTotal - 1);
      final fit = switch (c.floorPreference) {
        'high' => position,
        'low' => 1 - position,
        _ => 1 - (position - 0.5).abs() * 2,
      };
      reasons.add('floorPreference');
      score += 8 * fit;
    }

    if (c.softAmenities.isNotEmpty) {
      final projectAmenities = (project['amenities'] as List? ?? const [])
          .map((a) => a.toString().toLowerCase())
          .toList();
      for (final wanted in c.softAmenities) {
        if (projectAmenities.any((a) => a.contains(wanted))) {
          reasons.add('amenityMatch');
          score += 3;
          break;
        }
      }
    }

    final progress = (project['constructionProgress'] as num?)?.toDouble();
    final planned = (project['plannedProgress'] as num?)?.toDouble();
    double? trustIndex;
    if (progress != null && planned != null && planned > 0) {
      trustIndex = progress / planned;
      score += (trustIndex.clamp(0, 1.3) * 12);
      if (trustIndex >= 0.95) {
        reasons.add('highTrustIndex');
      }
    }

    if (project['status'] == 'under_construction' && (progress ?? 0) >= 80) {
      reasons.add('readySoon');
      score += 4;
    }
    if ((unit['isOffplan'] as bool? ?? false) && price != null) {
      reasons.add('offplanDiscount');
      score += 3;
    }

    final clamped = score.clamp(0, 100).round();

    return _ScoredResult(
      score: clamped,
      json: {
        'unitId': unit['id'],
        'projectId': project['id'],
        'projectName': project['name'],
        'buildingId': building['id'],
        'district': project['district'],
        'coverUrl': _coverUrl(unit, project),
        'number': unit['number'],
        'kind': _publicKind(unit['kind'] as String?),
        'dealType': unit['dealType'],
        'status': unit['status'],
        'isOffplan': unit['isOffplan'] ?? false,
        'rooms': unit['rooms'],
        'floor': unit['floor'],
        'floorsTotal': building['floors'],
        'areaTotal': unit['areaTotal'],
        'price': unit['dealType'] == 'rent' ? null : unit['price'],
        'priceM2': unit['priceM2'],
        'rentMonthly': unit['dealType'] == 'rent' ? unit['rentMonthly'] : null,
        'projectStatus': project['status'],
        'constructionProgress': project['constructionProgress'],
        'plannedProgress': project['plannedProgress'],
        'trustIndex': trustIndex == null
            ? null
            : double.parse(trustIndex.toStringAsFixed(2)),
        'matchScore': clamped,
        'matchReasons': reasons.toSet().toList(),
      },
    );
  }

  String? _coverUrl(Map<String, dynamic> unit, Map<String, dynamic> project) {
    final unitMedia = (unit['media'] as List? ?? const []).cast<Map>();
    final unitCover =
        unitMedia.where((m) => m['isCover'] == true).firstOrNull ??
        unitMedia.firstOrNull;
    if (unitCover != null) return unitCover['url'] as String?;
    final gallery = (project['gallery'] as List? ?? const []).cast<Map>();
    final projectCover =
        gallery.where((m) => m['isCover'] == true).firstOrNull ??
        gallery.firstOrNull;
    return projectCover?['url'] as String?;
  }
}

class _ScoredResult {
  _ScoredResult({required this.score, required this.json});
  final int score;
  final Map<String, dynamic> json;
  Map<String, dynamic> toJson() => json;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Free-text -> [SearchConstraints]. Numbers, ranges and directions are read
/// by regex; every remaining word goes through `search_dictionary.dart`
/// (exact, declension, transliteration, keyboard layout, prefix, then
/// Damerau-Levenshtein). A word that survives all of that is reported — never
/// ignored, never guessed at silently.
class SmartSearchParser {
  /// Backwards-compatible entry point: the constraints only.
  static SearchConstraints parse(
    String rawQuery, {
    CatalogueVocabulary? catalogue,
  }) => analyze(rawQuery, catalogue: catalogue).constraints;

  static ParsedQuery analyze(
    String rawQuery, {
    CatalogueVocabulary? catalogue,
  }) {
    final c = SearchConstraints();
    // Whitespace is collapsed to match how [AliasIndex] normalizes its
    // aliases — a double space must not break phrase matching. The collapse
    // happens *before* the consumed mask is created, so every span below is
    // an index into this string (not into `rawQuery`).
    final lower = normalizeSearchText(rawQuery, collapseWhitespace: true);
    final consumed = List<bool>.filled(lower.length, false);
    final suggestions = <SearchSuggestionCandidate>[];
    final autocorrections = <SearchAutocorrection>[];
    final softenedAmenities = <String>[];

    void consumeRange(int start, int end) {
      for (var i = start; i < end && i < consumed.length; i++) {
        consumed[i] = true;
      }
    }

    void consume(Match m) => consumeRange(m.start, m.end);

    /// True when every digit inside the match was already claimed by an
    /// earlier pass — `2 комнатная` must not also become a $2 budget.
    bool digitsAlreadyConsumed(Match m) {
      var sawDigit = false;
      for (var i = m.start; i < m.end && i < consumed.length; i++) {
        final code = lower.codeUnitAt(i);
        if (code >= 0x30 && code <= 0x39) {
          sawDigit = true;
          if (!consumed[i]) return false;
        }
      }
      return sawDigit;
    }

    void addRooms(Iterable<int> values) {
      c.rooms = {...(c.rooms ?? {}), ...values};
    }

    void applyTerm(SearchTerm term, String sourceToken) {
      switch (term.kind) {
        case SearchTermKind.rooms:
          addRooms([term.value as int]);
        case SearchTermKind.district:
          final value = term.value as String;
          if (value == kWholeCityDistrict) return;
          c.district ??= value == kCentralDistrict
              ? (catalogue?.centralDistrict ?? _fallbackCentralDistrict)
              : value;
        case SearchTermKind.dealType:
          c.dealType ??= term.value as String;
        case SearchTermKind.unitKind:
          c.unitKind ??= term.value as String;
        case SearchTermKind.status:
          switch (term.value as String) {
            case 'offplan':
              c.isOffplan ??= true;
              c.projectStatus ??= 'under_construction';
            case 'ready':
              c.isOffplan ??= false;
              c.projectStatus ??= 'ready';
            case 'available':
              c.availableOnly = true;
          }
        case SearchTermKind.price:
          c.pricePreference ??= term.value as String;
        case SearchTermKind.area:
          c.areaPreference ??= term.value as String;
        case SearchTermKind.floor:
          switch (term.value as String) {
            case 'notFirst':
              c.notFirstFloor = true;
            case 'notLast':
              c.notLastFloor = true;
            default:
              c.floorPreference ??= term.value as String;
          }
        case SearchTermKind.amenity:
          final key = term.value as String;
          if (c.excludedAmenities.contains(key)) return;
          if (catalogue == null || catalogue.hasAmenity(key)) {
            c.amenities.add(key);
          } else if (!c.softAmenities.contains(key)) {
            // Nothing published offers this — filtering on it would return an
            // empty list and blame the user for asking.
            c.softAmenities.add(key);
            softenedAmenities.add(key);
            suggestions.add(
              SearchSuggestionCandidate(
                term: sourceToken,
                target: term,
                confidence: 1,
                reason: SuggestionReason.softenedAmenity,
              ),
            );
          }
        case SearchTermKind.developer:
          c.developerName ??= term.value as String;
        case SearchTermKind.project:
          c.projectName ??= term.value as String;
        case SearchTermKind.noise:
          break;
      }
    }

    // Tokens are positions in `lower`; computed once, shared by the negation
    // pass, the n-gram retry and the token-by-token pass.
    final wordRe = RegExp(r"[\p{L}\d\u02BC\u2019']+", unicode: true);
    final tokens = wordRe.allMatches(lower).toList();

    // --- negation: «без X» / «не X» / «without X» / «no X» / uz «Xsiz»,
    // plus the lexicalized forms in kNegatedAmenityPhrases. Runs before every
    // positive pass so «ремонт» in «без ремонта» cannot be claimed as a
    // positive amenity. Only amenities are negatable: anything else keeps
    // its current (unrecognized) behaviour. -----------------------------------
    void exclude(String amenityKey) {
      c.excludedAmenities.add(amenityKey);
      c.amenities.remove(amenityKey);
    }

    // Lexicalized collocations first, longest first, so «черновая отделка»
    // wins over the bare «черновая».
    final lexicalNegations = kNegatedAmenityPhrases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final phrase in lexicalNegations) {
      var from = 0;
      while (from < lower.length) {
        final at = lower.indexOf(phrase, from);
        if (at < 0) break;
        final end = at + phrase.length;
        if (!_anyConsumed(consumed, at, end) &&
            _isBoundary(lower, at - 1) &&
            _isBoundary(lower, end)) {
          exclude(kNegatedAmenityPhrases[phrase]!);
          consumeRange(at, end);
        }
        from = end;
      }
    }

    /// The amenity a token resolves to (exact/inflection/translit/fuzzy),
    /// or null when it is anything else. Confidence-gated exactly like the
    /// positive token pass.
    String? amenityFor(String token) {
      final match = matchSearchToken(token);
      if (match == null || !match.isConfident) return null;
      if (match.term.kind != SearchTermKind.amenity) return null;
      return match.term.value as String;
    }

    for (var i = 0; i < tokens.length; i++) {
      final m = tokens[i];
      if (_anyConsumed(consumed, m.start, m.end)) continue;
      final word = m.group(0)!;

      // uz privative suffix: «mebelsiz», «liftsiz», «remontsiz».
      if (word.endsWith('siz') && word.length >= 6) {
        final amenity = amenityFor(word.substring(0, word.length - 3));
        if (amenity != null) {
          exclude(amenity);
          consume(m);
          continue;
        }
      }

      // uz postfix negation: «mebel yo'q», «lift kerak emas».
      if (i + 1 < tokens.length) {
        final next = tokens[i + 1].group(0)!;
        final isPostfix =
            next == "yo'q" ||
            (next == 'kerak' &&
                i + 2 < tokens.length &&
                tokens[i + 2].group(0)! == 'emas');
        if (isPostfix) {
          final amenity = amenityFor(word);
          if (amenity != null) {
            final endToken = next == "yo'q" ? tokens[i + 1] : tokens[i + 2];
            exclude(amenity);
            consumeRange(m.start, endToken.end);
            continue;
          }
        }
      }

      if (!kNegationCues.contains(word) || i + 1 == tokens.length) continue;
      final xStart = tokens[i + 1].start;

      // X as a known amenity phrase («без детской площадки» won't inflect,
      // but «without underground parking» matches verbatim).
      SearchPhraseAlias? phraseHit;
      for (final phrase in kSearchIndex.phrases) {
        if (phrase.term.kind != SearchTermKind.amenity) continue;
        if (!lower.startsWith(phrase.alias, xStart)) continue;
        if (!_isBoundary(lower, xStart + phrase.alias.length)) continue;
        if (_anyConsumed(consumed, xStart, xStart + phrase.alias.length)) {
          continue;
        }
        phraseHit = phrase;
        break; // phrases are sorted longest-first
      }
      if (phraseHit != null) {
        exclude(phraseHit.term.value as String);
        consumeRange(m.start, xStart + phraseHit.alias.length);
        continue;
      }

      // X as a single token («без ремонта», «no furniture»).
      final amenity = amenityFor(tokens[i + 1].group(0)!);
      if (amenity != null) {
        exclude(amenity);
        consumeRange(m.start, tokens[i + 1].end);
      }
    }

    // --- studio (before numeric rooms so "studio" isn't left dangling) ----
    final studioRe = RegExp(
      "studio|студи$_wordTail|studiya$_wordTail",
      caseSensitive: false,
    );
    for (final m in studioRe.allMatches(lower)) {
      addRooms(const [0]);
      consume(m);
    }

    // --- rooms ---------------------------------------------------------------
    const roomNoun =
        '(?:комн$_wordTail|ком\\.|xona$_wordTail|honali|room$_wordTail|'
        'bedroom$_wordTail)';
    final roomsRangeRe = RegExp(
      r'(?<!\d)([1-5])\s*[-–]\s*([1-5])\s*' + roomNoun,
      caseSensitive: false,
    );
    for (final m in roomsRangeRe.allMatches(lower)) {
      final from = int.parse(m.group(1)!);
      final to = int.parse(m.group(2)!);
      addRooms([for (var n = from; n <= to; n++) n]);
      consume(m);
    }
    final roomsEitherRe = RegExp(
      r'(?<!\d)([1-5])\s*(?:или|or|yoki)\s*([1-5])\s*' + roomNoun,
      caseSensitive: false,
    );
    for (final m in roomsEitherRe.allMatches(lower)) {
      addRooms([int.parse(m.group(1)!), int.parse(m.group(2)!)]);
      consume(m);
    }
    final roomsAtLeastRe = RegExp(
      r'(?:от|from|минимум|min|kamida)\s*([1-5])\s*(?:\+|' + roomNoun + ')',
      caseSensitive: false,
    );
    for (final m in roomsAtLeastRe.allMatches(lower)) {
      final from = int.parse(m.group(1)!);
      addRooms([for (var n = from; n <= 5; n++) n]);
      consume(m);
    }
    final roomsPlusRe = RegExp(r'(?<!\d)([1-5])\s*\+', caseSensitive: false);
    for (final m in roomsPlusRe.allMatches(lower)) {
      final from = int.parse(m.group(1)!);
      addRooms([for (var n = from; n <= 5; n++) n]);
      consume(m);
    }
    // `2-х комнатная` / `2х комнатная` are as common as `2 комнатная`, so the
    // genitive infix between the digit and the noun is optional too.
    const roomInfix = r'\s*[-–]?\s*(?:х|x)?\s*[-–]?\s*';
    final roomsRe = RegExp(
      r'(?<!\d)(\d)' + roomInfix + roomNoun + r'|(?<!\d)(\d)\s*[-–]?\s*br\b',
      caseSensitive: false,
    );
    for (final m in roomsRe.allMatches(lower)) {
      final n = int.tryParse(m.group(1) ?? m.group(2) ?? '');
      if (n != null) addRooms([n]);
      consume(m);
    }

    // --- floor constraints (checked before price so "выше/ниже" never gets
    // reinterpreted as a price direction word) --------------------------------
    const floorNoun = '(?:этаж$_wordTail|qavat$_wordTail|floor$_wordTail)';
    // A refusal is just as often phrased after the noun («первый этаж не
    // предлагать», «кроме первого») as before it, and those readings must not
    // fall through to the exact-floor pass as "floor 1".
    const floorRefusal =
        '(?:не\\s+(?:предлага$_wordTail|нужен|нужна|нужно|надо|'
        'интересует|рассматрива$_wordTail|подход$_wordTail|годится)|'
        'исключ$_wordTail)';
    final notFirstRe = RegExp(
      'не перв$_wordTail(?:\\s+этаж$_wordTail)?|'
      'перв$_wordTail\\s+этаж$_wordTail\\s+$floorRefusal|'
      'кроме\\s+перв$_wordTail(?:\\s+этаж$_wordTail)?|'
      'без\\s+перв$_wordTail\\s+этаж$_wordTail|'
      'birinchi qavat emas|birinchi qavat kerak emas|'
      'not (?:the )?first floor|no (?:first|ground) floor',
      caseSensitive: false,
    );
    if (notFirstRe.hasMatch(lower)) {
      c.notFirstFloor = true;
      consume(notFirstRe.firstMatch(lower)!);
    }
    final notLastRe = RegExp(
      'не последн$_wordTail(?:\\s+этаж$_wordTail)?|'
      'последн$_wordTail\\s+этаж$_wordTail\\s+$floorRefusal|'
      'кроме\\s+последн$_wordTail(?:\\s+этаж$_wordTail)?|'
      'без\\s+последн$_wordTail\\s+этаж$_wordTail|'
      'oxirgi qavat emas|oxirgi qavat kerak emas|'
      'not (?:the )?last floor|no (?:last|top) floor',
      caseSensitive: false,
    );
    if (notLastRe.hasMatch(lower)) {
      c.notLastFloor = true;
      consume(notLastRe.firstMatch(lower)!);
    }
    final floorRangeRe = RegExp(
      r'(?:с|from)\s*(\d{1,2})\s*(?:по|до|to|-)\s*(\d{1,2})\s*' +
          floorNoun +
          r'|(?<!\d)(\d{1,2})\s*[-–]\s*(\d{1,2})\s*' +
          floorNoun,
      caseSensitive: false,
    );
    for (final m in floorRangeRe.allMatches(lower)) {
      final from = int.tryParse(m.group(1) ?? m.group(3) ?? '');
      final to = int.tryParse(m.group(2) ?? m.group(4) ?? '');
      if (from != null) c.floorMin = from;
      if (to != null) c.floorMax = to;
      consume(m);
    }
    // «выше»/«ниже» belong to the floor only when the number could actually be
    // one: at most two digits and no money word behind it, otherwise «не выше
    // 100 тысяч» would leave the budget as floor 101. A leading «не» flips the
    // direction — «не выше 9 этажа» is a ceiling, not a floor.
    // A grouped amount («50 000») is money however small each group is, so the
    // lookahead rejects any further digits, not just a longer first group.
    const floorNumber = r'(\d{1,2})(?![\d\s]*\d)';
    const notMoney =
        "(?!\\s*(?:тыс|млн|млрд|миллион|миллиард|лям|сум|so'm|som|"
        r'доллар|бакс|dollar|usd|uzs|k(?![a-z])|к(?![а-я])|\$))';
    final notAboveRe = RegExp(
      'не\\s+выше\\s*$floorNumber$notMoney',
      caseSensitive: false,
    );
    for (final m in notAboveRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null) c.floorMax = n;
      consume(m);
    }
    final aboveRe = RegExp(
      '(?<!не )(?:выше|higher than|above)\\s*$floorNumber$notMoney'
      r'|(\d{1,2})\s*(?:dan|дан)\s*(?:yuqori|юкори)',
      caseSensitive: false,
    );
    for (final m in aboveRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final n = int.tryParse(m.group(1) ?? m.group(2) ?? '');
      if (n != null) c.floorMin = n + 1;
      consume(m);
    }
    final belowRe = RegExp(
      '(?:ниже|lower than|below)\\s*$floorNumber$notMoney'
      r'|(\d{1,2})\s*(?:dan|дан)\s*(?:past|паст)',
      caseSensitive: false,
    );
    for (final m in belowRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final n = int.tryParse(m.group(1) ?? m.group(2) ?? '');
      if (n != null) c.floorMax = n - 1;
      consume(m);
    }
    // «не на 2 этаже» / «не 2 этаж» / «кроме 5 этажа» / «без 5 этажа»: a
    // specific floor number refused — as opposed to notFirst/notLast above,
    // which refuse by position, not by number. Runs before exactFloorRe so
    // the number is not re-read as a positive floor constraint (which is
    // exactly the inverse of what the query asked for).
    const floorOrdinalTail = r'(?:-?[йяое][а-я]{0,2})?';
    final notExactFloorRe = RegExp(
      r'не\s+на\s*(\d{1,2})\s*' + floorOrdinalTail + r'\s*' + floorNoun +
          r'|не\s*(\d{1,2})\s*' + floorOrdinalTail + r'\s*' + floorNoun +
          r'|кроме\s*(\d{1,2})\s*' + floorOrdinalTail + r'\s*' + floorNoun +
          r'|без\s*(\d{1,2})\s*' + floorOrdinalTail + r'\s*' + floorNoun +
          r'|(\d{1,2})\s*' + floorOrdinalTail + r'\s*' + floorNoun +
          r'\s+' + floorRefusal +
          r'|(\d{1,2})\s*-?\s*qavat(?:da)?\s+emas' +
          r'|not\s+(?:on\s+)?floor\s*(\d{1,2})|no\s+floor\s*(\d{1,2})',
      caseSensitive: false,
    );
    for (final m in notExactFloorRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      String? group;
      for (var i = 1; i <= m.groupCount; i++) {
        group = m.group(i);
        if (group != null) break;
      }
      final n = int.tryParse(group ?? '');
      if (n != null) {
        (c.excludeFloors ??= <int>{}).add(n);
      }
      consume(m);
    }
    final exactFloorRe = RegExp(
      r'(?<!\d)(\d{1,2})\s*(?:-?[йяое][а-я]{0,2})?\s*' +
          floorNoun +
          r'|' +
          floorNoun +
          r'\s*(\d{1,2})(?!\d)',
      caseSensitive: false,
    );
    for (final m in exactFloorRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final n = int.tryParse(m.group(1) ?? m.group(2) ?? '');
      if (n != null) {
        c.floorMin = n;
        c.floorMax = n;
      }
      consume(m);
    }

    // --- area ------------------------------------------------------------
    const areaNoun =
        '(?:м2|м²|кв\\.?\\s*м$_wordTail|квадрат$_wordTail|sqm|m2|m²|'
        'kv\\.?\\s*m$_wordTail|kvadrat$_wordTail)';
    // «площадь от 60», «метраж до 90», «maydoni 85»: naming the field up front
    // makes the unit optional. Runs before the unit-driven passes so the cue
    // word is consumed with its number instead of being reported as unknown,
    // and before the budget pass so a bare «60» is not read as a $60 cap.
    final areaCueRe = RegExp(
      '(?:площад$_wordTail|метраж$_wordTail|квадратур$_wordTail|'
              'maydon$_wordTail|area)\\s*'
              '(от|до|from|up to|минимум|максимум|не менее|не более)?\\s*'
              r'(\d+(?:[.,]\d+)?)\s*(?:' +
          areaNoun +
          ')?',
      caseSensitive: false,
    );
    for (final m in areaCueRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final n = double.tryParse((m.group(2) ?? '').replaceAll(',', '.'));
      if (n == null) continue;
      final direction = m.group(1) ?? '';
      final isCeiling =
          direction.contains('до') ||
          direction.contains('up to') ||
          direction.contains('максимум') ||
          direction.contains('не более');
      if (isCeiling) {
        c.areaMax = n;
      } else {
        c.areaMin = n;
      }
      consume(m);
    }
    final areaRangeRe = RegExp(
      r'(?:от|from)\s*(\d+(?:[.,]\d+)?)\s*(?:до|to|-|–)\s*(\d+(?:[.,]\d+)?)\s*' +
          areaNoun,
      caseSensitive: false,
    );
    for (final m in areaRangeRe.allMatches(lower)) {
      c.areaMin = double.tryParse((m.group(1) ?? '').replaceAll(',', '.'));
      c.areaMax = double.tryParse((m.group(2) ?? '').replaceAll(',', '.'));
      consume(m);
    }
    final areaRe = RegExp(
      r'(от|до|from|up to)?\s*(\d+(?:[.,]\d+)?)\s*' + areaNoun,
      caseSensitive: false,
    );
    for (final m in areaRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final n = double.tryParse((m.group(2) ?? '').replaceAll(',', '.'));
      if (n == null) continue;
      final direction = (m.group(1) ?? '').toLowerCase();
      if (direction.contains('до') || direction.contains('up to')) {
        c.areaMax = n;
      } else {
        c.areaMin = n;
      }
      consume(m);
    }

    // --- "2к" / "3-к" -------------------------------------------------------
    // Only when no budget word is in front of it: "до 5 к" is five thousand,
    // "5к квартира" is five rooms.
    final roomsShortRe = RegExp(
      r'(?<!\d)([1-5])\s*[-–]?\s*к(?![а-яa-z])',
      caseSensitive: false,
    );
    final budgetLeadIn = RegExp(
      '(?:до|от|дороже|дешевле|бюджет$_wordTail|макс$_wordTail|мин$_wordTail|'
      r'up to|from|under|over|max|min|gacha)\s*$',
      caseSensitive: false,
    );
    for (final m in roomsShortRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final prefix = lower.substring(m.start < 12 ? 0 : m.start - 12, m.start);
      if (budgetLeadIn.hasMatch(prefix)) continue;
      addRooms([int.parse(m.group(1)!)]);
      consume(m);
    }

    // --- price ---------------------------------------------------------------
    const priceMagnitude =
        '(k(?![а-яa-z])|к(?![а-яa-z])|тыс$_wordTail|ming|mln|млн$_wordTail|'
        'million$_wordTail|миллион$_wordTail|лям$_wordTail|mlrd|млрд$_wordTail|'
        'миллиард$_wordTail|milliard$_wordTail)?';
    const priceCurrency =
        '(\\\$|usd|доллар$_wordTail|бакс$_wordTail|dollar$_wordTail|'
        "so'?m$_wordTail|сум$_wordTail|сумм$_wordTail|uzs)?";
    // `не` flips a direction word, so the negated forms are claimed by the
    // ceiling list and the bare comparatives refuse to match after it —
    // otherwise «не дороже 80 тысяч» reads as a floor of $80 000.
    const priceMinWords =
        r'от|начиная от|(?<!не )дороже|свыше|(?<!не )больше|(?<!не )выше|'
        'минимум|мин|from|above|over|more than|min';
    const priceMaxWords =
        'до|не дороже|не больше|не более|не выше|не превыша$_wordTail|'
        'дешевле|в пределах|бюджет$_wordTail|максимум|макс|'
        'up to|under|below|max|no more than|not more than';
    final priceRangeRe = RegExp(
      r'(?:от|между|from|between)?\s*(\d[\d\s.,]*)\s*(?:до|до\s|[-–]|to|и|and)\s*(\d[\d\s.,]*)\s*' +
          priceMagnitude +
          r'\s*' +
          priceCurrency,
      caseSensitive: false,
    );
    for (final m in priceRangeRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final magnitude = (m.group(3) ?? '').toLowerCase();
      final min = _amount(m.group(1), magnitude);
      final max = _amount(m.group(2), magnitude);
      if (min == null || max == null) continue;
      c.priceMin = min;
      c.priceMax = max;
      c.currency = _currencyFor(m.group(4), max);
      consume(m);
    }
    final priceRe = RegExp(
      '($priceMinWords|$priceMaxWords|gacha|dan boshlab)?'
      r'\s*(\d[\d\s.,]*)\s*'
      '$priceMagnitude'
      r'\s*'
      '$priceCurrency'
      r'\s*(gacha|dan boshlab|dan oshmagan|и выше|и больше)?',
      caseSensitive: false,
    );
    final minDirectionRe = RegExp(
      '$priceMinWords|dan boshlab',
      caseSensitive: false,
    );
    for (final m in priceRe.allMatches(lower)) {
      if (digitsAlreadyConsumed(m)) continue;
      final magnitudeWord = (m.group(3) ?? '').toLowerCase();
      final currencyWord = m.group(4) ?? '';
      final direction = '${m.group(1) ?? ''} ${m.group(5) ?? ''}'.trim();
      final magnitude = _amount(m.group(2), magnitudeWord);
      if (magnitude == null) continue;
      // A bare number with no direction word ("до"/"от"...), no currency and
      // no magnitude suffix ("к"/"тыс"/"млн"...) carries no price signal at
      // all — "офис на 5", a floor count, a room count that slipped past
      // the rooms pass above. Only a four-digit-and-up bare number is
      // unambiguous enough in a real-estate query to read as a budget
      // without an explicit cue; anything smaller is left unconsumed so it
      // can surface as `unrecognized` instead of a fabricated $5 cap.
      final hasSignal =
          direction.isNotEmpty ||
          magnitudeWord.isNotEmpty ||
          currencyWord.isNotEmpty;
      if (!hasSignal && magnitude < 1000) continue;
      c.currency = _currencyFor(currencyWord, magnitude);
      if (direction.isNotEmpty && minDirectionRe.hasMatch(direction)) {
        c.priceMin = magnitude;
      } else {
        c.priceMax = magnitude;
      }
      consume(m);
    }

    // --- dictionary: multi-word phrases first, longest first ----------------
    void applyPhrases(AliasIndex index) {
      for (final phrase in index.phrases) {
        var from = 0;
        while (from < lower.length) {
          final at = lower.indexOf(phrase.alias, from);
          if (at < 0) break;
          final end = at + phrase.alias.length;
          final free = !_anyConsumed(consumed, at, end);
          if (free && _isBoundary(lower, at - 1) && _isBoundary(lower, end)) {
            applyTerm(phrase.term, phrase.alias);
            consumeRange(at, end);
          }
          from = end;
        }
      }
    }

    applyPhrases(kSearchIndex);
    if (catalogue != null) applyPhrases(catalogue.index);

    // --- n-gram retry: runs of adjacent unconsumed tokens vs the phrase
    // index, with per-token inflection tolerance and conservative fuzzy.
    // This is what lets «в Мирзо Улугбеке» / «янги хаёте» / «мирзо улугбик»
    // land on the district instead of dropping half the phrase into
    // `unrecognized`. Runs BEFORE the token pass so «улугбеке» cannot be
    // claimed alone while «мирзо» is orphaned. ---------------------------------
    final indexes = <AliasIndex>[
      kSearchIndex,
      if (catalogue != null) catalogue.index,
    ];
    bool onlySpacesBetween(int endA, int startB) =>
        lower.substring(endA, startB).trim().isEmpty;

    for (var i = 0; i < tokens.length;) {
      var advancedBy = 0;
      for (final size in const [3, 2]) {
        if (i + size > tokens.length) continue;
        var windowOk = true;
        for (var j = i; j < i + size; j++) {
          if (_anyConsumed(consumed, tokens[j].start, tokens[j].end) ||
              (j > i &&
                  !onlySpacesBetween(tokens[j - 1].end, tokens[j].start))) {
            windowOk = false;
            break;
          }
        }
        if (!windowOk) continue;
        final words = [for (var j = i; j < i + size; j++) tokens[j].group(0)!];
        if (words.every(kSearchStopwords.contains)) continue;
        final hit = _matchTokenWindow(words, indexes);
        if (hit == null) continue;
        applyTerm(hit.term, hit.alias);
        consumeRange(tokens[i].start, tokens[i + size - 1].end);
        if (hit.distance > 0) {
          autocorrections.add(SearchAutocorrection(words.join(' '), hit.alias));
        }
        advancedBy = size;
        break;
      }
      i += advancedBy == 0 ? 1 : advancedBy;
    }

    // --- dictionary: token by token -----------------------------------------
    final suggested = <String>{};
    for (final m in tokens) {
      if (_anyConsumed(consumed, m.start, m.end)) continue;
      final token = m.group(0)!;
      if (kSearchStopwords.contains(token)) {
        consume(m);
        continue;
      }
      final match = matchSearchToken(token, catalogue: catalogue?.index);
      if (match == null) continue;
      if (match.isConfident) {
        applyTerm(match.term, token);
        consume(m);
        if (match.isAutocorrection && match.alias != token) {
          autocorrections.add(SearchAutocorrection(token, match.alias));
        }
      } else if (token.length >= 3 && match.term.kind != SearchTermKind.noise) {
        suggested.add(token);
        suggestions.add(
          SearchSuggestionCandidate(
            term: token,
            target: match.term,
            confidence: match.confidence,
            reason: SuggestionReason.unresolved,
          ),
        );
      }
    }

    // --- leftovers: unknown words and the "did you mean" bookkeeping --------
    final unrecognized = <String>[];
    final meaningful = <String>[];
    for (final m in tokens) {
      final word = m.group(0)!;
      if (word.length < 3 || kSearchStopwords.contains(word)) continue;
      if (!meaningful.contains(word)) meaningful.add(word);
      if (_anyConsumed(consumed, m.start, m.end)) continue;
      if (suggested.contains(word)) continue;
      if (!unrecognized.contains(word)) unrecognized.add(word);
    }
    c.unrecognized = unrecognized;

    return ParsedQuery(
      constraints: c,
      suggestions: suggestions,
      autocorrections: autocorrections,
      meaningfulTokens: meaningful,
      softenedAmenities: softenedAmenities,
    );
  }

  /// Matches a window of 2–3 adjacent unconsumed tokens against every
  /// space-joined phrase alias with the same token count. Per token: exact,
  /// inflection (the alias token is a prefix and at most four characters were
  /// appended — «улугбеке», «hayotda»), or Damerau-Levenshtein within the
  /// same length-scaled budget the single-token matcher uses. The combined
  /// confidence is gated at the parser's usual 0.9 (`isConfident`) so a
  /// two-edit guess never silently becomes a constraint.
  static _WindowMatch? _matchTokenWindow(
    List<String> words,
    List<AliasIndex> indexes,
  ) {
    _WindowMatch? best;
    for (final index in indexes) {
      for (final phrase in index.phrases) {
        final aliasTokens = phrase.alias.split(' ');
        if (aliasTokens.length != words.length) continue;
        var distance = 0;
        var inflected = false;
        var ok = true;
        for (var i = 0; i < aliasTokens.length; i++) {
          final wanted = aliasTokens[i];
          final got = words[i];
          if (got == wanted) continue;
          if (wanted.length >= 4 &&
              got.length > wanted.length &&
              got.length - wanted.length <= 4 &&
              got.startsWith(wanted)) {
            inflected = true;
            continue;
          }
          final budget = fuzzyThresholdFor(wanted.length);
          final d = damerauLevenshtein(got, wanted);
          if (budget == 0 || d > budget) {
            ok = false;
            break;
          }
          distance += d;
        }
        if (!ok) continue;
        final confidence = distance == 0
            ? (inflected ? 0.98 : 1.0)
            : fuzzyConfidence(distance, phrase.alias.length);
        if (confidence < 0.9) continue;
        if (best == null ||
            confidence > best.confidence ||
            (confidence == best.confidence &&
                phrase.alias.length > best.alias.length)) {
          best = _WindowMatch(
            term: phrase.term,
            alias: phrase.alias,
            confidence: confidence,
            distance: distance,
          );
        }
      }
    }
    return best;
  }

  static double? _amount(String? raw, String magnitude) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'[\s,]'), '')
        .replaceAll(RegExp(r'\.(?=\d{3}\b)'), '');
    final base = double.tryParse(cleaned);
    if (base == null || base <= 0) return null;
    if (magnitude.startsWith('k') ||
        magnitude.startsWith('к') ||
        magnitude.startsWith('тыс') ||
        magnitude.startsWith('ming')) {
      return base * 1000;
    }
    // Checked before the million branch: «миллиард» also starts with «милли».
    if (magnitude.startsWith('mlrd') ||
        magnitude.startsWith('млрд') ||
        magnitude.startsWith('миллиард') ||
        magnitude.startsWith('milliard')) {
      return base * 1000000000;
    }
    if (magnitude.startsWith('mln') ||
        magnitude.startsWith('млн') ||
        magnitude.startsWith('million') ||
        magnitude.startsWith('миллион') ||
        magnitude.startsWith('лям')) {
      return base * 1000000;
    }
    return base;
  }

  /// A bare price this large is almost certainly already UZS even without an
  /// explicit currency word (a $500,000,000 flat is not realistic).
  static String _currencyFor(String? raw, double magnitude) {
    final currency = (raw ?? '').toLowerCase();
    final isUzs =
        currency.contains('sum') ||
        currency.contains("so'm") ||
        currency.contains('som') ||
        currency.contains('сум') ||
        currency.contains('uzs');
    return isUzs || magnitude >= 5000000 ? 'UZS' : 'USD';
  }
}

class _WindowMatch {
  const _WindowMatch({
    required this.term,
    required this.alias,
    required this.confidence,
    required this.distance,
  });

  final SearchTerm term;
  final String alias;
  final double confidence;
  final int distance;
}

bool _anyConsumed(List<bool> consumed, int start, int end) {
  for (var i = start; i < end && i < consumed.length; i++) {
    if (consumed[i]) return true;
  }
  return false;
}

final RegExp _wordChar = RegExp(r"[\p{L}\p{N}']", unicode: true);

bool _isBoundary(String text, int index) {
  if (index < 0 || index >= text.length) return true;
  return !_wordChar.hasMatch(text[index]);
}
