# Multiplatform Dart — Feature Gap Catalog vs Next.js

**Status:** active planning artifact  
**Updated:** 2026-07-25 (UI fidelity residual audit; FEAT PARTIAL demotions for host density; GAP-UI-* catalog; PRODUCTION_CUTOVER GO **unchanged**)  
**Workstream:** DART (parallel to product Spec Kit `0NN`)  
**Integration base:** `feature/multiplatform-dart`  
**Worktree:** `F:\Destiny2BuildCreator-multiplatform-dart`

**Related**

| Doc | Role |
| --- | ---- |
| [multiplatform-dart-ui-fidelity.md](./multiplatform-dart-ui-fidelity.md) | **Host UI fidelity** master (atlas parity, GAP-UI-*, rules matrix, DART-062+) — distinct from cutover |
| [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md) | Slice backlog + DART-NNN status |
| [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) | Program vs production cutover gates (**GO** unchanged by fidelity) |
| [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) | Architecture freezes |
| [ui-polish-tracker.md](./ui-polish-tracker.md) | Pure visual density only |
| Product `PRODUCT.md` | Canonical product purpose + confirmed capabilities |
| Workflow `dart-gaps-analysis` | Re-scan Next vs Dart; refresh this catalog + inventory |

**Rule:** FEAT cutover **PASS** does **not** override missed BRs/DACs. Fidelity PARTIAL demotions track host presentation residuals; they do **not** re-open PRODUCTION_CUTOVER.

This document is the **canonical product→port planning ledger**:

1. **Product feature inventory** — every confirmed PRODUCT / AppShell capability with Dart status and plan ownership.  
2. **Gap catalog (GAP-\*)** — residual mismatches vs Next with severity and exit criteria.  
3. **Slice map (DART-050+)** — reserved Spec Kit work that closes those gaps.

Nothing here retires Next; it only plans the port. **Rule:** no open P0/P1 without a planned DART-NNN (or explicit deferred/N/A with reason).

---

## How to use

1. Start from the **Product feature inventory** — every row must have Plan ownership (`shipped` / `planned` / `deferred` / `n/a`).
2. Every Next product capability that is not fully matched on a required shell gets a **GAP-*** row (or is **N/A** with reason).
3. Every non-N/A gap has **planned work**: one or more **DART-NNN** slice IDs (pending/active/done).
4. After `dart-gaps-analysis` or live dual-use, update inventory status, gap **Status**, **Evidence**, and **Planned slices**.
5. New Spec Kit slices start at **DART-050+** (do not reuse product `0NN` numbers).
6. Exit criteria for each planned slice must be **parity-specific** (e.g. vault copies stored), not “sync button works”.

### Status values (gaps)

| Status | Meaning |
| ------ | ------- |
| `open` | Confirmed gap; work planned or needed |
| `partial` | Some shells/paths OK; residual listed |
| `planned` | Spec not started; DART-NNN reserved |
| `in_progress` | Active Spec Kit branch |
| `done` | Merged to `feature/multiplatform-dart`; re-verify live |
| `deferred` | Explicitly not planned for cutover (reason required) |
| `n/a` | Non-goal or not required |

### Plan ownership (inventory)

| Plan | Meaning |
| ---- | ------- |
| **shipped** | Delivered on DART-001–049 (or earlier); residual only if GAP open |
| **planned** | Reserved DART-050+ on roadmap (cutover 050–061 done; UI fidelity 062–068) |
| **deferred** | Explicitly out of cutover scope until product elevates |
| **n/a** | Non-goal for multiplatform port / cutover |

### Severity

| Sev | Meaning |
| --- | ------- |
| **P0** | Blocks trust of core compose→equip or live dual-use (wrong inventory, can’t equip) |
| **P1** | Blocks production cutover residual (`RB-*` / `RC-*`) |
| **P2** | Shell density / polish; not cutover-critical if documented |
| **P3** | Nice-to-have / non-goal unless product elevates |

---

## Product feature inventory

Source of truth for *what the product is*: `PRODUCT.md` (capabilities) + `AppShell` `NAV_LINKS`.  
Shell columns: **W** = Windows Flutter, **M** = Mobile Flutter, **J** = Jaspr web.  
Status legend matches cutover checklist: **PASS** / **PARTIAL** / **MISS** / **N/A**.

### A. Production nav surfaces (AppShell)

Shell columns: **cutover** spine (destination present) vs **fidelity** host density vs Next atlas. Fidelity **PARTIAL** does not re-open PRODUCTION_CUTOVER. Details: [multiplatform-dart-ui-fidelity.md](./multiplatform-dart-ui-fidelity.md).

| ID | Feature | Product path | W | M | J | Plan | Slices / notes |
| -- | ------- | ------------ | - | - | - | ---- | -------------- |
| **FEAT-NAV-BUILD** | Build library + composer | `/build` | **PARTIAL** | PASS | **PARTIAL** | **shipped** + fidelity | Cutover spine PASS (DART-028–038, 041, 046–047); fidelity: DBR-ID-008 confirm/fork + subclass kit (GAP-UI-BUILD-01/02) → **DART-064** |
| **FEAT-NAV-SYNERGY** | Synergy library | `/synergy` | **PARTIAL** | N/A\* | **PARTIAL** | **shipped** + fidelity | Windows dual-pane; catalog reverse tags **done** (DART-063); free-text evidence + Jaspr create+list residual (GAP-UI-SYN-01,02,04) → **DART-066** |
| **FEAT-NAV-SETS** | Sets library | `/sets` | **PARTIAL** | N/A\* | **PARTIAL** | **shipped** + fidelity | Library/slots functional; DAC-NME-004/BR-SET-010/011 board + dense rows + embedded Catalog fill missing (GAP-UI-SETS-01..03) → **DART-065** |
| **FEAT-NAV-CATALOG** | Catalog browse | `/catalog` | **PARTIAL** | N/A\* | **PARTIAL** | **shipped** + fidelity | Multi-facet/group-by/alpha (DART-062) + Weapons/Armor/Universal + synergy tags + owned detail (DART-063) **done**; icons residual (GAP-UI-CATALOG-09) → **DART-068** |
| **FEAT-NAV-SETTINGS** | Settings (auth, sync, data) | `/settings` | **PASS** | PARTIAL | **PASS** | **shipped** | OAuth Public+PKCE + inventory sync + diagnostics remain PASS; residuals chrome only (GAP-UI-SETTINGS-01/02; post-sync banner GAP-UI-SETTINGS-04) — **no demote** |
| **FEAT-NAV-LOADOUTS** | In-Game Loadouts browser | `/loadouts` | **PASS** | N/A\* | **PASS** | **shipped** | **DART-055** cutover PASS; residuals P2 density only (GAP-UI-LOADOUTS-01..03) — **no demote** |

### B. Compose → equip spine (PRODUCT primary job)

