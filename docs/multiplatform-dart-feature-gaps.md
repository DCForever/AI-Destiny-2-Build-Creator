# Multiplatform Dart — Feature Gap Catalog vs Next.js

**Status:** active planning artifact  
**Updated:** 2026-07-25  
**Workstream:** DART (parallel to product Spec Kit `0NN`)  
**Integration base:** `feature/multiplatform-dart`  
**Worktree:** `F:\Destiny2BuildCreator-multiplatform-dart`

**Related**

| Doc | Role |
| --- | ---- |
| [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md) | Slice backlog + DART-NNN status |
| [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) | Program vs production cutover gates |
| [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) | Architecture freezes |
| Workflow `dart-gaps-analysis` | Re-scan Next vs Dart; refresh this catalog |

This catalog is the **canonical list of product capabilities** that exist in Next.js and the **planned DART work** to close (or explicitly defer) each gap.  
Nothing here retires Next; it only plans the port.

---

## How to use

1. Every Next product capability that is not fully matched on a required shell gets a **GAP-*** row (or is **N/A** with reason).
2. Every non-N/A gap has **planned work**: one or more **DART-NNN** slice IDs (pending/active/done).
3. After `dart-gaps-analysis` or live dual-use, update **Status**, **Evidence**, and **Planned slices**.
4. New Spec Kit slices start at **DART-050+** (do not reuse product `0NN` numbers).
5. Exit criteria for each planned slice must be **parity-specific** (e.g. vault copies stored), not “sync button works”.

### Status values

| Status | Meaning |
| ------ | ------- |
| `open` | Confirmed gap; work planned or needed |
| `partial` | Some shells/paths OK; residual listed |
| `planned` | Spec not started; DART-NNN reserved |
| `in_progress` | Active Spec Kit branch |
| `done` | Merged to `feature/multiplatform-dart`; re-verify live |
| `deferred` | Explicitly not planned for cutover (reason required) |
| `n/a` | Non-goal or not required |

### Severity

| Sev | Meaning |
| --- | ------- |
| **P0** | Blocks trust of core compose→equip or live dual-use (wrong inventory, can’t equip) |
| **P1** | Blocks production cutover residual (`RB-*` / `RC-*`) |
| **P2** | Shell density / polish; not cutover-critical if documented |
| **P3** | Nice-to-have / non-goal unless product elevates |

---

## Phase plan (post DART-049)

| Phase | Theme | Planned slice range | Goal |
| ----- | ----- | ------------------- | ---- |
| **P6** | Inventory fidelity | DART-050–054 | Vault/postmaster parity, enrichment, diagnostics, live harness |
| **P7** | Nav & residual product surfaces | DART-055–057 | Loadouts; web sync depth; mobile gaps worth shipping |
| **P8** | Production readiness | DART-058–061 | Public auth matrix, entity CDN, dual-run ops, cutover re-gate |

---

## Master gap table

| ID | Area | Severity | Status | Next.js evidence | Dart today | Planned slices | Cutover link |
| -- | ---- | -------- | ------ | ---------------- | ---------- | -------------- | ------------ |
| **GAP-INV-01** | Vault/postmaster bucket resolution | **P0** | `open` | `buildEquipmentBucketLookup` + `resolveTransferContainerBuckets` in `src/lib/bungie/syncInventory.ts` | `syncUserInventory` on Windows omits `equipmentBucketLookup` → transfer-container items dropped | **DART-050** | Feeds RC-SYNC fidelity |
| **GAP-INV-02** | Roll tags enrichment | **P1** | `open` | `computeRollTags` + perk/weapon catalog in sync normalize | Only `Crafted` when `isCrafted` | **DART-051** | Owned pickers / quality UX |
| **GAP-INV-03** | Socket plugs / perk grid enrichment | **P1** | `open` | `buildSocketPlugsForItems` + weapon socket context | Raw `socketCapture` JSON; no category/perk-index enrichment | **DART-052** | Instance perk grids |
| **GAP-INV-04** | Sync diagnostics UI | **P1** | `open` | Console `[inventory-sync]` diagnostics | Item count only | **DART-053** | Makes drops visible |
| **GAP-INV-05** | Live Next-vs-Dart inventory harness | **P0** | `planned` | Manual dual sync | None automated | **DART-054** | Prevents silent drift |
| **GAP-INV-06** | Owned catalog needs entity stores | **P1** | `partial` | Manifest refresh always online | Owned join fails/looks empty without entity cache | **DART-050** docs + Settings UX in **DART-053** | UX after sync |
| **GAP-NAV-01** | In-Game Loadouts surface | **P1** | `open` | `/loadouts` AppShell | MISS all shells | **DART-055** | RB-01 / RC-NAV |
| **GAP-WEB-01** | Jaspr inventory sync + owned depth | **P1** | `open` | Full Settings sync + owned catalog | Thinner web path | **DART-056** | RB-02 / RC-SYNC |
| **GAP-MOB-01** | Mobile catalog / equip / optimizer | **P2** | `partial` | Full desktop-class | Reduced density; catalog MISS; equip/optimizer limited | **DART-057** | Phone spine polish |
| **GAP-AUTH-01** | Prod Public redirect matrix (all shells) | **P1** | `partial` | Confidential Next HTTPS | Windows Public loopback OK locally; prod/Jaspr/mobile matrix incomplete | **DART-058** | RB-03 / RC-AUTH |
| **GAP-WEB-02** | Entity bundle prod distribution | **P1** | `open` | Full raw manifest pipeline | Prebuilt bundles only; channel TBD | **DART-059** | RB-05 / RC-WEB-DATA |
| **GAP-OPS-01** | Dual-run + rollback procedure | **P1** | `open` | Next sole prod | Not executed | **DART-060** | RB-04 / RC-OPS |
| **GAP-CUT-01** | Re-gate production cutover | **P1** | `planned` | N/A | Checklist NO-GO | **DART-061** | Flip PRODUCTION_CUTOVER when ready |
| **GAP-UI-01** | Soft stat targets on web | **P2** | `partial` | Full editor | Partial on Jaspr | **DART-057** or fold into web polish | Soft never auto-apply |
| **GAP-FEAT-01** | Armor optimizer on mobile/web | **P2** | `deferred` | Full UI | Windows only (by design for program gate) | *None unless product requires* | Accept Windows-only or new slice later |
| **GAP-FEAT-02** | dim.gg share | **P3** | `deferred` | Optional | jsonOnly only | *Non-goal* | Cutover N/A |
| **GAP-FEAT-03** | LLM propose / multi-pass generator | **P3** | `deferred` | Optional / not primary | Not ported | *Non-goal* | Cutover N/A |
| **GAP-FEAT-04** | `/debug/*` operator tools | **P3** | `deferred` | Present | Not ported | *Non-goal* | Cutover N/A |
| **GAP-FEAT-05** | Analyze / legacy generator tab | **P3** | `deferred` | Adjacent | Not primary | *Non-goal* | Cutover N/A |

