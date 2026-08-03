# Multiplatform Dart Port — Slice Roadmap

**Status:** active program plan  
**Updated:** 2026-08-03 (dart-070-set-occupancy closed — package min floors + attach gates; DART-001–068 + dart-070; cutover GO unchanged)  
**Workstream ID:** **DART** (parallel to product Spec Kit `001`–`043+` on the Next.js line)  
**Integration base:** `feature/multiplatform-dart`  
**Worktree:** `F:\Destiny2BuildCreator-multiplatform-dart`  
**Pipeline per slice:** Spec Kit `specify → (clarify) → plan → tasks → implement → finish-spec` → **merge into `feature/multiplatform-dart` only** → update this table  

**Architecture freezes:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md)  
**Branch / worktree rules:** [multiplatform-dart-branching.md](./multiplatform-dart-branching.md)  
**Feature gaps (canonical):** [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md) — every open P0–P1 gap maps to a DART-NNN below  
**UI fidelity (post-cutover):** [multiplatform-dart-ui-fidelity.md](./multiplatform-dart-ui-fidelity.md) — GAP-UI-* → DART-062–068; **does not re-open cutover**  
**Exploration / gaps workflows:** `explore-flutter-port`, **`dart-gaps-analysis`**  

This is the **canonical list of Spec Kit slices** for the full port. Implement **in order** (do not skip phase gates). Each row is one feature branch / one `specs/dart-NNN-short-name/` directory — sized so a single Spec Kit cycle is realistic (roughly days to ~1–2 weeks of focused work, not a whole phase).

---

## Numbering (parallel workstream)

| Line | ID pattern | Examples | Spec dir / branch |
| ---- | ---------- | -------- | ----------------- |
| **Product (Next.js)** | Sequential Spec Kit `001`… | `043-default-variant-composer` | `specs/043-…` |
| **Multiplatform Dart (this doc)** | **`DART-NNN`** | **`DART-001`**, `DART-002`, … | `specs/dart-001-…` / branch `dart-001-…` |

