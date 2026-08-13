/// Recognition vocabulary + fuzzy matching for the deterministic smart search
/// (plan Part 2). Split out of `smart_search_engine.dart` so that file stays
/// the parser/ranker while the word lists — which is what makes the search
/// feel like a real assistant rather than a keyword filter — stay readable on
/// their own.
///
/// Nothing here calls OpenAI or allocates per request: the alias index is
/// built once, lazily, and shared by `SmartSearchParser` and by the
/// completion engine behind `POST /v1/ai/search/suggest`.
library;

/// What a dictionary entry constrains. The wire names are the `kind` values
/// documented for `suggestions[]` above `POST /v1/ai/search` — `noise` is
/// internal (intent/filler words) and never leaves the server.
enum SearchTermKind {
  rooms('rooms'),
  district('district'),
  dealType('dealType'),
  unitKind('unitKind'),
  price('price'),
  area('area'),
  floor('floor'),
  amenity('amenity'),
  status('status'),
  developer('developer'),
  project('project'),
  noise('noise');

  const SearchTermKind(this.wireName);

  final String wireName;
}

/// One canonical concept plus every spelling a user might actually type for
/// it — Cyrillic ru, Latin and Cyrillic uz, en, colloquialisms, declensions,
/// abbreviations and the misspellings we see most often. Aliases are
/// normalized (see [normalizeSearchText]) when the index is built, so they can
/// be written here the way a human writes them.
class SearchTerm {
  const SearchTerm({
    required this.canonical,
    required this.kind,
    required this.aliases,
    this.value,
    this.labels = const {},
  });

  /// Stable internal id (`rooms:2`, `district:Chilanzar`), never sent to
  /// clients.
  final String canonical;
  final SearchTermKind kind;
  final List<String> aliases;

  /// Kind-specific payload the parser applies: room count (`int`), district
  /// name, `sale`/`rent`, amenity key, and so on.
  final Object? value;

  /// Human-readable replacement per language, used for the "did you mean"
  /// suggestions. Falls back to the first alias.
  final Map<String, String> labels;

  String labelFor(String language) =>
      labels[language] ?? labels['ru'] ?? aliases.first;
}

/// A district plus the surface forms the suggest endpoint needs: the ru
/// prepositional and uz locative cases are what a person actually types after
/// "в …" / "…da".
class SearchDistrict {
  const SearchDistrict(
    this.canonical, {
    required this.centrality,
    required this.nameRu,
    required this.nameUz,
    required this.locativeRu,
    required this.locativeUz,
    required this.aliases,
  });

  final String canonical;

  /// 1 = most central. Decides which seeded district `центр` / `markaz` /
  /// `downtown` resolves to.
  final int centrality;
  final String nameRu;
  final String nameUz;
  final String locativeRu;
  final String locativeUz;
  final List<String> aliases;
}

/// All 12 Tashkent districts with an alias list wide enough to survive the
/// spelling chaos of a bilingual city (Cyrillic uz, Latin uz, ru, and the
/// short forms people type in a hurry).
const List<SearchDistrict> kSearchDistrictEntries = [
  SearchDistrict(
    'Bektemir',
    centrality: 11,
    nameRu: 'Бектемир',
    nameUz: 'Bektemir',
    locativeRu: 'Бектемире',
    locativeUz: 'Bektemirda',
    aliases: [
      'бектемир',
      'бектемирский',
      'бектемирском',
      'бектимир',
      'бектемер',
      'bektemir',
      'bektimir',
      'bektemirskiy',
    ],
  ),
  SearchDistrict(
    'Chilanzar',
    centrality: 6,
    nameRu: 'Чиланзар',
    nameUz: 'Chilonzor',
    locativeRu: 'Чиланзаре',
    locativeUz: 'Chilonzorda',
    aliases: [
      'чиланзар',
      'чилонзор',
      'чиланзор',
      'чилонзар',
      'чиланзарский',
      'чиланзарском',
      'чилан',
      'чилон',
      'чилка',
      'chilanzar',
      'chilonzor',
      'chilanzor',
      'chilonzar',
      'chilan',
      'chilonz',
      'chilanzarskiy',
    ],
  ),
  SearchDistrict(
    'Mirabad',
    centrality: 1,
    nameRu: 'Мирабад',
    nameUz: 'Mirobod',
    locativeRu: 'Мирабаде',
    locativeUz: 'Mirobodda',
    aliases: [
      'мирабад',
      'миробод',
      'мирабат',
      'мирабод',
      'мирабадский',
      'мирабадском',
      'мираб',
      'mirabad',
      'mirobod',
      'mirabod',
      'mirab',
    ],
  ),
  SearchDistrict(
    'Mirzo Ulugbek',
    centrality: 4,
    nameRu: 'Мирзо Улугбек',
    nameUz: "Mirzo Ulug'bek",
    locativeRu: 'Мирзо Улугбеке',
    locativeUz: "Mirzo Ulug'bekda",
    aliases: [
      'мирзо улугбек',
      'мирзо улугбеке',
      'мирзо улугбека',
      'мирзо улугбеку',
      'мирзо-улугбек',
      'мирзоулугбек',
      'мирзо улугбекский',
      'мирзо улугбекском',
      'м.улугбек',
      'м улугбек',
      'улугбек',
      'улугбеке',
      'улугбека',
      'улугбекский',
      'улугбекском',
      'mirzo ulugbek',
      "mirzo ulug'bek",
      'mirzo ulugbekda',
      "mirzo ulug'bekda",
      'mirzo ulugbekka',
      'mirzo-ulugbek',
      'mirzoulugbek',
      'ulugbek',
      "ulug'bek",
      'ulugbekda',
      'ulugbekskiy',
    ],
  ),
  SearchDistrict(
    'Olmazor',
    centrality: 8,
    nameRu: 'Олмазор',
    nameUz: 'Olmazor',
    locativeRu: 'Олмазоре',
    locativeUz: 'Olmazorda',
    aliases: [
      'олмазор',
      'алмазар',
      'алмазор',
      'олмазар',
      'алмазарский',
      'олмазорский',
      'олмаз',
      'алмаз',
      'olmazor',
      'almazar',
      'almazor',
      'olmazar',
    ],
  ),
  SearchDistrict(
    'Sergeli',
    centrality: 10,
    nameRu: 'Сергели',
    nameUz: 'Sergeli',
    locativeRu: 'Сергели',
    locativeUz: 'Sergelida',
    aliases: [
      'сергели',
      'сергелий',
      'сергелях',
      'сергель',
      'сергел',
      'сергелийский',
      'сергелийском',
      'sergeli',
      'sergely',
      'sergeliy',
    ],
  ),
  SearchDistrict(
    'Shayxontohur',
    centrality: 2,
    nameRu: 'Шайхантахур',
    nameUz: 'Shayxontohur',
    locativeRu: 'Шайхантахуре',
    locativeUz: 'Shayxontohurda',
    aliases: [
      'шайхантахур',
      'шайхантаур',
      'шайхантохур',
      'шайхонтохур',
      'шайхантахурский',
      'шайхантахурском',
      'шайх',
      'себзар',
      'сибзар',
      'shayxontohur',
      'shayhontohur',
      'shaykhantakhur',
      'shayxontoxur',
      'shayx',
      'sebzar',
    ],
  ),
  SearchDistrict(
    'Uchtepa',
    centrality: 7,
    nameRu: 'Учтепа',
    nameUz: 'Uchtepa',
    locativeRu: 'Учтепе',
    locativeUz: 'Uchtepada',
    aliases: [
      'учтепа',
      'уч-тепа',
      'уштепа',
      'учтепинский',
      'учтепинском',
      'учтеп',
      'uchtepa',
      'uch-tepa',
      'ushtepa',
      'uchtepinskiy',
    ],
  ),
  SearchDistrict(
    'Yakkasaray',
    centrality: 3,
    nameRu: 'Яккасарай',
    nameUz: 'Yakkasaroy',
    locativeRu: 'Яккасарае',
    locativeUz: 'Yakkasaroyda',
    aliases: [
      'яккасарай',
      'яккасарой',
      'яккасар',
      'яккасарайский',
      'яккасарайском',
      'якка',
      'як',
      'yakkasaray',
      'yakkasaroy',
      'yakkasar',
      'yakka',
    ],
  ),
  SearchDistrict(
    'Yangihayot',
    centrality: 12,
    nameRu: 'Янгихаёт',
    nameUz: 'Yangihayot',
    locativeRu: 'Янгихаёте',
    locativeUz: 'Yangihayotda',
    aliases: [
      'янгихаёт',
      'янгихайот',
      'янги хаёт',
      'янги хаёте',
      'янги хаёта',
      'янги-хаёт',
      'янгихаётский',
      'янгихаёте',
      'янгих',
      'yangihayot',
      'yangi hayot',
      'yangi hayotda',
      'yangi hayotga',
      'yangi-hayot',
      'yangixayot',
      'yangihayotda',
    ],
  ),
  SearchDistrict(
    'Yashnobod',
    centrality: 9,
    nameRu: 'Яшнабад',
    nameUz: 'Yashnobod',
    locativeRu: 'Яшнабаде',
    locativeUz: 'Yashnobodda',
    aliases: [
      'яшнабад',
      'яшнобод',
      'яшнобад',
      'яшнабат',
      'яшнабадский',
      'яшнабадском',
      'яшна',
      'yashnobod',
      'yashnabad',
      'yashnobad',
      'yashna',
    ],
  ),
  SearchDistrict(
    'Yunusabad',
    centrality: 5,
    nameRu: 'Юнусабад',
    nameUz: 'Yunusobod',
    locativeRu: 'Юнусабаде',
    locativeUz: 'Yunusobodda',
    aliases: [
      'юнусабад',
      'юнусобод',
      'юнусабат',
      'унусабад',
      'юнусабадский',
      'юнусабадском',
      'юнус',
      'yunusabad',
      'yunusobod',
      'yunusabod',
      'yunus',
      'yunusabadskiy',
    ],
  ),
];

/// Mirrors `kDiscoveryDistricts` in
/// `b2c/lib/features/discovery/presentation/widgets/filter_sheet.dart` (that
/// file has no server-reachable form — the district list is only seeded
/// client-side today).
const List<String> kSearchDistricts = [
  'Bektemir',
  'Chilanzar',
  'Mirabad',
  'Mirzo Ulugbek',
  'Olmazor',
  'Sergeli',
  'Shayxontohur',
  'Uchtepa',
  'Yakkasaray',
  'Yangihayot',
  'Yashnobod',
  'Yunusabad',
];

/// `district` payload meaning "the query named the whole city" — the token is
/// consumed so it never lands in `unknownTerms`, but no district filter is
/// applied.
const String kWholeCityDistrict = '@city';

/// `district` payload meaning "the most central district we actually have
/// listings in" — resolved against the live catalogue at parse time.
const String kCentralDistrict = '@central';

/// Prepositions/conjunctions/articles in all three languages. Removed before
/// deciding whether a query carried any meaning at all (see `meaningfulTokens`
/// in the `POST /v1/ai/search` contract).
const Set<String> kSearchStopwords = {
  // ru
  'и', 'в', 'во', 'на', 'с', 'со', 'для', 'или', 'по', 'у', 'к', 'из', 'за',
  'от', 'до', 'же', 'бы', 'ли', 'а', 'но', 'что', 'это', 'там', 'как', 'мне',
  'я', 'мы',
  // uz
  'va', 'bilan', 'uchun', 'yoki', 'da', 'ga', 'dan', 'ning', 'ham', 'bu',
  'men', 'biz', 'ichida', 'yaqin',
  // en
  'and', 'the', 'for', 'with', 'in', 'on', 'at', 'a', 'an', 'or', 'of', 'to',
  'my', 'me', 'is', 'it', 'we', 'i', 'be', 'by', 'that', 'this',
};

