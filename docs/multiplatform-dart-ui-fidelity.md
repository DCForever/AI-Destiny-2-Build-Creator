# Multiplatform Dart ΓÇö UI Fidelity Master (host presentation vs Next atlas)

**Status:** active planning artifact  
**Updated:** 2026-07-25 (postΓÇôPRODUCTION_CUTOVER GO residual audit; DART-062+ reserved)  
**Workstream:** DART (parallel to product Spec Kit `0NN`)  
**Integration base:** `feature/multiplatform-dart`  
**Worktree:** `F:\Destiny2BuildCreator-multiplatform-dart`  
**Atlas root (read-only reference):** `F:/Destiny2BuildCreator/docs/atlas`  
**Product root (Next reference only ΓÇö do not edit from this worktree for fidelity planning):** `F:/Destiny2BuildCreator`

**Related**

| Doc | Role |
| --- | ---- |
| [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md) | FEAT inventory + GAP ledger (includes GAP-UI-* rows) |
| [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md) | Spec Kit slice backlog (DART-062+) |
| [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) | **PRODUCTION_CUTOVER** gate (distinct; GO unchanged by this doc) |
| [ui-polish-tracker.md](./ui-polish-tracker.md) | Pure visual density only (not domain/rule misses) |
| Product domain specs | `specs/domain-business-rules.md` (DBR-*), `specs/domain-acceptance-criteria.md` (DAC-*), `specs/business-rules.md` (BR-*) |

---

## 1. Purpose

This document is the **canonical host UI fidelity residual ledger** after cutover spine work.

| Track | Question it answers | Gate impact |
| ----- | ------------------- | ----------- |
| **PRODUCTION_CUTOVER** (checklist) | Can multiplatform own production composeΓåÆequip nav/sync/auth without Next as sole host? | **GO** (DART-061, 2026-07-25). Unchanged by this fidelity program. |
| **UI fidelity** (this doc) | Do Windows + Jaspr host **presentation and browse/composition density** match Next atlas + BR/DAC/DBR surface rules? | **Does not re-open cutover.** Missed BRs/DACs remain product residual even when FEAT cutover was PASS. |

**FEAT cutover PASS does not override missed BRs/DACs.** Several FEAT rows stay **cutover-PASS** on destination presence while host chrome lags atlas; those FEATs are demoted to **PARTIAL** here and in the feature-gaps inventory for **fidelity** status (not cutover re-gate).

**Hard non-regressions (all fidelity slices):**

- Soft guidance **never auto-applies** (`PRODUCT-SOFT-NEVER-AUTO`).
- No `CLIENT_SECRET` / `SESSION_SECRET` in Flutter/Jaspr clients.
- Domain hard evaluators remain authoritative on save/attach.

---

## 2. Atlas path & shells

| Item | Value |
| ---- | ----- |
| Atlas root | `F:/Destiny2BuildCreator/docs/atlas` (README, manifest v3, screenshots/) |
| Primary shells in scope | **windows** (`apps/windows_host`), **jaspr** (`apps/web_host`) |
| Mobile | Density N/A / matrix-acceptable unless a GAP explicitly lists mobile |
| Reference product | Next AppShell + surface pages under product root (read-only for this program) |

Screen IDs cited below are atlas `screen_id` values (e.g. `catalog-filters-open`, `build-edit-finish`, `sets-detail`).

---

## 3. Summary (2026-07-25 residual audit)

UI fidelity residual audit after **PRODUCTION_CUTOVER: GO** (DART-061). Windows+Jaspr host spines for nav/compose/equip/sync **PASS cutover**, but host presentation trails Next atlas on domain browse/composition density.

| Priority | Themes |
| -------- | ------ |
| **P1** | Catalog multi-facet / group-by / Universal + exotic/legendary defs + synergy tags; Build DBR-ID-008 confirm/fork + subclass kit; Sets EoF base-roll board + dense rows + slot-fill; Synergy catalog picker + BR-SYN-004 reverse tags + Jaspr manage |
| **P2** | Alpha sort, instance detail, Finish walkthrough residual, armor improve not on Build Finish, Sets library chrome, Loadouts density, Settings chrome, shell labels/icons |
| **N/A** | Analyze / debug / LLM (non-goals) |
| **Bugs** | **BUG-20260725-003** lifecycle only ΓåÆ **GAP-UI-SETTINGS-02** |
| **Next free slice** | **DART-064** |
| **Cutover** | **Not reopened** |

---

## 4. FEAT adjustments (fidelity status vs cutover)

Cutover destination presence remains valid. Fidelity status below is what agents use for residual work. **Cutover GO unchanged.**

| FEAT ID | Cutover-era | Fidelity status | Reason |
| ------- | ----------- | --------------- | ------ |
| **FEAT-NAV-CATALOG** | PASS | **PARTIAL** | DART-062/063 closed multi-facet/group-by/Universal/synergy tags/owned detail; icons/dense meta residual (GAP-UI-CATALOG-09 → DART-068). |
| **FEAT-NAV-BUILD** | PASS | **PARTIAL** | Compose spine cutover-PASS; fidelity misses DBR-ID-008 identity confirm/fork and full Subclass kit composer (GAP-UI-BUILD-01/02). |
| **FEAT-NAV-SETS** | PASS | **PARTIAL** | Board + dense rows + catalog fill + library filters/readiness/delete **done** (DART-065/066); shell polish residual → DART-068. |
| **FEAT-NAV-SYNERGY** | PASS | **PARTIAL** | Catalog picker + filters + delete + Jaspr manage **done** (DART-063/066); designation icons residual → DART-068. |
| **FEAT-COMPOSE-IDENTITY** | PASS | **PARTIAL** | Identity fields editable in-place without Confirm/Fork (DBR-ID-008 miss ΓåÆ GAP-UI-BUILD-01); raw hash exotic/super pickers (GAP-UI-BUILD-05). |
| **FEAT-COMPOSE-FINISH** | PASS | **PARTIAL** | finish-gaps panel + equip gates shipped (GAP-FEAT-06 panel closed); full FinishBuildWalkthrough one-tap create/fill residual GAP-UI-BUILD-03; Finish armor improve not on Build path GAP-UI-BUILD-04. |
| **FEAT-COMPOSE-HARD** | PASS | **PARTIAL** | Domain hard constraints authoritative; client pre-block UI thinner than Next (GAP-UI-BUILD-08). |
| **FEAT-INV-OWNED-JOIN** | PASS | **PARTIAL** | Owned scope exists but incomplete defs (legendary-only weapons / exotic-only armor) and raw instance detail reduce owned-join browse fidelity (GAP-UI-CATALOG-04/05/08; GAP-INV-02/03 residual). |
| **FEAT-OPTIMIZER** | PASS (Windows Sets) | **PARTIAL** | Windows Sets optimizer confirm-only PASS; not wired into Build Finish (GAP-UI-BUILD-04) or Settings post-sync (GAP-UI-SETTINGS-04); web/mobile remain GAP-FEAT-01 deferred. |
| **FEAT-NAV-LOADOUTS** | PASS | **PASS** | DART-055 nav/list/filters/signed-out remain cutover PASS; residuals are P2 density only (color bar, exotic names, expand)ΓÇö**no status demote**. |
| **FEAT-NAV-SETTINGS** | PASS | **PASS** | OAuth Public+PKCE + inventory sync + diagnostics depth remain PASS; residuals are chrome (READY chips, ONLINE labels, post-sync soft banner Windows-only)ΓÇö**no status demote**. |