- **Do not** continue product numbers (`044`, `045`, …) for this port.
- **Do not** reuse product feature numbers for Dart slices.
- Program IDs in this table are **`DART-001` …** (zero-padded); post-049 planning continues at **DART-050+**.
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
| `pending` / `planned` | Not started (reserved on roadmap) |
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
| **P6** | Inventory fidelity | Vault resolution, roll tags, socket enrichment, diagnostics, live parity harness |
| **P7** | Nav & shell residuals | Loadouts; Jaspr sync depth; mobile polish |
| **P8** | Production readiness | Public OAuth matrix, entity channel, dual-run ops, cutover re-gate (**GO**) |
| **P9** | Host UI fidelity (post-cutover) | Atlas/BR/DAC presentation on Windows+Jaspr; not cutover re-gate |

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
| **DART-007** | **done** | `finish-gaps` | `dart-007-finish-gaps` | P0 | DART-005, DART-006 | Port finishGaps / next-slot pure helpers | Gap list stable for default vs non-default fixtures |
| **DART-008** | **done** | `optimizer-core` | `dart-008-optimizer-core` | P0 | DART-002 | Port enumerate/prune/score pure core + maxCombinations | Unit tests on small fixture boards; truncation flags; no Flutter isolate yet |
| **DART-009** | **done** | `static-sandbox-data` | `dart-009-static-sandbox-data` | P0 | DART-001 | Port static tables (stat benefits, synergy verbs, exotic ability requirements, etc.) | Constants package; update process documented for sandbox patches |
| **DART-010** | **done** | `dim-builders` | `dart-010-dim-builders` | P0 | DART-006 | Pure DIM loadout JSON builders + equipReady gate call (no network) | jsonOnly payload matches TS golden for one fixture variant |
| **DART-011** | **done** | `domain-parity-gate` | `dart-011-domain-parity-gate` | P0 | DART-003–010 | Aggregate parity suite + package dependency lint (domain has zero IO/UI) | Single command runs full pure suite; melos graph guard; **P0 phase gate** |
| **DART-012** | **done** | `storage-root` | `dart-012-storage-root` | P1 | DART-011 | StorageRoot abstraction + Windows path_provider layout (app support, not repo `.cache`) | Paths documented; unit tests with fake FS |
| **DART-013** | **done** | `drift-schema` | `dart-013-drift-schema` | P1 | DART-012 | Drift schema mirroring core tables (users, builds, variants, sets, synergies, inventory) | Schema creates clean DB; PRAGMA/index notes for critical uniques |
| **DART-014** | **done** | `drift-migrations` | `dart-014-drift-migrations` | P1 | DART-013 | Migration strategy mirroring historical ensure* / column upgrades needed for import later | Empty→current migrate green; documented version table |
| **DART-015** | **done** | `repos-library` | `dart-015-repos-library` | P1 | DART-014 | Repositories: builds/sets/synergies/variants CRUD (no Bungie) | Round-trip fixtures; RESTRICT attach semantics on set delete |
| **DART-016** | **done** | `repos-inventory` | `dart-016-repos-inventory` | P1 | DART-014 | Inventory repository + full-replace transaction shape + sync metadata fields | Composite unique; batch insert in one transaction; busy lock hook |
| **DART-017** | **done** | `manifest-entities` | `dart-017-manifest-entities` | P1 | DART-012 | Entity store reader + extractor port for MVP stores (weapons, armor, subclass pieces, mods) | Offline read of fixture entity JSON; perk/item resolve used by hard constraints adapters |
| **DART-018** | **done** | `manifest-windows-refresh` | `dart-018-manifest-windows-refresh` | P1 | DART-017 | Windows-only full/partial manifest refresh pipeline (download→extract→store) | Settings-level API: status/isStale/refresh; rebuild off UI isolate |
| **DART-019** | **done** | `flutter-windows-host-skeleton` | `dart-019-flutter-windows-host-skeleton` | P1 | DART-012, DART-013 | Minimal Flutter Windows app: open DB, show Settings stub (manifest status only) | App launches; single DB connection; no OAuth yet |
| **DART-020** | **done** | `flutter-catalog-offline` | `dart-020-flutter-catalog-offline` | P1 | DART-017, DART-019 | Catalog facets + browse offline from entity stores | Browse/filter without inventory; **P1 phase gate** |
| **DART-021** | **done** | `bungie-http` | `dart-021-bungie-http` | P2 | DART-011 | Shared Bungie HTTP client (API key header, errors, rate-limit hooks) | Unit tests with mocked HTTP; no secrets in package |
| **DART-022** | **done** | `oauth-pkce` | `dart-022-oauth-pkce` | P2 | DART-021 | Public+PKCE authorize/token/refresh pure + platform redirect URI config | No client_secret fields; state/CSRF; token model |
| **DART-023** | **done** | `flutter-windows-oauth` | `dart-023-flutter-windows-oauth` | P2 | DART-022, DART-019 | Windows loopback/deep-link OAuth + secure storage | Sign-in/out E2E on Windows; tokens not in SQLite plaintext |
| **DART-024** | **done** | `bungie-profile-sync` | `dart-024-bungie-profile-sync` | P2 | DART-021, DART-016 | Profile fetch + inventory sync algorithm into Drift | Full replace + sync_version; 60s freshness helper |
| **DART-025** | **done** | `flutter-inventory-sync-ui` | `dart-025-flutter-inventory-sync-ui` | P2 | DART-023, DART-024 | Settings inventory sync card + busy/error UX | User can sync; **P2 phase gate** (owned data local) |
| **DART-026** | **done** | `flutter-catalog-owned` | `dart-026-flutter-catalog-owned` | P2 | DART-020, DART-025 | Catalog all-vs-owned + instance projections for pickers | Owned filter works after sync |
| **DART-027** | **done** | `app-use-cases-library` | `dart-027-app-use-cases-library` | P3 | DART-015, DART-011 | Application use cases: set/synergy CRUD + attach (in-process, no HTTP) | Use cases call repos + pure domain; tests with in-memory/Drift |
| **DART-028** | **done** | `app-use-cases-build` | `dart-028-app-use-cases-build` | P3 | DART-027, DART-003–007 | Build/variant save pipeline order parity (hard gates + soft coverage query) | Illegal kits hard-block; soft misses do not block non-default |
| **DART-029** | **done** | `flutter-design-tokens` | `dart-029-flutter-design-tokens` | P3 | DART-019 | Shared design tokens + FlapBoard layout contracts (no full brand rewrite) | Documented tokens; Windows theme stub without Material-card default |
| **DART-030** | **done** | `flutter-sets-library-ui` | `dart-030-flutter-sets-library-ui` | P3 | DART-027, DART-029, DART-026 | Sets library + slot fill → catalog pick (Windows dual-pane) | Create/edit set; fill slot from catalog/owned |
| **DART-031** | **done** | `flutter-synergy-library-ui` | `dart-031-flutter-synergy-library-ui` | P3 | DART-027, DART-029 | Synergy library CRUD + evidence links UI | Create synergy; designation immutable after create |
| **DART-032** | **done** | `flutter-build-identity-ui` | `dart-032-flutter-build-identity-ui` | P3 | DART-028, DART-029 | Build list + identity (class, synergy types, exotic/super pins) | Create build with synergy types |
| **DART-033** | **done** | `flutter-variant-compose-ui` | `dart-033-flutter-variant-compose-ui` | P3 | DART-032, DART-030 | Variants, set attachments, slot pins (wishlist vs instance) | Attach set; pin slot; resolve conflicts surfaced |
| **DART-034** | **done** | `flutter-soft-guidance-ui` | `dart-034-flutter-soft-guidance-ui` | P3 | DART-033, DART-004 | Soft coverage chips + soft stat targets UI (display only) | Soft never auto-applies; **P3 phase gate** (compose without equip) |
| **DART-035** | **done** | `optimizer-isolate` | `dart-035-optimizer-isolate` | P4 | DART-008, DART-028 | Run enumerate in isolate; materialize Armor Set use case | UI thread safe; confirm-only apply path |
| **DART-036** | **done** | `flutter-optimizer-ui` | `dart-036-flutter-optimizer-ui` | P4 | DART-035, DART-030 | Finish/optimizer workspace on Windows | Suggest → user confirm; never silent apply |
| **DART-037** | **done** | `equip-orchestrator` | `dart-037-equip-orchestrator` | P4 | DART-006, DART-024 | planEquipSteps + execute + partial status (write client) | Best-effort partial; no full rollback; tests with mocked write API |
| **DART-038** | **done** | `flutter-equip-ui` | `dart-038-flutter-equip-ui` | P4 | DART-037, DART-033 | Character pick + equip CTA + step report | Equip-ready gate enforced; gaps confirm UX |
| **DART-039** | **done** | `flutter-dim-export-ui` | `dart-039-flutter-dim-export-ui` | P4 | DART-010, DART-038 | DIM jsonOnly / clipboard export | Blocked when not equip-ready |
| **DART-040** | **done** | `flutter-mobile-shell-nav` | `dart-040-flutter-mobile-shell-nav` | P4 | DART-034 | Android+iOS app shell: bottom nav, Focus Swap routes, shared use cases | Installable debug builds; Settings+Build list at minimum |
| **DART-041** | **done** | `flutter-mobile-compose` | `dart-041-flutter-mobile-compose` | P4 | DART-040, DART-033–034 | Reduced-density compose on phone (sheets, linear finish) | Create build → attach → soft guidance on device; **P4 phase gate** |
| **DART-042** | **done** | `jaspr-app-skeleton` | `dart-042-jaspr-app-skeleton` | P5 | DART-011, DART-013 | Jaspr app shell + routing + design tokens (CSS) | Hello Settings page; no Next dependency |
| **DART-043** | **done** | `jaspr-opfs-sqlite` | `dart-043-jaspr-opfs-sqlite` | P5 | DART-042, DART-014 | Drift WASM + OPFS + single-tab writer lock UX | Second tab read-only or blocked; documented limits |
| **DART-044** | **done** | `jaspr-entity-bundles` | `dart-044-jaspr-entity-bundles` | P5 | DART-017, DART-042 | Load prebuilt entity bundles (no full raw rebuild in browser) | Offline catalog facets on web |
| **DART-045** | **done** | `jaspr-oauth-pkce` | `dart-045-jaspr-oauth-pkce` | P5 | DART-022, DART-042 | Browser Public+PKCE + token storage strategy | No confidential secret; sign-in works on HTTPS loopback/prod origin |
| **DART-046** | **done** | `jaspr-compose-spine` | `dart-046-jaspr-compose-spine` | P5 | DART-043–045, DART-027–028 | Port compose spine UI to Jaspr (build/sets/synergy/catalog) | Intent→compose with hard/soft parity |
| **DART-047** | **done** | `jaspr-equip-export` | `dart-047-jaspr-equip-export` | P5 | DART-046, DART-037, DART-010 | Equip-ready + DIM json + optional equip on web | Same domain packages as Flutter |
| **DART-048** | **done** | `legacy-db-import` | `dart-048-legacy-db-import` | P5 | DART-014, DART-043 | Import tool/UX from Next `.cache/app.db` → platform StorageRoot | One documented migration path; dry-run + apply |
| **DART-049** | **done** | `cutover-parity-checklist` | `dart-049-cutover-parity-checklist` | P5 | DART-047, DART-041, DART-038 | Written parity checklist vs PRODUCT production nav; Next retirement criteria | Checklist in repo; explicit go/no-go; **P5 / program gate** |
| **DART-050** | **done** | `inventory-vault-resolution` | `dart-050-inventory-vault-resolution` | P6 | DART-024, DART-017/018 | Wire equipmentBucketLookup so vault/postmaster copies are stored | **GAP-INV-01**, GAP-INV-06 docs, GAP-INV-07 opt, **PROC-01/02/06**. Build itemHash→bucket lookup from DestinyInventoryItemDefinition/entity stores; wire non-empty lookup into **every** production sync path (Windows Settings syncNow, Windows equip syncIfStale, Jaspr equip, future web Settings). Vault/postmaster weapon/armor in Drift with Kinetic/Energy/Power/armor buckets; unit+host fixtures assert resolvedFromTransfer>0; host tests fail if vault fixtures omit lookup; package docs stop treating empty lookup as production-OK; finish-spec rejects “user can sync” alone and opens GAP+RB for intentional thinning; document Owned still needs entity stores → DART-053 UX. Optional: parseWeaponStatValues parity (GAP-INV-07). Soft never auto-applies; no CLIENT_SECRET |
| **DART-051** | **done** | `inventory-roll-tags` | `dart-051-inventory-roll-tags` | P6 | DART-050 | Port computeRollTags parity for weapon inventory rows | **GAP-INV-02** closed; roll tags match Next computeRollTags golden fixtures for crafted/champion/build samples; soft never auto-applies; web perk-name residual (no raw defs) documented not pure thinning |
| **DART-052** | **done** | `inventory-socket-enrichment` | `dart-052-inventory-socket-enrichment` | P6 | DART-050 | Enrich socket plugs for perk grids (weapon socket context) | **GAP-INV-03** closed; stored plugs include columnKind/columnLabel for instance perk grids; parity tests vs Next buildStoredSocketPlugs; web raw-less residual documented (PROC-06) |
| **DART-053** | **done** | `inventory-sync-diagnostics-ui` | `dart-053-inventory-sync-diagnostics-ui` | P6 | DART-025, DART-050 | Settings UI: raw/parsed/dropped/vault resolved counts + entity-cache empty warning | **GAP-INV-04**, **GAP-INV-06** UX. Controller retains last SyncInventoryResult diagnostics; Settings (Windows + web parity path) surfaces raw/parsed/dropped + resolution.resolvedFromTransfer/droppedNonEquipment/storedTotal; entity-cache empty warning so empty Owned is not blamed solely on inventory sync |
| **DART-054** | **done** | `inventory-live-parity-harness` | `dart-054-inventory-live-parity-harness` | P6 | DART-050–053 | Live/manual+tool Next-vs-Dart inventory count harness | **GAP-INV-05**, **PROC-03/04/05** closed. Dual-run procedure + compare tool + offline fidelity gate; RC-SYNC fidelity metrics; RB-06 cleared with DART-050–053 evidence |
| **DART-055** | **done** | `in-game-loadouts-surface` | `dart-055-in-game-loadouts-surface` | P7 | DART-024 | First-class Loadouts UI (Windows first) or product demote | **GAP-NAV-01** closed; RB-01 cleared; RC-NAV PASS for loadouts. Windows NavigationRail + page; Jaspr `/loadouts`; pure component 206 parse |
| **DART-056** | **done** | `jaspr-inventory-sync-depth` | `dart-056-jaspr-inventory-sync-depth` | P7 | DART-050, DART-045 | Web sync/owned depth match Windows resolution rules | **GAP-WEB-01** closed; RB-02 cleared; RC-SYNC PASS for web depth. Settings Sync now + vault lookup + diagnostics; Catalog All\|Owned + instanceId pins |
| **DART-057** | **done** | `mobile-compose-equip-polish` | `dart-057-mobile-compose-equip-polish` | P7 | DART-041, DART-050 | Mobile surface matrix; equip/catalog as product requires; Jaspr soft-stat editor; finish-gaps host UX | **GAP-MOB-01**, **GAP-UI-01**, **GAP-FEAT-06** closed; GAP-FEAT-01 deferred. Published mobile matrix; equip/catalog/DIM **N/A**; shell_nav Matches Builds\|Settings. Jaspr all ArmorStatName soft-stats. Windows+Jaspr finish-gaps host + CTA finish-complete ∧ equip-ready. Soft never auto-applies |
| **DART-058** | **done** | `prod-public-oauth-matrix` | `dart-058-prod-public-oauth-matrix` | P8 | DART-023, DART-045 | Prod Public redirects for all shells; no secrets in clients | **GAP-AUTH-01** closed; RB-03 cleared; RC-AUTH **PASS**. Published matrix (Windows HTTPS loopback, Jaspr `/auth/callback`, mobile schemes); secret scan gate; smoke preflight + operator checklist |
| **DART-059** | **done** | `entity-bundle-prod-channel` | `dart-059-entity-bundle-prod-channel` | P8 | DART-044 | Choose/harden entity bundle distribution for web | **GAP-WEB-02** closed; RB-05 cleared; RC-WEB-DATA **PASS**. Hybrid channel (ship-in-app primary + optional CDN) + versioning; prod `/entities/prod/bundle.json` offline; no Next manifest API |
| **DART-060** | **done** | `dual-run-rollback-ops` | `dart-060-dual-run-rollback-ops` | P8 | DART-050+ feature-ready dual-run | Execute dual-run + rollback runbook once | **GAP-OPS-01** closed; RB-04 cleared; RC-OPS **PASS**. Runbook + EXECUTED_ONCE notes; Next + Dart web/Windows available; compose→equip re-verify (equip-ready, Bungie equip partial OK, DIM jsonOnly); rollback = keep Next sole production; `tool/dual_run_ops_gate.dart` |
| **DART-061** | **done** | `production-cutover-regate` | `dart-061-production-cutover-regate` | P8 | DART-050–060 as needed | All RC-* pass; PRODUCTION_CUTOVER GO | **GAP-CUT-01** closed; GAP-FEAT-02 remains non-goal (jsonOnly). All RC-* PASS incl. RC-BRANCH; PRODUCTION_CUTOVER: GO 2026-07-25 with rationale; merge toward production/main allowed only after GO; offline `tool/production_cutover_regate.dart` |
| **DART-062** | **done** | `catalog-browse-semantics` | `dart-062-catalog-browse-semantics` | P9 | DART-061 | Catalog multi-facet, group-by, alpha sort, exotic weapons + legendary armor defs | **GAP-UI-CATALOG-01, 02, 04, 05, 07** closed. Windows+Jaspr multi-value include/exclude (slot/class/archetype/element/ammo/exotic); multi-dim group-by without changing filter semantics; alpha sort by display name; exotic-weapons + legendary-armor MVP stores; DAC-NME-003 + BR-CAT-001/003/006/007. **Cutover GO unchanged.** Soft never auto-applies; no CLIENT_SECRET |
| **DART-063** | **done** | `catalog-universal-modes-synergy-tags` | `dart-063-catalog-universal-modes-synergy-tags` | P9 | DART-062 | Weapons/Armor/Universal modes; synergy membership + BR-SYN-004 reverse tags; owned instance detail | **GAP-UI-CATALOG-03, 06, 08, 10; GAP-UI-SYN-03**. Universal Set/Synergy actions only (no Build kit attach); kind-appropriate facets; human-readable owned perks/traits + armor base-stat board when resolvable. Soft never auto-applies; no CLIENT_SECRET |
| **DART-064** | **done** | `build-identity-subclass-compose` | `dart-064-build-identity-subclass-compose` | P9 | DART-061 | Identity Confirm/Fork; subclass kit composer; Manifest pickers; hard-block UX; Jaspr attach pickers | **GAP-UI-BUILD-01, 02, 05, 08, 09**. DBR-ID-008 Confirm/Fork; full subclass kit + capacity plain language; Manifest search exotic/Super; client hard-block dual exotic/kit; Jaspr named set picker + per-slot pins. Soft never auto-applies; no CLIENT_SECRET |
| **DART-065** | **done** | `sets-board-rows-fill` | `dart-065-sets-board-rows-fill` | P9 | DART-061 | Armor EoF base-roll board; dense item rows; slot-fill Catalog; replace confirm; weapon perks | **GAP-UI-SETS-01, 02, 03, 07, 10**. DAC-NME-004/BR-SET-010/011 board + totals; icons/traits/synergies/Instance\|Wishlist; both shells embedded catalog density (Jaspr not hash-only); occupied-slot replace confirm; selectedPerks on weapon fill. Soft never auto-applies; no CLIENT_SECRET |
| **DART-066** | **done** | `synergy-picker-manage-sets-library` | `dart-066-synergy-picker-manage-sets-library` | P9 | DART-063 (syn tags helpful) | Synergy catalog picker + Jaspr manage; Sets library filters/readiness/delete | **GAP-UI-SYN-01, 02, 04, 06, 09; GAP-UI-SETS-04, 05, 06**. BR-SYN-011 omit-linked + BR-SYN-012 labels; Jaspr detail/edit/links; library search/type filters; delete synergy; Sets search+tag AND, Fill next/used-by, SET_IN_USE delete. Soft never auto-applies; no CLIENT_SECRET |
| **DART-067** | **done** | `finish-walkthrough-armor-optimize` | `dart-067-finish-walkthrough-armor-optimize` | P9 | DART-064, DART-036 | Finish one-tap Create/Capture/fill; Build Finish armor improve; Settings post-sync banner | **GAP-UI-BUILD-03, 04; GAP-UI-SETTINGS-04** closed. BR-BLD-008 walkthrough Create/Capture/fill (Windows+Jaspr); Windows Build Finish Find kits → confirm apply; Windows post-sync better-kit Confirm/Dismiss only — **never auto-apply**. Web optimizer remains GAP-FEAT-01 deferred. Soft never auto-applies; no CLIENT_SECRET |
| **DART-068** | **done** | `presentation-shell-loadouts-settings` | `dart-068-presentation-shell-loadouts-settings` | P9 | DART-062+ as needed | Shell labels; icons/meta; loadouts density; Settings chrome; designation icons | **GAP-UI-CATALOG-09; GAP-UI-BUILD-06; GAP-UI-SYN-05; GAP-UI-LOADOUTS-01..03; GAP-UI-SETTINGS-01, 02; GAP-UI-SHELL-01** closed. AppShell label/order; item icons; loadout color bar/swatch + exotic names + expand; READY/entity chips + ONLINE/Refresh; variant icon overview. **Not cutover re-gate.** Soft never auto-applies; no CLIENT_SECRET |
| **dart-070** | **done** | `set-occupancy` | `dart-070-set-occupancy` | P0 | domain + app | Set package min occupancy + Pair complete on save/attach | **GAP-DOM-SET-01** closed. Pure `set_minimum_occupancy` (Weapon/Armor ≥2 → `SET_MIN_ITEMS`; Mod ≥2 pieces → `MOD_SET_MIN_SLOTS`; Pair both → `PAIR_INCOMPLETE`; Fashion exempt). App assert + attach gates (BR-ATT-006); attachableSets filter; readiness package-min; hosts plain-language. Soft never auto-applies; no CLIENT_SECRET |

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

