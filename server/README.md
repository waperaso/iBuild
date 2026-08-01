# iBuild — Dev Server (Dart)

A lightweight Dart backend shared by the **B2C** ([`../b2c`](../b2c)) and
**B2B** ([`../b2b`](../b2b)) Flutter clients. Implements the REST envelope,
resource paths, auth, admin APIs, and WebSocket events from
[`../docs/08-api.md`](../docs/08-api.md). Optional NestJS migration is
documented in [`../docs/14-tech-stack.md`](../docs/14-tech-stack.md) — same
contract, swap the implementation later.

Built with [`shelf`](https://pub.dev/packages/shelf) +
[`shelf_router`](https://pub.dev/packages/shelf_router) +
[`shelf_web_socket`](https://pub.dev/packages/shelf_web_socket).

## Running it

```bash
dart pub get
dart run bin/server.dart
# iBuild dev server listening on http://0.0.0.0:4000
# Seeded 18 projects (15 residential, 3 business centres).
```

Bootstrap a platform admin (local dev only — the endpoint is disabled unless
`BOOTSTRAP_ADMIN_ENABLED=true`, and production refuses to start with a weak
`BOOTSTRAP_ADMIN_SECRET`). In production, list the operator's number in
`SYSTEM_ADMIN_PHONES` instead and it is promoted on first sign-in:

```bash
curl -X POST http://localhost:4000/v1/platform/bootstrap-admin \
  -H "Content-Type: application/json" \
  -d "{\"secret\":\"ibuild-local-demo-secret\",\"phone\":\"+998901111111\"}"
```

Set `PORT` to run on something other than `4000`. Configuration is read
from the environment **and from `server/.env`, which is auto-loaded on
startup** (`lib/src/env_loader.dart`; real env vars win over the file).
With no `DB_HOST` in either place there's no database — everything lives in
an in-memory `Store` (`lib/src/store.dart`), reseeded from scratch on every
restart. Set `DB_HOST` (see
[Persistence](#persistence-optional-postgresql) below) to back it with
PostgreSQL instead (**one shared DB for B2C + B2B**), with zero other code
changes. This repo ships a gitignored `server/.env` pointing at the local
dev database, so a plain `dart run bin/server.dart` persists out of the
box once PostgreSQL is running — on Windows without Docker,
[`scripts/db-local.ps1`](scripts/db-local.ps1) starts it in one command,
see
[Local dev database (Windows, no Docker)](#local-dev-database-windows-no-docker).

Then point the Flutter clients at it:

```bash
cd ../b2c
flutter run -d chrome \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://localhost:4000/v1 \
  --dart-define=WS_URL=ws://localhost:4000/v1/ws

cd ../b2b
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:4000/v1
```

## Seed data

[`lib/src/seed_data.dart`](lib/src/seed_data.dart) generates 18 Tashkent
projects (15 residential complexes + 3 business centres) spread across real
districts (Yashnobod, Mirzo Ulugbek, Yunusabad, Chilanzar, Mirabad, Sergeli,
Olmazor, Bektemir, Uchtepa, Shayxontohur, Yakkasaray, Yangihayot), each with:

- A developer **and an assigned realtor** (name + direct phone number +
  headshot placeholder) for the "Call agent" button in the client.
- Amenities drawn from a realistic pool — swimming pool, sauna, spa, gym,
  concierge, kindergarten, smart-home, etc.
- Sale pricing, rent pricing, or both (several complexes keep a portion of
  units for long-term rent alongside units for sale).
- Multiple buildings, each with several floors × units per floor, cycling
  through distinct apartment layouts (1/2/3/4-room) or office layouts
  (open-plan / cabinet / corner-suite) — this is what powers the client's
  "look inside the residence" **Floor plans** tab and per-unit galleries.
- Cover photos, gallery photos/renders, and floor-plan placeholder images
  (real Tashkent photos from Wikimedia Commons for galleries; picsum.photos
  for floor plans and agent avatars, deterministic per-entity).
- A couple of active offers (discounts / installment plans) per project.

Keep this in sync by hand with `../b2c/lib/models/*.dart` if either the
client's model shape or this seed shape changes — the server has no
compile-time dependency on the Flutter package, only a matching wire format.

## API

All responses use the envelope `{ success, data, meta?, error? }` (see
`lib/src/http_helpers.dart`), matching what the client's `apiClientProvider`
Dio interceptor expects.

| Method | Path | Notes |
|---|---|---|
| GET | `/v1/health` | Liveness check |
| GET | `/v1/projects` | `?mode=buy\|rent\|newBuilds`, `?type=`, `?status=`, `?district=`, `?search=`, `?page=` (default `1`), `?limit=` (default `20`) |
| GET | `/v1/projects/:id` | Full project incl. buildings/units |
| GET | `/v1/projects/:id/units` | Flattened unit list |
| GET | `/v1/projects/:id/offers` | Active offers |
| GET | `/v1/units/:id` | Single unit |
| GET | `/v1/leads` | **Auth required.** Own leads; system admins get all. |
| POST | `/v1/leads` | **Auth required.** Create a lead — `projectId`, `intent` and `consent: true` required. Rate-limited. |
| POST | `/v1/auth/otp/send` | Body `{ phone }` → `{ requestId }`. The code is never in the response. |
| POST | `/v1/auth/otp/verify` | Body `{ requestId, code }` → `{ accessToken, refreshToken, user }`. Dev-mode fixed code `123456`; production uses a random code over SMS. |
| POST | `/v1/auth/logout` | **Auth required.** Revokes both halves of the token pair — the refresh token stops working too. |
| GET | `/v1/static/uploads/:file` | Public operator uploads (unit media, photo reports). |
| GET | `/v1/documents/:file` | **Auth required.** KYC paperwork from `uploads/private/`. Readable only by the developer who uploaded it and platform admins. |
| GET | `/v1/ws` | **Auth required** (Bearer header or `?access_token=`). WebSocket upgrade — see below |

Admin, platform and developer routes (`/v1/admin/*`, `/v1/platform/*`,
`/v1/developers/*`) are mounted separately in `lib/src/admin_routes.dart` —
see [`../docs/08-api.md`](../docs/08-api.md) for the full contract.

Query params are validated: `?limit=` is capped at `100`, `?status=` must be
one of `planned|under_construction|ready|handed_over`, and a body that is not
a JSON object is rejected with `422 VALIDATION_ERROR` rather than a 500.

Uploads are capped at 15 MB (`413 PAYLOAD_TOO_LARGE` beyond that) and stored
under a random name with a whitelisted extension; anything unrecognised is
written as an inert `.bin`. Calculator terms are capped at 50 years.

Publishing a project requires an active subscription **and** room inside the
tier's `maxProjects` allowance (`GET /v1/subscription-plans`): Start 3, Growth
10, Corporate unlimited. Exceeding it answers `402 PLAN_LIMIT_REACHED`.
Re-publishing a project that is already live does not consume a second slot.

### WebSocket events

Connect to `ws://localhost:4000/v1/ws`. The server pushes:

- `unitStatusChanged` — every ~8s a random unit flips status
  (`available → reserved → sold/rented → available`), simulating the live
  "шахматка" availability grid.
- `leadCreated` — broadcast whenever any client submits a new lead.

Frames are JSON: `{ "event": "...", "data": { ... } }`.

### Phone-OTP auth (dev mode)

`POST /v1/auth/otp/send` and `POST /v1/auth/otp/verify` (`lib/src/store.dart`)
stand in for a real SMS-based OTP provider:

1. `send` takes `{ "phone": "+998901234567" }`, stores an in-memory
   `requestId -> phone` mapping (5-minute TTL) and returns
   `{ "requestId": "..." }`. No SMS is actually sent.
2. `verify` takes `{ "requestId": "...", "code": "123456" }` — the fixed dev
   code is always `123456`. On success it creates the user on first sign-in
   (keyed by phone) and returns opaque `accessToken`/`refreshToken` strings
   (random UUIDs, not real JWTs) plus `{ id, phone, name }`.

Tokens aren't verified on public catalogue routes. Protected routes
(`/leads`, `/users/me/*`, `/admin/*`, `/platform/*`, `/developers/*`)
require `Authorization: Bearer <accessToken>`.

Brute-force protection: at most `kMaxOtpAttempts` (5) wrong codes per
`requestId` before it is invalidated, codes are compared in constant time, and
`/auth/otp/send` + `/auth/otp/verify` are IP rate-limited. Behind a reverse
proxy — or in Docker — that means **`TRUST_PROXY=true` is required**,
otherwise every request appears to come from one address and shares a single
bucket. The server refuses to start in production without it in either case.
See [`docs/DEPLOYMENT_SSH.md`](../docs/DEPLOYMENT_SSH.md) §5.

## Persistence (optional PostgreSQL)

Without `DB_HOST` the server is **fully in-memory** — every test in
`test/` relies on this and it never changes: with no `DB_*` configuration
nothing about the server's behavior changes from before PostgreSQL support
existed.

Set `DB_HOST` (plus the other `DB_*` vars below, as needed) — either as
real environment variables or in the auto-loaded `server/.env` — to opt
into a PostgreSQL-backed persistence layer underneath the same in-memory
model:

| Env var | Default | Notes |
|---|---|---|
| `DB_HOST` | _(unset)_ | Unset/empty → pure in-memory mode. Setting this is what turns persistence on. |
| `DB_PORT` | `5432` | |
| `DB_NAME` | `ibuild` | |
| `DB_USER` | `postgres` | |
| `DB_PASSWORD` | _(empty)_ | |
| `DB_SSL` | `false` | `true` to require SSL (`SslMode.require`) |

See `lib/src/db/pg_config.dart` for the exact parsing (`PgConfig.fromEnv`).

What happens when `DB_HOST` is set (`Store.create` in `lib/src/store.dart`):

1. Connects to PostgreSQL and applies any pending SQL files under
   [`migrations/`](migrations) (tracked in a `schema_migrations` table, so
   re-running is idempotent).
2. If the `projects` table is empty (first run against this database), it
   seeds the database from the same in-memory seed data
   (`buildProjectsSeed()`) that pure in-memory mode uses, plus the demo
   reviews/rental listings.
3. Otherwise (subsequent runs), it **replaces** the in-memory
   `projects`/`leads`/`reviews`/`rentalListings` (and loads users,
   sessions, developers, subscriptions, favorites, saved searches, and the
   audit log) from what's already persisted — so restarting the server
   resumes from real state instead of re-seeding fresh randomized data.
4. From then on, every mutation writes through to PostgreSQL
   (fire-and-forget, logged to stderr on failure — a transient DB hiccup
   never breaks an HTTP response or WebSocket broadcast): accounts and
   sessions, developer registrations/verification, subscriptions, project
   create/update/moderation, buildings, units (all fields incl. the
   periodic status ticker), unit media, offers, leads (incl. CRM fields),
   reviews, rental listings, favorites, saved searches, and audit entries.

If connecting/migrating fails, a **prominent warning** is logged to stderr
and the server falls back to pure in-memory mode rather than refusing to
start — watch the `Persistence:` line printed at startup to confirm which
mode you're actually in.

Pending phone-OTP request codes stay in-memory in both modes (5-minute
TTL, by design). Users and issued sessions **are** persisted, so accounts
and Bearer tokens survive restarts.

Migrations under `migrations/` are applied in filename order on startup and
recorded in `schema_migrations`, so adding a numbered `.sql` file is all that
is needed — there is no list to register it in.

### Local dev database

Any of:

- **Docker**: `docker-compose up -d` starts a `postgres:13` container
  matching [`.env.example`](.env.example) (copy it to `.env` or export the
  same vars).
- **Windows without Docker**: see
  [below](#local-dev-database-windows-no-docker) — a portable PostgreSQL
  install + two convenience scripts.
- **Any other reachable PostgreSQL 13+**: point `DB_HOST`/`DB_PORT`/
  `DB_NAME`/`DB_USER`/`DB_PASSWORD` at it — nothing about this server is
  coupled to Docker.

```bash
cp .env.example .env   # already matches docker-compose.yml; auto-loaded
docker-compose up -d
dart run bin/server.dart
```

### Local dev database (Windows, no Docker)

Docker Desktop isn't available on every dev machine. This is the
Docker-free alternative used to develop this server on Windows —
[`scripts/db-local.ps1`](scripts/db-local.ps1) and
[`scripts/run-with-db.ps1`](scripts/run-with-db.ps1) wrap it into two
one-line commands for everyday use.

**First-time setup** (once per machine):

1. Download the portable ("zip", no-installer) Windows build of PostgreSQL
   13+ from [EnterpriseDB](https://www.enterprisedb.com/download-postgresql-binaries)
   and extract it to `.tools/pg/` at the repo root, so the binaries end up
   at `.tools/pg/pgsql/bin/*.exe`. `.tools/` is machine-local and already
   covered by the root `.gitignore` — never commit it.
2. Initialize a data directory (only once):
   ```powershell
   cd server
   .tools\pg\pgsql\bin\initdb.exe -D ..\.tools\pgdata -U postgres --pwfile=<(echo postgres)
   ```
   (`--pwfile` needs a real file path on Windows — write `postgres` to a
   temp `.txt` file and pass that path instead of the Unix-style
   `<(...)` above.)
3. Start it and create the `ibuild` role + database that
   [`.env.example`](.env.example) expects:
   ```powershell
   .\scripts\db-local.ps1 start
   $env:PGPASSWORD = 'postgres'
   .tools\pg\pgsql\bin\psql.exe -h localhost -p 5432 -U postgres -d postgres -c "CREATE ROLE ibuild LOGIN PASSWORD 'changeme'; CREATE DATABASE ibuild OWNER ibuild;"
   ```

**Every-day use** (after first-time setup):

```powershell
cd server
.\scripts\db-local.ps1 start      # start PostgreSQL (idempotent)
dart run bin/server.dart          # DB_* comes from the auto-loaded .env
# ... work ...
.\scripts\db-local.ps1 stop       # when you're done
```

(`.\scripts\run-with-db.ps1` still works too — it exports the same `DB_*`
values as real env vars before launching, which simply override `.env`.)

`db-local.ps1` also takes `status` (is it running / what PID) and `psql`
(drops you into an interactive `psql` session on the `ibuild` database).

The very first connection auto-applies the schema
([`migrations/0001_init.sql`](migrations/0001_init.sql)) and seeds it from
`seed_data.dart` since the `projects` table starts empty — see
[Persistence](#persistence-optional-postgresql) above. If you need to
force a re-seed later (e.g. after changing `seed_data.dart`), wipe the
tables first: `.\scripts\db-local.ps1 psql` then
`TRUNCATE media, offers, units, buildings, leads, sessions, users, projects, developers RESTART IDENTITY CASCADE;`.

### Deploying to a real server

**Step-by-step SSH runbook** (bare Ubuntu → Dart API under systemd + both
Flutter web apps behind nginx/TLS, with backups and troubleshooting):
[`docs/DEPLOYMENT_SSH.md`](../docs/DEPLOYMENT_SSH.md).

**Docker + autodeploy on push to `main`** (the API in a container, built and
shipped by GitHub Actions with health-checked rollout and automatic rollback):
[`docs/DEPLOYMENT_DOCKER.md`](../docs/DEPLOYMENT_DOCKER.md). The image is built
from [`Dockerfile`](Dockerfile); `deploy/docker-compose.yml` is the compose
file that runs on the server. `docker-compose.yml` in this directory is
unrelated — it is the local-dev PostgreSQL described above.

### Production target: aHOST.uz

**aHOST-specific notes (cPanel, managed PostgreSQL, shared hosting vs VDS):**
[`docs/HOSTING_AHOST.md`](../docs/HOSTING_AHOST.md).

This dev server stands in for a future production backend on
[aHOST.uz](https://ahost.uz), an Uzbekistan hosting provider whose shared
hosting **and** VDS plans both come with cPanel + a managed PostgreSQL 13 —
the same major version this schema targets. Deploying there is just
pointing `DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASSWORD`/`DB_SSL` at
aHOST's PostgreSQL connection details; no code changes needed. The one
real decision is **shared hosting vs. VDS** — see below.

#### 1. Create the database (cPanel, same steps on shared hosting or VDS)

1. Log into cPanel (credentials are emailed after ordering the plan).
2. Open **Databases → PostgreSQL Databases**.
3. Under **Create New Database**, enter a name (e.g. `ibuild`) → *Create
   Database*.
4. Under **PostgreSQL Users**, create a user + password → *Create User*.
5. Under **Add User To Database**, link the user to the database and grant
   it **ALL PRIVILEGES**.
6. Note the fully-qualified name cPanel gives the DB/user — it's usually
   prefixed with your cPanel account name, e.g. `cpaneluser_ibuild` /
   `cpaneluser_ibuild_user`, not the plain name you typed.
7. (Optional, to load existing data) use **phpPgAdmin**, linked from the
   same PostgreSQL Databases page, to run
   [`migrations/0001_init.sql`](migrations/0001_init.sql) by hand, or just
   let the server apply it automatically on first connect (step 3 below).

cPanel's managed PostgreSQL only accepts connections from **localhost** on
the same account (no remote `DB_HOST` from off-box, per aHOST's own docs —
enabling remote TCP/IP requires root access to `postgresql.conf`/
`pg_hba.conf`, which shared hosting doesn't give you). In practice this
means the server process and the database must run **on the same aHOST
box**, which is exactly what VDS gives you and shared hosting doesn't (see
below) — plan accordingly.

#### 2. Where the Dart server itself runs

cPanel's "Setup Node.js/Python/Ruby App" tooling on **shared hosting**
doesn't list Dart as a supported runtime, so shared hosting is realistically
**database-only** for this project (use it to host the PostgreSQL instance,
not the API process).

**VDS** (full root SSH access) is what actually runs the server:

1. `apt install` (or equivalent) the [Dart SDK](https://dart.dev/get-dart),
   or just ship a self-contained AOT executable built with
   `dart compile exe bin/server.dart -o ibuild-server` from your dev
   machine and `scp` that single binary over — no Dart SDK needed on the
   VDS at all in that case.
2. Set the `DB_*` env vars (from step 1 above) plus `PORT` (e.g. `4000`)
   and `ALLOWED_ORIGINS` (comma-separated list of your real client
   origins — leave `DB_SSL=false` since the DB is on `localhost`).
3. Run it under a process manager so it survives reboots/crashes, e.g. a
   `systemd` unit:
   ```ini
   # /etc/systemd/system/ibuild-server.service
   [Unit]
   Description=iBuild API server
   After=postgresql.service

   [Service]
   EnvironmentFile=/etc/ibuild-server.env   # DB_HOST=localhost, etc.
   ExecStart=/opt/ibuild/ibuild-server
   Restart=on-failure
   User=ibuild

   [Install]
   WantedBy=multi-user.target
   ```
   ```bash
   systemctl enable --now ibuild-server
   ```
4. Put Apache/nginx (already part of the cPanel/VDS stack) in front of it
   as a reverse proxy for `api.ibuild.uz` → `http://127.0.0.1:4000`,
   including the `/v1/ws` WebSocket upgrade headers, and issue it a free
   cPanel SSL certificate — this is what lets the client use
   `https://api.ibuild.uz/v1` / `wss://api.ibuild.uz/v1/ws`
   ([`b2c/lib/core/config/env.dart`](../b2c/lib/core/config/env.dart)'s
   production defaults) with zero further client changes.

The very first boot against the fresh cPanel database behaves exactly like
local dev: `migrate()` applies the schema and, finding `projects` empty,
seeds it from `seed_data.dart` — no manual import step required unless you
did the optional phpPgAdmin import above.

## CORS

`corsHeaders()` (`lib/src/http_helpers.dart`) reflects **loopback origins
only** (`localhost`/`127.0.0.1`/`::1`) when `ALLOWED_ORIGINS` is unset, so
the Flutter **web** build (served from a different port by
`flutter run -d chrome`/`web-server`) can call this API with zero config
locally while remote origins stay blocked. Set `ALLOWED_ORIGINS`
(comma-separated, e.g. `https://app.ibuild.uz,https://ibuild.uz`) in
production to allow your real client origins — only origins in that list
get `Access-Control-Allow-Origin` echoed back. `ALLOWED_ORIGINS=*` opts
into the legacy permissive wildcard behavior explicitly.
