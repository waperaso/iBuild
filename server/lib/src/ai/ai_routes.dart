import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth_context.dart';
import '../http_helpers.dart';
import '../static_files.dart';
import '../store.dart';
import 'ai_quota.dart';
import 'lead_scoring_engine.dart';
import 'openai_client.dart';
import 'prompts.dart';
import 'readiness_engine.dart';
import 'search_suggester.dart';
import 'smart_search_engine.dart';

/// Languages the AI layer answers in; anything else falls back to `en`.
const kAiLanguages = {'ru', 'uz', 'en'};

/// Upper bound on history sent upstream — a long transcript is the whole cost
/// of a chat turn.
const _kMaxChatMessages = 8;
const _kMaxChatMessageChars = 1500;
const _kChatMaxTokens = 700;

/// Registers the AI routes on [router] (plan Part 0), same shape as
/// `mountAdminRoutes`.
void mountAiRoutes(
  Router router,
  Store store, {
  OpenAiClient? openAiClient,
  AiQuota? quota,
}) {
  final client = openAiClient ?? OpenAiClient();
  final aiQuota = quota ?? AiQuota(store);
  final searchEngine = SmartSearchEngine();
  final suggester = SmartSearchSuggester();
  final scoringEngine = LeadScoringEngine();
  final crmQueryEngine = CrmQueryEngine(scoringEngine);
  final readinessEngine = ReadinessEngine();

  // Plan: "Run scoring on lead create, on status change" — store.dart has no
  // dependency on ai/, so it calls back through this injected hook.
  store.aiLeadScorer = (lead, s) => scoringEngine.score(lead, s);

  // --- b2c consultant chat --------------------------------------------------

  /// `POST /v1/ai/chat` — public (anonymous allowed), quota-limited per IP and,
  /// when a Bearer token is present, per user.
  ///
  /// Request: `{messages: [{role: "user"|"assistant", content: string}],
  /// user_language: "ru"|"uz"|"en"}`. History is capped to the last
  /// [_kMaxChatMessages] entries, [_kMaxChatMessageChars] characters each.
  ///
  /// Response: `{reply: string, quota: {used, limit, remaining, resetAt}}`.
  router.post('/v1/ai/chat', (Request req) async {
    // Checked before the quota so a misconfigured server never burns a budget.
    if (!client.isConfigured) {
      return _aiUnavailable();
    }

    final body = await req.readJson();
    final rawMessages = body['messages'];
    if (rawMessages is! List || rawMessages.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'messages must be a non-empty array',
        status: 422,
      );
    }

    final messages = <AiMessage>[];
    for (final entry in rawMessages) {
      if (entry is! Map) {
        return jsonError(
          'VALIDATION_ERROR',
          'each message must be an object with role and content',
          status: 422,
        );
      }
      final role = (entry['role'] as String?)?.trim();
      final content = (entry['content'] as String?)?.trim();
      if (role != 'user' && role != 'assistant') {
        return jsonError(
          'VALIDATION_ERROR',
          'message role must be user or assistant',
          status: 422,
        );
      }
      if (content == null || content.isEmpty) {
        return jsonError(
          'VALIDATION_ERROR',
          'message content is required',
          status: 422,
        );
      }
      messages.add(
        AiMessage(role: role!, content: _cap(content, _kMaxChatMessageChars)),
      );
    }
    if (messages.last.role != 'user') {
      return jsonError(
        'VALIDATION_ERROR',
        'the last message must be from the user',
        status: 422,
      );
    }
    final capped = messages.length > _kMaxChatMessages
        ? messages.sublist(messages.length - _kMaxChatMessages)
        : messages;

    final language = normalizeAiLanguage(body['user_language']);
    final userId = req.auth?.userId;

    final decision = await aiQuota.check(
      req,
      kind: AiQuotaKind.chat,
      userId: userId,
    );
    if (!decision.allowed) return _rateLimited(decision);

    final String reply;
    try {
      reply = await client.complete(
        systemPrompt: '$kConsultantPrompt\nuser_language: $language',
        messages: capped,
        maxTokens: _kChatMaxTokens,
      );
    } on AiUnavailableException catch (error) {
      // Not the caller's fault — do not charge the quota.
      return _aiUnavailable(error.message);
    }

    final charged = await aiQuota.consume(
      req,
      kind: AiQuotaKind.chat,
      userId: userId,
    );
    return jsonOk({
      'reply': sanitizeProviderMentions(reply),
      'quota': charged.toJson(),
    });
  });

  /// `GET /v1/ai/chat/quota` — read-only; never consumes. Feeds the `(i)` info
  /// sheet. Response: `{used, limit, remaining, resetAt}`.
  router.get('/v1/ai/chat/quota', (Request req) async {
    final snapshot = await aiQuota.peek(
      req,
      kind: AiQuotaKind.chat,
      userId: req.auth?.userId,
    );
    return jsonOk({
      ...snapshot.toJson(),
      'available': client.isConfigured && snapshot.allowed,
    });
  });

  // --- Seams for the engines built in the next phase ------------------------

  /// `POST /v1/ai/search` — deterministic smart search (no upstream call),
  /// public, quota kind `search` (`AI_SEARCH_HOURLY_LIMIT`, default 60/h).
  /// Replaces the removed b2c filter sheet.
  ///
  /// Request:
  /// ```json
  /// {
  ///   "query": "2 комнатная в Юнусабаде до 60000$",  // required, <= 300 chars
  ///   "user_language": "ru" | "uz" | "en",           // default "en"
  ///   "constraints": { /* same field names as the response `constraints`  */ },
  ///   "limit": 20                                    // 1..50, default 20
  /// }
  /// ```
  /// `constraints` is optional and overrides the parser field by field — that
  /// is how removing a chip re-runs the search without re-parsing the text.
  ///
  /// Response `data`:
  /// ```json
  /// {
  ///   "steps": [{"code": "parsing", "params": {"constraintCount": 3}}],
  ///   "results": [{ /* result object, see below */ }],
  ///   "constraints": { /* parsed constraints, see below */ },
  ///   "totals": {
  ///     "projectsScanned": 12, "projectsMatched": 4,
  ///     "unitsScanned": 340, "unitsMatched": 18,
  ///     "bookedFiltered": 6, "returned": 18, "elapsedMs": 41
  ///   },
  ///   "understood": true,
  ///   "blocked": false,
  ///   "suggestions": [{ /* see below */ }],
  ///   "unknownTerms": ["якк"]
  /// }
  /// ```
  ///
  /// `understood` is true when at least one real constraint was parsed.
  /// `blocked` is true when the catalogue was deliberately **not** traversed —
  /// see "the query made no sense" below. `unknownTerms` are the tokens with
  /// neither a dictionary hit nor a suggestion, and always equal
  /// `constraints.unrecognized`.
  ///
  /// `suggestions[]` — "did you mean" candidates, at most 5, confidence
  /// descending:
  /// ```json
  /// {
  ///   "term": "двушка",              // the raw token, lower-cased
  ///   "suggestion": "2-комнатная",   // replacement in `user_language`
  ///   "query": "2-комнатная квартира в Чиланзаре",  // resubmit verbatim
  ///   "kind": "rooms",               // rooms | district | dealType |
  ///                                  // unitKind | price | area | floor |
  ///                                  // amenity | status | developer | project
  ///   "confidence": 0.92             // 0..1
  /// }
  /// ```
  /// `query` is the request's own `query` with the first occurrence of `term`
  /// swapped for `suggestion`, ready to POST back unchanged. The one exception
  /// is `kind: "amenity"` raised by `softenedAmenity`: there is no better
  /// spelling to offer, so `query` is the same query with the amenity dropped
  /// — "search without it" rather than "did you mean".
  ///
  /// **The query made no sense.** When nothing at all parsed
  /// (`constraints.constraintCount == 0`) but the query did contain words —
  /// tokens that survive stopword removal and are at least three characters —
  /// the catalogue is not scanned at all: `blocked: true`,
  /// `understood: false`, `results: []`, every `totals` counter `0` except
  /// `elapsedMs`, and `steps` is just `parsing`, any `autocorrected`, and
  /// `noMatchIntent`. Show the suggestions ("Вы имели в виду …?") instead of a
  /// result count. A request carrying `constraints` (a chip re-run) is never
  /// blocked, and an empty query is still a 422 `VALIDATION_ERROR`.
  ///
  /// `steps[].code` is one of, in this order, each emitted at most once except
  /// `autocorrected` / `softenedAmenity` (once per word) and `openingProject`
  /// / `scanningUnits` (once per matched project):
  ///
  /// | code | params |
  /// |---|---|
  /// | `parsing` | `{constraintCount: int}` |
  /// | `autocorrected` | `{from: string, to: string}` |
  /// | `noMatchIntent` | `{terms: string[]}` |
  /// | `softenedAmenity` | `{amenity: string}` |
  /// | `lowConfidence` | `{terms: string[], count: int}` |
  /// | `scanningDistrict` | `{district: string, projectsScanned: int}` |
  /// | `foundInDistrict` | `{district: string, count: int}` |
  /// | `openingProject` | `{project: string, index: int, total: int}` |
  /// | `scanningUnits` | `{project: string, count: int}` |
  /// | `filteringBooked` | `{removed: int, left: int}` |
  /// | `rankingPrice` | `{count: int}` |
  /// | `done` | `{count: int, elapsedMs: int}` |
  ///
  /// `autocorrected` says a typo or a keyboard-layout slip was read as
  /// something else ("read `rdfhnbhf` as `квартира`"); `softenedAmenity` says
  /// no published project offers that amenity, so it was demoted from filter
  /// to ranking preference — the UI can say "no listings with X, showing the
  /// closest matches"; `lowConfidence` lists the words that only produced a
  /// suggestion. When the query names no district, `scanningDistrict` /
  /// `foundInDistrict` are omitted. Params carry real traversal counts only —
  /// never prose; the client renders localized text from ARB.
  ///
  /// `results[]` (one per unit, ranked):
  /// ```json
  /// {
  ///   "unitId": "u-1", "projectId": "p-1", "projectName": "Ideal City",
  ///   "buildingId": "b-1", "district": "Yunusabad",
  ///   "coverUrl": "https://…",           // nullable
  ///   "number": "42",
  ///   "kind": "apartment" | "commercial" | "parking",
  ///   "dealType": "sale" | "rent",
  ///   "status": "available" | "booked" | "sold",
  ///   "isOffplan": true,
  ///   "rooms": 2,                          // nullable
  ///   "floor": 7,                          // nullable
  ///   "floorsTotal": 16,                   // nullable
  ///   "areaTotal": 62.5,
  ///   "price": 58000,                      // sale price; null for rent-only
  ///   "priceM2": 928,                      // nullable
  ///   "rentMonthly": null,                 // set when dealType == "rent"
  ///   "projectStatus": "under_construction",
  ///   "constructionProgress": 68,          // nullable
  ///   "plannedProgress": 75,               // nullable
  ///   "trustIndex": 0.9,                   // progress / plannedProgress, nullable
  ///   "matchScore": 87,                    // 0..100
  ///   "matchReasons": ["priceFit", "roomsMatch"]
  /// }
  /// ```
  ///
  /// `matchReasons[]` codes: `districtMatch`, `roomsMatch`, `priceFit`,
  /// `priceBelowBudget`, `budgetPreference`, `premiumPreference`, `areaFit`,
  /// `areaPreference`, `floorPreference`, `dealTypeMatch`, `kindMatch`,
  /// `availableNow`, `amenityMatch`, `developerMatch`, `projectMatch`,
  /// `highTrustIndex`, `readySoon`, `offplanDiscount`.
  ///
  /// `constraints` (parsed; every field nullable, absent == not constrained):
  /// ```json
  /// {
  ///   "rooms": [2, 3],
  ///   "priceMin": null, "priceMax": 60000, "currency": "USD" | "UZS",
  ///   "areaMin": 55, "areaMax": null,
  ///   "district": "Yunusabad",
  ///   "dealType": "sale" | "rent",
  ///   "unitKind": "apartment" | "commercial" | "parking",
  ///   "projectStatus": "planned" | "under_construction" | "ready" | "handed_over",
  ///   "isOffplan": true,
  ///   "floorMin": 5, "floorMax": null,
  ///   "notFirstFloor": true, "notLastFloor": false, "excludeFloors": [2],
  ///   "availableOnly": true,
  ///   "amenities": ["parking"],
  ///   "excludedAmenities": ["renovation"],
  ///   "softAmenities": ["pool"],
  ///   "pricePreference": "cheap" | "premium" | null,
  ///   "areaPreference": "large" | "small" | null,
  ///   "floorPreference": "high" | "low" | "mid" | null,
  ///   "developerName": null, "projectName": null,
  ///   "unrecognized": ["якк"]
  /// }
  /// ```
  /// `amenities` filter; `softAmenities` (nothing in the catalogue offers
  /// them) and the three `*Preference` wishes — `недорого`, `просторная`,
  /// `высокий этаж` and their uz/en equivalents — only rank. All of them are
  /// chips the client may drop and re-send through `constraints`.
  ///
  /// `excludedAmenities` — amenities the query explicitly rejected («без
  /// ремонта», «mebelsiz», «without parking», «no furniture»). Same canonical
  /// id vocabulary as `amenities`; a unit whose project offers an excluded
  /// amenity is filtered out. Round-trips through the `constraints` override
  /// exactly like `amenities` and counts toward `constraintCount`, so a pure
  /// «без ремонта» query is understood, not blocked.
  ///
  /// Field names match `DiscoveryFilters` semantics in b2c so the chips can be
  /// written straight back into it (`rooms`, `minPrice`/`maxPrice` ←
  /// `priceMin`/`priceMax`, `districts` ← `district`, `status` ←
  /// `projectStatus`, `areaMin`, `offplanOnly` ← `isOffplan`).
  router.post('/v1/ai/search', (Request req) async {
    final body = await req.readJson();
    final query = (body['query'] as String?)?.trim() ?? '';
    final constraintsOverride = body['constraints'];
    if (query.isEmpty && constraintsOverride == null) {
      return jsonError('VALIDATION_ERROR', 'query is required', status: 422);
    }
    if (query.length > 300) {
      return jsonError(
        'VALIDATION_ERROR',
        'query must be at most 300 characters',
        status: 422,
      );
    }
    final limitRaw = body['limit'];
    final limit = limitRaw is num ? limitRaw.toInt() : 20;
    if (limit < 1 || limit > 50) {
      return jsonError(
        'VALIDATION_ERROR',
        'limit must be between 1 and 50',
        status: 422,
      );
    }

    final decision = await aiQuota.check(
      req,
      kind: AiQuotaKind.search,
      userId: req.auth?.userId,
    );
    if (!decision.allowed) return _rateLimited(decision);

    final data = searchEngine.run(
      store,
      query: query,
      language: normalizeAiLanguage(body['user_language']),
      constraintsOverride: constraintsOverride is Map<String, dynamic>
          ? constraintsOverride
          : null,
      limit: limit,
    );

    await aiQuota.consume(
      req,
      kind: AiQuotaKind.search,
      userId: req.auth?.userId,
    );
    return jsonOk(data);
  });

  /// `POST /v1/ai/search/suggest` — inline autocomplete for the search field.
  /// Public, no upstream call, **no quota**: it is meant to be called on every
  /// keystroke behind a client-side debounce and answers in single-digit
  /// milliseconds (only the generic per-IP rate limiter applies).
  ///
  /// Request:
  /// ```json
  /// {
  ///   "query": "Нужна квартира в цен",   // required, <= 300 chars
  ///   "user_language": "ru" | "uz" | "en",  // default "ru"
  ///   "limit": 6                            // 1..20, default 6
  /// }
  /// ```
  ///
  /// Response `data`:
  /// ```json
  /// {
  ///   "completion": "тре Ташкента",
  ///   "completionFull": "Нужна квартира в центре Ташкента",
  ///   "suggestions": [
  ///     {"text": "Нужна квартира в Чиланзаре", "tail": " Чиланзаре",
  ///      "kind": "district", "score": 0.9}
  ///   ]
  /// }
  /// ```
  ///
  /// `completion` is the tail to append to `query` **verbatim** — it may start
  /// with a space, and `query + completion == completionFull`. Render it as
  /// ghost text after the caret and commit it on Tab. Both are `null` when
  /// there is nothing confident to offer (including any query shorter than
  /// three characters, which also returns `suggestions: []`).
  ///
  /// `suggestions[]` are the ranked alternatives for a dropdown, at most
  /// `limit` of them; each carries its own `tail`, the already-joined `text`,
  /// the `kind` it would constrain (same domain as `suggestions[].kind` on
  /// `POST /v1/ai/search`) and a 0..1 `score`.
  ///
  /// Two completion modes, chosen automatically:
  ///
  /// 1. **Prefix** — the query stops mid-word and that word is the start of
  ///    exactly one (or one clearly dominant) known phrase:
  ///    `"квартира в цен"` → `"тре Ташкента"`. An ALL-CAPS prefix completes in
  ///    caps.
  /// 2. **Next clause** — the query already has two whole words and the last
  ///    one is finished, so the guess is what the query is still missing, in
  ///    the order district → rooms → budget → deal type → status:
  ///    `"Нужна квартира"` → `" в Чиланзаре"`,
  ///    `"2-комнатная в Юнусабаде"` → `" до 90 000 $"`. A dangling preposition
  ///    is not doubled: `"квартира в "` → `"Чиланзаре"`.
  ///
  /// Nothing already present in the query is offered again (no second district
  /// once one is parsed), and only districts, projects and developers that
  /// actually exist in the catalogue — best-stocked first — are suggested, so
  /// accepting a completion cannot lead to an empty result page.
  router.post('/v1/ai/search/suggest', (Request req) async {
    final body = await req.readJson();
    final query = (body['query'] as String?) ?? '';
    if (query.length > 300) {
      return jsonError(
        'VALIDATION_ERROR',
        'query must be at most 300 characters',
        status: 422,
      );
    }
    final limitRaw = body['limit'];
    final limit = limitRaw is num ? limitRaw.toInt() : 6;
    if (limit < 1 || limit > 20) {
      return jsonError(
        'VALIDATION_ERROR',
        'limit must be between 1 and 20',
        status: 422,
      );
    }
    // Unlike the rest of the AI layer this one defaults to ru: it is only ever
    // called from the b2c search field, whose default locale is ru.
    final languageRaw = (body['user_language'] as String?)?.trim();
    final language = languageRaw == null || languageRaw.isEmpty
        ? 'ru'
        : normalizeAiLanguage(languageRaw);

    return jsonOk(
      suggester.suggest(store, query: query, language: language, limit: limit),
    );
  });

  /// `GET /v1/ai/crm/leads` — computed lead scoring for the b2b CRM panel.
  /// Admin auth required (system admin sees all; residence admin only their own
  /// projects → 403 otherwise). No upstream call.
  ///
  /// Query: `?projectId=<id>&band=hot|warm|cold&owner=me|unassigned|<userId>`
  /// `&limit=<1..100, default 20>`.
  ///
  /// Response `data`:
  /// ```json
  /// {
  ///   "leads": [{
  ///     "id": "lead-1", "number": "LD-100242",
  ///     "projectId": "p-1", "projectName": "Ideal City",
  ///     "unitId": null, "unitLabel": null,
  ///     "intent": "viewing", "subject": "project", "status": "new",
  ///     "contactPhone": "+998…", "message": "…",
  ///     "preferredAt": null, "createdAt": "2026-08-12T10:00:00.000Z",
  ///     "lastContactAt": null, "ownerUserId": null, "assignedManager": null,
  ///     "score": null,                 // manual human override, always wins in UI
  ///     "aiScore": 82,                 // 0..100
  ///     "aiBand": "hot" | "warm" | "cold",
  ///     "aiReasons": ["slaBreach", "specificUnit"],
  ///     "aiScoredAt": "2026-08-12T10:00:01.000Z"
  ///   }],
  ///   "metrics": { /* see below */ }
  /// }
  /// ```
  ///
  /// `aiReasons[]` codes: `highIntent`, `viewingRequested`, `specificUnit`,
  /// `preferredTimeSet`, `longMessage`, `mortgageInterest`, `cashBuyer`,
  /// `urgentKeyword`, `repeatContact`, `recentActivity`, `noResponse24h`,
  /// `noResponse3d`, `slaBreach`, `funnelAdvanced`, `stalled`, `hotProject`,
  /// `unitScarcity`, `offplanInterest`, `rentIntent`, `lowSpecificity`.
  ///
  /// `metrics`:
  /// ```json
  /// {
  ///   "leadVolume": {"today": 4, "week": 21, "month": 78,
  ///                  "planCap": 100, "usedPercent": 78.0},
  ///   "byBand": {"hot": 6, "warm": 12, "cold": 30},
  ///   "perManager": [{"userId": "u-1", "name": "Aziz",
  ///                   "openLeads": 9, "hotLeads": 2,
  ///                   "avgResponseMinutes": 43.5}],
  ///   "responseSla": {"targetMinutes": 120, "medianMinutes": 55.0,
  ///                   "breachedCount": 3, "breachedPercent": 6.2},
  ///   "funnel": {"new": 8, "contacted": 14, "scheduled": 5, "visited": 3,
  ///              "qualified": 2, "won": 1, "lost": 4},
  ///   "conversion": [{"from": "new", "to": "contacted", "rate": 0.64}]
  /// }
  /// ```
  /// `conversion` covers the consecutive pairs `new→contacted`,
  /// `contacted→scheduled`, `scheduled→visited`, `visited→qualified`,
  /// `qualified→won`; `rate` is 0..1.
  router.get('/v1/ai/crm/leads', (Request req) {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isAdmin) {
      return jsonError('FORBIDDEN', 'Admin access required', status: 403);
    }

    final scope = _adminScope(store, auth);
    var leads = scope.leads;

    final qp = req.url.queryParameters;
    final projectIdFilter = qp['projectId'];
    if (projectIdFilter != null && projectIdFilter.isNotEmpty) {
      if (!scope.projects.any((p) => p['id'] == projectIdFilter)) {
        return jsonError('FORBIDDEN', 'Not your project', status: 403);
      }
      leads = leads.where((l) => l['projectId'] == projectIdFilter).toList();
    }
    // Score-on-create/status-change already keeps `aiScore` current for
    // every lead the store hands out; a null score only happens for legacy
    // rows from before this feature — score those lazily now.
    for (final lead in leads) {
      if (lead['aiScore'] == null) scoringEngine.score(lead, store);
    }
    final bandFilter = qp['band'];
    if (bandFilter != null && bandFilter.isNotEmpty) {
      leads = leads.where((l) => l['aiBand'] == bandFilter).toList();
    }
    leads = store.filterLeadsByOwner(
      leads,
      ownerFilter: qp['owner'],
      currentUserId: auth.userId,
    );

    final metrics = scoringEngine.metrics(scope.leads, store);

    final limitRaw = int.tryParse(qp['limit'] ?? '') ?? 20;
    final limit = limitRaw < 1 ? 1 : (limitRaw > 100 ? 100 : limitRaw);
    return jsonOk({'leads': leads.take(limit).toList(), 'metrics': metrics});
  });

  /// `POST /v1/ai/crm/query` — the guided b2b assistant. Not free chat: the
  /// client posts a node id and gets back the next options. Admin auth
  /// required. No upstream call.
  ///
  /// Request: `{node: string, params: {…}, user_language: "ru"|"uz"|"en"}`.
  /// `node` is `root` on open; afterwards it is the `id` of the option tapped.
  /// `params` is that option's `params` echoed back (e.g. `{"projectId": "p-1"}`).
  ///
  /// Node ids: `root`, `hotLeads`, `byProject`, `byImportance`, `todaySummary`,
  /// `whatNext`, `projectMenu`, `projectHot`, `projectNoResponse48h`,
  /// `projectNewToday`, `projectFunnel`.
  ///
  /// Response `data`:
  /// ```json
  /// {
  ///   "node": "hotLeads",
  ///   "messageCode": "crmBot.hotLeads.message",
  ///   "messageParams": {"count": 6},
  ///   "options": [{"id": "byProject", "labelCode": "crmBot.option.byProject",
  ///                "labelParams": {}, "params": {}}],
  ///   "cards": [{ /* see below */ }],
  ///   "breadcrumb": [{"node": "root", "labelCode": "crmBot.node.root",
  ///                   "labelParams": {}}]
  /// }
  /// ```
  /// An option's `id` doubles as the next `node` to post; `params` must be sent
  /// back verbatim. All display text is a code + params — the b2b ARB files own
  /// the wording in ru/uz/en.
  ///
  /// `cards[]` is one of three shapes, discriminated by `type`:
  /// ```json
  /// {"type": "lead", "leadId": "lead-1", "number": "LD-100242",
  ///  "projectName": "Ideal City", "contactPhone": "+998…",
  ///  "status": "new", "createdAt": "…", "aiScore": 82, "aiBand": "hot",
  ///  "aiReasons": ["slaBreach"],
  ///  "actions": ["openLead", "assignToMe", "markContacted"]}
  ///
  /// {"type": "metric", "metricCode": "crmBot.metric.responseSla",
  ///  "metricParams": {"medianMinutes": 55}, "value": 55, "unit": "minutes",
  ///  "trend": "up" | "down" | "flat"}
  ///
  /// {"type": "project", "projectId": "p-1", "projectName": "Ideal City",
  ///  "hotLeads": 3, "openLeads": 9, "availableUnits": 42}
  /// ```
  router.post('/v1/ai/crm/query', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isAdmin) {
      return jsonError('FORBIDDEN', 'Admin access required', status: 403);
    }

    final body = await req.readJson();
    final node = (body['node'] as String?)?.trim().isNotEmpty == true
        ? (body['node'] as String).trim()
        : 'root';
    if (!crmQueryEngine.isValidNode(node)) {
      return jsonError('VALIDATION_ERROR', 'Unknown node "$node"', status: 422);
    }
    final params = body['params'];

    final scope = _adminScope(store, auth);
    // Every lead in scope keeps a current score for the option-tree cards too.
    for (final lead in scope.leads) {
      if (lead['aiScore'] == null) scoringEngine.score(lead, store);
    }

    final data = crmQueryEngine.handle(
      node: node,
      params: params is Map<String, dynamic> ? params : const {},
      leadsInScope: scope.leads,
      projectsInScope: scope.projects,
      store: store,
    );
    return jsonOk(data);
  });

  // --- b2b free-form admin assistant ----------------------------------------

  /// `POST /v1/ai/b2b/chat` — free-form chat for B2B admins (system admin:
  /// platform-wide; residence admin: their own developer's projects only).
  /// Unlike `POST /v1/ai/crm/query` above (a fixed option tree), this is an
  /// actual LLM conversation: the caller's own authorization-scoped data
  /// (their projects, lead funnel metrics, and current hot leads — computed
  /// server-side via [_adminScope]/[_b2bDataDigest], never the raw store) is
  /// summarized into a compact JSON digest and appended to
  /// [kB2bAssistantPrompt] at request time, so the model can answer with real
  /// numbers without ever being handed direct database access. Admin auth
  /// required (401 `UNAUTHENTICATED`, 403 `FORBIDDEN`). Quota kind `b2bChat`
  /// (`AI_B2B_CHAT_DAILY_LIMIT`, default 30/day) — a separate, higher budget
  /// than the b2c `chat` kind's 5/day, keyed per authenticated admin (this
  /// route is never anonymous).
  ///
  /// Request: `{messages: [{role: "user"|"assistant", content: string}],
  /// user_language: "ru"|"uz"|"en"}` — validated exactly like
  /// `POST /v1/ai/chat` above: `messages` must be a non-empty array, each
  /// `role` must be `user`/`assistant`, each `content` is required, the last
  /// message must be from the user, and history is capped to the last
  /// [_kMaxChatMessages] entries of [_kMaxChatMessageChars] characters each.
  ///
  /// Response: `{reply: string, quota: {used, limit, remaining, resetAt}}` —
  /// same shape as `POST /v1/ai/chat`. `reply` is plain conversational text
  /// for a chat bubble, never JSON; the data digest itself is never returned
  /// to the client, only the model's prose answer derived from it.
  router.post('/v1/ai/b2b/chat', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isAdmin) {
      return jsonError('FORBIDDEN', 'Admin access required', status: 403);
    }

    // Checked before the quota so a misconfigured server never burns a budget.
    if (!client.isConfigured) {
      return _aiUnavailable();
    }

    final body = await req.readJson();
    final rawMessages = body['messages'];
    if (rawMessages is! List || rawMessages.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'messages must be a non-empty array',
        status: 422,
      );
    }

    final messages = <AiMessage>[];
    for (final entry in rawMessages) {
      if (entry is! Map) {
        return jsonError(
          'VALIDATION_ERROR',
          'each message must be an object with role and content',
          status: 422,
        );
      }
      final role = (entry['role'] as String?)?.trim();
      final content = (entry['content'] as String?)?.trim();
      if (role != 'user' && role != 'assistant') {
        return jsonError(
          'VALIDATION_ERROR',
          'message role must be user or assistant',
          status: 422,
        );
      }
      if (content == null || content.isEmpty) {
        return jsonError(
          'VALIDATION_ERROR',
          'message content is required',
          status: 422,
        );
      }
      messages.add(
        AiMessage(role: role!, content: _cap(content, _kMaxChatMessageChars)),
      );
    }
    if (messages.last.role != 'user') {
      return jsonError(
        'VALIDATION_ERROR',
        'the last message must be from the user',
        status: 422,
      );
    }
    final capped = messages.length > _kMaxChatMessages
        ? messages.sublist(messages.length - _kMaxChatMessages)
        : messages;

    final language = normalizeAiLanguage(body['user_language']);

    final decision = await aiQuota.check(
      req,
      kind: AiQuotaKind.b2bChat,
      userId: auth.userId,
    );
    if (!decision.allowed) return _rateLimited(decision);

    final scope = _adminScope(store, auth);
    final digest = _b2bDataDigest(store, auth, scope, scoringEngine);

    final String reply;
    try {
      reply = await client.complete(
        systemPrompt:
            '$kB2bAssistantPrompt\nuser_language: $language\n\n'
            "# LIVE DATA (JSON, this caller's authorized scope only)\n"
            '${jsonEncode(digest)}',
        messages: capped,
        maxTokens: _kChatMaxTokens,
      );
    } on AiUnavailableException catch (error) {
      // Not the caller's fault — do not charge the quota.
      return _aiUnavailable(error.message);
    }

    final charged = await aiQuota.consume(
      req,
      kind: AiQuotaKind.b2bChat,
      userId: auth.userId,
    );
    return jsonOk({
      'reply': sanitizeProviderMentions(reply),
      'quota': charged.toJson(),
    });
  });

  /// `GET /v1/ai/b2b/chat/quota` — read-only; never consumes. Same shape and
  /// purpose as `GET /v1/ai/chat/quota` above, for the B2B assistant's own
  /// separate budget. Admin auth required (401 `UNAUTHENTICATED`, 403
  /// `FORBIDDEN`).
  ///
  /// Response: `{used, limit, remaining, resetAt, available}`.
  router.get('/v1/ai/b2b/chat/quota', (Request req) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    if (!auth.isAdmin) {
      return jsonError('FORBIDDEN', 'Admin access required', status: 403);
    }

    final snapshot = await aiQuota.peek(
      req,
      kind: AiQuotaKind.b2bChat,
      userId: auth.userId,
    );
    return jsonOk({
      ...snapshot.toJson(),
      'available': client.isConfigured && snapshot.allowed,
    });
  });

  /// `POST /v1/admin/projects/<id>/photo-reports/analyze` — construction
  /// readiness check, run before the photo report is published. Requires the
  /// same authorization as `POST /v1/admin/projects/<id>/photo-reports`
  /// (401 `UNAUTHENTICATED`, 404 `NOT_FOUND` for an unknown project, 403
  /// `FORBIDDEN` when the caller does not manage it). Quota kind `verify`.
  ///
  /// Request: `multipart/form-data` with a `file` part (same handling as the
  /// upload route), or JSON:
  /// ```json
  /// {
  ///   "imageBase64": "data:image/jpeg;base64,…",  // or "url" of an uploaded file
  ///   "url": "/v1/static/uploads/abc.jpg",
  ///   "declaredStage": "facade",
  ///   "buildingId": "b-1",
  ///   "progressPercent": 68,
  ///   "comment": "утеплённый фасад, 3 секция",   // explains a regression
  ///   "user_language": "ru"
  /// }
  /// ```
  /// `declaredStage` ∈ `earthworks`, `foundation`, `frame_floors`, `roofing`,
  /// `facade`, `utilities`, `interior_finishing`, `landscaping`.
  ///
  /// Response `data` is the verification schema verbatim (see
  /// [kVerificationPrompt]), with localization codes added alongside every
  /// free-text field so the client renders ru/uz/en without a model call:
  /// ```json
  /// {
  ///   "object_id": "p-1",
  ///   "report_id": "phr-…",            // pending id; the report is not saved yet
  ///   "user_language": "ru",
  ///   "stopped_at": "stage_3" | null,
  ///   "overall_status": "confirmed" | "discrepancy_found" |
  ///                     "violation_found" | "requires_manual_review",
  ///   "confidence": 82,                  // 0..100
  ///   "checks": [{
  ///     "stage": "stage_1",
  ///     "name": "Input validity",        // fixed English label
  ///     "status": "passed" | "failed" | "warning",
  ///     "finding": "…", "findingCode": "stage1.ok", "findingParams": {},
  ///     "evidence": "…", "evidenceCode": "stage1.evidence.exifDate",
  ///     "evidenceParams": {"takenAt": "2026-08-10"}
  ///   }],
  ///   "summary_for_buyer": "…",
  ///   "summaryCode": "summary.confirmed",
  ///   "summaryParams": {"detectedStage": "facade"},
  ///   "phash": "9f1c…",                  // stored on the report when published
  ///   "detected_stage": "facade",
  ///   "declared_stage": "facade"
  /// }
  /// ```
  /// Stages after a `failed` one are omitted from `checks` (never null), and
  /// `stopped_at` names the stage that stopped the run.
  ///
  /// Fixed English `name` per stage: `Input validity`, `Duplicate detection`,
  /// `Relevance and stage classification`, `Match against declared stage`,
  /// `Progress relative to previous report`,
  /// `Visual risk and violation indicators`, `Final verdict`.
  ///
  /// Codes the engine emits (`findingCode` / `evidenceCode` with their params);
  /// every stage may also return `stageN.insufficientData` with `{}` as a
  /// `warning` when the input cannot support the check:
  ///
  /// - **stage_1** `stage1.ok`, `stage1.imageUnreadable`,
  ///   `stage1.lowQuality {blur, exposure}`, `stage1.metadataMissing`,
  ///   `stage1.geotagMissing`, `stage1.geotagFarFromObject {distanceKm, radiusKm}`,
  ///   `stage1.dateInFuture {takenAt}`, `stage1.dateOutsideWindow {takenAt, windowDays}`.
  ///   Evidence: `stage1.evidence.decoded {width, height, bytes}`,
  ///   `stage1.evidence.exifDate {takenAt}`, `stage1.evidence.noExif`,
  ///   `stage1.evidence.geoDistance {distanceKm, radiusKm}`,
  ///   `stage1.evidence.sharpness {blur, threshold}`.
  /// - **stage_2** `stage2.ok`, `stage2.noPriorReports`,
  ///   `stage2.nearDuplicate {distance, reportId, takenAt}`,
  ///   `stage2.duplicateFound {distance, reportId, takenAt}`.
  ///   Evidence: `stage2.evidence.comparedCount {count}`,
  ///   `stage2.evidence.hammingDistance {distance, threshold, reportId}`.
  /// - **stage_3** `stage3.ok {stage, confidence}`,
  ///   `stage3.notConstructionSite {confidence}`,
  ///   `stage3.stageUnclear {confidence}`.
  ///   Evidence: `stage3.evidence.classified {stage, confidence}`,
  ///   `stage3.evidence.features {skyRatio, soilRatio, concreteRatio,
  ///   vegetationRatio, verticalEdgeDensity, openingPeriodicity}`.
  /// - **stage_4** `stage4.ok {declaredStage}`, `stage4.noDeclaredStage`,
  ///   `stage4.adjacentStageMismatch {declaredStage, detectedStage}`,
  ///   `stage4.stageMismatch {declaredStage, detectedStage, distance}`.
  ///   Evidence: `stage4.evidence.comparison {declaredStage, detectedStage,
  ///   ordinalDistance}`.
  /// - **stage_5** `stage5.ok {previousTakenAt}`, `stage5.noPreviousReport`,
  ///   `stage5.noVisibleProgress {distance, previousTakenAt}`,
  ///   `stage5.regressionDetected {previousStage, detectedStage}`,
  ///   `stage5.progressNotDeclared`.
  ///   Evidence: `stage5.evidence.similarity {distance, threshold,
  ///   previousReportId, previousTakenAt}`,
  ///   `stage5.evidence.progressDelta {previousPercent, currentPercent}`,
  ///   `stage5.evidence.developerComment`.
  /// - **stage_6** `stage6.ok`, `stage6.safetyGearAbsent`,
  ///   `stage6.structuralDamage {ratio}`, `stage6.workStoppage`,
  ///   `stage6.debrisAccumulation {score}`,
  ///   `stage6.ambiguousIndicator {indicator}`.
  ///   Evidence: `stage6.evidence.hiVisRatio {ratio, threshold}`,
  ///   `stage6.evidence.crackPixels {ratio, threshold}`,
  ///   `stage6.evidence.noEquipment`, `stage6.evidence.debrisTexture {score}`.
  /// - **stage_7** `stage7.confirmed`, `stage7.manualReview {warnings}`,
  ///   `stage7.notReached {stoppedAt}`.
  ///   Evidence: `stage7.evidence.stageSummary {passed, warnings, failed}`.
  /// - **summary** `summary.confirmed {detectedStage, progressPercent}`,
  ///   `summary.manualReview {stage}`,
  ///   `summary.discrepancy {stage, declaredStage, detectedStage}`,
  ///   `summary.violation {stage, indicator}`.
  ///
  /// Confidence below 60 downgrades a `failed` stage to `warning` and forces
  /// `requires_manual_review`, per the reliability rules in the prompt.
  router.post('/v1/admin/projects/<id>/photo-reports/analyze', (
    Request req,
    String id,
  ) async {
    final auth = req.auth;
    if (auth == null) {
      return jsonError(
        'UNAUTHENTICATED',
        'Authentication required',
        status: 401,
      );
    }
    final project = store.projectById(id);
    if (project == null) {
      return jsonError('NOT_FOUND', 'Project $id not found', status: 404);
    }
    if (!_canManageProjectForAi(store, auth, project)) {
      return jsonError('FORBIDDEN', 'Not your project', status: 403);
    }

    String? declaredStage;
    String? buildingId;
    int? progressPercent;
    String? comment;
    String? userLanguageRaw;
    Uint8List? imageBytes;

    final contentType = req.headers['content-type'] ?? '';
    if (contentType.contains('multipart/form-data')) {
      final parts = await _readAiMultipartParts(req);
      final filePart = parts?.where((p) => p.filename != null).firstOrNull;
      if (filePart == null) {
        return jsonError('VALIDATION_ERROR', 'file is required', status: 422);
      }
      imageBytes = filePart.data;
      String? field(String name) {
        final part = parts!
            .where((p) => p.filename == null && p.name == name)
            .firstOrNull;
        return part == null ? null : utf8.decode(part.data);
      }

      declaredStage = field('declaredStage');
      buildingId = field('buildingId');
      final progressRaw = field('progressPercent');
      progressPercent = progressRaw == null ? null : int.tryParse(progressRaw);
      comment = field('comment');
      userLanguageRaw = field('user_language');
    } else {
      final body = await req.readJson();
      declaredStage = body['declaredStage'] as String?;
      buildingId = body['buildingId'] as String?;
      progressPercent = (body['progressPercent'] as num?)?.toInt();
      comment = body['comment'] as String?;
      userLanguageRaw = body['user_language'] as String?;
      final base64Raw = body['imageBase64'] as String?;
      final urlRaw = body['url'] as String?;
      if (base64Raw != null && base64Raw.isNotEmpty) {
        imageBytes = _decodeImageDataUrl(base64Raw);
      } else if (urlRaw != null && urlRaw.isNotEmpty) {
        imageBytes = await _readLocalUploadBytes(urlRaw);
      }
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      return jsonError(
        'VALIDATION_ERROR',
        'file, imageBase64, or a readable url is required',
        status: 422,
      );
    }
    if (declaredStage != null && !kDeclaredStages.contains(declaredStage)) {
      return jsonError(
        'VALIDATION_ERROR',
        'declaredStage must be one of ${kDeclaredStages.join(', ')}',
        status: 422,
      );
    }
    if (progressPercent != null &&
        (progressPercent < 0 || progressPercent > 100)) {
      return jsonError(
        'VALIDATION_ERROR',
        'progressPercent must be between 0 and 100',
        status: 422,
      );
    }

    final decision = await aiQuota.check(
      req,
      kind: AiQuotaKind.verify,
      userId: auth.userId,
    );
    if (!decision.allowed) return _rateLimited(decision);

    final priorReports = store
        .photoReportsForProject(id)
        .where((r) => r['phash'] != null)
        .map(_toPriorReport)
        .toList();
    final lastConfirmed = _lastConfirmedReport(store, id, buildingId);

    final result = await readinessEngine.analyze(
      imageBytes: imageBytes,
      objectId: id,
      reportId: 'phr-preview-${DateTime.now().microsecondsSinceEpoch}',
      userLanguage: normalizeAiLanguage(userLanguageRaw),
      declaredStage: declaredStage,
      buildingId: buildingId,
      progressPercent: progressPercent,
      comment: comment,
      projectLat: (project['lat'] as num?)?.toDouble(),
      projectLng: (project['lng'] as num?)?.toDouble(),
      priorReports: priorReports,
      lastConfirmedReport: lastConfirmed,
      visionClient: client,
    );

    await aiQuota.consume(req, kind: AiQuotaKind.verify, userId: auth.userId);
    return jsonOk(result.json);
  });
}

