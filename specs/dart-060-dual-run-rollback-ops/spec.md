# Feature Specification: DART-060 Dual-Run + Rollback Ops

**Feature Branch**: `dart-060-dual-run-rollback-ops`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Execute dual-run + rollback runbook once. GAP-OPS-01; RB-04 / RC-OPS."

**Program ID**: DART-060  
**Phase**: P8  
**Depends**: Windows + Jaspr feature-complete enough for dual-run (DART-050+ inventory fidelity, compose→equip on Windows/web)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (Next remains production until cutover; pure Dart I/O; Public+PKCE; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-OPS-01**  
**Cutover**: [docs/multiplatform-dart-cutover-parity-checklist.md](../../docs/multiplatform-dart-cutover-parity-checklist.md) — **RB-04** / **RC-OPS**

## Scope boundary

**In scope:**

- Written **dual-run runbook** covering simultaneous availability of:
  - **Next.js** (current sole production host)
  - **Flutter Windows** Dart host
  - **Jaspr web** Dart host
- **Rollback procedure** = keep Next sole production (do not flip `PRODUCTION_CUTOVER`; stop dual-use of Dart shells)
- **Compose→equip live re-verify** (not historical-only slice claims):
  - equip-ready gate
  - Bungie equip partial OK
  - DIM jsonOnly export (blocked when not equip-ready)
- Soft never auto-applies; no `CLIENT_SECRET` / `SESSION_SECRET` in clients
- **Execution notes** for one completed dual-run window, attached to / referenced from the cutover checklist
- Offline **ops gate** that validates runbook markers + execution notes + shell availability structure
- Close **GAP-OPS-01**; clear **RB-04**; set **RC-OPS** to **PASS** with evidence pointers
- `PRODUCTION_CUTOVER` remains **NO-GO** (DART-061 owns GO)

**Out of scope (do not implement in this slice):**

- Production cutover GO / merge to main (DART-061 / GAP-CUT-01)
- New product UI features or inventory algorithm changes
- dim.gg share, LLM, `/debug/*`
- Mobile dual-run as cutover-required (Windows + Jaspr + Next only for RC-OPS)
- Changing Next production traffic or Bungie Confidential config
- Auto-applying soft guidance (forbidden)

## Assumptions

- **A1**: Cutover-required dual-run shells are **Next** (prod), **Windows Flutter**, and **Jaspr web**. Mobile is optional evidence only.
- **A2**: "Executed once" means a dated **EXECUTION_NOTES** block records: shells available, compose→equip re-verify steps completed (automated host/domain tests as CI evidence + operator live path documented), rollback path confirmed, and notes linked from cutover checklist.
- **A3**: Live Bungie network equip against a real character is **operator optional** when credentials are available; in-repo PASS for RC-OPS requires (1) written runbook, (2) automated re-verify of equip-ready / equip partial / DIM jsonOnly host tests run in this dual-run window, (3) rollback = Next sole prod confirmed, (4) gate green. Operator live Bungie re-smoke remains recommended on cutover day (DART-061).
- **A4**: Inventory dual-run counts remain under DART-054 harness; this slice owns **ops dual-run + rollback + compose→equip re-verify**, not inventory fidelity math.
- **A5**: Soft never auto-applies; no CLIENT_SECRET in clients — non-regressions checked by gate markers + existing secret scan.
- **A6**: Rollback does **not** require code revert of `feature/multiplatform-dart`; operational rollback is "Next stays sole production; Dart dual-run optional."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dual-run runbook (Priority: P1)

As a release operator, I can follow a single written runbook to start dual-run: Next remains production while Windows and Jaspr Dart hosts are available for parallel compose→equip validation.

**Why this priority**: GAP-OPS-01 core deliverable; RC-OPS requires written ops steps.

**Independent Test**: Runbook doc exists with required markers; gate validates markers.

**Acceptance Scenarios**:

1. **Given** the dual-run runbook, **When** an operator reads prerequisites, **Then** Next, Windows Flutter, and Jaspr web availability steps are listed.
2. **Given** dual-run is active, **When** following the runbook, **Then** Next is still sole production traffic (no cutover GO required).
3. **Given** the offline ops gate, **When** run, **Then** it fails if required runbook markers are missing.

---

### User Story 2 - Compose→equip re-verify (Priority: P1)

As a cutover reviewer, I re-verify compose→equip on dual-run shells **in this ops window** (equip-ready gate, Bungie equip partial OK, DIM jsonOnly) — not only historical DART-038/047 merge notes.

**Why this priority**: Exit criteria explicitly require live re-verify, not historical only.

**Independent Test**: Execution notes list re-verify commands/results; host equip/DIM tests re-run green during this slice; gate requires EXECUTION_NOTES compose→equip markers.

**Acceptance Scenarios**:

1. **Given** dual-run execution notes, **When** inspected, **Then** equip-ready, equip partial OK, and DIM jsonOnly are each marked re-verified with evidence pointers (tests and/or operator steps).
2. **Given** wishlist-only pins, **When** equip-ready is evaluated, **Then** equip/DIM remain blocked (gate/doc reference domain rule).
3. **Given** soft guidance surfaces, **When** re-verified, **Then** soft never auto-applies.

---

### User Story 3 - Rollback = Next sole production (Priority: P1)

As an operator who finds dual-run problems, I can roll back by keeping Next as sole production without flipping cutover or requiring Dart deletion.

**Why this priority**: RC-OPS rollback path; RB-04 clearance requires executed rollback procedure definition + confirmation.

**Independent Test**: Runbook ROLLBACK_PROCEDURE section; execution notes confirm Next sole prod and PRODUCTION_CUTOVER NO-GO.

**Acceptance Scenarios**:

1. **Given** dual-run in progress, **When** rollback is invoked, **Then** operators stop dual-use of Dart shells and leave Next production unchanged.
2. **Given** cutover checklist after this slice, **When** PRODUCTION_CUTOVER is read, **Then** it remains **NO-GO** (DART-061 owns GO).
3. **Given** the ops gate, **When** run after docs updated, **Then** it requires rollback markers and RC-OPS evidence.

---

### Edge Cases

- Only Next available → dual-run incomplete; do not clear RB-04
- Dart Windows available but Jaspr not → RC-OPS incomplete (both cutover-primary Dart shells required)
- Operator lacks Bungie tokens → automated host re-verify still required; note live Bungie optional residual for cutover day
- Soft guidance path must not write sets/builds without explicit user action
- CLIENT_SECRET must not appear in client configs during dual-run

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST publish a dual-run + rollback runbook covering Next + Dart Windows + Jaspr web.
- **FR-002**: Runbook MUST include compose→equip re-verify steps for equip-ready, Bungie equip partial OK, and DIM jsonOnly.
- **FR-003**: Rollback MUST be defined as keep Next sole production (no cutover flip).
- **FR-004**: Execution notes MUST record one completed dual-run window with dated evidence.
- **FR-005**: Execution notes MUST be attached to or referenced from the cutover parity checklist.
- **FR-006**: Offline ops gate MUST validate runbook markers, execution notes, shell availability structure, and soft/secrets non-regression markers.
- **FR-007**: Cutover checklist MUST clear RB-04 and set RC-OPS **PASS** when exit criteria are met.
- **FR-008**: Soft guidance MUST never auto-apply; clients MUST NOT embed CLIENT_SECRET / SESSION_SECRET.
- **FR-009**: PRODUCTION_CUTOVER MUST remain NO-GO after this slice.

### Key Entities

- **DualRunRunbook**: Written procedure (prerequisites, dual-run steps, compose→equip re-verify, rollback)
- **DualRunExecutionNotes**: Dated record of one execution (shells, re-verify results, rollback confirmation)
- **DualRunOpsGateResult**: Offline validation (markers, shells present, notes executed-once)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Runbook + gate tests green; `dart run tool/dual_run_ops_gate.dart` exit 0.
- **SC-002**: Compose→equip host re-verify commands documented and executed (Windows + web equip/DIM/domain tests) with results in execution notes.
- **SC-003**: GAP-OPS-01 closed; RB-04 cleared; RC-OPS **PASS** with evidence; PRODUCTION_CUTOVER remains NO-GO.
- **SC-004**: Roadmap DART-060 status **done**; Current pointer advances to DART-061.
- **SC-005**: Soft never auto-applies; client secret scan remains green.

## Assumptions (defaults for NEEDS CLARIFICATION)

See Assumptions A1–A6 above. No open NEEDS CLARIFICATION retained.