---

## Detailed gap specs (must plan)

### GAP-INV-01 — Vault / postmaster resolution (**P0**)

**Problem:** Vault (General) and Postmaster items use transfer bucket hashes. Without itemHash → equipment bucket lookup from Destiny definitions, they are **dropped** before Drift write.

**Next:** `src/lib/bungie/resolveEquipmentBuckets.ts` + `syncInventory.ts`  
**Dart:** `syncUserInventory(..., equipmentBucketLookup: {})` default empty from Windows `InventorySyncController.syncNow`.

**Planned slice: DART-050 `inventory-vault-resolution`**

| Field | Value |
| ----- | ----- |
| Branch / specs | `dart-050-inventory-vault-resolution` |
| Depends | DART-024, DART-018/017 (manifest entity path) |
| Deliverables | Build lookup from raw item definitions or entity stores; wire into Windows (and web/mobile) sync; store vault copies with correct Kinetic/Energy/… buckets |
| Exit criteria | After sync, vault weapon/armor instances present in Drift; unit tests with vault fixtures; diagnostics show `resolvedFromTransfer > 0` when fixtures include vault; live count within agreed tolerance of Next for same membership (or documented remaining delta) |
| Status | `planned` |

---

### GAP-INV-02 — Roll tags (**P1**)

**Problem:** Next computes god-roll / perk-derived tags; Dart only tags `Crafted`.

**Next:** `computeRollTags` in sync normalize  
**Dart:** `_normalizeItems` rollTags ≈ crafted only

**Planned slice: DART-051 `inventory-roll-tags`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-051-inventory-roll-tags` |
| Depends | DART-050 (stable inventory set), entity perk stores |
| Exit criteria | Roll tags match Next golden fixtures for sample weapons; soft never auto-applies |
| Status | `planned` |

---

### GAP-INV-03 — Socket plug enrichment (**P1**)

**Problem:** Next builds categorized stored socket plugs for perk grids; Dart stores raw capture.

**Planned slice: DART-052 `inventory-socket-enrichment`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-052-inventory-socket-enrichment` |
| Depends | DART-050, manifest weapon socket context port |
| Exit criteria | Per-copy perk grid data parity for weapons on Windows catalog/instance UI; tests with socket fixtures |
| Status | `planned` |

---

### GAP-INV-04 — Sync diagnostics UI (**P1**)

**Problem:** Users cannot see raw/parsed/dropped/vault-dropped counts.

**Planned slice: DART-053 `inventory-sync-diagnostics-ui`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-053-inventory-sync-diagnostics-ui` |
| Depends | DART-025, DART-050 (so diagnostics are meaningful) |
| Exit criteria | Settings shows raw total, stored total, dropped unknown/transfer, resolvedFromTransfer; entity-cache empty warning for Owned catalog |
| Status | `planned` |

---

### GAP-INV-05 — Live parity harness (**P0** process)

**Problem:** No automated/manual dual-run checklist forced Next vs Dart inventory comparison.

**Planned slice: DART-054 `inventory-live-parity-harness`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-054-inventory-live-parity-harness` |
| Depends | DART-050–053 |
| Exit criteria | Documented procedure + optional script/tool that compares counts by location/bucket; CI or operator gate for future sync changes |
| Status | `planned` |

