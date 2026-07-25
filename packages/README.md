# Dart monorepo packages

**Workstream:** DART (multiplatform port)  
**Integration base:** `feature/multiplatform-dart`  
**Architecture:** [docs/multiplatform-dart-port-decisions.md](../docs/multiplatform-dart-port-decisions.md)

This directory holds **pure and host-shared Dart packages** for the multiplatform Destiny 2 Build Creator port. Host shells live under **`apps/`** (Flutter Windows/mobile + Jaspr web).

## Layout

```text
pubspec.yaml              # workspace root + Melos 7+ `melos:` scripts
melos.yaml                # pointer only (config lives in pubspec.yaml)
analysis_options.yaml     # shared analyzer defaults
apps/
  windows_host/           # Flutter Windows shell (DART-019…039) — destiny2_windows_host
    lib/
      main.dart           # BUNGIE_API_KEY / BUNGIE_CLIENT_ID / BUNGIE_REDIRECT_URI defines
      host_bootstrap.dart # StorageRoot + single AppDatabase + ManifestRefreshApi + OfflineCatalog + OAuth session
      auth/               # DART-023: TokenStore, loopback callback, WindowsOAuthSession
      catalog/            # Offline catalog browse (DART-020/026)
      sets/               # DART-030: Sets library dual-pane + catalog slot picker
      synergies/          # DART-031: Synergy library dual-pane + evidence links (designation immutable)
      settings/           # Manifest status + OAuth account card (sign-in/out)
      loadouts/           # DART-055: In-Game Loadouts (Bungie component 206)
      theme/              # DART-029: Flap theme stub
  mobile_host/            # Flutter Android+iOS shell (DART-040/041) — destiny2_mobile_host
    lib/
      main.dart           # optional BUNGIE_API_KEY; never CLIENT_SECRET
      host_bootstrap.dart # StorageRoot + single AppDatabase + ManifestRefreshApi
      app.dart            # bottom nav Builds|Settings + Focus Swap nested navigator
      builds/             # list + reduced-density compose sheets
      settings/           # path + manifest status
      theme/              # Matte Flap theme
  web_host/               # Jaspr web shell (DART-042) — destiny2_web_host (NOT root workspace member)
    lib/
      main.client.dart    # client SPA entry (jaspr mode: client)
      app.dart            # shell + jaspr_router (Settings primary + /loadouts DART-055)
      pages/              # Hello Settings stub
      loadouts/           # DART-055: In-Game Loadouts route page
      theme/              # CSS vars from destiny2_ui_tokens
    # Resolve with: cd apps/web_host && dart pub get  (Jaspr analyzer vs Flutter meta pin)

packages/
  README.md               # this file
  ui_tokens/              # pure Matte Flap tokens + FlapBoard contracts (DART-029)
  ui_flutter/             # Flutter-only ThemeExtension + board kit (Windows/mobile only)
  domain/                 # pure domain (models + evaluators)
    pubspec.yaml          # package name: destiny2_domain
    lib/
      destiny2_domain.dart
      src/
        smoke.dart
        models/           # DART-002 pure DTOs (+ DART-035 combination response types)
        evaluators/       # DART-003+ pure evaluators (+ DART-035 optimize pipeline)
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
  app/                    # In-process application use cases (DART-027/028/035+) — destiny2_app
    pubspec.yaml          # package name: destiny2_app
    lib/
      destiny2_app.dart
      src/
        set_use_cases.dart        # set/synergy library CRUD orchestration
        synergy_use_cases.dart
        attachment_use_cases.dart # prepareAttachments + replace-by-type
        build_use_cases.dart      # DART-028 build create/update + identity hard gates
        variant_use_cases.dart    # DART-028 variant save + validateVariantSave order
        coverage_use_cases.dart   # DART-028 soft coverage query (never blocks)
        hard_gates.dart           # identity + equipment hard gate orchestration
        hard_gate_ports.dart      # injectable manifest/sandbox ports
        optimizer_isolate.dart    # DART-035 Isolate.run optimize (UI-thread safe)
        optimizer_use_cases.dart  # DART-035 confirm-only materialize / apply-in-place
        mappers.dart              # db records → pure domain models
        errors.dart
    test/
  ui_tokens/              # Matte Flap Ledger tokens + FlapBoard layout contracts (DART-029)
    pubspec.yaml          # package name: destiny2_ui_tokens (SDK only)
    README.md             # documented tokens + anti-rules
    lib/
      destiny2_ui_tokens.dart
      src/
        colors.dart               # dark/light + element ARGB
        spacing.dart
        radii.dart                # square board (all 0)
        typography.dart           # family names + metrics
        flap_board_layout.dart    # rail 320, gap 0, column templates
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
| `packages/app` | `destiny2_app` | **In-process application use cases** (DART-027 library: set/synergy CRUD + attach; DART-028 build/variant save hard gates + soft coverage query; DART-035 optimizer isolate + confirm-only armor materialize/apply). Calls Drift repos + pure domain validators. No HTTP. Soft never auto-applies. | `destiny2_db`, `destiny2_domain`, `destiny2_sandbox_data`. **Not** pure. **No** CLIENT_SECRET. |
| `packages/ui_tokens` | `destiny2_ui_tokens` | **Matte Flap Ledger tokens + FlapBoard layout contracts** (DART-029). Colors/spacing/radii/typography metrics; rail 320 / gap 0 / column templates. Documented in package README. **No** Flutter/Jaspr widgets. | **SDK only**. Hosts map ARGB → Color/CSS. |
| `apps/windows_host` | `destiny2_windows_host` | **Flutter Windows host** (DART-019/020/023/025/026/029): open StorageRoot + single Drift DB; Catalog offline + owned; Settings OAuth + inventory sync; **flap theme stub** (`buildFlapTheme` — square elevation-0 cards, void canvas). Tokens not in SQLite. | Flutter, path_provider, sqlite3_flutter_libs, flutter_secure_storage, url_launcher; path deps on storage/db/manifest/bungie/ui_tokens. **No** CLIENT_SECRET. |
| `apps/mobile_host` | `destiny2_mobile_host` | **Flutter mobile host** (DART-040/041): bottom nav, Focus Swap, reduced-density compose. Soft never auto-applies. | Flutter; path deps on app/db/domain/manifest/storage/ui_tokens. **No** CLIENT_SECRET. |
| `apps/web_host` | `destiny2_web_host` | **Jaspr web host** (DART-042/043): client SPA shell + routing + design tokens CSS; Drift WASM/OPFS + **single-tab writer** lock (second tab blocked). **Not** a root pub workspace member (Jaspr builder/analyzer vs Flutter `meta` pin). | `jaspr`, `jaspr_router`, `drift`, `web`; path `destiny2_ui_tokens`, `destiny2_db`. **No** Next.js. **No** CLIENT_SECRET. Limits: `docs/multiplatform-dart-web-opfs-limits.md`. |

Flutter mobile compose is DART-041; Jaspr entity bundles/auth/compose are DART-044+.

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

## Design tokens + FlapBoard contracts (DART-029)

`destiny2_ui_tokens` is pure Matte Flap Ledger data for all shells (Flutter maps to `ThemeData`; Jaspr CSS later in DART-042):

```dart
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