| ID | Feature | Product evidence | W | M | J | Plan | Slices / GAP |
| -- | ------- | ---------------- | - | - | - | ---- | ------------ |
| **FEAT-COMPOSE-IDENTITY** | Build identity (synergies, exotic, Super) | Build composer | **PARTIAL** | PASS | **PARTIAL** | **shipped** + fidelity | In-place edit without Confirm/Fork (DBR-ID-008 → GAP-UI-BUILD-01); raw hash exotic/super pickers (GAP-UI-BUILD-05) → **DART-064** |
| **FEAT-COMPOSE-VARIANTS** | Variants + set attachments + slot pins | Build composer | PASS | PASS | PASS | **shipped** | DART-005/028+ |
| **FEAT-COMPOSE-HARD** | Hard constraints on save/attach | Domain DBR/DAC | **PARTIAL** | PASS | **PARTIAL** | **shipped** + fidelity | Domain authoritative; client pre-block UI thinner than Next (GAP-UI-BUILD-08) → **DART-064** |
| **FEAT-COMPOSE-SOFT** | Soft coverage display (never auto-apply) | Soft guidance UI | PASS | PASS | PASS | **shipped** | DART-004/034/041/046; RC-SOFT; soft **never auto-applies** |
| **FEAT-COMPOSE-SOFT-STATS** | Soft stat targets (explicit save) | Soft stat editor | PASS | PASS | PASS | **shipped** | DART-034/041/046; Jaspr all `ArmorStatName` **DART-057** / GAP-UI-01 closed |
| **FEAT-COMPOSE-FINISH** | Finish gaps helpers | Finish build UX | **PARTIAL** | PARTIAL | **PARTIAL** | **shipped** + fidelity | finish-gaps panel + equip gates shipped (GAP-FEAT-06 closed); residual one-tap walkthrough GAP-UI-BUILD-03 + Finish armor improve GAP-UI-BUILD-04 → **DART-067** |
| **FEAT-EQUIP-READY** | Equip-ready / wishlist vs owned pins | Equip-ready gate | PASS | N/A\* | PASS | **shipped** | DART-006/038/047; \*mobile equip path N/A (DART-057 matrix) |
| **FEAT-EQUIP-BUNGIE** | Bungie equip (partial OK) | Equip flow | PASS | N/A\* | PASS | **shipped** | DART-037/038/047; \*mobile equip **N/A** (DART-057 — use Windows/Jaspr) |
| **FEAT-EQUIP-DIM** | DIM jsonOnly export | DIM export | PASS | N/A\* | PASS | **shipped** | DART-010/039/047; \*mobile DIM **N/A** (DART-057 matrix) |
| **FEAT-OPTIMIZER** | Armor set optimizer (confirm-only) | Optimizer workspace | **PARTIAL** | deferred | deferred | **deferred** mobile/web + fidelity | Windows Sets optimizer confirm-only; not wired into Build Finish (GAP-UI-BUILD-04) or Settings post-sync (GAP-UI-SETTINGS-04); GAP-FEAT-01 remains deferred web/mobile → **DART-067** |

### C. Inventory & owned instances

| ID | Feature | Product evidence | Dart today | Plan | Slices / GAP |
| -- | ------- | ---------------- | ---------- | ---- | ------------ |
| **FEAT-INV-SYNC** | Full-replace inventory sync | Settings + `syncInventory` | Package + hosts; vault lookup wired (DART-050); web Settings sync (DART-056); fidelity program 050–054 | **shipped** (Windows + Jaspr) | **DART-050–054** done; **DART-056** web Settings; RB-06 + RB-02 cleared |
| **FEAT-INV-VAULT** | Vault + postmaster instances stored | Transfer bucket resolution | Lookup + host wiring (DART-050); harness DART-054 | **shipped** (fixture + harness) | **DART-050** + **DART-054** |
| **FEAT-INV-ROLL-TAGS** | God-roll / champion / build roll tags | `computeRollTags` | Pure + sync + host builders (DART-051) | **shipped** (golden + Windows raw; web frame-meta) | **DART-051** closed GAP-INV-02; residual: web perk names without raw defs |
| **FEAT-INV-SOCKETS** | Socket plugs for perk grids | `buildStoredSocketPlugs` | Pure + sync + Windows raw context (DART-052); web raw-less residual | **shipped** (fixture + Windows) | **DART-052** closed GAP-INV-03; residual: web without raw defs |
| **FEAT-INV-DIAG** | Sync diagnostics UI + logs | ManifestCard diagnostics | Windows retains + surfaces last diagnostics | **shipped** (P1) | **DART-053** / GAP-INV-04 closed |
| **FEAT-INV-HARNESS** | Next-vs-Dart live count harness | Manual dual sync | Dual-run doc + compare tool + offline gate | **shipped** (P0 process) | **DART-054** / GAP-INV-05 closed |
| **FEAT-INV-OWNED-JOIN** | Owned catalog = entities × inventory | Catalog owned mode | Bridge + All\|Owned **shipped**; fidelity **PARTIAL** — incomplete defs (legendary-only weapons / exotic-only armor) + raw instance detail (GAP-UI-CATALOG-04/05/08; GAP-INV-02/03 residual) | **shipped** + fidelity | Docs **DART-050**; UX **DART-053**; web Owned **DART-056**; residual browse fidelity → **DART-062/063** |
| **FEAT-INV-WEAPON-STATS** | Combat `statValues` on weapon rows | `parseWeaponStatValues` | Armor-hash parser reused | **planned** (P2) | Optional in **DART-050** / GAP-INV-07 |

### D. Auth, data, and ops

| ID | Feature | Product evidence | Dart today | Plan | Slices / GAP |
| -- | ------- | ---------------- | ---------- | ---- | ------------ |
| **FEAT-AUTH-PUBLIC** | Public+PKCE (no client secret in clients) | Next Confidential server | Windows/Jaspr Public+PKCE; mobile schemes published | **shipped** | Local DART-022/023/045; prod matrix **DART-058** / GAP-AUTH-01 **closed** / RB-03 cleared |
| **FEAT-DATA-MANIFEST** | Manifest / entity definitions | Next manifest pipeline | Entity stores + prebuilt web bundles | **shipped** | DART-017/018/044; prod hybrid channel **DART-059** / GAP-WEB-02 **closed** / RB-05 cleared |
| **FEAT-DATA-LEGACY-IMPORT** | Legacy Next `app.db` → StorageRoot | N/A (source) | Windows dry-run + apply | **shipped** | DART-048; RC-DATA PASS |
| **FEAT-DATA-OPFS** | Web OPFS single-tab writer | N/A (Node SQLite) | Jaspr OPFS writer | **shipped** | DART-043 |
| **FEAT-OPS-DUAL-RUN** | Dual-run + rollback procedure | Next sole prod today | Runbook + EXECUTED_ONCE + ops gate | **shipped** (P1) | **DART-060** / GAP-OPS-01 closed / RB-04 cleared |
| **FEAT-OPS-CUTOVER** | Production cutover re-gate | N/A | Checklist **PRODUCTION_CUTOVER: GO** | **shipped** (P1) | **DART-061** / GAP-CUT-01 **closed**; RC-BRANCH PASS; dim.gg (GAP-FEAT-02) non-goal — jsonOnly sufficient |

### E. Explicit non-goals / deferred (documented, not unplanned)

| ID | Feature | Product | Plan | Why documented |
| -- | ------- | ------- | ---- | -------------- |
| **FEAT-LLM** | LLM propose / multi-pass generator | Optional / not primary | **n/a** | GAP-FEAT-03; PRODUCT non-primary |
| **FEAT-DEBUG** | `/debug/*` operator tools | Present (404 in prod) | **n/a** | GAP-FEAT-04 |
| **FEAT-ANALYZE** | Analyze / legacy generator tab | Adjacent | **n/a** | GAP-FEAT-05 |
| **FEAT-DIM-SHARE** | dim.gg share URL | Optional | **deferred** | GAP-FEAT-02; jsonOnly enough for cutover |
| **FEAT-FLUTTER-WEB** | Flutter Web product target | — | **n/a** | Jaspr is web target (port decisions) |
| **FEAT-SHARE-LINKS** | Shareable public build links | PRODUCT open decision | **deferred** | Not cutover-blocking; no DART until product locks scope |

