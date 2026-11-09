# Ranked refactor backlog

**Created:** 2026-08-11  
**Source:** deep-research (simplicity · duplicate UI · performance · god classes) + [flutter-modularization-audit.md](./flutter-modularization-audit.md) + [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md) GAP-PERF  
**Status:** living backlog — mark rows Done / Defer with date; do not re-open completed M1/M2/M4 homes unless evidence of regression.

### Ranking method

| Factor | Weight | Meaning |
| --- | ---: | --- |
| **Pain** | high | Blocks velocity, causes bugs, or user-visible jank |
| **Leverage** | high | Unlocks many later slices / reduces copy |
| **Risk** | lower is better | Blast radius if wrong |
| **Fit** | — | Prefer pure/`app` extraction over cross-framework UI merge |

**Do not:** force one shared React/Flutter/Jaspr widget layer for chrome (forbidden by multiplatform rules). Share **pure** policy, DTOs, and orchestration in `packages/*`.

**Lane split (D-LANES):** UI chrome → `docs/ux-redesign/`. System/domain/IO → Spec Kit / this backlog system tracks.

---

## Ranked table (do first → later)

| Rank | ID | Title | Theme | Effort | Pain | Leverage | Depends on | Default home |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **R-GOD-SETS** | Split Windows `SetsLibraryPage` god-page | God object | L | High | High | — | Host parts + thin controller |
| 2 | **R-GOD-CAT-WIN** | Split Windows `CatalogPage` god-page | God object | L | High | High | — | Host parts + controller |
| 3 | **R-PERF-03** | Offline catalog load off UI isolate + long-lived cache | Perf | M–L | High | High | — | `packages/manifest` (GAP-PERF-03) |
| 4 | **R-OWNED-BRIDGE** | Unify `OwnedCatalogBridge` core in `app`/`manifest` | Duplicate / simplicity | M | Med | High | R-PERF-03 helps | Hosts adapt only |
| 5 | **R-GOD-BUILDS-CTL** | Thin `BuildsLibraryController` to session façade only | God object | M | Med | Med | M4 done | Windows host |
| 6 | **R-PERF-04** | Inventory hash-only list + less full-replace | Perf | M–L | Med | High | — | `packages/db` (GAP-PERF-04) |
| 7 | **R-PERF-01/02** | Catalog filter index + selection isolation | Perf | M | Med | Med | partial already | GAP-PERF-01/02 |
| 8 | **R-GOD-CAT-NEXT** | Split Next `CatalogScreen` | God object | L | Med | Med | — | Next components |
| 9 | **R-GOD-CAT-JASPR** | Split Jaspr `CatalogPage` | God object | M | Med | Med | R-OWNED-BRIDGE | web_host |
| 10 | **R-GOD-BUILD-NEXT** | Thin Next `BuildPage` I/O | God object | M | Med | Med | — | Next hooks/services |
| 11 | **R-PERF-06** | Virtualize catalog weapon detail | Perf | S–M | Low–Med | Med | — | `ui_flutter` (GAP-PERF-06) |
| 12 | **R-PASS-THRU** | Remove pure Next passthrough shells (optional) | Simplicity | S | Low | Low | — | Next only |
| 13 | **R-SYNC-UI** | Accept triple InventorySyncCard; share **policy** only | Duplicate UI | S–M | Low | Low | R-PERF-04 | `app` policy helpers |
| 14 | **R-LLM-LAYERS** | Document / optionally collapse Next multi-pass LLM | Simplicity | S–M | Low | Low | product decision | Next `lib/llm` |
| 15 | **R-OPT-BOUNDS** | Optimizer prune/cap observability (not raise caps blindly) | Perf | S | Low | Med | live vaults | domain + host status |

**Shipped / out of scope for re-do (audit Implemented homes):** M1 formatters, M2 equip/DIM cores, S1 builds page part-split skeleton, M4 `BuildsComposeSession`, U1 ItemRichness. Host re-exports are intentional post-M1 design.

---

## Rank 1 — R-GOD-SETS · Split `SetsLibraryPage`

**Why first:** Active Sets armor MVP surface; ~2k-line host page mixes dual-pane UI, create wizard, board modal, optimize confirm, enrichment, set-bonus catalog, inventory candidates. Highest ongoing merge conflict + bug density while feature work continues.

### Extract targets (suggested files)

| Slice | Responsibility | Suggested path |
| --- | --- | --- |
| A | Library list + filters + selection | keep thin in `sets_library_page.dart` or `sets_library_rail.dart` |
| B | Armor detail preview board | `sets_detail_panel.dart` |
| C | Board modal + pick/fill | `sets_board_host.dart` |
| D | Optimize open/run/apply | `sets_optimize_host.dart` |
| E | Set-bonus catalog load + itemHash map | already partial in `set_bonus_families.dart` — host only calls |
| F | Candidate board build | stay in `optimizer_candidate_map.dart` |

### Acceptance

- [ ] No single Sets file > ~600 lines without `part` or sibling host module  
- [ ] Optimize + board still confirm-only; set-bonus goals stamp candidates  
- [ ] Existing widget/host smoke tests green  
- [ ] Behavior parity: create → board → optimize → apply  

### Anti-goals

- Do not move Flutter widgets into `domain`  
- Do not Spec-Kit pure chrome density work  

---

## Rank 2 — R-GOD-CAT-WIN · Split Windows `CatalogPage`

**Why:** ~2.7k lines; every catalog feature lands here (filters, roll targets, entity info, owned, grouping).

### Extract targets

