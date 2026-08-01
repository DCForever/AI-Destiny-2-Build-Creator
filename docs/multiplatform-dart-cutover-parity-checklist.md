# Multiplatform Dart — Cutover Parity Checklist (DART-049)

> **DART-069:** Dart workspace root is `flutter/`. Prefer `cd flutter` then `dart run tool/...`. Host paths are `flutter/apps/...`.

**Status:** active program gate artifact  
**Updated:** 2026-07-25 (DART-061 production cutover re-gate; **PRODUCTION_CUTOVER_GO**; RC-BRANCH PASS; GAP-CUT-01 closed)  
**Program ID:** DART-049 (checklist) + **DART-061** (production cutover re-gate)  
**Phase:** P5 / **program gate** + P8 / **production readiness**  
**Integration base:** `feature/multiplatform-dart`  
**Architecture:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md)  
**Roadmap:** [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md)  
**Product production nav source:** `src/components/AppShell.tsx` (`NAV_LINKS`)  
**Product intent:** `PRODUCT.md` (compose→equip spine)  
**Offline re-gate:** `dart run tool/production_cutover_regate.dart` (DART-061)

This document is the **canonical written parity checklist** for retiring Next.js as the production host. **`PRODUCTION_CUTOVER: GO` authorizes** merge of `feature/multiplatform-dart` toward production/`main` and Next retirement ops; it does **not** auto-merge or delete the Next tree.

---

## Dual gates

| Gate | Meaning | Marker |
| ---- | ------- | ------ |
| **P5 / program gate** | Planned DART-001…049 slices delivered; checklist + residual list exist | `PROGRAM_GATE` |
| **Production cutover** | Next may stop being the sole production web host; multiplatform line may merge toward production/`main` | `PRODUCTION_CUTOVER` / **PRODUCTION_CUTOVER_GO** |

Program completion ≠ automatic Next retirement; **GO** is the explicit cutover decision (DART-061 / GAP-CUT-01).

---

## Verdict

```
PROGRAM_GATE: GO
PRODUCTION_CUTOVER: GO
```

**Date:** 2026-07-25  

**Marker:** `PRODUCTION_CUTOVER_GO` (machine-checked by `tool/production_cutover_regate.dart`)

**PROGRAM_GATE rationale:** All planned multiplatform slices through DART-049 are specified/implemented on `feature/multiplatform-dart` (domain → Drift → Flutter Windows → mobile → Jaspr → import → this checklist). Validator for this document is green. P5 exit (“Next retirement gates **documented**”) is satisfied.

**PRODUCTION_CUTOVER rationale (DART-061):** All residual blockers **RB-01…RB-06** are **CLEARED** (DART-050–060). Every **RC-*** criterion is **PASS**, including **RC-BRANCH** (merge of `feature/multiplatform-dart` toward production/`main` is allowed **only after** this GO — see [branching.md](./multiplatform-dart-branching.md)). Offline re-gate green; dual-run ops executed once; inventory fidelity gate green; Public OAuth matrix + secret scan green; entity hybrid channel green; soft never auto-applies; no `CLIENT_SECRET` / `SESSION_SECRET` in Flutter/Jaspr clients. **GAP-CUT-01** closed. **GAP-FEAT-02** (dim.gg share) remains **non-goal** — **jsonOnly** DIM is sufficient for the cutover spine unless product elevates share URL parity.

**After GO (ops):** A human/release engineer may merge `feature/multiplatform-dart` toward production/`main` and schedule Next domain-route retirement. DART slice finish-spec still lands on `feature/multiplatform-dart` only. Recommended: re-smoke live Bungie portal redirects + character equip on cutover day (hygiene; not a re-open of RB-*).

### Residual blockers