### Inventory planning coverage check

| Check | Result |
| ----- | ------ |
| Every AppShell nav key has a FEAT-NAV row | **Yes** (build, synergy, sets, catalog, settings, loadouts) |
| Every PRODUCT confirmed capability has a FEAT row | **Yes** (compose spine, inventory, optimizer, equip/export, LLM, legacy) |
| Every open/partial **P0/P1** cutover residual maps to DART-050–061 | **Yes** — cutover residuals closed; `unplanned_p0_p1` cutover = empty |
| Every open **P1 GAP-UI-*** maps to DART-062+ | **Yes** — see [ui-fidelity.md](./multiplatform-dart-ui-fidelity.md) + master table below |
| Every deferred/n/a has reason | **Yes** — section E + deferred gap table |
| Next Spec Kit start | **DART-062** (UI fidelity P1; cutover GO unchanged) |

---

## Phase plan (post DART-049)

| Phase | Theme | Planned slice range | Goal |
| ----- | ----- | ------------------- | ---- |
| **P6** | Inventory fidelity | DART-050–054 | Vault/postmaster parity, enrichment, diagnostics, live harness |
| **P7** | Nav & residual product surfaces | DART-055–057 | Loadouts; web sync depth; mobile gaps worth shipping |
| **P8** | Production readiness | DART-058–061 | Public auth matrix, entity CDN, dual-run ops, cutover re-gate (**GO**) |
| **P9** | Host UI fidelity (post-cutover) | DART-062–068 | Atlas/BR/DAC presentation parity on Windows+Jaspr; **not** cutover re-gate |

---

## Master gap table

| ID | Area | Severity | Status | Next.js evidence | Dart today | Planned slices | Cutover link |
| -- | ---- | -------- | ------ | ---------------- | ---------- | -------------- | ------------ |
| **GAP-INV-01** | Vault/postmaster bucket resolution | **P0** | `closed` (DART-050) | `buildEquipmentBucketLookup` + `resolveTransferContainerBuckets` in `src/lib/bungie/syncInventory.ts` | `buildEquipmentBucketLookup` + host wiring on Windows Settings/equip + Jaspr equip; package+host fixtures assert `resolvedFromTransfer > 0` | **DART-050** done | RB-06 partial (enrichment/harness remain 051–054) |
| **GAP-INV-02** | Roll tags enrichment | **P1** | `open` | `computeRollTags` + weapon-perks / WeaponRecord | `_normalizeItems` only emits `Crafted` when `isCrafted` | **DART-051** | Owned pickers / quality UX |
| **GAP-INV-03** | Socket plugs / perk grid enrichment | **P1** | `closed` (DART-052; web residual) | `buildStoredSocketPlugs` + weapon socket context | `classifyWeaponSocket` + `buildStoredSocketPlugs`; sync wires context builder; Windows raw defs | **DART-052** done | Instance perk grids; web raw-less → unenriched maps (PROC-06 residual, not pure thinning) |
| **GAP-INV-04** | Sync diagnostics UI | **P1** | `closed` (DART-053) | `formatSyncDiagnostics` + `[inventory-sync]` logs | Controller retains last diagnostics; Settings surfaces raw/parsed/dropped/resolution | **DART-053** done | Makes drops visible |
| **GAP-INV-05** | Live Next-vs-Dart inventory harness | **P0** | **`closed`** (DART-054) | Manual dual sync | Dual-run doc + compare tool + offline gate | **DART-054** | Prevents silent drift; equip pin fidelity |
| **GAP-INV-06** | Owned catalog needs entity stores | **P1** | `closed` (DART-053 UX + DART-056 web Owned) | Manifest refresh always online | Docs + Settings/Catalog entity empty warning; Jaspr All\|Owned + instance ids for pins | **DART-050** docs + **DART-053** UX + **DART-056** web Owned | UX after sync |
| **GAP-INV-07** | Weapon combat `statValues` on inventory rows | **P2** | `closed` (DART-050 opt) | `parseWeaponStatValues` for weapons + transfer containers | `parseWeaponStatValues` + transfer merge in `inventory_parse.dart` | **DART-050** optional delivered | Combat stats on vault weapons |
| **GAP-NAV-01** | In-Game Loadouts surface | **P1** | `closed` | `/loadouts` AppShell + page | Windows+Jaspr PASS (DART-055); mobile MISS density OK | **DART-055** | RB-01 cleared / RC-NAV PASS |
| **GAP-WEB-01** | Jaspr inventory sync + owned depth | **P1** | `closed` (DART-056) | Full Settings sync + owned catalog | Settings Sync now + vault lookup + diagnostics; Catalog All\|Owned + instance pins; equip still optional without write clients | **DART-056** done | RB-02 cleared / RC-SYNC web depth |
| **GAP-MOB-01** | Mobile AppShell nav / compose→equip matrix | **P2** | `closed` (DART-057) | Full desktop-class AppShell | Published matrix PASS/PARTIAL/N/A/deferred; Builds\|Settings nav; equip/catalog/DIM N/A | **DART-057** done | Phone surface matrix |
| **GAP-AUTH-01** | Prod Public redirect matrix (all shells) | **P1** | `closed` (DART-058) | Confidential Next HTTPS | Published matrix + secret scan; Windows HTTPS default; mobile schemes published (session deferred) | **DART-058** done | RB-03 cleared / RC-AUTH PASS |
| **GAP-WEB-02** | Entity bundle prod distribution | **P1** | `closed` (DART-059) | Full raw manifest pipeline | Hybrid ship-in-app + optional CDN; versioned channel | **DART-059** done | RB-05 cleared / RC-WEB-DATA PASS |
| **GAP-OPS-01** | Dual-run + rollback procedure | **P1** | `closed` (DART-060) | Next sole prod | Runbook executed once; compose→equip re-verify in dual-run window; rollback = keep Next | **DART-060** done | RB-04 cleared / RC-OPS PASS |
| **GAP-CUT-01** | Re-gate production cutover | **P1** | `closed` (DART-061) | N/A | Checklist **PRODUCTION_CUTOVER: GO** + all RC-* PASS | **DART-061** done | GO 2026-07-25; RC-BRANCH PASS |
| **GAP-UI-01** | Soft stat targets editor on Jaspr | **P2** | `closed` (DART-057) | Full `ArmorStatName` editor | All six stats + explicit save on web | **DART-057** done | Soft never auto-apply |
| **GAP-FEAT-01** | Armor optimizer on mobile/web | **P2** | `deferred` | Full UI | Windows only (by design for program gate) | remains deferred | Accept Windows-only |
| **GAP-FEAT-02** | dim.gg share | **P3** | `deferred` | Optional dim-export share | jsonOnly only | **DART-061** non-goal unless elevated | Cutover N/A |
| **GAP-FEAT-03** | LLM propose / multi-pass generator | **P3** | `deferred` | Optional / not primary | Not ported | *Non-goal* | Cutover N/A |
| **GAP-FEAT-04** | `/debug/*` operator tools | **P3** | `deferred` | Present | Not ported | *Non-goal* | Cutover N/A |
| **GAP-FEAT-05** | Analyze / legacy generator tab | **P3** | `deferred` | Adjacent | Not primary | *Non-goal* | Cutover N/A |
| **GAP-FEAT-06** | Finish-gaps host UX unwired | **P2** | `closed` (DART-057) | Next FinishTab gates equip/export | Windows+Jaspr host panels + finish-complete ∧ equip-ready CTAs; pure shared | **DART-057** done | FEAT-COMPOSE-FINISH residual → GAP-UI-BUILD-03 |