Unlisted FEAT rows keep their feature-gaps inventory status (compose variants/soft, equip, auth, data, ops).

---

## 5. Rules coverage matrix (BR / DAC / DBR + product catalog sort/group)

Verdicts are **host presentation** vs Next atlas + domain specs. Domain packages may already enforce on save; `miss`/`partial` means **UI/host** lag.

### Catalog

| Rule ID | Surface | Verdict | Gap |
| ------- | ------- | ------- | --- |
| DBR-ROLL-010 | catalog | partial | GAP-UI-CATALOG-01 (+04/05/06/08) |
| DAC-NME-003 | catalog | partial | GAP-UI-CATALOG-01 |
| DBR-PUR-002 | catalog | pass | ΓÇö |
| BR-CAT-001 | catalog | miss | GAP-UI-CATALOG-04 |
| BR-CAT-002 | catalog | pass | GAP-UI-CATALOG-08 closed (DART-063) |
| BR-CAT-003 | catalog | miss | GAP-UI-CATALOG-05 |
| BR-CAT-004 | catalog | partial | (facets partial) |
| BR-CAT-005 | catalog | pass | ΓÇö |
| BR-CAT-006 | catalog | partial | GAP-UI-CATALOG-01 |
| BR-CAT-007 | catalog | miss | GAP-UI-CATALOG-02 |
| BR-CAT-008 | catalog | pass | GAP-UI-CATALOG-06 closed (DART-063) |
| BR-CAT-009 | catalog | pass | GAP-UI-CATALOG-03 closed (DART-063) |
| PRODUCT-CAT-ALPHA-SORT | catalog | miss | GAP-UI-CATALOG-07 |
| PRODUCT-CAT-GROUP-SORT | catalog | miss | GAP-UI-CATALOG-02 |
| BR-SYN-004 | catalog | pass | GAP-UI-SYN-03 closed (DART-063) |
| DBR-ROLL-001 | catalog | pass | ΓÇö |

### Build / compose

| Rule ID | Surface | Verdict | Gap |
| ------- | ------- | ------- | --- |
| DBR-PUR-001 | build | pass | ΓÇö |
| DBR-PUR-003 | build | pass | (walkthrough residual GAP-UI-BUILD-03 is BR-BLD-008) |
| DBR-BLD-001 | build | pass | (kit UI partial via GAP-UI-BUILD-02) |
| DBR-BLD-003 | build | pass | ΓÇö |
| DBR-ID-001 | build | pass | (picker chrome GAP-UI-BUILD-05) |
| DBR-ID-002 | build | pass | ΓÇö |
| DBR-ID-008 | build | pass | GAP-UI-BUILD-01 closed (DART-064) |
| DBR-SYN-003 | build | pass | ΓÇö |
| DBR-CMP-001 | build | pass | ΓÇö |
| DBR-CMP-003 | build | partial | ΓÇö |
| DBR-CMP-007 | build | partial | GAP-UI-BUILD-08 |
| DBR-CMPL-001 | build | partial | GAP-UI-BUILD-02 |
| DBR-CMPL-002 | build | pass | ΓÇö |
| DBR-ROLL-004 | build | pass | ΓÇö |
| DBR-GUID-001 | build | pass | ΓÇö |
| DBR-GUID-003 | build | pass | ΓÇö |
| DAC-DST-009 | build | partial | GAP-UI-BUILD-08 |
| DBR-EQP-001 | build | pass | ΓÇö |
| DBR-EQP-002 | build | pass | ΓÇö |
| BR-BLD-008 | build | pass | GAP-UI-BUILD-03 closed (DART-067) |
| BR-BLD-009 | build | pass (Windows) | GAP-UI-BUILD-04 closed Windows; web GAP-FEAT-01 |
| BR-UI-001 | build | partial | GAP-UI-BUILD-08 |
| DBR-STAT-001 | build | pass | ΓÇö |
| PRODUCT-SOFT-NEVER-AUTO | build | pass | Soft never auto-applies |

### Sets / synergy (surface rules tracked via GAP rows)

| Rule IDs (representative) | Surface | Primary gaps |
| ------------------------- | ------- | ------------ |
| BR-SET-010, BR-SET-011, DAC-NME-004, DBR-STAT-008 | sets | GAP-UI-SETS-01/02 |
| BR-SLOT-001/002/006, DBR-CMP-001 | sets fill | GAP-UI-SETS-03/07 |
| BR-ROLL-001 | sets weapons | GAP-UI-SETS-10 |
| BR-TAG-007, BR-SET-001, BR-DEL-001 | sets library | GAP-UI-SETS-04/05/06 |
| BR-SYN-001/002/005/011/012, DBR-SYN-001/012/014 | synergy | GAP-UI-SYN-01/02/04/05/06/09 |
| BR-SYN-004, BR-SYN-008 | catalog reverse tags | GAP-UI-SYN-03 |

