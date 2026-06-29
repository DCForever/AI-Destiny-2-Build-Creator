# Research: Exotic Loadouts by Type

**Updated**: 2026-06-29

## Spec ↔ Implementation Traceability

| Spec topic | Spec (outcome) | Implementation |
|------------|----------------|----------------|
| FR-001/002 armor filters | Exact name + armor slot type | `ExoticFilterCriteria.armor` with `mode: exact \| slot` |
| FR-003 weapon filters | Exact weapon + weapon slot | `ExoticFilterCriteria.weapon` with `mode: exact \| slot` |
| FR-004 contextual discovery | Exact or broaden to slot | Sheet actions set same criteria as list filter |
| FR-005 result labels | Show actual exotic used | `LoadoutExoticSummary` on list rows |
| FR-008 stable classification | Manifest-backed slots | `exotic-armor` / `exotic-weapons` stores + `ResolvedBuildSheet` |
| FR-009 user scope | Own loadouts only | Existing `userId` on `loadouts` table |
| SC-001 performance | &lt;5s filter | In-memory over full user list (≤50 typical) |

## Loadouts vs Builds

**Decision**: Feature targets **`SavedLoadout`** (`loadouts` table, `/loadouts` page) — JSON `resolvedSheet`, not the **`builds` / `build_variants`** domain from spec 001.

**Rationale**: Spec assumptions and user stories reference saved loadouts from Generator/Analyzer. Builds API already has `exoticArmorHash` filter but serves a different workflow.

**Alternatives considered**:
- Implement on builds only: rejected — spec scope is loadouts.
- Unified exotic index table: rejected — no schema change needed; sheet JSON is sufficient.

## Exotic Classification Source

**Decision**: Derive identity from `ResolvedBuildSheet`:

| Piece | Source fields | Exact key | Slot key |
|-------|---------------|-----------|----------|
| Exotic armor | `exoticArmor.resolved` / `requestedName` | `hash` (preferred) or normalized name | `ArmorSlotName` from manifest (`Helmet`, `Gauntlets`, `Chest`, `Legs`, `ClassItem`) |
| Exotic weapon | `weapons[]` where `isExotic === true` (0–1) | `reference.resolved.hash` or name | `ResolvedWeapon.slot` (`Kinetic` \| `Energy` \| `Power`) |

**Rationale**: Matches spec assumption that persisted loadout + manifest stores suffice. Weapon slot already on resolved sheet; armor slot requires manifest lookup when hash present.

**Alternatives considered**:
- Store denormalized exotic columns on `loadouts`: rejected for v1 — avoids migration; sheet is authoritative.
- Use `generatedBuild` only: rejected — `resolvedSheet` has resolution status and slot legality.

## Exact vs Slot Matching

**Decision**:

- **Exact**: Match when filter hash equals resolved hash, OR (if unresolved) normalized `requestedName` equals filter name (case/diacritic insensitive).
- **Slot (armor)**: Loadout included if classified armor slot equals filter slot AND exotic armor `classType` matches loadout `buildRequest.className` (default `Titan` if missing).
- **Slot (weapon)**: Loadout included if exotic weapon exists and `weapon.slot` equals filter slot.
- **Absence**: Loadout without exotic armor/weapon excluded from that dimension's filter (FR-010).

**Rationale**: Clarification C — both modes. Class scoping addresses edge case in spec (Titan helmets vs Hunter).

**Alternatives considered**:
- Slot without class check: rejected — cross-class false positives.
- OR across exact+slot when both set: rejected — FR-006 requires independent apply/clear per dimension.

## Filter Execution Layer

**Decision**: **Shared pure functions** in `src/lib/loadouts/filterLoadouts.ts` used by:

1. API `GET /api/user/loadouts` (optional query params)
2. `LoadoutsPage` client (in-memory re-filter for instant UX)

List endpoint returns enriched summaries (`exoticSummary`) so rows show armor/weapon names without opening sheet.

**Rationale**: Test-first friendly; SC-005 (no reload) via client state; server filter enables future pagination.

**Alternatives considered**:
- Client-only filter: acceptable but harder to contract-test; hybrid chosen.
- SQL JSON queries: rejected — SQLite JSON path brittle; household scale fits memory.

## Manifest Refresh / Stale Names

**Decision**: On list open, existing `reResolveIfStale` flow remains. Filtering uses **current sheet** at fetch time. If hash fails after manifest update, fall back to `requestedName` for exact mode; slot mode excludes until re-resolve updates hash.

**Rationale**: Spec edge case on manifest updates; aligns with validation-first principle.

## UI Delivery Surface

**Decision**: **Production `/loadouts` page** — filter bar (armor mode, weapon mode, clear), row subtitles with exotic labels, contextual buttons on sheet.

**Rationale**: Spec explicitly names loadouts list and opened loadout sheet. Unlike 001, this is user-facing discovery, not debug-only.

**Alternatives considered**:
- Debug-only v1: rejected — spec success criteria reference user first-attempt success on filters.
- Separate `/loadouts/exotics` route: rejected — filter is augmentation of existing list.

## Optional Debug Page

**Decision**: **Optional** `/debug/loadouts` with query-param form for API verification — not required for acceptance but useful for constitution test checkpoints.

**Rationale**: Mirrors 001 pattern without deferring production UI.

## Performance

**Decision**: Full user loadout list loaded once; filter is O(n) over ≤50 rows. No pagination v1.

**Rationale**: SC-001/007 scale; matches 001 list API pattern.
