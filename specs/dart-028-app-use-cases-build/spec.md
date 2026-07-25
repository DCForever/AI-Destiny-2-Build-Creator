# Feature Specification: DART-028 App Use Cases Build

**Feature Branch**: `dart-028-app-use-cases-build`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Build/variant save pipeline order parity (hard gates + soft coverage query). Illegal kits hard-block; soft misses do not block non-default."

**Program ID**: DART-028  
**Phase**: P3  
**Depends**: DART-027 (app use cases library), DART-003–007 (hard/soft/resolve/equip-ready/finish pure domain)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Extend **`packages/app`** (`destiny2_app`) with **build + variant save** use cases (in-process, no HTTP / Flutter UI)
- **Hard-gate order parity** with product `buildService` / `validateVariantSave`:
  1. Build identity: ≥1 synergy designation (`NO_SYNERGY`), subclass kit legal, exotic ability match
  2. Variant equipment-affecting save: resolve claims → slot conflicts → exotic limits → mod energy → default completeness only
- **Soft coverage query** use case that evaluates pure `evaluateCoverage` and **never** hard-blocks save
- Transactional rollback when hard validation fails after provisional write (create-with-attachments / update variant equipment)
- Expand live/snapshot attachments → `ExpandedSetItem` for pure resolve (fashion excluded)
- Injectable **ports** for manifest-backed lookups (fragment capacity, exotic hash classification, mod energy pieces, exotic slots) so tests run without full entity cache
- Default ports: pure heuristics + `destiny2_sandbox_data` exotic ability table
- Unit tests with **in-memory Drift**

**Out of scope (later slices):**

- Flutter build/variant UI (DART-032 / DART-033)
- Soft guidance chips UI (DART-034)
- Equip-ready / DIM / equip orchestrator
- Identity fork UX polish beyond hard gate enforcement on update
- Full artifact selection entity resolution
- Node sidecar / CLIENT_SECRET (forbidden)

### Assumptions

- **A1**: Soft coverage is **query-only**; it is never invoked inside `validateVariantSave` and never mutates kit/pins/targets.
- **A2**: Create build with **empty default variant** is allowed (product staged pipeline). Hard equipment gates run only when equipment-affecting fields/attachments are present on save.
- **A3**: Non-default variants are **not** required to be full combat loadouts; soft coverage misses do **not** block their save (exit criteria).
- **A4**: Manifest-dependent inputs use injectable ports; default ports skip unknown capacities (`capacityResolved: false`), classify exotics via claim source/slot + optional hash sets, and skip mod energy when no piece costs are provided.
- **A5**: Exotic ability requirements default to `destiny2_sandbox_data.lookupExoticAbilityRequirements` (may be empty curated list; tests inject custom lookup when needed).
- **A6**: Soft suggestions never auto-apply; hard DBR blocks stay hard.
- **A7**: No HTTP; Flutter hosts call these use cases in-process later.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create / update build with hard identity gates (Priority: P1)

As a compose host, I can create and update builds with class, subclass, exotic pins, and synergy designations; illegal kits and missing synergies hard-block.

**Why this priority**: Identity gates are the first step of product save pipeline order.

**Independent Test**: In-memory DB; create with zero synergies fails; create with ≥1 synergy + legal subclass succeeds; illegal aspect count fails.

**Acceptance Scenarios**:

1. **Given** a user, **When** I create a build with no synergy types, **Then** hard-block `NO_SYNERGY` and no row is written.
2. **Given** ≥1 synergy designation and legal subclass, **When** I create a build, **Then** build + default empty variant are persisted.
3. **Given** subclass with more than max aspects, **When** I create/update, **Then** `ILLEGAL_SUBCLASS_KIT` hard-blocks and state is unchanged.
4. **Given** exotic armor with ability requirements (injected lookup) and mismatched kit, **When** I create, **Then** `EXOTIC_ABILITY_MISMATCH` hard-blocks.

---

### User Story 2 - Variant equipment save hard gates + rollback (Priority: P1)

As a compose host, I can update a variant’s attachments / exotic weapon; illegal equipment hard-blocks and prior state is restored.

**Why this priority**: Core exit criteria — illegal kits hard-block.

**Independent Test**: Seed build + sets; attach conflicting slots → fail with `SLOT_CONFLICT` and attachments unchanged; dual exotic composition → `TOO_MANY_EXOTICS`.

