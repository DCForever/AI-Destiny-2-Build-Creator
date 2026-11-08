# Feature Specification: DART-004 Soft Coverage

**Feature Branch**: `dart-004-soft-coverage`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port soft coverage + soft stat estimate inputs (no save path imports). Soft results never imply hard block; tests forbid hard/soft confusion; DBR-GUID soft path parity."

**Program ID**: DART-004  
**Phase**: P0  
**Depends**: DART-002 (models)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure soft evaluators and soft-stat input helpers in `packages/domain` that mirror TypeScript:

- `evaluateCoverage` / `matchEvidenceLink` / `tierForMatches` (`src/lib/builds/coverage.ts`)
- `estimateLoadoutStats` / `softStatWarnings` (`src/lib/builds/statEstimate.ts`)
- Pure soft-stat target helpers: `normalizeSoftStatTargets`, `mergeSoftStatTargets` (+ `STAT_MAX` constant) (`src/lib/builds/softStatTargets.ts` pure core)
- Pure `suggestStatNudges` / `targetsFromAcceptedNudges` (`src/lib/builds/statNudges.ts`)
- Pure input DTOs needed by those evaluators (e.g. set-bonus record, inventory stat snapshot, coverage eval input)
- Golden unit tests vs TS fixture behavior; **hard vs soft confusion forbidden**

**Out of scope (later slices):** save-pipeline orchestration / buildService import rules (product TS only here as behavioral reference), resolveVariant (DART-005), equipReady (DART-006), suggest-sets gap bias UI, UI draft editors / ApiError HTTP mapping, Flutter/Jaspr, Drift/IO, Node sidecar, hard evaluators (DART-003 already done).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Synergy / set-bonus / element soft coverage (Priority: P1)

As a multiplatform domain engineer, I can call pure `evaluateCoverage` with pre-resolved claims, synergies, set-bonus map, and weapon elements so later compose shells share DBR-GUID soft tiers without hard-blocking.

**Why this priority**: DBR-GUID-001/002 and DAC-P1-006 center on supported/weak/missing coverage + set-bonus + element soft rows.

**Independent Test**: Unit fixtures mirror `coverage.test.ts` (tiers, weapon/perk match, partial set bonus, element mismatch). Assert results are `CoverageResult` (not `ConstraintEvaluation`) and never set hard-block flags.

**Acceptance Scenarios**:

1. **Given** all evidence links matched, **When** coverage is evaluated, **Then** synergy tier is `supported` and hint is null.
2. **Given** some links matched, **When** evaluated, **Then** tier is `weak` with unmatched links listed and a non-null hint.
3. **Given** no links matched (or zero total links), **When** evaluated, **Then** tier is `missing`.
4. **Given** one piece of a multi-perk armor set, **When** evaluated with set-bonus map, **Then** a `partial` set-bonus soft row is emitted.
5. **Given** off-element special vs non-Prismatic subclass, **When** evaluated with weapon elements, **Then** one element soft mismatch row is emitted; kinetic and Prismatic skip.
6. **Given** empty claims/synergies and no targets, **When** evaluated, **Then** softStats/setBonuses/elementMismatches are empty.

---

### User Story 2 - Soft stat estimate + targets (Priority: P1)

As an engineer, I can estimate armor stats from instance-backed claims and compare to soft targets so below-target warnings are advisory only (DBR-STAT-004).

**Why this priority**: Soft-stat path is an explicit slice exit criterion and must not hard-block.

**Independent Test**: Fixtures for incomplete estimate, below-target warnings only, normalize/merge targets, and that soft warnings never appear as `HardBlock`.

**Acceptance Scenarios**:

1. **Given** armor claims without instance stats, **When** `estimateLoadoutStats` runs, **Then** `incomplete` is true.
2. **Given** targets Health:100 and estimate Health:72, **When** `softStatWarnings` runs, **Then** one Health warning row; stats at/above target are omitted.
3. **Given** valid EoF six-stat targets in 1..200, **When** normalized, **Then** accepted; out-of-range or unknown keys throw domain validation with stable `INVALID_ITEM` code.
4. **Given** merge of existing and incoming targets, **When** `mergeSoftStatTargets` runs, **Then** per-stat values never decrease (max).
5. **Given** coverage with `statEstimate` and targets, **When** `evaluateCoverage` runs, **Then** `softStats` rows appear; without estimate, softStats stay empty.

---