| ID | Blocker | Blocks | Planned work |
| -- | ------- | ------ | ------------ |
| ~~**RB-01**~~ | ~~Product **In-Game Loadouts** (`/loadouts`) has no first-class Dart shell surface~~ | ~~RC-NAV~~ | **CLEARED (2026-07-25)** by **DART-055** / GAP-NAV-01: Windows NavigationRail **Loadouts** + Jaspr `/loadouts` list Bungie component 206; pure parse in `destiny2_bungie`. Mobile top-level nav remains reduced (MISS/N/A — does not fail RC-NAV). |
| ~~**RB-02**~~ | ~~Jaspr web inventory sync + owned catalog filter remain thinner than Next Settings/catalog owned mode~~ | ~~RC-SYNC~~ | **CLEARED (2026-07-25)** by **DART-056** / GAP-WEB-01: Jaspr Settings Sync now + vault/transfer lookup (catalog slots, same rules as DART-050 equip path); diagnostics retained; Catalog All\|Owned + instanceId projections for equip/DIM pins. Host vault fixtures assert `resolvedFromTransfer > 0`. Residual: equip optional when write clients missing; legendary armor without prebuilt slots may drop (entity coverage). |
| ~~**RB-03**~~ | ~~Production Bungie **Public** app redirect matrix + hosting for Jaspr origin not ops-signed~~ | ~~RC-AUTH~~ | **CLEARED (2026-07-25)** by **DART-058** / GAP-AUTH-01: published matrix [multiplatform-dart-prod-public-oauth-matrix.md](./multiplatform-dart-prod-public-oauth-matrix.md) + `ProdPublicOAuthMatrix` (Windows HTTPS loopback, Jaspr `/auth/callback`, mobile schemes); client secret scan `tool/client_secret_scan.dart`; Windows+Jaspr smoke preflight (mocked session tests + operator checklist). |
| ~~**RB-04**~~ | ~~Dual-run / rollback procedure (Next + Dart) not executed in a release window~~ | ~~RC-OPS~~ | **CLEARED (2026-07-25)** by **DART-060** / GAP-OPS-01: written dual-run runbook executed once ([multiplatform-dart-dual-run-rollback-runbook.md](./multiplatform-dart-dual-run-rollback-runbook.md)); Next + Windows + Jaspr available; compose→equip re-verify (equip-ready, Bungie equip partial OK, DIM jsonOnly); rollback = keep Next sole production; offline gate `dart run tool/dual_run_ops_gate.dart`. |
| ~~**RB-05**~~ | ~~Entity bundle distribution channel for web (ship-in-app vs CDN) not production-hardened~~ | ~~RC-WEB-DATA~~ | **CLEARED (2026-07-25)** by **DART-059** / GAP-WEB-02: **hybrid** channel (ship-in-app primary + optional CDN) documented with versioning ([entity-bundle-channel.md](./multiplatform-dart-entity-bundle-channel.md)); prod path `/entities/channel.json` + `/entities/prod/bundle.json`; loader fallback + source report; offline Catalog without Next manifest API. |
| ~~**RB-06**~~ | ~~**Inventory fidelity:** vault/postmaster unwired + enrichment thinner + no live harness~~ | ~~RC-SYNC fidelity~~ | **CLEARED (2026-07-25)** by **DART-050–054**: vault lookup (050), roll tags (051), sockets (052), diagnostics UI (053), live/fixture harness + fidelity gate (054 / GAP-INV-05 / PROC-03/04/05). Evidence: package+host fixtures; [multiplatform-dart-inventory-live-parity-harness.md](./multiplatform-dart-inventory-live-parity-harness.md); `dart run tool/inventory_fidelity_gate.dart`. Web owned depth cleared separately by **RB-02** / DART-056. |

Canonical **product feature inventory** + gap list + exit criteria: [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md).  
**Formal GO:** All residual blockers cleared **and** all `RC-*` **PASS** → **`PRODUCTION_CUTOVER: GO`** (2026-07-25, **DART-061** / **GAP-CUT-01** closed). **GAP-FEAT-02** dim.gg remains non-goal (jsonOnly sufficient).

