# Feature Specification: Wishlist Desired Rolls & Equip-Ready Pins

**Feature Branch**: `016-wishlist-equip-ready`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Implement wishlist desired rolls and equip-ready owned instance pins per domain DAC-P1-005 and DBR-ROLL-*. Variants may save with unowned desired rolls; equip and DIM export blocked until every applied slot has a pinned owned instance; stale pins when instance gone. Out of scope: Bungie equip write API, DIM export implementation, soft guidance UI, artifacts, fashion, LLM."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [domain-slice-roadmap.md](../domain-slice-roadmap.md)

**Prior slice**: [015-build-identity](../015-build-identity/spec.md) — composition completeness; wishlist/pins deferred here.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Plan and Save Wishlist Desired Rolls (Priority: P1)

A builder plans a variant using **catalog items and desired rolls** (item + plug/perk selections) that they may not own yet. Wishlist/unowned desired rolls are **allowed to save**; a desired roll stores item identity and plug selections, **not** an inventory instance id. Ownership is not required for planning or save. Verification uses debug/API tools (001 pattern).

**Why this priority**: Planning without ownership is the core wishlist path; without saveable desired rolls, builders cannot draft kits ahead of drops or farm goals.

**Independent Test**: Via debug/API, attach a catalog item + desired plugs to one or more combat slots with no matching owned instance; save the variant and confirm persistence of item + plugs as unowned/wishlist desired roll data (no instance id required). Confirm a parallel owned-item desired roll also saves.

**Acceptance Scenarios**:

1. **Given** a signed-in user composing a variant, **When** they set a combat slot to a catalog item and desired plug selections they do not own, **Then** the slot stores desired roll data (item + plugs) marked unowned/wishlist and save succeeds.
2. **Given** a variant with one or more wishlist desired rolls and no instance pins, **When** the user saves, **Then** save is allowed (wishlist/unowned desired rolls do not block save).
3. **Given** a desired roll on a slot, **When** it is persisted, **Then** it is stored as item identity + plug selections (including origin trait / masterwork / crafted-enhanced plugs as applicable), not as an inventory instance id.
4. **Given** the default variant still subject to full combat loadout composition (015), **When** the user fills all required combat slots with catalog/wishlist desired rolls (no pins), **Then** composition completeness can pass while ownership/equip-readiness remains separate.

---

### User Story 2 - Pin Owned Instances for Equip-Ready Status (Priority: P1)

A builder pins a **specific owned inventory instance** to each **applied combat slot**. A variant is **equip-ready** only when every applied combat slot has a pinned owned instance. Desired rolls remain the planning target; pins are the ownership layer on top of 015 composition. Soft guidance, fashion, and actual equip/DIM execution are out of scope.

**Why this priority**: Equip-ready is the measurable bridge from wishlist planning to later equip/export; without pins and status, the gate in US3 has nothing to evaluate.

**Independent Test**: On a composition-complete variant, pin a valid owned instance on every applied combat slot and confirm equip-ready status; leave one applied slot unpinned (or wishlist-only) and confirm not equip-ready. Verifiable via debug/API status fields only.

**Acceptance Scenarios**:

1. **Given** an applied combat slot with a desired roll and a matching owned inventory instance, **When** the user pins that instance to the slot, **Then** the pin is stored against that slot and the desired roll data is retained.
2. **Given** a variant where every applied combat slot has a pinned owned inventory instance, **When** equip-ready status is evaluated, **Then** the variant is reported as equip-ready.
3. **Given** a variant with at least one applied combat slot that has a desired roll but no pinned owned instance, **When** equip-ready status is evaluated, **Then** the variant is not equip-ready and the unpinned applied slot(s) are identifiable.
4. **Given** a non-default variant with some empty combat slots (allowed by 015), **When** equip-ready is evaluated, **Then** only **applied** combat slots require pins; empty/unapplied slots do not prevent equip-ready for the slots being applied.

---

### User Story 3 - Gate In-Game Equip and DIM Export Until Equip-Ready (Priority: P1)

In-game equip and DIM export are **blocked** until the variant is equip-ready. This slice implements **gate and status only**—not Bungie write equip, transfers, inventory refresh-on-equip, or DIM export payload generation. Callers (debug/API) can query readiness and receive a clear blocked outcome when attempting equip/export entry points.

**Why this priority**: Domain rule is that wishlist-only kits must not be treated as equippable/exportable; shipping the gate now prevents premature equip/DIM work from ignoring ownership.

**Independent Test**: For a wishlist-only (not equip-ready) variant, invoke equip and DIM-export gate checks and confirm both are blocked with a clear not-equip-ready reason; for an equip-ready pinned variant, confirm the gate allows (status ready) without performing real equip or DIM export.

