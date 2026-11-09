# Feature Specification: DART-068 Presentation Shell / Loadouts / Settings Chrome

**Feature Branch**: `dart-068-presentation-shell-loadouts-settings`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Shell labels; icons/meta; loadouts density; Settings chrome; designation icons. Exit: GAP-UI-CATALOG-09; GAP-UI-BUILD-06; GAP-UI-SYN-05; GAP-UI-LOADOUTS-01..03; GAP-UI-SETTINGS-01, 02; GAP-UI-SHELL-01. AppShell label/order parity; item icons + dense meta on catalog/set-fill; loadout color bar/swatch + exotic names + details expand; Settings READY/entity chips + inventory ONLINE/Refresh chrome; designation icons; variant read-only icon overview. Not cutover re-gate. Soft never auto-applies; no CLIENT_SECRET."

**Program ID**: DART-068  
**Phase**: P9  
**Depends**: DART-062+ as needed  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-UI-CATALOG-09; GAP-UI-BUILD-06; GAP-UI-SYN-05; GAP-UI-LOADOUTS-01..03; GAP-UI-SETTINGS-01, 02; GAP-UI-SHELL-01**  
**Fidelity**: [docs/multiplatform-dart-ui-fidelity.md](../../docs/multiplatform-dart-ui-fidelity.md)

## Scope boundary

**In scope:**

- **AppShell label/order parity** (Windows NavigationRail + Jaspr ShellHeader): product short labels **Loadouts, Build, Synergy, Sets, Catalog, Settings** (GAP-UI-SHELL-01)
- **Item icons + dense meta** on catalog and set-fill/picker rows when `CatalogItem.icon` and facets present (GAP-UI-CATALOG-09)
- **Variant read-only icon overview** strip with empty/wishlist labels without requiring Edit (GAP-UI-BUILD-06)
- **DesignationLabel chrome**: Verb:/Element: human labels + element/verb icon chrome when available (GAP-UI-SYN-05)
- **Loadouts density**: color bar + swatch + icon plate when colorUrl/iconUrl resolve; exotic armor/weapon names after inventory enrich; Details expand panel (GAP-UI-LOADOUTS-01..03)
- **Settings chrome**: Windows Manifest READY/STALE + entity store count chips; Inventory ONLINE/OFFLINE + human last-sync + Sync inventory + Refresh status (GAP-UI-SETTINGS-01, 02; BUG-20260725-003)
- Soft never auto-applies; no `CLIENT_SECRET`; **not** cutover re-gate

**Out of scope (do not implement in this slice):**

- Production cutover re-gate / RC-* re-run
- Mobile bottom-nav label change (DART-057 matrix stays Builds|Settings)
- Pixel-perfect atlas brand rewrite / full offline designation icon index from raw defs
- Post-sync better-kit banner (closed DART-067)
- Web armor optimizer (GAP-FEAT-01 deferred)
- Next.js product worktree edits

## Assumptions

- **A1**: Product nav **order** is AppShell `NAV_LINKS`: Loadouts → Build → Synergy → Sets → Catalog → Settings. Short labels match product `short` fields (Build/Synergy singular).
- **A2**: Routes/paths stay `/builds`, `/synergies` etc.; only visible labels and destination order change. IndexedStack index mapping updates with order.
- **A3**: Entity icons use Bungie CDN absolute URLs via `bungieContentUrl` when icon path is relative; missing icons show a compact placeholder glyph (not blank crash).
- **A4**: Catalog dense meta chips: Exotic, slot, element, ammo, type/frame when known (no Instance/Wishlist on pure definition rows; owned badge retained separately).
- **A5**: Loadout exotic enrichment uses pure instanceId→hash + exotic catalog index (Next `resolveLoadoutExoticsFromInstances` parity); when inventory or catalog unavailable, names stay null without blocking list.
- **A6**: Designation chrome without full entity icon index: human `Verb: {sub}` / `Element: {sub}` labels + element color token / verb glyph; optional icon URL when subtype matches known element/verb table.
- **A7**: Variant overview is read-only: icons from catalog when resolvable for pin hashes; Empty / Wishlist / Instance labels from pin state.
- **A8**: Manifest READY when entityCache present and not stale; STALE when isStale; NOT DOWNLOADED when no cache; chips from `entityCache.counts`.
- **A9**: Inventory ONLINE when lastFullSyncAt present; OFFLINE otherwise; human last sync matches Next `formatLastSyncLabel` (same-day time, else short datetime).
- **A10**: Soft never auto-applies; pure Dart I/O only; no CLIENT_SECRET.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - AppShell labels and order (Priority: P1)