final voidBg = FlapColorTokens.dark.background; // #050608
assert(kFlapLibraryRailWidth == 320);
assert(kFlapBoardRowGap == 0);
assert(kFlapRadius == 0);
final buildsCols = flapColumnTemplateById('builds');
```

- Documented tokens: package [README](./ui_tokens/README.md)
- Windows theme stub: `apps/windows_host/lib/theme/flap_theme.dart` → `buildFlapTheme()` (no Material elevated/rounded card default)
- **Not** a shared widget tree; no FlapRow widgets in this package

```powershell
dart test packages/ui_tokens
```

## Application use cases (DART-027)

`destiny2_app` is the shared **in-process** orchestration layer for Flutter/Jaspr hosts (no Next `/api` tree):

```dart
import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';

final detail = await createUserSet(
  db,
  userId,
  CreateSetCommand(name: 'Kinetic', type: SetType.weapon),
);

await prepareAttachments(db, userId, variantId, [
  SetAttachmentInput(setId: detail.set.id, mode: AttachmentMode.live),
]);
```

- Set/synergy CRUD with domain type validation + designation immutability
- Attach: fashion max-one, snapshot freeze from active items, replace-by-type
- Tests: `dart test packages/app` (in-memory Drift)

```powershell
dart test packages/app
```

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

// DART-050: production hosts MUST wire equipmentBucketLookup / builder so
// vault General + Postmaster weapon/armor are stored with equipment buckets.
// Empty lookup is test-only — transfer containers are dropped before Drift.
final result = await syncUserInventory(
  db: db,
  userId: userId,
  accessToken: accessToken,
  profileClient: profile,
  equipmentBucketLookupBuilder: (transferHashes) async {
    // Prefer DestinyInventoryItemDefinition raw table (Windows after DART-018).
    // Fallback: buildEquipmentBucketLookupFromSlots from OfflineCatalog slots.
    return buildEquipmentBucketLookup(rawItemDefs, transferHashes);
  },
  // DART-051: roll tags (optional maps/builders — golden parity when provided)
  perkNameMapBuilder: (plugHashes) async =>
      buildPerkNameMapFromItemDefs(rawItemDefs, plugHashes),
  weaponRollMetaLookupBuilder: (itemHashes) async =>
      buildWeaponRollMetaLookup(catalogWeaponSources, onlyHashes: itemHashes),
  // DART-052: socket plugs with columnKind/columnLabel (Next buildStoredSocketPlugs)
  weaponSocketContextBuilder: (itemHash, plugHashes) async =>
      buildWeaponSocketContextFromItemDefs(rawItemDefs, itemHash, plugHashes),
);

// diagnostics.resolution.resolvedFromTransfer > 0 when vault items resolved
final resolved = result.diagnostics.resolution?.resolvedFromTransfer ?? 0;

if (!isInventoryFresh(result.lastFullSyncAt)) {
  // or: await syncIfStale(..., equipmentBucketLookupBuilder: ...)
}
```

