# Multiplatform Dart Port — Slice Roadmap

**Status:** active program plan  
**Updated:** 2026-07-24  
**Integration base:** `feature/multiplatform-dart`  
**Worktree:** `F:\Destiny2BuildCreator-multiplatform-dart`  
**Pipeline per slice:** Spec Kit `specify → (clarify) → plan → tasks → implement → finish-spec` → **merge into `feature/multiplatform-dart` only** → update this table  

**Architecture freezes:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md)  
**Branch / worktree rules:** [multiplatform-dart-branching.md](./multiplatform-dart-branching.md)  
**Exploration source:** workflow `explore-flutter-port` + decisions Q1–Q4  

This is the **canonical list of Spec Kit slices** for the full port. Implement **in order** (do not skip phase gates). Each row is one feature branch / one `specs/NNN-short-name/` directory — sized so a single Spec Kit cycle is realistic (roughly days to ~1–2 weeks of focused work, not a whole phase).

---

## How to use this document

1. Pick the next row with status **`pending`** whose **Depends** are all **`done`**.
2. From the multiplatform worktree on `feature/multiplatform-dart`, run Spec Kit specify (or continue the assigned branch).
3. Short name in the table is the Spec Kit short-name; `NNN` is assigned by Spec Kit sequential numbering (044+). Update the **NNN** column when the branch exists.
4. After finish-spec onto `feature/multiplatform-dart`, set status to **`done`**, fill NNN, and note merge tip if useful.
5. If a slice is still too large at plan time, **split it here first** (insert rows, renumber order) before implementing — do not ship mega-slices.
6. Product domain rules (DBR/DAC/BR) still win for game behavior; this roadmap does not redefine them.

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

Order is strict. `NNN` starts at **044** (first branch already created as `044-dart-domain-foundation` — keep that short name for S01 or rename only if you reset the branch before specify).