### P6 — Inventory fidelity (DART-050–054)

Critical path after program gate: production hosts omit `equipmentBucketLookup` so vault/postmaster drops before Drift (GAP-INV-01). **DART-050** wires lookup on every production sync call site and hardens exit criteria (PROC-01/02/06). Enrichment (roll tags, sockets) and diagnostics follow; **DART-054** live harness + RC-SYNC fidelity metrics prevent silent drift. Soft never auto-applies; no CLIENT_SECRET.

### P7 — Nav & shell residuals (DART-055–057)

Loadouts (RB-01), Jaspr owned depth after vault fix (RB-02), mobile surface matrix + Jaspr soft-stat editor completeness + finish-gaps host UX (GAP-FEAT-06; pure DART-007 already shipped).

### P8 — Production readiness (DART-058–061)

Public OAuth matrix (no secrets in clients), entity bundle channel, dual-run ops with live compose→equip re-verify, production cutover re-gate.

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
| **Next / active slice** | **None** — P9 host UI fidelity complete (DART-062–068 **done**) |
| **Active branch** | `feature/multiplatform-dart` |
| **Specs dir** | [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md); [ui-fidelity.md](./multiplatform-dart-ui-fidelity.md); cutover [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) |
| **Active worktree** | `F:\Destiny2BuildCreator-multiplatform-dart` |
| **Blocked on** | **None** for cutover — **PRODUCTION_CUTOVER: GO** (DART-061). P9 UI fidelity closed (does not re-open cutover). Human/release may merge toward production/`main` (RC-BRANCH) |
| **Phase plan** | P6–P9 **done** (DART-050–068); host UI fidelity residual closed |

