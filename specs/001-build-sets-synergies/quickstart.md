# Quickstart: Build Sets and Synergies

**Updated**: 2026-06-28 (concept tags integrated)

**Purpose**: Runnable validation scenarios proving spec user stories and Session 2026-06-22/2026-06-28 clarifications.

## Prerequisites

```bash
npm run dev
# http://localhost:3000
# Settings → Refresh manifest (BUNGIE_API_KEY)
# Configure LLM endpoint
# Sign in + sync inventory (for "my" items)
```

## Scenario 1: P1 — Typed Sets with Slot Rules and Concept Tags

1. Create **Weapon Set** named `Solar PVE` with tags `[Solar, PVE]` — add one primary, one special (leave heavy empty).
2. Attempt second primary → confirmation → replace on confirm (FR-027).
3. Create **Armor Set** named `Ferropotent` with tags `[Solar, Melee]` — one helmet, one chest.
4. Attempt to save a set with invalid tag → rejected (`INVALID_TAG`, FR-029).
5. Create **Pair Set** with exotic armor + exotic weapon entries.
6. Create **Fashion Set** — verify excluded from build composition UI.
7. Delete weapon from set → previous roll still visible; alternatives offered (FR-019).
8. Duplicate name within same set type → error (FR-005).
9. Filter Sets list by `Solar` + `Melee` → only Ferropotent armor set shown (FR-031).

**Pass**: SC-001 (<60s for 3+ items across slots).

## Scenario 2: P2 — Catalog Filtering

1. Browse all weapons — filter by type/archetype.
2. Toggle **My Weapons** after inventory sync.
3. Repeat for armor.

**Pass**: SC-002 (<5s search).

## Scenario 3: P3 — Build + Default Variant Attach

1. Create **Build** with exotic armor (e.g. Crown of Tempests), subclass, **≥1 synergy**.
2. Default variant: attach Armor Set (snapshot) + Weapon Set (live).
3. Save — fails if zero equipment slots filled (FR-025).
4. Attach **Pair Set** with matching exotic armor → supplies exotic weapon; mismatch → rejected (FR-028).
5. Attach Weapon Set primary + Pair exotic weapon conflicting → save blocked (FR-026).
6. Edit live set → variant reflects change; snapshot unchanged.
7. In attach flow, filter by `Solar` + `Melee` → only matching sets shown; empty state if none (FR-032).
8. Auto + explicit set suggestions appear (FR-010).

**Pass**: SC-003.

## Scenario 4: P4 — Synergies

1. Create Melee + Grenade synergies.
2. Designate **both** on a build.
3. Request suggestions → both influence results equally (FR-024).

## Scenario 5: P5 — Roll Suggestions

1. With synergies + sets attached, request roll suggestions.
2. Verify ≥2 manifest-valid perk combos (SC-006); owned vs unowned distinguished.

## Scenario 6: P6 — Variants

1. From build with Crown of Tempests, duplicate variant.
2. Variant A: Osteo Striga + survivability sets.
3. Variant B: Vex Mythoclast + DPS sets.
4. Compare variants — shared armor/subclass/synergies; diff weapons/sets highlighted.
5. Filter builds by exotic armor → both variants listed (FR-015, SC-004).

## Edge Cases

| Case | Expected |
|------|----------|
| Delete attached set | Blocked; list builds/variants (FR-017) |
| Save build without synergy | Blocked (FR-024) |
| 30 sets / 20 synergies | No noticeable lag (SC-007) |
| Fashion set on variant | Display only; ignored in resolution |

## Gate

```bash
npm run gate
```

## References

- [spec.md](./spec.md) — acceptance scenarios
- [data-model.md](./data-model.md) — entities
- [contracts/set-attachment-contract.md](./contracts/set-attachment-contract.md)
- [contracts/build-variant-contract.md](./contracts/build-variant-contract.md)
- [research.md](./research.md) — design decisions
