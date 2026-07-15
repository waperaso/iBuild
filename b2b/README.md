# iBuild B2B Admin

Separate Flutter app for **platform admins** and **residence (ЖК) admins**.
Uses the **same Dart API + PostgreSQL database** as the B2C buyer app
(`../server`).

## Roles

| Role | Access |
|------|--------|
| `system_admin` | Platform: approve developers, moderate projects, set user roles |
| `residence_admin` | Own projects: units, media URLs, lead CRM |
| `ordinary_user` | Can apply as developer (`POST /developers`) |

## Run (against local server)

```bash
# Terminal 1
cd ../server && dart run bin/server.dart

# Bootstrap a system admin (once):
curl -X POST http://localhost:4000/v1/platform/bootstrap-admin \
  -H "Content-Type: application/json" \
  -d "{\"secret\":\"ibuild-dev\",\"phone\":\"+998901111111\"}"

# Terminal 2
cd ../b2b
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:4000/v1
```

Sign in with the bootstrapped phone; OTP is `123456` when Eskiz is not configured.

## Shared database

Point the server at PostgreSQL (`DB_HOST=...`) so B2C inventory, leads, and
B2B moderation share one schema (`migrations/0003_admin_and_user_data.sql`).
