# Feature Specification: DART-055 In-Game Loadouts Surface

**Feature Branch**: `dart-055-in-game-loadouts-surface`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "First-class Loadouts UI (Windows first) or product demote. GAP-NAV-01; RB-01 / RC-NAV. First-class Loadouts UI reachable from primary shell nav on Windows (and plan/route for Jaspr) listing Bungie in-game loadouts comparable to product /loadouts, or product removes/demotes loadouts from AppShell NAV_LINKS with explicit PRODUCT note; host greps for nav labels/routes include Loadouts; cutover matrix loadouts row PASS or N/A; clears RB-01/RC-NAV when done"

**Program ID**: DART-055  
**Phase**: P7  
**Depends**: DART-024 (profile path)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-NAV-01**  
**Cutover**: [docs/multiplatform-dart-cutover-parity-checklist.md](../../docs/multiplatform-dart-cutover-parity-checklist.md) — **RB-01** / **RC-NAV**

## Scope boundary

**In scope:**

- Pure Dart parse of Bungie GetProfile **component 206** (`characterLoadouts`) into in-game loadout rows (parity with Next `parseCharacterLoadoutsResponse`)
- Presentation resolve (icon/color/name hashes → paths/CDN URLs) via optional `DestinyLoadout*Definition` tables already in `downloadRawTables`
- `BungieProfileClient` API to fetch characters + loadouts (`components=200,206`)
- **Windows** primary shell nav destination **Loadouts** → first-class page listing Bungie in-game loadouts (name, class, light, slot index, empty flag, item count; icon/color when tables available)
- Filters: class (Titan/Hunter/Warlock), hide empty (product default hide empty)
- Refresh from profile when signed in; signed-out empty/gate UX
- **Jaspr**: primary shell nav + `/loadouts` route + page listing loadouts (or signed-out gate) using same pure parse
- Host tests/greps: nav labels include Loadouts; routes include loadouts path
- Cutover matrix `loadouts` row → **PASS** on Windows + web; clear **RB-01**; **RC-NAV** no longer fails solely for loadouts MISS
- Close **GAP-NAV-01**
- Soft never auto-applies; no CLIENT_SECRET; no Node sidecar

**Out of scope (do not implement in this slice):**

- Local Next `loadouts` library snapshots (generated build sheets) as primary surface — product page is Bungie-first; local snapshots deferred
- LoadoutDiscoveryOverlay / exotic filter bar for local rows
- Mobile bottom-nav Loadouts (mobile reduced nav remains Builds|Settings; matrix may stay MISS/N/A for phone density per RC-NAV note)
- Equip / apply in-game loadout to character (write API)
- dim.gg / DIM import of in-game loadouts
- Product demote of AppShell `NAV_LINKS` loadouts (alternative exit — **not** chosen; we ship UI)
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / Node sidecar
- DART-056+ slices

## Assumptions

- **A1**: Exit path is **ship first-class Loadouts UI**, not product demote.
- **A2**: "Comparable to product `/loadouts`" means list Bungie character loadout slots with resolved name/class/light/index/empty/item counts and presentation icon/color when raw tables exist; exotic armor/weapon enrichment and linked-build matching are **optional polish** (may be null/omitted without failing exit).
- **A3**: Windows uses Public+PKCE session tokens + profile client; presentation tables loaded from StorageRoot raw tables when cached version exists, else fallback names (`Loadout N`).
- **A4**: Jaspr uses same pure parse; presentation may thin to fallback names when entity bundles omit Loadout* defs (documented residual if needed — not a cutover block if list + nav exist).
- **A5**: Mobile top-level Loadouts remains out of scope; RC-NAV production targets are Windows + Jaspr only.
- **A6**: Soft never auto-applies; no confidential secrets in clients.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pure parse of component 206 (Priority: P1)

As a multiplatform engineer, I parse GetProfile `characterLoadouts` into stable loadout rows with presentation resolve, matching Next fixtures.

**Why this priority**: Shared pure layer; host UI depends on it.

**Independent Test**: `dart test packages/bungie` loadout parse suite green against fixture parity.

**Acceptance Scenarios**:

1. **Given** a component-206 payload with two slots (one filled, one empty) and presentation tables, **When** parse runs with a Titan character, **Then** rows have ids `charId:index`, resolved name for filled slot, fallback `Loadout 2` for empty, `empty` flags correct, instance ids filter out `"0"`.
2. **Given** missing `characterLoadouts.data`, **When** parse runs, **Then** empty list (no throw).
3. **Given** presentation tables empty, **When** resolve runs, **Then** fallback name used and icon/color URLs null.

---

### User Story 2 - Windows primary nav Loadouts surface (Priority: P1)

As a Windows user signed in with Bungie, I open **Loadouts** from the primary NavigationRail and see my in-game loadout slots listed, with class/hide-empty filters and refresh.

