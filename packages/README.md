# Dart monorepo packages

**Workstream:** DART (multiplatform port)  
**Integration base:** `feature/multiplatform-dart`  
**Architecture:** [docs/multiplatform-dart-port-decisions.md](../docs/multiplatform-dart-port-decisions.md)

This directory holds **pure and host-shared Dart packages** for the multiplatform Destiny 2 Build Creator port. Flutter Windows host shell lives under **`apps/windows_host`** (DART-019).

## Layout

```text
pubspec.yaml              # workspace root + Melos 7+ `melos:` scripts
melos.yaml                # pointer only (config lives in pubspec.yaml)
analysis_options.yaml     # shared analyzer defaults
apps/
  windows_host/           # Flutter Windows shell (DART-019/020/023) — destiny2_windows_host
    lib/
      main.dart           # BUNGIE_API_KEY / BUNGIE_CLIENT_ID / BUNGIE_REDIRECT_URI defines
      host_bootstrap.dart # StorageRoot + single AppDatabase + ManifestRefreshApi + OfflineCatalog + OAuth session
      auth/               # DART-023: TokenStore, loopback callback, WindowsOAuthSession
      catalog/            # Offline catalog browse (DART-020)
      settings/           # Manifest status + OAuth account card (sign-in/out)

packages/
  README.md               # this file
  domain/                 # pure domain (models + evaluators)
    pubspec.yaml          # package name: destiny2_domain
    lib/
      destiny2_domain.dart
      src/
        smoke.dart
        models/           # DART-002 pure DTOs
        evaluators/       # DART-003+ pure evaluators
    test/
  sandbox_data/           # pure static sandbox tables (DART-009)
    pubspec.yaml          # package name: destiny2_sandbox_data
    lib/
      destiny2_sandbox_data.dart
      src/                # stat benefits, verbs, champions, …
    test/
  storage/                # StorageRoot paths (DART-012) — not pure
    pubspec.yaml          # package name: destiny2_storage
    lib/
      destiny2_storage.dart
      src/
        storage_root.dart
        version_dir.dart
    test/
  db/                     # Drift schema + library/inventory repos (DART-013–016) — not pure
    pubspec.yaml          # package name: destiny2_db
    lib/
      destiny2_db.dart
      src/
        tables.dart
        app_database.dart
        schema_notes.dart
        repos/            # DART-015 library CRUD; DART-016 inventory
    test/
  manifest/               # Entity stores + MVP extractors + Windows refresh + offline catalog (DART-017–020)
    pubspec.yaml          # package name: destiny2_manifest
    lib/
      destiny2_manifest.dart
      src/
        entity_cache.dart
        catalog/          # DART-020 facets + OfflineCatalog (no inventory)
        manifest_service.dart   # BungieManifestService download/status
        manifest_refresh.dart   # WindowsManifestRefresh status/isStale/refresh
        isolate_rebuild.dart    # rebuild off UI isolate
        extractors/       # weapons, exotic-armor, aspects, fragments, abilities, mods
        adapters/         # hard constraints adapters
        item_resolver.dart
        perk_validator.dart
    test/
  bungie/                 # Shared Bungie Platform HTTP + Public+PKCE OAuth + profile sync (DART-021/022/024)
    pubspec.yaml          # package name: destiny2_bungie
    lib/
      destiny2_bungie.dart
      src/
        bungie_http_client.dart   # getJson/postJson + X-API-Key
        bungie_envelope.dart      # ErrorCode unwrap
        bungie_errors.dart        # typed exceptions
        rate_limit.dart           # RateLimitSignal + hooks
        http_transport.dart       # injectable transport + default HttpClient
        oauth/                    # DART-022 Public+PKCE (no client_secret)
          bungie_oauth_client.dart
          bungie_tokens.dart
          pkce.dart
          oauth_state.dart
          redirect_uri_config.dart
        profile/                  # DART-024 memberships + GetProfile inventory parse
        sync/                     # DART-024 full-replace into Drift + 60s freshness
    test/
```