**Cleared residuals:** RB-01 (in-game loadouts surface DART-055); RB-02 (Jaspr inventory sync + Owned depth DART-056); RB-03 (prod Public OAuth matrix DART-058); RB-04 (dual-run + rollback ops DART-060); RB-05 (entity bundle prod channel DART-059); RB-06 (inventory fidelity program DART-050–054).

---

## Product production nav parity

Source of truth: `AppShell` `NAV_LINKS` (not `/debug/*`).

Status legend:

| Status | Meaning |
| ------ | ------- |
| **PASS** | Primary surface exists and supports the product job for that shell |
| **PARTIAL** | Present with reduced density or subset of actions |
| **MISS** | Not present as a first-class surface |
| **N/A** | Explicit non-goal for multiplatform port / not required for cutover |

| Nav key | Product path | Product label | Windows Flutter | Mobile Flutter | Jaspr web | Notes / evidence |
| ------- | ------------ | ------------- | --------------- | -------------- | --------- | ---------------- |
| `build` | `/build` | Build | **PASS** | **PARTIAL** | **PASS** | Windows: library + identity + variants + soft + equip + DIM + optimizer. Mobile: list + linear compose (DART-041). Web: compose + equip/DIM (DART-046/047). |
| `synergy` | `/synergy` | Synergy | **PASS** | **N/A**\* | **PASS** | Windows DART-031; web DART-046. \*Mobile: in-flow only via build compose; no top-level library nav (acceptable for phone density). |
| `sets` | `/sets` | Sets | **PASS** | **N/A**\* | **PASS** | Windows DART-030; web DART-046. \*Same mobile note as synergy. |
| `catalog` | `/catalog` | Catalog | **PASS** | **MISS** | **PASS** | Windows offline+owned (DART-020/026). Web facets + prebuilt + All\|Owned + instance pins (DART-044/056). Mobile catalog browse not primary nav. |
| `settings` | `/settings` | Settings | **PASS** | **PARTIAL** | **PASS** | Windows: OAuth, inventory sync, manifest, legacy import. Mobile: settings shell. Web: account + OPFS + inventory Sync now + vault resolution (DART-056). |
| `loadouts` | `/loadouts` | In-Game Loadouts | **PASS** | **MISS**\* | **PASS** | **DART-055**: Windows NavigationRail + page lists Bungie character loadouts (component 206); Jaspr ShellHeader `/loadouts` route + page. Pure parse/presentation in `packages/bungie`. \*Mobile top-level Loadouts not required for RC-NAV (reduced nav). RB-01 **cleared**. |

### Adjacent product surfaces (not AppShell gates)

| Surface | Product | Cutover treatment |
| ------- | ------- | ----------------- |
| `/analyze` | Adjacent / legacy generator entry | **N/A** — not AppShell primary; do not block cutover |
| `/debug/*` | Operator tooling (404 in production) | **N/A (non-goal)** — port roadmap forbids as primary nav |
| LLM propose / multi-pass generator | Optional product capability | **N/A (non-goal)** for early port / cutover |
| dim.gg share | Optional | **N/A (non-goal)** — **GAP-FEAT-02**; jsonOnly DIM is enough for cutover spine (DART-061) |
| Flutter Web | — | **N/A** — Jaspr is web target |

---

## Capability parity (compose→equip spine)

Domain packages are shared; UI shells differ.

