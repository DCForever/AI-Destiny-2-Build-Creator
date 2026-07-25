# Multiplatform Dart Port — Slice Roadmap

**Status:** active program plan  
**Updated:** 2026-07-24 (DART-006 done)  
**Workstream ID:** **DART** (parallel to product Spec Kit `001`–`043+` on the Next.js line)  
**Integration base:** `feature/multiplatform-dart`  
**Worktree:** `F:\Destiny2BuildCreator-multiplatform-dart`  
**Pipeline per slice:** Spec Kit `specify → (clarify) → plan → tasks → implement → finish-spec` → **merge into `feature/multiplatform-dart` only** → update this table  

**Architecture freezes:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md)  
**Branch / worktree rules:** [multiplatform-dart-branching.md](./multiplatform-dart-branching.md)  
**Exploration source:** workflow `explore-flutter-port` + decisions Q1–Q4  

This is the **canonical list of Spec Kit slices** for the full port. Implement **in order** (do not skip phase gates). Each row is one feature branch / one `specs/dart-NNN-short-name/` directory — sized so a single Spec Kit cycle is realistic (roughly days to ~1–2 weeks of focused work, not a whole phase).

---

## Numbering (parallel workstream)

| Line | ID pattern | Examples | Spec dir / branch |
| ---- | ---------- | -------- | ----------------- |
| **Product (Next.js)** | Sequential Spec Kit `001`… | `043-default-variant-composer` | `specs/043-…` |
| **Multiplatform Dart (this doc)** | **`DART-NNN`** | **`DART-001`**, `DART-002`, … | `specs/dart-001-…` / branch `dart-001-…` |

- **Do not** continue product numbers (`044`, `045`, …) for this port.
- **Do not** reuse product feature numbers for Dart slices.
- Program IDs in this table are always **`DART-001` … `DART-049`** (zero-padded to three digits).
- Git branch and `specs/` folder use **lowercase** `dart-NNN-short-name` (filesystem-friendly); the table’s **ID** column is the canonical label (`DART-001`).
- When running Spec Kit on this line, **force** names so auto-numbering never steals product `044+`:

```powershell
$env:GIT_BRANCH_NAME = "dart-001-domain-foundation"
# Prefer explicit feature dir if supported:
# SPECIFY_FEATURE_DIRECTORY=specs/dart-001-domain-foundation
```

---

## How to use this document

1. Pick the next row with status **`pending`** whose **Depends** are all **`done`**.
2. From the multiplatform worktree on `feature/multiplatform-dart`, create/checkout `dart-NNN-short-name` and run Spec Kit specify.
3. After finish-spec onto `feature/multiplatform-dart`, set status to **`done`** and advance **Current pointer**.
4. If a slice is still too large at plan time, **split it here first** (insert `DART-NNNa` style only if needed, or renumber with a note) before implementing.
5. Product domain rules (DBR/DAC/BR) still win for game behavior; this roadmap does not redefine them.

### Status values

| Status | Meaning |
| ------ | ------- |
| `pending` | Not started |
| `active` | Spec Kit branch in progress |
| `blocked` | Waiting on decision, dependency, or external config |
| `done` | Merged to `feature/multiplatform-dart` |
| `deferred` | Explicitly postponed (note why) |

### Slice sizing rules

A slice is “small enough” when:

- One primary package area or one vertical thin slice (not “all of Phase 3”)
- Exit criteria fit on one screen and are testable
- Spec Kit `tasks.md` stays under ~25 tasks (soft limit; split if you blow past)
- No dual UI shell work in the same slice as pure domain ports
- Hard vs soft DBR parity is never “later” for the functions that slice owns

### Program non-goals (all phases)

Do **not** schedule slices for: `/debug/*` as primary nav, multi-pass LLM generator, full DIM parity / dim.gg day-one, Flutter Web, Node sidecar, Confidential secrets in clients, multi-worker Edge SQLite.

---

## Phase overview

| Phase | Theme | Gate (phase exit) |
| ----- | ----- | ----------------- |
| **P0** | Pure domain + monorepo skeleton | Domain packages green on golden tests; zero Flutter/Jaspr/IO deps in domain |
| **P1** | Data + manifest (Windows host groundwork) | Drift DB open on Windows path; entity stores; catalog facets offline |
| **P2** | Auth + inventory sync | Public+PKCE on Windows; inventory replace sync; no client secret in binary |
| **P3** | Compose spine on Flutter Windows | Create build → attach sets → hard save gates → soft coverage chips |
| **P4** | Optimizer, equip/DIM, mobile shells | Equip-ready + partial equip; optimizer confirm-only; Android/iOS reduced compose path |
| **P5** | Jaspr web + cutover | OPFS single-writer; prebuilt entities; compose→equip-ready path; Next retirement gates documented |

