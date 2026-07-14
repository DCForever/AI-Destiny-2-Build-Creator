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
5. **Enumerate** kits with early reject on set-bonus coverage goals and exotic exclusivity.
6. **Score/rank** by ordered priorities and optional soft thresholds (seed from build `softStatTargets` when linked).
7. **Return** top-N combinations (default N=25–50) with estimates + set-bonus summary + unmet-constraint explanation when empty.

**Rationale**: Matches DIM’s “constrain then explode” practice without billions of unchecked combos; SC-007 interactive target for fixture inventories.

**Alternatives considered**: Exhaustive 5-slot product without prune (too slow); client-only search (duplicates inventory auth and bypasses Zod/service patterns).

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
2. For selected categories (`armor` | `weapon` | `mod`, default all non-empty): create Set with auto-unique name (`{buildName} Armor`, suffix ` (2)` on collision).
3. Upsert items with `itemHash`, `instanceId` when present, roll fields as available.
4. If `attachNow: true` (default): `prepareAttachments` / variant update with `mode: "live"` for each new set.
5. Return created set ids + attachment results; on uniqueness/exotic/energy failure, return structured errors without partial attach when `attachNow` (prefer all-or-nothing for attach phase after sets created, or transactional best-effort documented in contract).

**Rationale**: Reuses `setService` / `setItemService` / `attachmentService`; no new tables.

**Alternatives considered**: Client-only loop of existing APIs (racey, poor UX); overwrite existing attached sets in place (dangerous — create new sets instead).

---

## R6 — Materialize combination

**Decision**: `POST …/materialize` accepts a combination payload (or server-issued combination id from last search if we cache short-lived — **v1: client echoes the combination pieces/mods**). Creates Armor Set (+ optional Mod Set), optional `attachNow` + `buildId`/`variantId`.

**Rationale**: Stateless debug/API-first; avoids Redis/session cache complexity.

**Alternatives considered**: Server-side result cache keyed by search id (nicer UX later).

---

## R7 — API surface & verification

**Decision**:
| Endpoint | Purpose |
|----------|---------|
| `POST /api/user/builds/[id]/create-sets` | US1 create-from-build (+ attach) |
| `POST /api/user/armor/optimize` | US2–US4 search |
| `POST /api/user/armor/optimize/materialize` | US5 materialize (+ attach) |
| Debug panels on Builds + Sets pages | FR-014 |

Seed request from build: optional `buildId` loads class, exotic armor identity, `softStatTargets`.

**Rationale**: Thin route → Zod → service pattern; mirrors 019/021 debug/API-first.

---

## R8 — Persistence

**Decision**: **No new SQLite tables** for optimizer requests/results in v1. Persist only materialized Sets (existing schema).

**Rationale**: Spec entities are ephemeral search + durable Sets; keeps migration surface zero.

---

## R9 — Performance budgets

**Decision**: Hard caps — per-slot prune K (e.g. 12–20), max combinations evaluated (e.g. 250k), max results returned (e.g. 50), wall-clock soft budget (~3–5s) then return best-so-far with `truncated: true`. Document fixture sizes in quickstart.

**Rationale**: SC-007; DIM wiki warns unconstrained vaults explode — we require constraints and prune by default.

---

## R10 — Domain doc updates (implement-time)

**Decision**: When shipping behavior, add BRs as needed (e.g. create-from-build attach-now, optimizer hard vs soft constraints) to `business-rules.md` / DBR if new product rules emerge. Soft-stat seeding is already DBR-STAT-*; exotic exclusivity already DBR-CMP-007.

**Rationale**: AGENTS.md domain co-update rule.
