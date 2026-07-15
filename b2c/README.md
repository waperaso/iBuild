# iBuild — B2C Client (Flutter)

The buyer/tenant-facing app for the iBuild real-estate platform (see the root
[`IBUILD_APP_PLAN.md`](../IBUILD_APP_PLAN.md)). It targets **Android, iOS, Web
and Windows** from a single codebase, with responsive layouts for both phones
and the "computer view".

> For a step-by-step live demo script (recommended: real backend, not mock
> data), see [`../DEMO.md`](../DEMO.md).

Full theming, navigation, models, a repository layer, and every MVP client
screen are implemented end-to-end against a real running backend (see
[`../server`](../server)) — or against bundled mock data with zero setup.
This includes phone-OTP sign-in, favorites, search/filters, live WebSocket
availability, and pagination — see [Screens](#screens) below. Real maps SDK
integration is staged for later (see [Roadmap seams](#roadmap-seams)).

## Tech stack

| Concern | Choice |
|---|---|
| State / DI | `flutter_riverpod` (hand-written `Notifier`/`AsyncNotifier`, no codegen) |
| Routing | `go_router` (stateful shell) |
| Networking | `dio` + `web_socket_channel` |
| Models | `freezed` + `json_serializable` |
| Storage | `flutter_secure_storage`, `shared_preferences` |
| Maps | `flutter_map` + OSM tiles (Yandex Maps SDK later) |
| Fonts | `google_fonts` (Plus Jakarta Sans) |
| Localization | `flutter_localizations` + `intl` (gen-l10n), EN / RU / UZ |
| Backend (dev) | Dart `shelf` server in [`../server`](../server) — see below |

## Getting started

```bash
flutter pub get

# Generate freezed / json code (after editing models)
dart run build_runner build --delete-conflicting-outputs

# Regenerate AppLocalizations (after editing lib/l10n/*.arb) — `flutter pub get`
# and `flutter run`/`flutter build` also trigger this automatically because
# `generate: true` is set in pubspec.yaml.
flutter gen-l10n

# Run against bundled mock data (no backend needed) — see
# "Environment configuration" below for why the flag is required
flutter run -d chrome  --dart-define=USE_MOCK_DATA=true   # Web
flutter run -d windows --dart-define=USE_MOCK_DATA=true   # Windows desktop
flutter run -d <device> --dart-define=USE_MOCK_DATA=true  # Android / iOS
```

### Running the full stack (client + server)

The [`../server`](../server) folder is a small Dart backend that serves the
same REST/WebSocket contract the client expects. Start it first, then point
the Flutter client at it with `--dart-define`:

```bash
# Terminal 1 — backend (defaults to :4000)
cd ../server
dart pub get
dart run bin/server.dart

# Terminal 2 — client, talking to the live server
cd ../b2c
flutter run -d chrome \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://localhost:4000/v1 \
  --dart-define=WS_URL=ws://localhost:4000/v1/ws
```

The server seeds ~18 Tashkent residential complexes and business centres
(developers, assigned realtors + phone numbers, amenities, sale/rent pricing,
buildings/units/floor plans) on boot and simulates live unit-status changes
over WebSocket every few seconds — see
[`../server/README.md`](../server/README.md). By default that seed data is
purely in-memory (reset on every server restart); to persist it in a real
PostgreSQL database instead — locally or on the aHOST.uz production target —
see [`../server/README.md#persistence-optional-postgresql`](../server/README.md#persistence-optional-postgresql).
This only changes what backs the server; nothing on the client changes
beyond the `USE_MOCK_DATA=false` + server URLs above.

### Environment configuration

No secrets live in the repo. Configuration is injected at build time via
`--dart-define` (see [`lib/core/config/env.dart`](lib/core/config/env.dart)):

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.ibuild.uz/v1 \
  --dart-define=WS_URL=wss://api.ibuild.uz/v1/ws \
  --dart-define=USE_MOCK_DATA=false
```

`USE_MOCK_DATA` **defaults to `false`** (see
[`lib/core/config/env.dart`](lib/core/config/env.dart)), so a plain
`flutter run` with no flags talks to the API at `API_BASE_URL` — which itself
defaults to the unconfigured production URL `https://api.ibuild.uz/v1`. If
that host isn't reachable, the app will load but show nothing. There are
exactly two supported ways to run this app; pick one explicitly, don't rely
on the bare defaults:

**Mode A — real backend (recommended for anything beyond a quick local check,
and the only mode with a live WebSocket):**

```bash
flutter run -d chrome \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://localhost:4000/v1 \
  --dart-define=WS_URL=ws://localhost:4000/v1/ws
```

Requires [`../server`](../server) to be running — see
[Running the full stack](#running-the-full-stack-client--server) above. This
is the path used by [`../DEMO.md`](../DEMO.md) for live demos.

**Mode B — bundled mock data (no backend needed, e.g. CI or offline dev):**

```bash
flutter run -d chrome --dart-define=USE_MOCK_DATA=true
```

Runs end-to-end against `lib/models/mock_data.dart` with zero setup —
including the mock OTP bypass (code `123456`). Be aware this bundles only
**5 sample projects/developers** (versus the 18 the dev server seeds) and has
**no live WebSocket**, so unit-status changes never animate — fine for
UI/widget checks (this is what `flutter test` and CI use), not
representative of the full catalogue or the live-update story for a demo.

## Project structure

```
lib/
  main.dart            # ProviderScope + runApp
  app.dart             # MaterialApp.router + theme wiring
  core/
    config/            # env (dart-define)
    network/           # dio api_client, ws_client
    router/            # go_router table + stateful shell
    localization/      # locale_controller (active app language, persisted)
    theme/             # swappable color system (see below)
    utils/             # formatters (money, area, dates)
    widgets/           # shared UI: AppCard, AppChip, PillButton,
                       #   StatusBadge, AdaptiveScaffold, nav
  features/
    onboarding/  auth/  discovery/  map/  project/
    units/  leads/  favorites/  profile/
      presentation/    # screens + widgets
      providers/       # Riverpod state
  l10n/                # app_en/ru/uz.arb + generated AppLocalizations (gen/)
                       #   + enum_labels.dart (BuildContext-aware enum labels)
  models/              # freezed domain models + mock_data
```

Each feature holds `presentation/` (screens, widgets) and `providers/`
(Riverpod). Providers are `FutureProvider`/`AsyncNotifier`s backed by a
`data/*_repository.dart` per feature (`projects_repository.dart`,
`units_repository.dart`, `leads_repository.dart`) — the repository checks
`Env.useMockData` and either reads `models/mock_data.dart` or calls the
`apiClientProvider` (Dio). Screens render the resulting `AsyncValue` via the
shared [`AsyncValueView`](lib/core/widgets/async_value_view.dart) widget
(shimmer skeleton loading state / retry-able error state / data), so
switching between mock and live data is a one-line env change with no UI
code changes. Discovery, Favorites and My inquiries also wrap their body in
a `RefreshIndicator` that invalidates the relevant provider on pull.

## Theming — swappable color schema

Colors are fully decoupled from widgets so the palette can change without
touching UI code.

- [`core/theme/app_colors.dart`](lib/core/theme/app_colors.dart) — `AppColors`,
  a `ThemeExtension` of **semantic** tokens (`background`, `surface`, `accent`,
  `ink`, `unitAvailable`, …). Widgets never hardcode hex values.
- [`core/theme/color_schemes/lime_scheme.dart`](lib/core/theme/color_schemes/lime_scheme.dart)
  — the default palette (lime accent on cream), sampled from `DESIGN/`, with a
  dark variant.
- [`core/theme/app_theme.dart`](lib/core/theme/app_theme.dart) — builds
  `ThemeData` from any `AppColors` instance.
- [`core/theme/theme_controller.dart`](lib/core/theme/theme_controller.dart) —
  Riverpod provider driving the live palette + brightness (see the switcher on
  the Settings screen).

Widgets read colors ergonomically via `context.colors.accent`
([`app_theme_ext.dart`](lib/core/theme/app_theme_ext.dart)).

### Adding a new palette

1. Copy `lime_scheme.dart`, tweak the token values, export a new `AppColors`.
2. Add an entry to the `AppPalette` enum in `theme_controller.dart`.

No widget changes required.

## Responsive layout

Breakpoints live in [`core/theme/app_dimens.dart`](lib/core/theme/app_dimens.dart)
(`mobile < 700`, `tablet < 1100`, `desktop ≥ 1100`).
[`AdaptiveScaffold`](lib/core/widgets/adaptive_scaffold.dart) renders a floating
pill bottom nav on mobile and a left sidebar + centered max-width content on
desktop/web. List/grid screens adapt column counts via `context.screenSize`.

## Screens

Onboarding hero, phone-OTP Sign in/Verify, Discovery (Buy/Rent/New-builds
toggle + search bar + filter sheet + category chips + infinite-scroll
pagination + cards), Map (pins + draggable sheet), Project page (hero +
gallery + tabs), Availability grid ("шахматка", live-updating over
WebSocket), Unit card, Lead form, My inquiries, Favorites/Saved searches,
Profile/Settings.

### Search, filters & pagination

[`discovery_screen.dart`](lib/features/discovery/presentation/discovery_screen.dart)
has a search field and a filter-sheet icon
([`filter_sheet.dart`](lib/features/discovery/presentation/widgets/filter_sheet.dart):
district, status, price range) plus category chips (All / Apartments /
Offices / New builds), all backed by one
[`DiscoveryFiltersController`](lib/features/discovery/providers/filters_providers.dart).
`projectsProvider` ([`discovery_providers.dart`](lib/features/discovery/providers/discovery_providers.dart))
watches the discovery mode + filters together, calls
[`ProjectsRepository.fetchProjects`](lib/features/discovery/data/projects_repository.dart)
with the matching `mode`/`search`/`district`/`status`/`type`/`page`/`limit`
query params (price range is applied client-side), and exposes `loadMore()`
for the `CustomScrollView`'s infinite-scroll footer.

### Favorites

[`favorites_repository.dart`](lib/features/favorites/data/favorites_repository.dart)
persists a `Set<String>` of favorited project IDs to `shared_preferences`;
[`favorites_providers.dart`](lib/features/favorites/providers/favorites_providers.dart)
exposes a `Notifier` with `toggle(projectId)`. The heart icon on property
cards and the project page both call `toggle`, and the real
[`favorites_screen.dart`](lib/features/favorites/presentation/favorites_screen.dart)
filters `projectsProvider`'s results down to favorited IDs.

### Live availability

[`ws_client.dart`](lib/core/network/ws_client.dart) auto-reconnects with
exponential backoff (~1s → 30s cap) and re-subscribes any active project
rooms on reconnect.
[`live_unit_status_provider.dart`](lib/features/units/providers/live_unit_status_provider.dart)
subscribes to the current project on entry to the availability grid, and
overlays incoming `unitStatusChanged` events on top of the fetched grid so
cells recolor live without a refetch.

### Phone-OTP sign-in

[`auth_repository.dart`](lib/features/auth/data/auth_repository.dart) calls
the server's `/v1/auth/otp/send` + `/v1/auth/otp/verify` (dev code `123456`,
see [`../server/README.md`](../server/README.md#phone-otp-auth-dev-mode)) and
persists the returned tokens via `flutter_secure_storage`.
[`auth_providers.dart`](lib/features/auth/providers/auth_providers.dart)
restores the session on boot; the two-step
[`login_screen.dart`](lib/features/auth/presentation/login_screen.dart) →
[`otp_screen.dart`](lib/features/auth/presentation/otp_screen.dart) flow is
reachable from onboarding's "Sign in" button and from the Profile tab's
sign-in prompt. Browsing stays guest-accessible — nothing in the shell gates
on auth state.

### Looking inside a residence

The Project page's **Floor plans** tab
([`floor_plans_tab.dart`](lib/features/project/presentation/widgets/floor_plans_tab.dart))
groups every unit in the complex by layout (1/2/3/4-room, or office
open-plan/cabinet/corner-suite), shows a floor-plan thumbnail + area +
availability count per layout, and opens a bottom sheet listing the matching
apartments/offices — tap through to any unit's own gallery and details.
Both the project and unit screens use a full-screen swipeable
[`MediaGalleryViewer`](lib/features/project/presentation/widgets/media_gallery_viewer.dart)
for photos/renders/floor plans. The isometric hero on the project page
(["3D map preview"](lib/features/project/presentation/widgets/location_tracking_hero.dart))
also shows the assigned realtor's name/photo with a **Call agent** button
that dials their number directly via `url_launcher`.

## Localization — English, Russian, Uzbek

All UI copy is externalized to ARB files and generated into a typed
`AppLocalizations` class:

- [`lib/l10n/app_en.arb`](lib/l10n/app_en.arb) (template),
  [`app_ru.arb`](lib/l10n/app_ru.arb), [`app_uz.arb`](lib/l10n/app_uz.arb) —
  one key per string, `{placeholder}` ICU args for counts/dates/prices.
- [`lib/l10n/gen/`](lib/l10n/gen) — generated by `flutter gen-l10n` (see
  `l10n.yaml`); **do not hand-edit**, re-run the command after touching the
  ARB files.
- [`lib/l10n/enum_labels.dart`](lib/l10n/enum_labels.dart) — `BuildContext`-aware
  `.label(context)` extensions for domain enums (`UnitStatus`, `LeadIntent`,
  …), since the enums themselves (`packages/ibuild_core/lib/models/enums.dart`)
  stay UI-agnostic.
- [`core/localization/locale_controller.dart`](lib/core/localization/locale_controller.dart)
  — Riverpod controller for the active `Locale`; persists the choice via
  `shared_preferences` and mirrors it into `Intl.defaultLocale` so
  `Formatters` (money/date) follow suit. Switchable from **Settings →
  Appearance → Language**.

Screens read strings with `AppLocalizations.of(context).someKey`; call sites
never hardcode English copy.

## Roadmap seams

Left as clear extension points: Yandex Maps SDK (`features/map`), and
enforcing/refreshing auth tokens on protected routes (today's dev server
issues opaque tokens but doesn't check them — see
[`../server/README.md`](../server/README.md#phone-otp-auth-dev-mode)).