### Host UI fidelity (post–cutover GO) — detail in [multiplatform-dart-ui-fidelity.md](./multiplatform-dart-ui-fidelity.md)

**Note:** PRODUCTION_CUTOVER **GO** unchanged. These rows track host presentation vs Next atlas + BR/DAC/DBR surface rules. Soft never auto-applies; no CLIENT_SECRET.

| ID | Area | Severity | Status | Next.js evidence | Dart today | Planned slices | Cutover link |
| -- | ---- | -------- | ------ | ---------------- | ---------- | -------------- | ------------ |
| **GAP-UI-CATALOG-01** | Catalog multi-facet include/exclude UI | **P1** | `closed` | CatalogScreen chips slot/class/archetype/element/ammo/exotic OR/AND | Windows+Jaspr chips wired; pure filter OR/AND/exclude | **DART-062** | Not cutover; fidelity |
| **GAP-UI-CATALOG-02** | Catalog group-by | **P1** | `closed` | groupCatalogItems multi-dim | Pure `groupCatalogItems` + host group chips | **DART-062** | Not cutover; fidelity |
| **GAP-UI-CATALOG-03** | Universal mode + Set/Synergy actions | **P1** | `closed` | UniversalSearchPanel + Set/Synergy-only actions | Windows+Jaspr Universal + Create Set/Synergy CTAs (no Build kit attach) | **DART-063** | Not cutover; fidelity |
| **GAP-UI-CATALOG-04** | Exotic weapons in weapon catalog | **P1** | `closed` | weapons + exoticWeapons merge | `exotic-weapons` store + projector | **DART-062** | Not cutover; fidelity |
| **GAP-UI-CATALOG-05** | Legendary armor in armor catalog | **P1** | `closed` | exoticArmor + legendaryArmor merge | `legendary-armor` store + projector | **DART-062** | Not cutover; fidelity |
| **GAP-UI-CATALOG-06** | Synergy membership filter + tags | **P1** | `closed` | synergy include/exclude + linked on detail | Hosts wire linkedSynergyIds annotate + facet chips + detail badges | **DART-063** | Not cutover; fidelity |
| **GAP-UI-CATALOG-07** | Alpha sort by display name | **P2** | `closed` | compareDisplayName finalize | Alpha sort in `filterCatalogClient` | **DART-062** | Not cutover; fidelity |
| **GAP-UI-CATALOG-08** | Owned instance perk/stat cards | **P2** | `closed` | OwnedInstanceCard + perk grid + armor stats | Resolved plug cards + armor base-stat board when data present | **DART-063** | Names need map; residual when unresolved |
| **GAP-UI-CATALOG-09** | Item icons + dense meta chrome | **P2** | `open` | ItemIcon + MetaChips | Text ListTile / catalog-row | **DART-068** | Polish; see ui-polish-tracker |
| **GAP-UI-CATALOG-10** | Weapons/Armor kind modes | **P2** | `closed` | Weapons \| Armor \| Universal modes | Mode chips + kind-appropriate facets both hosts | **DART-063** | Not cutover; fidelity |
| **GAP-UI-BUILD-01** | Identity confirm/fork (DBR-ID-008) | **P1** | `open` | 409 IDENTITY_CONFIRM_REQUIRED Confirm/Fork | In-place identity edit; no identityAction | **DART-064** | Not cutover; fidelity |
| **GAP-UI-BUILD-02** | Subclass kit composer host UI | **P1** | `open` | SubclassTab full kit + capacity | Super pin text only | **DART-064** | Not cutover; fidelity |
| **GAP-UI-BUILD-03** | Finish slot-first one-tap walkthrough | **P2** | `open` | FinishBuildWalkthrough Create/Capture/fill | finish-gaps panel only (GAP-FEAT-06 residual) | **DART-067** | Not cutover; fidelity |
| **GAP-UI-BUILD-04** | Finish Armor improve path | **P2** | `open` | FinishArmorOptimizeWorkspace confirm apply | Optimizer on Sets only; not Build Finish | **DART-067** | Soft never auto-apply |
| **GAP-UI-BUILD-05** | Manifest search exotic/super pickers | **P2** | `open` | ManifestSearchPicker + icons | Raw hash TextFields | **DART-064** | Not cutover; fidelity |
| **GAP-UI-BUILD-06** | Variant read-only icon overview | **P2** | `open` | VariantCard DETAILS icon strips | Text attachments/pins only | **DART-068** | Polish |
| **GAP-UI-BUILD-08** | Client hard-block pre-save UX | **P2** | `open` | hardBlocks + plain-language disabled | Domain on save; thin host pre-filter | **DART-064** | Not cutover; fidelity |
| **GAP-UI-BUILD-09** | Jaspr attach/pin named pickers | **P2** | `open` | set search/tags + pin context | Free-text set id + pin | **DART-064** | Jaspr only |
| **GAP-UI-SETS-01** | Armor base-roll EoF six-stat board | **P1** | `open` | ArmorPieceStatRow + totals | No armorStatTotals | **DART-065** | DAC-NME-004 |
| **GAP-UI-SETS-02** | Set item rows meta/traits/synergies | **P1** | `open` | icons, traits, LINKED SYNERGIES | name(hash)·inst\|wishlist text | **DART-065** | Not cutover; fidelity |
| **GAP-UI-SETS-03** | Slot-fill embedded Catalog density | **P1** | `open` | SlotFillPanel Catalog grid | Text pickers; Jaspr hash-only | **DART-065** | Not cutover; fidelity |
| **GAP-UI-SETS-04** | Library search + tag AND filters | **P2** | `open` | SetsPage search + TYPE & TAGS | Unfiltered FlapBoard | **DART-066** | Not cutover; fidelity |
| **GAP-UI-SETS-05** | Readiness / Fill next / Used-by | **P2** | `open` | filled/capacity + FILL NEXT + USED BY | usedBy not rendered | **DART-066** | Not cutover; fidelity |
| **GAP-UI-SETS-06** | Delete set + SET_IN_USE | **P2** | `open` | Edit/Delete + SET_IN_USE error | deleteUserSet exists; no host control | **DART-066** | Not cutover; fidelity |
| **GAP-UI-SETS-07** | Occupied-slot replace confirm | **P2** | `open` | Confirm replace naming item | replaceExisting:true no dialog | **DART-065** | BR-SLOT-006 |
| **GAP-UI-SETS-10** | Weapon fill selectedPerks / traits | **P2** | `open` | selectedTraitPerks + store selectedPerks | hash/name/instanceId only | **DART-065** | BR-ROLL-001 |
| **GAP-UI-SYN-01** | Evidence catalog search picker | **P1** | `open` | Search catalog + filterOutLinked | Free-text + raw hash | **DART-066** | Not cutover; fidelity |
| **GAP-UI-SYN-02** | BR-SYN-012 weapon-perk source labels | **P1** | `open` | weaponPerkSourceLabel exotic/legendary | Free-text names only | **DART-066** | Not cutover; fidelity |
| **GAP-UI-SYN-03** | BR-SYN-004 reverse tags on catalog | **P1** | `closed` | linkedSynergies by-target badges | findSynergiesByTarget + detail badges both hosts | **DART-063** | Not cutover; fidelity |
| **GAP-UI-SYN-04** | Jaspr synergy detail/edit/links | **P1** | `open` | dual-pane detail + edit/delete | create+list only | **DART-066** | Jaspr only |
| **GAP-UI-SYN-05** | DesignationLabel verb/element icons | **P2** | `open` | DesignationLabel + icons | type::subType wire keys | **DART-068** | Polish |
| **GAP-UI-SYN-06** | Synergy library search/type filters | **P2** | `open` | SynergyFilters search + chips | setTypeFilter unwired | **DART-066** | Not cutover; fidelity |
| **GAP-UI-SYN-09** | Delete library synergy host action | **P2** | `open` | SynergyDetail Delete confirm | deleteUserSynergy; no control | **DART-066** | Not cutover; fidelity |
| **GAP-UI-LOADOUTS-01** | Color bar / swatch / icon plate | **P2** | `open` | LoadoutColorBar + IconPlate | iconUrl only; colorUrl unused | **DART-068** | Density only |
| **GAP-UI-LOADOUTS-02** | Exotic names on Bungie rows | **P2** | `open` | enrichLoadoutsWithExotics | exotic* fields unused | **DART-068** | Density only |
| **GAP-UI-LOADOUTS-03** | Details expand for Bungie slot | **P2** | `open` | expanded detail panel | No expansion state | **DART-068** | Density only |
| **GAP-UI-SETTINGS-01** | Manifest READY + entity count chips | **P2** | `open` | READY/STALE badge + Chip counts | Cached/Remote/Status text only | **DART-068** | Windows chrome |
| **GAP-UI-SETTINGS-02** | Inventory sync card presentation | **P2** | `open` | ONLINE chip + human last sync + Refresh | Sync now + raw ISO | **DART-068** | **BUG-20260725-003** |
| **GAP-UI-SETTINGS-04** | Post-sync soft armor kit banner | **P2** | `open` | Confirm/Dismiss better-kit Callout | No afterSync banner | **DART-067** | Soft never auto-apply |
| **GAP-UI-SHELL-01** | AppShell nav labels/order | **P2** | `open` | Loadouts, Build, Synergy, Sets, Catalog, Settings | Builds/Synergies labels; order diverge | **DART-068** | Not cutover; fidelity |

