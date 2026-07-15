# Research: Armor Set Optimizer

**Feature**: 026-armor-set-optimizer  
**Date**: 2026-07-14

## R1 — DIM Loadout Optimizer: reuse vs inspire

**Decision**: Implement a **clean-room, DIM-inspired** constrained armor searcher inside this repo. Do **not** vendor, copy, or npm-depend on DIM’s Loadout Optimizer implementation. Continue using `@destinyitemmanager/dim-api-types` only for **export/share** (021), not for search.

**Rationale**:
- DIM LO is a large, inventory-model-coupled pipeline (filter → permute → mod assign → worker parallelization) aimed at interactive client-side search over an entire vault.
- DIM is open source but its application license is not a drop-in for embedding LO into this product without legal/review overhead; algorithmic *patterns* (constraints, pruning, auto stat mods) are enough for FR quality (“DIM-like”).
- Our domain already stores Sets / Build attachments / soft targets — LO should **materialize into Sets**, not produce DIM-only loadouts.
- Existing DIM export remains complementary: optimize → Armor+Mod Sets → attach → equip/export later.

**Alternatives considered**:
| Option | Why rejected (v1) |
|--------|-------------------|
| Port DIM LO TypeScript modules | Tight coupling to DIM item model + workers; license/review risk; oversized for debug/API-first slice |
| Call DIM Sync / external LO API | No public “run optimizer” API; would require user’s DIM session and different product boundary |
| Pure ILP/solver dependency (e.g. OR-Tools) | Extra native/runtime cost; overkill before proving prune+enumerate on owned inventory |
| Keep per-piece picker only (008) | Does not satisfy multi-constraint full-kit stories |

**Planning follow-up**: During implement, skim DIM wiki + public issues on set-bonus constraints for *behavior* parity ideas (2pc+2pc, exotic lock, auto stat mods) — not source paste.

---

## R2 — Search algorithm shape

**Decision**: Server-side (Node) pipeline in `src/lib/optimizer/`:

1. **Load** owned armor instances for class (reuse inventory list/project + `statValues`, `setBonus`, `gearTier`).
2. **Hard-filter** candidates: class/slot fitness; optional locked exotic `itemHash` (and pick best owned copy when multiple); exclude kits that would place a second exotic.
3. **Tag** each piece with set-bonus family id/name (reuse `armorSetBonus` / `buildSetBonusByItemHash`).
4. **Prune** per slot: keep top-K / Pareto front by prioritized stats (and pieces needed for set-bonus goals) so enumeration stays bounded.
5. **Enumerate** kits with early reject on set-bonus coverage goals and exotic exclusivity; **require all five slots**.
6. **Annotate** pieces with other Armor Set membership (active items only); compute `reusePieceCount`.
7. **Score/rank** by ordered lexicographic priorities, then sum of prioritized stats; if `preferReuse`, higher reuse count breaks remaining ties only.
8. **Return** top-N combinations (default N=25–50) with estimates + set-bonus summary + reuse annotations + unmet-constraint explanation when empty.

**Rationale**: Matches DIM’s “constrain then explode” practice without billions of unchecked combos; SC-007 interactive target for fixture inventories.

**Alternatives considered**: Exhaustive 5-slot product without prune (too slow); client-only search (duplicates inventory auth and bypasses Zod/service patterns); return gapped kits (rejected — FR-004 complete kits only).

---

## R3 — Set-bonus coverage goals

**Decision**: Request model uses explicit goals: `{ setBonusId | setBonusName, minPieces: 2 | 4 }[]`. Satisfaction counts distinct armor pieces in the kit whose set-bonus family matches; a piece counts toward at most one goal family (its own). Dual 2pc (A+B) is two goals with `minPieces: 2`.

**Rationale**: Spec example + DBR-SETB-*; 008 catalog filter is hash allowlist only — kit-level counting is new but reuses family identity.

**Alternatives considered**: Free-text “2 TechSec + 2 Bushido” NLP (out of scope); require exact 4pc only (too narrow).

---

## R4 — Mod-aware estimates

**Decision**:
- For **optimizer scoring** (US4): after a base armor kit is formed, run a **greedy auto-stat-mod assigner** over a curated pool of general/stat armor mods, respecting per-piece energy (`armorEnergyCapacity` / `modSetEnergy`) and slot legality (`isModLegalForArmorSlot`). Expose assumed mods on each combination.
- Toggle `includeModEstimates: boolean` (default true for optimize-from-build when soft targets exist).
- Extend or parallel `estimateLoadoutStats` with an optimizer-specific estimator that adds assumed mod bonuses; mark `incomplete` when pool/data gaps remain.
- Global coverage estimate improvement (mods/fragments always) may share helpers but is **not** required to finish 019 gaps in this slice beyond what optimizer needs.

**Rationale**: DBR-STAT-005 + FR-009; DIM “Auto Stat Mods” behavior without copying DIM assignment code.

**Alternatives considered**: Full mod permutation (expensive); ignore mods until later (fails US4 / SC-004).

---

## R5 — Create Sets from Build + attach

**Decision**: New service `createSetsFromBuild` (under builds or sets):
1. Resolve default (or specified) variant → `SlotClaim[]` / mod claims via existing resolve helpers.
2. For selected categories (`armor` | `weapon` | `mod`, default all non-empty): create Set with auto-unique name (`{buildName} Armor`, suffix ` (2)` on collision — never fail solely for name collision).
3. Upsert items with `itemHash`, `instanceId` when present, roll fields as available.
4. For **Armor** Sets: **seed** `optimizer_constraints` with Build exotic armor identity (when set) + soft-stat priorities/thresholds from `softStatTargets` when present; **`setBonusGoals: []`**; `preferReuse: false`.
5. If `attachNow: true` (default): **replace-by-type** — detach existing live attachment(s) of the same set type on the variant, then attach each new set as `mode: "live"`. Detached Sets remain in the library.
6. Return created set ids (including seeded constraints on armor) + attachment results; on exotic/energy failure, return structured errors without partial attach when `attachNow`.