| Capability | Product (Next) | Windows | Mobile | Web (Jaspr) | Notes |
| ---------- | -------------- | ------- | ------ | ----------- | ----- |
| Hard constraints on save/attach | Yes | **PASS** | **PASS** | **PASS** | DART-003 + app use cases DART-028; golden/domain suite DART-011 |
| Soft coverage display (never auto-apply) | Yes | **PASS** | **PASS** | **PASS** | DART-004/034/041/046 — soft is display-only |
| Soft stat targets (explicit save) | Yes | **PASS** | **PASS** | **PARTIAL** | Soft never auto-applies on all hosts |
| Resolve variant / conflicts | Yes | **PASS** | **PASS** | **PASS** | DART-005 |
| Equip-ready / wishlist vs owned pins | Yes | **PASS** | **PARTIAL** | **PASS** | DART-006/038/047 |
| Finish gaps helpers | Yes | **PASS** | **PARTIAL** | **PASS** | DART-007 pure + **DART-057** host panels (Windows+Jaspr); CTA = finish-complete ∧ equip-ready; mobile display-only (equip N/A) |
| Armor optimizer (confirm-only) | Yes | **PASS** | **MISS** | **MISS** | DART-035/036 Windows; not required on mobile/web for program gate; product cutover may accept Windows-only optimizer |
| Bungie Public+PKCE auth | Confidential cookies on Next | **PASS** | **PARTIAL** | **PASS** | DART-022/023/045 + prod matrix **DART-058** — **no CLIENT_SECRET**; mobile schemes published, session host deferred |
| Inventory sync full-replace | Yes | **PASS** | **PARTIAL** | **PASS** | Vault lookup **DART-050**, roll tags **DART-051**, sockets **DART-052**, diagnostics UI **DART-053**, live/fixture harness **DART-054** (RB-06 **cleared**); Jaspr Settings sync + Owned depth **DART-056** (RB-02 **cleared**). Mobile residual → DART-057. |
| Bungie equip (partial OK) | Yes | **PASS** | **MISS** | **PASS** | DART-037/038/047 |
| DIM jsonOnly export | Yes | **PASS** | **MISS** | **PASS** | DART-010/039/047; blocked when not equip-ready |
| Legacy `app.db` import | N/A (source) | **PASS** | **N/A** | **N/A** | DART-048 dry-run + apply → StorageRoot |
| OPFS single-tab writer (web) | N/A (Node SQLite) | N/A | N/A | **PASS** | DART-043 |
| Prebuilt entity bundles (web) | Full manifest pipeline | N/A | N/A | **PASS** | DART-044 + prod **hybrid** channel **DART-059** (RB-05 cleared) |
| Pure Dart I/O (no Node sidecar) | Next is current product | **PASS** | **PASS** | **PASS** | D-IO locked |

---

## Next retirement criteria

All criteria must be **pass** before `PRODUCTION_CUTOVER: GO`. Soft guidance auto-apply and CLIENT_SECRET in clients are **hard non-regressions**.