**Shell order (locked):** pure packages → **Flutter Windows** → Flutter mobile → **Jaspr web**.  
**I/O (locked):** pure Dart only — no Node sidecar.

---

## Master slice table

Order is strict. IDs start at **`DART-001`**.

| ID | Status | Short name | Branch / specs dir | Phase | Depends | Goal (one line) | Exit criteria (must all pass) |
| -- | ------ | ---------- | ------------------ | ----- | ------- | --------------- | ----------------------------- |
| **DART-001** | **done** | `domain-foundation` | `dart-001-domain-foundation` | P0 | — | Melos (or equivalent) monorepo skeleton: package graph, CI-friendly `dart test` entry, no UI apps yet | Packages resolve; empty/smoke domain package; documented layout; no IO/UI deps allowed in domain pubspec |
| **DART-002** | **done** | `models` | `dart-002-models` | P0 | DART-001 | Pure DTOs / freezed (or equivalent) models for pins, claims, kits, coverage results, failure codes | Models package has zero IO; maps core build/variant/set/synergy shapes used by evaluators |
| **DART-003** | **done** | `hard-constraints` | `dart-003-hard-constraints` | P0 | DART-002 | Port pure hard evaluators: exotic limits, mod energy, subclass kit, exotic ability match | Golden tests vs TS fixtures; hard-block codes stable; capacityResolved semantics documented |
| **DART-004** | **done** | `soft-coverage` | `dart-004-soft-coverage` | P0 | DART-002 | Port soft coverage + soft stat estimate inputs (no save path imports) | Soft results never imply hard block; tests forbid hard/soft confusion; DBR-GUID soft path parity |
| **DART-005** | **done** | `resolve-variant` | `dart-005-resolve-variant` | P0 | DART-002 | Port pure resolveVariant merge/conflict/completeness (claims only; no DB load) | Default vs non-default completeness rules tested; conflict detection parity |
| **DART-006** | **done** | `equip-ready` | `dart-006-equip-ready` | P0 | DART-002, DART-005 | Port equipReady / wishlist vs owned-pin gates (pure) | Wishlist cannot be equip-ready; stale pin rules covered by tests |
| **DART-007** | pending | `finish-gaps` | `dart-007-finish-gaps` | P0 | DART-005, DART-006 | Port finishGaps / next-slot pure helpers | Gap list stable for default vs non-default fixtures |
| **DART-008** | pending | `optimizer-core` | `dart-008-optimizer-core` | P0 | DART-002 | Port enumerate/prune/score pure core + maxCombinations | Unit tests on small fixture boards; truncation flags; no Flutter isolate yet |
| **DART-009** | pending | `static-sandbox-data` | `dart-009-static-sandbox-data` | P0 | DART-001 | Port static tables (stat benefits, synergy verbs, exotic ability requirements, etc.) | Constants package; update process documented for sandbox patches |
| **DART-010** | pending | `dim-builders` | `dart-010-dim-builders` | P0 | DART-006 | Pure DIM loadout JSON builders + equipReady gate call (no network) | jsonOnly payload matches TS golden for one fixture variant |
| **DART-011** | pending | `domain-parity-gate` | `dart-011-domain-parity-gate` | P0 | DART-003–010 | Aggregate parity suite + package dependency lint (domain has zero IO/UI) | Single command runs full pure suite; melos graph guard; **P0 phase gate** |
| **DART-012** | pending | `storage-root` | `dart-012-storage-root` | P1 | DART-011 | StorageRoot abstraction + Windows path_provider layout (app support, not repo `.cache`) | Paths documented; unit tests with fake FS |
| **DART-013** | pending | `drift-schema` | `dart-013-drift-schema` | P1 | DART-012 | Drift schema mirroring core tables (users, builds, variants, sets, synergies, inventory) | Schema creates clean DB; PRAGMA/index notes for critical uniques |
| **DART-014** | pending | `drift-migrations` | `dart-014-drift-migrations` | P1 | DART-013 | Migration strategy mirroring historical ensure* / column upgrades needed for import later | Empty→current migrate green; documented version table |
| **DART-015** | pending | `repos-library` | `dart-015-repos-library` | P1 | DART-014 | Repositories: builds/sets/synergies/variants CRUD (no Bungie) | Round-trip fixtures; RESTRICT attach semantics on set delete |
| **DART-016** | pending | `repos-inventory` | `dart-016-repos-inventory` | P1 | DART-014 | Inventory repository + full-replace transaction shape + sync metadata fields | Composite unique; batch insert in one transaction; busy lock hook |
| **DART-017** | pending | `manifest-entities` | `dart-017-manifest-entities` | P1 | DART-012 | Entity store reader + extractor port for MVP stores (weapons, armor, subclass pieces, mods) | Offline read of fixture entity JSON; perk/item resolve used by hard constraints adapters |
| **DART-018** | pending | `manifest-windows-refresh` | `dart-018-manifest-windows-refresh` | P1 | DART-017 | Windows-only full/partial manifest refresh pipeline (download→extract→store) | Settings-level API: status/isStale/refresh; rebuild off UI isolate |
| **DART-019** | pending | `flutter-windows-host-skeleton` | `dart-019-flutter-windows-host-skeleton` | P1 | DART-012, DART-013 | Minimal Flutter Windows app: open DB, show Settings stub (manifest status only) | App launches; single DB connection; no OAuth yet |
| **DART-020** | pending | `flutter-catalog-offline` | `dart-020-flutter-catalog-offline` | P1 | DART-017, DART-019 | Catalog facets + browse offline from entity stores | Browse/filter without inventory; **P1 phase gate** |
| **DART-021** | pending | `bungie-http` | `dart-021-bungie-http` | P2 | DART-011 | Shared Bungie HTTP client (API key header, errors, rate-limit hooks) | Unit tests with mocked HTTP; no secrets in package |
| **DART-022** | pending | `oauth-pkce` | `dart-022-oauth-pkce` | P2 | DART-021 | Public+PKCE authorize/token/refresh pure + platform redirect URI config | No client_secret fields; state/CSRF; token model |
| **DART-023** | pending | `flutter-windows-oauth` | `dart-023-flutter-windows-oauth` | P2 | DART-022, DART-019 | Windows loopback/deep-link OAuth + secure storage | Sign-in/out E2E on Windows; tokens not in SQLite plaintext |
| **DART-024** | pending | `bungie-profile-sync` | `dart-024-bungie-profile-sync` | P2 | DART-021, DART-016 | Profile fetch + inventory sync algorithm into Drift | Full replace + sync_version; 60s freshness helper |
| **DART-025** | pending | `flutter-inventory-sync-ui` | `dart-025-flutter-inventory-sync-ui` | P2 | DART-023, DART-024 | Settings inventory sync card + busy/error UX | User can sync; **P2 phase gate** (owned data local) |
| **DART-026** | pending | `flutter-catalog-owned` | `dart-026-flutter-catalog-owned` | P2 | DART-020, DART-025 | Catalog all-vs-owned + instance projections for pickers | Owned filter works after sync |
| **DART-027** | pending | `app-use-cases-library` | `dart-027-app-use-cases-library` | P3 | DART-015, DART-011 | Application use cases: set/synergy CRUD + attach (in-process, no HTTP) | Use cases call repos + pure domain; tests with in-memory/Drift |
| **DART-028** | pending | `app-use-cases-build` | `dart-028-app-use-cases-build` | P3 | DART-027, DART-003–007 | Build/variant save pipeline order parity (hard gates + soft coverage query) | Illegal kits hard-block; soft misses do not block non-default |
| **DART-029** | pending | `flutter-design-tokens` | `dart-029-flutter-design-tokens` | P3 | DART-019 | Shared design tokens + FlapBoard layout contracts (no full brand rewrite) | Documented tokens; Windows theme stub without Material-card default |
| **DART-030** | pending | `flutter-sets-library-ui` | `dart-030-flutter-sets-library-ui` | P3 | DART-027, DART-029, DART-026 | Sets library + slot fill → catalog pick (Windows dual-pane) | Create/edit set; fill slot from catalog/owned |
| **DART-031** | pending | `flutter-synergy-library-ui` | `dart-031-flutter-synergy-library-ui` | P3 | DART-027, DART-029 | Synergy library CRUD + evidence links UI | Create synergy; designation immutable after create |
| **DART-032** | pending | `flutter-build-identity-ui` | `dart-032-flutter-build-identity-ui` | P3 | DART-028, DART-029 | Build list + identity (class, synergy types, exotic/super pins) | Create build with synergy types |
| **DART-033** | pending | `flutter-variant-compose-ui` | `dart-033-flutter-variant-compose-ui` | P3 | DART-032, DART-030 | Variants, set attachments, slot pins (wishlist vs instance) | Attach set; pin slot; resolve conflicts surfaced |
| **DART-034** | pending | `flutter-soft-guidance-ui` | `dart-034-flutter-soft-guidance-ui` | P3 | DART-033, DART-004 | Soft coverage chips + soft stat targets UI (display only) | Soft never auto-applies; **P3 phase gate** (compose without equip) |
| **DART-035** | pending | `optimizer-isolate` | `dart-035-optimizer-isolate` | P4 | DART-008, DART-028 | Run enumerate in isolate; materialize Armor Set use case | UI thread safe; confirm-only apply path |
| **DART-036** | pending | `flutter-optimizer-ui` | `dart-036-flutter-optimizer-ui` | P4 | DART-035, DART-030 | Finish/optimizer workspace on Windows | Suggest → user confirm; never silent apply |
| **DART-037** | pending | `equip-orchestrator` | `dart-037-equip-orchestrator` | P4 | DART-006, DART-024 | planEquipSteps + execute + partial status (write client) | Best-effort partial; no full rollback; tests with mocked write API |
| **DART-038** | pending | `flutter-equip-ui` | `dart-038-flutter-equip-ui` | P4 | DART-037, DART-033 | Character pick + equip CTA + step report | Equip-ready gate enforced; gaps confirm UX |
| **DART-039** | pending | `flutter-dim-export-ui` | `dart-039-flutter-dim-export-ui` | P4 | DART-010, DART-038 | DIM jsonOnly / clipboard export | Blocked when not equip-ready |
| **DART-040** | pending | `flutter-mobile-shell-nav` | `dart-040-flutter-mobile-shell-nav` | P4 | DART-034 | Android+iOS app shell: bottom nav, Focus Swap routes, shared use cases | Installable debug builds; Settings+Build list at minimum |
| **DART-041** | pending | `flutter-mobile-compose` | `dart-041-flutter-mobile-compose` | P4 | DART-040, DART-033–034 | Reduced-density compose on phone (sheets, linear finish) | Create build → attach → soft guidance on device; **P4 phase gate** |
| **DART-042** | pending | `jaspr-app-skeleton` | `dart-042-jaspr-app-skeleton` | P5 | DART-011, DART-013 | Jaspr app shell + routing + design tokens (CSS) | Hello Settings page; no Next dependency |
| **DART-043** | pending | `jaspr-opfs-sqlite` | `dart-043-jaspr-opfs-sqlite` | P5 | DART-042, DART-014 | Drift WASM + OPFS + single-tab writer lock UX | Second tab read-only or blocked; documented limits |
| **DART-044** | pending | `jaspr-entity-bundles` | `dart-044-jaspr-entity-bundles` | P5 | DART-017, DART-042 | Load prebuilt entity bundles (no full raw rebuild in browser) | Offline catalog facets on web |
| **DART-045** | pending | `jaspr-oauth-pkce` | `dart-045-jaspr-oauth-pkce` | P5 | DART-022, DART-042 | Browser Public+PKCE + token storage strategy | No confidential secret; sign-in works on HTTPS loopback/prod origin |
| **DART-046** | pending | `jaspr-compose-spine` | `dart-046-jaspr-compose-spine` | P5 | DART-043–045, DART-027–028 | Port compose spine UI to Jaspr (build/sets/synergy/catalog) | Intent→compose with hard/soft parity |
| **DART-047** | pending | `jaspr-equip-export` | `dart-047-jaspr-equip-export` | P5 | DART-046, DART-037, DART-010 | Equip-ready + DIM json + optional equip on web | Same domain packages as Flutter |
| **DART-048** | pending | `legacy-db-import` | `dart-048-legacy-db-import` | P5 | DART-014, DART-043 | Import tool/UX from Next `.cache/app.db` → platform StorageRoot | One documented migration path; dry-run + apply |
| **DART-049** | pending | `cutover-parity-checklist` | `dart-049-cutover-parity-checklist` | P5 | DART-047, DART-041, DART-038 | Written parity checklist vs PRODUCT production nav; Next retirement criteria | Checklist in repo; explicit go/no-go; **P5 / program gate** |