---

## Detailed gap specs (must plan)

### GAP-INV-01 — Vault / postmaster resolution (**P0**)

**Problem:** Vault (General) and Postmaster items use transfer bucket hashes. Without itemHash → equipment bucket lookup from Destiny definitions, they are **dropped** before Drift write. Equip-ready pin pool under-reports vault-owned gear vs Next.

**Evidence (2026-07-25 scan → closed by DART-050):**
- Next `performSync` always `buildEquipmentBucketLookup` + `resolveTransferContainerBuckets`.
- **DART-050 delivered:** `buildEquipmentBucketLookup` / `buildEquipmentBucketLookupFromSlots` in `packages/bungie`; `equipmentBucketLookupBuilder` on `syncUserInventory` / `syncIfStale`; Windows Settings + equip + Jaspr equip wire lookup; package/host fixtures assert `resolvedFromTransfer > 0` for vault fixtures; empty lookup remains only for drop-path tests (not production-OK in docs).
- Live dual-account count harness **DART-054 closed** (RB-06 cleared after 050–054).

**Next:** `src/lib/bungie/resolveEquipmentBuckets.ts` + `syncInventory.ts`  
**Dart:** `packages/bungie/lib/src/profile/equipment_bucket_lookup.dart`; host providers under `apps/windows_host` / `apps/web_host`.

**Slice: DART-050 `inventory-vault-resolution` — done**

| Field | Value |
| ----- | ----- |
| Branch / specs | `dart-050-inventory-vault-resolution` |
| Depends | DART-024, DART-018/017 (manifest entity path) |
| Deliverables | (1) `buildEquipmentBucketLookup` from DestinyInventoryItemDefinition + slot fallback. (2) Wired into Windows Settings `syncNow`, Windows equip `syncIfStale`, Jaspr equip `syncIfStale` (web Settings depth → DART-056). (3) Package docs require production lookup. (4) GAP-INV-06 residual → DART-053. (5) GAP-INV-07 parseWeaponStatValues delivered. |
| Exit criteria | Vault/postmaster fixtures land in Drift with equipment buckets; `resolvedFromTransfer > 0` asserted; host tests document fail-without-lookup path; finish-spec rejects “user can sync” alone |
| Status | **`closed`** (fixture proof; live harness DART-054 also closed) |
| Process | PROC-01/02 addressed; PROC-06: no intentional thinning in this slice |
| Cutover | RB-06 cleared after DART-050–054 enrichment + harness |

---

### GAP-INV-02 — Roll tags (**P1**) — **closed** (DART-051)

**Problem (was):** Next computes god-roll / perk-derived tags (Crafted, champion, build tags via weapon-perks map + WeaponRecord); Dart only tagged `Crafted`.

**Next:** `computeRollTags` in `src/lib/inventory/rollTags.ts` + sync normalize  
**Dart (now):** `packages/bungie` `computeRollTags` + `_normalizeItems` via perkNameMap / weaponRollMetaLookup builders; golden tests match Next fixtures; Windows Settings/equip wire raw plug names + OfflineCatalog frame meta; Jaspr equip wires catalog frame meta.

**Slice: DART-051 `inventory-roll-tags`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-051-inventory-roll-tags` |
| Depends | DART-050 (stable inventory set) |
| Exit criteria | Dart inventory normalize emits roll tags matching Next `computeRollTags` golden fixtures for sample crafted/champion/build weapons; soft never auto-applies; intentional thinning opens GAP residual at merge (PROC-06) |
| Status | **`done`** (2026-07-25) |
| Residual | Web/Jaspr without raw `DestinyInventoryItemDefinition` cannot resolve perk **names** (MeleeBuildCandidate / OrbitBuild / perk-champion) until weapon-perks entity store or injected map — **not** intentional pure-function thinning (golden parity holds). Frame champion + Crafted work from catalog. Track under RB-06 / DART-056 depth if web Settings needs full perk-name parity. Soft never auto-applies. |

---

### GAP-INV-03 — Socket plug enrichment (**P1**)

**Problem:** Next builds categorized stored socket plugs for perk grids (`columnKind` / `columnLabel`); Dart previously stored raw `socketCapture` map JSON only.

**Evidence (2026-07-25 → closed by DART-052):**
- Pure `classifyWeaponSocket` + `buildStoredSocketPlugs` mirror Next fixtures (barrel/mag/trait, cosmetics excluded, intrinsic/origin/mw/catalyst, enhanced trait frames).
- `syncUserInventory` accepts `weaponSocketContextBuilder`; weapons store plugs with `columnKind`/`columnLabel` when context provided; non-weapons null; no-context raw fallback.
- Windows Settings/equip wire raw DestinyInventoryItemDefinition context builder.
- **Residual (PROC-06, not pure thinning):** web/Jaspr MVP without raw item defs cannot classify columns until entity/raw channel (DART-056 depth / entity expansion) — raw capture maps only.

**Next:** `buildStoredSocketPlugs` + `loadWeaponSocketContext`  
**Dart:** `packages/bungie/lib/src/inventory/classify_weapon_socket.dart`, `build_stored_socket_plugs.dart`, `weapon_socket_context.dart`; sync + Windows host wiring

**Slice: DART-052 `inventory-socket-enrichment`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-052-inventory-socket-enrichment` |
| Depends | DART-050 |
| Exit criteria | Stored socket plugs for weapons include `columnKind`/`columnLabel` (or equivalent) usable by instance perk grids; parity tests with socket fixtures vs Next `buildStoredSocketPlugs`; intentional thinning opens GAP residual at merge (PROC-06) |
| Status | `done` (package + Windows; web residual documented) |