### P9 note — host UI fidelity post-cutover

After PRODUCTION_CUTOVER GO, Windows+Jaspr host spines remain cutover-PASS. **DART-062–068 done** closed catalog/build/sets/synergy/finish/presentation residuals vs Next atlas. Canonical ledger: [multiplatform-dart-ui-fidelity.md](./multiplatform-dart-ui-fidelity.md). Soft never auto-applies; no CLIENT_SECRET. **Does not re-open PRODUCTION_CUTOVER.**

### DART-062 note (completed) — catalog browse semantics

Closed **GAP-UI-CATALOG-01, 02, 04, 05, 07**. Pure `groupCatalogItems` + `compareDisplayName` alpha sort finalize; MVP stores `exotic-weapons` + `legendary-armor`; OfflineCatalog/EntityBundle projection; Windows+Jaspr multi-value include/exclude for slot/class/archetype/element/ammo/exotic + optional multi-dim group-by. DAC-NME-003 + BR-CAT-001/003/006/007. Cutover GO unchanged. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-062-catalog-browse-semantics/`.

### DART-061 note (completed) — production cutover re-gate

All **RC-*** **PASS** including **RC-BRANCH**; **`PRODUCTION_CUTOVER: GO`** (2026-07-25) with date/rationale; **GAP-CUT-01** closed; **GAP-FEAT-02** dim.gg remains non-goal (jsonOnly sufficient). Merge of `feature/multiplatform-dart` toward production/`main` allowed only after GO ([branching.md](./multiplatform-dart-branching.md)). Offline re-gate `tool/production_cutover_regate.dart`. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-061-production-cutover-regate/`. Finish-spec still lands on `feature/multiplatform-dart` only; actual main merge is human/release follow-on.

### DART-060 note (completed) — dual-run + rollback ops

Written dual-run runbook with Next sole production + Dart Windows/Jaspr available; **EXECUTED_ONCE** notes 2026-07-25; compose→equip re-verify (equip-ready, Bungie equip partial OK, DIM jsonOnly) in dual-run window via host tests; **ROLLBACK_PROCEDURE** = keep Next sole production; offline gate `tool/dual_run_ops_gate.dart`. GAP-OPS-01 closed; RB-04 cleared; RC-OPS PASS. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-060-dual-run-rollback-ops/`. Doc: `docs/multiplatform-dart-dual-run-rollback-runbook.md`. Next: **DART-061** (done).

### DART-059 note (completed) — entity bundle prod channel

Chosen **hybrid** distribution: ship-in-app primary (`/entities/prod/bundle.json`) for offline after install + optional CDN in `channel.json` with fallback. Versioning via `/entities/channel.json` + bundle `manifestVersion` (`entity-bundle-prod-*`). Pure `EntityBundleChannel` + `WebEntityBundleLoader` channel-aware load; no Next `/api/manifest`; no browser raw rebuild. GAP-WEB-02 closed; RB-05 cleared; RC-WEB-DATA PASS. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-059-entity-bundle-prod-channel/`. Doc: `docs/multiplatform-dart-entity-bundle-channel.md`. Next: **DART-060** dual-run rollback ops.