- Full-replace uses DART-016 exclusive busy lock; concurrent sync → `SyncInProgressError`
- Bumps `inventory_sync_meta.sync_version` / `last_full_sync_at` / `item_count`
- Fresh window: `kEquipSyncFreshMs` = **60_000** (DBR-EQP-007)
- **Vault/postmaster resolution (DART-050 / GAP-INV-01 / DART-056):** `buildEquipmentBucketLookup` + host wiring on every production path (Windows Settings `syncNow`, Windows/Jaspr equip `syncIfStale`, **Jaspr Settings Sync now**). Web uses catalog slot map (`buildEquipmentBucketLookupFromSlots`). Empty lookup is **not** production-OK.
- **Roll tags (DART-051 / GAP-INV-02):** `computeRollTags` (Next parity) tags Crafted / champion / MeleeBuildCandidate / OrbitBuild at normalize time. Pass `perkNameMap` (+ builder) and `weaponRollMetaLookup` (+ builder). Empty maps → Crafted-only when `isCrafted` (no invented tags). Windows hosts resolve plug names from raw `DestinyInventoryItemDefinition` and weapon meta from OfflineCatalog; web equip wires catalog frame meta (perk-name rules need raw or injected map — thinner until entity weapon-perks). Soft metadata only — **never** auto-applies.
- **Socket plugs (DART-052 / GAP-INV-03):** `classifyWeaponSocket` + `buildStoredSocketPlugs` (Next parity) persist weapon `socket_plugs` with `columnKind`/`columnLabel` when `weaponSocketContextBuilder` supplies plug categories + weapon perk socket indexes (`4241085061`). Without context, raw capture maps are stored (no kinds) — incomplete for perk grids. Windows wires raw DestinyInventoryItemDefinition; web MVP has no raw defs (PROC-06 residual until entity/raw channel). Soft metadata only — **never** auto-applies.
- **Owned catalog** still needs entity stores populated (`OwnedCatalogBridge` joins counts onto entity baseItems) — empty entity cache ≠ empty vault (**GAP-INV-06**). Settings/Catalog empty-cache UX is **DART-053**.
- Settings sync UI is **DART-025**; diagnostics retention + `formatSyncDiagnostics` surface is **DART-053** (`packages/bungie` exports the pure formatter)
- **In-game loadouts (DART-055 / GAP-NAV-01):** `parseCharacterLoadoutsResponse` + presentation tables + `getCharacterLoadoutsProfile` (`200,206`) in `destiny2_bungie`. Windows + Jaspr primary nav/route list Bungie character loadouts (not the local Drift `loadouts` snapshot table).

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