| Package path | Pub name | Role | Allowed deps |
| ------------ | -------- | ---- | ------------ |
| `packages/domain` | `destiny2_domain` | Pure domain library (models DART-002; evaluators DART-003+) | **SDK only** at runtime; `test` / pure lints as dev_dependencies. **No** Flutter, Jaspr, Drift, http, path_provider, or other IO/UI packages. |
| `packages/sandbox_data` | `destiny2_sandbox_data` | Pure static sandbox constants (stat benefits, synergy verbs, exotic ability requirements, archetypes, champion counters, vocabularies) | **SDK only** at runtime. Soft display tables only — never auto-apply / hard-block. |
| `packages/storage` | `destiny2_storage` | **StorageRoot** app-support path layout (DART-012). Not pure — may use `dart:io` for `ensureLayout`. | `path` (+ SDK). Hosts inject path_provider application-support path; package does **not** depend on Flutter/path_provider. **Not** in P0 pure graph guard list. |
| `packages/db` | `destiny2_db` | Drift SQLite **schema + migrations + library/inventory repos** (users, inventory, sets, synergies, builds/variants, attachments). schemaVersion 1 create-all (DART-013); ensure* upgrades on open (DART-014); builds/sets/synergies/variants CRUD (DART-015); inventory full-replace + sync meta + busy lock (DART-016). | `drift`, `sqlite3`, `path`. **Not** pure. |
| `packages/manifest` | `destiny2_manifest` | **Entity store reader + MVP extractors** (DART-017) + **Windows manifest refresh** (DART-018) + **offline catalog facets/browse** (`filterCatalogClient`, `OfflineCatalog`) (DART-020). Offline JSON under StorageRoot; no inventory. | `destiny2_storage`, `destiny2_domain`, `path`. **Not** pure (`dart:io`, `dart:isolate`). Public API key host-injected only; no CLIENT_SECRET. |
| `packages/bungie` | `destiny2_bungie` | **Shared Bungie Platform HTTP** (DART-021) + **Public+PKCE OAuth** (DART-022) + **profile inventory sync** (DART-024): `X-API-Key`, optional Bearer, envelope unwrap, rate-limit hooks; authorize/token/refresh with S256 PKCE; `HttpBungieProfileClient` + `syncUserInventory` full-replace into Drift + `isInventoryFresh` / `syncIfStale` (60s). | `crypto`, `destiny2_db` + SDK (`dart:io` default transport). **Not** pure. Host-injected public API key + public client id; **no** CLIENT_SECRET / `client_secret` fields. |
| `apps/windows_host` | `destiny2_windows_host` | **Flutter Windows host** (DART-019/020/023): open StorageRoot + single Drift DB; Catalog offline browse; Settings manifest + **Public+PKCE OAuth** (loopback `127.0.0.1`, `flutter_secure_storage` tokens — not SQLite). | Flutter, path_provider, sqlite3_flutter_libs, flutter_secure_storage, url_launcher; path deps on storage/db/manifest/bungie. **No** CLIENT_SECRET. |

Mobile Flutter / Jaspr web shells land under `apps/` in later slices (DART-040+, DART-042+).

## StorageRoot (DART-012)

Canonical multiplatform on-disk layout. **Windows Flutter hosts** resolve the base with path_provider, then build `StorageRoot`:

```dart
// Host (Flutter Windows) — path_provider not imported by destiny2_storage
final support = await getApplicationSupportDirectory();
final root = StorageRoot.windowsAppSupport(support.path);
await root.ensureLayout();
// root.appDbPath → <app support>/app.db
```

**Do not** use process CWD or repo `.cache` (Next.js legacy: `src/lib/manifest/cachePaths.ts`).

