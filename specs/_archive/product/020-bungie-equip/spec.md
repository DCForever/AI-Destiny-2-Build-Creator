# Feature Specification: Bungie Equip

**Feature Branch**: `020-bungie-equip`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Implement Bungie equip for equip-ready variants: sync-on-equip, character pick, vault/character transfer, apply loadout plus artifact and fashion when specified. Best-effort partial apply with clear status. Debug/API-first. Depends on prior equip-ready gates and resolved artifact/fashion."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md)

**Prior slices**: [016-wishlist-equip-ready](../016-wishlist-equip-ready/spec.md), [018-artifacts-fashion](../018-artifacts-fashion/spec.md)

## Clarifications

None yet — defaults from DBR-EQP-001, 003, 005–008 and DAC-P1-007.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Equip Gate Then Character Pick (Priority: P1)

A builder equips only when the variant is **equip-ready**. They always choose a **class-matching** character. Non-ready variants are blocked with the existing NOT_EQUIP_READY outcome.

**Independent Test**: Debug/API: attempt equip on non-ready → blocked; on ready → character list returned / selection required.

### User Story 2 - Sync-on-Equip + Transfer + Apply (Priority: P1)

On equip, inventory refreshes (respect ~1/min rate limit / reuse fresh sync), required items transfer from vault/other characters, then equip applies. Artifact config and fashion apply when present on resolved variant.

**Independent Test**: Fixture ready variant with items on another character/vault; equip to target; confirm transfer+equip attempted; artifact/fashion included when set.

### User Story 3 - Best-Effort Partial Status (Priority: P1)

Equip is **best-effort partial**: apply what succeeded, report per-slot/step failures, leave character otherwise as-is; support retry. No hard rollback requirement.

**Independent Test**: Simulate one slot failure; response lists successes and failures; character not rolled back; retry can continue.

### User Story 4 - Debug Verification (Priority: P2)

Builds debug exposes Equip action (beyond gate check) with character picker and status JSON.

**Independent Test**: Tester completes gate → pick character → equip → inspect status via debug only.

## Edge Cases

- Rate-limited sync: reuse last sync if within window; surface when forced wait needed.
- Fashion omitted slots: leave cosmetics as-is (018).
- Partial fashion/artifact failure does not undo successful gear equips.
- Wrong class character: rejected before transfer.

## Requirements *(mandatory)*

- **FR-001**: Equip MUST require equip-ready (016 gate).
- **FR-002**: User MUST select target character among class-matching characters.
- **FR-003**: Equip MUST refresh inventory subject to ~1/min limit (reuse fresh sync).
- **FR-004**: Equip MUST transfer needed instances then apply loadout.
- **FR-005**: When resolved has artifact/fashion, equip MUST attempt to apply them.
- **FR-006**: Partial success MUST be reported; no mandatory rollback.
- **FR-007**: Debug/API verification without production polish UI.

## Success Criteria *(mandatory)*

- **SC-001**: Non-ready equip blocked in automated/API tests.
- **SC-002**: Ready equip path returns structured success/failure per step.
- **SC-003**: Transfer from vault/other character is attempted when items are not on target.
- **SC-004**: Gate green with new equip tests (mocked Bungie where needed).
- **SC-005**: Debug Equip action usable end-to-end with mocks or live sandbox.

## Assumptions

- Bungie OAuth session already used by inventory sync.
- Live Bungie calls may be mocked in unit tests; integration optional behind env flag.
- DIM export remains slice 7.

## Out of Scope

- DIM export payload generation
- Soft-stat / LLM / class-item intent
- Hard rollback of partial equips