---

## 6. Master gaps table (GAP-UI-*)

**Classification:** `rule_miss` | `data_missing` | `data_present_ui_missing` | `polish_only`  
**Kind:** `rule` | `action` | `information` | `visual`  
**Status:** all `open` unless closed later.

| Gap ID | Sev | Surface | Title | Classification | Shells | Planned slice | Rules | Atlas screens |
| ------ | --- | ------- | ----- | -------------- | ------ | ------------- | ----- | ------------- |
| **GAP-UI-CATALOG-01** | P1 | catalog | Multi-facet include/exclude UI incomplete (slot/class/archetype missing) | **closed** (DART-062) | windows, jaspr | DART-062 | BR-CAT-006, DBR-ROLL-010, DAC-NME-003 | catalog-filters-open, catalog-weapons-owned, catalog-armor-owned |
| **GAP-UI-CATALOG-02** | P1 | catalog | Catalog group-by dimensions missing | **closed** (DART-062) | windows, jaspr | DART-062 | BR-CAT-007, PRODUCT-CAT-GROUP-SORT, DBR-ROLL-010, DAC-NME-003 | catalog-filters-open, catalog-weapons-owned |
| **GAP-UI-CATALOG-03** | P1 | catalog | Universal mode and Set/Synergy composition actions missing | rule_miss | windows, jaspr | DART-063 | BR-CAT-009 | catalog-universal |
| **GAP-UI-CATALOG-04** | P1 | catalog | Weapon catalog missing exotic weapons (legendary-only extract) | **closed** (DART-062) | windows, jaspr | DART-062 | BR-CAT-001, DBR-ROLL-010 | catalog-weapons-manifest, catalog-weapons-owned, catalog-signed-out-weapons |
| **GAP-UI-CATALOG-05** | P1 | catalog | Armor catalog missing legendary armor (exotic-only) | **closed** (DART-062) | windows, jaspr | DART-062 | BR-CAT-003, DBR-ROLL-010 | catalog-armor-manifest, catalog-armor-owned, catalog-signed-out-armor |
| **GAP-UI-CATALOG-06** | P1 | catalog | Synergy membership filter and linked tags absent | rule_miss | windows, jaspr | DART-063 | BR-CAT-008, BR-SYN-004, DBR-ROLL-010 | catalog-filters-open, catalog-weapon-detail, catalog-armor-detail |
| **GAP-UI-CATALOG-07** | P2 | catalog | Catalog results not alpha-sorted by display name | **closed** (DART-062) | windows, jaspr | DART-062 | PRODUCT-CAT-ALPHA-SORT | catalog-weapons-owned, catalog-signed-out-weapons |
| **GAP-UI-CATALOG-08** | P2 | catalog | Owned instance detail is raw placeholders vs Next perk/stat cards | data_present_ui_missing | windows, jaspr | DART-063 | DBR-ROLL-010, BR-CAT-002, BR-CAT-003 | catalog-weapon-detail, catalog-armor-detail |
| **GAP-UI-CATALOG-09** | P2 | catalog | Result cards lack item icons and dense meta chrome | polish_only | windows, jaspr | DART-068 | UI-POLISH-ITEM-ICONS, PRODUCT-BRAND-ICONS | catalog-weapons-owned, catalog-weapons-manifest, catalog-armor-owned, sets-fill-slot |
| **GAP-UI-CATALOG-10** | P2 | catalog | No Weapons/Armor kind mode separation in host browse | data_present_ui_missing | windows, jaspr | DART-063 | BR-CAT-001, BR-CAT-003, BR-CAT-009 | catalog-weapons-owned, catalog-armor-owned, catalog-universal |
| **GAP-UI-BUILD-01** | P1 | build | Identity confirm/fork missing on identity change (DBR-ID-008) | rule_miss | windows, jaspr | DART-064 **done** | DBR-ID-008, DBR-ID-001, DBR-BLD-001 | build-edit-general, build-library-selected |
| **GAP-UI-BUILD-02** | P1 | build | Subclass kit composer absent from host Build UI | data_present_ui_missing | windows, jaspr | DART-064 **done** | DBR-CMPL-001, DBR-BLD-001, BR-UI-001, DAC-DST-009 | build-edit-subclass, build-library-selected |
| **GAP-UI-BUILD-03** | P2 | build | Finish slot-first walkthrough (one-tap create/fill) not ported | closed (DART-067) | windows, jaspr | DART-067 | BR-BLD-008, DBR-PUR-003, DBR-CMPL-001 | build-edit-finish |
| **GAP-UI-BUILD-04** | P2 | build | Finish Armor improve (suggest-then-confirm) not in Build Finish path | closed (DART-067 windows; web GAP-FEAT-01) | windows | DART-067 | BR-BLD-009, PRODUCT-SOFT-NEVER-AUTO, DBR-GUID-001 | build-edit-armor-improve, build-edit-finish |
| **GAP-UI-BUILD-05** | P2 | build | Identity exotic/super pickers are raw hashes vs Manifest search + icons | data_present_ui_missing | windows, jaspr | DART-064 **done** | DBR-ID-001 | build-edit-general, build-library-selected |
| **GAP-UI-BUILD-06** | P2 | build | Variant loadout read-only overview missing icon density | polish_only | windows, jaspr | DART-068 | DBR-BLD-001, DBR-CMPL-001 | build-library-selected |
| **GAP-UI-BUILD-08** | P2 | build | Client hard-constraint UI prevention thinner than Next compose | rule_miss | windows, jaspr | DART-064 **done** | DAC-DST-009, BR-UI-001, DBR-GUID-003, DBR-CMP-007 | build-edit-subclass, build-edit-weapon-create, build-edit-armor-create |
| **GAP-UI-BUILD-09** | P2 | build | Jaspr compose attach/pin UX is id-text placeholders vs library pickers | data_present_ui_missing | jaspr | DART-064 **done** | DBR-CMP-001, DBR-ROLL-004 | build-edit-armor-reuse, build-edit-weapon-reuse |
| **GAP-UI-SETS-01** | P1 | sets | Armor set base-roll EoF six-stat board and totals missing | data_missing | windows, jaspr | **DART-065 done** | BR-SET-010, BR-SET-011, DAC-NME-004, DBR-STAT-008 | sets-detail |
| **GAP-UI-SETS-02** | P1 | sets | Set item rows lack identity meta, traits, synergies, and icons | data_missing | windows, jaspr | **DART-065 done** | BR-SET-010, DAC-NME-004, BR-ROLL-001 | sets-detail |
| **GAP-UI-SETS-03** | P1 | sets | Slot-fill density far below Next embedded Catalog (Jaspr hash-only) | data_present_ui_missing | windows, jaspr | **DART-065 done** | DBR-CMP-001, BR-SLOT-001, BR-SLOT-002, BR-SLOT-006 | sets-fill-slot |
| **GAP-UI-SETS-04** | P2 | sets | Library missing search and multi-tag AND type filters | rule_miss | windows, jaspr | **DART-066 done** | BR-TAG-007, BR-SET-001 | sets-library |
| **GAP-UI-SETS-05** | P2 | sets | Detail missing readiness strip, Fill next, and Used-by builds | data_present_ui_missing | windows, jaspr | **DART-066 done** | DBR-CMP-001, BR-SET-001 | sets-detail, sets-library |
| **GAP-UI-SETS-06** | P2 | sets | Delete set action and SET_IN_USE messaging absent | data_present_ui_missing | windows, jaspr | **DART-066 done** | BR-DEL-001, BR-SET-001 | sets-detail |
| **GAP-UI-SETS-07** | P2 | sets | Occupied-slot replace has no confirmation | rule_miss | windows, jaspr | **DART-065 done** | BR-SLOT-006 | sets-fill-slot, sets-detail |
| **GAP-UI-SETS-10** | P2 | sets | Weapon set fill does not capture or show full roll data | data_present_ui_missing | windows, jaspr | **DART-065 done** | BR-ROLL-001, BR-SET-010 | sets-detail, sets-fill-slot |
| **GAP-UI-SYN-01** | P1 | synergy | Evidence links lack catalog search picker (free-text + raw hash) | data_present_ui_missing | windows, jaspr | **DART-066 done** | BR-SYN-002, BR-SYN-005, BR-SYN-011, DBR-SYN-001, DBR-SYN-014 | synergy-create, synergy-detail |
| **GAP-UI-SYN-02** | P1 | synergy | BR-SYN-012 weapon-perk source labels missing on link search | rule_miss | windows, jaspr | **DART-066 done** | BR-SYN-012, DBR-SYN-014 | synergy-create |
| **GAP-UI-SYN-03** | P1 | synergy | Catalog/inventory reverse tags for linked library synergies (BR-SYN-004) | rule_miss | windows, jaspr | DART-063 | BR-SYN-004, BR-SYN-008 | catalog-weapon-detail, catalog-armor-detail |
| **GAP-UI-SYN-04** | P1 | synergy | Jaspr web synergy surface is create+list only (no detail/edit/links manage) | data_present_ui_missing | jaspr | **DART-066 done** | BR-SYN-001, BR-SYN-002, DBR-SYN-012 | synergy-library, synergy-detail, synergy-create |
| **GAP-UI-SYN-05** | P2 | synergy | DesignationLabel verb/element icons and human Type: Subtype chrome missing | data_present_ui_missing | windows, jaspr | DART-068 | BR-SYN-001, PRODUCT-BRAND-ICONS | synergy-library, synergy-detail, synergy-create |
| **GAP-UI-SYN-06** | P2 | synergy | Library instrument search and type/subtype facet filters not exposed | data_present_ui_missing | windows, jaspr | **DART-066 done** | BR-SYN-001 | synergy-library |
| **GAP-UI-SYN-09** | P2 | synergy | Delete library synergy action missing from host UI | data_present_ui_missing | windows, jaspr | **DART-066 done** | BR-SYN-001 | synergy-detail |
| **GAP-UI-LOADOUTS-01** | P2 | loadouts | Bungie slot row missing color bar, color swatch, and icon-plate chrome | data_present_ui_missing | windows, jaspr | DART-068 | UI-POLISH-LOADOUT-PRESENTATION, DART-055-BUNGIE-206 | loadouts-signed-in, loadouts-slot-expanded |
| **GAP-UI-LOADOUTS-02** | P2 | loadouts | Exotic armor/weapon names not enriched or shown on Bungie slot rows | data_missing | windows, jaspr | DART-068 | BR-EXO-005, DART-055-BUNGIE-206 | loadouts-signed-in, loadouts-slot-expanded |
| **GAP-UI-LOADOUTS-03** | P2 | loadouts | No Details expand for Bungie slot (hashes, large icon, instance snapshot) | data_present_ui_missing | windows, jaspr | DART-068 | DART-055-BUNGIE-206 | loadouts-slot-expanded |
| **GAP-UI-SETTINGS-01** | P2 | settings | Manifest status chrome: READY/STALE badge + per-store entity count chips | data_present_ui_missing | windows | DART-068 | PRODUCT-CAP-OAUTH-SYNC | settings-signed-out, settings-signed-in |
| **GAP-UI-SETTINGS-02** | P2 | settings | Inventory sync card presentation parity (ONLINE chip, labels, Refresh status, last-sync format) | polish_only | windows, jaspr | DART-068 | DART-025-INV-SYNC, DBR-EQP-007, RC-SYNC-FIDELITY | settings-signed-out, settings-signed-in |
| **GAP-UI-SETTINGS-04** | P2 | settings | Post-sync soft armor kit suggestions missing on Windows Settings | closed (DART-067) | windows | DART-067 | BR-OPT-004, PRODUCT-SOFT-NEVER-AUTO | settings-signed-in |
| **GAP-UI-SHELL-01** | P2 | shell-icons | Primary nav labels and order diverge from AppShell NAV_LINKS | rule_miss | windows, jaspr | DART-068 | PRODUCT-NAV-LINKS, DART-049-RC-NAV | build-library, settings-signed-in, loadouts-signed-in, catalog-weapons-owned |