| Relative path | Purpose |
| ------------- | ------- |
| `app.db` | Primary SQLite (Drift opens later) |
| `current-version.json` | Active manifest version pointer |
| `manifest/<versionDir>/<table>.json` | Raw Bungie tables |
| `entities/<versionDir>/<store>.json` | Derived entity stores |
| `entities/<versionDir>/meta.json` | Entity cache meta |
| `entities/<versionDir>/perk-weapon-index.json` | Perk–weapon index |
| `users/<membershipId>/preferences.json` | Per-user preferences |

`versionDir` = `versionToDirName` (unsafe chars → `_`). Unit tests inject a fake base path (no real AppData required).

## Bungie HTTP (DART-021)

`destiny2_bungie` is the shared Platform client for P2+ (OAuth, profile sync, equip):

```dart
import 'package:destiny2_bungie/destiny2_bungie.dart';

final client = BungieHttpClient(
  apiKey: hostPublicApiKey,
  onRateLimit: (signal) { /* orchestrator may delay or surface WAIT */ },
);

final response = await client.getJson(
  '/User/GetMembershipsForCurrentUser/',
  accessToken: token,
);
```

- Always sends `X-API-Key`; optional `Authorization: Bearer …`
- Unwraps envelope when `ErrorCode == 1`; throws typed `BungieHttpException` / `BungiePlatformException` / `BungieParseException`
- Rate-limit hooks on HTTP 429, `ThrottleSeconds > 0`, and throttle platform codes
- Injectable `BungieHttpTransport` for unit tests (no live network)
- **No** `CLIENT_SECRET`, session secrets, or hard-coded production keys

```powershell
dart test packages/bungie
```

## Profile + inventory sync (DART-024)

```dart
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';

final profile = HttpBungieProfileClient(http: BungieHttpClient(apiKey: publicApiKey));

final result = await syncUserInventory(
  db: db,
  userId: userId,
  accessToken: accessToken,
  profileClient: profile,
  // optional: equipmentBucketLookup: { itemHash: equipmentBucketHash },
);

if (!isInventoryFresh(result.lastFullSyncAt)) {
  // or: await syncIfStale(...)
}
```

- Full-replace uses DART-016 exclusive busy lock; concurrent sync → `SyncInProgressError`
- Bumps `inventory_sync_meta.sync_version` / `last_full_sync_at` / `item_count`
- Fresh window: `kEquipSyncFreshMs` = **60_000** (DBR-EQP-007)
- Settings sync UI is **DART-025** (not this package)

```powershell
dart test packages/bungie
```

## Manifest entities (DART-017)

`destiny2_manifest` reads/writes **MVP entity stores** under `StorageRoot` (`entities/<versionDir>/`):

- Stores: `weapons`, `exotic-armor`, `aspects`, `fragments`, `abilities`, `mods`
- Offline fixture read + rebuild from raw table maps (no Bungie download — DART-018)
- Item resolve (exact name + hash) and perk validator (weapon perk columns, fragment capacity)
- Hard-constraint adapters: `evaluateSubclassKitFromEntityCache`, `evaluateModEnergyFromEntityCache` → pure `destiny2_domain` evaluators

```powershell
dart test packages/manifest
```

## Drift schema + migrations (DART-013 / DART-014)

`destiny2_db` mirrors product `src/lib/db` core tables. Open helpers:

```dart
import 'package:destiny2_db/destiny2_db.dart';

final mem = AppDatabase.memory();
final file = AppDatabase.file(root.appDbPath); // StorageRoot from destiny2_storage
// beforeOpen: foreign_keys ON + applyEnsureUpgrades (product ensure* parity)
```

- **PRAGMA**: `foreign_keys = ON` on open
- **schemaVersion**: **1** = current create-all; see `migration_version_table.dart` + `specs/dart-014-drift-migrations/data-model.md`
- **Ensure upgrades**: idempotent ADD COLUMN / table create / builds rebuild mirroring `src/lib/db/client.ts` (import prep for DART-048)
- **Critical uniques**: `users.bungie_membership_id`; `inventory_items(user_id, instance_id)`; `sets(user_id, type, name)`; tag/synergy-type pairs — see `schema_notes.dart` and `specs/dart-013-drift-schema/data-model.md`
- **RESTRICT**: cannot delete a set while `variant_set_attachments` reference it
- Tests: `dart test packages/db`

