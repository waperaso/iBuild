# iBuild API

Dart backend shared by the B2C and B2B Flutter apps — REST catalogue, auth, leads, admin routes, and WebSocket live unit updates.

See the [root README](../README.md) for an overview of the iBuild platform.

```bash
dart pub get
dart run bin/server.dart
# http://0.0.0.0:4000
```

Optional PostgreSQL persistence: set `DB_*` in `server/.env` (see `.env.example`).