**Acceptance Scenarios**:

1. **Given** a non-default variant with empty equipment, **When** I save non-equipment fields only, **Then** save succeeds (no full-combat requirement).
2. **Given** two sets claiming the same slot, **When** I attach them and validate save, **Then** hard-block `SLOT_CONFLICT` and attachments roll back.
3. **Given** exotic composition with two armor exotics (classifier / claims), **When** validate save runs, **Then** hard-block `TOO_MANY_EXOTICS`.
4. **Given** a default variant with partial attachments insufficient for full combat, **When** equipment-affecting save runs, **Then** hard-block `DEFAULT_VARIANT_INCOMPLETE`.
5. **Given** a non-default variant with partial attachments, **When** equipment-affecting save runs, **Then** save succeeds (completeness soft for non-default).

---

### User Story 3 - Soft coverage query never blocks save (Priority: P1)

As a compose host, I can query soft synergy coverage for a variant; missing/weak coverage is returned for display and does not block save of default or non-default variants.

**Why this priority**: Exit criteria — soft misses do not block non-default (and soft never hard-blocks any save).

**Independent Test**: Build with designated synergy + unmatched evidence links; queryCoverage returns `missing`/`weak`; updateUserVariant still succeeds.

**Acceptance Scenarios**:

1. **Given** a variant with claims that miss synergy links, **When** I query coverage, **Then** tiers are missing/weak and no exception is thrown.
2. **Given** soft coverage is missing, **When** I save a non-default variant with legal equipment, **Then** save succeeds.
3. **Given** soft coverage is missing, **When** I save build identity softStatTargets only, **Then** save succeeds (soft targets never hard-block).
4. **Given** coverage query, **When** no auto-apply path is called, **Then** kit/attachments/soft targets are unchanged.

---

### Edge Cases

- Missing build/variant returns null (not crash).
- Empty name after trim fails validation (`INVALID_ARGUMENT`).
- Fashion attachments expand to zero combat claims.
- Soft-removed set items are excluded from live expansion.
- Create with defaultVariant attachments that fail hard gates deletes the provisional build (R2 parity).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST expose create/list/get/update/delete build use cases scoped by `userId`.
- **FR-002**: Create/update build MUST hard-block when synergy designations are empty (`NO_SYNERGY`).
- **FR-003**: Create/update build MUST hard-block illegal subclass kits via pure `evaluateSubclassKit` (+ capacity port).
- **FR-004**: Create/update build MUST hard-block exotic ability mismatch via pure `evaluateExoticAbilityMatch` (+ ability requirements port).
- **FR-005**: Package MUST expose variant create/update/delete and `validateVariantSave` orchestration.
- **FR-006**: Equipment-affecting variant saves MUST resolve claims, assert slot conflicts, exotic limits, mod energy (when pieces provided), and default completeness only for `isDefault`.
- **FR-007**: Failed hard validation after provisional write MUST restore prior attachments/variant fields (or delete provisional build on create-with-attachments).
- **FR-008**: Soft coverage query MUST use pure `evaluateCoverage` and MUST NOT be part of save hard-gate path.
- **FR-009**: Soft coverage misses/weak tiers MUST NOT throw or block variant save.
- **FR-010**: Soft suggestions MUST NOT auto-apply kit/pins/targets.
- **FR-011**: Use cases MUST NOT use HTTP, Flutter, Jaspr, CLIENT_SECRET, or Node sidecar.
- **FR-012**: Tests MUST use in-memory Drift and cover US1–US3 acceptance scenarios.

### Key Entities

- **CreateBuildCommand / UpdateBuildCommand** — identity + default variant seed
- **CreateVariantCommand / UpdateVariantCommand** — variant fields + optional attachments
- **BuildDetail** — build + variants (+ optional attachments map)
- **HardGateContext** — injectable ports for capacity / exotic / mod / slots / ability requirements
- **CoverageQueryResult** — soft-only envelope
- Domain: `ConstraintEvaluation`, `CoverageResult`, `ResolvedVariantEquipment`, failure codes

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/app` green including build/variant/coverage suites.
- **SC-002**: Specs under `specs/dart-028-app-use-cases-build/`; branch merges to `feature/multiplatform-dart` only.
- **SC-003**: Illegal kits hard-block; soft misses do not block non-default (exit criteria).
- **SC-004**: Soft never auto-applies; pure domain package stays free of app/db deps.