/// The Russian «N-комнатная» adjective declines for gender, case and number,
/// and a real query hits all of them («в трёхкомнатной», «ищу
/// трёхкомнатную», «из трёхкомнатных»). The bare stem is registered next to
/// the spelled-out forms so the inflection stage — alias plus at most four
/// characters — also covers the endings nobody thought to write down.
List<String> _roomsAdjectiveRu(String stem) => [
  stem,
  for (final ending in const [
    'ный',
    'ная',
    'ное',
    'ные',
    'ную',
    'ной',
    'ным',
    'ных',
    'ными',
    'ном',
    'ного',
    'ному',
  ])
    '$stem$ending',
];

/// «однушка», «двушечка», «полуторка» — feminine nouns, so one stem plus five
/// endings is every case a query can produce. Only stems that cannot be
/// confused with another concept get this treatment: «двух-» and «трёх-» are
/// deliberately *not* stems, because «двухуровневая» and «трёхэтажный» are
/// not room counts.
List<String> _roomsColloquialRu(String stem) => [
  stem,
  '${stem}а',
  '${stem}у',
  '${stem}и',
  '${stem}е',
  '${stem}ой',
];

/// The numeral instead of the adjective: «две комнаты», «двух комнат», «с
/// двумя комнатами», plus the «двух комнатная» spelling that writes the
/// adjective apart. Only the numeral needs every case — the n-gram retry
/// inflects «комнат» on its own, so «двух комнат» already covers «двух
/// комнатных» and «двух комнатами».
List<String> _roomsWordRu({
  required String nominative,
  required String countedNoun,
  required String genitive,
  required String instrumental,
}) => [
  '$nominative $countedNoun',
  '$genitive комнат',
  '$genitive комнатная',
  '$genitive комнатную',
  '$genitive комнатной',
  '$instrumental комнатами',
];

/// Digit shorthands the way they are typed on a phone. [infixes] carries the
/// genitive filler between digit and noun that the parser's digit regex does
/// not spell out: it handles «2-х», this handles «1-но», «2-ух», «5-ти».
/// [shortK] is off where the bare «Nк» would fight the price pass («6к» is
/// six thousand long before it is six rooms).
List<String> _roomsDigitRu(
  int n, {
  List<String> infixes = const [],
  bool shortK = true,
}) => [
  '${n}комн',
  '$n комн',
  '$n-комн',
  '${n}комнатная',
  '$n комнатная',
  '$n-комнатная',
  if (shortK) ...['${n}к', '$n-к', '$n к'],
  for (final infix in infixes)
    for (final separator in const ['-', ''])
      for (final tail in const [
        'комнатная',
        'комнатную',
        'комнатной',
        'комн',
      ]) ...['$n$separator$infix $tail', '$n$separator$infix$tail'],
];

/// uz digits, with the suffixes that follow «xona» in a real query
/// («xonali», «xonalik», «xonadan», «xonasi») and the «hona» spelling a
/// Cyrillic-uz keyboard produces.
List<String> _roomsDigitUz(int n) => [
  '$n xonali',
  '$n xonalik',
  '$n xona',
  '$n xonadan',
  '$n xonasi',
  '${n}xonali',
  '$n hona',
  '$n honali',
];

/// uz numeral spelled out — `uch` → «uch xonali», «uchxonali», «uch xona».
List<String> _roomsWordUz(String word) => [
  '$word xonali',
  '$word xonalik',
  '$word xona',
  '$word xonadan',
  '${word}xonali',
  '$word honali',
];

/// en digits, including the shorthands listing sites train people to type
/// («2br», «3-bed», «3 bhk»).
List<String> _roomsDigitEn(int n) => [
  '$n bedroom',
  '$n bedrooms',
  '$n-bedroom',
  '$n room',
  '$n rooms',
  '$n-room',
  '$n br',
  '${n}br',
  '$n-br',
  '$n bed',
  '$n beds',
  '$n-bed',
  '$n bhk',
  '${n}bhk',
  '$n-bhk',
];

/// en numeral spelled out — `two` → «two bedroom», «two-bed», «two rooms».
List<String> _roomsWordEn(String word) => [
  '$word bedroom',
  '$word bedrooms',
  '$word-bedroom',
  '$word room',
  '$word rooms',
  '$word bed',
  '$word-bed',
  '$word br',
];

/// Room counts 0..6: the adjective in every case, the colloquial nouns
/// Tashkent actually uses, the digit shorthands, and the uz/en equivalents.
/// Generated rather than listed by hand — the paradigm is mechanical, and
/// writing it out seven times is exactly how «трёхкомнатной» went missing.
final List<SearchTerm> _roomTerms = [
  SearchTerm(
    canonical: 'rooms:0',
    kind: SearchTermKind.rooms,
    value: 0,
    labels: {'ru': 'студия', 'uz': 'studiya', 'en': 'studio'},
    aliases: [
      'студия',
      'студию',
      'студии',
      'студией',
      'студио',
      // Too short for the fuzzy stage to reach confidently (a single edit in
      // a six-letter word only scores 0.84), so the typos are spelled out.
      'стедия',
      'студья',
      'стюдия',
      'студя',
      'стдия',
      ..._roomsColloquialRu('студийк'),
      ..._roomsColloquialRu('нулевк'),
      ..._roomsColloquialRu('гостинк'),
      ..._roomsDigitRu(0, shortK: false),
      'studio',
      'studiya',
      'studiyalar',
      'studiyani',
      'studiyada',
      'studiyasi',
      'stydio',
      'studya',
      'studiyo',
      'gostinka',
      '0 xonali',
      'studio flat',
      'studio apartment',
      'studio unit',
    ],
  ),
  SearchTerm(
    canonical: 'rooms:1',
    kind: SearchTermKind.rooms,
    value: 1,
    labels: {'ru': '1-комнатная', 'uz': '1 xonali', 'en': '1-bedroom'},
    aliases: [
      ..._roomsColloquialRu('однушк'),
      ..._roomsColloquialRu('однушечк'),
      ..._roomsColloquialRu('полуторк'),
      'однуха',
      'однуху',
      'однухи',
      'одношка',
      'одношку',
      'однушник',
      ..._roomsAdjectiveRu('однокомнат'),
      'однокомн',
      ..._roomsDigitRu(1, infixes: const ['но']),
      // Singular morphology, so this one count does not fit _roomsWordRu.
      'одна комната',
      'одну комнату',
      'одной комнаты',
      'одной комнатой',
      'одно комнат',
      'одно комнатная',
      'одно комнатную',
      'одно комнатной',
      ..._roomsDigitUz(1),
      ..._roomsWordUz('bir'),
      ..._roomsDigitEn(1),
      ..._roomsWordEn('one'),
      'single room',
      'single bedroom',
    ],
  ),
  SearchTerm(
    canonical: 'rooms:2',
    kind: SearchTermKind.rooms,
    value: 2,
    labels: {'ru': '2-комнатная', 'uz': '2 xonali', 'en': '2-bedroom'},
    aliases: [
      ..._roomsColloquialRu('двушк'),
      ..._roomsColloquialRu('двушечк'),
      'двуха',
      'двуху',
      'двушник',
      ..._roomsAdjectiveRu('двухкомнат'),
      'двухкомн',
      ..._roomsDigitRu(2, infixes: const ['ух']),
      ..._roomsWordRu(
        nominative: 'две',
        countedNoun: 'комнаты',
        genitive: 'двух',
        instrumental: 'двумя',
      ),
      // Latin `e` in an otherwise Cyrillic word: what a half-switched
      // keyboard produces, and invisible to the reader who typed it.
      'двe комнаты',
      ..._roomsDigitUz(2),
      ..._roomsWordUz('ikki'),
      ..._roomsDigitEn(2),
      ..._roomsWordEn('two'),
    ],
  ),
  SearchTerm(
    canonical: 'rooms:3',
    kind: SearchTermKind.rooms,
    value: 3,
    labels: {'ru': '3-комнатная', 'uz': '3 xonali', 'en': '3-bedroom'},
    aliases: [
      ..._roomsColloquialRu('трешк'),
      ..._roomsColloquialRu('трешечк'),
      'треха',
      'треху',
      'трешник',
      ..._roomsAdjectiveRu('трехкомнат'),
      'трехкомн',
      ..._roomsDigitRu(3, infixes: const ['ех']),
      ..._roomsWordRu(
        nominative: 'три',
        countedNoun: 'комнаты',
        genitive: 'трех',
        instrumental: 'тремя',
      ),
      ..._roomsDigitUz(3),
      ..._roomsWordUz('uch'),
      ..._roomsDigitEn(3),
      ..._roomsWordEn('three'),
    ],
  ),
  SearchTerm(
    canonical: 'rooms:4',
    kind: SearchTermKind.rooms,
    value: 4,
    labels: {'ru': '4-комнатная', 'uz': '4 xonali', 'en': '4-bedroom'},
    aliases: [
      ..._roomsColloquialRu('четырешк'),
      'четверка',
      'четверку',
      ..._roomsAdjectiveRu('четырехкомнат'),
      'четырехкомн',
      ..._roomsDigitRu(4, infixes: const ['ех']),
      ..._roomsWordRu(
        nominative: 'четыре',
        countedNoun: 'комнаты',
        genitive: 'четырех',
        instrumental: 'четырьмя',
      ),
      ..._roomsDigitUz(4),
      // Both spellings: the apostrophe is what a phone keyboard drops first.
      ..._roomsWordUz("to'rt"),
      ..._roomsWordUz('tort'),
      ..._roomsDigitEn(4),
      ..._roomsWordEn('four'),
    ],
  ),
  SearchTerm(
    canonical: 'rooms:5',
    kind: SearchTermKind.rooms,
    value: 5,
    labels: {'ru': '5-комнатная', 'uz': '5 xonali', 'en': '5-bedroom'},
    aliases: [
      ..._roomsColloquialRu('пятерк'),
      ..._roomsAdjectiveRu('пятикомнат'),
      'пятикомн',
      ..._roomsDigitRu(5, infixes: const ['ти']),
      ..._roomsWordRu(
        nominative: 'пять',
        countedNoun: 'комнат',
        genitive: 'пяти',
        instrumental: 'пятью',
      ),
      ..._roomsDigitUz(5),
      ..._roomsWordUz('besh'),
      ..._roomsDigitEn(5),
      ..._roomsWordEn('five'),
    ],
  ),
  // Six rooms is rare enough that the digit regexes cap out at five, but the
  // words are unambiguous, so the dictionary carries them anyway. `6к` is
  // left out on purpose: the price pass reads it as six thousand first.
  SearchTerm(
    canonical: 'rooms:6',
    kind: SearchTermKind.rooms,
    value: 6,
    labels: {'ru': '6-комнатная', 'uz': '6 xonali', 'en': '6-bedroom'},
    aliases: [
      ..._roomsAdjectiveRu('шестикомнат'),
      'шестикомн',
      ..._roomsDigitRu(6, infixes: const ['ти'], shortK: false),
      ..._roomsWordRu(
        nominative: 'шесть',
        countedNoun: 'комнат',
        genitive: 'шести',
        instrumental: 'шестью',
      ),
      ..._roomsDigitUz(6),
      ..._roomsWordUz('olti'),
      ..._roomsDigitEn(6),
      ..._roomsWordEn('six'),
    ],
  ),
];

