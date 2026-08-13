/// Inline completion behind `POST /v1/ai/search/suggest` — the ghost text the
/// b2c search field renders after the caret and accepts with Tab.
///
/// Deterministic and cheap on purpose: it is called on every keystroke (with
/// a client-side debounce), so there is no upstream call, no quota and no
/// catalogue traversal beyond counting available units per district.
library;

import '../store.dart';
import 'search_dictionary.dart';
import 'smart_search_engine.dart';

/// Ordering of the clause we guess next: the field that narrows the catalogue
/// most, and that a person naturally says first, wins.
const Map<SearchTermKind, double> _kindPriority = {
  SearchTermKind.district: 5,
  SearchTermKind.rooms: 4,
  SearchTermKind.price: 3,
  SearchTermKind.dealType: 2,
  SearchTermKind.amenity: 1.5,
  SearchTermKind.floor: 1.2,
  SearchTermKind.status: 1,
  SearchTermKind.area: 0.8,
  SearchTermKind.unitKind: 0.6,
  SearchTermKind.project: 0.5,
  SearchTermKind.developer: 0,
};

/// Proper names: the only words the field keeps completing after they already
/// resolve, because a short form of a name is still a half-typed name.
const Set<SearchTermKind> _nameKinds = {
  SearchTermKind.district,
  SearchTermKind.project,
  SearchTermKind.developer,
};

/// What a dangling preposition asks for: «до » a price, «с » an amenity,
/// «рядом » a proximity amenity, «в » a place. [_DanglingRoute.none] means
/// the last word is a whole word, not a clause opener.
enum _DanglingRoute { none, place, price, amenity, proximity }

final RegExp _cyrillic = RegExp(r'[\u0400-\u04FF]');

/// Words that occur in only one of the two Latin-script languages the search
/// speaks. Forms shared by both (`metro`, `parking`, `NestOne`) are left out:
/// they carry no signal.
const Set<String> _uzMarkers = {
  'xonadon',
  'xonali',
  'xona',
  'kvartira',
  'uy',
  'uyjoy',
  'ijara',
  'ijaraga',
  'sotib',
  'olish',
  'sotiladi',
  'ofis',
  'ofislar',
  'qavat',
  'qavatda',
  'yaqinida',
  'yaqin',
  'bilan',
  'gacha',
  'yangi',
  'bino',
  'tayyor',
  'arzon',
  'kerak',
  'izlayapman',
  'hovli',
  'maktab',
  "bog'",
  "bog'cha",
  'avtoturargoh',
  'mebel',
  "ta'mirlangan",
  'jihozlangan',
  'studiya',
  'manzara',
  'keng',
  'kichik',
  'markazda',
  'markaz',
  "o'rta",
  'yuqori',
  'past',
  'birinchi',
  'oxirgi',
  'emas',
  'tijorat',
  'hashamatli',
  'mavjud',
};
const Set<String> _enMarkers = {
  'apartment',
  'apartments',
  'flat',
  'house',
  'office',
  'offices',
  'studio',
  'bedroom',
  'bedrooms',
  'room',
  'rooms',
  'floor',
  'near',
  'nearby',
  'with',
  'without',
  'for',
  'rent',
  'sale',
  'buy',
  'ready',
  'new',
  'build',
  'up',
  'under',
  'below',
  'the',
  'and',
  'looking',
  'need',
  'want',
  'cheap',
  'affordable',
  'spacious',
  'compact',
  'view',
  'close',
  'downtown',
  'centre',
  'center',
  'renovated',
  'furnished',
  'commercial',
  'available',
};

/// The completion is glued onto the words the user already typed, so it has to
/// be phrased in the language they are typing in — an Uzbek interface must not
/// turn «квартира с » into «квартира с avtoturargoh bilan». The interface
/// language only decides when the query itself carries no signal.
String _phraseLanguage(String query, String uiLanguage) {
  if (_cyrillic.hasMatch(query)) return 'ru';
  var uz = 0;
  var en = 0;
  for (final word in query.split(RegExp(r'\s+'))) {
    final token = normalizeSearchToken(word);
    if (token.isEmpty) continue;
    if (_uzMarkers.contains(token)) uz++;
    if (_enMarkers.contains(token)) en++;
  }
  if (uz > en) return 'uz';
  if (en > uz) return 'en';
  return uiLanguage;
}

class _Candidate {
  const _Candidate({
    required this.tail,
    required this.kind,
    required this.score,
    required this.rank,
  });

  /// Appended to the query verbatim; may start with a space.
  final String tail;
  final SearchTermKind kind;
  final double score;

  /// Score plus the kind priority — ordering only, never sent to the client.
  final double rank;
}

