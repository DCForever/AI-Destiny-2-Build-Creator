# Feature Specification: DART-057 Mobile Compose / Equip Polish

**Feature Branch**: `dart-057-mobile-compose-equip-polish`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Mobile surface matrix; equip/catalog as product requires; Jaspr soft-stat editor; finish-gaps host UX. GAP-MOB-01, GAP-UI-01, GAP-FEAT-06; GAP-FEAT-01 deferred."

**Program ID**: DART-057  
**Phase**: P7  
**Depends**: DART-041 (mobile compose), DART-050 (vault), DART-007 (pure finish gaps), DART-034/046 (soft guidance hosts), DART-038/039/047 (equip/DIM hosts)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-MOB-01**, **GAP-UI-01**, **GAP-FEAT-06**; **GAP-FEAT-01** deferred  

## Scope boundary

**In scope:**

- Published **mobile surface matrix** (PASS / PARTIAL / MISS / N/A / deferred) for AppShell keys: build, synergy, sets, catalog, settings, loadouts + equip, DIM, optimizer
- Product decisions for mobile equip/catalog/DIM: **N/A** (OAuth + inventory sync + write clients not on mobile yet; desktop/web remain equip paths)
- `shell_nav` tests match matrix destinations (Builds | Settings only; no extra destinations without matrix update)
- Mobile Settings surfaces matrix summary so product thinning is explicit in UX
- **Jaspr** soft-stat editor: all `ArmorStatName` fields with explicit save parity to Windows (not Health-only)
- **Finish-gaps host UX** on at least one production host (Windows **and** Jaspr): call pure `evaluateFinishGaps`; show category complete reasons; equip/export CTA policy = **finish-complete AND equip-ready**
- Host tests for finish-gap display + CTA policy helpers; pure domain remains shared (`packages/domain`)
- Docs: close GAP-MOB-01 / GAP-UI-01 / GAP-FEAT-06; keep GAP-FEAT-01 deferred
- Soft never auto-applies; no CLIENT_SECRET; no Node sidecar

**Out of scope (do not implement in this slice):**

- Mobile OAuth / inventory sync / live equip / DIM jsonOnly on phone (matrix N/A → later auth slice DART-058+)
- Mobile catalog browse destination
- Mobile top-level Synergy / Sets / Loadouts nav (compose still reaches attach/designate)
- Armor optimizer on mobile/web (**GAP-FEAT-01** deferred unless elevated)
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / confidential cookie parity
- Node sidecar
- DART-058+ slices

## Assumptions

- **A1**: Phone density keeps bottom nav **Builds | Settings** only. Synergy/sets/loadouts/catalog are **N/A** at top-level nav because compose still designates synergy on create and attaches sets on detail (DART-041). Catalog/equip/DIM require OAuth + inventory depth not present on mobile → **N/A** with explicit matrix + Settings note (not silent MISS).
- **A2**: Finish-gaps host wiring targets **Windows Flutter** and **Jaspr web** as production hosts. Mobile may show finish-gap **display** on compose detail for parity chips but does not ship equip CTAs.
- **A3**: Equip/export CTA policy matches Next Finish intent: enabled only when `finishGaps.complete && equipReady` (plus existing signed-in / character / idle gates). Soft warnings never gate hard.
- **A4**: Soft-stat save remains explicit button; never written by coverage evaluation.
- **A5**: Optimizer mobile/web remains deferred (GAP-FEAT-01).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mobile surface matrix published + nav locked (Priority: P1)

As a cutover reviewer or mobile user, I see a published matrix of which AppShell surfaces ship on phone (PASS/PARTIAL/N/A/deferred). Bottom nav only exposes destinations that the matrix marks as shipped (Builds + Settings). Equip/catalog/DIM are explicitly N/A with reason (not accidental MISS).

**Why this priority**: GAP-MOB-01 exit; shell_nav must match matrix.

**Independent Test**: Unit/widget tests assert matrix keys + nav destination keys; Settings shows matrix card.

**Acceptance Scenarios**:

1. **Given** the mobile matrix Dart source, **When** keys are listed, **Then** build/synergy/sets/catalog/settings/loadouts/equip/dim/optimizer each have a status in {pass, partial, miss, na, deferred}.
2. **Given** the matrix, **When** bottom-nav destinations are derived, **Then** only Builds and Settings appear (build PASS, settings PARTIAL).
3. **Given** mobile shell, **When** shell_nav test runs, **Then** nav switches Builds ↔ Settings and does not require Catalog/Equip destinations.
4. **Given** Settings page, **When** rendered, **Then** a surface-matrix summary is visible with equip/DIM N/A notes.