const List<SearchTerm> _unitKindTerms = [
  SearchTerm(
    canonical: 'unitKind:apartment',
    kind: SearchTermKind.unitKind,
    value: 'apartment',
    labels: {'ru': 'квартира', 'uz': 'kvartira', 'en': 'apartment'},
    aliases: [
      'квартира',
      'квартиру',
      'квартиры',
      'квартире',
      'квартирой',
      'квартирка',
      'квартирку',
      // Dropped or swapped letters. A single edit in a seven-letter word
      // scores 0.89 — just under the bar the parser applies — so the common
      // slips are spelled out. «кваритра» is deliberately left to the fuzzy
      // stage: at eight characters it clears 0.9, and reporting it as an
      // autocorrection is the honest answer.
      'кватира',
      'кватиру',
      'кватире',
      'кварира',
      'кварире',
      'квртира',
      'квртиру',
      'квортира',
      'квортиру',
      'квортире',
      'кв',
      'апартаменты',
      'апартамент',
      'апарт',
      'жильё',
      'жилье',
      'жилья',
      'хата',
      'хату',
      'уй',
      'уй-жой',
      'kvartira',
      'kvartirani',
      'kvartiralar',
      'kvatira',
      'kvartia',
      'kvartra',
      'xonadon',
      'xonadonlar',
      'uy',
      'uy-joy',
      'uyjoy',
      'uy joy',
      'kvartirasi',
      'apartment',
      'apartments',
      'apartament',
      'appartment',
      'apartmant',
      'aparment',
      'flat',
      'flats',
      'condo',
      'condominium',
      'housing',
    ],
  ),
  SearchTerm(
    canonical: 'unitKind:commercial',
    kind: SearchTermKind.unitKind,
    value: 'commercial',
    labels: {'ru': 'коммерция', 'uz': 'tijorat', 'en': 'commercial'},
    aliases: [
      'коммерция',
      'коммерцию',
      'коммерческая',
      'коммерческое',
      'коммерческую',
      'офис',
      'офиса',
      'офисы',
      'офисное',
      'офисную',
      // Four- and five-letter typos: one edit in a word this short only
      // scores ~0.79, well under the 0.9 the parser needs to apply a match,
      // so the fuzzy stage can never rescue them on its own.
      'офиз',
      'офиис',
      'оффис',
      'оффиз',
      'оффиса',
      'ofic',
      'ofice',
      'offis',
      'офисное помещение',
      'помещение',
      'помещения',
      'нежилое',
      'нежилое помещение',
      'нежилой фонд',
      'коммерческое помещение',
      'коммерческая недвижимость',
      'под офис',
      'под магазин',
      'под бизнес',
      'магазин',
      'магазины',
      'торговое',
      'торговая',
      'торговую',
      'торговая точка',
      'ритейл',
      'склад',
      'склады',
      'шоурум',
      'шоу-рум',
      'бизнес-центр',
      'бизнес центр',
      'ofis',
      'ofislar',
      'ofis binosi',
      'biznes markaz',
      'biznes markazi',
      'savdo nuqtasi',
      'tijorat binosi',
      "do'kon",
      "do'konlar",
      'savdo',
      'savdo maydoni',
      'tijorat',
      'tijorat obyekti',
      'ombor',
      'office',
      'offices',
      'office space',
      'commercial space',
      'commercial unit',
      'commercial premises',
      'retail',
      'retail space',
      'shop',
      'store',
      'warehouse',
      'showroom',
      'commercial',
      'business centre',
      'business center',
    ],
  ),
  // NOTE: there is deliberately no `unitKind:parking` term any more. The
  // catalogue's `kind` vocabulary is `apartment | office | retail` — no
  // parking inventory exists, so a parsed `unitKind: parking` was a phantom
  // chip that could never match anything. «паркинг», «машиноместо», «garage»
  // and friends now resolve to `amenity:parking` instead (see
  // `_amenityTerms`), which is real and filterable.
];

const List<SearchTerm> _dealTypeTerms = [
  SearchTerm(
    canonical: 'dealType:sale',
    kind: SearchTermKind.dealType,
    value: 'sale',
    labels: {'ru': 'купить', 'uz': 'sotib olish', 'en': 'for sale'},
    aliases: [
      'купить',
      'куплю',
      'купля',
      'покупка',
      'покупку',
      'покупки',
      'приобрести',
      'приобретение',
      'в собственность',
      'продажа',
      'продажу',
      'продается',
      'продаётся',
      'на продажу',
      'продам',
      'ипотека',
      'ипотеку',
      'ипотечная',
      'в ипотеку',
      'кредит',
      'в кредит',
      'рассрочка',
      'рассрочку',
      'в рассрочку',
      'sotib olish',
      'sotib olmoqchimiz',
      'sotib olmoqchiman',
      'sotib olaman',
      'sotuv',
      'sotiladi',
      'sotilyapti',
      'xarid',
      'xarid qilish',
      'ipoteka',
      "muddatli to'lov",
      'buy',
      'buying',
      'purchase',
      'for sale',
      'on sale',
      'mortgage',
      'installment',
      'installments',
      'instalment',
    ],
  ),
  SearchTerm(
    canonical: 'dealType:rent',
    kind: SearchTermKind.dealType,
    value: 'rent',
    labels: {'ru': 'аренда', 'uz': 'ijara', 'en': 'for rent'},
    aliases: [
      'снять',
      'сниму',
      'снимем',
      'снимать',
      'съем',
      'съема',
      'наем',
      'найм',
      'аренда',
      'аренду',
      'аренды',
      'арендой',
      'арендовать',
      // Transposition and vowel typos in a six-letter word — same problem as
      // «офиз»: too short for the fuzzy stage to apply confidently.
      'аренад',
      'арнеда',
      'оренда',
      'орендовать',
      'в аренду',
      'долгосрочная аренда',
      'посуточная аренда',
      'сдается',
      'сдаётся',
      'сдам',
      'сдаю',
      'сдача',
      'помесячно',
      'на месяц',
      'посуточно',
      'ijara',
      'ijaraga',
      'ijarada',
      'ijarasi',
      'ijarga',
      'ijaraga olish',
      'ijaraga olmoqchiman',
      'ijaraga beriladi',
      'arenda',
      'arendaga',
      'arendga',
      'kira',
      'kiraga',
      'rent',
      'rental',
      'for rent',
      'renting',
      'lease',
      'leasing',
      'to let',
      'letting',
    ],
  ),
];

const List<SearchTerm> _statusTerms = [
  SearchTerm(
    canonical: 'status:offplan',
    kind: SearchTermKind.status,
    value: 'offplan',
    labels: {'ru': 'новостройка', 'uz': 'yangi bino', 'en': 'off-plan'},
    aliases: [
      'новостройка',
      'новостройку',
      'новостройки',
      'новострой',
      'строится',
      'строящийся',
      'строящаяся',
      'строительство',
      'на стадии строительства',
      'котлован',
      'офф-план',
      'оффплан',
      'офф план',
      'предпродажа',
      'первичка',
      'первичный рынок',
      'off-plan',
      'offplan',
      'off plan',
      'under construction',
      'new build',
      'newbuild',
      'presale',
      'pre-sale',
      'qurilmoqda',
      'qurilyapti',
      'qurilish',
      'qurilish bosqichida',
      'qurilayotgan',
      // «qurilgan» is the participle people reach for when they mean "newly
      // built" — «yangi qurilgan uy» is a new build, not a resale. The
      // property noun is deliberately left out of these aliases: «uy» has to
      // stay free to say "home" so the phrase yields both facts.
      'qurilgan',
      'yangi qurilgan',
      'yangi bino',
      'yangi qurilish',
      // Safe on its own because the district phrases («yangi hayot») are
      // matched before single tokens are.
      'yangi',
    ],
  ),
  SearchTerm(
    canonical: 'status:ready',
    kind: SearchTermKind.status,
    value: 'ready',
    labels: {'ru': 'готовое жильё', 'uz': 'tayyor uy', 'en': 'ready'},
    aliases: [
      'готовое',
      'готовая',
      'готовый',
      'готово',
      'готовую',
      'сдан',
      'сдана',
      'сдано',
      'сданный',
      'сданная',
      'с ключами',
      'заселение',
      'заселён',
      'заселен',
      'вторичка',
      'вторичное',
      'вторичный',
      'вторичный рынок',
      'готовый дом',
      'заселение сразу',
      'tayyor',
      'tayyor uy',
      'topshirilgan',
      'topshirildi',
      'ready',
      'completed',
      'handed over',
      'handover',
      'ready to move',
      'move in ready',
      'move-in ready',
      'keys ready',
    ],
  ),
  SearchTerm(
    canonical: 'status:available',
    kind: SearchTermKind.status,
    value: 'available',
    labels: {'ru': 'в наличии', 'uz': 'mavjud', 'en': 'available now'},
    aliases: [
      'в наличии',
      'в продаже',
      'свободные',
      'свободных',
      'не забронированные',
      'незабронированные',
      'доступные',
      'available',
      'available now',
      'in stock',
      'not booked',
      'unbooked',
      'mavjud',
      "bo'sh kvartiralar",
      'sotuvda bor',
    ],
  ),
];

const List<SearchTerm> _priceTerms = [
  SearchTerm(
    canonical: 'price:cheap',
    kind: SearchTermKind.price,
    value: 'cheap',
    labels: {'ru': 'недорого', 'uz': 'arzon', 'en': 'affordable'},
    aliases: [
      'недорого',
      'недорогая',
      'недорогую',
      'недорогое',
      'дешевая',
      'дешёвая',
      'дешевую',
      'дешево',
      'дешёво',
      'подешевле',
      'бюджетная',
      'бюджетный',
      'бюджетное',
      'бюджетно',
      'эконом',
      'эконом-класс',
      'arzon',
      'arzonroq',
      'arzon narx',
      'cheap',
      'cheaper',
      'affordable',
      'low budget',
      'inexpensive',
      'budget friendly',
    ],
  ),
  SearchTerm(
    canonical: 'price:premium',
    kind: SearchTermKind.price,
    value: 'premium',
    labels: {'ru': 'премиум', 'uz': 'hashamatli', 'en': 'premium'},
    aliases: [
      'премиум',
      'премиальная',
      'премиум-класс',
      'бизнес-класс',
      'бизнес класс',
      'элитная',
      'элитное',
      'элитка',
      'люкс',
      'люксовая',
      'дорогая',
      'дорогое',
      'premium',
      'lux',
      'luxury',
      'business class',
      'elite',
      'hashamatli',
      'lyuks',
      'qimmat',
      'biznes klass',
    ],
  ),
];

const List<SearchTerm> _areaTerms = [
  SearchTerm(
    canonical: 'area:large',
    kind: SearchTermKind.area,
    value: 'large',
    labels: {'ru': 'просторная', 'uz': 'keng', 'en': 'spacious'},
    aliases: [
      'большая',
      'большую',
      'большой',
      'большая площадь',
      'большой площадью',
      'большой метраж',
      'большого метража',
      'просторная',
      'просторную',
      'просторное',
      'просторный',
      'просторно',
      'вместительная',
      'крупная',
      'крупную',
      'побольше',
      'keng',
      'kengroq',
      'keng uy',
      'katta',
      'kattaroq',
      'katta maydonli',
      'spacious',
      'large',
      'large area',
      'big',
      'big area',
      'bigger',
      'roomy',
    ],
  ),
  SearchTerm(
    canonical: 'area:small',
    kind: SearchTermKind.area,
    value: 'small',
    labels: {'ru': 'компактная', 'uz': 'kichik', 'en': 'compact'},
    aliases: [
      'маленькая',
      'маленькую',
      'небольшая',
      'небольшую',
      'небольшой площади',
      'небольшого метража',
      'компактная',
      'компактную',
      'компактное',
      'компакт',
      'поменьше',
      'малогабаритная',
      'малогабаритка',
      'малометражка',
      'kichik',
      'kichikroq',
      'kichkina',
      'ixcham',
      'kichik uy',
      'small',
      'small area',
      'smaller',
      'compact',
      'tiny',
    ],
  ),
];