| ID | Criterion | Pass condition | Evidence pointer | Status (2026-07-25) |
| -- | --------- | -------------- | ---------------- | ------------------- |
| **RC-NAV** | Production nav parity for required spine | `build`, `synergy`, `sets`, `catalog`, `settings` are **PASS** on **web** (Jaspr) and **Windows**; `loadouts` is **PASS** **or** product explicitly demotes/removes it from AppShell | This matrix; AppShell diff; DART-055 host tests | **PASS** (loadouts PASS Windows+web — RB-01 cleared; re-verify labels on cutover build) |
| **RC-DOMAIN** | Hard/soft domain parity non-regression | Pure domain suite + hard-block codes stable; soft never implies hard block; soft never auto-applies | `dart run tool/p0_parity_gate.dart`; DBR/DAC | **PASS** (suite maintained; re-run before cutover day) |
| **RC-COMPOSE** | Intent→compose path on production web host | User can create build, attach sets, pin slots, see soft guidance on Jaspr without Next | DART-046 manual/scripted path | **PASS** (feature complete; re-verify on cutover build) |
| **RC-EQUIP** | Equip-ready + equip and/or DIM on production web | Equip-ready gate enforced; DIM jsonOnly blocked when not ready; optional equip partial OK | DART-047 tests + smoke | **PASS** (feature complete; re-verify live Bungie in dual-run) |
| **RC-AUTH** | Public+PKCE production auth | Prod Public Bungie app; HTTPS origin redirects registered; **no** `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` in Flutter/Jaspr artifacts | [prod Public OAuth matrix](./multiplatform-dart-prod-public-oauth-matrix.md); `ProdPublicOAuthMatrix` tests; `dart run tool/client_secret_scan.dart`; Windows/Jaspr OAuth session tests | **PASS** (RB-03 cleared DART-058; re-verify live portal + operator smoke before cutover day) |
| **RC-SYNC** | Owned inventory available for equip pins with **inventory fidelity** | (1) Documented sync path works on cutover-primary hosts (Windows + web at minimum for equip). (2) **After DART-050–054:** vault/postmaster weapon/armor present in Drift with correct equipment buckets; counts by location/bucket within agreed Next **tolerance** (default exact / 0) for same membership (or documented residual with GAP/RB note). (3) Diagnostics show resolution (resolvedFromTransfer / dropped) not only itemCount. (4) Inventory fidelity gate + dual-run procedure exist ([inventory live parity harness](./multiplatform-dart-inventory-live-parity-harness.md); `dart run tool/inventory_fidelity_gate.dart`) — separate from pure `p0_parity_gate` (PROC-05). Pass is **not** satisfied by “Settings sync card exists” alone (PROC-04). | Settings sync Windows + Jaspr (DART-056); [harness doc](./multiplatform-dart-inventory-live-parity-harness.md) + fixture gate; GAP-INV-01…06 closed; GAP-WEB-01 closed; live operator dual-run attachable under RC-OPS | **PASS** (RB-02 + RB-06 cleared; vault fixtures + web Settings/Owned depth; re-verify live dual-run under RC-OPS) |
| **RC-DATA** | Local data migration path | Legacy Next `.cache/app.db` → StorageRoot dry-run + apply documented and tested | [multiplatform-dart-legacy-db-import.md](./multiplatform-dart-legacy-db-import.md); DART-048 tests | **PASS** |
| **RC-WEB-DATA** | Web entity/DB limits accepted | OPFS single-writer UX documented; prebuilt bundles load offline; prod distribution chosen | [multiplatform-dart-web-opfs-limits.md](./multiplatform-dart-web-opfs-limits.md); [entity-bundle-channel.md](./multiplatform-dart-entity-bundle-channel.md); hybrid channel + loader tests; RB-05 cleared | **PASS** (DART-059; re-verify full extract packaging before cutover day) |
| **RC-SECRETS** | No confidential secrets in clients | Scan clients/packages for `CLIENT_SECRET` / `SESSION_SECRET` embedding — none | Package/app source + build defines | **PASS** (architecture + code review baseline) |
| **RC-SOFT** | Soft never auto-applies | Optimizer/guidance/improvement paths remain confirm-only | Domain + UI tests across hosts | **PASS** |
| **RC-OPS** | Dual-run and rollback | Written ops steps executed once: Dart web + Next available; rollback = keep Next live | [dual-run + rollback runbook](./multiplatform-dart-dual-run-rollback-runbook.md) (EXECUTION_NOTES EXECUTED_ONCE 2026-07-25); `dart run tool/dual_run_ops_gate.dart` | **PASS** (RB-04 cleared DART-060; re-smoke operator live Bungie equip on cutover day) |
| **RC-BRANCH** | Integration merge policy | Explicit decision to merge `feature/multiplatform-dart` → production branch/`main` only after PRODUCTION_CUTOVER GO | [multiplatform-dart-branching.md](./multiplatform-dart-branching.md) **RC-BRANCH / production merge** section; this verdict **PRODUCTION_CUTOVER_GO**; offline `dart run tool/production_cutover_regate.dart` | **PASS** (DART-061: GO recorded; merge toward production/`main` allowed only after this GO; finish-spec still lands on `feature/multiplatform-dart` only) |

### RC evaluation rules