## Sandbox constants (DART-009)

`destiny2_sandbox_data` mirrors product `src/data/**` curated tables. After Destiny sandbox patches, follow [docs/sandbox-data-update-process.md](../docs/sandbox-data-update-process.md).

## Domain models (DART-002)

`destiny2_domain` exports pure immutable DTOs used by evaluators:

- Claims / resolved equipment / pins / equip-ready **shapes**
- Kits (subclass, ability, exotic composition, mod energy pieces)
- Hard/soft constraint envelopes + failure code constants
- Soft coverage result tree + soft stat shapes
- Core build / variant / set / synergy library shapes

## Hard evaluators (DART-003)

Pure functions in `src/evaluators/destiny_build_constraints.dart`:

- `evaluateExoticLimits`, `evaluateModEnergy`, `evaluateSubclassKit`
- `evaluateExoticAbilityMatch`, `evaluateSynergyRequirement`, `mergeConstraintEvaluations`
- Golden tests: `test/hard_constraints_test.dart` (parity with TS vitest)

## DIM builders (DART-010)

Pure variant → DIM Sync loadout document builders (no network):

- Models: `src/models/dim_loadout.dart` (`DimLoadout*`, class/stat hash constants)
- Builders: `src/evaluators/dim_builders.dart` — `buildVariantDimLoadout`, `buildJsonOnlyDimExport` (equipReady gate)
- Golden tests: `test/dim_builders_test.dart` (jsonOnly fixture parity with TS)

## Domain purity rule (hard)

`destiny2_domain` must remain free of I/O and UI frameworks so golden tests and hard/soft evaluators stay portable across Windows, mobile, and Jaspr.

Forbidden in `packages/domain/pubspec.yaml` **dependencies** (runtime):

- `flutter` / Flutter plugins
- Jaspr packages
- Drift / sqflite / sqlite3 (except pure in-memory fakes if ever justified later — prefer none)
- `http`, `dio`, and network clients
- `path_provider` and filesystem path packages used for app storage
- Any package that pulls a Flutter or browser DOM SDK transitively for product logic

Graph guard automation is enforced by **DART-011** (`dart run tool/pure_package_graph_guard.dart` / P0 gate). Review pubspecs in code review as a second line of defense.

## P0 phase gate (DART-011)

Before starting P1 (Drift / StorageRoot), the pure suite must be green and pure packages must stay free of IO/UI runtime deps:

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
dart run tool/p0_parity_gate.dart
```

Equivalents:

| Command | What it does |
| ------- | ------------ |
| `dart run tool/p0_parity_gate.dart` | **Gate**: graph guard + full pure suite |
| `dart run tool/pure_package_graph_guard.dart` | Dependency lint only |
| `dart run tool/run_all_pure_tests.dart` | All pure package tests only |
| `dart run melos run p0-gate` | Same gate via Melos (no global Melos required) |
| `dart run melos run test` | Full pure suite only |
| `dart run melos run graph-guard` | Graph guard only |
| `dart test tool/test` | Graph guard unit tests |

Pure packages guarded today: `packages/domain`, `packages/sandbox_data`.

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
# Optional Melos on PATH (after: dart pub global activate melos)
# Prefer: dart run melos …
```

## CI-friendly test entry

```powershell
# Preferred — full pure suite (non-interactive)
dart run tool/run_all_pure_tests.dart
# or
dart run melos run test

# Single package
dart test packages/domain
dart test packages/sandbox_data
```

## Coexistence with Next.js

The repository still contains the production Next.js app under `src/` / `package.json`. Dart workspace files at the repo root are additive and must not be required for Node product builds. Ignore Dart tool artifacts via root `.gitignore`.
