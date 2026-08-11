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
  <a href="#русский">Русский</a>
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
8. [Buyer features](#8-buyer-features)
9. [Business features](#9-business-features)
10. [Differences](#10-differences-from-alternatives)
11. [Monetization](#11-monetization)
12. [Status and roadmap](#12-status-and-roadmap)

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
| **AI vendors** | Newo AI, Karmon AI, AI photo-report verification |
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

**Engineering — AI-native.** The codebase is written with agentic AI models in Cursor: **Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol**.

**In the product**, AI is a verification layer on vendor solutions — not a showcase. Own models are not trained; vendor APIs are plugged in so continuous informational monitoring stays affordable.

| Vendor | Role | Status |
|---|---|---|
| **Newo AI** | Voice assistant and call centre: answers on the catalogue and matches preferences — deal type, district, budget, rooms. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |
| **Karmon AI** | Budgeting: purchase budget with installments and mortgage, project expense planning. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span> |
| **AI verification** | Photo geotag/metadata (coords, date, device) and visual progress vs prior reports. Mismatches are flagged for clarification. | <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">in progress</span> |

### 7.1. Scope of AI

- **Every** report goes through machine verification — continuous, not sampling.
- AI flags and escalates; it **does not decide** — a human changes object status.
- Site visits are only for disputed reports, so headcount grows slower than inventory.
- Matching and budgeting are optional — the app works without them.

### 7.2. Value for payers

| Who pays | What AI delivers |
|---|---|
| **Developer** (subscription) | More completed leads at the same traffic; verified reports support verified-developer status. |
| **Bank** (verification · leads) | Continuous monitoring plus specialists on disputes costs less than an in-house team; referral link brings mortgage/loan applications. |
| **iBuild** (margin) | Monitoring unit cost falls; the service stays cheaper than a bank’s own staff as inventory grows. |

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

## 12. Status and roadmap

**Works today.** Search, chessboard, requests, CRM; platform panel; dual readiness bars.

**Next stage.** AI verification, Newo AI and Karmon AI, subscription billing, specialists (tech experts), government information exchange, bank contracts and mortgage/loan referral leads. IT Park residency and tax benefits are planned. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">planned</span>

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
8. [Возможности для клиентов](#8-возможности-для-клиентов)
9. [Возможности для бизнеса](#9-возможности-для-бизнеса)
10. [Отличия от аналогов](#10-отличия-от-аналогов)
11. [Монетизация](#11-монетизация)
12. [Статус и дорожная карта](#12-статус-и-дорожная-карта)

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
| **ИИ-вендоры** | Newo AI, Karmon AI, ИИ-верификация фотоотчётов |
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

**Инженерия — AI-native.** Код пишется агентными ИИ-моделями в Cursor: **Fable 5, Opus 4.8, Opus 5, Sonnet 5, GPT 5.6 Sol**.

**В продукте** ИИ — слой верификации на решениях вендоров, а не витрина. Собственные модели не разрабатываются — подключаются API вендоров, чтобы сплошной информационный мониторинг оставался доступным по себестоимости.

| Вендор | Назначение | Статус |
|---|---|---|
| **Newo AI** | Голосовой помощник и колл-центр: отвечает по каталогу и подбирает объекты по предпочтениям клиента — сделка, район, бюджет, комнатность. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |
| **Karmon AI** | Универсальный инструмент бюджетирования: расчёт бюджета покупки с учётом рассрочки и ипотеки, планирование расходов по проекту. | <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span> |
| **ИИ-верификация** | Геотег и метаданные снимка (координаты, дата, устройство) и визуальное сравнение прогресса с прошлыми отчётами. При несоответствии отчёт помечается как требующий уточнения. | <span style="background:#fdf2dc;color:#b8860b;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">в разработке</span> |

### 7.1. Объём участия

- Машинную верификацию проходит **каждый** отчёт: мониторинг сплошной, а не выборочный.
- ИИ помечает и передаёт дальше, но **решения не выносит** — статус объекта меняет человек.
- Посещение объекта нужно только по спорным отчётам: штат растёт медленнее числа объектов.
- Подбор и бюджет вспомогательны — приложение работает и без них.

### 7.2. Что это даёт плательщикам

| Кто платит | Что даёт ИИ |
|---|---|
| **Застройщик** (подписка) | Больше доведённых заявок при том же трафике; пройденная верификация отчётов подтверждает статус верифицированного застройщика. |
| **Банк** (верификация · лиды) | Сплошной мониторинг плюс специалист по спорным дешевле собственного штата; реферальная ссылка приводит заявки на ипотеку и кредит. |
| **iBuild** (маржа) | Себестоимость мониторинга падает: услуга дешевле банковского штата, маржа держится при росте объектов. |

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

## 12. Статус и дорожная карта

**Работает сегодня.** Поиск, «шахматка», заявка, CRM; панель платформы; две полосы готовности.

**Ближайший этап.** ИИ-верификация, Newo AI и Karmon AI, оплата подписок, специалисты (технические эксперты), взаимодействие с уполномоченными государственными органами, договоры с банками и реферальные лиды на ипотеку и кредит. Планируется получение резидентства в IT Park и налоговых льгот. <span style="background:#eef1f5;color:#5a6270;padding:1px 4px;border-radius:3px;font-size:0.8em;font-weight:700">план</span>

---

## Repository / Репозиторий

| Path | Purpose |
|---|---|
| [`b2c/`](b2c/) | Buyer app — search, map, project pages, favorites, requests |
| [`b2b/`](b2b/) | Developer & platform admin — CRM, units, media, moderation |
| [`server/`](server/) | API — REST, WebSocket, PostgreSQL |
| [`packages/`](packages/) | Shared Dart packages (theme, models, widgets) |
| [`ibuild-wiki/`](ibuild-wiki/) | Internal project reference (full HTML version) |

---

<p align="center">
  <sub>iBuild Wiki · © iBuild</sub>
</p>