**Open gap count:** 40  
**Note:** IDs skip intentional holes (e.g. no GAP-UI-BUILD-07, no GAP-UI-SETS-08/09, no GAP-UI-SYN-07/08, no GAP-UI-SETTINGS-03) to leave room for future inserts without renumbering.

---

## 7. Gap detail (evidence + exit criteria)

### Catalog

#### GAP-UI-CATALOG-01 ΓÇö Multi-facet include/exclude UI incomplete (P1)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | CatalogScreen cycle chips for slots, class, archetypes, elements, ammos, exotic + filterCatalogClient OR/AND/exclude; atlas dense filter chrome |
| Dart | `filter_catalog.dart` accepts slots/classNames/archetypes; `filter_options.dart` lists unused; hosts only wire elements/ammos/exotic |
| Exit | Hosts expose multi-value include/exclude chips for slot, class, archetype/frame (and element/ammo/exotic) with OR-within and AND-across; DAC-NME-003 scenarios pass on Windows+Jaspr |

#### GAP-UI-CATALOG-02 ΓÇö Catalog group-by dimensions missing (P1)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | `groupCatalogItems` partitions by element/ammo/archetype/frame/slot/class; empty dims ΓåÆ All results; labels/items compareDisplayName-sorted |
| Dart | No `groupCatalogItems` under packages/manifest or hosts; flat ListView/button rows only |
| Exit | Optional multi-dimension group-by UI; partitions do not change filter semantics; groups and items alpha-sorted comparable to Next |

