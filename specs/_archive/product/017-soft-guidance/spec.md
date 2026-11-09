# Feature Specification: Soft Guidance & Coverage Indicators

**Feature Branch**: `017-soft-guidance`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Implement soft guidance and coverage indicators per domain DAC-P1-006, DBR-GUID-*, DBR-SYN-011. Passiveive indicators and coverage breakdown (supported / weak / missing + hints) for synergies, armor set-bonus soft coverage, and element/subclass soft mismatches. Weak coverage must not block save on non-default variants. Soft-stat UI deferred to slice 5. Out of scope: hard blocks from soft coverage, Bungie equip, DIM, artifacts, fashion, LLM, wishlist pins."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [domain-slice-roadmap.md](../domain-slice-roadmap.md)

**Prior slices**: [015-build-identity](../015-build-identity/spec.md), [016-wishlist-equip-ready](../016-wishlist-equip-ready/spec.md)

## Clarifications

### Session 2026-07-10

- Q: How are coverage tiers defined for a designated synergy? → **A**: **supported** = ALL evidence links matched; **missing** = NONE matched; **weak** = SOME but not all.
- Q: What does the coverage breakdown include in this slice? → **C**: Designated **synergies** + armor **set-bonus soft coverage** + **element/subclass soft mismatches**.
- Q: Soft-stat targets / below-target warnings UI? → **C**: **Defer ALL soft-stat UI to slice 5** (`soft-stat-targets`); this slice has **no** soft-stat targets or soft-stat warnings UI.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Synergy Coverage Tiers & Passive Indicators (Priority: P1)

A builder viewing a variant sees **passive coverage indicators** for each **designated synergy**, using fixed tiers: **supported** (all evidence links matched), **weak** (some but not all), **missing** (none matched). Indicators are informational only; they do not themselves block save. Verification is debug/API-first (001 pattern).

**Why this priority**: Synergy coverage is the core of soft guidance (DBR-GUID-001, DAC-P1-006); without tiered indicators, builders cannot tell whether a kit actually supports their designated play patterns.

**Independent Test**: Via debug/API, resolve a variant against a designated synergy with (a) all evidence links present → `supported`; (b) a proper subset → `weak`; (c) zero matches → `missing`. Confirm passive indicator fields expose the tier per designated synergy without requiring production UI.

**Acceptance Scenarios**:

1. **Given** a build with a designated synergy whose evidence links are all satisfied by the variant loadout, **When** coverage is evaluated, **Then** that synergy is reported as **supported**.
2. **Given** a designated synergy where at least one but not all evidence links match the variant, **When** coverage is evaluated, **Then** that synergy is reported as **weak**.
3. **Given** a designated synergy where no evidence links match the variant, **When** coverage is evaluated, **Then** that synergy is reported as **missing**.
4. **Given** multiple designated synergies on the same build, **When** coverage is evaluated, **Then** each synergy receives its own independent tier (equal weight; no single synergy hides another).
5. **Given** coverage results for a variant, **When** a tester inspects debug/API output, **Then** passive indicators expose per-synergy tier without soft-stat UI, equip, DIM, artifacts, fashion, or LLM features.

---

### User Story 2 - Coverage Breakdown with Hints (Priority: P1)

A builder (or tester via debug/API) can open a **coverage breakdown** that lists soft-check rows for: (1) designated synergies (with tier + which links matched/unmatched), (2) armor **set-bonus soft coverage** (active 2pc/4pc and which designated synergies they support), and (3) **element/subclass soft mismatches** (e.g. off-element weapons vs subclass tree). Each row may include a short **hint** toward improving coverage. Soft-stat target rows are **out of scope** for this slice.

**Why this priority**: Passive tiers alone are not actionable; the breakdown + hints (DBR-GUID-001, DBR-SETB-001) explain *why* coverage is weak/missing and what to change next.

**Independent Test**: Fixture a variant with mixed synergy match, a partial armor set bonus, and an off-element weapon; request coverage breakdown; confirm rows for synergies, set-bonus soft coverage, and element/subclass soft mismatch each appear with tier/status and a non-empty hint where applicable; confirm **no** soft-stat target/warning rows are emitted.

**Acceptance Scenarios**:

1. **Given** a variant with at least one designated synergy that is weak or missing, **When** the coverage breakdown is requested, **Then** it lists that synergy’s tier and identifies matched vs unmatched evidence links, plus a hint toward closing gaps.
2. **Given** a variant with armor pieces that activate a 2pc and/or 4pc set bonus, **When** the coverage breakdown is requested, **Then** it reports soft set-bonus coverage (active pieces/bonus) and which designated synergies that bonus supports.
3. **Given** a subclass tree of one element and one or more weapons of a different damage type, **When** the coverage breakdown is requested, **Then** the element/subclass mismatch appears as a **soft** row (not a hard block) with a hint.
4. **Given** coverage breakdown evaluation in this slice, **When** soft-stat targets are absent or present on the build, **Then** the response includes **no** soft-stat target or below-target warning UI/rows (deferred to slice 5).
5. **Given** debug/API tools only, **When** a tester reviews breakdown output, **Then** they can verify synergies + set-bonus soft coverage + element/subclass soft mismatches without production polish UI.

---

### User Story 3 - Suggestions Prefer Synergy Coverage Gaps (Priority: P2)

Set/roll (and related `suggest*`) flows **primarily optimize for synergy coverage** (DBR-GUID-002): when ranking suggestions for a variant, candidates that close **missing** or **weak** designated-synergy gaps are preferred over equally tagged candidates that do not improve coverage. Existing suggestion surfaces may be extended rather than replaced; fashion remains excluded from suggestion drivers.

**Why this priority**: Indicators without gap-aware suggestions leave builders to guess; aligning `suggest*` with coverage gaps makes soft guidance actionable while staying soft.

**Independent Test**: On a build with a designated synergy in `missing` or `weak` state, run suggest-sets (and/or suggest-rolls) via debug/API; confirm higher-ranked results preferentially include items/plugs that match unmatched evidence links over controls that do not improve that synergy’s coverage.

**Acceptance Scenarios**:

1. **Given** a variant with a designated synergy marked **missing** or **weak**, **When** suggest-sets (or equivalent) runs, **Then** ranking primarily prefers candidates that would match unmatched evidence links for that synergy over candidates that do not improve coverage.
2. **Given** multiple designated synergies, **When** suggestions are scored, **Then** designated synergies contribute **equally** to coverage-oriented ranking; no single designated synergy monopolizes the score.
3. **Given** a suggestion result list, **When** the tester inspects rationale/debug fields (if exposed), **Then** coverage-gap preference is observable without requiring LLM or fashion-driven ranking.
4. **Given** fashion/cosmetic sets, **When** suggestions run, **Then** fashion does not drive synergy coverage scoring.

---

### User Story 4 - Soft Guidance Never Hard-Blocks Save (Priority: P1)

Weak or missing synergy coverage, set-bonus soft gaps, and element/subclass soft mismatches **do not block save** on **non-default** variants (DBR-SYN-011). Soft guidance remains advisory. **Hard blocks** stay reserved for true Destiny/system constraints already in force (DBR-GUID-003). This slice does **not** newly implement required-link hard enforcement on the default variant; at most it may **soft-warn**.

**Why this priority**: Soft guidance must not become a second composition gate; preserving soft-only save behavior is the acceptance hinge of DAC-P1-006 / DBR-SYN-011.

**Independent Test**: Save a non-default variant with weak and missing synergy coverage (and an element soft mismatch); confirm save succeeds with soft guidance still reported. Separately confirm an illegal exotic double-equip (or other existing hard constraint) still fails save.

**Acceptance Scenarios**:

1. **Given** a non-default variant with one or more designated synergies at **weak** or **missing**, **When** the user saves, **Then** save succeeds and soft coverage indicators/breakdown remain available.
2. **Given** a non-default variant with set-bonus soft gaps and/or element/subclass soft mismatches, **When** the user saves, **Then** save succeeds; those rows stay soft warnings/hints only.
3. **Given** a variant that violates a true Destiny/system constraint (e.g. two exotic weapons), **When** the user saves, **Then** save is still hard-blocked by existing constraint rules (unchanged by soft guidance).
4. **Given** unsatisfied synergy links on a variant in this slice, **When** save runs, **Then** this feature emits soft guidance/warnings only and does **not** newly hard-enforce required links on default.
5. **Given** debug/API verification, **When** comparing soft-coverage fixtures vs hard-constraint fixtures, **Then** testers can distinguish soft advisory outcomes from hard save failures.

---

### Edge Cases

