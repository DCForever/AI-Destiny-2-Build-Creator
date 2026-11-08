# Feature Specification: DART-038 Flutter Equip UI

**Feature Branch**: `dart-038-flutter-equip-ui`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Character pick + equip CTA + step report. Equip-ready gate enforced; gaps confirm UX."

**Program ID**: DART-038  
**Phase**: P4  
**Depends**: DART-037 (equip plan + write client + orchestrator), DART-033 (variant compose / slot pins)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter **Windows** equip surface on **Builds library** detail when a **variant** is selected:
  - **Character pick** (class-filtered to build class; load via profile `getCharacters`)
  - **Equip CTA** (“Apply to character”) that runs equip-ready → optional gaps confirm → plan → execute
  - **Step report** after execute (`EquipStatus`: per-step ok/error + completed/failed counts)
- **Equip-ready gate enforced** before plan/execute (`computeEquipReady` / `assertEquipReady` on post-sync inventory pin index)
- **Gaps confirm UX**: surface non-ready pin statuses (wishlist/stale) and require explicit confirm when equip-ready but combat slots are incomplete (empty combat gaps)
- Character class must match build class (`INVALID_CHARACTER` when mismatch)
- Optional pre-equip `syncIfStale` (60s freshness) when signed in
- Pure display helpers for pin gap labels, CTA enablement, step report lines
- Widget + unit tests with mocked write client / fake profile characters (no live Bungie; no CLIENT_SECRET)

**Out of scope (later slices):**

- DIM export / clipboard UI (DART-039)
- Full seasonal artifact socket wiring (parity: execute may fail artifact step — report in step list)
- Soft guidance auto-apply (forbidden)
- Jaspr / mobile equip shells
- Node sidecar / CLIENT_SECRET (forbidden)
- Product Next.js route changes

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Character pick + equip-ready gate (Priority: P1)

As a Windows user with a signed-in account and a selected variant, I can pick a matching-class character and see whether the variant is equip-ready. The Apply CTA is disabled when not equip-ready (wishlist/stale pins) or when no character is selected.

**Why this priority**: Roadmap exit — character pick + equip-ready gate enforced.

**Independent Test**: Seed wishlist pin → equipReady false → CTA disabled; seed owned instance pin + inventory row → equipReady true → CTA enabled with character selected.

**Acceptance Scenarios**:

1. **Given** a selected variant with only wishlist pins, **When** readiness is evaluated, **Then** equip-ready is false, pin gap list shows wishlist, and Apply is disabled.
2. **Given** owned instance pins present in local inventory and a class-matching character selected, **When** readiness is evaluated, **Then** equip-ready is true and Apply is enabled.
3. **Given** only Titan characters on the account and a Hunter build, **When** characters load, **Then** matching list is empty and UI explains no matching class.
4. **Given** signed out, **When** equip panel renders, **Then** sign-in guidance is shown and Apply is disabled.

---

### User Story 2 - Gaps confirm then equip + step report (Priority: P1)

As a Windows user, when the variant is equip-ready but has empty combat slots, Apply opens a **confirm** dialog describing those gaps before executing. After execute, a step report lists transfer/equip results with completed/failed counts. Soft guidance never auto-applies.

**Why this priority**: Roadmap exit — gaps confirm UX + step report.

**Independent Test**: Equip-ready with one empty combat slot → Apply → cancel confirm → no write; confirm → mock write client called; step report shows completed ≥ 1.

**Acceptance Scenarios**:

1. **Given** equip-ready and at least one empty combat slot, **When** I press Apply, **Then** a gaps confirm dialog appears and no write runs until confirm.
2. **Given** gaps confirm open, **When** I cancel, **Then** write client is not invoked.
3. **Given** equip-ready with all applied pins owned (no empty gaps or after confirm), **When** equip runs with mock write, **Then** step report shows per-step results and completed/failed counts.
4. **Given** middle step fails on mock, **When** equip finishes, **Then** step report shows partial status (no rollback claim).

---