#### GAP-UI-CATALOG-03 ΓÇö Universal mode and Set/Synergy composition actions missing (P1)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | UniversalSearchPanel + kind filters; UniversalHitDetail with UniversalSetActions/UniversalSynergyActions only (no Build kit attach) |
| Dart | No Universal tab/CTAs; offline_catalog mixes mods/aspects/fragments into one browse list without mode chrome |
| Exit | Dedicated Universal mode with mixed-kind search; from hit detail create/add Sets (wizard + instance pin) or Synergies onlyΓÇönot Build kit attach |

#### GAP-UI-CATALOG-04 ΓÇö Weapon catalog missing exotic weapons (P1)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | filterWeaponCatalog merges weapons + exoticWeapons with isExotic flag |
| Dart | WeaponsExtractor skips non-legendary; projector isExotic=false for weapons; no exotic weapons MvpStoreName |
| Exit | Full weapon browse includes exotic + legendary with correct exotic facet behavior and owned join |

#### GAP-UI-CATALOG-05 ΓÇö Armor catalog missing legendary armor (P1)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | filterArmorCatalog merges exoticArmor + legendaryArmor for all/owned browse |
| Dart | OfflineCatalog loads exoticArmor only; projectMvpStores has no legendary armor path |
| Exit | All armor + My armor browse includes legendary and exotic with class/slot facets |

#### GAP-UI-CATALOG-06 ΓÇö Synergy membership filter and linked tags absent (P1)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | CatalogScreen synergy include/exclude via allowlist/hash sets; linked synergies on detail |
| Dart | filter_catalog supports synergies; hosts never wire library synergies; linkedSynergyIds empty; no tags UI |
| Exit | Include/exclude by library synergy membership; matching rows show synergy tags/notes on detail |

#### GAP-UI-CATALOG-07 ΓÇö Catalog results not alpha-sorted (P2)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | filterItems finalize sorts via compareDisplayName; group path re-sorts each group |
| Dart | filterCatalogClient returns `.where().toList()` without name sort; hosts render store projection order |
| Exit | Filtered catalog lists (and group contents) sort alphabetically by display name with base sensitivity comparable to Next |

#### GAP-UI-CATALOG-08 ΓÇö Owned instance detail raw placeholders (P2)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | OwnedInstanceCard + InstancePerkGridView + ArmorStatsPanel base stats |
| Dart | Windows plugs:N; web id+power/location/rollTags; CatalogInstanceProjection raw plug hashes; GAP-INV-02/03 residual |
| Exit | Owned copy detail shows human-readable perks/traits when resolvable and armor base-stat board parity; wishlist clearly unpinned |

#### GAP-UI-CATALOG-09 ΓÇö Result cards lack icons and dense meta (P2 polish)

| Field | Value |
| ----- | ----- |
| Kind | visual |
| Next | ItemIcon 36px + Ex/slot/element/ammo/frame MetaChips; dense grid; entity icon paths on pickers |
| Dart | Windows ListTile / web catalog-row text only; CatalogItem.icon populated but unused on catalog and set-fill rows |
| Exit | Catalog and set-fill/picker rows show entity icons and compact element/ammo/slot/exotic meta comparable to Next card density |
| Polish tracker | Cross-list under [ui-polish-tracker.md](./ui-polish-tracker.md) (icons only) |

#### GAP-UI-CATALOG-10 ΓÇö No Weapons/Armor kind mode separation (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | CatalogScreen Weapons \| Armor \| Universal modes with kind-specific facets |
| Dart | Single mixed list from projectMvpStores without mode tabs |
| Exit | Dedicated Weapons and Armor browse modes (plus Universal) with kind-appropriate facets; mixed MVP stores not dumped into weapon browse by default |

### Build

#### GAP-UI-BUILD-01 ΓÇö Identity confirm/fork missing (P1)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | BuildEditPanel 409 IDENTITY_CONFIRM_REQUIRED ΓåÆ Confirm in-place / Fork new build |
| Dart | updateUserBuild has no identityAction; DART-032 notes confirm/fork deferred |
| Exit | Identity-affecting changes require Confirm (all variants) or Fork (new Build) or Cancel; comparable to Next + domain gate |

#### GAP-UI-BUILD-02 ΓÇö Subclass kit composer absent (P1)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | SubclassTab abilities + aspects/fragments + Save Subclass Kit; capacity/legality |
| Dart | SubclassKit in domain/DB; hosts expose only pinned Super textΓÇöno kit UI |
| Exit | Host compose views/edits full subclass kit with plain-language hard capacity; kit persists on variant/build |

#### GAP-UI-BUILD-03 ΓÇö Finish slot-first walkthrough residual (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | FinishBuildWalkthrough: one-tap Create/Capture + first-empty-slot fill loop |
| Dart | finish-gaps panel lists categories; no one-tap Create/Capture/fill host (GAP-FEAT-06 residual after panel close) |
| Exit | Finish supports slot-first Create/Capture then fill first empty required slot without name/type/tag chrome; equip still gated finish-completeΓêºequip-ready |