### User Story 3 - Hard/soft separation & no auto-apply (Priority: P1)

As an engineer, soft coverage APIs never imply hard blocks and never auto-apply kit changes (DBR-GUID-003; port decision soft guidance).

**Why this priority**: Exit criterion — tests forbid hard/soft confusion.

**Independent Test**: Type/API and unit tests assert soft modules return only soft envelopes; hard evaluators remain the only hard-block source; soft APIs are pure (no mutation of input lists beyond return values).

**Acceptance Scenarios**:

1. **Given** a coverage result with weak/missing tiers, partial set bonus, element mismatch, and soft-stat warnings, **When** inspected, **Then** there is no hard-block list / `isHardBlocked` semantics on the result.
2. **Given** soft modules and hard modules, **When** tested side-by-side, **Then** soft results are not assignable/confused with `ConstraintEvaluation.hardBlocks` (tests assert soft codes ≠ pure hard-gate codes for coverage rows).
3. **Given** soft evaluators, **When** called, **Then** they do not mutate input claim/synergy collections (pure).
4. **Given** designated synergy types, **When** `suggestStatNudges` runs, **Then** nudges are suggestions only; `targetsFromAcceptedNudges` requires explicit accept merge (never auto-applied by coverage).

---

### Edge Cases

- `tierForMatches(0, 0)` → `missing`.
- Armor set-bonus match: prefer `armorSetHash`; name fallback only when map present.
- Element soft mismatch skips Prismatic subclass and kinetic weapons.
- Incomplete armor set (fewer than 5 armor claims) marks estimate incomplete.
- Soft-stat draft UI helpers (empty string draft) remain out of scope; pure map normalize only.
- Domain package remains zero IO/UI runtime dependencies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export pure `tierForMatches`, `matchEvidenceLink`, and `evaluateCoverage` with parity to TS soft coverage semantics (DBR-GUID-001, DBR-SETB-001, DBR-SYN-011).
- **FR-002**: Domain MUST export pure `estimateLoadoutStats` and `softStatWarnings` (DBR-STAT-004).
- **FR-003**: Domain MUST export pure `normalizeSoftStatTargets` / `mergeSoftStatTargets` with `STAT_MAX = 200` and Armor 3.0 six stats.
- **FR-004**: Domain MUST export pure `suggestStatNudges` / `targetsFromAcceptedNudges` as non-auto-apply helpers.
- **FR-005**: Soft evaluation results MUST use soft models (`CoverageResult`, `SoftStatWarningRow`, etc.) and MUST NOT return or set `HardBlock` / hard-block codes for coverage tiers, set-bonus soft status, element soft mismatch, or below-target stats.
- **FR-006**: Soft evaluators MUST NOT perform IO, import save services, or auto-apply targets/pins/claims.
- **FR-007**: Golden unit tests MUST cover core scenarios from `coverage.test.ts` and soft-stat estimate/warning cases; tests MUST forbid hard/soft confusion.
- **FR-008**: Domain package runtime dependencies MUST remain zero IO/UI.

### Key Entities

- **CoverageEvalInput / CoverageResult**: soft aggregate evaluation (models from DART-002 + input DTO this slice).
- **SetBonusRecord**: pure set-bonus catalog row for soft matching (this slice).
- **StatEstimate / SoftStatTargets / SoftStatWarningRow**: soft-stat models (DART-002).
- **SlotClaim / Synergy / SynergyLink**: claims and evidence (DART-002).
- **StatNudge**: soft suggestion row (this slice).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` includes soft-coverage suite green with parity scenarios above.
- **SC-002**: Soft APIs never emit `HardBlock` or pure hard-gate codes for soft-only conditions.
- **SC-003**: Domain `pubspec.yaml` runtime deps remain empty (SDK only).
- **SC-004**: Roadmap row DART-004 marked done after merge to `feature/multiplatform-dart`.

## Assumptions

- Callers pass pre-resolved claims, set-bonus maps, weapon elements, and inventory stat maps (no manifest/DB in domain).
- Soft-stat validation uses domain exception with code `INVALID_ITEM` rather than HTTP `ApiError` (adapters map later).
- `coverageGapsForSuggest` and save-module import lint stay product/TS concerns; Dart save pipeline lands in DART-028.
- UI draft string editors deferred; pure int map normalize is enough for P0.
- Stat nudges map synergy type wire → Armor 3.0 stat using the same TYPE_TO_STAT table as TS.
