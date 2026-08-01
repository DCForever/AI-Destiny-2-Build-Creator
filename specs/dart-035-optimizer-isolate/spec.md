# Feature Specification: DART-035 Optimizer Isolate

**Feature Branch**: `dart-035-optimizer-isolate`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Run enumerate in isolate; materialize Armor Set use case. UI thread safe; confirm-only apply path."

**Program ID**: DART-035  
**Phase**: P4  
**Depends**: DART-008 (optimizer pure core), DART-028 (app use cases build / set CRUD)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Pure **optimize pipeline** on top of DART-008 (`prune` → `enumerate` → score/rank combinations) with truncation + `maxResults` + optional soft-threshold filter (`requireThresholds`)
- Combination DTOs (pieces, estimated stats, set-bonus summary, reuse count, score, soft-threshold flag) without auto-stat-mod assignment (base-armor estimates only in this slice)
- Empty-reason codes parity with product `explainEmpty` when zero combinations
- **Isolate runner** (`Isolate.run`) so heavy enumerate/score does not block the Flutter UI isolate; same-isolate fallback for tests/tooling
- Application **materialize Armor Set** use case: create a new armor set from an explicit user-confirmed combination (pieces + optional constraints JSON)
- Application **apply combination in place** use case: overwrite an existing armor set’s items from an explicit user-confirmed combination (confirm-only; no silent apply)
- Optional ownership validation port for materialize/apply (injectable; tests can skip or provide maps)
- Unit tests: pure pipeline, isolate path, materialize + apply confirm-only (in-memory Drift)

**Out of scope (later slices):**

- Flutter optimizer workspace UI (DART-036)
- Inventory → `loadArmorCandidates` pipeline polish / owned-armor projection from Drift (hosts may inject candidates)
- Auto stat mods / assumedMods assignment parity (US4 product); materialize may still accept empty assumedMods
- Equip / DIM (DART-037–039)
- Soft auto-apply of suggested kits (forbidden)
- Jaspr / mobile shells
- Node sidecar / CLIENT_SECRET

### Assumptions

- **A1**: Candidates are injected into the optimize request (no inventory load in this slice). Hosts wire inventory later.
- **A2**: `includeModEstimates` is accepted for API shape parity but **ignored** for scoring in this slice — estimates are base-armor only; `assumedMods` on combinations is always empty until a later mod-estimate slice.
- **A3**: Isolate boundary uses transferable maps / primitive lists so `Isolate.run` stays reliable; pure core remains in `destiny2_domain`.
- **A4**: Confirm-only: optimize never writes sets/attachments; materialize/apply run only when the host explicitly calls them after user confirmation (DART-036 UI).
- **A5**: Materialize creates a **new** armor set; apply-in-place updates an **existing** armor set id (product US5 / US5b).
- **A6**: Soft thresholds never hard-block enumerate; they only filter when `requireThresholds` is true (score side). Soft never auto-applies kit changes.
- **A7**: Pure Dart I/O only; no CLIENT_SECRET; no Node sidecar.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Optimize pipeline pure (Priority: P1)

As a multiplatform host engineer, I can run prune → enumerate → rank on an injected candidate board and receive scored combinations with truncation flags without touching the database.

**Why this priority**: Core of “run enumerate”; builds on DART-008 for a full optimize response.

**Independent Test**: Small fixture board; assert combinations length, scores order, truncated when maxResults/maxCombinations hit.

**Acceptance Scenarios**:

1. **Given** one piece per armor slot, **When** optimize core runs, **Then** exactly one combination with five pieces is returned, `truncated` false.
2. **Given** multi-piece slots and `maxResults: 2`, **When** more than two valid kits rank, **Then** only two combinations are returned and `truncated` is true.
3. **Given** dual-exotic impossible kits only, **When** optimize runs, **Then** combinations empty and emptyReason code is a documented `NO_VALID_KITS` (or more specific when inventory/exotic/set-bonus flags provided).
4. **Given** soft thresholds with `requireThresholds: false`, **When** a kit is below threshold, **Then** it still appears (soft filter off).

---

### User Story 2 - Enumerate off UI isolate (Priority: P1)

As a Flutter Windows host, I can run the optimize pipeline via `Isolate.run` so the UI isolate is not blocked by large Cartesian enumeration.

**Why this priority**: Exit criterion — UI thread safe.

**Independent Test**: Call isolate runner with a non-trivial board; result equals same-isolate pure core; message types are sendable maps.