### DART-058 note (completed) — prod Public OAuth matrix

Published Bungie Public redirect matrix (Windows `https://127.0.0.1:8765/callback`, Jaspr `{origin}/auth/callback`, mobile `d2buildcreator://oauth/callback`) in docs + `ProdPublicOAuthMatrix`. Windows host default HTTPS. Client secret scan `tool/client_secret_scan.dart` (zero BUNGIE_CLIENT_SECRET / SESSION_SECRET in client lib trees). Smoke: mocked Windows/Jaspr OAuth session preflight + operator checklist. GAP-AUTH-01 closed; RB-03 cleared; RC-AUTH PASS. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-058-prod-public-oauth-matrix/`.

### DART-057 note (completed) — mobile compose / equip polish

Published mobile surface matrix (`surface_matrix.dart`) PASS/PARTIAL/N/A/deferred for AppShell + equip/DIM/optimizer; bottom nav Builds\|Settings; Settings matrix card; equip/catalog/DIM product-marked **N/A** (OAuth path Windows/Jaspr). Jaspr soft-stat editor all `ArmorStatName` + explicit save. Windows + Jaspr host `evaluateFinishGaps` panels with category reasons; equip/DIM CTAs require finish-complete **AND** equip-ready; mobile finish display-only. GAP-MOB-01 / GAP-UI-01 / GAP-FEAT-06 closed; GAP-FEAT-01 remains deferred. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-057-mobile-compose-equip-polish/`. Tests: mobile surface/shell/finish; windows/web finish + equip/dim format.

### DART-056 note (completed) — Jaspr inventory sync depth

Jaspr `InventorySyncController` + Settings **Sync now** card call `syncUserInventory` with lazy catalog-slot `equipmentBucketLookupBuilder` (same vault/postmaster resolution rules as Windows post-DART-050 equip path). Diagnostics retained (raw/parsed/dropped/`resolvedFromTransfer`). Catalog **All \| Owned** + instance projections with **instanceId** for compose equip/DIM pins. Host vault fixtures assert Kinetic/Helmet stored + `resolvedFromTransfer > 0`. GAP-WEB-01 closed; GAP-INV-06 closed; RB-02 cleared; RC-SYNC no longer fails for web owned depth. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-056-jaspr-inventory-sync-depth/`. Tests: `apps/web_host/test/inventory_sync_*`, `catalog_owned_page_test`.

### DART-055 note (completed) — in-game loadouts surface

Pure `parseCharacterLoadoutsResponse` + presentation tables (component 206 / DIM source) in `packages/bungie`. Profile client `getCharacterLoadoutsProfile` (`components=200,206`). Windows NavigationRail **Loadouts** + list page (class / hide-empty filters, refresh, signed-out gate). Jaspr ShellHeader + `/loadouts` route + page. Cutover loadouts row PASS (Windows+web); RB-01 cleared; RC-NAV PASS for loadouts; GAP-NAV-01 closed. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-055-in-game-loadouts-surface/`. Tests: `character_loadouts_test`, windows_host loadouts/nav, web_host shell/loadouts.

### DART-054 note (completed) — inventory live parity harness

