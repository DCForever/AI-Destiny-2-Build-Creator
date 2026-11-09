# Feature Specification: DART-002 Models

**Feature Branch**: `dart-002-models`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Pure DTOs / freezed (or equivalent) models for pins, claims, kits, coverage results, failure codes. Models package has zero IO; maps core build/variant/set/synergy shapes used by evaluators."

**Program ID**: DART-002  
**Phase**: P0  
**Depends**: DART-001  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure value types / DTOs in `packages/domain` (`destiny2_domain`) for:

- Equipment slots and set types
- Slot claims, resolved variant equipment, expanded set items, conflicts
- Instance pins / pin status / equip-ready result shapes
- Subclass kit and ability kit fields; exotic composition; mod energy pieces
- Hard blocks, soft warnings, constraint evaluation envelopes
- Stable hard-failure / domain failure code constants (parity with TS evaluators)
- Soft coverage results (tiers, synergy rows, set-bonus soft rows, element mismatches)
- Soft stat targets / estimate / warning row shapes
- Core build, variant, set, set-item, attachment, synergy, and synergy-link shapes used by pure evaluators

**Out of scope (later slices):** hard evaluators (DART-003), soft coverage algorithms (DART-004), resolveVariant merge logic (DART-005), equipReady logic (DART-006), finishGaps (DART-007), optimizer (DART-008), Drift/repos, Flutter/Jaspr, network/IO, JSON wire codecs for Bungie APIs.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Evaluator-ready claim and pin models (Priority: P1)

As a multiplatform domain engineer, I can construct pure slot-claim, resolved-equipment, and pin-status values without any IO so later hard/soft evaluators share one shape language.

**Why this priority**: DART-003–006 all consume claims/pins; without shared models, each slice invents incompatible types.

**Independent Test**: Unit tests construct `SlotClaim`, `ResolvedVariantEquipment`, `PinStatus`, and `EquipReadyResult` with TS-parity field names/enums and assert equality / wire names.

**Acceptance Scenarios**:

1. **Given** the domain package, **When** I construct a `SlotClaim` for slot `helmet` with item hash and source `set`, **Then** the value is immutable and exposes `slot`, `itemHash`, `itemName`, `source`, optional `setId` / `selectedPerks` / `instanceId`.
2. **Given** claims with two sources on the same slot, **When** I hold them in a conflict structure, **Then** `ResolvedVariantEquipment` can represent equipment map + conflicts list.
3. **Given** pin kinds wishlist / pinned / stale, **When** I construct `PinStatus` and `EquipReadyResult`, **Then** kinds and optional stale reasons match product semantics (no evaluation logic required).

---

### User Story 2 - Failure codes and constraint envelopes (Priority: P1)

As an engineer porting hard gates, I can reference stable failure code strings and `HardBlock` / `SoftWarning` / `ConstraintEvaluation` types that mirror the TS pure constraint layer.

**Why this priority**: Golden tests and API-facing codes must not drift; codes are the contract for hard blocks.

**Independent Test**: Constants for `TOO_MANY_EXOTICS`, `ILLEGAL_SUBCLASS_KIT`, `MOD_ENERGY_EXCEEDED`, `EXOTIC_ABILITY_MISMATCH`, `NO_SYNERGY` (and related domain codes used by pure evaluators) exist and match TS string values; envelope types construct cleanly.

**Acceptance Scenarios**:

1. **Given** domain failure code constants, **When** compared to known TS codes, **Then** the hard-gate codes used by pure evaluators are identical strings.
2. **Given** a hard block and soft warning, **When** placed in `ConstraintEvaluation`, **Then** the envelope holds both lists without implying either is auto-applied.

---

### User Story 3 - Kits, coverage, and library shapes (Priority: P2)

As an engineer, I can use subclass/ability kit DTOs, coverage result trees, and core build/variant/set/synergy shapes so soft coverage and resolve pipelines share models without DB types.

**Why this priority**: Soft coverage and resolveVariant need these shapes; build/set/synergy identity fields anchor completeness rules later.

**Independent Test**: Construct `SubclassKit`, `CoverageResult`, `Build`, `Variant`, `GearSet`, `Synergy` (+ links/designations) in unit tests; assert key fields and nested lists.

**Acceptance Scenarios**:

1. **Given** kit fields (aspects, fragments, super/melee/grenade/class ability), **When** constructed, **Then** they are pure value objects with no capacity evaluation.
2. **Given** a `CoverageResult` with synergy rows and soft-stat warnings, **When** inspected, **Then** soft tiers never use hard-block types.
3. **Given** build/variant/set/synergy shapes, **When** constructed with minimal required fields, **Then** they map the evaluator-facing subset of product records (not full DB rows).

