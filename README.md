<p align="center">
  <img src="DESIGN/ibuild-logo.jpg" alt="iBuild" width="96" height="96" style="border-radius: 12px">
</p>

<h1 align="center">iBuild</h1>

<p align="center">
  <strong>Independent digital system for monitoring, documenting, and verifying construction progress</strong><br>
  <sub>Независимая цифровая система мониторинга, документирования и верификации сведений о ходе строительства</sub>
</p>

<p align="center">
  <a href="#english">English</a> ·
  <a href="#русский">Русский</a> ·
  <a href="#oʻzbek">Oʻzbek</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/stack-Dart%20%7C%20PostgreSQL-002147" alt="Stack">
  <img src="https://img.shields.io/badge/market-Uzbekistan-14866d" alt="Market">
  <img src="https://img.shields.io/badge/stage-MVP-3366cc" alt="Stage">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/built%20with-Fable%205-0a1f35" alt="Fable 5">
  <img src="https://img.shields.io/badge/built%20with-Opus%204.8-0a1f35" alt="Opus 4.8">
  <img src="https://img.shields.io/badge/built%20with-Opus%205-0a1f35" alt="Opus 5">
  <img src="https://img.shields.io/badge/built%20with-Sonnet%205-0a1f35" alt="Sonnet 5">
  <img src="https://img.shields.io/badge/built%20with-GPT%205.6%20Sol-0a1f35" alt="GPT 5.6 Sol">
</p>

> ### 🇺🇿 Regulatory tailwind — happening right now
>
> A law introducing **mandatory escrow accounts for shared construction** is currently moving through Uzbekistan's parliament. Buyer funds will no longer go straight to the developer — they will sit in a bank and be released only against **confirmed construction progress**. That hands every lending bank a new legal duty it has no cheap way to fulfill today: verifying that the work behind each tranche actually happened.
>
> Закон о долевом строительстве с обязательными **эскроу-счетами** сейчас проходит через парламент Узбекистана. Деньги дольщика больше не пойдут напрямую застройщику — они лягут на счёт в банке и будут переведены только после **подтверждения выполненных работ**. У банков появляется новая юридическая обязанность, которую сегодня нечем закрыть недорого: проверять, что стройка за каждым траншем реальна.
>
> Ulushli qurilish uchun majburiy **eskrou-hisoblar**ni joriy etuvchi qonun hozir Oʻzbekiston parlamentidan oʻtmoqda. Xaridor puli endi toʻgʻridan-toʻgʻri quruvchiga bormaydi — u bankdagi hisobda turadi va faqat **bajarilgan ishlar tasdiqlangandan keyin** chiqariladi. Bu har bir kreditlashtiruvchi bankka bugun arzon bajarish usuli yoʻq boʻlgan yangi yuridik majburiyatni yuklaydi: har bir transh ortidagi ishning haqiqatan bajarilganini tekshirish.

---

# English

<table>
<tr>
<td width="50%" valign="top">

### Contents

