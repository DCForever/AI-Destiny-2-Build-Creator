# Feature Specification: DART-005 Resolve Variant

**Feature Branch**: `dart-005-resolve-variant`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port pure resolveVariant merge/conflict/completeness (claims only; no DB load). Default vs non-default completeness rules tested; conflict detection parity."

**Program ID**: DART-005  
**Phase**: P0  
**Depends**: DART-002 (models)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure claim merge, conflict detection, exotic pin injection, pair-armor match, and completeness asserts in `packages/domain` that mirror TypeScript pure helpers in `src/lib/builds/resolveVariant.ts`:

- `detectSlotConflicts` / `buildEquipmentMap`
- `itemsToSlotClaims` (via existing `ExpandedSetItem.toSlotClaim` + list helper)
- `addExoticWeaponClaim` / `addExoticArmorClaim`
- `effectiveExoticWeapon` (build-shared vs variant weapon)
- `validatePairArmorMatch` (including class-item intent mode)
- `assertNoSlotConflicts` / `assertVariantNotEmpty` / `assertFullCombatLoadout`
- Pure `resolveVariantClaims` (claims-only orchestration; expanded items + slots in, no DB)

**Out of scope (later slices):** `loadExpandedAttachmentItems` / DB set expansion, equipReady (DART-006), finishGaps (DART-007), save pipeline (DART-028), UI, Drift/IO, Node sidecar, hard evaluators / soft coverage (already done).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Conflict detection & equipment map (Priority: P1)

As a multiplatform domain engineer, I can detect multi-claim slot conflicts and build a first-writer equipment map from pure claims so compose shells surface conflicts before save (DBR-CMP-006).

**Why this priority**: Conflict detection parity is an explicit roadmap exit criterion.

**Independent Test**: Unit fixtures mirror `resolveVariant.test.ts` multi-claim primary conflict; assert `SLOT_CONFLICT` on assert path; first claim wins equipment map.

**Acceptance Scenarios**:

1. **Given** two set claims on `primary`, **When** `detectSlotConflicts` runs, **Then** one conflict lists both claimants; equipment map keeps the first claim.
2. **Given** a resolved result with conflicts, **When** `assertNoSlotConflicts` runs, **Then** it throws with code `SLOT_CONFLICT`.
3. **Given** unique slots only, **When** conflicts are detected, **Then** the conflict list is empty.

---

### User Story 2 - Exotic pin injection & pair armor (Priority: P1)

As an engineer, I can inject build/variant exotic weapon and build exotic armor claims, prefer build-shared exotic weapon, and validate pair-set exotic armor match (with class-item intent skip).

**Why this priority**: Identity exotic pins and pair sets feed resolve before completeness; TS fixtures cover these.

**Independent Test**: Golden cases for add exotic claims, `effectiveExoticWeapon` preference, pair mismatch hard, intent mode allow, skip armor inject when class_item already claimed.

**Acceptance Scenarios**:

1. **Given** exotic weapon hash + slot, **When** `addExoticWeaponClaim` runs, **Then** a `variant_exotic_weapon` claim is appended.
2. **Given** build exotic armor hash + slot, **When** `addExoticArmorClaim` runs, **Then** a `build_exotic_armor` claim is appended; null hash adds nothing.
3. **Given** build-shared and variant exotic weapon hashes, **When** `effectiveExoticWeapon` runs, **Then** build hash wins and `fromBuild` is true.
4. **Given** pair exotic_armor hash ≠ build exotic armor, **When** `validatePairArmorMatch` runs, **Then** throws `PAIR_ARMOR_MISMATCH`; null build exotic or `intentMode: true` does not throw.
5. **Given** existing class_item claim and `skipIfClassItemClaimed: true`, **When** armor inject runs, **Then** claim list is unchanged.

---

### User Story 3 - Default vs non-default completeness (Priority: P1)

As an engineer, I can assert empty variants and full combat loadout only for default-variant completeness rules (DBR-CMPL-001/002).

**Why this priority**: Roadmap exit criterion — default vs non-default completeness rules tested.