---

### GAP-INV-04 — Sync diagnostics UI (**P1**) — **closed (DART-053)**

**Problem (was):** Package computed `InventoryParseDiagnostics` + resolution on `SyncInventoryResult`, but controller only kept itemCount/syncVersion/lastFullSyncAt and InventorySyncCard had no diagnostics UI — silent vault loss.

**Next:** `ManifestCard` `formatSyncDiagnostics` + console `logInventorySyncDiagnostics`  
**Dart (done):** `formatSyncDiagnostics` in `destiny2_bungie`; `InventorySyncController.lastDiagnostics`; Windows `InventorySyncCard` surfaces raw/parsed/dropped/resolution; web Settings parity path notes GAP-INV-04/06.

**Slice: DART-053 `inventory-sync-diagnostics-ui`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-053-inventory-sync-diagnostics-ui` |
| Depends | DART-025, DART-050 |
| Exit criteria | Controller retains last sync diagnostics; Windows Settings surfaces raw/parsed/dropped + resolution; entity-cache empty warning; web Owned/entity parity warning |
| Status | **`closed`** |
| Related | GAP-INV-06 UX half (also closed under DART-053) |

---

### GAP-INV-05 — Live parity harness (**P0** process) — **closed**

**Problem:** No automated/manual dual-run inventory harness forced Next vs Dart counts by location/bucket. Live drift only surfaces post dual-use; equip pin fidelity depends on matching owned index.

**Closed by: DART-054 `inventory-live-parity-harness`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-054-inventory-live-parity-harness` |
| Depends | DART-050–053 |
| Exit criteria | Documented dual-run procedure + optional tool comparing Next vs Dart counts by location/bucket (and raw/stored/`resolvedFromTransfer`) for same membership; operator/CI gate for future inventory-sync changes; update cutover **RC-SYNC** pass condition to require vault/postmaster fidelity within agreed Next tolerance (or documented residual) — not only “documented sync path works” (PROC-04); inventory fidelity gate documented as **separate** from pure `p0_parity_gate` (PROC-05); closes PROC-03 |
| Status | **`closed`** (2026-07-25) |
| Process | PROC-03, PROC-04, PROC-05 **closed** |
| Cutover | RB-06 **cleared** |
| Evidence | [multiplatform-dart-inventory-live-parity-harness.md](./multiplatform-dart-inventory-live-parity-harness.md); `tool/inventory_fidelity_gate.dart`; `tool/inventory_fidelity_compare.dart`; fixtures under `tool/fixtures/inventory_fidelity/` |

---

### GAP-INV-06 — Owned catalog needs entity stores (**P1** partial → UX closed)

**Problem:** `OwnedCatalogBridge` annotates `OfflineCatalog.baseItems` with inventory counts; Catalog empty states require entity cache version/stores. Inventory sync alone cannot populate Owned definitions — vault fix (DART-050) is necessary but not sufficient.

**Next:** catalog filter / owned join always has manifest entities  
**Dart:** `owned_catalog_bridge.dart`; catalog_page empty messages; Settings entity-cache empty warning (DART-053)

**Ownership (dual):**
- **DART-050 (done):** Documented entity-store dependency remains after vault resolution; packages/README states empty entity cache ≠ empty vault / Owned needs entities.
- **DART-053 (done):** Settings entity-cache empty warning + Catalog Owned empty prefers entity message; web Settings Owned/entity dependency warning.
- **DART-056 (done):** Jaspr Catalog All\|Owned + instanceId projections for equip/DIM pins; Settings Sync now with vault resolution.

| Field | Value |
| ----- | ----- |
| Exit criteria | After inventory sync, Owned scope is usable when entity cache is populated; Settings/Catalog UX clearly warns when entity cache missing/empty; documented dependency remains after DART-050 vault fix |
| Status | **`closed`** (docs + UX + web Owned depth) |
| Planned slices | **DART-050** (docs **done**) + **DART-053** (UX **done**) + **DART-056** (web Owned **done**) |

---

### GAP-INV-07 — Weapon combat `statValues` on inventory rows (**P2**)

**Problem (historical):** Dart reused armor-hash parser for weapons/transfer.  
**DART-050 fix:** `parseWeaponStatValues` + transfer merge (weapon or armor hashes) in `inventory_parse.dart`.

**Next:** `src/lib/inventory/instances/weaponStats.ts`  
**Dart:** `packages/bungie/lib/src/profile/inventory_parse.dart` (`kWeaponStatHashToName`, `parseWeaponStatValues`)

| Field | Value |
| ----- | ----- |
| Exit criteria | Weapon and vault/postmaster weapon instances store combat stats (RPM/Impact/Range/etc.) comparable to Next `parseWeaponStatValues` fixtures; armor stats remain armor-hash mapped |
| Status | **`closed`** (DART-050 optional deliverable) |
| Severity | P2 |

---

### GAP-NAV-01 — In-Game Loadouts (**P1**)

**Problem:** Next `NAV_LINKS` includes loadouts → `/loadouts` with a real page. Windows NavigationRail omitted Loadouts; mobile NavigationBar is Builds|Settings only; Jaspr ShellHeader/Router had no `/loadouts`. Schema table only for local snapshots; no shell UI. RC-NAV FAIL / RB-01.

**Slice: DART-055 `in-game-loadouts-surface` — closed**

| Field | Value |
| ----- | ----- |
| Branch | `dart-055-in-game-loadouts-surface` |
| Depends | DART-024 profile path; Windows host first |
| Exit criteria | First-class Loadouts UI reachable from primary shell nav on Windows (and plan/route for Jaspr) listing Bungie in-game loadouts comparable to product `/loadouts`, **or** product removes/demotes loadouts from AppShell NAV_LINKS with explicit PRODUCT note; host greps for nav labels/routes include Loadouts; cutover matrix loadouts row PASS or N/A; clears RB-01/RC-NAV when done |
| Status | **`closed`** (2026-07-25) — pure parse component 206 + presentation; Windows nav+page; Jaspr `/loadouts`; matrix PASS Windows+web; RB-01 cleared; RC-NAV PASS for loadouts |
| Cutover | RB-01 **cleared** |

---

### GAP-WEB-01 — Jaspr sync + owned depth (**P1**)

**Problem:** Web equip is optional when write clients missing; Settings sync thinner than Next; owned depth insufficient for equip/DIM pins until vault resolution + web path share rules.

**Planned slice: DART-056 `jaspr-inventory-sync-depth`** — **closed 2026-07-25**

