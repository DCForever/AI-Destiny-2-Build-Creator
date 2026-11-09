# Feature Specification: DART-049 Cutover Parity Checklist

**Feature Branch**: `dart-049-cutover-parity-checklist`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Written parity checklist vs PRODUCT production nav; Next retirement criteria. Checklist in repo; explicit go/no-go; P5 / program gate."

**Program ID**: DART-049  
**Phase**: P5  
**Depends**: DART-047 (Jaspr equip/export), DART-041 (mobile compose), DART-038 (Flutter equip UI)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (Next remains production until explicit cutover gates; pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)

## Scope boundary

**In scope:**

- **Written parity checklist** in-repo comparing **PRODUCT production nav** (`AppShell` primary links) and core compose→equip capabilities against multiplatform Dart shells (Flutter Windows, Flutter mobile, Jaspr web)
- **Next.js retirement criteria** — explicit, testable gates that must all pass before Next stops being the production host
- **Explicit go/no-go** dual verdict:
  1. **P5 / program gate** (port workstream complete for planned slices)
  2. **Production cutover** (retire Next as production host)
- Machine-checkable presence of required checklist sections (validator test)
- Roadmap row update on finish-spec (status **done**; Current pointer closed / program complete)

**Out of scope (do not implement in this slice):**

- Retiring or deleting the Next.js app
- Merging `feature/multiplatform-dart` → `main`
- New product UI, new domain evaluators, or new host features
- Closing residual capability gaps listed as NO-GO blockers (those are follow-on work)
- `/debug/*` as primary nav parity (explicit non-goal)
- LLM multi-pass generator, dim.gg share, Flutter Web, Node sidecar, CLIENT_SECRET in clients

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Program gate checklist exists (Priority: P1)

As a program owner finishing the multiplatform Dart port, I open a single in-repo document that maps PRODUCT production nav and the compose→equip spine to Windows / mobile / web Dart hosts, with status per row and residual gaps named.

**Why this priority**: Exit criteria — “Checklist in repo”; P5 / program gate.

**Independent Test**: File `docs/multiplatform-dart-cutover-parity-checklist.md` exists; contains production nav matrix, capability matrix, and residual gaps section. Validator test fails if required headings/markers are missing.

**Acceptance Scenarios**:

1. **Given** the multiplatform worktree, **When** a contributor opens the cutover checklist doc, **Then** every `AppShell` production nav key (`loadouts`, `build`, `synergy`, `sets`, `catalog`, `settings`) appears in a parity row with Windows / mobile / web status.
2. **Given** the checklist, **When** a reader scans capability rows, **Then** intent→compose→soft guidance→equip-ready→equip/DIM→auth/sync→legacy import are each listed with host coverage notes.
3. **Given** the checklist, **When** a row is intentionally non-goal (e.g. `/debug/*`, LLM primary nav), **Then** it is marked **N/A (non-goal)** and does not block production cutover.

---

### User Story 2 - Explicit go/no-go verdicts (Priority: P1)

As a release decision-maker, I see two separate verdicts with dated rationale: (A) P5 program gate for the DART workstream, (B) production cutover readiness to retire Next.

**Why this priority**: Exit criteria — “explicit go/no-go”; decisions doc left “when Next stops” open until this gate.

**Independent Test**: Doc contains `## Verdict` with `PROGRAM_GATE:` and `PRODUCTION_CUTOVER:` markers set to `GO` or `NO-GO` plus residual-blocker list when NO-GO.

**Acceptance Scenarios**:

1. **Given** all planned DART-001…049 slices merged to `feature/multiplatform-dart`, **When** the checklist is authored, **Then** **PROGRAM_GATE** is **GO** (written plan complete; artifacts + validator green).
2. **Given** residual production-parity gaps remain (documented), **When** the checklist is authored, **Then** **PRODUCTION_CUTOVER** is **NO-GO** until retirement criteria are checked off, and blockers are listed by id.
3. **Given** a future re-evaluation, **When** all retirement criteria are satisfied, **Then** a human may flip PRODUCTION_CUTOVER to GO without inventing new nav rows (update checklist + date only).

---