Dual-run procedure doc `docs/multiplatform-dart-inventory-live-parity-harness.md` (same-membership Next vs Dart counts by location/bucket + raw/stored/resolvedFromTransfer). Pure Dart snapshot compare library + CLI `tool/inventory_fidelity_compare.dart`. Offline CI/operator gate `tool/inventory_fidelity_gate.dart` (fixture pair + doc markers) **separate** from `p0_parity_gate` (PROC-05). Default tolerance exact (0). Cutover RC-SYNC cites harness; RB-06 cleared with DART-050–053 product evidence. GAP-INV-05 + PROC-03/04/05 closed. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-054-inventory-live-parity-harness/`. Tests: `dart test tool/test/inventory_fidelity_*.dart`; `dart run tool/inventory_fidelity_gate.dart`.

### DART-053 note (completed) — inventory sync diagnostics UI

`formatSyncDiagnostics` pure helper (Next ManifestCard parity) in `destiny2_bungie`. `InventorySyncController` retains full `lastDiagnostics` after successful `syncNow` (raw/parsed/dropped + resolution). Windows `InventorySyncCard` surfaces keys for raw/parsed/dropped/resolvedFromTransfer/droppedNonEquipment/storedTotal + monospace format block. Settings entity-cache empty warning + Catalog Owned empty prefers entity-cache message (GAP-INV-06 UX). Web Settings Owned/entity dependency warning (full web sync depth delivered by DART-056). Soft never auto-applies; no CLIENT_SECRET. GAP-INV-04 closed. Specs: `specs/dart-053-inventory-sync-diagnostics-ui/`. Tests: format_sync_diagnostics + windows_host inventory/settings/catalog + web settings.

### DART-052 note (completed) — inventory socket enrichment

`classifyWeaponSocket` + `buildStoredSocketPlugs` pure port + golden fixtures matching Next classify tests; `weaponSocketContextBuilder` + `buildWeaponSocketContextFromItemDefs` for plug categories / perk indexes (`4241085061`). `syncUserInventory` stores weapon plugs with `columnKind`/`columnLabel` when context provided; non-weapons null; no-context raw fallback. Windows Settings + equip wire raw DestinyInventoryItemDefinition; web MVP raw-less residual documented (PROC-06). Soft never auto-applies; no CLIENT_SECRET. GAP-INV-03 closed (package + Windows). Specs: `specs/dart-052-inventory-socket-enrichment/`. Tests: `dart test packages/bungie` (99 green).

### DART-051 note (completed) — inventory roll tags

`computeRollTags` pure port + golden tests matching Next `rollTags.test.ts` (Crafted, frame/perk champion, MeleeBuildCandidate, OrbitBuild). `_normalizeItems` / `syncUserInventory` accept perkNameMap + weaponRollMetaLookup (maps/builders). Windows Settings + equip wire raw plug names + OfflineCatalog weapon meta; Jaspr equip wires catalog frame meta. Soft never auto-applies; no CLIENT_SECRET. GAP-INV-02 closed; web perk-name residual (no raw defs) documented. Specs: `specs/dart-051-inventory-roll-tags/`. Tests: `dart test packages/bungie`.

### DART-050 note (completed) — vault / postmaster resolution

`buildEquipmentBucketLookup` + slot fallback; production wiring on Windows Settings `syncNow`, Windows equip + Jaspr equip `syncIfStale`. Unit+host fixtures assert `resolvedFromTransfer > 0` and Kinetic/Helmet vault rows. Package docs: empty lookup not production-OK. GAP-INV-06 residual → DART-053 UX. Optional GAP-INV-07 `parseWeaponStatValues` shipped. Soft never auto-applies; no CLIENT_SECRET. Specs: `specs/dart-050-inventory-vault-resolution/`.

### DART-049 note (completed) — **P5 / program gate**

Written cutover parity checklist vs PRODUCT `AppShell` production nav + compose→equip capability matrix (Windows / mobile / Jaspr). Next retirement criteria `RC-*`; dual verdicts: `PROGRAM_GATE: GO`, `PRODUCTION_CUTOVER: NO-GO` (residual loadouts surface, web sync polish, prod Public redirects, dual-run ops, entity bundle channel). Validator: `dart test tool/test/cutover_parity_checklist_validate_test.dart` (7 green). Canonical doc: `docs/multiplatform-dart-cutover-parity-checklist.md`. Soft never auto-applies; no CLIENT_SECRET. **Program planned slices complete** — production Next retirement is a separate human gate.

### DART-048 note (completed)

Legacy Next `.cache/app.db` → platform StorageRoot: pure `LegacyDbImporter` dry-run + apply (replace + backup + ensure*); Windows Settings **Data migration** card; docs `docs/multiplatform-dart-legacy-db-import.md`; CLI `tool/legacy_db_import.dart`. Tests: `packages/db` legacy_db_import (8) + full db suite; windows_host controller/card (5). Soft never auto-applies; no CLIENT_SECRET. Next: DART-049 cutover checklist.

### DART-047 note (completed)

Jaspr web Build compose surfaces equip-ready (domain `computeEquipReady`), DIM jsonOnly clipboard export (`buildJsonOnlyDimExport`, blocked when not equip-ready), and optional equip (character pick + gaps confirm + `planEquipSteps`/`executeEquipPlan`). Same domain packages as Flutter. Soft never auto-applies. No CLIENT_SECRET.

### DART-046 note (completed)

Jaspr web host compose spine: Builds/Sets/Synergies routes + Catalog nav; in-process `destiny2_app` use cases; hard attach gates + soft guidance display-only. Writer-tab only. Tests: `dart test` in `apps/web_host` (70 green).

### DART-045 note (completed)

Browser Public+PKCE on Jaspr web host: `WebOAuthSession` + origin-scoped `localStorage` tokens (not SQLite), `sessionStorage` pending PKCE, `/auth/callback`, Settings account card. No `CLIENT_SECRET`. Merged on `feature/multiplatform-dart`.

### DART-044 note (completed)

- **Prebuilt bundles:** `EntityBundleDocument` + `MemoryEntityCache` in `destiny2_manifest`; no raw rebuild in browser.
- **Web-safe IO:** conditional text-file / HTTP / isolate stubs so catalog APIs import on Jaspr web.
- **Catalog:** `apps/web_host` `/catalog` — query + element/ammo/exotic facets; fixture `web/entities/prebuilt/bundle.json`.
- **Tests:** `packages/manifest` green (entity_bundle_test); `apps/web_host` 26 green (loader + Catalog page + prior).
- **Next:** DART-045 browser Public+PKCE OAuth.

### DART-043 note (completed)

- **OPFS/WASM:** `WasmWebDatabaseOpener` + `web/sqlite3.wasm` / `drift_worker.js` (fetch script `tool/fetch_drift_web_assets.ps1`).
- **Single-tab writer:** `TabWriterCoordinator` + localStorage heartbeat; second tab **blocked** with Settings banner.
- **destiny2_db:** conditional native open (`connection/open_*.dart`); web uses `AppDatabase(executor)`.
- **Limits:** `docs/multiplatform-dart-web-opfs-limits.md`.
- **Tests:** `apps/web_host` 20 green (lock + Settings status + prior skeleton); `packages/db` green.
- **Next:** DART-044 prebuilt entity bundles (done).

### DART-042 note (completed)

- **Package:** `apps/web_host` / `destiny2_web_host` — Jaspr **client** SPA; `jaspr_router` Settings at `/` and `/settings`.
- **Tokens CSS:** `lib/theme/flap_tokens_css.dart` maps `destiny2_ui_tokens` → `:root` custom properties (`#050608`, `#e6b35c`, radius `0`).
- **Workspace:** not a root pub workspace member (Jaspr builder/analyzer requires newer `meta` than Flutter hosts pin). `cd apps/web_host && dart pub get`.
- **Exit:** Hello Settings page; no Next dependency; `dart test` green.
- **Next:** DART-043 OPFS/SQLite single-writer (done).

### DART-041 note (completed) — **P4 phase gate**

Mobile reduced-density compose on `apps/mobile_host`: create-build FAB sheet, linear Focus Swap detail (variants → attach sheet → pins → soft guidance chips + explicit soft stat save). Shared `destiny2_app` use cases; soft never auto-applies; hard `SLOT_CONFLICT` surfaces. `flutter test` 23 green. **P4 complete** (optimizer/equip/DIM/Windows + mobile shell + mobile compose). Next: P5 Jaspr.

### DART-040 note (completed)

Android+iOS `apps/mobile_host`: bottom NavigationBar (Builds|Settings), Focus Swap nested navigator (list XOR detail), shared `destiny2_app` list/detail use cases, local-library user, Matte Flap theme. Android `flutter build apk --debug` green; `ios/` present for macOS. Soft never auto-applies; no CLIENT_SECRET. Full mobile compose → DART-041.

### DART-039 note (completed)

Windows Builds detail **DIM export** panel: equip-ready gate (wishlist/stale block Copy); **Copy DIM JSON** builds jsonOnly `{ loadout }` via pure `buildJsonOnlyDimExport` (DART-010) and writes clipboard; injectable clipboard for tests; soft never auto-applies; no dim.gg network. Tests: `dim_export_format_test` + `dim_export_panel_test` (8).

### DART-038 note (completed)

Windows Builds detail **Equip / Apply** panel: class-filtered character pick (`getCharacters`), equip-ready gate (wishlist/stale block CTA), empty combat **gaps confirm**, `planEquipSteps` + `executeEquipPlan` with **step report**. Soft never auto-applies. Tests: `equip_format_test` + `equip_panel_test` + bungie `character_parse_test`.

### DART-037 note (completed)

Merged pure `planEquipSteps` into `packages/domain` and `BungieWriteClient` + best-effort `executeEquipPlan` (no full rollback) into `packages/bungie` with mocked write/HTTP tests. Artifact HTTP apply remains season-stub; Flutter equip UI is DART-038.

### DART-036 note (completed)

- Windows Sets detail **Armor optimizer workspace** for `armor` sets (goals → Find kits → suggestions)
- Find kits uses DART-035 isolate/local runners — **never writes** sets
- Apply in place / Materialize require **explicit confirm dialog**; cancel leaves set unchanged
- Soft thresholds / prefer-reuse never auto-apply kits; advisory caption: never silent apply
- Injectable candidates for tests; inventory bucket map for live candidates
- Tests: `flutter test test/optimizer_format_test.dart test/optimizer_workspace_test.dart` (18) + sets library green

### DART-035 note (completed)

- Pure `optimizeArmorCore` pipeline (prune → enumerate → score/rank) in `destiny2_domain`
- `optimizeArmorInIsolate` via `Isolate.run` + local runner in `destiny2_app` (UI-thread safe)
- Confirm-only `materializeArmorCombination` / `applyArmorCombinationInPlace` — optimize never writes sets
- Soft thresholds filter only when `requireThresholds`; soft never auto-applies; auto-stat-mods deferred
- Tests: `dart test packages/domain packages/app` (pipeline + isolate + materialize suites)

### DART-034 note (completed) — **P3 phase gate**