#### GAP-UI-BUILD-04 ΓÇö Finish Armor improve not on Build path (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | FinishArmorOptimizeWorkspace: Find kits ΓåÆ top-3 ΓåÆ confirm apply-in-place |
| Dart | Windows optimizer on Sets detail only; not Build Finish; Jaspr deferred GAP-FEAT-01 |
| Exit | From Build Finish/Armor with live covering Armor Set: Find kits ΓåÆ compare ΓåÆ confirm apply; **never silent auto-apply**. Web may stay deferred if product reaffirms GAP-FEAT-01 |

#### GAP-UI-BUILD-05 ΓÇö Identity exotic/super pickers raw hashes (P2)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | GeneralTab ManifestSearchPicker for Super + exotic armor with icons; ClassFilterChip |
| Dart | Windows TextFields for hash+name; Jaspr identity summary text only |
| Exit | Identity edit uses searchable named picks with Destiny icons; hashes not primary input |

#### GAP-UI-BUILD-06 ΓÇö Variant loadout read-only overview density (P2 polish)

| Field | Value |
| ----- | ----- |
| Kind | visual |
| Next | VariantCard DETAILS icon strips; Empty/Identity/Wishlist labels |
| Dart | Attachments + slot pin text cards only; no ability/item icon strip overview |
| Exit | Selected variant shows loadout overview with icons and empty/wishlist labels without requiring Edit |

#### GAP-UI-BUILD-08 ΓÇö Client hard-constraint UI thinner (P2)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | VariantEditPanel client hardBlocks; SubclassTab capacity notes; illegal picks blocked/explained pre-save |
| Dart | Domain hard evaluators on save/attach; host UI does not pre-filter dual exotic/illegal kit with plain-language disabled controls |
| Exit | Primary compose actions surface hard blocks with plain-language reasons before/at save; soft never disables Save; API/domain authoritative |

#### GAP-UI-BUILD-09 ΓÇö Jaspr compose attach/pin UX placeholders (P2)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Shells | jaspr |
| Next | Armor/Weapon tabs: set type + attach mode + Load sets search/tags + Attach; pin context from resolved equipment |
| Dart | BuildComposePage free-text attach set id + single pin field; data present, presentation raw |
| Exit | Web compose attach uses named set picker and per-slot pin edit; no raw id-only primary path |

### Sets

#### GAP-UI-SETS-01 — Armor set base-roll EoF six-stat board (P1) — **closed (DART-065)**

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | SetsDetail armor subgrid Totals + per-piece ArmorPieceStatRow from armor_stats plugs (mods/MW/tuning excluded) |
| Dart | `sumArmorSetStats` + host armor boards from inventory `statValues` / `buildArmorBaseStatBoard`; wishlist unknown |
| Exit | Pinned armor pieces show Health/Melee/Grenade/Super/Class/Weapons + totals (base roll only); unpinned show stats unknown |

#### GAP-UI-SETS-02 — Set item rows lack meta/traits/synergies/icons (P1) — **closed (DART-065)**

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | Atlas sets-detail cards: icons, Exotic/Instance badges, selected+available traits, LINKED SYNERGIES |
| Dart | Dense meta chips, trait perks, Instance\|Wishlist, linked synergies; icon URL residual → DART-068 |
| Exit | Filled slots show icon + element/type/frame/tier/origin when known; trait perks + available traits; linked synergies; Instance vs Wishlist |

#### GAP-UI-SETS-03 — Slot-fill density below embedded Catalog (P1) — **closed (DART-065)**

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | SlotFillPanel full Catalog grid icons + facets + Owned/Manifest + exotic-set banner + confirm replace |
| Dart | Windows denser picker meta + traits; Jaspr named search fill (not hash-only primary) |
| Exit | Both shells: slot-constrained catalog pick with icons + free-text at minimum; Owned vs all; instance pin or wishlist; Jaspr retires hash-only primary path |

#### GAP-UI-SETS-04 ΓÇö Library missing search and multi-tag AND filters (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | SetsPage search + TYPE & TAGS multi-select AND; ConceptTagChip column |
| Dart | Windows unfiltered FlapBoard; typeFilter unwired; Jaspr unordered buttons no filters |
| Exit | Library filter by free-text name and multi-select tags AND; optional type facet; tags as chips not raw ids |

#### GAP-UI-SETS-05 ΓÇö Detail readiness / Fill next / Used-by (P2)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | filled/capacity strip, FILL NEXT, USED BY BUILDS pills from setService.usedByBuilds |
| Dart | SetDetail.usedBy populated but never rendered; no readiness badge or Fill next CTA |
| Exit | Selected set shows filled/capacity, Fill next for first empty slot, used-by builds when attachments exist |

#### GAP-UI-SETS-06 ΓÇö Delete set + SET_IN_USE (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | sets-detail Edit/Delete; deleteUserSet blocked SET_IN_USE with user-facing error |
| Dart | deleteUserSet + SetInUseException exist; hosts expose no Delete control |
| Exit | Delete unused sets; attached sets blocked with plain-language SET_IN_USE on both shells |

#### GAP-UI-SETS-07 — Occupied-slot replace confirmation (P2) — **closed (DART-065)**

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | SlotFillPanel Confirm replace naming current item |
| Dart | Windows dialog + Jaspr two-step confirm naming current item (BR-SLOT-006) |
| Exit | Replacing occupied non-mod multi-slot requires explicit confirm naming current item; cancel leaves slot unchanged |

#### GAP-UI-SETS-10 — Weapon set fill full roll data (P2) — **closed (DART-065)**

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | Weapon cards selectedTraitPerks + availableTraitPerks; set items store selectedPerks from pick |
| Dart | `selectedPerksFromInstance` + UpsertSetItemCommand.selectedPerks; trait chips on detail |
| Exit | Pinning owned weapon persists selected perk hashes from sockets; detail shows trait names (not barrels/mags/stocks) |

### Synergy

