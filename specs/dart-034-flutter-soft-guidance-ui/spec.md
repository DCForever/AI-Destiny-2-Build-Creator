# Feature Specification: DART-034 Flutter Soft Guidance UI

**Feature Branch**: `dart-034-flutter-soft-guidance-ui`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Soft coverage chips + soft stat targets UI (display only). Soft never auto-applies; P3 phase gate (compose without equip)."

**Program ID**: DART-034  
**Phase**: P3  
**Depends**: DART-033 (variant compose UI), DART-004 (soft coverage pure domain)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- On the Flutter **Builds** library detail pane (Windows host), under variant compose:
  - **Soft coverage chips** for designated synergies: `supported` / `weak` / `missing` tiers from `queryVariantCoverage`
  - Soft rows for **set-bonus soft status** and **element mismatches** when present
  - **Soft stat targets** display for the selected build (Armor 3.0 six stats)
  - Explicit user edit + save of soft stat targets via `updateUserBuild` (never auto-applied from nudges or coverage)
  - Soft-stat **below-target warning** rows when a stat estimate is supplied (optional; empty without estimate)
  - Clear advisory copy that soft guidance never blocks save and never auto-applies kit changes
- Pure display helpers for tier labels, chip colors keys, target formatting
- Widget + unit tests with memory DB (no live Bungie)

**Out of scope (later slices):**

- Optimizer isolate / optimizer UI (DART-035/036)
- Equip / DIM (DART-037–039)
- Auto-apply of suggested pins, sets, or stat nudges
- Suggest-sets ranking UI
- Hard-block from soft misses (forbidden)
- Full inventory-backed stat estimate pipeline polish (may pass null estimate)
- Jaspr / mobile shells
- Node sidecar / CLIENT_SECRET

### Assumptions

- **A1**: Soft coverage is queried in-process via `queryVariantCoverage` (DART-028); no HTTP.
- **A2**: Soft guidance lives on the existing Builds detail pane under variant compose (not a new nav destination).
- **A3**: Soft stat targets are build-level (`Build.softStatTargets`); editing requires explicit Save — never derived auto-write from coverage/nudges.
- **A4**: Without a `StatEstimate`, soft-stat warning rows stay empty; targets still display/edit.
- **A5**: Coverage refresh runs when the selected variant / attachments change; results are display-only and do not gate compose actions.
- **A6**: Hard DBR blocks remain hard and are already surfaced by DART-033; this slice does not soften them.
- **A7**: Local library user same as DART-030–033.
- **A8**: Pure Dart I/O only; no CLIENT_SECRET.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Soft coverage chips (Priority: P1)

As a Windows user composing a variant on a build with designated synergies, I see **passive coverage chips** for each designated synergy (`supported` / `weak` / `missing`) after coverage is evaluated. Chips are informational; they do not block attach/save.

**Why this priority**: Exit criterion — soft coverage chips; P3 phase gate compose-without-equip needs guidance visible.

**Independent Test**: Memory DB: create build with synergy type matching a library synergy with an evidence link; empty kit → missing chip; attach set matching the link → supported or weak as appropriate.

**Acceptance Scenarios**:

1. **Given** a build designating melee/Base and a library synergy with an unmatched weapon link, **When** coverage is queried for the selected variant, **Then** a soft chip shows tier `missing` (or `weak` if partial).
2. **Given** coverage results, **When** the UI renders, **Then** chips appear under a Soft guidance section and no auto-attach/auto-pin occurs.
3. **Given** soft miss, **When** user attaches a legal set (non-default), **Then** attach still succeeds (soft does not hard-block).

---

### User Story 2 - Soft stat targets UI (Priority: P1)

As a Windows user, I can view and **explicitly save** soft stat targets on the selected build. Targets are advisory; saving them never hard-blocks and never auto-fills from coverage.

**Why this priority**: Exit criterion — soft stat targets UI.

**Independent Test**: Set Melee target to 100 via controller/UI → `updateUserBuild` persists; re-select shows Melee:100; coverage targets reflect values.

**Acceptance Scenarios**:

1. **Given** a selected build, **When** I set Health target 100 and save soft targets, **Then** build record stores Health:100.
2. **Given** no stat estimate, **When** coverage runs, **Then** soft-stat warning list may be empty while targets still display.
3. **Given** soft targets present, **When** compose actions run, **Then** targets are not auto-modified by coverage evaluation.

---

### User Story 3 - Soft never auto-applies (Priority: P1)

As a user, viewing soft coverage or editing targets does **not** auto-apply set attachments, pins, or target values beyond my explicit save. Soft results never appear as hard-block errors.

**Why this priority**: Port decision + DBR-GUID; exit criterion “Soft never auto-applies.”

**Independent Test**: Query coverage with missing tier → attachments unchanged; suggest-style helpers not called for auto-write; soft section has advisory caption.

**Acceptance Scenarios**:

1. **Given** missing synergy coverage, **When** coverage refresh completes, **Then** attachment list is unchanged without user attach.
2. **Given** soft guidance UI, **When** rendered, **Then** caption states soft guidance does not block save / does not auto-apply.
3. **Given** hard slot conflict from DART-033, **When** attach fails, **Then** that remains a hard error path (orthogonal to soft chips).

---

### Edge Cases

- No designated library synergies matching types → empty synergy chip list (not an error).
- No variant selected → soft section idle / empty.
- Invalid soft target (0, >200, unknown stat) → validation error; no write.
- Coverage query null (missing build/variant) → clear soft state without crash.
- Element mismatches / set-bonus rows optional when maps empty (common offline).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Selected variant MUST trigger soft coverage query via `queryVariantCoverage` for display.
- **FR-002**: UI MUST show synergy coverage chips with tier labels `supported` | `weak` | `missing`.
- **FR-003**: UI MUST show set-bonus soft rows and element soft mismatches when present in `CoverageResult`.
- **FR-004**: UI MUST display build soft stat targets and allow **explicit** save via `updateUserBuild` / `UpdateBuildCommand.softStatTargets`.
- **FR-005**: Soft coverage results MUST NOT auto-apply attachments, pins, or targets; MUST NOT hard-block compose.
- **FR-006**: Soft section MUST include advisory copy that soft guidance is display-only / never auto-applies.
- **FR-007**: No CLIENT_SECRET; pure Dart I/O; in-process use cases only.
- **FR-008**: Tests MUST cover coverage chips (missing/supported path), soft target save, and non-auto-apply.

### Key Entities

- **CoverageQueryResult / CoverageResult**: soft aggregate (domain + app).
- **SynergyCoverageRow**: per-designation tier + links + hint.
- **SoftStatTargets / SoftStatWarningRow**: build-level soft stats.
- **Variant compose context**: selected build + variant from DART-033.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Soft coverage chips visible for designated synergies after variant select (widget/controller test green).
- **SC-002**: Soft stat targets can be saved and reloaded without hard-block.
- **SC-003**: Coverage refresh does not mutate attachments/pins without user action.
- **SC-004**: Slice tests pass under `flutter test` for soft guidance helpers + page tests.
- **SC-005**: **P3 phase gate** — compose spine on Windows works without equip (DART-030–034 path): identity → variants → attach → soft guidance display.