**Acceptance Scenarios**:

1. **Given** a candidate board, **When** optimize runs in isolate, **Then** combination counts and scores match local pure core.
2. **Given** isolate runner, **When** invoked, **Then** pure domain packages remain free of Flutter UI imports.

---

### User Story 3 - Materialize Armor Set (confirm-only) (Priority: P1)

As a compose host, after the user **confirms** a combination, I can materialize a new armor set with five instance-pinned pieces and optional stored optimizer constraints. Optimize alone never creates sets.

**Why this priority**: Exit criterion — materialize Armor Set use case; confirm-only apply path.

**Independent Test**: In-memory DB: materialize five pieces → set type armor + five active items; optimize path leaves set count unchanged.

**Acceptance Scenarios**:

1. **Given** five distinct armor slots with instance ids, **When** materialize is called, **Then** a new armor set exists with those items and optional `optimizerConstraints` JSON.
2. **Given** fewer than five slots or duplicate slots, **When** materialize is called, **Then** hard invalid-argument failure and no set written.
3. **Given** only optimize was run, **When** I list sets, **Then** no new armor set appeared (confirm-only).
4. **Given** optional ownership map missing an instance, **When** materialize runs with ownership required, **Then** hard block and no write.

---

### User Story 4 - Apply combination in place (confirm-only) (Priority: P2)

As a compose host, after the user confirms, I can apply a combination onto an existing constrained armor set without creating a new set id.

**Why this priority**: Product US5b parity for re-optimize; still confirm-only.

**Independent Test**: Create armor set; apply new pieces; same set id; items updated.

**Acceptance Scenarios**:

1. **Given** an existing armor set, **When** apply-in-place runs with a valid five-piece combination, **Then** active items match new instances and set id is unchanged.
2. **Given** a non-armor or missing set, **When** apply-in-place runs, **Then** not-found / type failure and state unchanged.

---

### Edge Cases

- Empty candidate list → empty combinations + empty reason (NO_INVENTORY / NO_CLASS_ARMOR depending on flags).
- Truncation from enumerate budget vs maxResults both set `truncated`.
- Materialize never auto-attaches unless host explicitly passes attach flags (this slice: attach optional via existing `replaceAttachmentByType` only when host requests — default **no attach**).
- Soft guidance never auto-applies; hard kit piece validation stays hard on materialize.
- Domain remains zero Flutter/Jaspr deps; isolate wrapper may use `dart:isolate` in app package.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export a pure optimize pipeline that accepts candidates + kit/score options and returns ranked combinations, evaluatedCount, truncated, optional emptyReason.
- **FR-002**: Domain MUST build combination DTOs with pieces, estimatedStats (base armor), incompleteEstimate, setBonusSummary, reusePieceCount, score, meetsSoftThresholds; assumedMods empty in this slice.
- **FR-003**: App package MUST expose isolate + local runners that execute the pure pipeline without blocking when isolate is used.
- **FR-004**: App package MUST expose `materializeArmorCombination` that creates an armor set only on explicit call (confirm-only).
- **FR-005**: App package MUST expose `applyArmorCombinationInPlace` for existing armor sets (confirm-only).
- **FR-006**: Materialize/apply MUST validate five distinct armor slots; optional ownership validation when a map is provided.
- **FR-007**: Optimize MUST NOT write library sets, set items, or attachments.
- **FR-008**: Soft thresholds filter only when `requireThresholds` is true; never hard-block enumerate validity.
- **FR-009**: Unit tests MUST cover pure pipeline, isolate parity, materialize, apply-in-place, and confirm-only (optimize does not write).

### Key Entities

- **ArmorOptimizeRequest**: candidates, constraints, priorities, thresholds, requireThresholds, preferReuse, maxResults, maxCombinations, inventory flags for empty reason.
- **ArmorCombination**: scored kit DTO for hosts / UI (DART-036).
- **ArmorOptimizeResponse**: combinations + truncated + evaluatedCount + emptyReason.
- **MaterializeCommand**: pieces, armorSetName, constraints JSON, optional assumedMods (ignored/empty ok).
- **ApplyCombinationCommand**: pieces for existing setId.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` and `dart test packages/app` green including DART-035 suites.
- **SC-002**: Isolate path produces same combination count/order as local pure core on fixture board.
- **SC-003**: Materialize creates armor set only after explicit use-case call; optimize alone does not.
- **SC-004**: UI-thread safety documented via Isolate.run wrapper API (callable from Flutter host without domain UI deps).