**Acceptance Scenarios**:

1. **Given** a saved variant that is not equip-ready (missing pins and/or wishlist-only applied slots), **When** the user attempts in-game equip (gate check), **Then** equip is blocked and the response names that applied slots lack owned instance pins / equip-ready status.
2. **Given** the same not-equip-ready variant, **When** the user attempts DIM export (gate check), **Then** export is blocked for the same equip-ready requirement.
3. **Given** an equip-ready variant (every applied combat slot pinned to an owned instance), **When** equip and DIM-export gate checks run, **Then** both report allowed/ready; this slice does **not** execute Bungie equip or produce a DIM export file.
4. **Given** gate evaluation in debug/API tools, **When** a tester inspects a blocked vs ready variant, **Then** they can confirm readiness and blocked reasons without production UI, soft guidance, fashion, or LLM features.

---

### User Story 4 - Mark Stale Pins When Owned Instances Disappear (Priority: P2)

After inventory sync (or equivalent ownership refresh), if a **pinned instance no longer exists** in the user’s inventory, the system marks that pin **stale**, **keeps** the item + desired roll, and **blocks** equip (and DIM export gate) until the user re-pins a current owned instance.

**Why this priority**: Stale pins are the failure mode after wishlist→pin flows ship; without stale handling, equip-ready would lie after dismantle/transfer-out/sync drift.

**Independent Test**: Pin an owned instance, remove it from synced inventory (or simulate disappearance), re-evaluate; confirm stale pin flag, desired roll retained, not equip-ready / equip gated; re-pin a valid owned instance and confirm stale cleared and equip-ready restored when all applied slots are validly pinned.

**Acceptance Scenarios**:

1. **Given** a variant with a pinned owned instance on an applied slot, **When** a subsequent sync shows that instance id is gone, **Then** that slot’s pin is marked stale and the item + desired roll remain.
2. **Given** one or more stale pins on applied slots, **When** equip-ready or equip/DIM gate checks run, **Then** the variant is not equip-ready and equip/export remain blocked until re-pin.
3. **Given** a stale pin on a slot, **When** the user pins a currently owned instance to that slot, **Then** the stale state is cleared for that slot and desired roll data is preserved (updated only as the product rules for re-pin require).
4. **Given** all applied slots again have non-stale pinned owned instances, **When** status is re-evaluated, **Then** the variant is equip-ready and equip/DIM gates report ready (still without executing equip/export in this slice).

---

### Edge Cases

- Saving a composition-complete default with only wishlist desired rolls succeeds; equip-ready is false and equip/DIM gates stay blocked.
- Default variant must still satisfy 015 full combat loadout composition; wishlist/pins do not relax missing weapons, armor, subclass kit, or mods-as-part-of-build.
- Non-default variants may have empty combat slots; equip-ready considers only applied slots, not empty ones.
- A pin whose instance still exists but no longer matches the slot’s item identity is invalid for equip-ready (re-pin required); desired roll is kept.
- Partial pins (some applied slots pinned, others wishlist-only) never count as equip-ready.
- Stale pin after dismantle, vault wipe, or character transfer-out: keep desired roll; block equip until re-pin; do not auto-delete the slot’s planned item.
- Re-pinning a different owned copy of the same item clears stale and can restore equip-ready without forcing full re-entry of plug selections from scratch.
- Catalyst / deepsight / pattern progress remain display-only and must not gate save or equip-ready in this slice.
- Actual Bungie write equip, transfers, fashion-on-equip, artifact apply, DIM file/export implementation, soft guidance UI, and LLM flows are out of scope; only readiness status and block gates are in scope.
- “Pin” here means **owned-instance pin**, not composition slot override (DBR-CMP-002); naming in UI/API must keep those concepts distinct.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A user MAY save a variant (or set slot feeding a variant) with a **desired roll** (item + chosen plugs) **without** owning that item or pinning a copy.
- **FR-002**: A desired-roll (wishlist) slot MUST store **item identity and plug selections**, and MUST NOT require an owned-copy identifier.
- **FR-003**: A user MAY **pin** a specific owned copy to an applied equipment slot; the pin MUST identify that copy distinctly from other copies of the same item.
- **FR-004**: Pinning a copy MUST retain the **desired roll** associated with that slot; changing the pin MUST NOT silently clear the desired roll unless the user replaces the item.
- **FR-005**: Saving a variant MUST succeed when one or more applied slots are wishlist-only (unpinned), subject to existing composition rules for default vs non-default variants (015).
- **FR-006**: A variant is **equip-ready** only when **every applied equipment slot** has a **valid non-stale owned-copy pin**; otherwise equip and DIM export MUST be blocked (with a clear not-ready reason).
- **FR-007**: The system MUST expose, per applied slot, whether it is **wishlist**, **pinned**, or **stale-pinned**, and an overall equip-ready / not-ready status for the variant.
- **FR-008**: After inventory sync (or when readiness is evaluated against current inventory), if a pinned copy is **no longer owned**, the system MUST mark that pin **stale**, **keep** item + desired roll, and treat the variant as **not equip-ready** until the user re-pins.
- **FR-009**: A stale pin MUST remain visible as such until the user **re-pins** a currently owned copy (or clears the pin back to wishlist-only).
- **FR-010**: Re-pinning MUST only accept copies that match the slot’s **item identity** (same catalog item); the user MAY update plug selections to match the newly pinned copy.
- **FR-011**: Empty combat slots on **non-default** variants remain allowed for save; equip-ready evaluation MUST consider only **slots that are applied** (filled), not empty optional gaps.
- **FR-012**: Soft warnings (catalyst, deepsight, soft stats) MUST NOT by themselves block save or equip-ready; only missing/stale pins on applied slots block equip/export readiness.
- **FR-013**: Equip and DIM-export **gate checks** MUST share the same equip-ready definition; this feature MUST NOT implement Bungie write equip or DIM export payloads.
- **FR-014**: Composition completeness (015) and equip-ready MUST remain independent: a composition-complete default MAY be wishlist-only and not equip-ready.