---

## Phase notes (why these splits)

### P0 — Pure domain

Split **by pure module**, not “port all of `src/lib`”. Hard constraints, soft coverage, resolve, equip-ready, optimizer, and DIM builders each get their own slice so parity failures stay localized. **DART-011** is the phase gate: do not start Drift until pure suite is trustworthy.

### P1 — Data + manifest

Schema, migrations, library repos, inventory repos, and manifest are separate so a migration bug does not block entity-store work. Flutter Windows skeleton is intentionally thin (open DB + Settings) before catalog.

### P2 — Auth + sync

HTTP client → PKCE core → Windows OAuth UI → sync algorithm → Settings UI. Catalog owned mode is its own slice so sync can ship without picker polish.

### P3 — Compose on Windows

Use cases before UI. Sets / Synergy / Build identity / variants / soft guidance are separate UI slices sharing the same tokens package.

### P4 — Equip + mobile

Optimizer and equip are domain+UI pairs. Mobile is **nav shell first**, then compose density — not a third full desktop port in one slice.

### P5 — Jaspr

Skeleton → OPFS writer policy → bundles → auth → compose → equip → import → cutover. Matches locked decisions (OPFS 1a, Public+PKCE, no sidecar).

---

## Deferred / out of roadmap (explicit)

| Item | Why deferred |
| ---- | ------------ |
| `/debug/*` operator tools | Non-goal for early port |
| LLM propose-for-confirm | P2 product capability; after compose→equip |
| dim.gg share | After jsonOnly; needs API key + CORS story |
| Artifact apply completeness | Unfinished in TS writeClient; follow-on |
| Shareable public build links | PRODUCT open decision |
| Flutter Web | Prefer Jaspr |
| Multi-app Bungie split (prod) | Hybrid: start one Public app; split when needed |