/// Mirrors `admin_routes.dart`'s private `_canManageProject` (same
/// authorization the existing photo-report upload route uses) — duplicated
/// rather than exported to keep the two route files independent.
bool _canManageProjectForAi(Store store, AuthContext auth, Map project) {
  if (auth.isSystemAdmin) return true;
  if (!auth.isResidenceAdmin) return false;
  return store.ownsProject(auth.userId, project);
}

/// Leads/projects a caller may see on the CRM routes: system admin gets
/// everything, residence admin only their own developer's projects.
class _AdminScope {
  const _AdminScope(this.leads, this.projects);
  final List<Map<String, dynamic>> leads;
  final List<Map<String, dynamic>> projects;
}

_AdminScope _adminScope(Store store, AuthContext auth) {
  if (auth.isSystemAdmin) {
    return _AdminScope(store.leads, store.projects);
  }
  final projects = store.projectsForDeveloperOwner(auth.userId);
  final projectIds = projects.map((p) => p['id']).toSet();
  final leads = store.leads
      .where((l) => projectIds.contains(l['projectId']))
      .toList();
  return _AdminScope(leads, projects);
}

/// Compact JSON-serializable snapshot of everything [auth] is authorized to
/// see ([scope]), appended to [kB2bAssistantPrompt] at request time so the
/// free-form B2B chat can answer with real numbers without direct database
/// access. Numeric/structural only — never a dump of every record, and never
/// a phone number or other raw contact PII — so both the token budget and the
/// leak surface of one chat turn stay bounded regardless of catalogue size.
Map<String, dynamic> _b2bDataDigest(
  Store store,
  AuthContext auth,
  _AdminScope scope,
  LeadScoringEngine scoringEngine,
) {
  const maxProjects = 30;
  const maxHotLeads = 5;

  // Every lead in scope keeps a current score for the digest too (mirrors the
  // lazy-score fallback already used by `GET /v1/ai/crm/leads` and
  // `POST /v1/ai/crm/query` above).
  for (final lead in scope.leads) {
    if (lead['aiScore'] == null) scoringEngine.score(lead, store);
  }
  final hotLeads = scope.leads.where((l) => l['aiBand'] == 'hot').toList()
    ..sort(
      (a, b) => ((b['aiScore'] as int?) ?? 0).compareTo(
        (a['aiScore'] as int?) ?? 0,
      ),
    );

  return {
    'role': auth.isSystemAdmin ? 'systemAdmin' : 'residenceAdmin',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'projectCount': scope.projects.length,
    'leadCount': scope.leads.length,
    'projects': scope.projects
        .take(maxProjects)
        .map((p) => _b2bProjectDigest(store, p))
        .toList(),
    'leadFunnel': scoringEngine.metrics(scope.leads, store),
    'hotLeads': hotLeads
        .take(maxHotLeads)
        .map(
          (l) => {
            'number': l['number'],
            'projectName': l['projectName'],
            'status': l['status'],
            'aiScore': l['aiScore'],
            'aiReasons': l['aiReasons'],
          },
        )
        .toList(),
  };
}

