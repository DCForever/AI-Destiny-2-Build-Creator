# Research: DART-051 Inventory Roll Tags

**Date**: 2026-07-25

## Product source of truth

| Artifact | Path |
| -------- | ---- |
| Pure rules | `src/lib/inventory/rollTags.ts` → `computeRollTags` |
| Golden tests | `src/lib/inventory/rollTags.test.ts` |
| Champion frames | `src/data/rules/championCounters.ts` → already ported `destiny2_sandbox_data` `getChampionCounterForFrame` |
| Sync call site | `src/lib/bungie/syncInventory.ts` `normalizeItems` builds perk map from entity store `weapon-perks` and weapon lookup from `weapons` + `exotic-weapons`; only legendary `WeaponRecord` (`originTraitHashes` in object) used for frame path |
| Tag type | `src/lib/db/types.ts` `RollTag` union |

## Dart today

| Area | State |
| ---- | ----- |
| `_normalizeItems` | `rollTags = [if isCrafted 'Crafted']` only |
| Champion counters | Ported and tested in `packages/sandbox_data` |
| Weapon meta | `WeaponRecord` / `CatalogItem` have `frame` + `itemTypeName` |
| weapon-perks store | **Not** in MVP `MvpStoreName` (weapons, exotic-armor, aspects, fragments, abilities, mods) |

## Decisions

### D1 — Pure port location

**Decision**: `packages/bungie/lib/src/inventory/roll_tags.dart` with dependency on `destiny2_sandbox_data`.

**Rationale**: Rules are inventory-sync enrichment, not domain hard gates. sandbox_data already owns champion frames; avoid duplicating BASE_FRAME_COUNTERS.

### D2 — Perk names without weapon-perks store

**Decision**: Injectable `Map<int,String>` + optional builder. Production Windows resolves plug display names from raw `DestinyInventoryItemDefinition` for hashes present on inventory items. Tests inject maps like vitest.

**Rationale**: Adding full weapon-perks entity extraction expands DART-017 scope. Raw def names match what weapon-perks store would carry for equipped plugs. Residual: hosts without raw tables may only get Crafted + frame tags (frame from OfflineCatalog) until DART-052/entity expansion — document if residual remains.

### D3 — Weapon meta filter

**Decision**: `RollTagWeaponMeta { frame, itemTypeName }` keyed by itemHash. Hosts populate from OfflineCatalog weapons (non-exotic / sourceStore weapons) with non-empty frame.

**Rationale**: Matches Next legendary-only frame path without exotic-weapons MVP store.

### D4 — Tag order

**Decision**: Insert order: Crafted → frame champion → perk champion → MeleeBuildCandidate → OrbitBuild (mirror TS Set insertion). Tests use `contains` / set equality for order-independence where product tests use `toContain`.

### D5 — Soft / hard

**Decision**: Roll tags are soft storage metadata only. Never auto-apply build edits. Hard DBR blocks unchanged.

## Alternatives considered

| Option | Rejected because |
| ------ | ---------------- |
| Put computeRollTags in domain | Domain has no inventory sync; would need sandbox_data there; tags are not hard gates |
| Block on weapon-perks entity store slice | Delays GAP-INV-02; raw def names sufficient for equipped plugs |
| Keep Crafted-only + document forever | Explicit P1 gap; exit criteria require golden parity |

## Open residuals (if any after implement)

- Full product entity `weapon-perks` store still missing from MVP — not required if raw-def name map is wired on Windows; web may be thinner until entity channel / DART-056 depth (note in GAP if needed).
- Socket enrichment remains DART-052.
