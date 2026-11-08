# Feature Specification: DART-054 Inventory Live Parity Harness

**Feature Branch**: `dart-054-inventory-live-parity-harness`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Live/manual+tool Next-vs-Dart inventory count harness. GAP-INV-05, PROC-03/04/05. Documented dual-run procedure + optional tool comparing Next vs Dart counts by location/bucket (and raw/stored/resolvedFromTransfer) for same membership; operator/CI gate for future inventory-sync changes; update cutover RC-SYNC to require vault/postmaster fidelity within Next tolerance (or documented residual); inventory fidelity gate separate from pure p0_parity_gate; closes PROC-03; clears RB-06 when combined with DART-050–053 evidence"

**Program ID**: DART-054  
**Phase**: P6  
**Depends**: DART-050–053  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-INV-05**, **PROC-03**, **PROC-04**, **PROC-05**  
**Cutover**: [docs/multiplatform-dart-cutover-parity-checklist.md](../../docs/multiplatform-dart-cutover-parity-checklist.md) — **RC-SYNC**, **RB-06**

## Scope boundary

**In scope:**

- Documented dual-run operator procedure (Next Settings/sync vs Dart Windows Settings/sync) for the **same** Bungie membership
- Canonical **inventory fidelity snapshot** JSON schema covering:
  - raw totals (and optional vault/character raw sub-counts)
  - parsed totals + **byLocation** + **byBucket**
  - dropped totals (unknown/missing)
  - resolution: **resolvedFromTransfer**, **droppedNonEquipment**, **storedTotal**, **storedEquipment**
  - membership identity (type + id) for same-membership checks
- Optional pure-Dart **compare tool** that loads Next snapshot + Dart snapshot and reports diffs with agreed tolerance
- **Operator/CI inventory fidelity gate** (`tool/inventory_fidelity_gate.dart`) **separate** from pure `p0_parity_gate` (PROC-05):
  - fixture compare path always runnable offline
  - procedure doc + schema markers present
  - fails on intentional mismatch fixtures in tests
