# Feature Specification: DART-017 Manifest Entities

**Feature Branch**: `dart-017-manifest-entities`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Entity store reader + extractor port for MVP stores (weapons, armor, subclass pieces, mods). Offline read of fixture entity JSON; perk/item resolve used by hard constraints adapters."

**Program ID**: DART-017  
**Phase**: P1  
**Depends**: DART-012 (StorageRoot paths)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- New Dart package **`destiny2_manifest`** (`packages/manifest`) for:
  - **Entity store reader**: read pre-built entity store JSON from `StorageRoot.entityStorePath` / meta path (offline, pure Dart I/O)
  - **MVP extractors** projecting raw Bungie tables → entity stores: **weapons**, **exotic-armor**, **aspects**, **fragments**, **abilities**, **mods**
  - **Rebuild** of MVP stores from in-memory / file raw tables into StorageRoot entity paths (no network download — that is DART-018)
  - **Item resolve**: by hash and exact normalized name (searchName); used by hard-constraint adapters
  - **Perk resolve helpers**: weapon perk column legality + aspect fragment capacity aggregation (StorePerkValidator parity for MVP)
  - **Hard constraints adapters**: resolve fragment capacity from aspect names; resolve mod energy costs / slot legality for `evaluateModEnergy` / `evaluateSubclassKit` inputs
  - Hand-trimmed **raw table fixtures** + offline **entity JSON** fixtures for tests

**Out of scope (later slices):**

- Full/partial **manifest download / refresh** pipeline, remote version check (DART-018)
- Non-MVP extractors as first-class exit (exotic-weapons, weapon-perks, origin-traits, artifacts, set-bonuses, stats) — may exist as stubs or empty stores for schema stability, not required green
- Fuse.js-parity fuzzy search ranking (exact + simple contains fallback is enough; full Fuse later if catalog needs it)
- Ability enrichment (subclassAffinities / verbs overrides from sandbox_data) beyond empty/minimal fields
- Flutter catalog UI (DART-020)
- Bungie HTTP (DART-021+), OAuth, inventory sync
- Node sidecar / CLIENT_SECRET (forbidden)
- Soft guidance auto-apply (forbidden)

### Assumptions

- **A1**: Package depends on `destiny2_storage` for path layout and `destiny2_domain` for pure hard evaluators used by adapters.
- **A2**: Entity JSON on disk matches product shapes in `src/lib/manifest/types/records.ts` for MVP stores (camelCase JSON field names).
- **A3**: Offline tests inject a temp `StorageRoot` base path; no real AppData or network.
- **A4**: `rebuild` for this slice only runs **MVP extractors**; other product store names may be written as empty arrays so meta counts stay complete if needed, or omitted — document choice in research (prefer writing only MVP stores + meta listing those counts).
- **A5**: Hard constraints adapters return pure evaluation results / typed errors — they do not throw HTTP `ApiError` (no Next server).
- **A6**: Soft guidance never auto-applies; adapters only feed hard evaluators.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Offline read of entity store JSON (Priority: P1)

As a multiplatform data layer, I can open a versioned entity cache under StorageRoot and read MVP stores (weapons, exotic-armor, aspects, fragments, abilities, mods) from fixture JSON without network so hard constraints and catalog can work offline.

**Why this priority**: Roadmap exit — “Offline read of fixture entity JSON.”

**Independent Test**: Write fixture entity JSON under temp StorageRoot; `getStore` / `getMeta` return parsed records; missing store throws clear error; memoization returns same list.

**Acceptance Scenarios**:

1. **Given** fixture `entities/<ver>/aspects.json` and `meta.json`, **When** cache is constructed for that version, **Then** `getMeta` returns manifestVersion and counts, and `getStore('aspects')` returns records with hash/name/fragmentCapacity.
2. **Given** no version set, **When** `getStore` is called, **Then** a typed/clear error indicates rebuild or version is required.
3. **Given** a store file missing, **When** `getStore` is called, **Then** a clear error names the store and path.

---

### User Story 2 - MVP extractors from raw tables (Priority: P1)

As a port engineer, I can run MVP extractors against hand-trimmed raw table fixtures and obtain entity records that match product field projections for weapons, exotic armor, subclass pieces (aspects/fragments/abilities), and mods.

**Why this priority**: Roadmap goal — “extractor port for MVP stores.”

**Independent Test**: In-memory raw tables (no disk) → each MVP extractor returns expected fixture counts and key field values (parity with TS extractor tests where applicable).

**Acceptance Scenarios**:

1. **Given** raw fixtures, **When** exotic-armor extractor runs, **Then** Celestial Nighthawk-shaped record (hash, class, slot, intrinsic).
2. **Given** raw fixtures, **When** weapons extractor runs, **Then** legendary weapon with perk columns.
3. **Given** raw fixtures, **When** aspects/fragments/abilities/mods extractors run, **Then** expected counts and energyCost / fragmentCapacity fields.

---

### User Story 3 - Rebuild writes entity stores under StorageRoot (Priority: P1)

As a host preparing offline data, I can rebuild MVP entity stores from a raw-table loader into `StorageRoot` entity paths and then read them back via the entity cache.

**Why this priority**: Connects extractors + reader without DART-018 network.

**Independent Test**: Temp StorageRoot → rebuild(version) → getStore round-trip matches extractor output lengths.

**Acceptance Scenarios**:

1. **Given** raw loader + empty entity dir, **When** rebuild, **Then** meta.json and each MVP store JSON exist; counts match store lengths.
2. **Given** rebuild completed, **When** new cache opens that version, **Then** offline read works without re-extract.

---

### User Story 4 - Perk/item resolve for hard constraints adapters (Priority: P1)

As a save/validate pipeline, I can resolve items by name/hash and feed pure hard evaluators: fragment capacity from aspects, mod energy pieces from mod hashes, weapon perk legality from weapon perk columns.

**Why this priority**: Roadmap exit — “perk/item resolve used by hard constraints adapters.”

**Independent Test**: Entity cache from fixtures → adapters produce `ConstraintEvaluation` hard blocks when capacity/energy exceeded; legal kits empty hard blocks; weapon perk check legal/illegal.

**Acceptance Scenarios**:

1. **Given** aspects Touch of Thunder (cap 4) + Consecration (cap 2), **When** resolveFragmentCapacity + evaluateSubclassKit with 7 fragments, **Then** hard block illegal subclass kit.
2. **Given** mods with energy costs on a piece totaling over capacity, **When** assert/evaluate mod energy adapter, **Then** hard block mod energy exceeded.
3. **Given** weapon with perk Kill Clip in column, **When** checkWeaponPerk, **Then** legal with column; unknown perk illegal.
4. **Given** exact name “Celestial Nighthawk”, **When** resolve exotic-armor, **Then** confidence 1 match.

---

### Edge Cases

- Empty aspect list → fragment capacity 0; capacityResolved true when no aspects.
- Unknown aspect name → not counted in capacity; capacityResolved false when any aspect fails to resolve.
- Missing mod hash → skip cost (no invent); illegal slot category still reported when mod found.
- Redacted / empty-name raw items skipped by extractors.
- Soft warnings never auto-apply kit mutations.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST expose entity cache APIs: `getMeta`, `getStore`, `rebuild` for MVP stores under StorageRoot.
- **FR-002**: Package MUST implement MVP extractors: weapons, exotic-armor, aspects, fragments, abilities, mods.
- **FR-003**: Offline tests MUST read fixture entity JSON without network.
- **FR-004**: Package MUST expose item resolve by exact normalized name and by hash for MVP stores.
- **FR-005**: Package MUST expose perk validator helpers: weapon perk legality + fragment capacity from aspect hashes/names.
- **FR-006**: Package MUST expose hard-constraint adapters that load entity data and call `destiny2_domain` pure evaluators (`evaluateSubclassKit`, `evaluateModEnergy`).
- **FR-007**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; no Flutter/Jaspr UI.
- **FR-008**: Soft guidance never auto-applies.
- **FR-009**: Domain package remains free of IO; manifest package is not pure (may use dart:io + path + destiny2_storage).

### Key Entities

- **EntityRecord** / store-specific records (Weapon, ExoticArmor, Aspect, Fragment, Ability, Mod)
- **EntityCacheMeta**: manifestVersion, builtAt, counts
- **EntityCache**: reader + rebuild
- **ItemResolver**: resolve / getByHash
- **PerkValidator**: checkWeaponPerk, checkFragmentCount
- **HardConstraintsAdapters**: subclass kit + mod energy resolution

## Success Criteria *(mandatory)*

### Measurable Outcomes

- `dart test packages/manifest` green with offline fixture coverage for read, extract, rebuild, resolve, adapters.
- MVP store extractors produce non-empty fixture results for all six MVP stores.
- Hard constraint adapters produce hard blocks for illegal fragment capacity and mod energy; legal configs do not.
- Workspace lists `packages/manifest`; README documents package role.
- No product branch merge; finish merges to `feature/multiplatform-dart` only.
