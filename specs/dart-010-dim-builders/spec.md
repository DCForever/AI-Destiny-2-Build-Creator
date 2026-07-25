# Feature Specification: DART-010 DIM Builders

**Feature Branch**: `dart-010-dim-builders`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Pure DIM loadout JSON builders + equipReady gate call (no network). jsonOnly payload matches TS golden for one fixture variant."

**Program ID**: DART-010  
**Phase**: P0  
**Depends**: DART-006 (equipReady assert)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure DIM Sync loadout document builders in `packages/domain` that mirror TypeScript:

- `src/lib/dim/dimLoadout.ts` — types, class/stat hash constants, shared shapes
- `src/lib/dim/buildVariantDimLoadout.ts` — variant → `DimLoadout` (primary product path for jsonOnly export)
- Pure **equipReady gate call** before emitting a jsonOnly-shaped payload (`assertEquipReady` reuse from DART-006)
- Deterministic `toJson` map for `{ loadout: … }` jsonOnly envelope (no network / no dim.gg)

**Out of scope (later slices):**

- Network dim.gg share / `DimSyncClient` (DART-039 / product share path)
- `collectVariantMods` DB I/O (callers pass `modHashes`)
- Inventory sync, equip orchestrator (DART-037), Flutter/Jaspr UI
- Legacy LLM sheet `buildDimLoadout(ResolvedBuildSheet)` (optional deferred; not required for exit)
- Wishlist file text builders (`buildWishlist`)
- Soft guidance auto-apply; hard DBR blocks stay hard via existing evaluators only

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Variant → DimLoadout JSON (Priority: P1)

As a multiplatform domain engineer, I can map a resolved variant (combat pins, fashion, mods, soft stats, subclass/artifact notes) into a pure `DimLoadout` document whose JSON shape matches the product DIM export contract so hosts can clipboard-export without a Node sidecar.

**Why this priority**: Roadmap exit criterion — jsonOnly payload parity for one fixture variant.

**Independent Test**: Golden fixture mirrors `buildVariantDimLoadout.test.ts` “maps combat pins to equipped with instance ids” and serializes to a stable jsonOnly envelope (fixed loadout id).

**Acceptance Scenarios**:

1. **Given** combat pins with `itemHash` + `instanceId` on primary and helmet and `modHashes: [9001]`, **When** `buildVariantDimLoadout` runs for Titan, **Then** `classType` is 0, name contains the build name, `equipped` is `[{hash:111,id:"inst-1"},{hash:222,id:"inst-2"}]`, and `parameters.mods` is `[9001]`.
2. **Given** fashion with a ghost piece, **When** built, **Then** that hash appears in `unequipped`; empty fashion slots yield empty `unequipped`.
3. **Given** subclass + artifact inputs, **When** built, **Then** `notes` encode subclass and artifact unlock lines (truncated to 1024).
4. **Given** soft stat targets Weapons=100 Health=70, **When** built, **Then** `parameters.statConstraints` match DIM stat hashes sorted by descending minStat.
5. **Given** a fixed loadout id, **When** `toJson` / jsonOnly envelope is produced, **Then** the payload matches the TS golden structure for that fixture (excluding only fields the TS generator randomizes unless fixed).

---

### User Story 2 - equipReady gate before jsonOnly (Priority: P1)

As an engineer, I can call a pure helper that asserts equip-ready (DART-006) and only then returns `{ loadout }` so non-ready variants cannot produce an allowed jsonOnly export payload in domain (product 409 `NOT_EQUIP_READY` parity at the pure layer).

**Why this priority**: Slice goal explicitly includes equipReady gate call; DIM export must not bypass ownership pins.

**Independent Test**: Ready inventory + pinned claims → payload returned; wishlist claim → throws `NOT_EQUIP_READY`.

**Acceptance Scenarios**:

1. **Given** equip-ready true for the fixture equipment and a valid loadout input, **When** `buildJsonOnlyDimExport` (or equivalent) runs, **Then** it returns a map/object with key `loadout` and does not throw.
2. **Given** wishlist-only applied combat pins (not equip-ready), **When** the gated builder runs, **Then** it throws with code `NOT_EQUIP_READY` and does not return a loadout.
3. **Given** the gate, **When** success path runs, **Then** it uses the same `assertEquipReady` semantics as DART-006 (no network).

---

### User Story 3 - Constants and socket / exotic parameter parity (Priority: P2)