#### GAP-UI-SYN-01 ΓÇö Evidence links lack catalog search picker (P1)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | SynergyEditPanel kind select + Search catalog + filterOutLinked* + EntityHotspot evidence |
| Dart | Windows kind dropdown + free name/hash fields; web weapon name+hash only; no picker |
| Exit | Hosts search catalog by link kind, add resolved targets, omit already-linked (BR-SYN-011), reject invalid targets |

#### GAP-UI-SYN-02 ΓÇö BR-SYN-012 weapon-perk source labels (P1)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | weaponPerkSourceLabel Exotic intrinsic/trait vs Legendary perk vs Legendary & exotic |
| Dart | No formatWeaponPerkSourceLabel; free-text display names only |
| Exit | Weapon_perk picker rows show exotic vs legendary role labels matching Next |

#### GAP-UI-SYN-03 ΓÇö BR-SYN-004 reverse tags on catalog (P1)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | CatalogScreen linkedSynergies via /api/user/synergies/by-target badges |
| Dart | No by-target/linkedSynerg usage in windows_host or web_host catalog/synergy code |
| Exit | Matching weapon/perk/origin/set-bonus/exotic/artifact shows all linked library synergies as tags/notes on both hosts |

#### GAP-UI-SYN-04 ΓÇö Jaspr synergy create+list only (P1)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Shells | jaspr |
| Next | SynergyPage dual-pane select ΓåÆ SynergyDetail + SynergyEditPanel edit/delete/links |
| Dart | web synergies_page create+list only; selectSynergy never opens detail/edit |
| Exit | Web dual-pane (or equivalent): select ΓåÆ locked designation + edit notes/links + delete comparable to Windows/Next |

#### GAP-UI-SYN-05 ΓÇö DesignationLabel icons chrome (P2 polish)

| Field | Value |
| ----- | ----- |
| Kind | visual |
| Next | DesignationLabel + useDesignationIcons; Verb/Element glyphs |
| Dart | formatSynergyDesignation returns type::subType wire keys only |
| Exit | Library/detail/create show Verb:/Element: with official-ish icons and human labels when available |

#### GAP-UI-SYN-06 ΓÇö Library search and type/subtype filters (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | SynergyFilters search + type family chips/subtypes |
| Dart | Windows setTypeFilter exists but page has no search/filter chrome; web none |
| Exit | Free-text search designations and multi-select type/subtype filters update library rail |

#### GAP-UI-SYN-09 ΓÇö Delete library synergy missing (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Next | SynergyDetail Delete with confirm in SynergyPage |
| Dart | deleteUserSynergy exists; no Delete control on Windows or web pages |
| Exit | User can delete library synergy from detail with confirm; list refreshes |

### Loadouts

#### GAP-UI-LOADOUTS-01 ΓÇö Color bar / swatch / icon-plate (P2)

| Field | Value |
| ----- | ----- |
| Kind | visual |
| Next | LoadoutColorBar + LoadoutIconPlate + colorUrl swatch |
| Dart | iconUrl Image.network only; colorUrl resolved but never painted |
| Exit | When presentation tables resolve colorUrl/iconUrl, rows show color stripe, icon plate, and small swatch comparable to atlas |

#### GAP-UI-LOADOUTS-02 ΓÇö Exotic names not enriched (P2)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | enrichLoadoutsWithExotics ΓåÆ exoticArmorName ┬╖ exoticWeaponName on rows |
| Dart | parseCharacterLoadoutsResponse never sets exotic*; model fields unused |
| Exit | After inventory sync, Bungie rows show resolved exotic armor/weapon names when present |

#### GAP-UI-LOADOUTS-03 ΓÇö Details expand for Bungie slot (P2)

| Field | Value |
| ----- | ----- |
| Kind | information |
| Next | Details/Hide expandedBungieId panel with characterId, icon/color hashes, large icon, instance count |
| Dart | No expansion state or secondary detail panel despite fields on model |
| Exit | User can expand a slot and see character id + icon/color hashes, larger icon, empty vs instance-count messaging |

### Settings

#### GAP-UI-SETTINGS-01 ΓÇö Manifest READY/entity chips (P2)

| Field | Value |
| ----- | ----- |
| Kind | visual |
| Shells | windows |
| Next | ManifestCard Badge READY/STALE/NOT DOWNLOADED + Chip map of entityCache.counts |
| Dart | _ManifestStatusCard Cached/Remote/Status only; entityCache.counts not rendered as chips |
| Exit | Windows Manifest panel shows readiness badge and store-name+count chips; Refresh retained |

#### GAP-UI-SETTINGS-02 ΓÇö Inventory sync card presentation parity (P2)

| Field | Value |
| ----- | ----- |
| Kind | visual |
| Bugs | **BUG-20260725-003** |
| Next | InventorySyncCard ONLINE/OFFLINE Chip; human last sync; Sync inventory + Refresh status |
| Dart | Sync now only; no ONLINE chip; no Refresh status button; lastFullSyncAt raw ISO |
| Exit | Inventory card shows ONLINE/OFFLINE, human last sync, Sync inventory CTA, secondary Refresh status; signed-out disables with sign-in copy |

#### GAP-UI-SETTINGS-04 ΓÇö Post-sync soft armor kit suggestions (P2)

| Field | Value |
| ----- | ----- |
| Kind | action |
| Shells | windows |
| Next | InventorySyncCard fetchPostSyncSuggestions Better armor kits Callout Confirm/Dismiss; never auto-applies |
| Dart | InventorySyncCard ends at Sync now + diagnostics; no afterSync better-kit banner |
| Exit | After successful Windows inventory sync, constrained Armor Sets attached to ΓëÑ1 Build may show suggest-then-confirm banner; **never silent auto-apply**. Jaspr remains deferred with FEAT-OPTIMIZER / GAP-FEAT-01 |

### Shell

#### GAP-UI-SHELL-01 ΓÇö Primary nav labels and order (P2)

| Field | Value |
| ----- | ----- |
| Kind | rule |
| Next | AppShell NAV_LINKS: Loadouts, Build, Synergy, Sets, Catalog, Settings |
| Dart | Windows/Jaspr use Builds/Synergies labels and different order; destinations present |
| Exit | Primary destinations match AppShell keys with product labels (Build/Synergy) and documented order parity or explicit product note; shell nav tests assert labels |