1. [Definition](#1-definition)
2. [Market problem](#2-market-problem)
3. [Schedule trust system](#3-schedule-trust-system)
4. [Government interaction](#4-government-interaction)
5. [Monitoring chain](#5-monitoring-chain-from-photo-to-specialist)
6. [Four market sides](#6-four-market-sides-and-the-gaps-ibuild-closes)
7. [Role of AI](#7-role-of-artificial-intelligence)
   - [7.4 AI differentiators](#74-how-our-ai-differs-from-typical-alternatives)
8. [Buyer features](#8-buyer-features)
9. [Business features](#9-business-features)
10. [Differences](#10-differences-from-alternatives)
11. [Monetization](#11-monetization)

</td>
<td width="50%" valign="top">

### iBuild · at a glance

| | |
|---|---|
| **Market** | Uzbekistan: Tashkent, New Tashkent |
| **Offers** | Ready apartments, off-plan, office lease, street retail |
| **Apps** | Buyer app (Android, iOS, Web), two admin panels |
| **Parties** | Buyers, developers, banks, specialists, government |
| **Stack** | Flutter, Dart (REST & WebSocket), PostgreSQL with row-level isolation |
| **Engineering** | AI-native: Cursor — Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol |
| **AI engines** | Shipped, in-house: smart search, CRM lead scoring, readiness/photo verification (no training), OpenAI-backed buyer chat. Planned vendors: Newo AI (voice), Karmon AI (budgeting) |
| **Stage** | MVP — end-to-end scenario works |
| **Revenue** | Developer subscription, promotion, bank verification & referral leads |

</td>
</tr>
</table>

---

## 1. Definition

**iBuild** is an independent digital system for monitoring, documenting, and verifying construction progress. It connects developers, buyers, banks, and authorized government bodies. One product covers four offers: ready apartments from the developer, apartments under construction (*off-plan*), office lease in business centres, and street retail on the ground floors of residential complexes.

The system includes a buyer app, a developer panel, a platform admin panel, and a shared API on one database. The platform is **AI-native**: the full stack is written with agentic AI models in Cursor — Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol.

Unlike a classifieds board, iBuild does not publish third-party listings. It maintains a **verified registry of properties** with a traceable construction history and a comparison of promised schedules against actual progress.

> **Primary-only sales.** Sales on the platform are primary real estate from the developer only. Secondary properties are allowed for rent only. This rule is enforced by the database schema, not just policy.

---

## 2. Market problem

The main buyer complaint in Uzbekistan is not price or choice — it is the **inability to match a developer’s promises with facts**. Delivery dates appear in ads but are not documented: a project promised in three months may take a year, and some projects are never finished.

- availability and price are only known by calling each sales office;
- new builds have no public dated history of site progress;
- promised vs actual work volumes are never compared;
- developers lack a usable digital storefront and lead tracking;
- banks cannot see how disbursed funds are used and must hunt separately for mortgage and loan leads;
- government bodies learn about problem sites late — from harmed buyers.

iBuild’s product job: give buyers and banks an **independent monitoring and verification tool** for construction progress, and give authorized agencies an early signal when plan and fact diverge.

> **Why now.** A law introducing mandatory escrow accounts for shared construction is currently moving through Uzbekistan’s parliament — state-level recognition of the exact same broken-promise problem iBuild is built to solve, and the moment banks start needing a verification tool rather than just wanting one.

---

## 3. Schedule trust system

The product core. Instead of one marketing “readiness” number, a project card shows **two** figures and the gap between them.

### 3.1. Two progress metrics

- **Actual construction progress** — confirmed readiness from dated photo reports with percentage complete. <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span>
- **Planned construction progress** — readiness per the schedule the developer declared when publishing the project. <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span>

```
Actual construction progress   ████████████░░░░░░░░  62 %
Planned construction progress  ██████████████░░░░░░  74 %
```

> ⚠️ **Gap 12 %.** Acceptable deviation. Trust index — 84 %.

### 3.2. Trust index and thresholds

Trust index = actual readiness ÷ planned readiness on a 0–100 % scale. Gaps fall into three bands:

| Range | Assessment |
|---|---|
| **up to 10 %** | on schedule |
| **10–15 %** | acceptable deviation |
| **over 15 %** | lag — monitoring |

Up to 15 % is normal for a build cycle. Over 15 % triggers a flag and informational monitoring, with a possible site visit. Buyers, developers, banks, and admins all see the same number; the actual figure changes only with a verified photo report.

---

## 4. Government interaction

iBuild is an **independent digital system** for monitoring, documenting, and verifying construction progress. Informational exchange with authorized government bodies is planned. <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">planned</span>

A plan–fact gap is a signal for the buyer, the bank, and the agency. Judging compliance with building codes is the government’s job, not the platform’s.

> **The near-term driver.** Once escrow accounts are mandatory, a bank cannot release a tranche without confirming the work behind it — today that check is manual, slow, and expensive to staff. The monitoring chain below (Section 5) is designed to be the tool a bank plugs into for that confirmation, turning a regulatory cost into a service iBuild already sells.

---

## 5. Monitoring chain: from photo to specialist

| Step | Stage | Description |
|:---:|---|---|
| **1** | Developer photo report | Dated site photo with geotag and readiness %. <span style="background:#e6f3ef;color:#14866d;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">shipped</span> |
| **2** | AI photo verification | Geotag/metadata checks plus visual progress vs prior reports. <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">in progress</span> |
| **3** | “Needs clarification” flag | On mismatch the developer explains and re-shoots. <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">in progress</span> |
| **4** | System alert | No valid reply or lag over threshold — critical admin alert. <span style="background:#e6f3ef;color:#14866d;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">shipped</span> |
| **5** | Specialist (tech expert) | Visit by contract or with developer consent — record actual progress. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |
| **6** | Signal to the agency | Data goes to the relevant government body in an agreed format. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |
| **7** | Result on the card | Monitoring outcome is published and affects the trust index. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |

Monitoring is two-tier: machine first (metadata and image compare), then a specialist. On material lag — informational monitoring and, if needed, a site visit by contract or with the developer’s consent.

---

## 6. Four market sides and the gaps iBuild closes

<table>
<tr>
<td width="50%" valign="top">

#### ① iBuild · <sub>earns revenue</sub>

**Gap.** Between developer, buyer, and bank there is no independent party that documents and verifies construction progress: everyone takes claims on trust or runs their own checks.

**Solution.** iBuild keeps the registry, records the schedule, and verifies reports by machine and specialists. The product is **monitoring and verification** plus hot leads: developers pay for subscription; banks pay for verification and mortgage/loan referral leads.

</td>
<td width="50%" valign="top">

#### ② Banks · <sub>pays: verification · leads</sub>

**Gap.** After lending, the bank cannot see what the money becomes: poor materials, misuse, or — worst case — the developer disappears with the funds. An in-house specialist team is expensive; mortgage and loan leads are a separate problem.

**Solution.** A confirmed site picture lets tranches follow verified progress. Separately, banks may pay for mortgage/loan leads via an in-app referral link. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span>

</td>
</tr>
<tr>
<td valign="top">

#### ③ Buyers · <sub>do not pay iBuild</sub>

**Gap.** Buyers in Uzbekistan often do not know the real progress of a project they already paid for: there is no verifiable link between the ad promise and the site.

**Solution.** AI report checks and specialist visits provide a dated work history, actual next to plan, and monitoring results — before more money changes hands, not after.

</td>
<td valign="top">

#### ④ Developers · <sub>pays for subscription</sub>

**Gap.** Honest developers have no way to stand out from dishonest ones: the market treats everyone the same; storefront and lead tracking stay manual.

**Solution.** Visibility, hot leads, a project admin panel with CRM, and **iBuild verified developer** status after document verification. Transparency becomes an advantage.

</td>
</tr>
</table>

---

## 7. Role of artificial intelligence

Two different things carry the "AI" label in this project — kept separate here so neither overstates the other.

**Engineering.** The codebase itself is written with agentic coding models in Cursor: **Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol**.

**In the product**, AI is built in-house. Three engines below are plain deterministic Dart code, written and run entirely in this repo — no training step, no upstream model call.

| Engine | What it does | Calls an upstream model? | Server code | Client code |
|---|---|:---:|---|---|
| **Smart search (b2c)** | Parses free-text ru/uz/en queries into structured constraints, ranks catalogue units, and drives the inline "ghost text" suggestion. | No | [`smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart), [`search_dictionary.dart`](server/lib/src/ai/search_dictionary.dart), [`search_suggester.dart`](server/lib/src/ai/search_suggester.dart) | [`b2c/lib/features/ai/`](b2c/lib/features/ai/) |
| **CRM lead scoring (b2b)** | Scores every lead hot/warm/cold from behaviour, SLA timers, and ru/uz/en keyword signals; answers the CRM assistant's guided questions. | No | [`lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart) | [`b2b/lib/features/ai_crm/`](b2b/lib/features/ai_crm/) |
| **Readiness / photo verification** | A 7-stage pipeline per photo report: EXIF/geotag checks, perceptual-hash duplicate detection, a hand-tuned stage classifier, progress-vs-previous-report comparison, and visual risk indicators (safety gear, cracks, debris). | Optional (see below) | [`readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) | [`project_detail_readiness.dart`](b2b/lib/features/residence/project_detail_readiness.dart) |
| **Buyer AI consultant** | Conversational chat layer over the catalogue. | **Yes — OpenAI** | [`openai_client.dart`](server/lib/src/ai/openai_client.dart), [`prompts.dart`](server/lib/src/ai/prompts.dart) | [`ai_chat_sheet.dart`](b2c/lib/features/ai/presentation/ai_chat_sheet.dart) |

The readiness engine can optionally merge a GPT-vision pass over its own local result (`AI_VISION_ENABLED`, off by default); if that call fails, times out, or is disabled, the deterministic local result ships as-is. All AI HTTP endpoints (`/v1/ai/search`, `/v1/ai/search/suggest`, `/v1/ai/crm/leads`, `/v1/ai/crm/query`, `/v1/ai/chat`, photo-report verification) are wired in [`ai_routes.dart`](server/lib/src/ai/ai_routes.dart); usage is quota-limited per IP/user via [`ai_quota.dart`](server/lib/src/ai/ai_quota.dart).

### 7.1. Scope of AI

- Every photo report goes through the deterministic pipeline before publication — continuous, not sampling.
- The readiness check runs as a **preview** (`POST /v1/admin/projects/<id>/photo-reports/analyze`) before a report is published: it flags and classifies, it does not itself publish or reject — an admin acts on the result.
- A low-confidence classification automatically downgrades a hard failure to a manual-review flag instead of a false-positive rejection.

### 7.2. Value for payers

| Who pays | What AI delivers |
|---|---|
| **Developer** (subscription) | More completed leads at the same traffic; verified reports support verified-developer status. |
| **Bank** (verification · leads) | Continuous monitoring plus specialists on disputes costs less than an in-house team; referral link brings mortgage/loan applications. |
| **iBuild** (margin) | Monitoring unit cost falls; the service stays cheaper than a bank’s own staff as inventory grows. |

### 7.3. Planned vendor integrations

Not built yet, no code in this repo — future integrations under consideration, kept separate from the in-house engines above so the two are never confused:

| Vendor | Role | Status |
|---|---|---|
| **Newo AI** | Voice assistant and call centre: answers on the catalogue and matches preferences — deal type, district, budget, rooms. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |
| **Karmon AI** | Budgeting: purchase budget with installments and mortgage, project expense planning. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |

### 7.4. How our AI differs from typical alternatives

Detailed write-ups grounded in the actual server code — not marketing copy:

| Topic | Document | What it covers |
|---|---|---|
| **Smart search (b2c)** | [`AI_SEARCH_DIFFERENTIATORS.md`](AI_SEARCH_DIFFERENTIATORS.md) | Negation handling, blocked queries when intent is unclear, domain ranking with trust index, softened impossible amenities, execution trace |
| **CRM AI (b2b)** | [`AI_CRM_DIFFERENTIATORS.md`](AI_CRM_DIFFERENTIATORS.md) | Explainable lead scoring with reason codes, real-estate inventory signals, SLA and silence escalation, guided assistant tree (not free chat), demand vs available units |

---

## 8. Buyer features

| Feature | Status |
|---|---|
| Map and search with Buy / Rent / New-build filters | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span> |
| Live unit grid (“chessboard”) for apartments and offices | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span> |
| One-tap request: viewing, call, hold, rent | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span> |
| Dated construction photo-report feed | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span> |
| Dual progress bars and trust index | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Developer card with verified documents | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span> |
| Mortgage, installment, and rental-yield calculators | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Favorites, saved searches, My requests, reviews, three languages | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Push alerts on price and construction stages | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Bank referral for mortgage/loan; voice matching (Newo AI) | <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">planned</span> |

---

## 9. Business features

| Feature | Status |
|---|---|
| Projects, buildings, units, media library, floor plans | <span style="background:#e8f0e4;color:#5a7a2f;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #c5d6a8">refining</span> |
| Chessboard editor with conflict-safe edits | <span style="background:#e8f0e4;color:#5a7a2f;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #c5d6a8">refining</span> |
| Lead CRM: funnel, statuses, tags, event history | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span> |
| Photo reports and planned construction schedule entry | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Analytics: demand, funnel, lead conversion | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">shipped</span> |
| Developer verification, project/review moderation, audit log | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Alerts, including critical schedule-deviation alerts | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Subscription payment via bank transfer | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">in progress</span> |
| Bank reports and mortgage/loan referral leads | <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">planned</span> |

---

## 10. Differences from alternatives

- Classifieds sell **impressions**; iBuild sells **monitoring and verification**.
- **Source.** Only developers with verified documents.
- **Availability and price.** Live chessboard instead of stale ads.
- **Build progress.** Dated reports and a trust index instead of marketing photos.
- **Missed deadline.** AI flag, alert, and specialist visit instead of silence.
- **Bank and state.** Verification, mortgage/loan referral leads, informational signal to the agency.

---

## 11. Monetization

Only businesses pay. Developers — subscription and promotion; banks — object verification and, as planned, mortgage/loan leads via referral. Buyers do not pay.

| Source | From | Description |
|---|---|---|
| Developer subscription | Developers | Publishing, CRM, analytics. Start / Growth / Scale |
| Promotion and lead packs | Developers | Search placement; leads above the plan limit |
| Bank verification | Banks | Construction progress monitoring/verification as a lender service <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |
| Bank referral leads | Banks | Mortgage or loan application via referral link <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |

---

# Русский

<table>
<tr>
<td width="50%" valign="top">

### Содержание

1. [Определение](#1-определение)
2. [Проблема рынка](#2-проблема-рынка)
3. [Система доверия к срокам](#3-система-доверия-к-срокам)
4. [Взаимодействие с госорганами](#4-взаимодействие-с-госорганами)
5. [Цепочка мониторинга](#5-цепочка-мониторинга-от-снимка-до-специалиста)
6. [Четыре стороны рынка](#6-четыре-стороны-рынка-и-разрывы-которые-закрывает-ibuild)
7. [Роль искусственного интеллекта](#7-роль-искусственного-интеллекта)
   - [7.4 Отличия ИИ](#74-чем-наш-ии-отличается-от-типичных-аналогов)
8. [Возможности для клиентов](#8-возможности-для-клиентов)
9. [Возможности для бизнеса](#9-возможности-для-бизнеса)
10. [Отличия от аналогов](#10-отличия-от-аналогов)
11. [Монетизация](#11-монетизация)

</td>
<td width="50%" valign="top">

### iBuild · кратко

| | |
|---|---|
| **Рынок** | Узбекистан: Ташкент, Новый Ташкент |
| **Предложения** | Готовые квартиры, off-plan, аренда офисов, стрит-ритейл |
| **Приложения** | Клиентское (Android, iOS, Web), две панели администратора |
| **Стороны** | Клиенты, застройщики, банки, специалисты, госорганы |
| **Стек** | Flutter, Dart (REST и WebSocket), PostgreSQL с изоляцией на уровне строк |
| **Инженерия** | AI-native: Cursor — Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol |
| **ИИ-движки** | Реализовано, собственные: умный поиск, скоринг лидов CRM, верификация готовности/фото (без обучения), чат-консультант на базе OpenAI. В планах — вендоры: Newo AI (голос), Karmon AI (бюджетирование) |
| **Стадия** | MVP, сквозной сценарий работает |
| **Доход** | Подписка застройщика, продвижение, верификация и реферальные лиды для банков |

</td>
</tr>
</table>

---

## 1. Определение

**iBuild** — независимая цифровая система мониторинга, документирования и верификации сведений о ходе строительства, взаимодействующая с застройщиками, покупателями, банками и уполномоченными государственными органами. В одном продукте объединены четыре предложения: готовые квартиры от застройщика, квартиры на этапе строительства (*off-plan*), аренда офисов в бизнес-центрах и стрит-ритейл на первых этажах жилых комплексов.

Система состоит из клиентского приложения, панели застройщика, административной панели и общего программного интерфейса поверх единой базы данных. Платформа **AI-native**: весь стек пишется в связке с агентными ИИ-моделями Cursor — Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol.

Отличие от классифайда принципиальное: iBuild не публикует чужие объявления, а ведёт **верифицированный реестр объектов** с прослеживаемой историей строительства и сопоставлением заявленных сроков с фактическим ходом работ.

> **Правило первички.** Продажа на платформе — только первичная недвижимость напрямую от застройщика. Вторичные объекты допускаются исключительно в аренде. Правило закреплено не регламентом, а структурой базы данных.

---

## 2. Проблема рынка

Главная претензия покупателя в Узбекистане — не цена и не выбор, а **невозможность сопоставить обещания застройщика с фактами**. Срок сдачи объявляется в рекламе, но нигде не фиксируется в документированном виде: объект, обещанный через три месяца, строится год, а часть объектов не достраивается вовсе.

- наличие и цену квартиры узнают только звонком в отдел продаж каждого комплекса;
- у новостройки нет публичной датированной истории хода работ;
- обещанный и фактический объём работ нигде не сопоставляются;
- у застройщика нет доступной цифровой витрины и учёта заявок;
- банк не видит судьбу выданных денег и отдельно ищет каналы заявок на ипотеку и кредит;
- уполномоченные государственные органы получают сведения о проблемном объекте поздно — от пострадавших покупателей.

Отсюда продуктовая задача iBuild: дать покупателю и банку **инструмент независимого мониторинга и верификации сведений** о ходе строительства, а уполномоченным государственным органам — ранний информационный сигнал о расхождении плана и факта.

> **Почему именно сейчас.** Через парламент Узбекистана проходит закон о долевом строительстве с обязательными эскроу-счетами — та же проблема обманутых дольщиков признана на уровне государства, и именно с этого момента у банков появляется не желание, а необходимость в инструменте верификации.

---

## 3. Система доверия к срокам

Ядро продукта. Вместо одной рекламной цифры готовности карточка объекта показывает **две** и разницу между ними.

### 3.1. Два показателя готовности

- **Фактический ход строительства** — подтверждённая готовность: формируется из датированных фотоотчётов с процентом выполненных работ. <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span>
- **Плановый ход строительства** — готовность по графику, заявленному застройщиком при публикации проекта. <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span>

```
Фактический ход строительства  ████████████░░░░░░░░  62 %
Плановый ход строительства    ██████████████░░░░░░  74 %
```

> ⚠️ **Расхождение 12 %.** Допустимое отклонение. Индекс доверия — 84 %.

### 3.2. Индекс доверия и пороги

Индекс доверия — отношение фактической готовности к плановой по шкале от 0 до 100 %. Расхождение оценивается по трём диапазонам:

| Диапазон | Оценка |
|---|---|
| **до 10 %** | соответствует графику |
| **10–15 %** | допустимое отклонение |
| **свыше 15 %** | отставание, мониторинг |

Отклонение до 15 % нормально для строительного цикла. Свыше 15 % — пометка и информационный мониторинг с возможным посещением объекта. Цифру видят покупатель, застройщик, банк и администратор; факт меняется только с верифицированным фотоотчётом.

---

## 4. Взаимодействие с госорганами

iBuild — **независимая цифровая система** мониторинга, документирования и верификации сведений о ходе строительства. Планируется информационный обмен с уполномоченными государственными органами. <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">план</span>

Расхождение плана и факта — сигнал для покупателя, банка и ведомства. Оценка соответствия строительным нормам — компетенция госорганов, не платформы.

> **Ближайший драйвер.** Как только эскроу-счета станут обязательными, банк не сможет выпустить транш без подтверждения выполненных работ — сегодня эта проверка ручная, медленная и дорога в содержании. Цепочка мониторинга ниже (раздел 5) спроектирована как инструмент, к которому банк подключается для такого подтверждения, — регуляторная нагрузка превращается в услугу, которую iBuild уже продаёт.

---

## 5. Цепочка мониторинга: от снимка до специалиста

| Шаг | Этап | Описание |
|:---:|---|---|
| **1** | Фотоотчёт застройщика | Датированный снимок объекта с геометкой и процентом готовности. <span style="background:#e6f3ef;color:#14866d;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">реализовано</span> |
| **2** | ИИ-верификация снимка | Верификация геотега и метаданных плюс визуальное сравнение прогресса с прошлыми отчётами. <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">в разработке</span> |
| **3** | Пометка «требует уточнения» | При несовпадении застройщик даёт объяснение и переснимает объект. <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">в разработке</span> |
| **4** | Оповещение системы | Нет корректного ответа или отставание свыше порога — критическое уведомление админу. <span style="background:#e6f3ef;color:#14866d;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">реализовано</span> |
| **5** | Специалист (техн. эксперт) | Посещение по договору или по согласованию с застройщиком — фиксация фактического хода работ. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |
| **6** | Информационный сигнал ведомству | Сведения уходят в профильный государственный орган в согласованном формате. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |
| **7** | Результат в карточке | Итог мониторинга публикуется и влияет на индекс доверия объекта. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |

Мониторинг двухуровневый: сначала машина (метаданные и сравнение изображений), затем специалист (технический эксперт). При существенном отставании — информационный мониторинг и при необходимости посещение объекта по договору или по согласованию с застройщиком.

---

## 6. Четыре стороны рынка и разрывы, которые закрывает iBuild

<table>
<tr>
<td width="50%" valign="top">

#### ① iBuild · <sub>получает доход</sub>

**Разрыв.** Между застройщиком, покупателем и банком нет независимой стороны, которая документирует и верифицирует сведения о ходе строительства: каждый верит на слово либо ведёт собственный мониторинг.

**Решение.** iBuild ведёт реестр, фиксирует график и верифицирует отчёты машиной и специалистами. Продукт — **мониторинг и верификация сведений** плюс горячие заявки: застройщик платит за подписку, банк — за верификацию и за реферальные лиды на ипотеку и кредит.

</td>
<td width="50%" valign="top">

#### ② Банки · <sub>платит: верификация · лиды</sub>

**Разрыв.** Выдав кредит, банк не видит, во что превращаются деньги: некачественные материалы, расход не по назначению, в худшем случае застройщик исчезает со средствами. Собственный штат технических специалистов дорог; отдельно нужны заявки на ипотеку и кредит.

**Решение.** Подтверждённая картина стройки позволяет привязывать транши к верифицированному прогрессу. Отдельно планируется оплата банка за лиды на ипотеку и кредит по реферальной ссылке из приложения. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span>

</td>
</tr>
<tr>
<td valign="top">

#### ③ Клиенты · <sub>не платят iBuild</sub>

**Разрыв.** Покупатель в Узбекистане не осведомлён о реальном ходе строительства объекта, за который уже заплатил: между рекламным обещанием и стройплощадкой нет верифицируемой связи.

**Решение.** ИИ-верификация отчётов и посещения специалистами дают датированную историю работ, факт рядом с планом и результаты мониторинга — до внесения денег, а не после.

</td>
<td valign="top">

#### ④ Застройщики · <sub>платит за подписку</sub>

**Разрыв.** Добросовестному застройщику нечем отличить себя от недобросовестного: рынок оценивает всех одинаково, витрина и учёт заявок остаются ручными.

**Решение.** Медийность, поток горячих заявок, панель управления объектами с CRM и статус **верифицированного застройщика iBuild** после документарной верификации. Прозрачность становится преимуществом.

</td>
</tr>
</table>

---

## 7. Роль искусственного интеллекта

В проекте под словом «ИИ» скрываются две разные вещи — здесь они разделены, чтобы одна не выдавалась за другую.

**Инженерия.** Сам код пишется агентными ИИ-моделями в Cursor: **Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol**.

**В продукте** ИИ разрабатывается собственными силами. Три движка ниже — обычный детерминированный Dart-код, написанный и выполняемый целиком в этом репозитории: без этапа обучения и без обращения к внешней модели.

| Движок | Что делает | Обращается к внешней модели? | Код сервера | Код клиента |
|---|---|:---:|---|---|
| **Умный поиск (b2c)** | Разбирает свободный текст на ru/uz/en в структурные условия, ранжирует юниты каталога и формирует подсказку «серым текстом». | Нет | [`smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart), [`search_dictionary.dart`](server/lib/src/ai/search_dictionary.dart), [`search_suggester.dart`](server/lib/src/ai/search_suggester.dart) | [`b2c/lib/features/ai/`](b2c/lib/features/ai/) |
| **Скоринг лидов CRM (b2b)** | Оценивает каждый лид как горячий/тёплый/холодный по поведению, таймерам SLA и ключевым словам на ru/uz/en; отвечает на вопросы ассистента CRM. | Нет | [`lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart) | [`b2b/lib/features/ai_crm/`](b2b/lib/features/ai_crm/) |
| **Готовность / анализ фото** | 7-этапная проверка каждого фотоотчёта: EXIF и геотег, поиск дублей по перцептивному хешу, классификатор этапа стройки, сравнение прогресса с прошлым отчётом, визуальные риск-индикаторы (СИЗ, трещины, мусор). | Опционально (см. ниже) | [`readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) | [`project_detail_readiness.dart`](b2b/lib/features/residence/project_detail_readiness.dart) |
| **ИИ-консультант покупателя** | Диалоговый слой над каталогом. | **Да — OpenAI** | [`openai_client.dart`](server/lib/src/ai/openai_client.dart), [`prompts.dart`](server/lib/src/ai/prompts.dart) | [`ai_chat_sheet.dart`](b2c/lib/features/ai/presentation/ai_chat_sheet.dart) |

Движок готовности может опционально домешать проход через GPT-vision поверх собственного локального результата (`AI_VISION_ENABLED`, по умолчанию выключено); если этот вызов упал, превысил таймаут или отключён — уходит детерминированный локальный результат без изменений. Все ИИ-эндпоинты (`/v1/ai/search`, `/v1/ai/search/suggest`, `/v1/ai/crm/leads`, `/v1/ai/crm/query`, `/v1/ai/chat`, верификация фотоотчётов) подключены в [`ai_routes.dart`](server/lib/src/ai/ai_routes.dart); использование ограничено квотой на IP/пользователя через [`ai_quota.dart`](server/lib/src/ai/ai_quota.dart).

### 7.1. Объём участия

- Каждый фотоотчёт проходит детерминированную проверку до публикации — мониторинг сплошной, а не выборочный.
- Проверка готовности запускается как **предпросмотр** (`POST /v1/admin/projects/<id>/photo-reports/analyze`) до публикации отчёта: она помечает и классифицирует, но не публикует и не отклоняет сама — решение по результату принимает администратор.
- Низкая уверенность классификации автоматически понижает жёсткий отказ до пометки «на ручную проверку» вместо ложного отклонения.


### 7.2. Что это даёт плательщикам

| Кто платит | Что даёт ИИ |
|---|---|
| **Застройщик** (подписка) | Больше доведённых заявок при том же трафике; пройденная верификация отчётов подтверждает статус верифицированного застройщика. |
| **Банк** (верификация · лиды) | Сплошной мониторинг плюс специалист по спорным дешевле собственного штата; реферальная ссылка приводит заявки на ипотеку и кредит. |
| **iBuild** (маржа) | Себестоимость мониторинга падает: услуга дешевле банковского штата, маржа держится при росте объектов. |

### 7.3. Планируемые интеграции с вендорами

Пока не реализовано, кода в этом репозитории нет — рассматриваемые интеграции на будущее, отдельно от собственных движков выше, чтобы одно не путалось с другим:

| Вендор | Назначение | Статус |
|---|---|---|
| **Newo AI** | Голосовой помощник и колл-центр: отвечает по каталогу и подбирает объекты по предпочтениям клиента — сделка, район, бюджет, комнатность. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |
| **Karmon AI** | Универсальный инструмент бюджетирования: расчёт бюджета покупки с учётом рассрочки и ипотеки, планирование расходов по проекту. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |

### 7.4. Чем наш ИИ отличается от типичных аналогов

Подробные разборы с опорой на реальный код сервера — не маркетинговые формулировки:

| Тема | Документ | О чём |
|---|---|---|
| **Умный поиск (b2c)** | [`AI_SEARCH_DIFFERENTIATORS.md`](AI_SEARCH_DIFFERENTIATORS.md) | Отрицание, блокировка непонятных запросов, доменное ранжирование с индексом доверия, смягчение невыполнимых пожеланий, трейс выполнения |
| **CRM AI (b2b)** | [`AI_CRM_DIFFERENTIATORS.md`](AI_CRM_DIFFERENTIATORS.md) | Объяснимый скоринг с кодами причин, сигналы инвентаря недвижимости, эскалация SLA и молчания, дерево ассистента (не свободный чат), спрос vs свободные юниты |

---

## 8. Возможности для клиентов

| Возможность | Состояние |
|---|---|
| Карта и поиск с фильтрами «Купить / Снять / Новостройки» | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span> |
| «Шахматка» — сетка квартир и офисов со статусами в реальном времени | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span> |
| Заявка в один тап: просмотр, звонок, бронь, аренда | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span> |
| Датированная лента фотоотчётов о ходе строительства | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span> |
| Две полосы хода строительства и индекс доверия | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Карточка застройщика с верифицированными документами | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span> |
| Калькуляторы ипотеки, рассрочки и доходности аренды | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Избранное, сохранённые поиски, «Мои заявки», отзывы, три языка | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Push-уведомления о цене и этапах строительства | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Реф. ссылка банка на ипотеку/кредит; голосовой подбор (Newo AI) | <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">план</span> |

---

## 9. Возможности для бизнеса

| Возможность | Состояние |
|---|---|
| Проекты, корпуса, юниты, медиатека и планировки | <span style="background:#e8f0e4;color:#5a7a2f;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #c5d6a8">в доработке</span> |
| Редактор «шахматки» с защитой от конфликтов правок | <span style="background:#e8f0e4;color:#5a7a2f;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #c5d6a8">в доработке</span> |
| CRM заявок: воронка, статусы, теги, история событий | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span> |
| Фотоотчёты и ввод планового графика строительства | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Аналитика: спрос, воронка, конверсия заявок | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">реализовано</span> |
| Верификация застройщика, модерация проектов и отзывов, журнал | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Оповещения, включая критические по отклонению сроков | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Оплата подписки через банковский перевод | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">в разработке</span> |
| Отчёты банку и реферальные лиды на ипотеку/кредит | <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">план</span> |

---

## 10. Отличия от аналогов

- Доски объявлений продают **показы**, iBuild — **мониторинг и верификацию сведений**.
- **Источник.** Только застройщик с верифицированными документами.
- **Наличие и цена.** Живая «шахматка» вместо устаревших объявлений.
- **Ход стройки.** Датированные отчёты и индекс доверия вместо рекламных фото.
- **Срыв срока.** ИИ-пометка, оповещение и посещение специалиста вместо тишины.
- **Банк и государство.** Верификация, реф. лиды на ипотеку/кредит, информационный сигнал в ведомство.

---

## 11. Монетизация

Платит только бизнес. Застройщик — подписка и продвижение; банк — верификация объекта и, по плану, лиды на ипотеку и кредит по реферальной ссылке. Покупатель не платит.

| Источник | От кого | Описание |
|---|---|---|
| Подписка застройщика | Застройщики | Публикация, CRM, аналитика. Start / Growth / Scale |
| Продвижение и пакеты заявок | Застройщики | Позиции в поиске; заявки сверх лимита тарифа |
| Верификация для банков | Банки | Мониторинг и верификация сведений о ходе стройки как услуга кредитору <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |
| Реферальные лиды банку | Банки | Заявка на ипотеку или кредит по реф. ссылке <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |

---

# Oʻzbek

<table>
<tr>
<td width="50%" valign="top">

### Mazmuni

1. [Taʼrif](#1-taʼrif)
2. [Bozor muammosi](#2-bozor-muammosi)
3. [Muddatlarga ishonch tizimi](#3-muddatlarga-ishonch-tizimi)
4. [Davlat organlari bilan hamkorlik](#4-davlat-organlari-bilan-hamkorlik)
5. [Monitoring zanjiri](#5-monitoring-zanjiri-suratdan-mutaxassisgacha)
6. [Bozorning toʻrt tomoni](#6-bozorning-toʻrt-tomoni-va-ibuild-yopadigan-boʻshliqlar)
7. [Sunʼiy intellekt roli](#7-sunʼiy-intellekt-roli)
   - [7.4 SI farqlari](#74-bizning-si-analoglardan-qanday-farq-qiladi)
8. [Xaridorlar uchun imkoniyatlar](#8-xaridorlar-uchun-imkoniyatlar)
9. [Biznes uchun imkoniyatlar](#9-biznes-uchun-imkoniyatlar)
10. [Analoglardan farqi](#10-analoglardan-farqi)
11. [Monetizatsiya](#11-monetizatsiya)

</td>
<td width="50%" valign="top">

### iBuild · qisqacha

| | |
|---|---|
| **Bozor** | Oʻzbekiston: Toshkent, Yangi Toshkent |
| **Taklif** | Tayyor kvartiralar, off-plan, ofis ijarasi, strit-riteyl |
| **Ilovalar** | Xaridor ilovasi (Android, iOS, Web), ikki admin panel |
| **Taraflar** | Xaridorlar, quruvchilar, banklar, mutaxassislar, davlat organlari |
| **Stek** | Flutter, Dart (REST va WebSocket), qatorlar darajasida izolyatsiyalangan PostgreSQL |
| **Muhandislik** | AI-native: Cursor — Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol |
| **SI dvijoklari** | Ishlab chiqilgan, oʻz kuchimiz bilan: aqlli qidiruv, CRM lidlarni baholash, tayyorlik/foto tekshiruvi (oʻqitishsiz), OpenAI asosidagi xaridor chati. Rejada — vendorlar: Newo AI (ovoz), Karmon AI (byudjetlashtirish) |
| **Bosqich** | MVP — toʻliq stsenariy ishlaydi |
| **Daromad** | Quruvchi obunasi, ilgari surish, banklar uchun tasdiqlash va referal lidlar |

</td>
</tr>
</table>

---

## 1. Taʼrif

**iBuild** — qurilish jarayoni haqidagi maʼlumotlarni monitoring qilish, hujjatlashtirish va tasdiqlash boʻyicha mustaqil raqamli tizim; u quruvchilarni, xaridorlarni, banklarni va vakolatli davlat organlarini bir-biriga bogʻlaydi. Bitta mahsulotda toʻrt xil taklif birlashtirilgan: quruvchidan tayyor kvartiralar, qurilayotgan kvartiralar (*off-plan*), biznes-markazlarda ofis ijarasi va turar-joy majmualarining birinchi qavatlarida strit-riteyl.

Tizim xaridor ilovasidan, quruvchi panelidan, platforma admin panelidan va yagona maʼlumotlar bazasi ustidagi umumiy API dan iborat. Platforma **AI-native**: butun kod bazasi Cursordagi agentlik SI modellari — Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol — bilan yoziladi.

Klassifayd (eʼlonlar) taxtasidan farqli oʻlaroq, iBuild boshqalarning eʼlonlarini joylashtirmaydi. U qurilish tarixi kuzatib boriladigan **tasdiqlangan obyektlar reyestri**ni yuritadi va vaʼda qilingan jadvalni haqiqiy jarayon bilan solishtiradi.

> **Faqat birlamchi sotuv.** Platformada sotuv — faqat quruvchidan birlamchi koʻchmas mulk. Ikkilamchi obyektlarga faqat ijaraga berish uchun ruxsat berilgan. Bu qoida siyosat bilan emas, balki maʼlumotlar bazasi sxemasi bilan mustahkamlangan.

---

## 2. Bozor muammosi

Oʻzbekistondagi xaridorning asosiy shikoyati narx yoki tanlov emas — bu **quruvchi vaʼdalarini faktlar bilan solishtira olmaslik**. Topshirish sanalari reklamada eʼlon qilinadi, ammo hech qanday hujjatlashtirilgan holda qayd etilmaydi: uch oyda vaʼda qilingan obyekt bir yilda quriladi, ayrim obyektlar esa umuman tugallanmaydi.

- kvartira mavjudligi va narxi faqat har bir sotuv ofisiga qoʻngʻiroq qilib bilinadi;
- yangi qurilishning ochiq, sanalangan qurilish tarixi yoʻq;
- vaʼda qilingan va haqiqiy ish hajmlari hech qachon solishtirilmaydi;
- quruvchida qulay raqamli vitrina va lidlarni hisobga olish tizimi yoʻq;
- bank ajratilgan mablagʻlarning taqdirini koʻrmaydi va ipoteka/kredit lidlarini alohida izlashga majbur;
- vakolatli davlat organlari muammoli obyekt haqida kechikib — jabrlangan xaridorlardan bilib oladi.

Shu sababli iBuildning mahsulot vazifasi: xaridor va bankka qurilish jarayoni boʻyicha **mustaqil monitoring va tasdiqlash vositasi**ni, vakolatli davlat organlariga esa reja va fakt orasidagi farq haqida erta signalni taqdim etish.

> **Nega aynan hozir.** Oʻzbekiston parlamentidan ulushli qurilish uchun majburiy eskrou-hisoblar toʻgʻrisidagi qonun oʻtmoqda — bu aldangan xaridorlar bilan bogʻliq xuddi shu muammoning davlat darajasida tan olinishi va shu paytdan boshlab banklarda tasdiqlash vositasiga ehtiyoj — istak emas, zaruratning paydo boʻlishi.

---

## 3. Muddatlarga ishonch tizimi

Mahsulotning yadrosi. Bitta reklama "tayyorlik" raqami oʻrniga obyekt kartochkasi **ikki** koʻrsatkichni va ular orasidagi farqni koʻrsatadi.

### 3.1. Ikki tayyorlik koʻrsatkichi

- **Haqiqiy qurilish jarayoni** — sanalangan, tayyorlik foizi bilan fotohisobotlardan tasdiqlangan tayyorlik. <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span>
- **Rejalashtirilgan qurilish jarayoni** — quruvchi obyektni eʼlon qilishda bildirgan jadvalga koʻra tayyorlik. <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span>

```
Haqiqiy qurilish jarayoni           ████████████░░░░░░░░  62 %
Rejalashtirilgan qurilish jarayoni   ██████████████░░░░░░  74 %
```

> ⚠️ **Farq 12 %.** Ruxsat etilgan chetlanish. Ishonch indeksi — 84 %.

### 3.2. Ishonch indeksi va chegaralar

Ishonch indeksi — haqiqiy tayyorlikning rejalashtirilganiga nisbati, 0–100 % shkalada. Farq uch diapazonga boʻlinadi:

| Diapazon | Baho |
|---|---|
| **10 %gacha** | jadvalga mos |
| **10–15 %** | ruxsat etilgan chetlanish |
| **15 %dan yuqori** | orqada qolish — monitoring |

Qurilish siklida 15 %gacha boʻlgan chetlanish odatiy holdir. 15 %dan yuqori chetlanish bayroqcha va axborot monitoringini, zarur boʻlsa obyektga tashrifni keltirib chiqaradi. Xaridor, quruvchi, bank va administrator bir xil raqamni koʻradi; haqiqiy koʻrsatkich faqat tasdiqlangan fotohisobot bilan oʻzgaradi.

---

## 4. Davlat organlari bilan hamkorlik

iBuild — qurilish jarayoni haqidagi maʼlumotlarni monitoring qilish, hujjatlashtirish va tasdiqlash boʻyicha **mustaqil raqamli tizim**. Vakolatli davlat organlari bilan axborot almashinuvi rejalashtirilgan. <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">reja</span>

Reja va fakt orasidagi farq — xaridor, bank va idora uchun signal. Qurilish normalariga muvofiqlikni baholash — davlat organlarining vazifasi, platformaning emas.

> **Yaqin muddatdagi drayver.** Eskrou-hisoblar majburiy boʻlishi bilanoq, bank bajarilgan ishni tasdiqlamasdan transhni chiqarib berolmaydi — bugun bu tekshiruv qoʻlda, sekin va xodim saqlash uchun qimmat. Quyidagi monitoring zanjiri (5-boʻlim) bank shu tasdiqlash uchun ulanadigan vosita boʻlishi uchun moʻljallangan — tartibga solish yuki iBuild allaqachon sotayotgan xizmatga aylanadi.

---

## 5. Monitoring zanjiri: suratdan mutaxassisgacha

| Qadam | Bosqich | Tavsif |
|:---:|---|---|
| **1** | Quruvchi fotohisoboti | Geobelgi va tayyorlik foizi bilan sanalangan obyekt surati. <span style="background:#e6f3ef;color:#14866d;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">amalga oshirilgan</span> |
| **2** | SI orqali surat tekshiruvi | Geobelgi/metadata tekshiruvi plyus oldingi hisobotlar bilan vizual taqqoslash. <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">ishlanmoqda</span> |
| **3** | "Aniqlashtirish talab etiladi" belgisi | Nomuvofiqlikda quruvchi tushuntirish beradi va qayta suratga oladi. <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">ishlanmoqda</span> |
| **4** | Tizim ogohlantiruvi | Toʻgʻri javob yoʻq yoki chetlanish chegaradan oshgan — administratorga tanqidiy ogohlantirish. <span style="background:#e6f3ef;color:#14866d;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">amalga oshirilgan</span> |
| **5** | Mutaxassis (texnik ekspert) | Shartnoma boʻyicha yoki quruvchi roziligi bilan tashrif — haqiqiy jarayonni qayd etish. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span> |
| **6** | Idoraga signal | Maʼlumotlar kelishilgan formatda tegishli davlat organiga boradi. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span> |
| **7** | Kartochkadagi natija | Monitoring natijasi eʼlon qilinadi va ishonch indeksiga taʼsir qiladi. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span> |

Monitoring ikki bosqichli: avval mashina (metadata va tasvirlarni taqqoslash), keyin mutaxassis. Sezilarli chetlanishda — axborot monitoringi va zarur boʻlsa shartnoma boʻyicha yoki quruvchi roziligi bilan obyektga tashrif.

---

## 6. Bozorning toʻrt tomoni va iBuild yopadigan boʻshliqlar

<table>
<tr>
<td width="50%" valign="top">

#### ① iBuild · <sub>daromad oladi</sub>

**Boʻshliq.** Quruvchi, xaridor va bank orasida qurilish jarayoni haqidagi maʼlumotlarni hujjatlashtiradigan va tasdiqlaydigan mustaqil taraf yoʻq: har kim soʻzga ishonadi yoki oʻz tekshiruvini oʻtkazadi.

**Yechim.** iBuild reyestrni yuritadi, jadvalni qayd etadi va hisobotlarni mashina va mutaxassislar orqali tasdiqlaydi. Mahsulot — **monitoring va tasdiqlash** plyus qizigan lidlar: quruvchi obuna uchun, bank esa tasdiqlash va ipoteka/kredit uchun referal lidlar uchun toʻlaydi.

</td>
<td width="50%" valign="top">

#### ② Banklar · <sub>toʻlaydi: tasdiqlash · lidlar</sub>

**Boʻshliq.** Kredit berilgandan keyin bank pul nimaga aylanayotganini koʻrmaydi: sifatsiz materiallar, maqsadsiz sarflash, eng yomon holatda — quruvchi mablagʻlar bilan gʻoyib boʻladi. Oʻz texnik mutaxassislar shtati qimmat; ipoteka va kredit lidlari alohida muammo.

**Yechim.** Tasdiqlangan obyekt manzarasi transhlarni tasdiqlangan jarayonga bogʻlash imkonini beradi. Alohida, banklar ilovadagi referal havola orqali ipoteka/kredit lidlari uchun toʻlashi mumkin. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span>

</td>
</tr>
<tr>
<td valign="top">

#### ③ Xaridorlar · <sub>iBuildga toʻlamaydi</sub>

**Boʻshliq.** Oʻzbekistondagi xaridor allaqachon toʻlagan obyektning haqiqiy jarayonidan koʻpincha bexabar: reklama vaʼdasi va qurilish maydoni orasida tasdiqlanadigan bogʻliqlik yoʻq.

**Yechim.** SI orqali hisobot tekshiruvi va mutaxassis tashriflari sanalangan ish tarixini, fakt va rejani yonma-yon, monitoring natijalarini — pul koʻchishidan oldin, keyin emas — taqdim etadi.

</td>
<td valign="top">

#### ④ Quruvchilar · <sub>obuna uchun toʻlaydi</sub>

**Boʻshliq.** Insofli quruvchida oʻzini insofsizidan ajratib koʻrsatishning imkoni yoʻq: bozor barchani bir xil baholaydi, vitrina va lidlarni hisobga olish qoʻlda qolmoqda.

**Yechim.** Koʻrinuvchanlik, qizigan lidlar oqimi, CRM bilan obyektlarni boshqarish paneli va hujjatlarni tasdiqlashdan keyin **iBuild tasdiqlangan quruvchi** maqomi. Shaffoflik ustunlikka aylanadi.

</td>
</tr>
</table>

---

## 7. Sunʼiy intellekt roli

Loyihada "SI" soʻzi ortida ikki xil narsa yashiringan — ular bu yerda ajratilgan, biri boshqasining oʻrniga oʻtib ketmasligi uchun.

**Muhandislik.** Kodning oʻzi Cursordagi agentlik SI modellari bilan yoziladi: **Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol**.

**Mahsulotda** SI oʻz kuchimiz bilan ishlab chiqiladi. Quyidagi uch dvijok — bu repozitoriyada toʻliq yoziladigan va ishlaydigan oddiy deterministik Dart kodi: oʻqitish bosqichisiz va tashqi modelga murojaatsiz.

| Dvijok | Nima qiladi | Tashqi modelga murojaat qiladimi? | Server kodi | Klient kodi |
|---|---|:---:|---|---|
| **Aqlli qidiruv (b2c)** | Erkin matnni ru/uz/en tillarida struktura shartlariga ajratadi, katalog yunitlarini reytinglaydi va "kul rang matn" taklifini shakllantiradi. | Yoʻq | [`smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart), [`search_dictionary.dart`](server/lib/src/ai/search_dictionary.dart), [`search_suggester.dart`](server/lib/src/ai/search_suggester.dart) | [`b2c/lib/features/ai/`](b2c/lib/features/ai/) |
| **CRM lidlarni baholash (b2b)** | Har bir lidni xatti-harakati, SLA taymerlari va ru/uz/en kalit soʻzlariga koʻra issiq/iliq/sovuq deb baholaydi; CRM yordamchisining boshqariladigan savollariga javob beradi. | Yoʻq | [`lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart) | [`b2b/lib/features/ai_crm/`](b2b/lib/features/ai_crm/) |
| **Tayyorlik / foto tekshiruvi** | Har bir fotohisobot uchun 7 bosqichli tekshiruv: EXIF/geobelgi, perseptiv xesh boʻyicha dublikatlarni aniqlash, qoʻlda sozlangan qurilish bosqichi klassifikatori, oldingi hisobot bilan jarayonni solishtirish va vizual xavf koʻrsatkichlari (SIV, yoriqlar, chiqindilar). | Ixtiyoriy (quyida qarang) | [`readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) | [`project_detail_readiness.dart`](b2b/lib/features/residence/project_detail_readiness.dart) |
| **SI xaridor konsultanti** | Katalog ustidagi dialog qatlami. | **Ha — OpenAI** | [`openai_client.dart`](server/lib/src/ai/openai_client.dart), [`prompts.dart`](server/lib/src/ai/prompts.dart) | [`ai_chat_sheet.dart`](b2c/lib/features/ai/presentation/ai_chat_sheet.dart) |

Tayyorlik dvijogi ixtiyoriy ravishda oʻz mahalliy natijasi ustiga GPT-vision oʻtishini qoʻshib qoʻyishi mumkin (`AI_VISION_ENABLED`, birlamchi holatda oʻchirilgan); agar bu chaqiriq muvaffaqiyatsiz boʻlsa, vaqt tugasa yoki oʻchirilgan boʻlsa — deterministik mahalliy natija oʻzgarishsiz yuboriladi. Barcha SI HTTP endpointlari (`/v1/ai/search`, `/v1/ai/search/suggest`, `/v1/ai/crm/leads`, `/v1/ai/crm/query`, `/v1/ai/chat`, fotohisobotlarni tekshirish) [`ai_routes.dart`](server/lib/src/ai/ai_routes.dart) da ulangan; foydalanish IP/foydalanuvchi boʻyicha kvota bilan cheklangan [`ai_quota.dart`](server/lib/src/ai/ai_quota.dart).

### 7.1. Qamrov

- Har bir fotohisobot eʼlon qilinishidan oldin deterministik tekshiruvdan oʻtadi — monitoring uzluksiz, tanlab emas.
- Tayyorlik tekshiruvi hisobot eʼlon qilinishidan oldin **koʻrib chiqish (preview)** sifatida ishlaydi (`POST /v1/admin/projects/<id>/photo-reports/analyze`): u belgilaydi va tasniflaydi, lekin oʻzi eʼlon qilmaydi yoki rad etmaydi — natija boʻyicha qarorni administrator qabul qiladi.
- Past ishonchli tasniflash qattiq radni avtomatik ravishda notoʻgʻri radlashning oʻrniga "qoʻlda tekshirish" belgisiga tushiradi.

### 7.2. Toʻlovchilar uchun nima beradi

| Kim toʻlaydi | SI nima beradi |
|---|---|
| **Quruvchi** (obuna) | Bir xil trafikda koʻproq yakunlangan lidlar; tasdiqlangan hisobotlar tasdiqlangan quruvchi maqomini qoʻllab-quvvatlaydi. |
| **Bank** (tasdiqlash · lidlar) | Uzluksiz monitoring plyus nizoli holatlar boʻyicha mutaxassis oʻz shtatidan arzonroq; referal havola ipoteka/kredit arizalarini keltiradi. |
| **iBuild** (marja) | Monitoring tan narxi tushadi: obyektlar soni oʻsishi bilan xizmat bank shtatidan arzon qolib qoladi. |

### 7.3. Vendorlar bilan rejalashtirilgan integratsiyalar

Hali amalga oshirilmagan, bu repozitoriyada kod yoʻq — kelajak uchun koʻrib chiqilayotgan integratsiyalar, yuqoridagi oʻz dvijoklarimizdan alohida, biri ikkinchisi bilan aralashib ketmasligi uchun:

| Vendor | Vazifasi | Holati |
|---|---|---|
| **Newo AI** | Ovozli yordamchi va kol-markaz: katalog boʻyicha javob beradi va xaridor afzalliklariga koʻra obyektlarni tanlaydi — bitim turi, tuman, byudjet, xonalar soni. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span> |
| **Karmon AI** | Byudjetlashtirish: boʻlib-toʻlov va ipoteka hisobga olingan xarid byudjeti, loyiha xarajatlarini rejalashtirish. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span> |

### 7.4. Bizning SI analoglardan qanday farq qiladi

Server kodining haqiqiy holatiga asoslangan batafsil tahlillar — marketing matni emas:

| Mavzu | Hujjat | Nima haqida |
|---|---|---|
| **Aqlli qidiruv (b2c)** | [`AI_SEARCH_DIFFERENTIATORS.md`](AI_SEARCH_DIFFERENTIATORS.md) | Inkorni qayta ishlash, niyat aniq boʻlmaganda soʻrovlarni bloklash, ishonch indeksi bilan domen reytingi, imkonsiz qulayliklarni yumshatish, bajarilish trace |
| **CRM SI (b2b)** | [`AI_CRM_DIFFERENTIATORS.md`](AI_CRM_DIFFERENTIATORS.md) | Sabab kodlari bilan tushunarli skoring, koʻchmas mulk inventar signallari, SLA va sukut eskalatsiyasi, boshqariladigan yordamchi daraxti (erkin chat emas), talab va boʻsh yunitlar |

---

## 8. Xaridorlar uchun imkoniyatlar

| Imkoniyat | Holat |
|---|---|
| Xarid / Ijara / Yangi qurilish filtrlari bilan xarita va qidiruv | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span> |
| Kvartira va ofislar uchun jonli "shaxmat taxtasi" panjarasi | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span> |
| Bir tegishda soʻrov: koʻrish, qoʻngʻiroq, band qilish, ijara | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span> |
| Qurilish jarayoni boʻyicha sanalangan fotohisobotlar tasmasi | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span> |
| Ikki tayyorlik chizigʻi va ishonch indeksi | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Tasdiqlangan hujjatlar bilan quruvchi kartochkasi | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span> |
| Ipoteka, boʻlib-toʻlov va ijara daromadliligi kalkulyatorlari | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Sevimlilar, saqlangan qidiruvlar, "Mening soʻrovlarim", sharhlar, uch til | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Narx va qurilish bosqichlari boʻyicha push-bildirishnomalar | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Ipoteka/kredit uchun bank referal havolasi; ovozli tanlov (Newo AI) | <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">reja</span> |

---

## 9. Biznes uchun imkoniyatlar

| Imkoniyat | Holat |
|---|---|
| Loyihalar, korpuslar, yunitlar, media kutubxona, planirovkalar | <span style="background:#e8f0e4;color:#5a7a2f;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #c5d6a8">yaxshilanmoqda</span> |
| Ziddiyatlardan himoyalangan tahrirlash bilan "shaxmat taxtasi" muharriri | <span style="background:#e8f0e4;color:#5a7a2f;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #c5d6a8">yaxshilanmoqda</span> |
| Lidlar CRM: funnel, statuslar, teglar, voqealar tarixi | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span> |
| Fotohisobotlar va rejalashtirilgan qurilish jadvalini kiritish | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Analitika: talab, funnel, lid konversiyasi | <span style="background:#e6f3ef;color:#14866d;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #b7ded2">amalga oshirilgan</span> |
| Quruvchini tasdiqlash, loyiha/sharh moderatsiyasi, audit jurnali | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Ogohlantirishlar, jumladan jadvaldan tanqidiy chetlanish ogohlantirishlari | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Bank oʻtkazmasi orqali obuna toʻlovi | <span style="background:#fdf2dc;color:#b8860b;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #e8d4a2">ishlanmoqda</span> |
| Bank hisobotlari va ipoteka/kredit referal lidlari | <span style="background:#eef1f5;color:#5a6270;padding:1px 6px;border-radius:3px;font-size:0.85em;font-weight:700;border:1px solid #ccd2da">reja</span> |

---

## 10. Analoglardan farqi

- Eʼlonlar taxtalari **koʻrishlarni** sotadi, iBuild — **monitoring va tasdiqlashni**.
- **Manba.** Faqat tasdiqlangan hujjatlarga ega quruvchilar.
- **Mavjudlik va narx.** Eskirgan eʼlonlar oʻrniga jonli "shaxmat taxtasi".
- **Qurilish jarayoni.** Reklama suratlari oʻrniga sanalangan hisobotlar va ishonch indeksi.
- **Muddat buzilishi.** Sukunat oʻrniga SI belgisi, ogohlantirish va mutaxassis tashrifi.
- **Bank va davlat.** Tasdiqlash, ipoteka/kredit referal lidlari, idoraga axborot signali.

---

## 11. Monetizatsiya

Faqat biznes toʻlaydi. Quruvchi — obuna va ilgari surish; bank — obyektni tasdiqlash va, rejaga koʻra, referal havola orqali ipoteka/kredit lidlari. Xaridor toʻlamaydi.

| Manba | Kimdan | Tavsif |
|---|---|---|
| Quruvchi obunasi | Quruvchilar | Eʼlon qilish, CRM, analitika. Start / Growth / Scale |
| Ilgari surish va lid paketlari | Quruvchilar | Qidiruvda joylashuv; tarif limitidan ortiq lidlar |
| Banklar uchun tasdiqlash | Banklar | Kreditlashtiruvchi xizmati sifatida qurilish jarayoni monitoringi/tasdiqlashi <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span> |
| Bankka referal lidlar | Banklar | Referal havola orqali ipoteka yoki kredit arizasi <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">reja</span> |

---


## Repository / Репозиторий

| Path | Purpose |
|---|---|
| [`b2c/`](b2c/) | Buyer app — search, map, project pages, favorites, requests |
| [`b2c/lib/features/ai/`](b2c/lib/features/ai/) | Buyer-side smart search UI (search bar, results, ghost-text suggest) |
| [`b2b/`](b2b/) | Developer & platform admin — CRM, units, media, moderation |
| [`b2b/lib/features/ai_crm/`](b2b/lib/features/ai_crm/) | CRM AI assistant UI (bot sheet, lead/metric cards, band pills) |
| [`server/`](server/) | API — REST, WebSocket, PostgreSQL |
| [`server/lib/src/ai/`](server/lib/src/ai/) | AI engines — smart search, CRM lead scoring, readiness/photo analysis, chat |
| [`AI_SEARCH_DIFFERENTIATORS.md`](AI_SEARCH_DIFFERENTIATORS.md) | Smart search vs ordinary search — code-backed explanation |
| [`AI_CRM_DIFFERENTIATORS.md`](AI_CRM_DIFFERENTIATORS.md) | CRM AI vs typical CRM AI — code-backed explanation |
| [`packages/`](packages/) | Shared Dart packages (theme, models, widgets) |
| [`ibuild-wiki/`](ibuild-wiki/) | Internal project reference (full HTML version) |

---

<p align="center">
  <sub>iBuild Wiki · © iBuild</sub>
</p>