As a multiplatform user, primary nav shows product labels **Build** and **Synergy** (not Builds/Synergies) and the AppShell order: Loadouts, Build, Synergy, Sets, Catalog, Settings.

**Why this priority**: GAP-UI-SHELL-01; shell tests assert labels.

**Independent Test**: Unit/widget tests on `navLabels` / ShellHeader.routes order and labels.

**Acceptance Scenarios**:

1. **Given** Windows host, **When** shell mounts, **Then** rail labels are Loadouts, Build, Synergy, Sets, Catalog, Settings in that order.
2. **Given** Jaspr shell, **When** header mounts, **Then** nav labels match the same short labels and documented order.
3. **Given** existing page tests, **When** they tap nav by label, **Then** they use Build/Synergy (updated).

---

### User Story 2 - Catalog / set-fill icons + dense meta (Priority: P1)

As a browser of catalog or set-fill pickers, each row shows an item icon when the entity provides an icon path and compact meta chips (element/ammo/slot/exotic) comparable to Next card density.

**Why this priority**: GAP-UI-CATALOG-09; residual after DART-062/063/065.

**Independent Test**: Widget/component tests with CatalogItem.icon + meta fields assert leading icon key and meta chips.

**Acceptance Scenarios**:

1. **Given** a catalog item with icon path, **When** list renders, **Then** row shows resolved icon (or placeholder on load error).
2. **Given** item with element/ammo/exotic, **When** row renders, **Then** dense meta includes those facets as chips/text.
3. **Given** set-fill picker item with icon, **When** picker list renders, **Then** leading uses entity icon not only exotic star.

---

### User Story 3 - Loadouts presentation density (Priority: P1)

As a signed-in user viewing In-Game Loadouts, each Bungie slot shows color bar/swatch and icon plate when URLs resolve; exotic names when inventory enriches; expandable Details for hashes and instance count.

**Why this priority**: GAP-UI-LOADOUTS-01..03.

**Independent Test**: Pure exotic enrich unit tests; host tile tests for color bar key, expand panel, exotic name text.

**Acceptance Scenarios**:

1. **Given** loadout with colorUrl, **When** row paints, **Then** color stripe/swatch is present.
2. **Given** inventory maps instances to exotic hashes, **When** loadouts load, **Then** exoticArmorName/exoticWeaponName appear on the row.
3. **Given** a non-empty slot, **When** user expands Details, **Then** character id, icon/color hashes, larger icon, and instance messaging show; collapse hides them.

---

### User Story 4 - Settings READY + inventory ONLINE chrome (Priority: P1)

As a Windows Settings user, Manifest shows READY/STALE/NOT DOWNLOADED and store count chips; Inventory shows ONLINE/OFFLINE, human last sync, Sync inventory, and Refresh status.

**Why this priority**: GAP-UI-SETTINGS-01/02; BUG-20260725-003.

**Independent Test**: Manifest card tests for badge + chips; inventory card tests for ONLINE key, formatted last sync, both buttons.

**Acceptance Scenarios**:

1. **Given** entityCache present and not stale, **When** Manifest card renders, **Then** READY badge and per-store chips appear.
2. **Given** lastFullSyncAt set, **When** Inventory card renders, **Then** ONLINE chip and human last-sync (not raw ISO alone as primary).
3. **Given** signed-in user, **When** card renders, **Then** Sync inventory + Refresh status are available; signed-out disables with sign-in copy.

