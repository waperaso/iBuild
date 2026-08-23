<p align="center">
  <img src="DESIGN/ibuild-logo.jpg" alt="iBuild" width="96" height="96" style="border-radius: 12px">
</p>

<h1 align="center">iBuild</h1>

<p align="center">
  <strong>Construction verification platform for Uzbekistan</strong><br>
  <sub>Buyer storefront · developer admin · platform admin · shared API</sub>
</p>

<p align="center">
  <strong>English</strong> · <a href="README.ru.md">Русский</a> · <a href="README.uz.md">Oʻzbekcha</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/stack-Dart%20%7C%20PostgreSQL-002147" alt="Stack">
  <img src="https://img.shields.io/badge/market-Uzbekistan-14866d" alt="Market">
</p>

**Contents:** [Repository](#repository) · [Status](#status) · [Artificial intelligence](#artificial-intelligence) · [Code map](#code-map--verification-pipeline) · [Monitoring chain](#monitoring-chain-from-photo-to-the-agency) · [Buyer features](#buyer-features) · [Business features](#business-features)

---

## Repository

| Path | Role |
|---|---|
| [`b2c/`](b2c/) | Buyer app — map, search, chessboard, photo feed, AI search |
| [`b2b/`](b2b/) | Developer + platform admin — CRM, units, photo verification UI |
| [`server/`](server/) | Dart REST + WebSocket API, PostgreSQL, AI engines |
| [`packages/ibuild_core/`](packages/ibuild_core/) | Shared theme, widgets, domain models |

---

## Status

| Layer | Status |
|---|---|
| Smart search (own engine) | **live** |
| CRM lead scoring (own engine) | **live** |
| Photo verification engine (own engine — EXIF, geotag, hashes, stage) | **alpha** → [`readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) |
| GPT-vision overlay | **testing** — `AI_VISION_ENABLED=true` by default, active once `OPENAI_API_KEY` is set |
| Buyer / admin chat (optional adapter) | **planned** — built, routed, hidden behind `AI_CHAT_ENABLED=false` in both apps |
| Own construction-vision model | **planned** — labelled images collected; **model not trained yet** |
| Buyer marketplace (map, search, chessboard, photo feed) | **live** |
| Developer / platform admin (CRM, analytics, units) | **live** — inventory editor **refining** |

---

## Artificial intelligence

<table width="100%" cellspacing="0" cellpadding="0">
<tr>
<td width="6" bgcolor="#14866d"></td>
<td valign="top">
<table cellspacing="0" cellpadding="16">
<tr>
<td valign="top">

<table>
<tr>
<th align="left">Engine</th>
<th align="center">Calls an upstream model?</th>
<th align="left">Status</th>
<th align="left">Server code</th>
<th align="left">Client code</th>
</tr>
<tr>
<td><strong>Smart search</strong></td>
<td align="center">No</td>
<td><strong>live</strong></td>
<td><a href="server/lib/src/ai/smart_search_engine.dart"><code>smart_search_engine.dart</code></a>, <a href="server/lib/src/ai/search_dictionary.dart"><code>search_dictionary.dart</code></a>, <a href="server/lib/src/ai/search_suggester.dart"><code>search_suggester.dart</code></a></td>
<td><a href="b2c/lib/features/ai/"><code>b2c/lib/features/ai/</code></a></td>
</tr>
<tr>
<td><strong>CRM assistant</strong></td>
<td align="center">No</td>
<td><strong>live</strong></td>
<td><a href="server/lib/src/ai/lead_scoring_engine.dart"><code>lead_scoring_engine.dart</code></a></td>
<td><a href="b2b/lib/features/ai_crm/"><code>b2b/lib/features/ai_crm/</code></a></td>
</tr>
<tr>
<td><strong>Photo verification</strong></td>
<td align="center">Optional overlay only</td>
<td><strong>alpha</strong></td>
<td><a href="server/lib/src/ai/readiness_engine.dart"><code>readiness_engine.dart</code></a></td>
<td><a href="b2b/lib/features/residence/project_detail_readiness.dart"><code>project_detail_readiness.dart</code></a>, <a href="b2b/lib/features/residence/residence_site_photos.dart"><code>residence_site_photos.dart</code></a></td>
</tr>
<tr>
<td><strong>Buyer / admin chat</strong></td>
<td align="center">Yes, when enabled</td>
<td><strong>planned</strong>, UI hidden</td>
<td><a href="server/lib/src/ai/openai_client.dart"><code>openai_client.dart</code></a>, <a href="server/lib/src/ai/prompts.dart"><code>prompts.dart</code></a></td>
<td><a href="b2c/lib/features/ai/presentation/ai_chat_sheet.dart"><code>ai_chat_sheet.dart</code></a> — <code>AI_CHAT_ENABLED=false</code></td>
</tr>
</table>

<h3>Photo verification of the construction site · <strong>alpha</strong></h3>

<table>
<tr><td><strong>Engine</strong></td><td><a href="server/lib/src/ai/readiness_engine.dart"><code>server/lib/src/ai/readiness_engine.dart</code></a></td></tr>
<tr><td><strong>Tests</strong></td><td><a href="server/test/ai_readiness_engine_test.dart"><code>server/test/ai_readiness_engine_test.dart</code></a></td></tr>
<tr><td><strong>GPT-vision</strong> (testing)</td><td><a href="server/lib/src/ai/openai_client.dart"><code>openai_client.dart</code></a> + <a href="server/lib/src/ai/prompts.dart"><code>prompts.dart</code></a></td></tr>
<tr><td><strong>Schema</strong></td><td><a href="server/migrations/0019_ai.sql"><code>server/migrations/0019_ai.sql</code></a></td></tr>
<tr><td><strong>Flag</strong></td><td><code>AI_VISION_ENABLED=true</code> in <a href="server/.env.example"><code>server/.env.example</code></a> — active once <code>OPENAI_API_KEY</code> is set</td></tr>
</table>

**7 local stages:**

1. Input validity — decode image; EXIF date; geotag vs project coordinates. Missing EXIF/GPS does not block the upload, only raises a warning — metadata is not yet mandatory, relaxed on purpose for the current early-testing phase
2. Duplicate detection — perceptual hash vs prior reports
3. Stage classification — earthworks → landscaping
4. Declared vs detected stage
5. Progress vs previous confirmed report
6. Visual risk indicators (safety gear, cracks, debris)
7. Verdict — `confirmed` · `requires_manual_review` · `discrepancy_found` · `violation_found`

The engine runs from two routes: automatically and best-effort on every actual upload (`POST /v1/admin/projects/<id>/photo-reports`) — a failed check never blocks or fails the save — and on demand as a **preview** (`POST /v1/admin/projects/<id>/photo-reports/analyze`) an admin can call before deciding to publish: same 7 stages, nothing saved. A low-confidence classification downgrades a hard failure to a manual-review flag instead of a false-positive rejection.

**GPT-vision** (testing): the visual pass of the same verification pipeline. It compares follow-up photo B with baseline A and the declared plan — same viewpoint, what actually changed on site, and whether visible progress matches the claimed stage. Prompts: [`prompts.dart`](server/lib/src/ai/prompts.dart) and the [`construction_verify/`](server/lib/src/ai/prompts/construction_verify/) prompt pack.

<h3>Smart Search · <strong>live</strong> · no upstream model</h3>

Free-text queries in Russian, Uzbek, or English are parsed into structured constraints, catalogue units are ranked, and inline "ghost text" suggestions appear as you type.

**How it differs from typical search** ([details](AI_SEARCH_DIFFERENTIATORS.md)):

- Understands **negation** ("without parking", `mebelsiz`) — excludes, not includes
- **Blocks** queries it cannot parse — never pretends to understand
- Ranks with **trust index** (`constructionProgress / plannedProgress`) and named match reasons
- **Softens** impossible amenities instead of returning zero results
- Returns an execution **`steps`** trace the client can show

Files: [`smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart), [`search_dictionary.dart`](server/lib/src/ai/search_dictionary.dart), [`search_suggester.dart`](server/lib/src/ai/search_suggester.dart), tested in [`ai_smart_search_test.dart`](server/test/ai_smart_search_test.dart) · Client: [`b2c/lib/features/ai/`](b2c/lib/features/ai/)

<h3>CRM assistant · <strong>live</strong> · no upstream model</h3>

Every lead is scored hot / warm / cold from intent, message depth, SLA timers, inventory scarcity, and ru/uz/en keyword signals. The assistant itself is a **guided option tree**.

**CRM assistant functions** ([details](AI_CRM_DIFFERENTIATORS.md)):

- **Explainable** scoring with reason codes the client localizes
- Real-estate signals: unit scarcity, hot projects, repeat phone
- **SLA and silence** escalation (no response 24h / 3d, stuck status)
- **Demand vs available units** per project
- Auto-score never overwrites a manager's manual call — separate fields, so a human override survives every re-score

File: [`lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart), tested in [`ai_lead_scoring_test.dart`](server/test/ai_lead_scoring_test.dart) · Client: [`b2b/lib/features/ai_crm/`](b2b/lib/features/ai_crm/)

</td>
</tr>
</table>
</td>
</tr>
</table>

---

## Code map — verification pipeline

| What | Where |
|---|---|
| Photo verification engine (own, alpha) | [`server/lib/src/ai/readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) |
| Verification tests | [`server/test/ai_readiness_engine_test.dart`](server/test/ai_readiness_engine_test.dart) |
| Verdict schema in PostgreSQL | [`server/migrations/0019_ai.sql`](server/migrations/0019_ai.sql) |
| A→B vendor-call audit trail | [`server/migrations/0020_site_photo_cycles.sql`](server/migrations/0020_site_photo_cycles.sql) |
| Smart search engine (own, live) | [`server/lib/src/ai/smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart) |
| CRM lead scoring engine (own, live) | [`server/lib/src/ai/lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart) |
| Search + CRM tests | [`ai_smart_search_test.dart`](server/test/ai_smart_search_test.dart), [`ai_lead_scoring_test.dart`](server/test/ai_lead_scoring_test.dart) |
| All AI HTTP routes | [`server/lib/src/ai/ai_routes.dart`](server/lib/src/ai/ai_routes.dart) |
| GPT-vision overlay (on by default) + parked chat | [`server/lib/src/ai/openai_client.dart`](server/lib/src/ai/openai_client.dart) |
| Prompts for the adapter above | [`server/lib/src/ai/prompts.dart`](server/lib/src/ai/prompts.dart) |
| Env template — no keys | [`server/.env.example`](server/.env.example) |

---

## Monitoring chain: from photo to the agency

| Step | Stage | Status |
|:---:|---|---|
| 1 | Developer photo report — dated, with readiness %; geotag checked when present, not yet mandatory (early testing) | **live** |
| 2 | AI photo verification — geotag/metadata plus visual progress vs prior reports | **alpha** |
| 3 | "Needs clarification" flag — developer explains and re-shoots on mismatch | **alpha** |
| 4 | System alert — no valid reply or lag over threshold triggers a critical admin alert | **alpha** |
| 5 | Signal to the responsible agency | **planned** |
| 6 | Online observation center reviews the verification results — [Presidential Decree No. UP-104](https://lex.uz/ru/docs/8245277) of 4 June 2026 | **planned** |
| 7 | Result on the card — monitoring outcome published, affects the trust index | **planned** |

---

## Buyer features

| Feature | Status |
|---|---|
| Map and search with Buy / Rent / New-build filters | **live** |
| Live unit grid ("chessboard") for apartments and offices | **live** |
| One-tap request: viewing, call, hold, rent | **live** |
| Dated construction photo-report feed | **live** |
| Dual progress bars and trust index | **alpha** |
| Developer card with verified documents | **live** |
| Mortgage, installment, and rental-yield calculators | **alpha** |
| Favorites, saved searches, My requests, reviews, three languages | **alpha** |
| Push alerts on price and construction stages | **alpha** |
| Bank referral for mortgage/loan; voice matching (Newo AI) | **planned** |

---

## Business features

| Feature | Status |
|---|---|
| Projects, buildings, units, media library, floor plans | **live** (refining) |
| Chessboard editor with conflict-safe edits | **live** (refining) |
| Lead CRM: funnel, statuses, tags, event history | **live** |
| Photo reports and planned construction schedule entry | **alpha** |
| Analytics: demand, funnel, lead conversion | **live** |
| Developer verification, project/review moderation, audit log | **alpha** |
| Alerts, including critical schedule-deviation alerts | **alpha** |
| Subscription payment via bank transfer | **planned** |
| Bank reports and mortgage/loan referral leads | **planned** |

---

<p align="center">
  <sub>iBuild · © iBuild</sub>
</p>