1. Any **FAIL** ⇒ `PRODUCTION_CUTOVER` must remain **NO-GO**.
2. Re-run **RC-DOMAIN** and smoke **RC-COMPOSE** / **RC-EQUIP** on the cutover candidate build (not only historical slice merges).
3. Product may change AppShell; if a new primary nav key appears, add a row before GO.
4. Mobile reduced nav does **not** fail **RC-NAV** for Next web retirement (Windows + Jaspr are the production-nav targets).
5. **RC-SYNC** after DART-050–056 must cite vault/postmaster fidelity evidence (counts by location/bucket vs Next, or documented residual) — not only presence of a Settings sync card (PROC-04). **RB-06** cleared by DART-050–054; **RB-02** / web owned depth cleared by DART-056. Inventory fidelity gate (`tool/inventory_fidelity_gate.dart`) is separate from pure `p0_parity_gate` (PROC-05).
6. Soft never auto-applies; no `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` in Flutter/Jaspr clients (**RC-SOFT**, **RC-SECRETS**).

---

## Explicit non-goals (do not block cutover)

- `/debug/*` as primary Dart nav  
- Multi-pass LLM generator as primary spine  
- Full DIM product parity / dim.gg  
- Flutter Web product target  
- Node sidecar / dual runtime  
- Confidential cookie parity on Jaspr  
- Cloud multi-tenant / multi-worker Edge SQLite  
- Shareable public build links (product open)  
- Formal WCAG level (product open) — track separately; not a DART program gate  

---

## How to use this checklist

1. **Before claiming program complete:** ensure `PROGRAM_GATE: GO` and validator green (`dart test tool/test/cutover_parity_checklist_validate_test.dart`).
2. **Before retiring Next:** walk every `RC-*`; clear residual blockers; set `PRODUCTION_CUTOVER: GO`; update **Updated** date. (**Done 2026-07-25 — DART-061 / PRODUCTION_CUTOVER_GO.**)
3. **After GO:** follow branching doc **RC-BRANCH** — merge multiplatform line toward production/`main` is now **allowed**; schedule Next domain route retirement. Run `dart run tool/production_cutover_regate.dart` before release merge.
4. **Domain conflicts:** DBR / DAC / BR win over this checklist.

---

## Related artifacts

| Artifact | Role |
| -------- | ---- |
| [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) | Architecture freezes |
| [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md) | Slice table + phase gates |
| [multiplatform-dart-branching.md](./multiplatform-dart-branching.md) | Worktree / merge rules |
| [multiplatform-dart-legacy-db-import.md](./multiplatform-dart-legacy-db-import.md) | RC-DATA path |
| [multiplatform-dart-web-opfs-limits.md](./multiplatform-dart-web-opfs-limits.md) | RC-WEB-DATA OPFS limits |
| [multiplatform-dart-entity-bundle-channel.md](./multiplatform-dart-entity-bundle-channel.md) | RC-WEB-DATA prod hybrid channel |
| [multiplatform-dart-dual-run-rollback-runbook.md](./multiplatform-dart-dual-run-rollback-runbook.md) | RC-OPS dual-run + rollback + EXECUTION_NOTES |
| `specs/dart-049-cutover-parity-checklist/` | Spec Kit slice (program gate) |
| `specs/dart-061-production-cutover-regate/` | Spec Kit slice (PRODUCTION_CUTOVER GO re-gate) |
| `tool/cutover_parity_checklist_validate.dart` | Structural validator |
| `tool/dual_run_ops_gate.dart` | RC-OPS offline ops gate (DART-060) |
| `tool/production_cutover_regate.dart` | PRODUCTION_CUTOVER GO + RC-* PASS re-gate (DART-061) |

---

## Document markers (machine-checked)

The following markers MUST remain present for automated validation:

- `PROGRAM_GATE:`
- `PRODUCTION_CUTOVER:`
- `## Product production nav parity`
- `## Capability parity`
- `## Next retirement criteria`
- `## Residual blockers` **or** residual blockers table under Verdict
- `RC-NAV`
- `RC-DOMAIN`
- `RC-COMPOSE`
- `RC-EQUIP`
- `RC-AUTH`
- `RC-SYNC`
- `RC-DATA`
- `RC-WEB-DATA`
- `RC-SECRETS`
- `RC-SOFT`
- `RC-OPS`
- `RC-BRANCH`
- AppShell nav keys: `loadouts`, `build`, `synergy`, `sets`, `catalog`, `settings`