| Field | Value |
| ----- | ----- |
| Branch | `dart-056-jaspr-inventory-sync-depth` |
| Depends | DART-050, DART-045 |
| Exit criteria | Web sync applies same vault/transfer resolution as Windows post-DART-050; Owned catalog usable to pin instances for equip/DIM on Jaspr build compose; RC-SYNC no longer fails solely for web owned depth; clears RB-02 |
| Status | **`closed`** |
| Cutover | RB-02 **cleared** |
| Evidence | Jaspr `InventorySyncController` + Settings card call `syncUserInventory` with lazy `createWebEquipmentBucketLookupBuilder` (catalog slots); vault fixtures assert `resolvedFromTransfer > 0` + Kinetic/Helmet stored; Catalog All\|Owned + instanceId projections for compose pin; diagnostics retained (DART-053 parity). Specs: `specs/dart-056-jaspr-inventory-sync-depth/`. Tests: `apps/web_host/test/inventory_sync_*`, `catalog_owned_page_test`. Residual: equip still optional when write clients missing (product OK); legendary armor without prebuilt slot labels may drop (PROC-06 / entity coverage, not pure thinning). |

---

### GAP-MOB-01 — Mobile AppShell nav / compose→equip matrix (**P2**)

**Problem (was):** Mobile bottom nav is Builds|Settings only; catalog/equip/DIM unstated MISS; no published matrix.

**Closed by DART-057:** Published `kMobileSurfaceMatrix` in `apps/mobile_host/lib/surface_matrix.dart` (build PASS, settings PARTIAL, synergy/sets/catalog/loadouts/equip/dim **N/A**, optimizer **deferred**). Settings surfaces matrix card. shell_nav tests match Builds|Settings. Compose still designates synergy + attaches sets; equip/DIM path remains Windows/Jaspr (OAuth deferred). Soft never auto-applies.

| Field | Value |
| ----- | ----- |
| Branch | `dart-057-mobile-compose-equip-polish` |
| Status | `closed` |
| Evidence | `surface_matrix.dart` + Settings card; tests `surface_matrix_test`, `shell_nav_test` |
| Related | GAP-UI-01, GAP-FEAT-06 closed same slice; GAP-FEAT-01 remains deferred |

---

### GAP-UI-01 — Soft stat targets editor on Jaspr (**P2**)

**Problem (was):** Jaspr soft-stat editor was Health-only.

**Closed by DART-057:** Jaspr `build_compose_page` exposes all `ArmorStatName` fields with explicit save via `saveSoftStatTargetsFromFields`. Soft never auto-applies.

| Field | Value |
| ----- | ----- |
| Status | `closed` |
| Evidence | `apps/web_host/lib/builds/build_compose_page.dart`; `soft_guidance_format_test` multi-stat |

---

### GAP-FEAT-06 — Finish-gaps host UX unwired (**P2**)

**Problem (was):** Pure `evaluateFinishGaps` had zero host wiring; equip/export not finish-gated.

**Closed by DART-057:** Windows + Jaspr compose evaluate finish gaps from attachments + slot pins; display category complete reasons; equip Apply + DIM Copy require **finish-complete AND equip-ready**. Mobile shows finish display only (equip N/A). Pure domain remains shared. Soft never auto-applies.

| Field | Value |
| ----- | ----- |
| Branch | `dart-057-mobile-compose-equip-polish` |
| Status | `closed` |
| Evidence | `finish_gaps_format.dart` on windows/web/mobile; panels + CTA helpers; host format tests |
| Residual | Full FinishBuildWalkthrough one-tap create / skip / optimizer workspace not ported (category readiness + CTA policy is the cutover bar) |

---

### GAP-AUTH-01 — Prod Public redirect matrix (**P1**) — **closed**

**Problem:** Dart shells implement Public+PKCE only (no client_secret API surface). Windows loopback + Jaspr `/auth/callback` exist; mobile OAuth deferred; prod Public redirect matrix was not ops-signed (RC-AUTH FAIL / RB-03). Confidential secrets remain Next-server-only until cutover.

**Slice: DART-058 `prod-public-oauth-matrix`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-058-prod-public-oauth-matrix` |
| Depends | DART-023/045 |
| Exit criteria | Published Bungie Public app redirect matrix for Windows HTTPS loopback, Jaspr production origin (`/auth/callback`), and mobile schemes; live sign-in smoke on each cutover-required shell; binary/source scan shows zero `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET`; RC-AUTH PASS and RB-03 cleared |
| Status | **`closed`** (2026-07-25) |
| Cutover | RB-03 **cleared**; RC-AUTH **PASS** |
| Evidence | [multiplatform-dart-prod-public-oauth-matrix.md](./multiplatform-dart-prod-public-oauth-matrix.md); `ProdPublicOAuthMatrix` in `destiny2_bungie`; Windows default HTTPS; `tool/client_secret_scan.dart`; host OAuth session tests |
| Residual | Mobile OAuth **session** host still deferred (schemes published); operator live portal re-verify on cutover day |

---

### GAP-WEB-02 — Entity bundle channel (**P1**) — **closed (DART-059)**

**Problem:** Jaspr loaded MVP fixture prebuilt JSON with no production channel decision (RC-WEB-DATA FAIL / RB-05).

**Slice: DART-059 `entity-bundle-prod-channel`** — **done**

| Field | Value |
| ----- | ----- |
| Branch | `dart-059-entity-bundle-prod-channel` |
| Depends | DART-044 |
| Exit criteria | Chosen channel (ship-in-app / CDN / hybrid) documented with versioning; prod web Catalog loads non-fixture entity data offline after install; offline compose works without Next manifest API; RC-WEB-DATA PASS and RB-05 cleared |
| Status | `closed` |
| Cutover | RB-05 **cleared** |
| Evidence | [multiplatform-dart-entity-bundle-channel.md](./multiplatform-dart-entity-bundle-channel.md); `EntityBundleChannel` + hybrid resolve; `WebEntityBundleLoader` channel-aware; `/entities/channel.json` + `/entities/prod/bundle.json`; tests in `packages/manifest` + `apps/web_host` |
| Residual | Operators replace sample prod bundle with full extract for live catalog size; CDN host optional |

---

### GAP-OPS-01 — Dual-run ops (**P1**) — **closed** (DART-060)

**Problem (was):** Dual-run + rollback ops had not been executed (RC-OPS FAIL / RB-04). Compose→equip RC-EQUIP was historically PASS but needed re-verify not historical only.

**Closed by: DART-060 `dual-run-rollback-ops`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-060-dual-run-rollback-ops` |
| Depends | Windows + Jaspr feature complete enough for dual-run |
| Exit criteria | Written dual-run runbook executed once with Next + Dart web/Windows available; re-verify compose→equip (equip-ready gate, Bungie equip partial OK, DIM jsonOnly) live not historical only; rollback path = keep Next sole production; execution notes attached to cutover checklist; RC-OPS PASS and RB-04 cleared |
| Status | **`closed`** (2026-07-25) |
| Cutover | RB-04 **cleared**; RC-OPS **PASS** |
| Evidence | [multiplatform-dart-dual-run-rollback-runbook.md](./multiplatform-dart-dual-run-rollback-runbook.md) (EXECUTION_NOTES EXECUTED_ONCE); `tool/dual_run_ops_gate.dart`; host equip/DIM re-verify in dual-run window |
| Residual | Operator live Bungie character equip recommended again on cutover day (DART-061); inventory dual-run remains DART-054 |