- Builds detail **soft guidance** (display only): synergy coverage chips (`supported` / `weak` / `missing`) via `queryVariantCoverage`
- Soft set-bonus / element mismatch rows when present; soft-stat warnings when estimate supplied
- Soft stat targets: view + **explicit** save via `updateUserBuild` (never from coverage/nudges)
- Advisory caption: soft never auto-applies and does not block save; hard DBR blocks stay hard
- **P3 gate**: Windows compose spine complete without equip (sets → synergy → build identity → variant compose → soft guidance)
- Tests: `flutter test test/soft_guidance_format_test.dart test/soft_guidance_page_test.dart` (+ builds/compose suite green)

### DART-033 note (completed)

- Builds detail **variant compose**: list/create/select variants; attach/detach library sets (live)
- Slot pins board: wishlist vs instance labels; pin/clear instance on live-attached set items
- Hard `SLOT_CONFLICT` (and other use-case hard gates) surfaced in status; rollback preserves prior attachments
- Soft guidance never auto-applies; pure `variant_compose_format` helpers
- Tests: `flutter test test/variant_compose_format_test.dart test/variant_compose_page_test.dart` (+ builds suite green)

### DART-032 note (completed)

- Windows **Builds** nav + dual-pane library (`kFlapLibraryRailWidth` + `kFlapColumnsBuilds`)
- Create via `destiny2_app` `createUserBuild`; local-library user when signed out
- Identity: class, ≥1 synergy type designation, optional exotic armor/weapon + pinned Super
- Hard `NO_SYNERGY` when zero synergy types; soft guidance never auto-applies
- In-place identity update (confirm/fork deferred); variant compose delivered in DART-033
- Pure `build_identity_format` helpers (designation list, exotics/identity summaries)
- Tests: `flutter test test/build_identity_format_test.dart test/builds_library_page_test.dart` (15)

### DART-031 note (completed)

- Windows **Synergies** nav + dual-pane library (`kFlapLibraryRailWidth` + `kFlapColumnsSynergy`)
- Create via `destiny2_app` synergy use cases; local-library user when signed out
- Designation (type + subtype) **immutable after create** (read-only chip; use-case `DESIGNATION_IMMUTABLE`)
- Evidence links draft/add/remove + full-list save; creatable types only on create
- Pure `formatSynergyDesignation` helper
- Tests: `flutter test test/synergy_designation_test.dart test/synergies_library_page_test.dart` (11)

### DART-030 note (completed)

- Windows **Sets** nav + dual-pane library (`kFlapLibraryRailWidth` list + detail/slots)
- Create/edit via `destiny2_app` set use cases; local-library user when signed out
- Slot fill → catalog picker (All|Owned) + optional instance pin; clear slot soft-remove
- Pure `set_slot_mapping` (slots-for-type, Kinetic→primary, armor buckets)
- Tests: `flutter test test/set_slot_mapping_test.dart test/sets_library_page_test.dart` (17)

### DART-029 note (completed)

- Package `packages/ui_tokens` (`destiny2_ui_tokens`): pure ARGB colors, spacing, radius 0, typography metrics, FlapBoard rail/gap/column templates; README documented.
- Windows `buildFlapTheme()`: void canvas, accent primary, **cardTheme elevation 0 + square shape** (no Material-card default); wired in `Destiny2WindowsApp`.
- Tests: `dart test packages/ui_tokens`; `flutter test test/flap_theme_test.dart` in windows_host.
- Out of scope kept: full FlapRow widget suite, brand rewrite of every surface, Jaspr CSS (DART-042).

### DART-028 note (completed)

- Extended `packages/app`: build/variant save pipeline with hard-gate order parity + soft coverage query
- Illegal kits hard-block (`NO_SYNERGY`, subclass kit, exotic ability, slot conflict, exotic limits, default completeness); soft misses never block save
- Injectable `HardGatePorts` for manifest-backed inputs; R1/R2 rollback on failed equipment validation
- Tests: `dart test packages/app` (33, in-memory Drift)

### DART-027 note (completed)

- Package `packages/app` (`destiny2_app`): set/synergy library CRUD + `prepareAttachments` / `replaceAttachmentByType`
- In-process only; pure domain type/link validation; designation immutability; fashion max-one
- Tests: `dart test packages/app` (in-memory Drift)

### DART-026 note (completed)

Catalog **All | Owned** scope after inventory sync; `owned`/`ownedCount` annotate from Drift; instance projections (power-desc) for pickers on row select. Exit: owned filter works after sync.

### DART-025 note (completed) — **P2 phase gate**

Settings inventory sync card on Windows host: `InventorySyncController` + `InventorySyncCard` (Sync now → `syncUserInventory`, busy/error, 60s freshness display). Local `ensureUser` from OAuth membership id; tokens stay in secure storage. **P2 complete** (Public+PKCE OAuth + inventory full-replace → owned data local). Tests: `flutter test` apps/windows_host (38). Next: DART-026 catalog owned filter.

### DART-024 note (completed)

Profile client + inventory parse in `destiny2_bungie`; `syncUserInventory` full-replace into Drift (sync_version); `isInventoryFresh` / `syncIfStale` at 60s (DBR-EQP-007). No Settings UI (DART-025).

### DART-023 note (completed)

- **Host:** `apps/windows_host` OAuth — loopback `127.0.0.1` callback, system browser, `WindowsOAuthSession`, Settings account card
- **Storage:** `flutter_secure_storage` / `TokenStore` — access/refresh **not** in SQLite plaintext
- **Exit:** Sign-in/out E2E (mocked transport + fake browser); `flutter test` 24; no CLIENT_SECRET
- **Next:** DART-024 profile fetch + inventory sync algorithm

### DART-022 note (completed)

- **Package:** `packages/bungie` OAuth modules — `BungieOAuthClient`, PKCE S256, CSRF state, `BungieTokens`, `PlatformRedirectUriConfig`
- **Exit:** No `client_secret` fields; authorize/token/refresh with public client_id + PKCE; unit tests mocked HTTP only
- **Next:** DART-023 Windows host loopback/deep-link + secure token storage

### DART-021 note (completed)

Shared `packages/bungie` (`destiny2_bungie`): `BungieHttpClient` with host-injected public `X-API-Key`, optional Bearer, envelope unwrap (`ErrorCode == 1`), typed HTTP/platform/parse errors, and `onRateLimit` hooks (429 / `ThrottleSeconds` / throttle ErrorCode). Unit tests use injectable mock transport only; no `CLIENT_SECRET` in package.

### DART-020 note (completed) — **P1 phase gate**

Offline catalog facets + browse: pure `filterCatalogClient` / `FacetFilter` in `packages/manifest/src/catalog/`; `OfflineCatalog` projects MVP entity stores (no inventory); Flutter host Catalog page + nav rail Catalog|Settings. Tests: `dart test packages/manifest` (57); `flutter test` apps/windows_host (9). **P1 complete** (Drift + entities + offline catalog).

### DART-019 note (completed)

Flutter Windows host `apps/windows_host` (`destiny2_windows_host`): `HostBootstrap` opens StorageRoot (path_provider app-support) + **single** Drift `AppDatabase`; Settings stub shows manifest status only via DART-018 `WindowsManifestRefresh`. No OAuth. Tests: `flutter test` (5); smoke `flutter build windows --debug`.

### DART-018 note (completed)

