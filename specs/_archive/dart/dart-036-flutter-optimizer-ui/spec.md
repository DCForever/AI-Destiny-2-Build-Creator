# Feature Specification: DART-036 Flutter Optimizer UI

**Feature Branch**: `dart-036-flutter-optimizer-ui`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Finish/optimizer workspace on Windows. Suggest → user confirm; never silent apply."

**Program ID**: DART-036  
**Phase**: P4  
**Depends**: DART-035 (optimizer isolate + confirm-only materialize/apply), DART-030 (Sets library UI)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter **Windows** Finish/optimizer **workspace** on the Sets library detail pane when the selected set is **armor**
- Goals controls: optional locked exotic item hash, prefer-reuse toggle, require soft thresholds toggle, soft-stat thresholds fields (display/edit draft only until Find kits)
- **Find kits** runs `optimizeArmorInIsolate` (or injectable runner) with injected/mapped candidates — **never writes** sets
- Suggestion list (top-N compare, expand to see all returned combinations) with score, estimated stats, piece summary
- **Suggest → user confirm**: Apply in place / Materialize as new set only after **explicit confirmation** dialog (or equivalent confirm control)
- Empty-reason / error surfacing (`NO_INVENTORY`, `NO_VALID_KITS`, etc.)
- Pure display helpers for combination labels, empty-reason copy, confirm advisory caption
- Widget + unit tests (memory DB / injected candidates; no live Bungie; no CLIENT_SECRET)

**Out of scope (later slices):**

- Equip / DIM (DART-037–039)
- Full inventory→candidate projection polish / set-bonus ranking from synergies (MVP: bucket map + optional catalog exotic/name; injectable candidates for tests)
- Auto-stat-mods / assumedMods assignment
- Soft auto-apply of kits (forbidden)
- Weapons optimizer
- Jaspr / mobile shells
- Node sidecar / CLIENT_SECRET

### Assumptions

- **A1**: Workspace lives on **Sets library** armor-set detail (depends DART-030); not a new nav rail destination.
- **A2**: Candidates may be **injected** (tests) or built from local inventory + optional catalog annotations; empty inventory surfaces `NO_INVENTORY`-style guidance without writing.
- **A3**: Optimize uses DART-035 isolate/local runners; materialize/apply use DART-035 confirm-only use cases.
- **A4**: Default action after confirm is **apply in place** when a selected armor set exists; **materialize** is an alternate confirm path (new set name).
- **A5**: Soft thresholds never auto-apply kit changes; `requireThresholds` only filters scored results when enabled.
- **A6**: Top-3 is the default compare window; user can expand to full returned list (maxResults capped as in pipeline).
- **A7**: Pure Dart I/O only; no CLIENT_SECRET; local-library user same as Sets when signed out.
- **A8**: Confirm dialog is mandatory before materialize/apply — silent apply after Find kits is a hard fail of this slice.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Goals then Find kits (Priority: P1)

As a Windows user with an armor set selected, I can set optimizer goals and press **Find kits**. The host runs optimize off the UI isolate and shows ranked suggestions without creating or mutating any set.

**Why this priority**: Core of Finish/optimizer workspace; suggest phase of exit criteria.

**Independent Test**: Inject five-slot fixture candidates; Find kits → combinations length ≥ 1; set item count unchanged before confirm.

**Acceptance Scenarios**:

1. **Given** an armor set selected and injectable candidates covering five slots, **When** I press Find kits, **Then** suggestion cards appear and the set’s items are unchanged.
2. **Given** empty candidates / no inventory, **When** Find kits runs, **Then** empty-reason guidance is shown and no set is written.
3. **Given** optimize in progress, **When** the UI renders, **Then** a busy indicator appears and no apply runs automatically.

---

### User Story 2 - Confirm apply / materialize (Priority: P1)

As a Windows user, choosing a suggested kit requires an **explicit confirm** before apply-in-place or materialize. There is no silent apply when suggestions arrive.

**Why this priority**: Exit criterion — Suggest → user confirm; never silent apply.

**Independent Test**: Find kits → assert no write; open confirm → cancel → no write; confirm → apply-in-place updates five slots.

**Acceptance Scenarios**:

1. **Given** suggestions displayed, **When** optimize completes, **Then** no set write occurred (confirm-only).
2. **Given** a suggestion, **When** I request Apply and cancel the confirm dialog, **Then** set items remain unchanged.
3. **Given** a suggestion, **When** I confirm Apply in place, **Then** the selected armor set’s five slots match the combination instances.
4. **Given** a suggestion, **When** I confirm Materialize as new set with a name, **Then** a new armor set is created and the original set is unchanged.

---

### User Story 3 - Empty / errors + soft never auto-apply (Priority: P2)

As a user, I see empty/error reasons clearly, and soft threshold toggles never auto-write kit pieces.

**Why this priority**: Product parity for NO_INVENTORY guidance; DBR-GUID soft path.

**Independent Test**: Empty candidates → emptyReason message; requireThresholds toggle does not call materialize/apply.

**Acceptance Scenarios**:

1. **Given** NO_INVENTORY empty reason, **When** UI renders, **Then** copy suggests inventory sync without writing sets.
2. **Given** soft thresholds draft fields, **When** I only toggle requireThresholds without confirming a kit, **Then** no materialize/apply runs.

---

### Edge Cases

- Optimize failure / isolate error surfaces as status error; no partial write.
- Truncated results show a truncation note; still require confirm to apply.
- Non-armor selected set: optimizer workspace hidden.
- Duplicate set name on materialize: use-case allocates unique name or surfaces error (existing DART-035 behavior).
- Apply on deleted set: use-case not-found; UI shows error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Windows Sets detail MUST show an Armor optimizer workspace when the selected set type is `armor`.
- **FR-002**: Find kits MUST call the DART-035 optimize runner with current goals + candidates and MUST NOT write sets.
- **FR-003**: Suggestions MUST display score, estimated stats summary, and piece identity summary for at least top-3 (with expand for all returned).
- **FR-004**: Apply in place and Materialize MUST require explicit user confirmation after a suggestion is chosen.
- **FR-005**: Completing Find kits alone MUST leave library set rows unchanged (confirm-only / never silent apply).
- **FR-006**: Empty-reason and hard use-case errors MUST surface in status UI.
- **FR-007**: Soft threshold / prefer-reuse goals MUST NOT auto-apply kit changes.
- **FR-008**: Unit/widget tests MUST cover suggest-without-write, cancel-confirm-no-write, and confirm-apply write.

### Key Entities

- **OptimizerGoalsDraft**: lockedExoticItemHash?, preferReuse, requireThresholds, soft stat thresholds map, maxResults.
- **OptimizerSuggestionView**: index, score, estimatedStats, pieces, meetsSoftThresholds, truncated context.
- **PendingConfirmAction**: applyInPlace | materializeNew with combination + optional new name.
- **CandidateBoard**: injected or inventory-mapped `CandidatePiece` list + hasInventory flag.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `flutter test` for optimizer format + workspace/page tests green on Windows host package.
- **SC-002**: Find kits never writes sets without confirm (asserted in tests).
- **SC-003**: Confirm apply updates five armor slots on the selected set; cancel leaves them unchanged.
- **SC-004**: Workspace advisory caption states suggestions require confirmation / never silent apply.

## Assumptions

See Scope boundary Assumptions A1–A8 (reasonable defaults; no NEEDS CLARIFICATION retained).