| Order | Status | NNN | Short name | Phase | Depends | Goal (one line) | Exit criteria (must all pass) |
| ----- | ------ | --- | ---------- | ----- | ------- | --------------- | ----------------------------- |
| S01 | **active** | `044` | `dart-domain-foundation` | P0 | — | Melos (or equivalent) monorepo skeleton: package graph, CI-friendly `dart test` entry, no UI apps yet | Packages resolve; empty/smoke domain package; documented layout; no IO/UI deps allowed in domain pubspec |
| S02 | pending | | `dart-models` | P0 | S01 | Pure DTOs / freezed (or equivalent) models for pins, claims, kits, coverage results, failure codes | Models package has zero IO; maps core build/variant/set/synergy shapes used by evaluators |
| S03 | pending | | `dart-hard-constraints` | P0 | S02 | Port pure hard evaluators: exotic limits, mod energy, subclass kit, exotic ability match | Golden tests vs TS fixtures; hard-block codes stable; capacityResolved semantics documented |
| S04 | pending | | `dart-soft-coverage` | P0 | S02 | Port soft coverage + soft stat estimate inputs (no save path imports) | Soft results never imply hard block; tests forbid hard/soft confusion; DBR-GUID soft path parity |
| S05 | pending | | `dart-resolve-variant` | P0 | S02 | Port pure resolveVariant merge/conflict/completeness (claims only; no DB load) | Default vs non-default completeness rules tested; conflict detection parity |
| S06 | pending | | `dart-equip-ready` | P0 | S02,S05 | Port equipReady / wishlist vs owned-pin gates (pure) | Wishlist cannot be equip-ready; stale pin rules covered by tests |
| S07 | pending | | `dart-finish-gaps` | P0 | S05,S06 | Port finishGaps / next-slot pure helpers | Gap list stable for default vs non-default fixtures |
| S08 | pending | | `dart-optimizer-core` | P0 | S02 | Port enumerate/prune/score pure core + maxCombinations | Unit tests on small fixture boards; truncation flags; no Flutter isolate yet |
| S09 | pending | | `dart-static-sandbox-data` | P0 | S01 | Port static tables (stat benefits, synergy verbs, exotic ability requirements, etc.) | Constants package; update process documented for sandbox patches |
| S10 | pending | | `dart-dim-builders` | P0 | S06 | Pure DIM loadout JSON builders + equipReady gate call (no network) | jsonOnly payload matches TS golden for one fixture variant |
| S11 | pending | | `dart-domain-parity-gate` | P0 | S03–S10 | Aggregate parity suite + package dependency lint (domain has zero IO/UI) | Single command runs full pure suite; melos graph guard; **P0 phase gate** |
| S12 | pending | | `dart-storage-root` | P1 | S11 | StorageRoot abstraction + Windows path_provider layout (app support, not repo `.cache`) | Paths documented; unit tests with fake FS |
| S13 | pending | | `dart-drift-schema` | P1 | S12 | Drift schema mirroring core tables (users, builds, variants, sets, synergies, inventory) | Schema creates clean DB; PRAGMA/index notes for critical uniques |
| S14 | pending | | `dart-drift-migrations` | P1 | S13 | Migration strategy mirroring historical ensure* / column upgrades needed for import later | Empty→current migrate green; documented version table |
| S15 | pending | | `dart-repos-library` | P1 | S14 | Repositories: builds/sets/synergies/variants CRUD (no Bungie) | Round-trip fixtures; RESTRICT attach semantics on set delete |
| S16 | pending | | `dart-repos-inventory` | P1 | S14 | Inventory repository + full-replace transaction shape + sync metadata fields | Composite unique; batch insert in one transaction; busy lock hook |
| S17 | pending | | `dart-manifest-entities` | P1 | S12 | Entity store reader + extractor port for MVP stores (weapons, armor, subclass pieces, mods) | Offline read of fixture entity JSON; perk/item resolve used by hard constraints adapters |
| S18 | pending | | `dart-manifest-windows-refresh` | P1 | S17 | Windows-only full/partial manifest refresh pipeline (download→extract→store) | Settings-level API: status/isStale/refresh; rebuild off UI isolate |
| S19 | pending | | `flutter-windows-host-skeleton` | P1 | S12,S13 | Minimal Flutter Windows app: open DB, show Settings stub (manifest status only) | App launches; single DB connection; no OAuth yet |
| S20 | pending | | `flutter-catalog-offline` | P1 | S17,S19 | Catalog facets + browse offline from entity stores | Browse/filter without inventory; **P1 phase gate** |
| S21 | pending | | `dart-bungie-http` | P2 | S11 | Shared Bungie HTTP client (API key header, errors, rate-limit hooks) | Unit tests with mocked HTTP; no secrets in package |
| S22 | pending | | `dart-oauth-pkce` | P2 | S21 | Public+PKCE authorize/token/refresh pure + platform redirect URI config | No client_secret fields; state/CSRF; token model |
| S23 | pending | | `flutter-windows-oauth` | P2 | S22,S19 | Windows loopback/deep-link OAuth + secure storage | Sign-in/out E2E on Windows; tokens not in SQLite plaintext |
| S24 | pending | | `dart-bungie-profile-sync` | P2 | S21,S16 | Profile fetch + inventory sync algorithm into Drift | Full replace + sync_version; 60s freshness helper |
| S25 | pending | | `flutter-inventory-sync-ui` | P2 | S23,S24 | Settings inventory sync card + busy/error UX | User can sync; **P2 phase gate** (owned data local) |
| S26 | pending | | `flutter-catalog-owned` | P2 | S20,S25 | Catalog all-vs-owned + instance projections for pickers | Owned filter works after sync |
| S27 | pending | | `dart-app-use-cases-library` | P3 | S15,S11 | Application use cases: set/synergy CRUD + attach (in-process, no HTTP) | Use cases call repos + pure domain; tests with in-memory/Drift |
| S28 | pending | | `dart-app-use-cases-build` | P3 | S27,S03–S07 | Build/variant save pipeline order parity (hard gates + soft coverage query) | Illegal kits hard-block; soft misses do not block non-default |
| S29 | pending | | `flutter-design-tokens` | P3 | S19 | Shared design tokens + FlapBoard layout contracts (no full brand rewrite) | Documented tokens; Windows theme stub without Material-card default |
| S30 | pending | | `flutter-sets-library-ui` | P3 | S27,S29,S26 | Sets library + slot fill → catalog pick (Windows dual-pane) | Create/edit set; fill slot from catalog/owned |
| S31 | pending | | `flutter-synergy-library-ui` | P3 | S27,S29 | Synergy library CRUD + evidence links UI | Create synergy; designation immutable after create |
| S32 | pending | | `flutter-build-identity-ui` | P3 | S28,S29 | Build list + identity (class, synergy types, exotic/super pins) | Create build with synergy types |
| S33 | pending | | `flutter-variant-compose-ui` | P3 | S32,S30 | Variants, set attachments, slot pins (wishlist vs instance) | Attach set; pin slot; resolve conflicts surfaced |
| S34 | pending | | `flutter-soft-guidance-ui` | P3 | S33,S04 | Soft coverage chips + soft stat targets UI (display only) | Soft never auto-applies; **P3 phase gate** (compose without equip) |
| S35 | pending | | `dart-optimizer-isolate` | P4 | S08,S28 | Run enumerate in isolate; materialize Armor Set use case | UI thread safe; confirm-only apply path |
| S36 | pending | | `flutter-optimizer-ui` | P4 | S35,S30 | Finish/optimizer workspace on Windows | Suggest → user confirm; never silent apply |
| S37 | pending | | `dart-equip-orchestrator` | P4 | S06,S24 | planEquipSteps + execute + partial status (write client) | Best-effort partial; no full rollback; tests with mocked write API |
| S38 | pending | | `flutter-equip-ui` | P4 | S37,S33 | Character pick + equip CTA + step report | Equip-ready gate enforced; gaps confirm UX |
| S39 | pending | | `flutter-dim-export-ui` | P4 | S10,S38 | DIM jsonOnly / clipboard export | Blocked when not equip-ready |
| S40 | pending | | `flutter-mobile-shell-nav` | P4 | S34 | Android+iOS app shell: bottom nav, Focus Swap routes, shared use cases | Installable debug builds; Settings+Build list at minimum |
| S41 | pending | | `flutter-mobile-compose` | P4 | S40,S33–S34 | Reduced-density compose on phone (sheets, linear finish) | Create build → attach → soft guidance on device; **P4 phase gate** |
| S42 | pending | | `jaspr-app-skeleton` | P5 | S11,S13 | Jaspr app shell + routing + design tokens (CSS) | Hello Settings page; no Next dependency |
| S43 | pending | | `jaspr-opfs-sqlite` | P5 | S42,S14 | Drift WASM + OPFS + single-tab writer lock UX | Second tab read-only or blocked; documented limits |
| S44 | pending | | `jaspr-entity-bundles` | P5 | S17,S42 | Load prebuilt entity bundles (no full raw rebuild in browser) | Offline catalog facets on web |
| S45 | pending | | `jaspr-oauth-pkce` | P5 | S22,S42 | Browser Public+PKCE + token storage strategy | No confidential secret; sign-in works on HTTPS loopback/prod origin |
| S46 | pending | | `jaspr-compose-spine` | P5 | S43–S45,S27–S28 | Port compose spine UI to Jaspr (build/sets/synergy/catalog) | Intent→compose with hard/soft parity |
| S47 | pending | | `jaspr-equip-export` | P5 | S46,S37,S10 | Equip-ready + DIM json + optional equip on web | Same domain packages as Flutter |
| S48 | pending | | `legacy-db-import` | P5 | S14,S43 | Import tool/UX from Next `.cache/app.db` → platform StorageRoot | One documented migration path; dry-run + apply |
| S49 | pending | | `cutover-parity-checklist` | P5 | S47,S41,S38 | Written parity checklist vs PRODUCT production nav; Next retirement criteria | Checklist in repo; explicit go/no-go; **P5 / program gate** |