---

### GAP-CUT-01 — Production cutover re-gate (**P1**) — **closed** (DART-061)

**Problem (was):** `PROGRAM_GATE: GO` / `PRODUCTION_CUTOVER: NO-GO` remained while formal re-gate / RC-BRANCH were incomplete.

**Closed by: DART-061 `production-cutover-regate`**

| Field | Value |
| ----- | ----- |
| Branch | `dart-061-production-cutover-regate` |
| Depends | DART-050–060 residual blockers cleared |
| Exit criteria | All `RC-*` pass or product-waived with written note; `PRODUCTION_CUTOVER: GO` with date/rationale; merge policy allows `feature/multiplatform-dart` toward production/main only after GO (RC-BRANCH); dim.gg share remains non-goal (jsonOnly sufficient) unless product elevates (GAP-FEAT-02) |
| Status | **`closed`** / **done** (2026-07-25) |
| Cutover | **PRODUCTION_CUTOVER: GO**; **RC-BRANCH PASS**; offline `dart run tool/production_cutover_regate.dart` |
| Evidence | [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) verdict; [multiplatform-dart-branching.md](./multiplatform-dart-branching.md) RC-BRANCH section; specs `specs/dart-061-production-cutover-regate/` |
| Residual | GAP-FEAT-02 dim.gg remains **deferred** / non-goal (jsonOnly sufficient); actual main merge + Next tree retirement are human/release follow-on after GO |

---

## Process gaps (why P0 inventory issues shipped)

| ID | Severity | Status | Process miss | Fix (planned into slices) | Exit criteria |
| -- | -------- | ------ | ------------ | ------------------------- | ------------- |
| **PROC-01** | P0 | `closed` (DART-050) | DART-024/025 closed on “user can sync” only | **DART-050** exit criteria + finish-spec | Vault/postmaster fixtures land in Drift with equipment buckets; `resolvedFromTransfer > 0` asserted in package + host tests |
| **PROC-02** | P0 | `closed` (DART-050) | Production hosts omitted lookup | **DART-050** host wiring | Windows Settings/equip + Jaspr equip wire builder; package docs require production lookup; host tests assert vault resolution |
| **PROC-03** | P0 | **`closed`** (DART-054) | No live dual-account Next-vs-Dart inventory harness | **DART-054** | Documented operator procedure + optional script compares counts by location/bucket (and raw/stored/`resolvedFromTransfer`); CI or pre-merge operator gate; closes GAP-INV-05 |
| **PROC-04** | P1 | **`closed`** (DART-054) | RC-SYNC pass = “documented sync path works”; evaluation coarse vs RB-06 fidelity | **DART-054** checklist update | Cutover RC-SYNC pass condition requires vault/postmaster present within agreed Next tolerance (or documented residual), referencing DART-050–054 evidence; RB-06 clearance tied to fidelity metrics |
| **PROC-05** | P1 | **`closed`** (DART-054) | Spec Kit / pure `p0_parity_gate` green ≠ product inventory sameness; unit tests pass with empty lookup | **DART-054** + gaps workflow | `dart-gaps-analysis` (or successor) required after inventory slices; DART-054 harness or fixture-compare gate blocks claiming inventory parity; `p0_parity_gate` remains domain-only but inventory fidelity has an explicit separate gate (`tool/inventory_fidelity_gate.dart`) |
| **PROC-06** | P1 | `open` | DART-024 documented intentional transfer drop (A2/R2) and closed without opening GAP-INV-01 / RB residual at merge time | **DART-050** finish-spec checklist; enforce for **051/052** enrichments | Finish-spec for any DART slice that documents intentional product thinning: create/update GAP-* row + cutover residual RB in the same change; no silent “MVP ok” without residual tracker. Retro: GAP-INV-01/RB-06 already opened — enforce for roll tags/sockets so they never close phase gates as full parity |

---

## Deferred / non-goals (do not invent slices unless product changes)

| ID | Item | Reason | Slice note |
| -- | ---- | ------ | ---------- |
| GAP-FEAT-01 | Optimizer on mobile/web | Windows-first acceptable unless product elevates | Remain deferred on **DART-057** unless elevated; then confirm-only materialize/apply, soft never auto-apply |
| GAP-FEAT-02 | dim.gg share | jsonOnly sufficient for cutover spine | **Remains non-goal** after **DART-061** GO unless product elevates share URL parity without secrets in clients |
| GAP-FEAT-03 | LLM multi-pass / propose primary | PRODUCT non-primary | *Non-goal* |
| GAP-FEAT-04 | `/debug/*` | Operator non-goal for port | *Non-goal* |
| GAP-FEAT-05 | Analyze primary tab | Adjacent legacy | *Non-goal* |

**Closed on DART-057:** **GAP-FEAT-06** (finish-gaps host UX), **GAP-MOB-01**, **GAP-UI-01**. **GAP-FEAT-01** remains deferred (optimizer mobile/web).  
**Post-cutover fidelity:** Full GAP-UI-* detail + rules matrix + exit criteria live in [multiplatform-dart-ui-fidelity.md](./multiplatform-dart-ui-fidelity.md) (do not duplicate prose here unless a slice closes a gap).

---

## Update checklist (after gaps analysis or finish-spec)

- [x] Touch **Updated** date (2026-07-25 — UI fidelity residual audit; cutover GO unchanged)
- [x] Refresh **Product feature inventory** (sections A–E) — fidelity PARTIAL demotions for catalog/build/sets/synergy/identity/finish/hard/owned-join/optimizer
- [x] Set gap **Status** — GAP-UI-* `open` with planned DART-062–068; cutover gaps remain closed
- [x] Ensure every open **P1 GAP-UI-*** has planned **DART-062+** (see fidelity master)
- [x] Cutover checklist **not** re-gated (PRODUCTION_CUTOVER GO stands)
- [x] Append DART-062–068 planned rows on [slice roadmap](./multiplatform-dart-slice-roadmap.md)
- [x] Cross-link [ui-fidelity.md](./multiplatform-dart-ui-fidelity.md); pure visual density only on [ui-polish-tracker.md](./ui-polish-tracker.md)
- [x] Soft never auto-applies; no CLIENT_SECRET

---

## Current pointer (post-program + UI fidelity planning)

| Field | Value |
| ----- | ----- |
| **Next planned slice** | **DART-064** `build-identity-subclass-compose` (UI fidelity P1) |
| **Next phase** | **P9** host UI fidelity (DART-062–063 **done**, DART-064–068 planned); P8 cutover program **done** |
| **Blocker for cutover** | **None** — PRODUCTION_CUTOVER **GO** (2026-07-25); RC-BRANCH **PASS**; GAP-CUT-01 **closed** |
| **Feature inventory** | Complete; fidelity PARTIAL on nav/compose browse density; loadouts/settings remain PASS |
| **unplanned_p0_p1** | *(empty for cutover)*; open **P1 GAP-UI-*** all map to DART-062–066 |
| **Open GAP-UI count** | **40** (canonical table in ui-fidelity.md) |
| **Non-goal residual** | **GAP-FEAT-02** dim.gg remains deferred (jsonOnly sufficient) |
| **Bug crosswalk** | **BUG-20260725-003** → **GAP-UI-SETTINGS-02** |
