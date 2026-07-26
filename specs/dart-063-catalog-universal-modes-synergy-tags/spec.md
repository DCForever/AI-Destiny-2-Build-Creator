# Feature Specification: DART-063 Catalog Universal Modes, Synergy Tags, Owned Detail

**Feature Branch**: `dart-063-catalog-universal-modes-synergy-tags`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Weapons/Armor/Universal modes; synergy membership + BR-SYN-004 reverse tags; owned instance detail. Exit: GAP-UI-CATALOG-03, 06, 08, 10 and GAP-UI-SYN-03 on Windows+Jaspr. Kind-appropriate facets; Universal Set/Synergy actions only (no Build kit attach); synergy include/exclude + linked tags; reverse tags by-target; human-readable owned perk/trait cards + armor base-stat board when resolvable. Soft never auto-applies; no CLIENT_SECRET. Cutover GO unchanged."

**Program ID**: DART-063  
**Phase**: P9  
**Depends**: DART-062  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-UI-CATALOG-03, 06, 08, 10; GAP-UI-SYN-03**  
**Fidelity**: [docs/multiplatform-dart-ui-fidelity.md](../../docs/multiplatform-dart-ui-fidelity.md)

## Scope boundary

**In scope:**

- **Weapons | Armor | Universal** browse modes on Windows Flutter + Jaspr with kind-appropriate facets (BR-CAT-001/003/009, GAP-UI-CATALOG-10)
- **Universal** mode mixed-kind browse + hit detail **Set / Synergy composition actions only** (no Build kit attach) (BR-CAT-009, GAP-UI-CATALOG-03)
- **Synergy membership** include/exclude filter wired from library synergies onto catalog rows (`linkedSynergyIds`) (BR-CAT-008, GAP-UI-CATALOG-06)
- **BR-SYN-004 reverse tags**: linked library synergies as badges/notes on catalog detail for matching weapon/perk/origin/set-bonus/exotic/artifact targets (GAP-UI-SYN-03)
- **Owned instance detail**: human-readable perk/trait cards when resolvable + armor base-stat board when `statValues` resolvable (BR-CAT-002, DBR-ROLL-010, GAP-UI-CATALOG-08)
- Pure Dart I/O only; soft guidance never auto-applies; no `CLIENT_SECRET`
- **Cutover GO unchanged**

**Out of scope (do not implement in this slice):**

- Synergy catalog picker for evidence links (DART-066 / GAP-UI-SYN-01)
- BR-SYN-012 weapon-perk source labels (DART-066)
- Jaspr synergy dual-pane manage (DART-066 / GAP-UI-SYN-04)
- Sets EoF base-roll board on Sets detail (DART-065 / GAP-UI-SETS-01)
- Item icons + dense meta polish (DART-068 / GAP-UI-CATALOG-09)
- Full Universal Set wizard multi-step replace confirm parity with Next (minimal create + optional add-to-set is enough for exit; open residual if thinned)
- Full InstancePerkGridView socket-column grid fidelity when plugs lack columnKind (show resolvable names; residual when unresolved)
- Production cutover re-gate; mobile catalog (N/A matrix)

## Assumptions

- **A1**: Kind modes filter by `CatalogItem.sourceStore` stems already set by DART-062 projector (`weapons`, `exotic-weapons`, `exotic-armor`, `legendary-armor`, `mods`, `aspects`, `fragments`, `abilities`).
- **A2**: Synergy membership for weapon/armor browse uses **itemHash** links (`weapon`, `exotic_armor`) primarily. Perk/origin/set-bonus reverse tags appear on **detail** via by-target lookup; deep allowlist expansion via perk index is **best-effort residual** if perk→weapon index is unavailable offline (PROC-06 note if thinned).
- **A3**: Universal Set/Synergy actions create library rows via existing use cases (signed-in user required); unsigned users see disabled/plain-language CTA.
- **A4**: Owned detail reads `InventoryItemRecord.socketPlugs`, `plugHashes`, `statValues`, `rollTags` already stored by DART-050–052. Human names require optional `Map<int,String>` plug name resolver when available; otherwise show column labels + hash fallback without inventing names.
- **A5**: Soft never auto-applies; no OAuth/secret work; pure Dart I/O only.
- **A6**: Cutover GO is presentation-only for this slice.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Weapons / Armor / Universal kind modes (Priority: P1)

As a Windows or Jaspr user, I switch Catalog between Weapons, Armor, and Universal. Each mode shows kind-appropriate results and facets (weapon slots/ammo/archetypes vs armor slots/class; Universal mixed kinds).

**Why this priority**: GAP-UI-CATALOG-10; foundation for Universal actions.

**Independent Test**: Host tests tap mode chips; assert armor-only rows hidden in Weapons; mixed rows visible in Universal; facet rows change.

**Acceptance Scenarios**:

1. **Given** base catalog with weapons + armor + mods, **When** Weapons mode, **Then** only weapon stores appear; armor slots facet is not primary.
2. **Given** same base, **When** Armor mode, **Then** only armor stores; ammo facet not primary.
3. **Given** Universal mode, **Then** mixed kinds appear and free-text search works across them.

---

### User Story 2 - Universal Set / Synergy actions only (Priority: P1)

As a user in Universal mode, selecting a hit shows composition actions for Set and/or Synergy when eligible — never Build kit attach.

**Why this priority**: GAP-UI-CATALOG-03; BR-CAT-009.

**Independent Test**: Pure `hitActions(kind)` tests; host detail asserts Set/Synergy CTAs present and no Build-attach control.

**Acceptance Scenarios**:

1. **Given** Universal weapon hit, **When** detail opens, **Then** Create/Add Set and Create/Add Synergy CTAs available (signed-in).
2. **Given** aspect/fragment hit, **When** detail opens, **Then** no Set action (or disabled) and no Build kit attach.
3. **Given** any mode/detail, **Then** no control labeled as Build kit attach.

---

### User Story 3 - Synergy membership filter + linked tags (Priority: P1)

As a user with library synergies linked to catalog items, I filter include/exclude by synergy membership and see linked synergy tags on detail.

**Why this priority**: GAP-UI-CATALOG-06; BR-CAT-008.

**Independent Test**: Pure annotate + `filterCatalogClient` synergies facet; host cycles synergy chip and asserts row membership.

**Acceptance Scenarios**:

1. **Given** item annotated with synergy id S1, **When** include S1, **Then** only matching rows remain.
2. **Given** exclude S1, **Then** rows with S1 drop.
3. **Given** selected matching item, **Then** detail shows linked synergy name badges.

---

### User Story 4 - BR-SYN-004 reverse tags (Priority: P1)

As a user viewing a catalog item that is a synergy evidence target, I see **all** linked library synergies as tags/notes (multiple allowed).

**Why this priority**: GAP-UI-SYN-03; BR-SYN-004/008.

**Independent Test**: DB reverse-lookup unit tests by itemHash; host detail badges after seed synergies.

**Acceptance Scenarios**:

1. **Given** synergy linked to weapon hash H, **When** catalog selects H, **Then** badge list includes that synergy.
2. **Given** two synergies link the same target, **Then** both badges appear.
3. **Given** no links, **Then** no empty error; zero badges.

---

### User Story 5 - Owned instance human-readable detail (Priority: P2)

As a user selecting an owned definition, instance cards show human-readable perks/traits when resolvable and armor base-stat board when `statValues` present; wishlist/definition-only is clearly unpinned.

**Why this priority**: GAP-UI-CATALOG-08; BR-CAT-002.

**Independent Test**: Pure projection enrichment tests; host/widget asserts perk labels / stat board keys.

**Acceptance Scenarios**:

1. **Given** weapon copy with socketPlugs + name map, **When** projected, **Then** perk/trait cards use display names (not only raw hashes).
2. **Given** armor copy with statValues, **When** projected, **Then** base-stat board shows known armor stats + total when computable.
3. **Given** no owned copies, **Then** panel states wishlist/definition only (unpinned).

---

### Edge Cases

- Unsigned user: synergy filter empty; reverse tags empty; Universal create CTAs disabled with plain language
- Missing socketPlugs / names: show available column labels or hash fallback; never invent perk names
- Missing statValues on armor: show “stats unknown” not fabricated zeros
- Soft suggestions never auto-apply on any catalog path
- No `CLIENT_SECRET` in any host or package change

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hosts MUST provide Weapons | Armor | Universal mode chrome that filters base items by kind-appropriate stores.
- **FR-002**: Facet chrome MUST be kind-appropriate (weapons: weapon slots/ammo/archetypes; armor: armor slots/class/armor archetypes; Universal: broader free-text + mixed results).
- **FR-003**: Universal hit detail MUST offer Set and/or Synergy actions per composition eligibility and MUST NOT offer Build kit attach.
- **FR-004**: System MUST annotate catalog rows with `linkedSynergyIds` from library synergies (itemHash links) and wire include/exclude synergy facet on hosts.
- **FR-005**: Catalog detail MUST show reverse-lookup linked synergy badges for the selected target (BR-SYN-004).
- **FR-006**: Owned instance projections MUST surface resolvable perk/trait presentation and armor base-stat board from stored inventory fields.
- **FR-007**: Soft guidance MUST never auto-apply; no `CLIENT_SECRET`; pure Dart I/O only.
- **FR-008**: PRODUCTION_CUTOVER GO status MUST remain unchanged.

### Non-Functional / Parity

- Exit criteria are parity-specific (modes separate kinds; reverse tags from library; readable plugs/stats when data present), not merely “button works”.
- Intentional thinning residuals documented under PROC-06 when deep perk-index allowlists or full Next wizard UX are deferred.

## Success Criteria

| ID | Criterion | Evidence |
| -- | --------- | -------- |
| SC-01 | GAP-UI-CATALOG-10 closed | Mode tests on Windows+Jaspr |
| SC-02 | GAP-UI-CATALOG-03 closed | Universal actions + no Build attach |
| SC-03 | GAP-UI-CATALOG-06 closed | Synergy facet + linked tags |
| SC-04 | GAP-UI-SYN-03 closed | Reverse tags by-target |
| SC-05 | GAP-UI-CATALOG-08 closed | Readable perks/stats when resolvable |
| SC-06 | Cutover GO unchanged; no CLIENT_SECRET | Docs + scan unchanged |

## Traceability

| Exit / Rule | Implementation |
| ----------- | -------------- |
| GAP-UI-CATALOG-10 | `CatalogBrowseMode` + host mode chips |
| GAP-UI-CATALOG-03 | `composition_kinds` + Universal detail CTAs |
| GAP-UI-CATALOG-06 | annotate linkedSynergyIds + host synergy facet |
| GAP-UI-SYN-03 | `findSynergiesByTarget` / by itemHash + detail badges |
| GAP-UI-CATALOG-08 | enriched `CatalogInstanceProjection` + host cards |
| BR-CAT-009 / BR-SYN-004 / BR-CAT-008 | US1–4 |

## Out of scope residuals (PROC-06)

| Residual | Track |
| -------- | ----- |
| Perk-index deep synergy allowlists (weapon from perk links) | optional later; itemHash primary |
| Full Next Universal set wizard replace confirm | DART-065 adjacent |
| Icons/dense meta | DART-068 |
| Synergy evidence picker / manage | DART-066 |