---

## Phase notes (why these splits)

### P0 — Pure domain

Split **by pure module**, not “port all of `src/lib`”. Hard constraints, soft coverage, resolve, equip-ready, optimizer, and DIM builders each get their own slice so parity failures stay localized. **S11** is the phase gate: do not start Drift until pure suite is trustworthy.

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
| **Next slice** | **S01** `044-dart-domain-foundation` (monorepo skeleton only — do not expand S01 into all of P0) |
| **Active branch** | `044-dart-domain-foundation` |
| **Active worktree** | `F:\Destiny2BuildCreator-multiplatform-dart` |
| **Blocked on** | — |

### S01 scope boundary (important)

The existing branch name says “domain-foundation” but **this roadmap defines S01 as monorepo skeleton only**.  
Spec Kit specify for `044` should **not** include porting all evaluators — those are S02–S11. If specify already drifted wide, narrow the spec to S01 exit criteria before plan/tasks.

---

## Update checklist (end of every finish-spec)

- [ ] Row status → `done`, NNN filled  
- [ ] **Current pointer** advanced to next pending row  
- [ ] Phase gate row marked done when that phase completes  
- [ ] Decisions doc still accurate (link only; don’t fork architecture here)  
- [ ] No product-branch merges  

---

## Related files

| File | Role |
| ---- | ---- |
| [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) | Locked architecture |
| [multiplatform-dart-branching.md](./multiplatform-dart-branching.md) | Git / worktree isolation |
| `specs/NNN-*/` | Per-slice Spec Kit artifacts |
| `.grok/workflows/explore-flutter-port.rhai` | Optional re-exploration only |