const List<SearchTerm> _floorTerms = [
  SearchTerm(
    canonical: 'floor:notFirst',
    kind: SearchTermKind.floor,
    value: 'notFirst',
    labels: {
      'ru': 'не первый этаж',
      'uz': 'birinchi qavat emas',
      'en': 'not the first floor',
    },
    aliases: [
      'не первый этаж',
      'не первом этаже',
      'не первый',
      'кроме первого',
      'кроме первого этажа',
      'not first floor',
      'not the first floor',
      'birinchi qavat emas',
      'birinchi qavatdan tashqari',
    ],
  ),
  SearchTerm(
    canonical: 'floor:notLast',
    kind: SearchTermKind.floor,
    value: 'notLast',
    labels: {
      'ru': 'не последний этаж',
      'uz': 'oxirgi qavat emas',
      'en': 'not the last floor',
    },
    aliases: [
      'не последний этаж',
      'не последнем этаже',
      'не последний',
      'кроме последнего',
      'кроме последнего этажа',
      'not last floor',
      'not the last floor',
      'oxirgi qavat emas',
      'oxirgi qavatdan tashqari',
    ],
  ),
  SearchTerm(
    canonical: 'floor:high',
    kind: SearchTermKind.floor,
    value: 'high',
    labels: {'ru': 'высокий этаж', 'uz': 'yuqori qavat', 'en': 'high floor'},
    aliases: [
      'высокий этаж',
      'высокие этажи',
      'высоком этаже',
      'верхние этажи',
      'верхний этаж',
      'повыше',
      'высоко',
      'пентхаус',
      'penthouse',
      'yuqori qavat',
      'yuqori qavatlar',
      'tepa qavat',
      'high floor',
      'higher floor',
      'upper floor',
      'upper floors',
      'top floor',
    ],
  ),
  SearchTerm(
    canonical: 'floor:low',
    kind: SearchTermKind.floor,
    value: 'low',
    labels: {'ru': 'низкий этаж', 'uz': 'past qavat', 'en': 'low floor'},
    aliases: [
      'низкий этаж',
      'низкие этажи',
      'нижние этажи',
      'нижний этаж',
      'пониже',
      'невысоко',
      'past qavat',
      'past qavatlar',
      'quyi qavat',
      'low floor',
      'lower floor',
      'lower floors',
      'ground floor',
    ],
  ),
  SearchTerm(
    canonical: 'floor:mid',
    kind: SearchTermKind.floor,
    value: 'mid',
    labels: {'ru': 'средний этаж', 'uz': "o'rta qavat", 'en': 'middle floor'},
    aliases: [
      'средний этаж',
      'средние этажи',
      'среднем этаже',
      "o'rta qavat",
      'orta qavat',
      'middle floor',
      'middle floors',
    ],
  ),
];

/// «рядом с метро» / «возле школы» / «недалеко от парка»… — generated from
/// explicit Russian case forms so the grammar stays correct (`рядом` +
/// `с/со` + instrumental, `возле` + genitive, `близко к` + dative).
/// [withInstr] carries its own preposition («с метро», «со школой»).
List<String> _nearRu({
  required String nom,
  required String gen,
  required String dat,
  required String withInstr,
}) => [
  'рядом $withInstr',
  'возле $gen',
  'недалеко от $gen',
  'около $gen',
  'вблизи $gen',
  'поблизости от $gen',
  'близко к $dat',
  'в шаговой доступности от $gen',
  '$nom рядом',
  'рядом $nom',
];

List<String> _nearUz(String noun) => [
  '$noun yonida',
  '$noun yaqinida',
  '$noun oldida',
  '$noun atrofida',
  '${noun}ga yaqin',
];

List<String> _nearEn(String noun) => [
  'near $noun',
  'near the $noun',
  'close to $noun',
  'close to the $noun',
  '$noun nearby',
  'next to $noun',
  'next to the $noun',
  'walking distance to $noun',
];