**Why this priority**: GAP-NAV-01 / RB-01 Windows PASS.

**Independent Test**: Widget tests assert nav label Loadouts, page keys, signed-out gate, fixture list after load.

**Acceptance Scenarios**:

1. **Given** Windows host shell, **When** nav destinations are inspected, **Then** a destination labeled **Loadouts** exists and selecting it shows the Loadouts page.
2. **Given** signed-out session, **When** Loadouts page opens, **Then** empty/sign-in gate is shown (no crash).
3. **Given** signed-in session and profile client returns loadouts, **When** page loads or Refresh is pressed, **Then** list shows loadout names, class, light, slot, empty badge / item count.
4. **Given** hide-empty on (default), **When** empty slots exist, **Then** they are hidden until the user shows empty.

---

### User Story 3 - Jaspr /loadouts route (Priority: P1)

As a web user, I reach **Loadouts** from the shell header and `/loadouts` route and see the same list model (or sign-in gate).

**Why this priority**: Exit criteria plan/route for Jaspr; RC-NAV web PASS for loadouts.

**Independent Test**: ShellHeader routes include Loadouts/`/loadouts`; page tests for gate/list.

**Acceptance Scenarios**:

1. **Given** ShellHeader routes, **When** labels/paths are read, **Then** Loadouts and `/loadouts` are present.
2. **Given** Router with `/loadouts`, **When** page renders without session, **Then** sign-in gate copy is shown.
3. **Given** controller with fixture loadouts, **When** page renders, **Then** loadout names appear.

---

### User Story 4 - Cutover / gaps docs (Priority: P1)

As a cutover reviewer, I see loadouts matrix PASS (Windows + web), RB-01 cleared, RC-NAV no longer fails solely for loadouts, GAP-NAV-01 closed.

**Why this priority**: Exit criteria for RB-01/RC-NAV.

**Independent Test**: Doc greps + cutover validator green.

**Acceptance Scenarios**:

1. **Given** cutover checklist, **When** loadouts row is read, **Then** Windows and Jaspr are **PASS** (mobile may remain MISS/N/A).
2. **Given** residual blockers, **When** RB-01 is read, **Then** cleared with DART-055 evidence.
3. **Given** RC-NAV, **When** status is read, **Then** not FAIL solely for loadouts MISS (other RBs may still block PRODUCTION_CUTOVER).

---

### Edge Cases

- No Destiny memberships → empty list + error/hint message, not crash
- Manifest presentation tables missing → fallback names; list still works
- Character in loadouts data without matching character summary → skip those slots
- Concurrent refresh while loading → single in-flight or last-write-wins; no double error toast required
- Soft guidance never auto-applies from this surface

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST parse Bungie `characterLoadouts` (component 206) into `BungieInGameLoadout` rows with stable `characterId:index` ids in pure Dart.
- **FR-002**: System MUST resolve loadout icon/color/name presentation when presentation tables are provided; otherwise use fallback names.
- **FR-003**: `BungieProfileClient` MUST support fetching a profile payload including components 200+206 (characters + loadouts).
- **FR-004**: Windows primary NavigationRail MUST include a **Loadouts** destination that opens a first-class Loadouts page.
- **FR-005**: Windows Loadouts page MUST list in-game loadouts for the signed-in user (or show signed-out gate) comparable to product `/loadouts` Bungie section.
- **FR-006**: Loadouts UI MUST support class filter and hide-empty toggle (default hide empty true).
- **FR-007**: Jaspr ShellHeader and Router MUST expose `/loadouts` with a Loadouts page using the same list model.
- **FR-008**: Host tests MUST assert nav labels/routes include Loadouts (Windows + web).
- **FR-009**: Cutover matrix and gaps docs MUST mark loadouts PASS / GAP-NAV-01 closed / RB-01 cleared when implementation lands.
- **FR-010**: Soft guidance MUST NOT auto-apply; clients MUST NOT embed CLIENT_SECRET.

### Key Entities

- **BungieInGameLoadout**: id, characterId, className, characterLight, index, name, icon/color/name hashes + paths/URLs, itemInstanceIds, empty
- **LoadoutPresentationTables**: icons/colors/names hash maps
- **LoadoutsController** (host): load/refresh state, filters, error/hint

## Success Criteria *(mandatory)*

- **SC-001**: `dart test packages/bungie` includes green loadout parse tests.
- **SC-002**: Windows host greps/tests find nav label Loadouts and loadouts page surface.
- **SC-003**: Jaspr shell greps/tests find Loadouts + `/loadouts`.
- **SC-004**: Cutover `loadouts` row PASS for Windows and web; RB-01 cleared; GAP-NAV-01 closed.
- **SC-005**: Merged to `feature/multiplatform-dart`; roadmap DART-055 **done**.