---

### User Story 5 - Designation chrome + variant overview (Priority: P2)

As a synergy library user I see Verb:/Element: human labels with icon chrome; as a build user the selected variant shows a read-only loadout icon strip without entering Edit.

**Why this priority**: GAP-UI-SYN-05; GAP-UI-BUILD-06 polish.

**Independent Test**: Pure designation format tests; builds page overview key with pin labels Empty/Wishlist.

**Acceptance Scenarios**:

1. **Given** synergy type verb + subType Scorch, **When** library/detail renders, **Then** label shows Verb: Scorch (not only verb::Scorch).
2. **Given** element Solar designation, **When** rendered, **Then** Element: Solar with element chrome.
3. **Given** selected variant with slot pins, **When** detail shows overview, **Then** icon strip / labels include Wishlist or Instance without Edit.

---

### Edge Cases

- Missing icon path → placeholder; never throws.
- colorUrl null → solid class-tint or neutral stripe, not broken layout.
- Exotic enrich with empty inventory → no crash; names null.
- Manifest no entityCache → NOT DOWNLOADED, no empty chips spam.
- lastFullSyncAt unparseable → Never.
- Mobile nav unchanged (Builds|Settings).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Windows + Jaspr primary nav MUST use product short labels Build/Synergy and AppShell order Loadouts, Build, Synergy, Sets, Catalog, Settings.
- **FR-002**: Catalog and set-fill rows MUST show entity icons when icon path present and dense element/ammo/slot/exotic meta.
- **FR-003**: Loadout rows MUST paint color bar/swatch + icon plate when URLs/paths available.
- **FR-004**: Loadouts MUST enrich exotic armor/weapon names from inventory+catalog when data available.
- **FR-005**: Loadout Details expand MUST show character id, icon/color hashes, larger icon, empty vs instance-count messaging.
- **FR-006**: Windows Manifest panel MUST show readiness badge (READY/STALE/NOT DOWNLOADED) and entity store count chips; Refresh retained.
- **FR-007**: Inventory card MUST show ONLINE/OFFLINE, human last sync, Sync inventory CTA, secondary Refresh status; signed-out copy when disabled.
- **FR-008**: Synergy designation display MUST prefer Verb:/Element: human chrome over raw type::subType wire keys as primary label.
- **FR-009**: Selected variant MUST show read-only loadout overview with icons/labels (empty/wishlist/instance) without requiring Edit.
- **FR-010**: Soft guidance MUST never auto-apply; clients MUST NOT embed CLIENT_SECRET.
- **FR-011**: This slice MUST NOT re-open PRODUCTION_CUTOVER.

### Key Entities

- **BungieInGameLoadout**: iconUrl, colorUrl, exotic* names, itemInstanceIds
- **CatalogItem**: icon, element, ammo, slot, isExotic
- **ManifestStatus / entityCache.counts**: readiness chips
- **Inventory sync status**: lastFullSyncAt, ONLINE/OFFLINE
- **Synergy designation**: type + subType → Verb/Element chrome
- **SlotPinView**: pin detail for overview strip

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: GAP-UI-SHELL-01 closed — nav tests assert product labels + order on Windows + Jaspr.
- **SC-002**: GAP-UI-CATALOG-09 closed — catalog/set-fill show icons + dense meta when data present.
- **SC-003**: GAP-UI-LOADOUTS-01..03 closed — color chrome, exotic names, details expand tested.
- **SC-004**: GAP-UI-SETTINGS-01/02 closed — READY chips + ONLINE/human last sync/Refresh status tested on Windows; Jaspr inventory chrome parity where applicable.
- **SC-005**: GAP-UI-SYN-05 + GAP-UI-BUILD-06 closed — designation chrome + variant overview present.
- **SC-006**: Soft never auto-applies; secret scan remains clean; cutover GO unchanged.

## Assumptions (summary)

See Assumptions A1–A10 above.