Settings-level `WindowsManifestRefresh` (`status` / `isStale` / `refresh`) + `BungieManifestService` partial/full download under StorageRoot; MVP entity rebuild via `Isolate.run`. Injectable HTTP; no CLIENT_SECRET.

### DART-017 note (completed)

Entity store package `destiny2_manifest`: offline read of fixture entity JSON under StorageRoot; MVP extractors (weapons, exotic-armor, aspects, fragments, abilities, mods); item/perk resolve; hard-constraint adapters for subclass kit + mod energy. Tests: `dart test packages/manifest` (20).

### DART-016 note (completed)

**Inventory repositories** in `packages/db`: `replaceInventoryBatch` (delete-all + batch insert + `inventory_sync_meta` bump + `users.last_sync_at` in one transaction), composite unique `(user_id, instance_id)`, query helpers (list/bucket/hashes/instance ids/tags), `InventoryBusyLock` / `replaceInventoryBatchExclusive` busy lock hook. Tests: `dart test packages/db` (43). Bungie profile sync deferred to DART-024.

### DART-015 note (completed)

**Library repositories** in `packages/db` (`src/repos/`): builds (tags + synergy types), sets (tags + attachment refs), set items (persist upsert/soft-remove), synergies (+ links), variants (+ replace attachments). `deleteSetRecord` throws `SetInUseException` when attached; schema ON DELETE RESTRICT remains backstop. Round-trip + RESTRICT + user-scope tests: `dart test packages/db` (33). Inventory repos deferred to DART-016.

### DART-014 note (completed)

**Drift migrations** in `packages/db`: schemaVersion remains **1** (create-all current). Documented ensure step catalog (`migration_version_table.dart` / `specs/dart-014-drift-migrations/data-model.md`) mirrors product `ensure*` from `src/lib/db/client.ts`. `applyEnsureUpgrades` runs on `beforeOpen` (idempotent ADD COLUMN / build_synergy_types create / builds identity rebuild). Empty→current + partial fixture tests: `dart test packages/db` (23). Import UX deferred to DART-048.

### DART-013 note (completed)

**Drift schema** package `packages/db` (`destiny2_db`): tables for users, inventory_items, inventory_sync_meta, loadouts, sets/set_items/set_tags, synergies/synergy_links, builds/build_variants/build_tags/build_synergy_types, variant_set_attachments. schemaVersion **1** create-all; `foreign_keys = ON`; critical uniques + product index names; set-delete **RESTRICT** on attachments. Factories: `AppDatabase.memory()`, `AppDatabase.file(path)`. Tests: `dart test packages/db` (12). PRAGMA/index notes in `schema_notes.dart` + `specs/dart-013-drift-schema/data-model.md`. Migrations history deferred to DART-014.

### DART-012 note (completed)

**StorageRoot** package `packages/storage` (`destiny2_storage`): app-support layout paths for `app.db`, `manifest/`, `entities/`, `users/`, `current-version.json` — **not** repo `.cache`. Hosts inject path_provider `getApplicationSupportDirectory().path` via `StorageRoot.windowsAppSupport`. Unit tests: fake base path + temp `ensureLayout` (`dart test packages/storage`, 11 tests). Pure packages unchanged; P0 gate still green.

### DART-011 note (completed)

**P0 phase gate closed.** Single command `dart run tool/p0_parity_gate.dart` (or `dart run melos run p0-gate`) runs pure-package graph guard then full pure suite (`packages/domain` + `packages/sandbox_data`). Graph guard forbids Flutter/Jaspr/Drift/http/path_provider (and related) runtime deps on pure packages; unit tests under `tool/test/`. Melos scripts `test` / `graph-guard` / `p0-gate` are non-interactive root runs (no nested Melos on PATH). P1 may start.

### DART-010 note (completed)

Pure `buildVariantDimLoadout` + Dim loadout DTOs/constants in `packages/domain`; `buildJsonOnlyDimExport` calls `assertEquipReady` then returns `{ loadout }` with fixed-id golden parity vs TS variant fixture. No network / dim.gg / collectVariantMods.

### DART-009 note (completed)

- Pure constants package `packages/sandbox_data` (`destiny2_sandbox_data`): stat benefits, synergy verbs/elements, exotic ability requirements, armor archetypes, champion counters, activity artifact gate, ability timings, weapon types, concept tags, subclasses-by-class.
- Update process: `docs/sandbox-data-update-process.md`.
- Golden tests: `dart test packages/sandbox_data` (25 tests). Soft-only package; no IO/UI.

### DART-008 note (completed)

Pure optimizer core merged: `enumerateKits` / `prunePiecesForSlot` / score helpers + kit constraints in `packages/domain`; truncation flags; golden tests; no Flutter isolate.

### DART-007 note (completed)

Merged pure `evaluateFinishGaps` + next-slot helpers (`finish_gaps.dart`, `finish_next_slot.dart`) into `packages/domain`. Golden tests cover TS finishGaps/finishNextSlot parity and default vs non-default gap list stability (`isDefaultVariant` echo-only). Soft never auto-applies; `hasModCoverage` is explicit input.

### DART-006 note (completed)

Merged pure `computeEquipReady` / wishlist vs owned-pin / stale pin gates into `packages/domain` with golden tests vs TS `equipReady.test.ts` (plus hash_mismatch). Wishlist never equip-ready; post-sync stale covered.

### Residual package note — `pkg-default-three-gates` (closed 2026-08-03)

Post-DART-068 residual package (not a new DART-NNN). Ports Next Phase B/C default three-gate save into Dart:

- `collectSubclassKitCompleteGaps` / `collectArtifactCompleteGaps` + extended `assertFullCombatLoadout` (kit bar Super/melee/grenade + aspects/fragments at capacity; artifact hash + non-empty config)
- `synergy_links.required` Drift + `assertRequiredLinksSatisfied` (equip-ready pins only; wishlist never; artifact_perk via applied config)
- Default-only hard gate-2; non-default soft-warn only; host three-gate chips + required toggle (Windows+Jaspr)
- Residual closed by `pkg-variant-subclass-kit` (2026-08-03): kit from `build_variants.subclass_kit` + effective merge (tree/pin Super on Build)
- Residual: APPLIED_KIT kinds beyond `artifact_perk` until `pkg-synergy-kinds-v1`

### Residual package note — `pkg-variant-subclass-kit` (closed 2026-08-03)

Post-DART-068 residual package (not a new DART-NNN). Per-variant subclass kit ownership (DBR-SUB-001/003, DBR-CMPL-001c, DBR-ID-008a/b/010):

- Domain `mergeEffectiveSubclassKit` (variant pieces + build tree + pinned Super; no exotic auto-pin)
- Drift `build_variants.subclass_kit` + ensure heal from legacy `builds.subclass`; tree-only writes on Build
- Identity detector keys only on tree name; kit saves via `updateUserVariant` without Confirm/Fork
- Gate-1 / coverage / three-gate / validateVariantSave read **active variant** effective kit
- Hosts (Windows + Jaspr): load/save kit on active variant; switch-variant reloads kit

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
- [ ] **PROC-06:** if intentional thinning, complete [finish-spec-thinning-checklist.md](./finish-spec-thinning-checklist.md) + GAP residual in same change (`dart run tool/proc06_thinning_gate.dart`)  
- [ ] Soft never auto-applies; no CLIENT_SECRET

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
