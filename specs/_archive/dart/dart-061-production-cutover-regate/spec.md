# Feature Specification: DART-061 Production Cutover Re-Gate

**Feature Branch**: `dart-061-production-cutover-regate`

**Created**: 2026-07-25

**Status**: Active

**Input**: User description: "All RC-* pass; PRODUCTION_CUTOVER GO. GAP-CUT-01; GAP-FEAT-02 non-goal."

**Program ID**: DART-061  
**Phase**: P8  
**Depends**: DART-050–060 residual blockers cleared as required  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-CUT-01** (close); **GAP-FEAT-02** remains non-goal  
**Cutover**: [docs/multiplatform-dart-cutover-parity-checklist.md](../../docs/multiplatform-dart-cutover-parity-checklist.md) — **PRODUCTION_CUTOVER** / **RC-BRANCH**

## Scope boundary

**In scope:**

- Re-evaluate every **RC-*** criterion with written evidence (pass or product-waived note)
- Set **`PRODUCTION_CUTOVER: GO`** with **date** and **rationale**
- Set **RC-BRANCH** to **PASS**: merge of `feature/multiplatform-dart` toward production/`main` is **allowed only after** this GO (policy update in branching doc + checklist)
- Close **GAP-CUT-01**
- Keep **GAP-FEAT-02** (dim.gg share) as **non-goal** / deferred unless product elevates; **jsonOnly** remains sufficient for cutover spine
- Offline **production cutover re-gate** that machine-checks GO + all RC-* PASS + branch policy markers + non-goal residual
- Soft never auto-applies; no `CLIENT_SECRET` / `SESSION_SECRET` in clients (non-regression)
- Update feature-gaps, roadmap, port-decisions open item on cutover timing

**Out of scope (do not implement in this slice):**

- Actually merging `feature/multiplatform-dart` → `main` in this Spec Kit finish (finish-spec still lands on `feature/multiplatform-dart` only; GO **authorizes** a subsequent human/release merge)
- Implementing dim.gg share (GAP-FEAT-02 remains non-goal)
- New product UI, inventory algorithms, OAuth app registration in Bungie portal
- LLM / `/debug/*` / Flutter Web / Node sidecar
- Auto-applying soft guidance (forbidden)
- Deleting the Next.js tree in-repo in this slice (retirement is an ops follow-on after GO)

## Assumptions

- **A1**: All residual blockers **RB-01…RB-06** are already **CLEARED** by DART-050–060; this slice formalizes re-gate + GO, not re-implements those features.
- **A2**: “All RC-* pass” means each criterion in the cutover checklist shows **PASS** (or an explicit product-waived note with residual tracker). No open FAIL remains.
- **A3**: **RC-BRANCH PASS** means written policy: merge toward production/`main` is **permitted only when** `PRODUCTION_CUTOVER: GO` is set; the GO decision itself satisfies the prior FAIL (“blocked on cutover GO”). This slice does **not** perform the main merge.
- **A4**: dim.gg share (**GAP-FEAT-02**) stays **deferred/non-goal**; cutover does not require share URL parity.
- **A5**: Operator live Bungie portal re-smoke and character equip remain recommended on cutover day but are not blockers when automated evidence + prior dual-run (DART-060) + secret scan + fidelity gates are green (same standard as RC-OPS residual).
- **A6**: Soft never auto-applies; no CLIENT_SECRET in clients — non-regressions checked by re-gate markers + existing secret scan.
- **A7**: Mobile reduced nav / Windows-only optimizer remain acceptable per existing RC-NAV and product deferrals (GAP-FEAT-01 deferred).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - RC-* re-gate to all PASS (Priority: P1)

As a cutover reviewer, I re-walk every Next retirement criterion and record **PASS** (or product-waived) with evidence so no open FAIL blocks GO.

**Why this priority**: Exit criteria require all RC-* pass before PRODUCTION_CUTOVER GO.

**Independent Test**: Cutover checklist RC table all PASS; offline re-gate fails if any RC-* status is FAIL or missing PASS evidence markers.

**Acceptance Scenarios**:

1. **Given** residual blockers RB-01…06 are cleared, **When** the RC-* table is re-evaluated, **Then** RC-NAV through RC-OPS remain **PASS** with evidence pointers.
2. **Given** prior RC-BRANCH **FAIL** (blocked on GO), **When** GO is recorded with branch policy, **Then** RC-BRANCH becomes **PASS**.
3. **Given** the offline production cutover re-gate, **When** run against the checklist, **Then** it fails if any required RC-* lacks PASS status.

---

### User Story 2 - PRODUCTION_CUTOVER GO with date/rationale (Priority: P1)