final List<SearchTerm> _amenityTerms = [
  SearchTerm(
    canonical: 'amenity:parking',
    kind: SearchTermKind.amenity,
    value: 'parking',
    labels: {'ru': 'паркинг', 'uz': 'avtoturargoh', 'en': 'parking'},
    aliases: [
      'подземный паркинг',
      'подземная парковка',
      'подземная стоянка',
      'с паркингом',
      'паркингом',
      'есть паркинг',
      'с парковкой',
      'парковкой',
      'место для машины',
      'место под машину',
      // "A parking space of my own" — the qualifier is what people lead with,
      // and «своя»/«собственная» on their own are filler (see `_noiseTerms`),
      // so the pair has to be a phrase to stay one concept.
      'своя парковка',
      'свой паркинг',
      'своя стоянка',
      'собственная парковка',
      'собственный паркинг',
      'личная парковка',
      'отдельная парковка',
      // Former `unitKind:parking` spellings — there is no parking *inventory*
      // in the catalogue, so these read as "a home with parking" instead of a
      // phantom unit-kind filter that can never match.
      'паркинг',
      'паркинга',
      'парковка',
      'парковку',
      'парковки',
      'парковкам',
      'машиноместо',
      'машиноместа',
      'машино-место',
      'машина место',
      'паркоместо',
      'паркоместа',
      'парко-место',
      'парковочное место',
      'парковочные места',
      'гараж',
      'гаражи',
      'гаражом',
      'гаража',
      'подземный гараж',
      'стоянка',
      'стоянки',
      'стоянкой',
      'автостоянка',
      'underground parking',
      'with parking',
      'parking included',
      'own parking',
      'private parking',
      'dedicated parking',
      'parking',
      'parking spot',
      'parking space',
      'parking spaces',
      'parking place',
      'car parking',
      'garage',
      'garage space',
      'car park',
      'avtoturargoh bilan',
      'yer osti avtoturargohi',
      'avtoturargoh',
      'avtoturargohlar',
      'avtoturargoh joyi',
      'garaj',
      'garaj bilan',
      'parkovka',
      'mashina joyi',
      'mashina uchun joy',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:gym',
    kind: SearchTermKind.amenity,
    value: 'gym',
    labels: {'ru': 'спортзал', 'uz': 'sport zali', 'en': 'gym'},
    aliases: [
      'спортзал',
      'спортзалом',
      'спортивный зал',
      'тренажерный зал',
      'тренажёрный зал',
      'тренажерка',
      'тренажёрка',
      'тренажер',
      'фитнес',
      'фитнес-зал',
      'фитнесс',
      'gym',
      'fitness',
      'fitness centre',
      'fitness center',
      'sport zali',
      'sportzal',
      'trenajyor zali',
      'mashqlar zali',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:pool',
    kind: SearchTermKind.amenity,
    value: 'pool',
    labels: {'ru': 'бассейн', 'uz': 'basseyn', 'en': 'pool'},
    aliases: [
      'бассейн',
      'бассейном',
      'с бассейном',
      'бассейна',
      'басик',
      'pool',
      'swimming pool',
      'basseyn',
      'suzish havzasi',
      'havza',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:security',
    kind: SearchTermKind.amenity,
    value: 'security',
    labels: {'ru': 'охрана', 'uz': "qo'riqlash", 'en': 'security'},
    aliases: [
      'охрана',
      'охраны',
      'охраной',
      'с охраной',
      'охраняемая',
      'охраняемый',
      'охраняемое',
      'безопасность',
      // What people actually ask for instead of the word «охрана»: a fenced,
      // watched courtyard. «территория» alone is filler (see `_noiseTerms`),
      // so each of these has to be a phrase to keep its meaning.
      'закрытая территория',
      'закрытой территории',
      'закрытую территорию',
      'охраняемая территория',
      'охраняемой территории',
      'охраняемую территорию',
      'территория под охраной',
      'под охраной',
      'закрытый двор с охраной',
      'круглосуточная охрана',
      'видеонаблюдение',
      'видеонаблюдением',
      'видеокамеры',
      'камеры',
      'камеры видеонаблюдения',
      'кпп',
      'шлагбаум',
      'security',
      'guarded',
      'guarded territory',
      'gated',
      'gated community',
      'gated residence',
      'security cameras',
      'video surveillance',
      'cctv',
      '24/7 security',
      "qo'riqlash",
      "qo'riqlanadigan hudud",
      'qorovul',
      'qorovulli',
      'yopiq hudud',
      'yopiq hududda',
      'xavfsizlik',
      'xavfsizlik xizmati',
      'videokuzatuv',
      'kameralar',
      'qorovulxona',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:concierge',
    kind: SearchTermKind.amenity,
    value: 'concierge',
    labels: {'ru': 'консьерж', 'uz': 'konsyerj', 'en': 'concierge'},
    aliases: [
      'консьерж',
      'консьержем',
      'консьерж-сервис',
      'консьержа',
      'concierge',
      'concierge service',
      'konsyerj',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:coworking',
    kind: SearchTermKind.amenity,
    value: 'coworking',
    labels: {'ru': 'коворкинг', 'uz': 'kovorking', 'en': 'coworking'},
    aliases: [
      'коворкинг',
      'коворкингом',
      'коворкинг-зона',
      'коворкинга',
      'coworking',
      'co-working',
      'coworking lounge',
      'kovorking',
      'kovorking zonasi',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:courtyard',
    kind: SearchTermKind.amenity,
    value: 'courtyard',
    labels: {'ru': 'закрытый двор', 'uz': 'ichki hovli', 'en': 'courtyard'},
    aliases: [
      'двор',
      'во дворе',
      'закрытый двор',
      'благоустроенный двор',
      'двором',
      'courtyard',
      'landscaped courtyard',
      'inner yard',
      'hovli',
      'ichki hovli',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:playground',
    kind: SearchTermKind.amenity,
    value: 'playground',
    labels: {
      'ru': 'детская площадка',
      'uz': 'bolalar maydonchasi',
      'en': 'playground',
    },
    aliases: [
      'детская площадка',
      'детской площадкой',
      'площадка для детей',
      'детская',
      'playground',
      'kids area',
      'kids playground',
      'bolalar maydonchasi',
      'bolalar uchun maydon',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:school',
    kind: SearchTermKind.amenity,
    value: 'school',
    labels: {'ru': 'школа рядом', 'uz': 'maktab', 'en': 'school nearby'},
    aliases: [
      'школа',
      'школой',
      'со школой',
      'school',
      'maktab',
      ..._nearRu(
        nom: 'школа',
        gen: 'школы',
        dat: 'школе',
        withInstr: 'со школой',
      ),
      ..._nearUz('maktab'),
      ..._nearEn('school'),
    ],
  ),
  SearchTerm(
    canonical: 'amenity:kindergarten',
    kind: SearchTermKind.amenity,
    value: 'kindergarten',
    labels: {
      'ru': 'детский сад',
      'uz': "bolalar bog'chasi",
      'en': 'kindergarten',
    },
    aliases: [
      'садик',
      'детский сад',
      'детсад',
      'детсадом',
      'садиком',
      'kindergarten',
      'nursery',
      "bog'cha",
      "bolalar bog'chasi",
      ..._nearRu(
        nom: 'садик',
        gen: 'садика',
        dat: 'садику',
        withInstr: 'с садиком',
      ),
      ..._nearRu(
        nom: 'детсад',
        gen: 'детского сада',
        dat: 'детскому саду',
        withInstr: 'с детским садом',
      ),
      ..._nearUz("bog'cha"),
      ..._nearEn('kindergarten'),
    ],
  ),
  SearchTerm(
    canonical: 'amenity:park',
    kind: SearchTermKind.amenity,
    value: 'park',
    labels: {'ru': 'парк рядом', 'uz': "bog' yaqinida", 'en': 'park nearby'},
    aliases: [
      'парк',
      'парком',
      'у парка',
      'зеленая зона',
      'зелёная зона',
      'park',
      'green zone',
      "bog'",
      'yashil hudud',
      ..._nearRu(
        nom: 'парк',
        gen: 'парка',
        dat: 'парку',
        withInstr: 'с парком',
      ),
      ..._nearUz("bog'"),
      ..._nearUz('park'),
      ..._nearEn('park'),
    ],
  ),
  SearchTerm(
    canonical: 'amenity:metro',
    kind: SearchTermKind.amenity,
    value: 'metro',
    labels: {'ru': 'рядом с метро', 'uz': 'metro yaqinida', 'en': 'near metro'},
    aliases: [
      'метро',
      'у метро',
      'metro',
      'subway',
      'metro bekati',
      ..._nearRu(
        nom: 'метро',
        gen: 'метро',
        dat: 'метро',
        withInstr: 'с метро',
      ),
      ..._nearUz('metro'),
      ..._nearEn('metro'),
      ..._nearEn('subway'),
    ],
  ),
  SearchTerm(
    canonical: 'amenity:elevator',
    kind: SearchTermKind.amenity,
    value: 'elevator',
    labels: {'ru': 'лифт', 'uz': 'lift', 'en': 'elevator'},
    aliases: [
      'лифт',
      'лифты',
      'с лифтом',
      'лифтом',
      'elevator',
      'elevators',
      'lift',
      'lifts',
      'high-speed elevators',
      'lift bor',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:balcony',
    kind: SearchTermKind.amenity,
    value: 'balcony',
    labels: {'ru': 'балкон', 'uz': 'balkon', 'en': 'balcony'},
    aliases: [
      'балкон',
      'балконом',
      'с балконом',
      'лоджия',
      'лоджией',
      'balcony',
      'with balcony',
      'balkon',
      'ayvon',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:terrace',
    kind: SearchTermKind.amenity,
    value: 'terrace',
    labels: {'ru': 'терраса', 'uz': 'terrasa', 'en': 'terrace'},
    aliases: [
      'терраса',
      'террасой',
      'с террасой',
      'террасa',
      'terrace',
      'with terrace',
      'terrasa',
    ],
  ),
  // Nothing published lists a storage room today, so this term is downgraded
  // to a soft preference at parse time. That is the point: a wish that ranks
  // is a far better answer than «кладовка» coming back as an unknown word.
  SearchTerm(
    canonical: 'amenity:storage',
    kind: SearchTermKind.amenity,
    value: 'storage',
    labels: {'ru': 'кладовая', 'uz': 'omborxona', 'en': 'storage room'},
    aliases: [
      'кладовка',
      'кладовку',
      'кладовки',
      'кладовке',
      'кладовкой',
      'кладовая',
      'кладовую',
      'кладовой',
      'кладовые',
      'с кладовкой',
      'кладовое помещение',
      'подсобка',
      'подсобное помещение',
      'storage',
      'storage room',
      'storage space',
      'store room',
      'storeroom',
      'pantry',
      // `ombor` and `omborxona` both name a commercial warehouse (see
      // `unitKind:commercial`) — the diminutive and the explicit "room of a
      // warehouse" are the ones that mean a closet in a flat.
      'ombor xonasi',
      'omborcha',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:underfloor heating',
    kind: SearchTermKind.amenity,
    value: 'underfloor heating',
    labels: {'ru': 'тёплый пол', 'uz': 'issiq pol', 'en': 'underfloor heating'},
    aliases: [
      'теплый пол',
      'теплые полы',
      'теплым полом',
      'с теплым полом',
      'теплого пола',
      'теплых полов',
      'подогрев пола',
      'подогрев полов',
      'с подогревом пола',
      'underfloor heating',
      'under floor heating',
      'floor heating',
      'heated floor',
      'heated floors',
      'issiq pol',
      'issiq pollar',
      'iliq pol',
      'pol isitish',
      'pol isitgichi',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:panoramic windows',
    kind: SearchTermKind.amenity,
    value: 'panoramic windows',
    labels: {
      'ru': 'панорамные окна',
      'uz': 'panoramali derazalar',
      'en': 'panoramic windows',
    },
    aliases: [
      'панорамные окна',
      'панорамными окнами',
      'панорамное остекление',
      'витражные окна',
      'panoramic windows',
      'panoramic glazing',
      'floor to ceiling windows',
      'panoramali derazalar',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:renovation',
    kind: SearchTermKind.amenity,
    value: 'renovation',
    labels: {'ru': 'с ремонтом', 'uz': 'ta\'mirlangan', 'en': 'renovated'},
    aliases: [
      'с ремонтом',
      'ремонт',
      'ремонтом',
      'отделка',
      'отделки',
      'отделкой',
      'с отделкой',
      'готовый ремонт',
      'свежий ремонт',
      'со свежим ремонтом',
      'дизайнерский ремонт',
      'с капитальным ремонтом',
      'под ключ',
      'евроремонт',
      'с евроремонтом',
      'чистовая отделка',
      'чистовая',
      'отремонтированная',
      'renovation',
      'renovated',
      'newly renovated',
      'fully renovated',
      'finished',
      'turnkey',
      'with renovation',
      "ta'mirlangan",
      'tamirlangan',
      'remont',
      'remont bilan',
      'remont qilingan',
      'tayyor remont',
      'yevroremont',
      'yevro remont',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:furnished',
    kind: SearchTermKind.amenity,
    value: 'furnished',
    labels: {'ru': 'с мебелью', 'uz': 'jihozlangan', 'en': 'furnished'},
    aliases: [
      'с мебелью',
      'мебель',
      'мебели',
      'мебелью',
      'меблированная',
      'меблированную',
      'мебелированная',
      'обставленная',
      'с мебелью и техникой',
      'со всей мебелью',
      'furnished',
      'fully furnished',
      'furniture',
      'with furniture',
      'mebel',
      'mebellar',
      'mebelli',
      'mebel bilan',
      'jihozlangan',
      'jihozli',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:view',
    kind: SearchTermKind.amenity,
    value: 'view',
    labels: {'ru': 'красивый вид', 'uz': 'manzara', 'en': 'nice view'},
    aliases: [
      'вид на горы',
      'вид на парк',
      'вид на город',
      'с видом',
      'красивый вид',
      'видом на горы',
      'panorama',
      'view',
      'mountain view',
      'park view',
      'city view',
      'nice view',
      'manzara',
      "tog' manzarasi",
      'chiroyli manzara',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:smart home',
    kind: SearchTermKind.amenity,
    value: 'smart home',
    labels: {'ru': 'умный дом', 'uz': 'aqlli uy', 'en': 'smart home'},
    aliases: [
      'умный дом',
      'умного дома',
      'смарт-дом',
      'смарт дом',
      'система умный дом',
      'smart home',
      'smart house',
      'smart home systems',
      'aqlli uy',
      'aqlli uy tizimi',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:ev charging',
    kind: SearchTermKind.amenity,
    value: 'ev charging',
    labels: {
      'ru': 'зарядка для электромобилей',
      'uz': 'elektromobil zaryadgohi',
      'en': 'ev charging',
    },
    aliases: [
      'зарядка для электромобилей',
      'электрозарядка',
      'зарядная станция',
      'зарядка для электрокаров',
      'ev charging',
      'ev charger',
      'charging station',
      'elektromobil zaryadgohi',
      'zaryadlash stansiyasi',
    ],
  ),
  SearchTerm(
    canonical: 'amenity:hospital',
    kind: SearchTermKind.amenity,
    value: 'hospital',
    labels: {
      'ru': 'клиника рядом',
      'uz': 'shifoxona yaqinida',
      'en': 'clinic nearby',
    },
    aliases: [
      'больница',
      'поликлиника',
      'клиника',
      'медцентр',
      'hospital',
      'clinic',
      'shifoxona',
      'kasalxona',
      'poliklinika',
      ..._nearRu(
        nom: 'больница',
        gen: 'больницы',
        dat: 'больнице',
        withInstr: 'с больницей',
      ),
      ..._nearRu(
        nom: 'поликлиника',
        gen: 'поликлиники',
        dat: 'поликлинике',
        withInstr: 'с поликлиникой',
      ),
      ..._nearRu(
        nom: 'клиника',
        gen: 'клиники',
        dat: 'клинике',
        withInstr: 'с клиникой',
      ),
      ..._nearUz('shifoxona'),
      ..._nearUz('poliklinika'),
      ..._nearEn('hospital'),
      ..._nearEn('clinic'),
    ],
  ),
  SearchTerm(
    canonical: 'amenity:mall',
    kind: SearchTermKind.amenity,
    value: 'mall',
    labels: {
      'ru': 'торговый центр рядом',
      'uz': 'savdo markazi yaqinida',
      'en': 'mall nearby',
    },
    aliases: [
      'торговый центр',
      'тц',
      'молл',
      'супермаркет',
      'mall',
      'shopping mall',
      'shopping centre',
      'shopping center',
      'savdo markazi',
      'supermarket',
      ..._nearRu(nom: 'тц', gen: 'тц', dat: 'тц', withInstr: 'с тц'),
      ..._nearRu(
        nom: 'торговый центр',
        gen: 'торгового центра',
        dat: 'торговому центру',
        withInstr: 'с торговым центром',
      ),
      ..._nearRu(
        nom: 'супермаркет',
        gen: 'супермаркета',
        dat: 'супермаркету',
        withInstr: 'с супермаркетом',
      ),
      ..._nearUz('savdo markazi'),
      ..._nearUz('supermarket'),
      ..._nearEn('mall'),
      ..._nearEn('supermarket'),
    ],
  ),
  SearchTerm(
    canonical: 'amenity:pharmacy',
    kind: SearchTermKind.amenity,
    value: 'pharmacy',
    labels: {
      'ru': 'аптека рядом',
      'uz': 'dorixona yaqinida',
      'en': 'pharmacy nearby',
    },
    aliases: [
      'аптека',
      'pharmacy',
      'dorixona',
      ..._nearRu(
        nom: 'аптека',
        gen: 'аптеки',
        dat: 'аптеке',
        withInstr: 'с аптекой',
      ),
      ..._nearUz('dorixona'),
      ..._nearEn('pharmacy'),
    ],
  ),
];

/// Intent and filler words. They carry no constraint but must be consumed, or
/// every polite Russian query would report half its words as unknown.
const List<SearchTerm> _noiseTerms = [
  SearchTerm(
    canonical: 'noise:intent',
    kind: SearchTermKind.noise,
    aliases: [
      // ru
      'нужна', 'нужно', 'нужен', 'нужны', 'надо', 'ищу', 'ищем', 'искать',
      'хочу', 'хотел', 'хотела', 'хочется', 'подбери', 'подберите',
      'подобрать', 'найди', 'найдите', 'найти', 'покажи', 'покажите',
      'показать', 'посоветуй', 'посоветуйте', 'помоги', 'помогите', 'есть',
      'вариант', 'варианты', 'вариантов', 'семья', 'семьи', 'семейная',
      'срочно', 'пожалуйста', 'плиз', 'привет', 'здравствуйте', 'подскажи',
      'подскажите', 'интересует', 'рассматриваю', 'рассматриваем', 'смотрю',
      'рассмотрю', 'рассмотрим', 'предлагать', 'предлагаю', 'предложи',
      'предложите', 'посмотреть', 'присматриваю', 'что-нибудь',
      'что нибудь', 'какая-нибудь', 'недвижимость', 'объект', 'объекты',
      'предложение', 'предложения', 'жк', 'жилой комплекс', 'комплекс',
      'дом', 'здание', 'район', 'районе', 'города', 'город',
      // Bare «территория»/«своя» constrain nothing; the combinations that do
      // («закрытая территория», «своя парковка») are phrases in
      // `_amenityTerms` and are matched before this list is ever reached.
      'территория', 'территории', 'территорию', 'территорией',
      'своя', 'свой', 'свои', 'собственная', 'собственный', 'собственную',
      'цена', 'цены', 'стоимость', 'сколько стоит',
      // uz
      'kerak', 'kerakli', 'qidiryapman', 'qidiraman', 'izlayapman',
      'istayman', 'xohlayman', 'toping', 'topib', "ko'rsating", "ko'rsat",
      'iltimos', 'salom', 'variant', 'variantlar', 'oila', 'oila uchun',
      'shoshilinch', 'uy-joy majmuasi', 'turar joy', 'bino', 'tuman',
      'hudud', 'hududi', 'taklif', 'taklif qiling', "o'zimning",
      'shahar', 'narx', 'narxi', 'qancha turadi',
      // en
      'need', 'want', 'looking', 'look', 'looking for', 'searching', 'search',
      'find', 'show', 'show me', 'please', 'hello', 'hi', 'options', 'option',
      'help', 'would', 'like', 'some', 'any', 'family', 'urgent', 'property',
      'properties', 'real estate', 'listing', 'listings', 'complex',
      'residential complex', 'building', 'district', 'city', 'territory',
      'interested', 'consider', 'browse', 'own',
      'price', 'prices', 'cost', 'how much',
    ],
  ),
  // Bare measure words. With a number in front of them the regex passes have
  // already claimed them; on their own they constrain nothing, and reporting
  // `комнатная` as an unknown word would be absurd.
  SearchTerm(
    canonical: 'noise:measures',
    kind: SearchTermKind.noise,
    aliases: [
      'комната',
      'комнаты',
      'комнат',
      'комнатная',
      'комнатную',
      'комнатной',
      'комнатах',
      'комнатами',
      'этаж',
      'этажа',
      'этаже',
      'этажей',
      'этажи',
      'метр',
      'метра',
      'метров',
      'xona',
      'xonali',
      'xonalar',
      'qavat',
      'qavatda',
      'qavatlar',
      'metr',
      'room',
      'rooms',
      'bedroom',
      'bedrooms',
      'bed',
      'floor',
      'floors',
      'meter',
      'meters',
      'metre',
      'sq',
    ],
  ),
];

/// Centrality words map to whichever seeded district is most central, and the
/// city name is consumed without constraining anything.
const List<SearchTerm> _cityTerms = [
  SearchTerm(
    canonical: 'district:@central',
    kind: SearchTermKind.district,
    value: kCentralDistrict,
    labels: {
      'ru': 'центр Ташкента',
      'uz': 'Toshkent markazi',
      'en': 'city centre',
    },
    aliases: [
      'центр',
      'центре',
      'в центре',
      'центральный',
      'центральном',
      'центральная',
      'ближе к центру',
      'markaz',
      'markazda',
      'markaziy',
      'shahar markazi',
      'center',
      'centre',
      'city center',
      'city centre',
      'downtown',
      'central',
    ],
  ),
  SearchTerm(
    canonical: 'district:@city',
    kind: SearchTermKind.district,
    value: kWholeCityDistrict,
    labels: {'ru': 'Ташкент', 'uz': 'Toshkent', 'en': 'Tashkent'},
    aliases: [
      'ташкент',
      'ташкенте',
      'ташкента',
      'ташкентский',
      'тошкент',
      'тошкентда',
      'toshkent',
      'toshkentda',
      'tashkent',
      'tashkent city',
      'tosh',
    ],
  ),
];

/// Lexicalized negations: a normalized collocation (single word or phrase)
/// that *excludes* an amenity. The grammar-driven negation pass in the parser
/// handles «без X» / «не X» / «without X» / «no X» / uz «Xsiz» — this map is
/// for the fixed expressions that do not follow that grammar. Keys must be
/// pre-normalized (lower case, `е` not `ё`, straight apostrophe).
const Map<String, String> kNegatedAmenityPhrases = {
  // renovation
  'черновая отделка': 'renovation',
  'черновую отделку': 'renovation',
  'черновой отделкой': 'renovation',
  'черновая': 'renovation',
  'предчистовая отделка': 'renovation',
  'предчистовая': 'renovation',
  'под ремонт': 'renovation',
  'требует ремонта': 'renovation',
  'unrenovated': 'renovation',
  'unfinished': 'renovation',
  'shell condition': 'renovation',
  'white box': 'renovation',
  'remontsiz': 'renovation',
  "ta'mirsiz": 'renovation',
  "ta'mirlanmagan": 'renovation',
  'tamirlanmagan': 'renovation',
  // furnished
  'немеблированная': 'furnished',
  'немеблированную': 'furnished',
  'без обстановки': 'furnished',
  'unfurnished': 'furnished',
  'mebelsiz': 'furnished',
  'jihozlanmagan': 'furnished',
};

/// Grammar cues that start a negation: «без ремонта», «не первый»*, «without
/// parking», «no furniture». (*`не` only negates when what follows resolves
/// to an amenity — «не первый этаж» is claimed by the floor pass instead.)
const Set<String> kNegationCues = {'без', 'не', 'without', 'no'};

/// Every static term, in the order the parser prefers them. Catalogue-derived
/// project/developer names are layered on top at request time (see
/// [CatalogueVocabulary]).
final List<SearchTerm> kSearchTerms = List.unmodifiable([
  ..._roomTerms,
  ..._unitKindTerms,
  ..._dealTypeTerms,
  ..._statusTerms,
  ..._priceTerms,
  ..._areaTerms,
  ..._floorTerms,
  ..._amenityTerms,
  ..._cityTerms,
  ...kSearchDistrictEntries.map(_districtTerm),
  ..._noiseTerms,
]);

/// Case endings of a Russian relational adjective, appended to the `-ск`
/// stem: «чиланзарский», «чиланзарского», «чиланзарскую», «чиланзарскими».
/// A district name is almost never typed in the nominative — «в
/// чиланзарском районе», «квартиры юнусабадского района» — and two letters
/// of difference is more than the fuzzy stage will apply on its own.
const List<String> _districtAdjectiveEndings = [
  'ий',
  'ого',
  'ому',
  'ом',
  'им',
  'ими',
  'ая',
  'ой',
  'ую',
  'ое',
  'ие',
  'их',
];

/// The nominative adjective each district entry already carries, from which
/// the rest of the paradigm is derived.
final RegExp _districtAdjective = RegExp(r'ск(ий|ом)$');

/// One district entry -> its [SearchTerm], with the ru/uz locatives (used by
/// the suggester's «в Чиланзаре» phrasing) fed into the alias index too, so
/// «в Мирзо Улугбеке» parses the same way it is suggested. Multi-word Latin
/// spellings also get the uz `-da`/`-ga` case suffixes; single-word ones
/// already resolve through the inflection stage.
SearchTerm _districtTerm(SearchDistrict d) {
  final aliases = <String>{
    d.canonical.toLowerCase(),
    d.nameRu.toLowerCase(),
    d.nameUz.toLowerCase(),
    d.locativeRu.toLowerCase(),
    d.locativeUz.toLowerCase(),
    ...d.aliases,
  };
  // Adjective paradigm, derived once per entry so the 12 const entries above
  // stay a list of names rather than a list of grammar. The bare stem goes
  // in too, so the inflection stage covers any ending missed here. A
  // hyphenated twin is needed for the multi-word names because the n-gram
  // retry only walks tokens separated by spaces — «мирзо-улугбекского» is
  // never two tokens it will look at together.
  for (final alias in aliases.toList()) {
    if (!_districtAdjective.hasMatch(alias)) continue;
    final stem = alias.substring(0, alias.length - 2);
    final spellings = [stem, if (stem.contains(' ')) stem.replaceAll(' ', '-')];
    for (final spelling in spellings) {
      aliases.add(spelling);
      for (final ending in _districtAdjectiveEndings) {
        aliases.add('$spelling$ending');
      }
    }
  }
  for (final alias in aliases.toList()) {
    if (!alias.contains(' ')) continue;
    final isLatin = !RegExp(r'[а-я]').hasMatch(alias);
    if (isLatin) {
      aliases.add('${alias}da');
      aliases.add('${alias}ga');
    }
  }
  return SearchTerm(
    canonical: 'district:${d.canonical}',
    kind: SearchTermKind.district,
    value: d.canonical,
    labels: {'ru': d.nameRu, 'uz': d.nameUz, 'en': d.canonical},
    aliases: aliases.toList(),
  );
}

// --- Normalization --------------------------------------------------------

final RegExp _apostrophes = RegExp("[\u02BC\u2018\u2019\u02BB\u00B4`']");
final RegExp _dashes = RegExp('[\u2010-\u2015]');
final RegExp _whitespace = RegExp(r'\s+');

/// Length-preserving where it can be (the parser tracks consumed character
/// spans by index): case folding, `ё`→`е`, every apostrophe variant → `'`,
/// every dash variant → `-`, non-breaking space → space. Only
/// [collapseWhitespace] changes the length, and the parser never asks for it.
String normalizeSearchText(String raw, {bool collapseWhitespace = false}) {
  var text = raw
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll('ў', 'у')
      .replaceAll('қ', 'к')
      .replaceAll('ғ', 'г')
      .replaceAll('ҳ', 'х')
      .replaceAll('\u00A0', ' ')
      .replaceAll(_apostrophes, "'")
      .replaceAll(_dashes, '-');
  if (collapseWhitespace) {
    text = text.replaceAll(_whitespace, ' ').trim();
  }
  return text;
}

/// Strips anything that is not a letter, digit or apostrophe — used on single
/// tokens before a dictionary lookup.
String normalizeSearchToken(String raw) => normalizeSearchText(
  raw,
).replaceAll(RegExp(r"[^\p{L}\p{N}']", unicode: true), '');

const Map<String, String> _cyrillicToLatin = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'е': 'e',
  'ж': 'j',
  'з': 'z',
  'и': 'i',
  'й': 'y',
  'к': 'k',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ф': 'f',
  'х': 'x',
  'ц': 'ts',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'sh',
  'ъ': '',
  'ы': 'i',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};

const List<List<String>> _latinToCyrillicDigraphs = [
  ['sh', 'ш'],
  ['ch', 'ч'],
  ['ts', 'ц'],
  ['kh', 'х'],
  ['ya', 'я'],
  ['yu', 'ю'],
  ['yo', 'ё'],
  ['ye', 'е'],
  ["o'", 'у'],
  ["g'", 'г'],
];

const Map<String, String> _latinToCyrillic = {
  'a': 'а',
  'b': 'б',
  'c': 'к',
  'd': 'д',
  'e': 'е',
  'f': 'ф',
  'g': 'г',
  'h': 'х',
  'i': 'и',
  'j': 'ж',
  'k': 'к',
  'l': 'л',
  'm': 'м',
  'n': 'н',
  'o': 'о',
  'p': 'п',
  'q': 'к',
  'r': 'р',
  's': 'с',
  't': 'т',
  'u': 'у',
  'v': 'в',
  'w': 'в',
  'x': 'х',
  'y': 'й',
  'z': 'з',
};

/// `чилонзор` → `chilonzor`. Approximate on purpose: it only has to land on a
/// dictionary alias, not to be a reversible transliteration standard.
String cyrillicToLatin(String value) {
  final buffer = StringBuffer();
  for (final char in value.split('')) {
    buffer.write(_cyrillicToLatin[char] ?? char);
  }
  return buffer.toString();
}

/// `kvartira` → `квартира`, digraphs first so `sh`/`ch`/`o'` survive.
String latinToCyrillic(String value) {
  var text = value;
  for (final pair in _latinToCyrillicDigraphs) {
    text = text.replaceAll(pair[0], '\u0000${pair[1]}\u0000');
  }
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    if (char == '\u0000') continue;
    buffer.write(_latinToCyrillic[char] ?? char);
  }
  return buffer.toString();
}

/// ЙЦУКЕН keys as they land on a QWERTY layout. `rdfhnbhf` → `квартира`.
const Map<String, String> _qwertyToJcuken = {
  'q': 'й',
  'w': 'ц',
  'e': 'у',
  'r': 'к',
  't': 'е',
  'y': 'н',
  'u': 'г',
  'i': 'ш',
  'o': 'щ',
  'p': 'з',
  '[': 'х',
  ']': 'ъ',
  'a': 'ф',
  's': 'ы',
  'd': 'в',
  'f': 'а',
  'g': 'п',
  'h': 'р',
  'j': 'о',
  'k': 'л',
  'l': 'д',
  ';': 'ж',
  "'": 'э',
  'z': 'я',
  'x': 'ч',
  'c': 'с',
  'v': 'м',
  'b': 'и',
  'n': 'т',
  'm': 'ь',
  ',': 'б',
  '.': 'ю',
};

final Map<String, String> _jcukenToQwerty = {
  for (final entry in _qwertyToJcuken.entries) entry.value: entry.key,
};

/// Both directions of the layout mix-up; returns the candidates that actually
/// changed something.
List<String> keyboardLayoutVariants(String token) {
  final variants = <String>[];
  final toCyrillic = StringBuffer();
  var changedToCyrillic = false;
  for (final char in token.split('')) {
    final mapped = _qwertyToJcuken[char];
    if (mapped != null) changedToCyrillic = true;
    toCyrillic.write(mapped ?? char);
  }
  if (changedToCyrillic) variants.add(toCyrillic.toString());

  final toLatin = StringBuffer();
  var changedToLatin = false;
  for (final char in token.split('')) {
    final mapped = _jcukenToQwerty[char];
    if (mapped != null) changedToLatin = true;
    toLatin.write(mapped ?? char);
  }
  if (changedToLatin) variants.add(toLatin.toString());
  return variants;
}

/// Damerau-Levenshtein (optimal string alignment): substitutions, insertions,
/// deletions and adjacent transpositions — `квартиар` is one edit from
/// `квартира`, which a plain Levenshtein would score as two.
int damerauLevenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final lb = b.length;
  var beforePrevious = List<int>.filled(lb + 1, 0);
  var previous = List<int>.generate(lb + 1, (i) => i);
  var current = List<int>.filled(lb + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= lb; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var value = current[j - 1] + 1;
      if (previous[j] + 1 < value) value = previous[j] + 1;
      if (previous[j - 1] + cost < value) value = previous[j - 1] + cost;
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1) &&
          beforePrevious[j - 2] + cost < value) {
        value = beforePrevious[j - 2] + cost;
      }
      current[j] = value;
    }
    final recycled = beforePrevious;
    beforePrevious = previous;
    previous = current;
    current = recycled;
  }
  return previous[lb];
}

/// Length-scaled edit budget: one edit for a short word, three for a long one.
/// Below four characters nothing but an exact hit is trustworthy — that is
/// exactly why `якк` must not silently become `Yakkasaray`.
int fuzzyThresholdFor(int length) {
  if (length < 4) return 0;
  if (length <= 5) return 1;
  if (length <= 8) return 2;
  return 3;
}

/// How a token was resolved. Everything except [fuzzy] is trusted outright;
/// [layout] and a high-confidence [fuzzy] hit are reported to the client as an
/// `autocorrected` step so the UI can say "read X as Y".
enum DictionaryMatchKind {
  exact,
  inflection,
  transliteration,
  layout,
  prefix,
  fuzzy,
}

class DictionaryMatch {
  const DictionaryMatch({
    required this.term,
    required this.matchKind,
    required this.confidence,
    required this.alias,
  });

  final SearchTerm term;
  final DictionaryMatchKind matchKind;

  /// 0..1. At or above 0.9 the parser applies the term silently (or with an
  /// `autocorrected` step); below that it only offers it as a suggestion.
  final double confidence;

  /// The dictionary spelling that matched — the "to" of an autocorrection.
  final String alias;

  bool get isConfident => confidence >= 0.9;

  bool get isAutocorrection =>
      matchKind == DictionaryMatchKind.layout ||
      matchKind == DictionaryMatchKind.fuzzy;
}

/// An alias containing a space, dot or dash: matched as a substring with word
/// boundaries instead of by token, so `не первый этаж` and `sotib olish` work.
class SearchPhraseAlias {
  const SearchPhraseAlias(this.alias, this.term);
  final String alias;
  final SearchTerm term;
}

/// Alias → term index with the staged lookup the parser and the suggester
/// share. Built once for the static vocabulary and once per request for the
/// (tiny) catalogue vocabulary.
class AliasIndex {
  AliasIndex(List<SearchTerm> terms) {
    for (final term in terms) {
      for (final rawAlias in term.aliases) {
        final alias = normalizeSearchText(rawAlias, collapseWhitespace: true);
        if (alias.isEmpty) continue;
        if (_isPhrase(alias)) {
          phrases.add(SearchPhraseAlias(alias, term));
        } else {
          _byAlias.putIfAbsent(alias, () => term);
          _singles.add(alias);
        }
      }
    }
    phrases.sort((a, b) => b.alias.length.compareTo(a.alias.length));
    _singles.sort((a, b) => b.length.compareTo(a.length));
  }

  final Map<String, SearchTerm> _byAlias = {};
  final List<String> _singles = [];

  /// Multi-word aliases, longest first — `не первый этаж` must win over
  /// `этаж`.
  final List<SearchPhraseAlias> phrases = [];

  int get aliasCount => _byAlias.length + phrases.length;

  static bool _isPhrase(String alias) =>
      alias.contains(' ') || alias.contains('-') || alias.contains('.');

  SearchTerm? termForAlias(String alias) => _byAlias[alias];

  DictionaryMatch? exact(String token) {
    final term = _byAlias[token];
    if (term == null) return null;
    return DictionaryMatch(
      term: term,
      matchKind: DictionaryMatchKind.exact,
      confidence: 1,
      alias: token,
    );
  }

  /// A declension or a case suffix: the alias is a prefix of the token and at
  /// most four characters were appended (`чиланзаре`, `chilanzarda`,
  /// `квартирой`).
  DictionaryMatch? inflection(String token) {
    if (token.length < 5) return null;
    for (final alias in _singles) {
      if (alias.length < 4 || alias.length >= token.length) continue;
      if (token.length - alias.length > 4) continue;
      if (!token.startsWith(alias)) continue;
      return DictionaryMatch(
        term: _byAlias[alias]!,
        matchKind: DictionaryMatchKind.inflection,
        confidence: 0.98,
        alias: alias,
      );
    }
    return null;
  }

  /// The token is the start of a longer alias and every candidate points at
  /// the same concept (`чилан` → Chilanzar, `квартир` → apartment).
  DictionaryMatch? prefix(String token, {int minLength = 4}) {
    if (token.length < minLength) return null;
    final terms = prefixTerms(token);
    if (terms.length != 1) return null;
    return DictionaryMatch(
      term: terms.first,
      matchKind: DictionaryMatchKind.prefix,
      confidence: 0.9,
      alias: _shortestAliasStartingWith(token) ?? token,
    );
  }

  /// Distinct terms having an alias that starts with [token].
  List<SearchTerm> prefixTerms(String token) {
    final found = <String, SearchTerm>{};
    for (final alias in _singles) {
      if (alias.length > token.length && alias.startsWith(token)) {
        final term = _byAlias[alias]!;
        found[term.canonical] = term;
      }
    }
    for (final phrase in phrases) {
      if (phrase.alias.startsWith(token)) {
        found[phrase.term.canonical] = phrase.term;
      }
    }
    return found.values.toList();
  }

  String? _shortestAliasStartingWith(String token) {
    String? best;
    for (final alias in _singles) {
      if (alias.length > token.length && alias.startsWith(token)) {
        if (best == null || alias.length < best.length) best = alias;
      }
    }
    return best;
  }

  DictionaryMatch? fuzzy(String token) {
    final budget = fuzzyThresholdFor(token.length);
    if (budget == 0) return null;
    String? bestAlias;
    var bestDistance = budget + 1;
    for (final alias in _singles) {
      if ((alias.length - token.length).abs() > budget) continue;
      final distance = damerauLevenshtein(token, alias);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestAlias = alias;
        if (distance == 1) break;
      }
    }
    if (bestAlias == null || bestDistance > budget) return null;
    return DictionaryMatch(
      term: _byAlias[bestAlias]!,
      matchKind: DictionaryMatchKind.fuzzy,
      confidence: fuzzyConfidence(bestDistance, token.length),
      alias: bestAlias,
    );
  }
}

/// Confidence from the edit distance, scaled by how long the word was: one
/// slip in a long word is almost certainly a typo, one slip in a short word
/// could be a different word entirely.
double fuzzyConfidence(int distance, int length) {
  if (distance <= 0) return 1;
  final ratio = 1 - distance / length;
  final confidence = ratio * 0.95 + 0.08;
  return confidence < 0 ? 0 : (confidence > 0.99 ? 0.99 : confidence);
}

/// The static vocabulary, indexed once.
final AliasIndex kSearchIndex = AliasIndex(kSearchTerms);

/// Resolves one token against the static vocabulary and, when supplied, the
/// catalogue names — stage by stage so an exact hit anywhere beats a fuzzy hit
/// everywhere.
DictionaryMatch? matchSearchToken(String rawToken, {AliasIndex? catalogue}) {
  final token = normalizeSearchToken(rawToken);
  if (token.isEmpty) return null;
  final indexes = <AliasIndex>[kSearchIndex, if (catalogue != null) catalogue];

  for (final index in indexes) {
    final hit = index.exact(token);
    if (hit != null) return hit;
  }
  for (final index in indexes) {
    final hit = index.inflection(token);
    if (hit != null) return hit;
  }
  for (final variant in [cyrillicToLatin(token), latinToCyrillic(token)]) {
    if (variant == token || variant.isEmpty) continue;
    for (final index in indexes) {
      final hit = index.exact(variant) ?? index.inflection(variant);
      if (hit != null) {
        return DictionaryMatch(
          term: hit.term,
          matchKind: DictionaryMatchKind.transliteration,
          confidence: 0.95,
          alias: hit.alias,
        );
      }
    }
  }
  for (final variant in keyboardLayoutVariants(token)) {
    for (final index in indexes) {
      final hit = index.exact(variant) ?? index.inflection(variant);
      if (hit != null) {
        return DictionaryMatch(
          term: hit.term,
          matchKind: DictionaryMatchKind.layout,
          confidence: 0.93,
          alias: hit.alias,
        );
      }
    }
  }
  for (final index in indexes) {
    final hit = index.prefix(token);
    if (hit != null) return hit;
  }
  DictionaryMatch? best;
  for (final index in indexes) {
    final hit = index.fuzzy(token);
    if (hit != null && (best == null || hit.confidence > best.confidence)) {
      best = hit;
    }
  }
  if (best != null) return best;

  // Last resort, and deliberately not confident enough to apply: a short stub
  // that starts a real word becomes a "did you mean" instead of a match.
  final stubs = <SearchTerm>[];
  for (final index in indexes) {
    stubs.addAll(index.prefixTerms(token));
  }
  if (token.length >= 3 && stubs.isNotEmpty) {
    return DictionaryMatch(
      term: stubs.first,
      matchKind: DictionaryMatchKind.prefix,
      confidence: 0.7,
      alias: stubs.first.aliases.first,
    );
  }
  return null;
}

/// Vocabulary that only exists because of what is actually published:
/// project and developer names, the amenities the catalogue really offers, and
/// which districts have inventory. Cheap to build (a couple of projects) and
/// rebuilt per request so an admin edit is visible immediately.
class CatalogueVocabulary {
  CatalogueVocabulary._({
    required this.index,
    required this.amenityTexts,
    required this.districtUnitCounts,
    required this.projectNames,
    required this.developerNames,
  });

  factory CatalogueVocabulary.fromProjects(
    List<Map<String, dynamic>> projects,
  ) {
    final terms = <SearchTerm>[];
    final amenityTexts = <String>{};
    final districtUnitCounts = <String, int>{};
    final projectNames = <String>[];
    final developerNames = <String>[];

    for (final project in projects) {
      final name = (project['name'] as String? ?? '').trim();
      if (name.isNotEmpty) {
        projectNames.add(name);
        terms.add(
          SearchTerm(
            canonical: 'project:$name',
            kind: SearchTermKind.project,
            value: name,
            labels: {'ru': name, 'uz': name, 'en': name},
            aliases: _nameAliases(name),
          ),
        );
      }
      final developer =
          ((project['developer'] as Map?)?['name'] as String? ?? '').trim();
      if (developer.isNotEmpty && !developerNames.contains(developer)) {
        developerNames.add(developer);
        terms.add(
          SearchTerm(
            canonical: 'developer:$developer',
            kind: SearchTermKind.developer,
            value: developer,
            labels: {'ru': developer, 'uz': developer, 'en': developer},
            aliases: _nameAliases(developer),
          ),
        );
      }
      for (final amenity in (project['amenities'] as List? ?? const [])) {
        amenityTexts.add(normalizeSearchText(amenity.toString()));
      }
      final district = project['district'] as String?;
      if (district != null && district.isNotEmpty) {
        var available = 0;
        for (final building
            in (project['buildings'] as List? ?? const []).cast<Map>()) {
          for (final unit
              in (building['units'] as List? ?? const []).cast<Map>()) {
            if (unit['status'] == 'available') available++;
          }
        }
        districtUnitCounts[district] =
            (districtUnitCounts[district] ?? 0) + available;
      }
    }

    return CatalogueVocabulary._(
      index: AliasIndex(terms),
      amenityTexts: amenityTexts,
      districtUnitCounts: districtUnitCounts,
      projectNames: projectNames,
      developerNames: developerNames,
    );
  }

  final AliasIndex index;
  final Set<String> amenityTexts;

  /// Available units per district — the suggester offers the districts with
  /// something to show first.
  final Map<String, int> districtUnitCounts;
  final List<String> projectNames;
  final List<String> developerNames;

  /// `Hills Blue` → `hills blue`, `hillsblue`, plus the Cyrillic/Latin
  /// transliteration of each so `хиллс блю` resolves too. Individual words of
  /// a multi-word name are deliberately *not* registered as standalone
  /// aliases any more — «blue» alone matching a project was a false-positive
  /// factory. The n-gram retry in the parser covers slightly misspelled or
  /// inflected full names instead.
  static List<String> _nameAliases(String name) {
    final normalized = normalizeSearchText(name, collapseWhitespace: true);
    final aliases = <String>{normalized};
    if (normalized.contains(' ')) {
      aliases.add(normalized.replaceAll(' ', ''));
    }
    for (final alias in aliases.toList()) {
      final cyrillic = latinToCyrillic(alias);
      if (cyrillic != alias) aliases.add(cyrillic);
      final latin = cyrillicToLatin(alias);
      if (latin != alias) aliases.add(latin);
    }
    return aliases.where((a) => a.length >= 3).toList();
  }

  /// Does any published project list this amenity? A `no` turns the hard
  /// filter into a soft preference instead of zeroing the result set.
  bool hasAmenity(String key) {
    final needle = normalizeSearchText(key);
    return amenityTexts.any((text) => text.contains(needle));
  }

  /// The most central district that actually has listings — what `в центре`
  /// resolves to.
  String? get centralDistrict {
    final ranked = [...kSearchDistrictEntries]
      ..sort((a, b) => a.centrality.compareTo(b.centrality));
    for (final district in ranked) {
      if (districtUnitCounts.containsKey(district.canonical)) {
        return district.canonical;
      }
    }
    return null;
  }
}

/// A phrase the suggest endpoint can offer. [stem] is what a half-typed word
/// completes into (`центре Ташкента` after `цен`), [clause] is what gets
/// appended as a whole next clause (`в центре Ташкента`).
class SuggestPhrase {
  const SuggestPhrase({
    required this.kind,
    required this.clause,
    required this.stem,
    required this.score,
    this.proximity = false,
  });

  final SearchTermKind kind;
  final String clause;
  final String stem;
  final double score;

  /// A «рядом с …» amenity phrase: offered after a dangling «рядом»/«near»,
  /// never after a dangling «с»/«with» (which takes the plain amenity stems).
  final bool proximity;
}

/// Static completion pool per language. Districts and project names are added
/// from the catalogue at request time, so only the phrasings that do not
/// depend on inventory live here.
const Map<String, List<SuggestPhrase>> kSuggestPhrases = {
  'ru': [
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: 'на 2 комнаты',
      stem: '2-комнатная',
      score: 0.72,
    ),
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: 'на 3 комнаты',
      stem: '3-комнатная',
      score: 0.70,
    ),
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: 'на 1 комнату',
      stem: '1-комнатная',
      score: 0.68,
    ),
    SuggestPhrase(
      kind: SearchTermKind.price,
      clause: 'до 90 000 \$',
      stem: '90 000 \$',
      score: 0.66,
    ),
    SuggestPhrase(
      kind: SearchTermKind.price,
      clause: 'до 60 000 \$',
      stem: '60 000 \$',
      score: 0.64,
    ),
    SuggestPhrase(
      kind: SearchTermKind.price,
      clause: 'до 120 000 \$',
      stem: '120 000 \$',
      score: 0.62,
    ),
    SuggestPhrase(
      kind: SearchTermKind.dealType,
      clause: 'купить',
      stem: 'купить',
      score: 0.56,
    ),
    SuggestPhrase(
      kind: SearchTermKind.dealType,
      clause: 'в аренду',
      stem: 'аренду',
      score: 0.54,
    ),
    SuggestPhrase(
      kind: SearchTermKind.status,
      clause: 'новостройка',
      stem: 'новостройка',
      score: 0.50,
    ),
    SuggestPhrase(
      kind: SearchTermKind.status,
      clause: 'готовое жильё',
      stem: 'готовое жильё',
      score: 0.48,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'с паркингом',
      stem: 'паркингом',
      score: 0.46,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'рядом с метро',
      stem: 'с метро',
      score: 0.45,
      proximity: true,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'с ремонтом',
      stem: 'ремонтом',
      score: 0.44,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'с мебелью',
      stem: 'мебелью',
      score: 0.42,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'рядом со школой',
      stem: 'со школой',
      score: 0.35,
      proximity: true,
    ),
    SuggestPhrase(
      kind: SearchTermKind.floor,
      clause: 'не первый этаж',
      stem: 'не первый этаж',
      score: 0.40,
    ),
    SuggestPhrase(
      kind: SearchTermKind.floor,
      clause: 'высокий этаж',
      stem: 'высоком этаже',
      score: 0.38,
    ),
    SuggestPhrase(
      kind: SearchTermKind.area,
      clause: 'до 80 м²',
      stem: '80 м²',
      score: 0.36,
    ),
    SuggestPhrase(
      kind: SearchTermKind.unitKind,
      clause: 'офисное помещение',
      stem: 'офисное помещение',
      score: 0.28,
    ),
  ],
  'uz': [
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: '2 xonali',
      stem: '2 xonali',
      score: 0.72,
    ),
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: '3 xonali',
      stem: '3 xonali',
      score: 0.70,
    ),
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: '1 xonali',
      stem: '1 xonali',
      score: 0.68,
    ),
    SuggestPhrase(
      kind: SearchTermKind.price,
      clause: '90 000 \$ gacha',
      stem: '90 000 \$ gacha',
      score: 0.66,
    ),
    SuggestPhrase(
      kind: SearchTermKind.price,
      clause: '60 000 \$ gacha',
      stem: '60 000 \$ gacha',
      score: 0.64,
    ),
    SuggestPhrase(
      kind: SearchTermKind.dealType,
      clause: 'sotib olish',
      stem: 'sotib olish',
      score: 0.56,
    ),
    SuggestPhrase(
      kind: SearchTermKind.dealType,
      clause: 'ijaraga',
      stem: 'ijaraga',
      score: 0.54,
    ),
    SuggestPhrase(
      kind: SearchTermKind.status,
      clause: 'yangi bino',
      stem: 'yangi bino',
      score: 0.50,
    ),
    SuggestPhrase(
      kind: SearchTermKind.status,
      clause: 'tayyor uy',
      stem: 'tayyor uy',
      score: 0.48,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'avtoturargoh bilan',
      stem: 'avtoturargoh bilan',
      score: 0.46,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'metro yaqinida',
      stem: 'metro yaqinida',
      score: 0.45,
      proximity: true,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: "ta'mirlangan",
      stem: "ta'mirlangan",
      score: 0.44,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'mebel bilan',
      stem: 'mebel bilan',
      score: 0.42,
    ),
    SuggestPhrase(
      kind: SearchTermKind.floor,
      clause: 'birinchi qavat emas',
      stem: 'birinchi qavat emas',
      score: 0.40,
    ),
    SuggestPhrase(
      kind: SearchTermKind.floor,
      clause: 'yuqori qavat',
      stem: 'yuqori qavat',
      score: 0.38,
    ),
    SuggestPhrase(
      kind: SearchTermKind.area,
      clause: '80 m² gacha',
      stem: '80 m² gacha',
      score: 0.36,
    ),
    SuggestPhrase(
      kind: SearchTermKind.unitKind,
      clause: 'ofis',
      stem: 'ofis',
      score: 0.28,
    ),
  ],
  'en': [
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: 'with 2 bedrooms',
      stem: '2 bedrooms',
      score: 0.72,
    ),
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: 'with 3 bedrooms',
      stem: '3 bedrooms',
      score: 0.70,
    ),
    SuggestPhrase(
      kind: SearchTermKind.rooms,
      clause: 'with 1 bedroom',
      stem: '1 bedroom',
      score: 0.68,
    ),
    SuggestPhrase(
      kind: SearchTermKind.price,
      clause: 'up to 90 000 \$',
      stem: '90 000 \$',
      score: 0.66,
    ),
    SuggestPhrase(
      kind: SearchTermKind.price,
      clause: 'up to 60 000 \$',
      stem: '60 000 \$',
      score: 0.64,
    ),
    SuggestPhrase(
      kind: SearchTermKind.dealType,
      clause: 'for sale',
      stem: 'for sale',
      score: 0.56,
    ),
    SuggestPhrase(
      kind: SearchTermKind.dealType,
      clause: 'for rent',
      stem: 'for rent',
      score: 0.54,
    ),
    SuggestPhrase(
      kind: SearchTermKind.status,
      clause: 'new build',
      stem: 'new build',
      score: 0.50,
    ),
    SuggestPhrase(
      kind: SearchTermKind.status,
      clause: 'ready to move',
      stem: 'ready to move',
      score: 0.48,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'with parking',
      stem: 'parking',
      score: 0.46,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'near the metro',
      stem: 'the metro',
      score: 0.45,
      proximity: true,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'renovated',
      stem: 'renovated',
      score: 0.44,
    ),
    SuggestPhrase(
      kind: SearchTermKind.amenity,
      clause: 'furnished',
      stem: 'furniture',
      score: 0.42,
    ),
    SuggestPhrase(
      kind: SearchTermKind.floor,
      clause: 'not the first floor',
      stem: 'not the first floor',
      score: 0.40,
    ),
    SuggestPhrase(
      kind: SearchTermKind.floor,
      clause: 'on a high floor',
      stem: 'a high floor',
      score: 0.38,
    ),
    SuggestPhrase(
      kind: SearchTermKind.area,
      clause: 'up to 80 m²',
      stem: '80 m²',
      score: 0.36,
    ),
    SuggestPhrase(
      kind: SearchTermKind.unitKind,
      clause: 'office space',
      stem: 'office space',
      score: 0.28,
    ),
  ],
};

/// "In the centre of Tashkent" per language — scored above every individual
/// district so a half-typed `цен` completes to it unambiguously.
const Map<String, SuggestPhrase> kCentreSuggestPhrase = {
  'ru': SuggestPhrase(
    kind: SearchTermKind.district,
    clause: 'в центре Ташкента',
    stem: 'центре Ташкента',
    score: 0.86,
  ),
  'uz': SuggestPhrase(
    kind: SearchTermKind.district,
    clause: 'Toshkent markazida',
    stem: 'markazida',
    score: 0.86,
  ),
  'en': SuggestPhrase(
    kind: SearchTermKind.district,
    clause: 'in the centre of Tashkent',
    stem: 'centre of Tashkent',
    score: 0.86,
  ),
};

/// Locative district phrase in [language] (`в Юнусабаде`, `Yunusobodda`,
/// `in Yunusabad`).
SuggestPhrase districtSuggestPhrase(
  SearchDistrict district,
  String language,
  double score,
) {
  switch (language) {
    case 'uz':
      return SuggestPhrase(
        kind: SearchTermKind.district,
        clause: district.locativeUz,
        stem: district.locativeUz,
        score: score,
      );
    case 'en':
      return SuggestPhrase(
        kind: SearchTermKind.district,
        clause: 'in ${district.canonical}',
        stem: district.canonical,
        score: score,
      );
    default:
      return SuggestPhrase(
        kind: SearchTermKind.district,
        clause: 'в ${district.locativeRu}',
        stem: district.locativeRu,
        score: score,
      );
  }
}

/// A dangling preposition routes the completion instead of merely not being
/// doubled: «до » wants a price, «с » wants an amenity, «рядом » wants a
/// proximity amenity, «в » wants a place. Grouped here so the suggester and
/// any future caller agree on the routing.
const Set<String> kPlacePrepositions = {
  'в', 'во', 'на', 'у', 'по', 'для', // ru
  'in', 'at', 'on', 'for', // en
  'da', // uz
};

const Set<String> kPricePrepositions = {
  'до', 'от', 'за', 'дешевле', 'дороже', // ru
  'to', 'under', 'over', 'from', // en ("up to" ends in "to")
  'gacha', 'dan', // uz
};

const Set<String> kAmenityPrepositions = {
  'с', 'со', // ru
  'with', // en
  'bilan', // uz
};

const Set<String> kProximityPrepositions = {
  'рядом', 'возле', 'около', 'недалеко', // ru
  'near', // en
  'yonida', 'yaqinida', // uz
};

/// Every word the suggester treats as a dangling clause-opener: the next
/// completion is appended without its own preposition.
final Set<String> kTrailingPrepositions = {
  ...kPlacePrepositions,
  ...kPricePrepositions,
  ...kAmenityPrepositions,
  ...kProximityPrepositions,
};