---

## Current pointer

| Field | Value |
| ----- | ----- |
| **Next / active slice** | **DART-007** `finish-gaps` (pure finishGaps / next-slot helpers — depends on DART-005, DART-006 done) |
| **Active branch** | (create) `dart-007-finish-gaps` from `feature/multiplatform-dart` |
| **Specs dir** | `specs/dart-007-finish-gaps/` (created at specify) |
| **Active worktree** | `F:\Destiny2BuildCreator-multiplatform-dart` |
| **Blocked on** | — |

### DART-006 note (completed)

Merged pure `computeEquipReady` / wishlist vs owned-pin / stale pin gates into `packages/domain` with golden tests vs TS `equipReady.test.ts` (plus hash_mismatch). Wishlist never equip-ready; post-sync stale covered.

### DART-005 note (completed)

Pure resolveVariant claims merge/conflict/completeness in `packages/domain` (`resolve_variant.dart`). Golden tests cover SLOT_CONFLICT, pair armor, default full combat vs non-default partial (DBR-CMPL-001/002). No DB load.

### DART-004 note (completed)

Soft coverage + soft-stat estimate/targets/nudges pure port in `packages/domain` (`evaluateCoverage`, `estimateLoadoutStats`, `softStatWarnings`, `normalizeSoftStatTargets`, `suggestStatNudges`). Golden + hard/soft separation tests green. Soft results are `CoverageResult` only — never hard blocks. Merged to `feature/multiplatform-dart`.

### DART-003 note (completed)

Pure hard evaluators live in `packages/domain/lib/src/evaluators/destiny_build_constraints.dart` with golden tests in `hard_constraints_test.dart`. `capacityResolved` semantics documented in slice research/quickstart.

---

## Update checklist (end of every finish-spec)

- [ ] Row status → `done`  
- [ ] **Current pointer** advanced to next pending `DART-NNN`  
- [ ] Phase gate row marked done when that phase completes  
- [ ] Decisions doc still accurate (link only; don’t fork architecture here)  
- [ ] No product-branch merges; no product `0NN` IDs used for this line  

---

## Related files

| File | Role |
| ---- | ---- |
| [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) | Locked architecture |
| [multiplatform-dart-branching.md](./multiplatform-dart-branching.md) | Git / worktree isolation |
| `specs/dart-NNN-*/` | Per-slice Spec Kit artifacts (DART workstream only) |
| `.grok/workflows/explore-flutter-port.rhai` | Optional re-exploration only |
| `.grok/workflows/dart-speckit-loop.rhai` | Auto Spec Kit advance for DART-001… |
| [multiplatform-dart-speckit-loop.md](./multiplatform-dart-speckit-loop.md) | Operator notes for the auto-loop |