---

### User Story 2 - Jaspr full soft-stat editor (Priority: P1)

As a Guardian on Jaspr web, I can set soft targets for **all** Armor 3.0 stats (Health, Melee, Grenade, Super, Class, Weapons), save explicitly, and see the saved summary — same parity as Windows.

**Why this priority**: GAP-UI-01 exit.

**Independent Test**: Compose page / format tests cover multi-stat field map save; soft never auto-applies.

**Acceptance Scenarios**:

1. **Given** an open build on Jaspr, **When** soft-stat section renders, **Then** each `ArmorStatName` has an input (`data-testid` soft-stat-{wire}).
2. **Given** filled multi-stat fields, **When** Save soft targets is pressed, **Then** controller persists normalized targets and summary lists all saved stats.
3. **Given** soft coverage evaluation, **When** it runs, **Then** it does not write soft-stat targets (save remains explicit).

---

### User Story 3 - Finish-gaps host UX + CTA policy (Priority: P1)

As a Guardian finishing a build on Windows or Jaspr, I see armor/weapon/mod finish categories with complete reasons (satisfied / needs set / needs fill / capture available). Equip Apply and DIM Copy stay disabled until **finish is complete AND equip-ready**.

**Why this priority**: GAP-FEAT-06 residual host wiring.

**Independent Test**: Format unit tests + host tests with incomplete finish assert CTA false; complete+ready assert true; pure `evaluateFinishGaps` still package-tested.

**Acceptance Scenarios**:

1. **Given** a selected variant with no armor set, **When** finish gaps evaluate, **Then** armor status is needs_set (or equivalent display) and complete is false.
2. **Given** finish incomplete, **When** equip-ready is true, **Then** Apply/Copy CTAs remain disabled (finish-complete AND equip-ready policy).
3. **Given** finish complete and equip-ready (and signed-in character for equip), **When** CTAs evaluate, **Then** they may enable per existing idle/sign-in gates.
4. **Given** host UI, **When** finish panel renders, **Then** category rows and complete summary are visible; soft never auto-applies.

---

### Edge Cases

- No selected variant → finish panel empty / N/A; equip/DIM unbound
- Snapshot attachments still cover finish categories when set type matches
- Mod category: set **or** hasModCoverage satisfies
- Soft-stat invalid range → save error, no silent clamp write of out-of-range without normalize path
- Mobile matrix update requires shell_nav test update (single source of truth)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST publish a mobile surface matrix covering build, synergy, sets, catalog, settings, loadouts, equip, dim, optimizer with PASS/PARTIAL/MISS/N/A/deferred.
- **FR-002**: Mobile bottom nav MUST only include destinations consistent with the matrix (Builds + Settings for this slice).
- **FR-003**: Mobile Settings MUST surface the matrix (or summary) so equip/catalog/DIM N/A is product-visible.
- **FR-004**: Jaspr soft-stat editor MUST expose all `ArmorStatName` fields with explicit save parity to Windows.
- **FR-005**: At least Windows and Jaspr hosts MUST evaluate finish gaps via pure `evaluateFinishGaps` from compose attachments + equipment claims.
- **FR-006**: Hosts MUST display per-category finish status and overall complete flag.
- **FR-007**: Equip Apply and DIM Copy CTAs on those hosts MUST require finish-complete **and** equip-ready (plus existing gates).
- **FR-008**: Soft guidance MUST never auto-apply; soft-stat targets change only on explicit save.
- **FR-009**: No CLIENT_SECRET in mobile/web/windows client artifacts for this slice.
- **FR-010**: Optimizer on mobile/web remains deferred (GAP-FEAT-01); matrix marks deferred.

### Key Entities

- **MobileSurfaceEntry**: key, status, product note
- **FinishGapsResult** (domain): complete, gaps[], nextActionable
- **SoftStatTargets** (domain): map of ArmorStatName → int

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Mobile matrix document + Dart source list 9 surfaces with statuses; shell_nav tests green and match nav keys.
- **SC-002**: Jaspr soft-stat section has 6 stat fields; multi-stat save test green.
- **SC-003**: Windows + Jaspr host tests assert finish-gap rows and CTA false when finish incomplete.
- **SC-004**: Feature-gaps GAP-MOB-01, GAP-UI-01, GAP-FEAT-06 closed with evidence; GAP-FEAT-01 still deferred.
- **SC-005**: Soft never auto-applies language retained in soft advisory captions.

## Assumptions (product defaults)

See **Assumptions** above (A1–A5). No remaining NEEDS CLARIFICATION for this slice.