As a release owner, I set `PRODUCTION_CUTOVER: GO` with an explicit date and rationale once criteria are met, closing GAP-CUT-01.

**Why this priority**: Core exit of DART-061 / GAP-CUT-01.

**Independent Test**: Checklist verdict block shows `PRODUCTION_CUTOVER: GO` plus date and rationale; re-gate requires GO markers; feature-gaps GAP-CUT-01 closed.

**Acceptance Scenarios**:

1. **Given** all RC-* PASS, **When** GO is set, **Then** the verdict block includes date and rationale citing cleared residuals and RC-* PASS.
2. **Given** GO is set, **When** GAP-CUT-01 is inspected, **Then** status is closed/done with DART-061 evidence.
3. **Given** the re-gate, **When** PRODUCTION_CUTOVER is still NO-GO, **Then** the gate fails.

---

### User Story 3 - RC-BRANCH merge policy after GO (Priority: P1)

As a release engineer, after GO I may merge `feature/multiplatform-dart` toward production/`main` under written policy; before GO that merge remained forbidden.

**Why this priority**: Exit criteria explicitly name RC-BRANCH + merge-only-after-GO.

**Independent Test**: Branching doc + checklist contain merge-after-GO policy markers; re-gate validates them; this slice’s finish-spec still merges only to `feature/multiplatform-dart`.

**Acceptance Scenarios**:

1. **Given** PRODUCTION_CUTOVER GO, **When** branching policy is read, **Then** it states merge to production/`main` is allowed only after GO (RC-BRANCH).
2. **Given** GO is not set, **When** policy is read historically, **Then** merge to main remains forbidden.
3. **Given** GAP-FEAT-02, **When** cutover is GO, **Then** dim.gg share remains non-goal (jsonOnly sufficient).

---

### Edge Cases

- Any RC-* still FAIL → must not set GO; re-gate fails
- Product elevates dim.gg → would open new work; not this slice (GAP-FEAT-02 stays deferred)
- GO authorizes but does not auto-execute main merge or Next tree deletion
- Soft guidance must never auto-apply on cutover candidates
- CLIENT_SECRET / SESSION_SECRET must remain absent from Flutter/Jaspr clients

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST re-record every `RC-*` criterion as **PASS** (or product-waived with written note) in the cutover parity checklist.
- **FR-002**: System MUST set `PRODUCTION_CUTOVER: GO` with **date** and **rationale**.
- **FR-003**: System MUST set **RC-BRANCH** to **PASS** and document merge of `feature/multiplatform-dart` toward production/`main` only after GO.
- **FR-004**: System MUST close **GAP-CUT-01** in the feature-gaps catalog.
- **FR-005**: System MUST keep **GAP-FEAT-02** (dim.gg share) as non-goal/deferred unless product elevates; jsonOnly remains cutover-sufficient.
- **FR-006**: System MUST provide an offline production cutover re-gate that validates GO, RC-* PASS markers, branch policy, GAP-CUT-01 closed markers, and GAP-FEAT-02 non-goal residual.
- **FR-007**: Soft guidance MUST never auto-apply; clients MUST NOT embed CLIENT_SECRET / SESSION_SECRET.
- **FR-008**: PROGRAM_GATE MUST remain **GO**.
- **FR-009**: This slice’s finish-spec MUST merge only to `feature/multiplatform-dart` (not main); GO authorizes a later production merge.

### Key Entities

- **ProductionCutoverVerdict**: `PRODUCTION_CUTOVER: GO|NO-GO` + date + rationale
- **RetirementCriterion (RC-*)**: Named pass condition + evidence + status
- **BranchMergePolicy (RC-BRANCH)**: Allow multiplatform → production/main only after GO
- **ProductionCutoverRegateResult**: Offline validation result

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart run tool/production_cutover_regate.dart` exit 0; unit tests green.
- **SC-002**: Cutover checklist shows `PRODUCTION_CUTOVER: GO` with date/rationale; all RC-* **PASS** including RC-BRANCH.
- **SC-003**: GAP-CUT-01 closed; GAP-FEAT-02 remains deferred/non-goal; FEAT-OPS-CUTOVER shipped.
- **SC-004**: Roadmap DART-061 **done**; Current pointer notes program complete / no further planned DART-050–061 residual.
- **SC-005**: Soft never auto-applies; client secret scan remains green.
- **SC-006**: Branching doc documents merge-after-GO policy (RC-BRANCH).

## Assumptions (defaults for NEEDS CLARIFICATION)

See Assumptions A1–A7 above. No open NEEDS CLARIFICATION retained.