As an engineer, I can rely on DIM class type and Armor 3.0 stat hash constants and optional socket overrides / exotic armor hash from `build_exotic_armor` claims matching TS builders.

**Why this priority**: Supporting parity for full DimLoadout parameters; not the single exit golden but needed for correct documents.

**Independent Test**: Class type map Titan=0 Hunter=1 Warlock=2; stat hash map; socketOverrides from selectedPerks indices; exoticArmorHash from build_exotic_armor source.

**Acceptance Scenarios**:

1. **Given** GuardianClass Titan/Hunter/Warlock, **When** mapped, **Then** classType is 0/1/2.
2. **Given** a claim with `selectedPerks: [p0, p1]`, **When** built, **Then** equipped item has `socketOverrides` `{0: p0, 1: p1}`.
3. **Given** a combat claim with `source == build_exotic_armor`, **When** built, **Then** `parameters.exoticArmorHash` equals that claim’s itemHash.
4. **Given** always, **When** parameters built, **Then** `autoStatMods` and `includeRuntimeStatBenefits` are true.

---

### Edge Cases

- Missing `instanceId` on a claim → equipped item is hash-only (no `id` field); gate still fails if not equip-ready.
- Empty equipment map → empty equipped; gate fails (zero applied pins not ready).
- Null/empty fashion → empty unequipped.
- Null soft stats / empty modHashes → omit `statConstraints` / `mods` keys (or leave absent), matching TS.
- Name truncated to 120 chars; notes to 1024.
- Domain package remains zero IO/UI runtime dependencies.
- Soft guidance never auto-applies; this slice only maps soft **targets** into DIM constraints as display/export data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export pure DIM loadout types: item, stat constraint, parameters, loadout document.
- **FR-002**: Domain MUST export `DIM_CLASS_TYPE` / `DIM_STAT_HASHES` (or Dart equivalents) matching TS hashes.
- **FR-003**: Domain MUST export pure `buildVariantDimLoadout` accepting pre-resolved equipment, fashion, artifact, modHashes, softStatTargets, subclass note inputs (no DB).
- **FR-004**: Equipped items MUST walk combat slots in product order; include instance id and socketOverrides when present.
- **FR-005**: Unequipped MUST list fashion piece hashes only.
- **FR-006**: Parameters MUST set autoStatMods + includeRuntimeStatBenefits true; mods, statConstraints, exoticArmorHash when applicable.
- **FR-007**: Domain MUST export a pure jsonOnly path that calls `assertEquipReady` then returns `{ loadout }` (typed or Map with toJson).
- **FR-008**: Golden unit tests MUST cover the primary TS fixture (equipped pins + mods) and gated success/failure.
- **FR-009**: Loadout id MUST be injectable for deterministic goldens (hosts may generate UUID).
- **FR-010**: Domain package runtime dependencies MUST remain zero IO/UI.

### Key Entities

- **DimLoadout / DimLoadoutItem / DimLoadoutParameters / DimStatConstraint**: pure export DTOs.
- **VariantDimLoadoutInput**: pure input DTO (buildName, class, equipment map, fashion, artifact, mods, soft stats, subclass).
- **ResolvedFashion / FashionPiece / ResolvedArtifact**: thin pure shapes for export (not full library models).
- **JsonOnlyDimExport**: `{ loadout }` envelope after gate.
- Reuse: `SlotClaim`, `EquipmentSlot.combatSlots`, `SoftStatTargets`, `EquipReadyResult`, `assertEquipReady`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` includes dim-builder suite green.
- **SC-002**: One fixture variant’s jsonOnly `loadout` body matches TS golden field-for-field (with fixed id).
- **SC-003**: Non-equip-ready gated path throws `NOT_EQUIP_READY`.
- **SC-004**: Domain `pubspec.yaml` runtime deps remain empty (SDK only).
- **SC-005**: Roadmap row DART-010 marked done after merge to `feature/multiplatform-dart`.

## Assumptions

- Callers supply resolved equipment, fashion, artifact, and mod hashes; no `collectVariantMods` in domain.
- Network dim.gg share is out of scope; only the pure document + gate.
- Subclass note uses optional `name` / `super` strings (same loose shape as TS `unknown` extractor).
- Fashion slot key order for unequipped follows map iteration of provided pieces (tests use single-piece fashion).
- Soft targets export is not a hard block; equip-ready remains ownership-only.
- Legacy LLM `buildDimLoadout(sheet)` is **not** required for this slice’s exit criterion.
