# iBuild

**Construction-loan tranche platform for Uzbekistan**  
Developer cabinet · bank cabinet · platform admin · shared API

**English** · [Русский](README.ru.md) · [Oʻzbekcha](README.uz.md)

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Shelf%20API-0175C2?logo=dart&logoColor=white)
![Stage](https://img.shields.io/badge/stage-pilot-orange)

**Contents:** Repository · Status · Roles · Tranche flow · Bank cabinet · Registration and CRM · Security · Docs

> The previous version of this project (a new-build marketplace with AI photo verification) is kept in the branch [`archive/legacy-v1`](https://github.com/waperaso/iBuild/tree/archive/legacy-v1). `main` is the new iBuild.

---

## Repository

| Path | Role |
| --- | --- |
| [app/](app) | One Flutter Web app for every role — developer, contractor, technical supervisor, bank, platform admin. Russian, English, Uzbek |
| server | Dart REST API and PostgreSQL — **private**, not published in this repository |
| [docs/](docs) | MVP scope, registration and legal notes |

---

## Status

| Layer | Status |
| --- | --- |
| Budget per project: limit, in tranches, paid out, balance | **live** |
| Tranche request with photos: draft → technical check → director → bank → paid | **live** |
| Payment record and rollback of approval when money did not leave | **live** |
| Bank cabinet: queue, SLA timers, committee, rules and routes, reports | **live** |
| Inspections ordered by the bank, loan desk and draw wizard | **live** |
| Public registration of developers and banks, admin CRM with call log and checks | **live** |
| Read-only demo: role buttons on the sign-in page, isolated from real companies | **live** |
| Password change, forced change on first login, session and CSRF protection | **live** |
| Email notifications and scheduled bank reports | **alpha** |
| CSV registry of requests | **live** |
| Public HTTPS deployment | **planned** — the pilot runs as a local stand |
| Direct payments, e-signature, state registry APIs, SMS, Telegram | **planned** |

---

## Roles

One account has one role on a project. A contractor never reviews their own request.

| Role | Can | Cannot |
| --- | --- | --- |
| Developer (director) | Create projects, set the budget, assign people, approve and record payments | See another company |
| Contractor | See assigned projects, submit tranche requests with photos | See other requests, create a project |
| Technical supervisor | Confirm the work volume on site photos | Approve or record payment |
| Bank | Review, approve or reject a tranche, order inspections, run reports | Edit the developer's budget |
| Platform admin | Review applications, call and check applicants, approve and open accounts | — |

Hiding a button is not protection: the server checks role and membership on every request.

---

## Tranche flow

| Step | Status in the app | Money |
| --- | --- | --- |
| 1 | Draft | Not reserved |
| 2 | Under technical check | Reserved |
| 3 | Awaiting the director | Reserved |
| 4 | Approved for payment | Reserved until payment is recorded |
| 5 | Paid | Moves from reserved to paid |
| — | Rejected · Cancelled | Reserve is released |

Money is stored and transferred as strings of `NUMERIC(18,2)` — never as floating point. Currency: UZS.

---

## Bank cabinet

| Feature | Status |
| --- | --- |
| Queue of tranches with SLA timers and priorities | **live** |
| Tranche card: budget, photos, history, decision, payment | **live** |
| Roles inside the bank: loan officer, expert, department heads, credit committee, risk manager, bank admin | **live** |
| Approval rules and routes editable by the bank admin | **live** |
| Portfolio view, exports, scheduled reports | **alpha** |

---

## Registration and CRM

A developer or a bank leaves a long application on the public form. The platform admin works it as a CRM: status, call log, notes, document requests, required checks. Approval creates the company, the director account and the first project in one transaction. Applicants follow their application by a private link.

The document list and checks follow the laws of Uzbekistan (AML/KYC, personal data, shared construction). Details and open questions for a lawyer: [docs/registration.ru.md](docs/registration.ru.md). This is a working note, not legal advice.

---

## Security

The backend, database schema, deployment files and access tests are kept in a private repository. Access is enforced on the server for every request; the client only reflects it.

---

## Docs

| Document | Content |
| --- | --- |
| [docs/mvp.md](docs/mvp.md) | Pilot scope, roles, statuses |
| [docs/registration.ru.md](docs/registration.ru.md) | Registration, documents and legal notes |

---

iBuild · © iBuild
