# Feature Specification: DIM Export

**Feature Branch**: `021-dim-export`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Export equip-ready variant loadout to DIM share: subclass kit, gear, mods, fashion, artifact. Block wishlist-only / unpinned variants via existing dim-export-gate. Reuse dim.gg share client where possible. Debug/API-first."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md)

**Prior slices**: [016-wishlist-equip-ready](../016-wishlist-equip-ready/spec.md) (gate), [018-artifacts-fashion](../018-artifacts-fashion/spec.md) (resolved layers), [020-bungie-equip](../020-bungie-equip/spec.md) (equip path separate)

## Clarifications

None yet — defaults from DBR-EQP-002–004 and DAC-P1-008.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gate Before Export (Priority: P1)

DIM export is allowed only when the variant is **equip-ready**. Wishlist-only or stale-pin variants are blocked with `NOT_EQUIP_READY` (same definition as 016 dim-export-gate).

**Why this priority**: Domain rule DBR-EQP-003; prevents exporting unowned kits.

**Independent Test**: Non-ready → export blocked; ready → export proceeds past gate.

**Acceptance Scenarios**:

1. **Given** a not-equip-ready variant, **When** export is requested, **Then** response is `NOT_EQUIP_READY` (409) and no DIM share is created.
2. **Given** an equip-ready variant, **When** export is requested, **Then** the gate allows and payload generation begins.

### User Story 2 - Full Variant → DIM Loadout (Priority: P1)

Export builds a **full variant loadout** for DIM: subclass kit, weapons/armor (pinned instances where available), mods, fashion (specified slots), and artifact config. Uses resolved variant + inventory pins.

**Why this priority**: DAC-P1-008 / DBR-EQP-004 core deliverable.

**Independent Test**: Fixture ready variant with artifact + fashion; export payload includes gear, mods, fashion slots, artifact; share URL or structured loadout returned.

**Acceptance Scenarios**:

1. **Given** an equip-ready variant with combat pins, **When** exported, **Then** DIM loadout equipped items include those item hashes (and instance ids when DIM schema supports them).
2. **Given** resolved artifact and fashion, **When** exported, **Then** artifact config and specified fashion slots are represented in the export payload/notes/parameters as designed.
3. **Given** soft-stat targets on the build (019), **When** exported, **Then** they MAY map to DIM stat constraints when hashes are known (soft enhancement, not blocking).

### User Story 3 - dim.gg Share (Priority: P1)

When DIM Sync is configured and the user is signed in to Bungie, export creates a **dim.gg share URL**. When DIM is not configured, API returns a clear 503 (or returns the loadout JSON only for debug)—document chosen behavior in plan.

**Why this priority**: Existing `/api/dim/share` path; builders need a usable link.

**Independent Test**: Mock DimSyncClient → shareUrl returned; missing DIM_API_KEY → 503.

**Acceptance Scenarios**:

1. **Given** DIM_API_KEY + signed-in user, **When** export succeeds, **Then** response includes `shareUrl`.
2. **Given** DIM not configured, **When** export is attempted, **Then** response is 503 with a clear configuration message (or documented JSON-only fallback).

### User Story 4 - Debug Export Action (Priority: P2)

Builds debug exposes **Export to DIM** (beyond gate check and raw resolved export) that calls the new variant export endpoint and shows share URL / payload JSON.

**Why this priority**: Debug/API-first delivery consistent with prior slices.

**Independent Test**: Tester: gate → Export to DIM → inspect shareUrl/panel.

## Edge Cases

- Empty fashion slots: omit (leave-as-is semantics; do not invent cosmetics).
- Missing artifact: omit artifact section.
- Soft-stat targets absent: omit or empty constraints.
- Existing generator-sheet `/api/dim/share` remains for ResolvedBuildSheet path; this slice adds **variant-based** export.

## Requirements *(mandatory)*

- **FR-001**: Variant DIM export MUST require equip-ready (reuse 016 assert / dim-export-gate).
- **FR-002**: Export MUST include subclass kit, combat gear, mods, fashion (specified), and artifact when present (DBR-EQP-004).
- **FR-003**: Export MUST map pinned `instanceId` into DIM items when the DIM loadout schema supports `id`.
- **FR-004**: When DIM Sync is configured, export MUST return a dim.gg `shareUrl` via existing DimSyncClient patterns.
- **FR-005**: Debug/API MUST expose the export path without production polish UI.
- **FR-006**: Generator-sheet `/api/dim/share` MUST remain available; variant export is additive.

## Success Criteria *(mandatory)*

- **SC-001**: Non-ready export blocked in automated tests with `NOT_EQUIP_READY`.
- **SC-002**: Ready export produces a DimLoadout covering gear + mods; fashion/artifact present when resolved.
- **SC-003**: Mocked DimSync share returns `shareUrl` in API tests.
- **SC-004**: Gate green with new DIM export tests.
- **SC-005**: Debug Export to DIM usable end-to-end with mocks or live sandbox.

## Assumptions

- Reuse `src/lib/dim/dimSync.ts` and extend/adapt `dimLoadout` builders for resolved variants.
- Bungie OAuth already required for dim.gg share today.
- Live DIM calls mocked in unit tests.

## Out of Scope

- Bungie in-game equip (020)
- Soft guidance / LLM / class-item intent
- Changing equip-ready definition
- Production polish UI beyond Builds debug
