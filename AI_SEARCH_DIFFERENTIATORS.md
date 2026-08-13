# Чем умный AI-поиск iBuild отличается от обычного поиска

Обычный поиск по объектам — это подстрочный матч по полям (`title LIKE '%...%'`) либо набор фильтров-дропдаунов, которые пользователь обязан выставить сам. Наш поиск (`server/lib/src/ai/smart_search_engine.dart`, `server/lib/src/ai/search_dictionary.dart`, `server/lib/src/ai/search_suggester.dart`) — это собственный парсер свободного текста + движок ранжирования, написанные под конкретную модель каталога. Ниже — конкретные, проверяемые в коде отличия.

---

## 1. Понимает отрицание, а не только совпадение слов

Обычный текстовый поиск по фразе «без ремонта» скорее всего найдёт объекты, у которых слово «ремонт» просто встречается в описании — то есть выдаст ровно то, что человек не хотел.

У нас есть отдельный проход парсера для отрицаний: «без X» / «не X» / «without X» / «no X», узбекский суффикс `-siz` («mebelsiz» = без мебели), узбекская постфиксная форма «X yo'q» / «X kerak emas», а также лексикализованные словосочетания вроде «черновая отделка». Этот проход **исключает** объекты с найденным удобством, а не включает их, и запускается раньше позитивного разбора, чтобы «ремонт» внутри «без ремонта» не был случайно засчитан как желаемое удобство:

```dart
// server/lib/src/ai/smart_search_engine.dart
// --- negation: «без X» / «не X» / «without X» / «no X» / uz «Xsiz»,
// plus the lexicalized forms in kNegatedAmenityPhrases. Runs before every
// positive pass so «ремонт» in «без ремонта» cannot be claimed as a
// positive amenity. Only amenities are negatable: anything else keeps
// its current (unrecognized) behaviour.
void exclude(String amenityKey) {
  c.excludedAmenities.add(amenityKey);
  c.amenities.remove(amenityKey);
}
```

Результат: юнит, чей проект предлагает забаненное удобство, отфильтровывается — это жёсткое вето, симметричное позитивному фильтру, а не просто отсутствие совпадения.

---

## 2. Никогда не «притворяется», что поняло запрос

Обычный поиск на пустой/непонятной query почти всегда либо возвращает 0 результатов, либо (что хуже) начинает искать по случайным словам и выдаёт нерелевантный мусор — и в обоих случаях пользователь не понимает, что произошло.

Наш движок явно отличает «ничего не нашли» от «ничего не поняли». Если из запроса не удалось извлечь ни одного признака (`constraintCount == 0`), но в нём было что-то содержательное (`meaningfulTokens.isNotEmpty`), движок **вообще не идёт в каталог** и не сообщает число совпадений — он возвращает `blocked: true` вместе с вариантами «может, вы имели в виду...»:

```dart
// server/lib/src/ai/smart_search_engine.dart
// The core of the "stop pretending you understood" fix: no constraint at
// all out of a query that clearly said *something* means we never touch
// the catalogue and never report a match count.
final blocked =
    constraintsOverride == null &&
    constraints.constraintCount == 0 &&
    parsed.meaningfulTokens.isNotEmpty;
```

Это осознанное архитектурное решение, а не побочный эффект: код прямо документирует, что цель — «перестать делать вид, что запрос понят».

---

## 3. Ранжирует по релевантности с доменным сигналом, а не просто фильтрует

Обычный поиск либо находит объект, либо не находит — бинарно. У нас каждый подходящий юнит получает `matchScore` (0–100) и список именованных причин (`districtMatch`, `roomsMatch`, `priceFit`, `priceBelowBudget`, `areaFit`, `floorPreference`, `amenityMatch`, `highTrustIndex`, `readySoon`, `offplanDiscount`, `availableNow`) — то есть не просто «да/нет», а объяснимая степень соответствия.

Ключевая деталь: в скор вшит доменный сигнал, которого у обычного текстового поиска просто не существует — **индекс доверия к проекту**, посчитанный как отношение реального хода строительства к заявленному графику:

```dart
// server/lib/src/ai/smart_search_engine.dart
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
```

Проект, который строится строго по графику, поднимается в выдаче выше — это бизнес-логика рынка недвижимости, а не текстовый матчинг.

---

## 4. Умеет «смягчать» невозможные пожелания вместо пустого результата

Если пользователь просит удобство, которого нет ни в одном опубликованном проекте (например, специфичный вид отделки), обычный фильтр честно, но бесполезно вернёт пустой список — и создаст у пользователя ощущение, что в базе вообще ничего нет.

Наш движок сначала проверяет, существует ли такое удобство хоть где-то в реальном, живом каталоге (`CatalogueVocabulary`). Если нет — он не фильтрует по нему жёстко, а понижает пожелание до мягкого предпочтения (`softAmenities`), которое лишь слегка поднимает релевантные объекты в ранжировании, и явно сообщает об этом в ответе шагом `softenedAmenity`:

```dart
// server/lib/src/ai/smart_search_engine.dart
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
    ...
  }
```

Комментарий в коде прямо формулирует принцип: фильтрация по несуществующему удобству «вернула бы пустой список и переложила бы вину на пользователя за то, что он спросил» — этого мы избегаем.

---

## 5. Прозрачный трейс выполнения, а не чёрный ящик

Обычный поиск отдаёт только итоговый список (или его отсутствие) — как именно он к нему пришёл, не видно ни пользователю, ни разработчику при отладке.

Каждый ответ нашего движка включает поле `steps` — реальную, воспроизводимую последовательность шагов с настоящими счётчиками на каждом этапе: `parsing` → (`autocorrected` / `softenedAmenity` / `lowConfidence`) → `scanningDistrict` → `foundInDistrict` → `openingProject` (по каждому проекту) → `scanningUnits` → `filteringBooked` → `rankingPrice` → `done`. Это не декоративная анимация — цифры в каждом шаге настоящие (сколько проектов просканировано, сколько юнитов отброшено как забронированные, сколько осталось после ранжирования), и клиент локализует их сам из ARB-файлов, не получая готовую прозу от сервера:

```dart
// server/lib/src/ai/smart_search_engine.dart
steps.add(
  SearchStep('filteringBooked', {
    'removed': bookedFiltered,
    'left': unitsAfterHardFilters,
  }),
);
```

Это делает поиск объяснимым: можно показать пользователю (или отладить самому), почему именно эти объекты и именно в этом порядке.

---

### Итог

Разница не в том, что «AI» звучит громче, чем «поиск по полям» — разница в конкретных инженерных решениях: отдельный проход под отрицания, осознанный отказ выдавать результат, когда запрос не понят, доменное ранжирование с индексом доверия к застройщику, смягчение невыполнимых пожеланий вместо пустой выдачи, и полная прослеживаемость каждого шага выполнения.