**Independent Test**: `assertVariantNotEmpty` on empty map; `assertFullCombatLoadout` missing slots/class/subclass/mods → `DEFAULT_VARIANT_INCOMPLETE` with `missing` details; full map + identity + mods passes; non-default path uses only empty-check (not full combat) in orchestration helper docs/tests.

**Acceptance Scenarios**:

1. **Given** empty equipment, **When** `assertVariantNotEmpty` runs, **Then** throws `VARIANT_EMPTY`.
2. **Given** partial equipment (e.g. primary only) without full armor/weapons/class/subclass/mods, **When** `assertFullCombatLoadout` runs, **Then** throws `DEFAULT_VARIANT_INCOMPLETE` listing missing keys.
3. **Given** all weapon + armor slots filled, className present, subclass name present, `hasMods: true`, **When** `assertFullCombatLoadout` runs, **Then** it does not throw.
4. **Given** non-default completeness policy, **When** only non-empty is required, **Then** partial combat loadout is allowed (no full-combat assert).

---

### Edge Cases

- First-writer wins for equipment map when conflicts exist (assert still fails on conflicts).
- Exotic weapon inject skipped when hash or slot is null.
- Pair items without `exotic_armor` slot do not trigger pair mismatch.
- Class-item intent: `exoticArmorSlot == class_item` implies intent mode for pair validation + skip inject.
- Fashion / mod expansion stays out of pure resolve (caller filters expanded items).
- Domain package remains zero IO/UI runtime dependencies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export pure `detectSlotConflicts` and `buildEquipmentMap` with TS parity.
- **FR-002**: Domain MUST export pure `itemsToSlotClaims`, `addExoticWeaponClaim`, `addExoticArmorClaim`, and `effectiveExoticWeapon`.
- **FR-003**: Domain MUST export pure `validatePairArmorMatch` with intent-mode allow and `PAIR_ARMOR_MISMATCH` code.
- **FR-004**: Domain MUST export pure asserts `assertNoSlotConflicts`, `assertVariantNotEmpty`, `assertFullCombatLoadout` with stable codes `SLOT_CONFLICT`, `VARIANT_EMPTY`, `DEFAULT_VARIANT_INCOMPLETE`.
- **FR-005**: Domain MUST export pure `resolveVariantClaims` that merges expanded items + exotic pins into `ResolvedVariantEquipment` without DB/IO.
- **FR-006**: Default completeness MUST require full combat weapons+armor, className, subclass name, and mods flag (DBR-CMPL-001); non-default MUST allow empty combat slots beyond non-empty policy (DBR-CMPL-002).
- **FR-007**: Golden unit tests MUST cover conflict detection and default vs non-default completeness scenarios.
- **FR-008**: Domain package runtime dependencies MUST remain zero IO/UI.

### Key Entities

- **SlotClaim / ExpandedSetItem / SlotConflict / ResolvedVariantEquipment**: DART-002 models (reuse).
- **Build / Variant**: DART-002 identity + exotic pin fields for effective weapon/armor.
- **ResolveVariantException**: domain throw type with `code`, `message`, optional `details` (no HTTP).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` includes resolve-variant suite green with parity scenarios above.
- **SC-002**: Conflict detection and default incompleteness codes match product string codes.
- **SC-003**: Domain `pubspec.yaml` runtime deps remain empty (SDK only).
- **SC-004**: Roadmap row DART-005 marked done after merge to `feature/multiplatform-dart`.

## Assumptions

- Callers pass pre-expanded `ExpandedSetItem` lists (no set repository / snapshot load in domain).
- Domain throws `ResolveVariantException` instead of HTTP `ApiError`; adapters map codes later.
- `hasMods` is a caller-supplied boolean (mod set expansion not in this slice).
- Completeness for default is enforced only when callers invoke `assertFullCombatLoadout` (or a thin helper that branches on `variant.isDefault`); non-default callers use `assertVariantNotEmpty` only.
- Slot wire names reuse DART-002 `EquipmentSlot`.