---

### Edge Cases

- Null vs empty for optional pins (`instanceId` null = wishlist-capable claim shape).
- Empty equipment map is valid (incomplete variant); models do not enforce completeness.
- Soft coverage empty lists are valid (no designated synergies matched).
- Failure codes are string constants (not only enums) so golden fixtures can assert exact TS parity.
- Domain package must not gain Flutter/Jaspr/Drift/http/path_provider dependencies for these models.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `packages/domain` MUST export pure immutable (or freezed-equivalent) models for slot claims, resolved variant equipment, expanded set items, and slot conflicts.
- **FR-002**: Domain MUST export pin status kinds/statuses and equip-ready result shapes without implementing equip-ready evaluation.
- **FR-003**: Domain MUST export subclass kit, ability kit, exotic composition, and mod-energy piece shapes used by hard evaluators.
- **FR-004**: Domain MUST export `HardBlock`, `SoftWarning`, `ConstraintEvaluation`, and stable hard-failure code string constants matching TS pure evaluators for: `TOO_MANY_EXOTICS`, `ILLEGAL_SUBCLASS_KIT`, `MOD_ENERGY_EXCEEDED`, `EXOTIC_ABILITY_MISMATCH`, `NO_SYNERGY` (plus documented related domain codes used by claim/resolve gates if included).
- **FR-005**: Domain MUST export soft coverage result types: coverage tier, synergy coverage rows, set-bonus soft rows, element soft mismatches, and aggregate `CoverageResult` (including soft-stat warning / estimate hooks as pure shapes).
- **FR-006**: Domain MUST export core build, variant, set, set-item, attachment, synergy, synergy-link, and synergy-type designation shapes needed by evaluators (identity + composition fields; not repository CRUD).
- **FR-007**: Domain package runtime dependencies MUST remain zero IO/UI (SDK-only; optional pure annotation packages allowed only if they introduce no IO/UI; prefer no freezed codegen if pure Dart classes suffice).
- **FR-008**: Equipment slot and set-type values MUST use wire names compatible with TS (`class_item`, `exotic_weapon`, set types `weapon`/`armor`/`mod`/`pair`/`fashion`).
- **FR-009**: Soft guidance types MUST remain distinct from hard-block types so later slices cannot confuse soft misses with hard saves.
- **FR-010**: Unit tests MUST cover construction/equality (or wire-name parity) for the primary model groups above; existing smoke test remains green.

### Key Entities

- **SlotClaim**: One equipment claim for a slot (hash, name, source, optional set/perks/instance).
- **ResolvedVariantEquipment**: Applied equipment map + conflict list.
- **PinStatus / EquipReadyResult**: Per-slot pin state and aggregate equip-ready flag shape.
- **HardBlock / SoftWarning / ConstraintEvaluation**: Constraint outputs.
- **DomainFailureCodes**: Stable string codes.
- **CoverageResult** (+ rows): Soft coverage tree.
- **SubclassKit / AbilityKit / ExoticComposition / ModEnergyPiece**: Hard-gate inputs.
- **Build / Variant / GearSet / SetItem / Attachment / Synergy / SynergyLink / SynergyTypeDesignation**: Library shapes for evaluators.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` (or Melos test) passes including new model tests.
- **SC-002**: Domain `pubspec.yaml` has no Flutter/Jaspr/Drift/http/path_provider (or other IO/UI) runtime dependencies.
- **SC-003**: Hard failure code string constants used by pure evaluators match TS values for the five core hard-gate codes listed in FR-004.
- **SC-004**: Models for pins, claims, kits, coverage results, and failure codes are exported from the domain barrel.
- **SC-005**: No evaluator algorithm (exotic limits, mod energy, soft matching, resolve merge) is implemented in this slice.

## Assumptions

- Models live **inside** existing `packages/domain` (`destiny2_domain`) rather than a second package, matching DART-001’s “models land in domain package” intent and keeping one purity boundary. “Models package” in the roadmap means this pure package surface.
- **Freezed equivalent**: Dart 3 immutable value classes with `==`/`hashCode` (and enums with wire names) are used instead of freezed/build_runner to keep zero codegen and zero extra runtime deps. Revisit freezed only if codegen becomes necessary for large DTO trees.
- Soft-stat armor names: Health, Melee, Grenade, Super, Class, Weapons (Armor 3.0 product table).
- Guardian class names: Titan, Hunter, Warlock.
- Persistence timestamps, userId ownership, and optimizer constraint JSON blobs are optional/minimal on library shapes; full DB parity is P1 Drift slices.
- Soft suggestions never auto-apply; hard DBR blocks stay hard — models only encode shapes, not apply policy.