/// One project's entry in [_b2bDataDigest] — unit counts and readiness/photo
/// status only; no gallery, offers, or per-unit list.
Map<String, dynamic> _b2bProjectDigest(
  Store store,
  Map<String, dynamic> project,
) {
  final units = [
    for (final b in (project['buildings'] as List? ?? const []).cast<Map>())
      ...(b['units'] as List? ?? const []).cast<Map>(),
  ];
  final reports = store.photoReportsForProject(project['id'] as String);
  final lastReport = reports.isEmpty ? null : reports.first;
  return {
    'id': project['id'],
    'name': project['name'],
    'status': project['status'],
    'unitsTotal': project['totalUnits'],
    'unitsAvailable': project['availableUnits'],
    'unitsBooked': units.where((u) => u['status'] == 'booked').length,
    'unitsSold': units
        .where((u) => u['status'] == 'sold' || u['status'] == 'rented')
        .length,
    'constructionProgress': project['constructionProgress'],
    'plannedProgress': project['plannedProgress'],
    'lastVerifiedStage':
        lastReport?['declaredStage'] ?? lastReport?['detectedStage'],
    'lastPhotoReportStatus': lastReport?['verificationStatus'],
  };
}

PriorReport _toPriorReport(Map<String, dynamic> report) {
  Map<String, double>? features;
  final verification = report['verification'];
  if (verification is Map) {
    final checks = verification['checks'];
    if (checks is List) {
      for (final entry in checks) {
        if (entry is Map && entry['stage'] == 'stage_3') {
          final evidenceParams = entry['evidenceParams'];
          if (evidenceParams is Map) {
            features = evidenceParams.map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0),
            );
          }
        }
      }
    }
  }
  final takenAtRaw =
      report['exifTakenAt'] as String? ?? report['takenAt'] as String?;
  return PriorReport(
    id: report['id'] as String,
    phash: report['phash'] as String? ?? '',
    takenAt: takenAtRaw == null ? null : DateTime.tryParse(takenAtRaw),
    verificationStatus: report['verificationStatus'] as String?,
    declaredStage: report['declaredStage'] as String?,
    progressPercent: report['progressPercent'] as int?,
    featureVector: features,
  );
}