**Rationale**: Reuses `setService` / `setItemService` / `attachmentService`; FR-001a / FR-002a clarifications; no new tables (JSON column on `sets`).

**Alternatives considered**: Client-only loop of existing APIs (racey); overwrite existing attached sets’ items in place on create-from-build (rejected — create new Sets, replace attachment only); fail on name collision (rejected — auto-suffix).

**Supersedes earlier note**: “Do not overwrite existing attached sets in place” still applies to **create-from-build** (new Sets); attachment **replace-by-type** is intentional and distinct from item overwrite.

---

## R6 — Materialize + refresh constrained Sets

**Decision**:
- **First-time materialize** (`POST …/armor/optimize/materialize`): client echoes combination pieces/mods + the search **constraints**. Creates a **new** Armor Set, persists `optimizer_constraints`, optionally creates Mod Set + `linked_mod_set_id`, optional `attachNow` with replace-by-type. Auto-unique naming on collision.
- **Refresh / apply** (`POST …/sets/[id]/optimize` then `POST …/sets/[id]/apply-combination`): load stored constraints (optional per-search override for `preferReuse` etc. without saving unless user saves constraints); search current inventory; on confirm, **update that Set’s items in place** (same Set id/name); constraints unchanged unless explicitly edited; linked Mod Set may update in place.

**Rationale**: Stateless debug/API-first search; FR-010 / FR-010a — living constrained kits without duplicate Sets that break Build attachments.

**Alternatives considered**: Always create a new Set on every apply (superseded — breaks attachment stability / SC-005a); server-side result cache keyed by search id (nicer UX later); silent auto-apply after sync (rejected — suggest-then-confirm).

**Supersedes earlier R6 “create-only / never overwrite Set items”**: first materialize still creates; **refresh deliberately overwrites items on the same constrained Set**.

---

## R7 — API surface & verification

**Decision**:
| Endpoint | Purpose |
|----------|---------|
| `POST /api/user/builds/[id]/create-sets` | US1 create-from-build (+ seed constraints + replace-by-type attach) |
| `POST /api/user/armor/optimize` | US2–US4 / US7 search |
| `POST /api/user/armor/optimize/materialize` | US5 first-time materialize (+ persist constraints + attach) |
| `POST /api/user/sets/[id]/optimize` | US5b refresh search from stored constraints |
| `POST /api/user/sets/[id]/apply-combination` | US5b in-place apply |
| `GET /api/user/armor/improvement-suggestions` | US5b soft suggestions (attached constrained Sets) |
| Debug panels on Builds + Sets pages | FR-014; on-open check for unattached constrained Sets |

Seed request from build: optional `buildId` loads class, exotic armor identity, `softStatTargets`. Refresh seeds from Set’s `optimizer_constraints`.

**Rationale**: Thin route → Zod → service pattern; mirrors 019/021 debug/API-first; T051 route shape.

---

## R8 — Persistence

**Decision**: **No new SQLite tables** in v1. Persist optimizer intent as **nullable JSON columns on existing `sets`** (`optimizer_constraints`, optional `linked_mod_set_id`). Search results and improvement suggestions remain computed/ephemeral.

**Rationale**: Spec entities are ephemeral search + durable Sets with stored constraints; migration surface is column adds only — still “no new tables.”

**Supersedes earlier R8 “persist only materialized Sets / zero schema change”**: durable constraints require columns on `sets`, not a separate optimizer table.

---

## R9 — Performance budgets

**Decision**: Hard caps — per-slot prune K (e.g. 12–20), max combinations evaluated (e.g. 250k), max results returned (e.g. 50), wall-clock soft budget (~3–5s) then return best-so-far with `truncated: true`. Document fixture sizes in quickstart.

**Rationale**: SC-007; DIM wiki warns unconstrained vaults explode — we require constraints and prune by default.

---

## R10 — Domain doc updates (implement-time)

**Decision**: When shipping behavior, add/finalize BRs (create-from-build replace-by-type, Armor Set `optimizerConstraints`, prefer-reuse soft tie-break, soft suggestions suggest-then-confirm) in `business-rules.md` / DBR if needed. Soft-stat seeding is already DBR-STAT-*; exotic exclusivity already DBR-CMP-007. Stubs land with design sync (T007); finalize at polish (T059).

**Rationale**: AGENTS.md domain co-update rule.

---

## R11 — Prefer-reuse / cross-Set annotation

**Decision**:
- On every optimize/refresh result, annotate each piece with **other** Armor Sets (all user-owned Armor Sets except the Set being optimized/refreshed) that already include that `instanceId` as an **active** item. Soft-removed items do not count.
- Combination exposes `reusePieceCount` (0–5).
- Optional `preferReuse` (default **false**, stored on `ArmorSetOptimizerConstraints`): after lexicographic stats and prioritized-stat sum ties, rank higher reuse count first. Stats always win over reuse.
- Per-search override MAY differ from stored value without saving unless the user saves constraints.

**Rationale**: FR-005 / FR-005a / US7; vault hygiene secondary to hard constraints and stat ranking.

**Alternatives considered**: Prefer-reuse as a hard filter (rejected — would hide better stats); count soft-removed items (rejected); scope “other Sets” to attached-only (rejected — all other Armor Sets).