### Key Entities

- **Desired Roll**: Catalog item identity + plug/perk selections; no instance id; persistable without ownership.
- **Owned Instance Pin**: Binding of an owned inventory `instanceId` to an applied combat slot.
- **Stale Pin**: Prior pin whose instance is missing after sync/evaluation; desired roll retained.
- **Equip-Ready Status**: Aggregate over applied combat slots; true only when all have non-stale pins.
- **Equip / DIM Gate**: Readiness check used by future equip/export features; blocked when not equip-ready.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In verification, 100% of save attempts that include wishlist/unowned desired rolls (item + plugs, no instance id) succeed when composition rules from 015 are otherwise satisfied.
- **SC-002**: A scripted checklist can mark a variant equip-ready only when every applied combat slot has a non-stale pinned owned instance; any missing pin or wishlist-only applied slot yields not-equip-ready in 100% of fixtures.
- **SC-003**: 100% of equip and DIM-export gate checks on not-equip-ready variants return blocked with an identifiable readiness reason; 100% of equip-ready fixtures report gate-allowed without performing real equip or DIM export in this slice.
- **SC-004**: When a pinned instance disappears from synced inventory, 100% of affected fixtures mark the pin stale, retain item + desired roll, and keep equip/DIM gated until re-pin restores non-stale pins on all applied slots.
- **SC-005**: Default-variant fixtures that fail 015 full combat loadout composition remain blocked on composition completeness even if pins are present; wishlist/pin status does not substitute for missing combat slots.
- **SC-006**: A tester can complete the wishlist → pin → equip-ready → stale → re-pin path using debug/API tools only in under 10 minutes for a single variant fixture, without production UI, soft guidance, fashion, Bungie write equip, DIM export implementation, or LLM.

## Assumptions

- Domain DBR/DAC are canonical over older feature BRs when conflicting.
- Stale detection runs when inventory is synced via existing sync paths **and/or** when equip-ready status is evaluated against current inventory (continuous realtime sync is not required).
- Set-item `instanceId` + `selectedPerks` are the starting persistence model; variant resolve/snapshots must carry pin/readiness into equip-ready evaluation (exact storage shape is a planning decision).
- “Applied slot” means a combat equipment slot with a resolved item claim; empty non-default gaps are not applied.
- Combat slots only for this slice’s equip-ready gate; fashion/artifact pin requirements wait for later slices.
- Owned-instance pin ≠ composition slot override; APIs/docs must distinguish them.
- Verification is debug/API-first (001 pattern).

## Out of Scope

- Bungie API equip, transfers, sync-on-equip orchestration
- DIM export payload/file generation
- Soft guidance / coverage UI
- Artifacts and fashion equip
- Soft stat targets UI
- LLM propose-for-confirm
- Exotic class-item intent-lock
- Continuous realtime inventory sync

## Traceability

| Spec item | Domain |
|-----------|--------|
| US1 / FR-001–002, FR-005, FR-014 | DBR-ROLL-001–003, DAC-P1-005 |
| US2 / FR-003–004, FR-006–007, FR-011 | DBR-ROLL-004–005, DAC-P1-005 |
| US3 / FR-006, FR-013 | DBR-EQP-003, DAC-P1-005 |
| US4 / FR-008–010 | DBR-ROLL-006, DAC-DST-007 |
| FR-012 | DBR-ROLL-007–008, DAC-DST-008 |