- Fixture snapshots under `tool/fixtures/inventory_fidelity/` proving pass/fail behavior
- Update cutover **RC-SYNC** pass condition / evidence to require vault/postmaster fidelity metrics (PROC-04) and cite harness
- Clear **RB-06** when DART-050–054 evidence is complete (fidelity program shipped; residual live operator dual-run is evidence attachment, not a missing product feature)
- Close **GAP-INV-05**, **PROC-03**; advance **PROC-04**/**PROC-05** to closed
- Soft never auto-applies; no CLIENT_SECRET; no Node sidecar

**Out of scope (do not implement in this slice):**

- Live Bungie network calls inside CI (no secrets, no account tokens in gate)
- New vault resolution algorithm (DART-050 done)
- Roll tags / sockets / diagnostics UI (DART-051–053 done)
- Full Jaspr inventory sync depth (DART-056 / RB-02)
- Auto-export UI button in Settings hosts (optional future; operator may hand-write or paste JSON from diagnostics)
- Changing pure domain / `p0_parity_gate` graph rules
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / Node sidecar

## Assumptions

- **A1**: Agreed default **Next tolerance** is **exact match** (delta 0) on all compared scalar counts and on each `byLocation` / `byBucket` key present in either snapshot, unless a residual is documented in the compare report / gaps doc. Operators may pass `--tolerance N` only for exploratory dual-runs; CI fixtures use tolerance 0.
- **A2**: Snapshots are produced offline (hand-authored fixtures, or operator paste from Next console log / Dart `formatSyncDiagnostics` + host diagnostics fields). Tool does not call Bungie APIs.
- **A3**: Same-membership dual-run means matching `membershipType` + `membershipId` (when both present); empty membership on fixtures is allowed only for pure schema unit fixtures.
- **A4**: Clearing RB-06 means the **inventory fidelity program** (vault lookup, roll tags, sockets, diagnostics, harness) is shipped; PRODUCTION_CUTOVER remains NO-GO while other RBs (e.g. RB-02 web depth) remain. RC-SYNC may still FAIL solely for web depth until DART-056.
- **A5**: Soft never auto-applies; no confidential secrets in clients or harness fixtures.
- **A6**: `byBucket` keys are stringified bucket hashes (Next + Dart parity); missing keys treat as 0 when the other side has a key (diff reported).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dual-run procedure is documented (Priority: P1)

As a multiplatform engineer, I follow an in-repo procedure to sync inventory on Next and Dart for the same membership, capture count snapshots, and compare them by location/bucket and resolution metrics.

**Why this priority**: GAP-INV-05 / PROC-03 core — without a written dual-run path, live drift stays ad-hoc.

**Independent Test**: Doc `docs/multiplatform-dart-inventory-live-parity-harness.md` exists with dual-run steps, snapshot schema, tolerance policy, and how to run the compare tool / fidelity gate.

**Acceptance Scenarios**:

1. **Given** the multiplatform worktree, **When** an operator opens the harness doc, **Then** steps cover: same membership, Next sync, Dart Windows Settings sync, capture raw/parsed/byLocation/byBucket/resolution fields, run compare tool, interpret pass/fail.
2. **Given** the harness doc, **When** reading gate policy, **Then** it states inventory fidelity is **separate** from `dart run tool/p0_parity_gate.dart` (PROC-05).
3. **Given** residual thinning is intentional, **When** operator documents it, **Then** procedure points to opening/updating a GAP/RB residual (PROC-06 style) rather than forcing a green compare.

---

### User Story 2 - Compare tool reports Next vs Dart count parity (Priority: P1)

As an engineer, I run a pure Dart tool with two JSON snapshots and get a structured report of mismatches for totals, byLocation, byBucket, and resolution (resolvedFromTransfer / storedTotal / etc.).

**Why this priority**: Exit criteria — optional tool comparing counts for same membership.

**Independent Test**: Unit tests with matching fixtures pass; mismatch fixtures fail with named field paths; CLI exits 0/1 accordingly.

**Acceptance Scenarios**:

1. **Given** two snapshots with identical counts and same membership, **When** compare runs at tolerance 0, **Then** result is pass with empty diffs.
2. **Given** Dart `resolvedFromTransfer` lower than Next by more than tolerance, **When** compare runs, **Then** fail reports path `resolution.resolvedFromTransfer` with both values.
3. **Given** `byLocation.vault` differs, **When** compare runs, **Then** fail reports that location key.
4. **Given** membership ids differ, **When** compare runs, **Then** fail reports membership mismatch (even if counts match).
5. **Given** one snapshot omits `resolution`, **When** the other has resolution, **Then** fail unless both omit (resolution optional only if both absent).

---

### User Story 3 - Inventory fidelity gate is CI-runnable offline (Priority: P1)

As CI / pre-merge, I run an inventory fidelity gate that does not require live Bungie tokens, does not depend on `p0_parity_gate`, and fails if fixtures or procedure markers regress.

**Why this priority**: PROC-03 operator/CI gate; PROC-05 separation.

**Independent Test**: `dart run tool/inventory_fidelity_gate.dart` exits 0 on workspace; tests cover gate structure + fixture compare; gate does not invoke pure domain suite.

**Acceptance Scenarios**:

1. **Given** a clean worktree with fixtures + doc, **When** fidelity gate runs, **Then** exit 0 and prints that inventory fidelity fixture compare passed.
2. **Given** procedure doc missing required markers, **When** gate runs, **Then** exit non-zero.
3. **Given** matching fixture pair, **When** gate compare step runs, **Then** pass; deliberately broken pair used only in unit tests (not as gate inputs).
4. **Given** `p0_parity_gate` is green with empty lookup historically, **When** reading docs, **Then** fidelity gate is named as the inventory parity claim gate (PROC-05).

---

### User Story 4 - RC-SYNC / RB-06 / process gaps updated (Priority: P1)

As a cutover reviewer, I see RC-SYNC require vault/postmaster fidelity evidence (not only “sync card exists”), RB-06 cleared for the fidelity program with DART-050–054 evidence, and GAP-INV-05 / PROC-03 closed.

**Why this priority**: PROC-04 + cutover exit; clears RB-06 with 050–053 evidence + harness.

**Independent Test**: Checklist/gaps doc greps; cutover validator still green.

**Acceptance Scenarios**:

1. **Given** updated cutover checklist, **When** reading RC-SYNC, **Then** pass condition requires fidelity metrics / harness evidence; evidence pointer includes inventory live parity harness doc + DART-050–054.
2. **Given** DART-050–054 merged, **When** residual blockers table is read, **Then** RB-06 is **cleared** (or struck with note) and RC-SYNC remaining FAIL (if any) cites RB-02 web depth only — not vault unwired.
3. **Given** feature-gaps catalog, **When** GAP-INV-05 and PROC-03 rows are read, **Then** status is **closed**; PROC-04/PROC-05 closed or advanced with fidelity gate reference.

---

### Edge Cases

- Empty inventories (all zeros) still compare successfully if both sides match.
- Extra `byBucket` keys on one side only count as diffs (missing = 0).
- Malformed JSON → tool exits non-zero with parse error (no silent pass).
- Tolerance > 0 allows absolute delta ≤ N per scalar field (exploratory only; not default CI).
- Snapshot without membership fields: membership check skipped only if **both** omit id; otherwise fail.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide `docs/multiplatform-dart-inventory-live-parity-harness.md` documenting dual-run procedure, snapshot schema, tolerance, and gate commands.
- **FR-002**: System MUST define a JSON snapshot shape covering membership, raw, parsed (incl. byLocation/byBucket), dropped, and resolution counts.
- **FR-003**: System MUST provide a pure Dart compare library + CLI (`tool/inventory_fidelity_compare.dart`) that diffs two snapshots and exits 0 only when within tolerance.
- **FR-004**: System MUST provide `tool/inventory_fidelity_gate.dart` that validates procedure doc markers + runs fixture compare offline, separate from `p0_parity_gate`.
- **FR-005**: System MUST ship matching fixture pair under `tool/fixtures/inventory_fidelity/` used by the gate.
- **FR-006**: Unit tests MUST cover match, mismatch (location/bucket/resolution/membership), and gate structural checks.
- **FR-007**: Cutover checklist MUST update RC-SYNC evidence / RB-06 for DART-054 completion; feature-gaps MUST close GAP-INV-05 and PROC-03 and advance PROC-04/05.
- **FR-008**: Soft guidance MUST never auto-apply; harness MUST NOT embed CLIENT_SECRET or live tokens.

### Key Entities

- **InventoryFidelitySnapshot**: Portable count snapshot for one membership after one sync (Next or Dart).
- **InventoryFidelityDiff**: Named field path + left/right values + absolute delta.
- **InventoryFidelityCompareResult**: pass/fail, diffs list, tolerance used, membership check outcome.
- **InventoryFidelityGate**: Offline CI/operator gate (doc markers + fixture compare).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operator can complete dual-run documentation path without inventing schema fields (all fields listed in doc + fixtures).
- **SC-002**: `dart test tool/test/inventory_fidelity_*.dart` is green; matching fixtures pass; mismatch fixtures fail with expected paths.
- **SC-003**: `dart run tool/inventory_fidelity_gate.dart` exits 0 on the worktree.
- **SC-004**: GAP-INV-05 and PROC-03 are **closed**; RB-06 cleared with DART-050–054 evidence; RC-SYNC no longer cites vault-unwired RB-06 as the sole fidelity blocker (web RB-02 may remain).
- **SC-005**: Docs state inventory fidelity gate ≠ `p0_parity_gate` (PROC-05).

## Assumptions

See **Assumptions** above (A1–A6).