### User Story 3 - Next retirement criteria are actionable (Priority: P1)

As an engineer preparing cutover, I can walk a numbered list of retirement criteria (parity, ops, auth, data migration, dual-run) and mark each pass/fail against evidence.

**Why this priority**: Exit criteria — “Next retirement criteria”; closes open question in port decisions.

**Independent Test**: Doc section `## Next retirement criteria` lists criteria with stable ids (`RC-*`); each has pass condition + evidence pointer pattern.

**Acceptance Scenarios**:

1. **Given** the retirement section, **When** read, **Then** criteria cover at least: production-nav parity (required rows), hard/soft domain parity, equip/DIM path, Public+PKCE auth, inventory sync, legacy `app.db` import path, single-writer web policy, no CLIENT_SECRET in clients, dual-run / rollback note.
2. **Given** a criterion, **When** status is fail, **Then** the production cutover verdict remains NO-GO.
3. **Given** soft guidance, **When** checklist is applied, **Then** soft never auto-applies remains a hard non-regression criterion (not optional polish).

---

### Edge Cases

- Product adds a new primary `AppShell` link after this slice → re-open checklist; do not treat missing new row as automatic GO.
- Adjacent surfaces (`/analyze`, `/debug/*`) are **not** production-nav gates unless promoted into `AppShell`.
- Mobile reduced density (Builds + Settings) is **acceptable** for cutover of **web** production host; mobile is not required to mirror every desktop nav item for Next retirement.
- Platform-specific auth (Confidential cookies on Next vs Public+PKCE on Dart) is expected; cutover retires Confidential server path only after Public+PKCE prod redirects are registered.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repo MUST contain `docs/multiplatform-dart-cutover-parity-checklist.md` as the canonical cutover checklist.
- **FR-002**: Checklist MUST enumerate PRODUCT production nav from `src/components/AppShell.tsx` `NAV_LINKS` (keys: loadouts, build, synergy, sets, catalog, settings).
- **FR-003**: Checklist MUST report parity for Flutter Windows, Flutter mobile, and Jaspr web for each required nav/capability row.
- **FR-004**: Checklist MUST include Next retirement criteria with stable `RC-*` ids and explicit pass conditions.
- **FR-005**: Checklist MUST record dual verdicts with machine-detectable markers: `PROGRAM_GATE: GO|NO-GO` and `PRODUCTION_CUTOVER: GO|NO-GO`.
- **FR-006**: Checklist MUST list residual blockers when PRODUCTION_CUTOVER is NO-GO.
- **FR-007**: A Dart test or tool MUST validate required sections/markers in the checklist doc (fails CI-style when missing).
- **FR-008**: Spec Kit artifacts under `specs/dart-049-cutover-parity-checklist/` MUST document scope; no product Next route deletion in this slice.
- **FR-009**: Soft guidance never auto-applies and no CLIENT_SECRET in clients MUST appear as non-regression cutover criteria.

### Key Entities

- **ParityRow**: surface/capability id, product reference, Windows/mobile/web status, notes
- **RetirementCriterion (RC-\*)**: id, description, pass condition, evidence, status
- **CutoverVerdict**: PROGRAM_GATE + PRODUCTION_CUTOVER + date + rationale

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Checklist document exists in `docs/` and is linked from the slice roadmap note.
- **SC-002**: Validator test is green (`dart test` on the cutover checklist validator).
- **SC-003**: Dual go/no-go verdicts are explicit in the doc (not implied).
- **SC-004**: P5 program gate is closed in the slice roadmap (DART-049 **done**; Current pointer indicates program complete or no further planned DART slices).
- **SC-005**: No new host feature code beyond docs + validator is required for this slice exit.

## Assumptions

- PRODUCT production nav source of truth is `AppShell` `NAV_LINKS`, not `/debug/*` and not every `src/app/*` folder.
- Closing the **program** gate does **not** automatically retire Next; production cutover is a separate human decision gated by `RC-*`.
- Honest **NO-GO** for production cutover is acceptable and expected if residual gaps remain; the slice still succeeds when the checklist and program gate are correct.
- Domain truth remains DBR/DAC/BR; this checklist does not redefine game rules.