---

## 8. Slice plan (DART-062+)

| DART ID | Short name | Phase | Gap IDs | Exit criteria (summary) |
| ------- | ---------- | ----- | ------- | ----------------------- |
| **DART-062** | `catalog-browse-semantics` | ui-fidelity-p1 | GAP-UI-CATALOG-01, 02, 04, 05, 07 | Windows+Jaspr Catalog: multi-value include/exclude for slot/class/archetype/element/ammo/exotic; optional multi-dim group-by without changing filter semantics; alpha sort by display name; weapon browse includes exotic+legendary; armor browse includes legendary+exotic; DAC-NME-003 + BR-CAT-001/003/006/007 scenarios pass. **Cutover GO unchanged.** |
| **DART-063** | `catalog-universal-modes-synergy-tags` | ui-fidelity-p1 | GAP-UI-CATALOG-03, 06, 08, 10; GAP-UI-SYN-03 | Weapons\|Armor\|Universal modes with kind-appropriate facets; Universal hit detail Set/Synergy actions only (no Build kit attach); synergy membership include/exclude + BR-SYN-004 reverse tags; owned instance detail human-readable perks/traits + armor base-stat board when resolvable |
| **DART-064** | `build-identity-subclass-compose` | ui-fidelity-p1 **done** | GAP-UI-BUILD-01, 02, 05, 08, 09 | Identity change Confirm in-place or Fork new Build (DBR-ID-008); full subclass kit composer with capacity plain language; Manifest search pickers for exotic armor/Super; client hard-block UX dual exotic/kit; Jaspr attach uses named set picker + per-slot pins |
| **DART-065** | `sets-board-rows-fill` | ui-fidelity-p1 | GAP-UI-SETS-01, 02, 03, 07, 10 | Armor set base-roll EoF six-stat per-piece + totals (DAC-NME-004/BR-SET-010/011); item rows icons/traits/origin/synergies/Instance\|Wishlist; slot-fill embedded catalog density on both shells (Jaspr not hash-only); occupied-slot replace confirm; weapon fill persists/shows trait perks |
| **DART-066** | `synergy-picker-manage-sets-library` | ui-fidelity-p1-p2 | GAP-UI-SYN-01, 02, 04, 06, 09; GAP-UI-SETS-04, 05, 06 | **done** — Synergy evidence catalog search by kind with BR-SYN-011 omit-linked + BR-SYN-012 perk labels; Jaspr detail/edit/links manage; library search/type filters; delete synergy; Sets library search+tag AND filters, readiness/Fill next/used-by, delete with SET_IN_USE |
| **DART-067** | `finish-walkthrough-armor-optimize` | ui-fidelity-p2 **done** | GAP-UI-BUILD-03, 04; GAP-UI-SETTINGS-04 | **done** — Finish slot-first Create/Capture + first-empty fill (Windows+Jaspr); Windows Build Finish Armor improve confirm-only; Windows Settings post-sync better-kit Confirm/Dismiss only—**never auto-apply**. Web optimizer remains GAP-FEAT-01 deferred |
| **DART-068** | `presentation-shell-loadouts-settings` | ui-fidelity-p2-polish **done** | GAP-UI-CATALOG-09; GAP-UI-BUILD-06; GAP-UI-SYN-05; GAP-UI-LOADOUTS-01..03; GAP-UI-SETTINGS-01, 02; GAP-UI-SHELL-01 | **done** — AppShell label/order parity; item icons + dense meta; loadout color bar/swatch + exotic names + details expand; Settings READY/entity chips + inventory ONLINE/Refresh; designation chrome; variant overview. **Not cutover re-gate.** |

---

## 9. Open bugs crosswalk

| Bug ID | Gap IDs | Notes |
| ------ | ------- | ----- |
| **BUG-20260725-003** | GAP-UI-SETTINGS-02 | Lifecycle only ΓÇö inventory sync card presentation parity (ONLINE chip, labels, Refresh status, last-sync format). No cutover re-open. |

No other open bugs are linked to this fidelity residual set as of 2026-07-25.

---

## 10. Non-goals

| Item | Why |
| ---- | --- |
| Re-opening **PRODUCTION_CUTOVER** / re-running RC-* as fidelity exit | Cutover GO already records composeΓåÆequip spine; fidelity is host density |
| **GAP-FEAT-01** optimizer on mobile/web (unless product elevates) | Windows-first remain; DART-067 may wire Windows Build Finish + Settings only |
| **GAP-FEAT-02** dim.gg share | jsonOnly sufficient |
| **GAP-FEAT-03 / 04 / 05** LLM, `/debug/*`, Analyze primary | PRODUCT non-goals |
| Flutter Web product target | Jaspr is web host |
| Pixel-perfect canvas hi-fi as a gate | Unbounded; polish tracker deferred items only |
| Soft auto-apply of kit suggestions | **Forbidden** ΓÇö confirm/dismiss only |
| CLIENT_SECRET in clients | **Forbidden** |

---

## 11. How agents use this doc

1. Prefer this file for **host presentation residual** planning; prefer [feature-gaps.md](./multiplatform-dart-feature-gaps.md) for FEAT inventory + all GAP-* lifecycle.
2. Prefer [cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) for production merge GO only ΓÇö **do not** flip cutover for GAP-UI-* alone.
3. Prefer [ui-polish-tracker.md](./ui-polish-tracker.md) only for pure visual density (icons, chrome, spacing) that does **not** encode BR/DAC/DBR semantics.
4. Every open P1 GAP-UI-* must keep a planned **DART-062+** (see ┬º8 and slice roadmap).
5. On finish-spec of a fidelity slice: update gap status here + feature-gaps master table; bump **Updated**; soft never auto-applies; no CLIENT_SECRET.

---

## Current pointer

| Field | Value |
| ----- | ----- |
| **Next free slice** | **DART-064** `build-identity-subclass-compose` |
| **Phase** | ui-fidelity-p1 (post P8 cutover program) |
| **Cutover** | **PRODUCTION_CUTOVER: GO** (unchanged) |
| **Open GAP-UI count** | **40** |
| **Blocker for cutover** | **None** |