---

### GAP-NAV-01 — In-Game Loadouts (**P1**)

**Planned slice: DART-055 `in-game-loadouts-surface`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-055-in-game-loadouts-surface` |
| Depends | DART-024 profile components 200/206 path; Windows host first |
| Exit criteria | First-class Loadouts UI on Windows (and plan for web); or product decision demotes AppShell link (then mark deferred with PRODUCT note) |
| Status | `planned` |
| Cutover | RB-01 |

---

### GAP-WEB-01 — Jaspr sync + owned depth (**P1**)

**Planned slice: DART-056 `jaspr-inventory-sync-depth`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-056-jaspr-inventory-sync-depth` |
| Depends | DART-050, DART-045 |
| Exit criteria | Web sync path stores same resolution rules as Windows; Owned catalog usable for equip pins |
| Status | `planned` |
| Cutover | RB-02 |

---

### GAP-MOB-01 — Mobile spine polish (**P2**)

**Planned slice: DART-057 `mobile-compose-equip-polish`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-057-mobile-compose-equip-polish` |
| Depends | DART-041, DART-050 |
| Exit criteria | Documented mobile surface matrix; equip path or explicit N/A; catalog access if product requires |
| Status | `planned` |

---

### GAP-AUTH-01 — Prod Public redirect matrix (**P1**)

**Planned slice: DART-058 `prod-public-oauth-matrix`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-058-prod-public-oauth-matrix` |
| Depends | DART-023/045 |
| Exit criteria | Doc of Bungie Public app redirects for Windows HTTPS loopback, Jaspr prod origin, mobile schemes; no secrets in clients; ops sign-off checklist |
| Status | `planned` |
| Cutover | RB-03 |

---

### GAP-WEB-02 — Entity bundle channel (**P1**)

**Planned slice: DART-059 `entity-bundle-prod-channel`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-059-entity-bundle-prod-channel` |
| Depends | DART-044 |
| Exit criteria | Chosen channel (ship-in-app / CDN / hybrid); versioning; offline web compose still works |
| Status | `planned` |
| Cutover | RB-05 |

---

### GAP-OPS-01 — Dual-run ops (**P1**)

**Planned slice: DART-060 `dual-run-rollback-ops`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-060-dual-run-rollback-ops` |
| Depends | Windows + Jaspr feature complete enough for dual-run |
| Exit criteria | Written ops runbook executed once; rollback = keep Next; attach notes to cutover checklist |
| Status | `planned` |
| Cutover | RB-04 |

---

### GAP-CUT-01 — Production cutover re-gate (**P1**)

**Planned slice: DART-061 `production-cutover-regate`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-061-production-cutover-regate` |
| Depends | DART-050–060 as required by residual blockers |
| Exit criteria | All `RC-*` pass or product-waived; `PRODUCTION_CUTOVER: GO` with date; merge policy cleared |
| Status | `planned` |

---

## Process gaps (why P0 inventory issues shipped)

| ID | Process miss | Fix (planned into slices) |
| -- | ------------ | ------------------------- |
| **PROC-01** | Exit criteria said “sync works” not “vault parity” | DART-050 exit criteria |
| **PROC-02** | Optional API params allowed empty production wiring | DART-050 host wiring required |
| **PROC-03** | No live dual-account harness | DART-054 |
| **PROC-04** | Cutover checklist coarse on inventory fidelity | Update checklist after DART-050–054 |
| **PROC-05** | Automated Spec Kit green ≠ product sameness | Gaps workflow + harness |

---

## Deferred / non-goals (do not invent slices unless product changes)

| ID | Item | Reason |
| -- | ---- | ------ |
| GAP-FEAT-01 | Optimizer on mobile/web | Windows-first acceptable unless product elevates |
| GAP-FEAT-02 | dim.gg | jsonOnly sufficient for cutover spine |
| GAP-FEAT-03 | LLM multi-pass / propose primary | PRODUCT non-primary |
| GAP-FEAT-04 | `/debug/*` | Operator non-goal for port |
| GAP-FEAT-05 | Analyze primary tab | Adjacent legacy |

---

## Update checklist (after gaps analysis or finish-spec)

- [ ] Touch **Updated** date  
- [ ] Set gap **Status**  
- [ ] Ensure every `open`/`partial` P0–P1 gap has a **planned DART-NNN**  
- [ ] Sync residual table in cutover checklist if RB/RC change  
- [ ] Append new DART-NNN rows to [slice roadmap](./multiplatform-dart-slice-roadmap.md) when work starts  

---

## Current pointer (post-program planning)

| Field | Value |
| ----- | ----- |
| **Next planned slice** | **DART-050** `inventory-vault-resolution` |
| **Next phase** | P6 inventory fidelity |
| **Blocker for cutover** | See residual RB-01…05; inventory P0 is GAP-INV-01 |
