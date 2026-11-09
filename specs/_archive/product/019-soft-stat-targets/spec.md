# Feature Specification: Soft Stat Targets

**Feature Branch**: `019-soft-stat-targets`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Implement soft-stat targets at build level for EoF six stats (DBR-STAT-*). Soft targets and below-target warnings UI deferred from slice 017. Soft-only validation; never hard-block non-default save. Debug/API-first."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [domain-slice-roadmap.md](../domain-slice-roadmap.md)

**Prior slices**: [015](../015-build-identity/spec.md)–[018](../018-artifacts-fashion/spec.md)

## Clarifications

None yet — defaults from DBR-STAT-001–007.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build-Level Soft Stat Targets (Priority: P1)

A builder sets optional per-stat soft targets on a **build** for the EoF six: Class, Grenade, Melee, Super, Health, Weapons. Targets are shared across variants. Range supports benefits up to **200**. Missing targets are allowed.

**Why this priority**: Core of DBR-STAT-001–003; without stored targets, soft guidance cannot warn.

**Independent Test**: Via debug/API, set targets on a build (subset of six), reload, confirm persistence shared across variants; clear a target and confirm absence.

**Acceptance Scenarios**:

1. **Given** a build, **When** the user sets one or more of the six soft targets (≤200), **Then** they persist at build level.
2. **Given** two variants of that build, **When** targets are read, **Then** both see the same build-level targets.
3. **Given** a target above 200, **When** save runs, **Then** validation rejects it.
4. **Given** no targets set, **When** the build is saved, **Then** save succeeds.

---

### User Story 2 - Below-Target Soft Warnings (Priority: P1)

Coverage/soft guidance reports **below-target warnings** when a full-loadout estimate is under a set target. Warnings are soft only — they do not block non-default save or equip gates from prior slices.

**Why this priority**: DBR-STAT-004–005; closes the soft-stat UI deferred from 017.

**Independent Test**: Fixture a build with a Health target of 100 and a loadout estimate below 100; request coverage (or soft-stat endpoint); confirm warning row; confirm save still succeeds.

**Acceptance Scenarios**:

1. **Given** a set target and estimated loadout below it, **When** soft guidance is evaluated, **Then** a below-target warning appears for that stat.
2. **Given** estimate meets or exceeds the target, **When** evaluated, **Then** no below-target warning for that stat.
3. **Given** below-target warnings, **When** a non-default variant is saved, **Then** save succeeds.
4. **Given** no targets, **When** evaluated, **Then** no soft-stat warning rows are invented.

---

### User Story 3 - Synergy Nudges (Priority: P2)

Designated synergies may **suggest/nudge** related soft stat targets; the user accepts or ignores. Nudges are advisory and do not auto-write targets without confirmation.

**Why this priority**: DBR-STAT-006; improves discoverability without forcing stats.

**Independent Test**: Build with a designated synergy that maps to a stat nudge; request suggest/nudge via debug/API; confirm suggested targets listed; confirm build targets unchanged until user accepts.

**Acceptance Scenarios**:

1. **Given** designated synergies with known stat affinities, **When** nudges are requested, **Then** related soft targets are suggested with rationale.
2. **Given** a nudge, **When** the user ignores it, **Then** build targets remain unchanged.
3. **Given** a nudge, **When** the user accepts, **Then** accepted targets are written at build level (without lowering existing higher targets unless explicitly replaced).

---

### User Story 4 - Soft Element Remains Soft (Priority: P2)

Weapon damage type vs subclass element remains **soft / synergy-based** (already partially in 017). This slice does not add a hard element lock.

**Why this priority**: DBR-STAT-007 continuity.

**Independent Test**: Off-element weapon still yields soft mismatch from 017; save not hard-blocked by element alone.

**Acceptance Scenarios**:

1. **Given** off-element weapons vs subclass, **When** coverage runs, **Then** soft element mismatch remains advisory only.
2. **Given** soft-stat targets present, **When** element mismatch also present, **Then** both appear as soft rows without hard-blocking save.

---

### Edge Cases

- Partial target set (only Health + Weapons) is valid.
- Estimate sources incomplete (missing armor): warn with best-effort estimate and note incompleteness rather than inventing stats.
- Target of 0 treated as unset or invalid — prefer unset (omit key).
- Concurrent variant edits do not fork targets (build-level).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST store optional soft targets for Class, Grenade, Melee, Super, Health, Weapons at build level.
- **FR-002**: Targets MUST be integers in 1–200 when set; omit/null means no target.
- **FR-003**: System MUST estimate loadout stats from armor (incl. class item), mods, fragments/aspects, and other known bonuses when evaluating warnings.
- **FR-004**: Below-target MUST emit soft warnings only; MUST NOT hard-block non-default save.
- **FR-005**: Synergy nudges MUST be opt-in (accept/ignore); no silent overwrite of higher user targets.
- **FR-006**: Element mismatch remains soft (no new hard lock).
- **FR-007**: Debug/API MUST expose targets, estimates, and warnings; production polish UI optional/minimal.

### Key Entities

- **SoftStatTargets**: Build-level map of six stats → optional threshold.
- **StatEstimate**: Computed totals for the six stats for a variant loadout.
- **SoftStatWarning**: Below-target advisory row.
- **StatNudge**: Suggested target from designated synergies.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Tester can set/clear build targets and see them on all variants via debug/API in under 2 minutes.
- **SC-002**: Below-target warning appears when estimate &lt; target in automated tests.
- **SC-003**: Non-default save with below-target warnings succeeds in automated tests.
- **SC-004**: `npm run gate` green with new soft-stat tests.
- **SC-005**: Accepting a nudge writes targets; ignoring leaves them unchanged.

## Assumptions

- Stat estimate reuses or extends existing inventory/armor/mod resolution where available; gaps documented as best-effort.
- Soft-stat rows integrate with or sit beside 017 coverage response (preferred: extend coverage or sibling endpoint).
- Weapon element soft mismatch already from 017; this slice only ensures coexistence.

## Out of Scope

- Hard-blocking save/equip for soft stats
- Bungie equip / DIM / LLM propose
- Production-polished charts beyond debug
- Changing the six-stat set