### User Story 3 - Hard block when not equip-ready (Priority: P1)

As a user, pressing Apply must not call plan/execute when not equip-ready; error/status surfaces `NOT_EQUIP_READY` style guidance from pin gaps.

**Why this priority**: Hard equip gate (DBR equip-ready / wishlist cannot equip).

**Independent Test**: Force equip attempt while readiness false → no plan/execute; status message references not equip-ready / pin gaps.

**Acceptance Scenarios**:

1. **Given** not equip-ready, **When** Apply is invoked programmatically, **Then** write client is not called and error/status explains equip-ready failure.
2. **Given** character class mismatch, **When** Apply is attempted, **Then** equip is blocked with class mismatch guidance.

---

### Edge Cases

- No applied combat pins → equip-ready false (empty equipment) → Apply blocked.
- Stale pin (instance missing after sync) → equip-ready false; re-evaluate after syncIfStale.
- Fashion/artifact steps may fail at execute; still listed in step report (best-effort).
- Soft coverage chips remain display-only; equip path never auto-fills soft suggestions.
- Missing access token / unsigned → block equip with sign-in message.
- No CLIENT_SECRET anywhere in equip UI/client surface.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Builds detail MUST show an Equip / Apply panel when a variant is selected.
- **FR-002**: Panel MUST load characters for the signed-in account and filter to the build’s guardian class.
- **FR-003**: Panel MUST compute equip-ready from resolved variant equipment + local inventory pin index and display pin gap statuses (wishlist/stale/pinned).
- **FR-004**: Apply CTA MUST be disabled when not signed in, no character selected, equipping busy, or not equip-ready.
- **FR-005**: Apply MUST call `assertEquipReady` (or equivalent) after optional `syncIfStale` before `planEquipSteps` / `executeEquipPlan`.
- **FR-006**: When equip-ready and empty combat slots exist, Apply MUST require explicit gaps confirm before execute.
- **FR-007**: After execute, UI MUST show a step report (kind/slot, ok/error, completed, failed).
- **FR-008**: Character class MUST match build class or equip is blocked.
- **FR-009**: Soft guidance MUST NOT auto-apply as part of equip.
- **FR-010**: Unit/widget tests MUST cover gate-disabled CTA, gaps cancel/confirm, and step report with mocked write client (no live Bungie; no CLIENT_SECRET).

### Key Entities

- **CharacterSummary**: characterId, classType (Titan/Hunter/Warlock), light, dateLastPlayed.
- **EquipReadinessView**: equipReady flag + pin statuses for UI gaps list.
- **EmptyCombatGap**: combat slot with no applied claim (confirm UX).
- **EquipStepReport**: derived from `EquipStatus` for display.
- **EquipController**: host orchestration (characters, readiness, confirm, execute).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Wishlist-only variant cannot invoke write client from Apply.
- **SC-002**: Owned-pin equip-ready variant with character selected can run mock equip and show step report.
- **SC-003**: Gaps confirm cancel prevents any write; confirm proceeds.
- **SC-004**: No CLIENT_SECRET in host/equip surface; pure Dart I/O only.

## Assumptions

- **A1**: Equip panel lives on Builds library detail (depends DART-033), not a new nav rail destination.
- **A2**: Characters come from Bungie profile component 200 via new `getCharacters` on `BungieProfileClient` (minimal addition required for character pick; was not on DART-024 surface).
- **A3**: Pre-equip inventory refresh uses existing `syncIfStale` (60s); tests may inject readiness/inventory without network.
- **A4**: Gaps confirm applies to empty combat slots when already equip-ready; non-ready pin gaps block without a “force equip” path.
- **A5**: Fashion/artifact optional inputs: plan only combat pins from resolved equipment when artifact/fashion not modeled in host yet (null/empty — parity with empty fashion).
- **A6**: Write client is constructed with host public API key only (same as profile HTTP client); injectable for tests.
- **A7**: Soft never auto-applies; equip does not mutate soft targets or coverage.
- **A8**: DIM export remains DART-039.
