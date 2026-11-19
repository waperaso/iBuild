# iBuild

**English** · [Русский](README.ru.md) · [Oʻzbekcha](README.uz.md)

Construction-loan monitoring. A bank releases a loan in tranches: the developer
requests each one with evidence, a site inspector confirms the work, the bank
decides what to fund, and every step stays in the journal.

Flutter Web and a Dart API on one origin, PostgreSQL in Docker.

---

## Quick start

Needs Docker, Flutter and Dart.

> **Build the web app with `--no-web-resources-cdn`.**
> Without that flag Flutter loads CanvasKit from `gstatic.com`, the server's
> Content-Security-Policy blocks the request, and the page stays blank.

```bash
(cd app && flutter build web --release --no-web-resources-cdn)
docker compose up -d --build
curl localhost:8080/api/ready
```

Then open <http://localhost:8080>.

The database is published on **5433**, because `5432` is usually taken by
another Postgres.

---

## Demo accounts

Password for every seeded login is `SEED_PASSWORD` from `.env` — `123456` by default.

### Developer side

`a.*` belong to Навои Девелопмент, `b.*` to Чиланзар Строй.

| Login | Role |
| --- | --- |
| `a.director` · `b.director` | Developer |
| `a.contractor` · `b.contractor` | Contractor |
| `a.tech` · `b.tech` | Site inspector |

### Bank workspace

| Login | Role |
| --- | --- |
| `a.observer` | Credit specialist |
| `a.expert` | Technical expert |
| `a.head1` … `a.head3` | Heads of department |
| `a.committee1` … `a.committee5` | Credit committee |
| `a.risk` | Risk manager |
| `a.bankadmin` | Bank administrator — rules and sign-off routes |
| `b.observer` | Credit specialist, second bank |

### Platform

| Login | Role |
| --- | --- |
| `a.admin` | iBuild administrator |
| `a.disabled` | Disabled on purpose — cannot sign in |

The sign-in page also offers a **read-only demo** for each role. A demo session
may look at everything and change nothing.

---

## Checks

```bash
cd app    && flutter analyze && flutter test
cd server && dart analyze    && dart test
```

Server tests need the pilot database on `5433`. They create and use
`ibuild_test` and never touch `ibuild`.

---

## Backup

A copy is taken from the running stand into `backups/`. Restore goes into a
separate `ibuild_restore` database, so the working `ibuild` is never
overwritten. The script checks that a request keeps its status, amount, history
and photo.

```bash
dir=$(./scripts/backup.sh)
./scripts/restore.sh "$dir"
```

---

## Accounts without the sign-up screen

```bash
cd server
export DATABASE_URL='postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable'
dart run bin/operator.dart create --inn 300000001 --login pilot.user --name "Name" --password "secret"
dart run bin/operator.dart reset-password --login pilot.user --password "secret"
dart run bin/operator.dart set-active --login pilot.user --active false
```

---

## Documentation

| Document | What it covers |
| --- | --- |
| [docs/presentation.ru.md](docs/presentation.ru.md) | the 12–15 minute product showing |
| [docs/audit-pre-demo.ru.md](docs/audit-pre-demo.ru.md) | pre-demo audit: what was fixed, what to watch |
| [docs/production.ru.md](docs/production.ru.md) | going to production |
| [docs/api.md](docs/api.md) | API contract |
| [docs/security-matrix.md](docs/security-matrix.md) | who may do what |

The request registry is `GET /api/requests.csv`. On the tranches screen the same
export follows the chosen project and status, and shows only the requests the
role could open anyway.

---

## Not a production server

The Compose file here is a local pilot stand: no public HTTPS, demo data seeded
on start. Production settings live in [docs/production.ru.md](docs/production.ru.md).