class SmartSearchSuggester {
  /// Returns the exact response `data` documented above
  /// `POST /v1/ai/search/suggest`.
  Map<String, dynamic> suggest(
    Store store, {
    required String query,
    required String language,
    int limit = 6,
  }) {
    final trimmedRight = query.trimRight();
    if (trimmedRight.trim().length < 3) return _empty();

    final phraseLanguage = _phraseLanguage(trimmedRight, language);
    final catalogue = CatalogueVocabulary.fromProjects(store.publishedProjects);
    // The parser is cheap and deterministic, so the CURRENT query is parsed
    // on every call: a clause that already parsed (rooms out of «двушка»,
    // unitKind out of «офис») is never suggested again.
    final constraints = SmartSearchParser.parse(
      trimmedRight,
      catalogue: catalogue,
    );
    final normalizedQuery = normalizeSearchText(
      trimmedRight,
      collapseWhitespace: true,
    );
    bool alreadyTyped(String text) => normalizedQuery.contains(
      normalizeSearchText(text, collapseWhitespace: true),
    );
    final untyped = _pool(
      phraseLanguage,
      catalogue,
    ).where((p) => !alreadyTyped(p.stem) && !alreadyTyped(p.clause)).toList();
    // Guessing the NEXT clause must skip what the query already pins down;
    // finishing the CURRENT word must not, because that word is usually the
    // very thing that pinned it down — «квартира в Чилан» resolves to
    // Chilanzar and would otherwise refuse to complete itself.
    final pool = untyped
        .where((p) => !_alreadyConstrained(p.kind, constraints))
        .toList();

    final words = trimmedRight
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final hasTrailingSpace = query.length > trimmedRight.length;
    final lastWord = words.isEmpty ? '' : words.last;
    final normalizedLast = normalizeSearchText(lastWord);

    // Mode 1 — the query stops mid-word: finish that word. A word that is
    // already a dictionary spelling of its own is normally left alone («офис»
    // is not a half-typed «офисное помещение»), but a name is: «Мираб» and
    // «Чилан» are short forms people expect the field to spell out for them.
    var dominant = true;
    var candidates = const <_Candidate>[];
    final resolvesOnItsOwn = kSearchIndex.termForAlias(normalizedLast);
    final completesAWord =
        !hasTrailingSpace &&
        normalizedLast.length >= 2 &&
        (resolvesOnItsOwn == null ||
            _nameKinds.contains(resolvesOnItsOwn.kind));
    if (completesAWord) {
      final matches =
          untyped
              .where(
                (p) =>
                    normalizeSearchText(p.stem).startsWith(normalizedLast) &&
                    p.stem.length > normalizedLast.length,
              )
              .toList()
            ..sort(_byScoreThenLength);
      dominant =
          matches.length == 1 ||
          (matches.length > 1 && matches[0].score > matches[1].score);
      candidates = matches
          .map(
            (p) => _Candidate(
              tail: _matchCase(
                lastWord,
                p.stem.substring(normalizedLast.length),
              ),
              kind: p.kind,
              score: p.score,
              rank: p.score + (_kindPriority[p.kind] ?? 0),
            ),
          )
          .toList();
    }

    // Mode 2 — the words that are in are whole, so guess the next clause
    // instead. This is the "после двух слов" behaviour, with one word enough
    // when it already carries a constraint: «двушка» or «офис» is as clear an
    // opening as two words are, and staying silent there reads as broken. A
    // single word the parser did not understand keeps its silence, so
    // gibberish is never dressed up with a district.
    final opensAClause =
        words.length >= 2 ||
        (words.length == 1 && constraints.constraintCount > 0);
    if (candidates.isEmpty && opensAClause) {
      final lead = hasTrailingSpace ? '' : ' ';
      final route = _danglingRoute(normalizedLast);
      final dangling = route != _DanglingRoute.none;
      candidates =
          pool
              .where((p) => _matchesRoute(p, route))
              .map(
                (p) => _Candidate(
                  tail: '$lead${dangling ? p.stem : p.clause}',
                  kind: p.kind,
                  score: p.score,
                  rank: p.score + (_kindPriority[p.kind] ?? 0),
                ),
              )
              .toList()
            ..sort((a, b) => b.rank.compareTo(a.rank));
      dominant = candidates.isNotEmpty;
    }

    if (candidates.isEmpty) return _empty();
    final safeLimit = limit < 1 ? 1 : (limit > 20 ? 20 : limit);
    final completion = dominant ? candidates.first.tail : null;
    return {
      'completion': completion,
      'completionFull': completion == null ? null : '$query$completion',
      'suggestions': candidates
          .take(safeLimit)
          .map(
            (c) => {
              'text': '$query${c.tail}',
              'tail': c.tail,
              'kind': c.kind.wireName,
              'score': double.parse(c.score.toStringAsFixed(2)),
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _empty() => {
    'completion': null,
    'completionFull': null,
    'suggestions': const [],
  };

  static int _byScoreThenLength(SuggestPhrase a, SuggestPhrase b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.stem.length.compareTo(b.stem.length);
  }

  /// The user's casing wins: an all-caps prefix keeps completing in caps.
  static String _matchCase(String typed, String tail) {
    if (typed.length > 1 && typed == typed.toUpperCase()) {
      return tail.toUpperCase();
    }
    return tail;
  }

  static _DanglingRoute _danglingRoute(String lastWord) {
    if (kPricePrepositions.contains(lastWord)) return _DanglingRoute.price;
    if (kAmenityPrepositions.contains(lastWord)) return _DanglingRoute.amenity;
    if (kProximityPrepositions.contains(lastWord)) {
      return _DanglingRoute.proximity;
    }
    if (kPlacePrepositions.contains(lastWord)) return _DanglingRoute.place;
    return _DanglingRoute.none;
  }

  static bool _matchesRoute(
    SuggestPhrase p,
    _DanglingRoute route,
  ) => switch (route) {
    _DanglingRoute.none => true,
    // After a dangling `в`/`in` only a place reads as Russian (or
    // English) — "в 2-комнатная" does not.
    _DanglingRoute.place =>
      p.kind == SearchTermKind.district ||
          p.kind == SearchTermKind.project ||
          p.kind == SearchTermKind.developer,
    _DanglingRoute.price => p.kind == SearchTermKind.price,
    _DanglingRoute.amenity => p.kind == SearchTermKind.amenity && !p.proximity,
    _DanglingRoute.proximity => p.kind == SearchTermKind.amenity && p.proximity,
  };

  bool _alreadyConstrained(SearchTermKind kind, SearchConstraints c) =>
      switch (kind) {
        SearchTermKind.district => c.district != null,
        // A commercial/parking query never gets room-count clauses — «офис на
        // 2 комнаты» is not a thing a person says.
        SearchTermKind.rooms =>
          (c.rooms != null && c.rooms!.isNotEmpty) ||
              c.unitKind == 'commercial' ||
              c.unitKind == 'parking',
        SearchTermKind.price =>
          c.priceMin != null || c.priceMax != null || c.pricePreference != null,
        SearchTermKind.dealType => c.dealType != null,
        SearchTermKind.status => c.projectStatus != null || c.isOffplan != null,
        SearchTermKind.amenity =>
          c.amenities.isNotEmpty ||
              c.softAmenities.isNotEmpty ||
              c.excludedAmenities.isNotEmpty,
        SearchTermKind.floor =>
          c.floorMin != null ||
              c.floorMax != null ||
              c.notFirstFloor == true ||
              c.notLastFloor == true ||
              (c.excludeFloors != null && c.excludeFloors!.isNotEmpty) ||
              c.floorPreference != null,
        SearchTermKind.area =>
          c.areaMin != null || c.areaMax != null || c.areaPreference != null,
        SearchTermKind.unitKind => c.unitKind != null,
        SearchTermKind.project => c.projectName != null,
        SearchTermKind.developer => c.developerName != null,
        _ => false,
      };

  /// Static phrasings plus everything that only the live catalogue knows:
  /// districts that actually have available units (best stocked first), real
  /// project names and real developer names.
  List<SuggestPhrase> _pool(String language, CatalogueVocabulary catalogue) {
    final phrases = <SuggestPhrase>[
      ...(kSuggestPhrases[language] ?? kSuggestPhrases['ru']!),
    ];

    final counts = catalogue.districtUnitCounts;
    final stocked =
        kSearchDistrictEntries
            .where((d) => (counts[d.canonical] ?? 0) > 0)
            .toList()
          ..sort(
            (a, b) =>
                (counts[b.canonical] ?? 0).compareTo(counts[a.canonical] ?? 0),
          );
    for (var i = 0; i < stocked.length; i++) {
      phrases.add(districtSuggestPhrase(stocked[i], language, 0.90 - i * 0.02));
    }
    if (catalogue.centralDistrict != null) {
      phrases.add(
        kCentreSuggestPhrase[language] ?? kCentreSuggestPhrase['ru']!,
      );
    }

    for (final name in catalogue.projectNames) {
      phrases.add(
        SuggestPhrase(
          kind: SearchTermKind.project,
          clause: name,
          stem: name,
          score: 0.60,
        ),
      );
    }
    for (final developer in catalogue.developerNames) {
      phrases.add(
        SuggestPhrase(
          kind: SearchTermKind.developer,
          clause: _developerClause(developer, language),
          stem: developer,
          score: 0.45,
        ),
      );
    }
    return phrases;
  }

  static String _developerClause(String developer, String language) =>
      switch (language) {
        'uz' => '$developer dan',
        'en' => 'by $developer',
        _ => 'от $developer',
      };
}