| Slice | Out of page |
| --- | --- |
| Filter/browse state | `CatalogBrowseController` or extend existing bridge |
| Detail pane | already partial widgets — host should only bind  
| Owned annotate + refresh | OwnedCatalogBridge (then R-OWNED-BRIDGE) |
| Roll targets / filter collections | feature controllers already used by UX slices |

### Acceptance

- [ ] Page is composition + keys only  
- [ ] GAP-PERF-01/02 host partial behavior preserved  
- [ ] Capture dual-truth keys stable  

---

## Rank 3 — R-PERF-03 · Offline catalog load / project

**Ledger:** GAP-PERF-03 (open).

### Work

1. Long-lived `OfflineCatalog` / entity store cache per process (skip re-read if version unchanged).  
2. `Isolate.run` (or worker) for `jsonDecode` + project of MVP stores.  
3. Optional pre-warm on app start after manifest ready.  
4. Perf harness (planned in catalog-performance-tests.md).

### Acceptance

- [ ] Second `loadBase` same version is cheap (no full re-project)  
- [ ] UI thread not blocked on multi-MB store parse in debug profiles  
- [ ] Catalog browse still correct after warm  

---

## Rank 4 — R-OWNED-BRIDGE · Shared owned-catalog core

**Why:** Windows + Jaspr duplicate `OwnedCatalogBridge` (~80%+ overlap). Annotate path is hot for Catalog + Sets fill.

### Work

- Extract DB + OfflineCatalog + plug-name resolve core into `packages/app` (or manifest orchestration).  
- Hosts: ChangeNotifier + session adapter only.

### Acceptance

- [ ] Single pure/core implementation for annotate/browse  
- [ ] Both hosts call core; no logic drift in tag/owned counts  

---

## Rank 5 — R-GOD-BUILDS-CTL · Thin Builds host controller

**Why:** Session already exists; controller still re-exposes + mixes finish/identity/DB.

### Work

- Public API = thin forwards to `BuildsComposeSession`  
- Host-only: OAuth identity hard-block UI, Windows finish walkthrough glue  
- Drop duplicate state mirrors where session is source of truth  

### Acceptance

- [ ] Controller LOC down materially without moving domain into widgets  
- [ ] Builds tests / smoke still pass  

---

## Rank 6 — R-PERF-04 · Inventory lightweight paths

**Ledger:** GAP-PERF-04.

### Work

1. Hash/instanceId-only list for catalog owned annotate.  
2. Optional incremental upsert (defer full-replace merge until web depth reconciled — modularization audit).  
3. Avoid “load entire inventory to find one instance” in API handlers (Next perk-grid).

### Acceptance

- [ ] Annotate path does not require full plug/stat decode for every row  
- [ ] Sync correctness tests still pass  

---

## Rank 7 — R-PERF-01/02 · Catalog filter & tree

**Status:** partial (debounce + tree memo + scroll-spy throttle).

### Remaining

- Optional pure search index / progressive filter  
- Selection-only `setState` isolation on host  
- Keep harness thresholds documented  

---

## Rank 8–10 — Other god surfaces

| ID | Notes |
| --- | --- |
| R-GOD-CAT-NEXT | Split `CatalogScreen` into filter state hook + grid + detail + data hooks; keep Catalog route thin |
| R-GOD-CAT-JASPR | Mirror Windows catalog split after shared bridge |
| R-GOD-BUILD-NEXT | Extract equip/DIM/loadout API hooks from `BuildPage`; page stays layout |

---

## Rank 11–15 — Smaller / later

| ID | Notes |
| --- | --- |
| R-PERF-06 | `ListView.builder` / virtualize weapon detail body; RepaintBoundary on cards |
| R-PASS-THRU | Optional: delete pure re-export files only if they confuse imports — low value |
| R-SYNC-UI | **Do not** merge three InventorySyncCard UIs; share sync **status format / policy** only |
| R-LLM-LAYERS | Product decision: is multi-pass primary? Document; collapse only if unused |
| R-OPT-BOUNDS | Surface evaluatedCount/truncated honestly; measure real vaults before raising 250k / K=16 |

---

## Suggested sequencing (quarters-ish)

```text
Now (while Sets armor lands)
  R-GOD-SETS (opportunistic extract on each Sets PR)
  → R-PERF-03 when Sets stabilize

Next
  R-GOD-CAT-WIN
  R-OWNED-BRIDGE
  R-GOD-BUILDS-CTL

Then
  R-PERF-04
  R-PERF-01/02 remaining
  Next/Jaspr god splits as those surfaces are touched

Ongoing
  No new logic in god pages — extract first if >50 LOC of new host behavior
```

### Rule of thumb for PRs

> If a change adds behavior to `SetsLibraryPage` / `CatalogPage` / `CatalogScreen` and the file is already a god object, **extract the slice in the same PR** (or a stacked PR immediately before). Do not grow rank-1/2 files.

---

## Tracking

| Place | Use |
| --- | --- |
| This file | Ranked order + acceptance |
| [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md) | GAP-PERF status machine |
| [flutter-modularization-audit.md](./flutter-modularization-audit.md) | What already shipped |
| ProjectTracker (optional) | One epic per R-* ID when scheduling |

**Last research pass:** 2026-08-11 deep-research (partial coverage; no DevTools frame budgets).

---

## Explicit non-goals

1. Unifying Flutter + React presentation components.  
2. Raising optimizer maxResults / combination caps without vault metrics.  
3. Replacing Spec Kit domain lanes with UX mockup work (or vice versa).  
4. Re-litigating M1 host re-export shims as “delete tech debt.”  