- A designated synergy with **zero evidence links** cannot be `supported` via link matching; treat as **missing** (or empty-evidence advisory) and still do not block non-default save.
- Multiple designated synergies: one `supported` and one `missing` — both tiers appear independently.
- Partial armor set (e.g. 1/2 or 3/4 pieces): set-bonus soft coverage reports inactive/partial state; does not invent a bonus the loadout has not earned.
- Off-element weapons: mismatch is soft in the breakdown; may contribute to a synergy’s weak/missing tier via evidence matching, but never becomes a blanket hard element lock.
- Empty combat slots on non-default variants: unmatched links yield weak/missing soft guidance; save remains allowed per 015.
- Wishlist/unowned desired rolls (016): coverage evaluates planned item/plugs for soft guidance; ownership/pins do not gate coverage tiers or save in this slice.
- Soft-stat targets and below-target warnings are **absent** from this slice’s UI/API surface; slice 5 owns them.
- Required-link hard enforcement on default, equip/DIM, artifacts, fashion, LLM, and wishlist pin UX are out of scope.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: For each designated synergy, the system MUST compute coverage status `supported` | `weak` | `missing` where supported = all evidence links matched, weak = some but not all, missing = none matched.
- **FR-002**: Soft guidance MUST expose passive per-synergy indicators and MUST NOT block save solely because coverage is weak/missing on non-default variants.
- **FR-003**: Soft guidance MUST expose a coverage breakdown listing designated synergies (tier + matched/unmatched links + hints), armor set-bonus soft coverage, and element/subclass soft mismatches.
- **FR-004**: Coverage breakdown MUST NOT include soft-stat target or below-target warning rows in this slice.
- **FR-005**: Multiple designated synergies MUST contribute equally to coverage aggregation and coverage-driven suggestions.
- **FR-006**: Link matching MUST support existing link kinds (`weapon`, `weapon_perk`, `origin_trait`, `armor_set_bonus`) against resolved loadout claims / available set-bonus metadata.
- **FR-007**: Suggestions (`suggest*` flows) SHOULD prefer candidates that close `missing`/`weak` synergy gaps over peers that do not improve coverage.
- **FR-008**: Soft guidance MUST NOT introduce new hard blocks for synergy coverage, set-bonus soft gaps, or element/subclass soft mismatches; hard blocks remain Destiny/system constraints only.
- **FR-009**: Coverage MUST be evaluate-on-read from the current resolved loadout (live/snapshot attachments).
- **FR-010**: Fashion MUST NOT drive synergy coverage scoring or soft-guidance suggestion ranking.

### Key Entities

- **Coverage Tier**: `supported` | `weak` | `missing` for a designated synergy.
- **Coverage Breakdown**: Soft-check rows (synergy, set-bonus, element/subclass) with status + hints.
- **Evidence Link Match**: Whether a synergy link is satisfied by the resolved variant.
- **Soft Hint**: Short advisory text toward closing a gap (non-blocking).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For fixtures covering all-links-matched, partial-match, and zero-match cases, 100% of designated synergies receive the correct tier per the locked definition.
- **SC-002**: 100% of coverage-breakdown fixtures expose synergies, set-bonus soft coverage, and element/subclass soft mismatches when present; 0% include soft-stat target/warning rows.
- **SC-003**: 100% of non-default variant save attempts with weak and/or missing synergy coverage succeed when existing hard constraints and composition rules are otherwise satisfied.
- **SC-004**: In a ranked suggest-sets checklist with a known coverage gap, ≥80% of top-5 results are gap-closing candidates relative to a non-gap-aware baseline on the same fixture.
- **SC-005**: 100% of hard-constraint fixtures still fail save; soft coverage alone never converts a hard failure into success or a soft advisory into a new hard block.
- **SC-006**: A tester can complete indicator → breakdown → soft-save → gap-preferring suggest verification using debug/API tools only in under 10 minutes for a single fixture.

## Assumptions

- Domain DBR/DAC are canonical when conflicting with older feature BRs.
- Soft-stat authoring and warnings are entirely slice 5; this slice never emits soft-stat rows.
- Required-link hard enforcement on default remains a later/other concern; this slice soft-warns only.
- Debug/API-first delivery (001 pattern).
- Coverage evaluates planned rolls (hashes/plugs), not ownership/equip-ready.

## Out of Scope

- Soft-stat targets UI and below-target warnings (slice 5)
- Bungie equip / DIM export
- Artifacts / fashion equip
- LLM propose-for-confirm
- Wishlist pin UX (016)
- New required-link hard blocks on default
- Production-polished guidance chrome

## Traceability

| Spec item | Domain |
|-----------|--------|
| US1 / FR-001–002 | DBR-GUID-001, DBR-SYN-011, DAC-P1-006 |
| US2 / FR-003–004, FR-006 | DBR-GUID-001, DBR-SETB-001, DAC-P1-006 |
| US3 / FR-005, FR-007, FR-010 | DBR-GUID-002, DBR-SYN-004 |
| US4 / FR-008 | DBR-GUID-003, DBR-SYN-011 |
| Clarifications | Session 2026-07-10 Q1=A, Q2=C, Q3=C |