/// Most recent *confirmed* report for [projectId] (optionally scoped to
/// [buildingId]) — the stage_5 "previous report" baseline.
PriorReport? _lastConfirmedReport(
  Store store,
  String projectId,
  String? buildingId,
) {
  final candidates = store
      .photoReportsForProject(projectId)
      .where(
        (r) =>
            r['verificationStatus'] == 'confirmed' &&
            r['phash'] != null &&
            (buildingId == null || r['buildingId'] == buildingId),
      )
      .toList();
  if (candidates.isEmpty) return null;
  // photoReportsForProject already sorts newest `takenAt` first.
  return _toPriorReport(candidates.first);
}

Uint8List? _decodeImageDataUrl(String raw) {
  try {
    final comma = raw.indexOf(',');
    final b64 = raw.startsWith('data:') && comma >= 0
        ? raw.substring(comma + 1)
        : raw;
    return base64Decode(b64.trim());
  } catch (_) {
    return null;
  }
}

/// Reads bytes for a previously-uploaded file referenced by its own public
/// URL (`/v1/static/uploads/<file>` or `/v1/static/residences/<file>`) so a
/// caller can point `/analyze` at a photo it already uploaded. Anything else
/// (an external URL, a private/KYC path) is refused — this endpoint reads
/// local disk, not the network.
Future<Uint8List?> _readLocalUploadBytes(String url) async {
  final segments =
      Uri.tryParse(url)?.pathSegments ??
      url.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  final filename = segments.last;
  if (!isSafeUploadFilename(filename)) return null;
  final isResidence = segments.contains('residences');
  if (isResidence == false && !segments.contains('uploads')) return null;
  final dir = isResidence
      ? '${Directory.current.path}${Platform.pathSeparator}residences-images'
      : kUploadsRoot;
  final file = File('$dir${Platform.pathSeparator}$filename');
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _AiMultipartPart {
  _AiMultipartPart({required this.data, this.filename, this.name});
  final Uint8List data;
  final String? filename;
  final String? name;
}

/// Minimal multipart/form-data reader for this route only — mirrors
/// `admin_routes.dart`'s private parser (kept separate; each route file is
/// independently maintained).
Future<List<_AiMultipartPart>?> _readAiMultipartParts(Request req) async {
  final contentType = req.headers['content-type'] ?? '';
  final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
  if (boundaryMatch == null) return null;
  final boundary = boundaryMatch.group(1)!.trim();

  final declared = int.tryParse(req.headers['content-length'] ?? '');
  if (declared != null && declared > kMaxUploadBytes) {
    throw const PayloadTooLargeException('Upload exceeds the 15 MB limit');
  }

  final builder = BytesBuilder(copy: false);
  await for (final chunk in req.read()) {
    builder.add(chunk);
    if (builder.length > kMaxUploadBytes) {
      throw const PayloadTooLargeException('Upload exceeds the 15 MB limit');
    }
  }
  return _parseAiMultipart(builder.takeBytes(), boundary);
}

List<_AiMultipartPart> _parseAiMultipart(Uint8List body, String boundary) {
  final delimiter = utf8.encode('--$boundary');
  final parts = <_AiMultipartPart>[];
  var start = _indexOfBytes(body, delimiter, 0);
  while (start >= 0) {
    start += delimiter.length;
    if (start < body.length && body[start] == 45 && body[start + 1] == 45) {
      break; // closing --
    }
    if (start < body.length && body[start] == 13) start++;
    if (start < body.length && body[start] == 10) start++;
    final next = _indexOfBytes(body, delimiter, start);
    final end = next < 0 ? body.length : next - 2; // strip \r\n
    final chunk = body.sublist(start, end.clamp(0, body.length));
    final headerEnd = _indexOfBytes(chunk, utf8.encode('\r\n\r\n'), 0);
    if (headerEnd >= 0) {
      final headerText = utf8.decode(chunk.sublist(0, headerEnd));
      final data = chunk.sublist(headerEnd + 4);
      final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(headerText);
      final fileMatch = RegExp(r'filename="([^"]+)"').firstMatch(headerText);
      parts.add(
        _AiMultipartPart(
          data: data,
          name: nameMatch?.group(1),
          filename: fileMatch?.group(1),
        ),
      );
    }
    start = next;
  }
  return parts;
}

int _indexOfBytes(Uint8List haystack, List<int> needle, int from) {
  outer:
  for (var i = from; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// `ru` / `uz` / `en`; anything else (including null) becomes `en`.
String normalizeAiLanguage(Object? raw) {
  final code = (raw as String?)?.trim().toLowerCase();
  if (code == null || code.isEmpty) return 'en';
  final base = code.split(RegExp('[-_]')).first;
  return kAiLanguages.contains(base) ? base : 'en';
}

String _cap(String value, int max) =>
    value.length <= max ? value : value.substring(0, max);

Response _aiUnavailable([String? message]) => jsonError(
  'AI_UNAVAILABLE',
  message ?? 'AI is temporarily unavailable. Please try again later.',
  status: 503,
);

/// 429 with the reset both as a header (clients) and in the payload (UI copy).
Response _rateLimited(AiQuotaDecision decision) => jsonError(
  'RATE_LIMITED',
  'Daily AI limit reached. Please try again after the reset.',
  status: 429,
  extraHeaders: {'Retry-After': '${decision.retryAfterSeconds}'},
  data: {
    'used': decision.used,
    'limit': decision.limit,
    'remaining': decision.remaining,
    'resetAt': decision.resetAt.toIso8601String(),
    'blockedBy': decision.blockedBy,
  },
);
