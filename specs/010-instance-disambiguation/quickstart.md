# Quickstart: Instance Disambiguation Picker

**Feature**: 010-instance-disambiguation | **Date**: 2026-07-03 | **Phase**: 1

Validation/run guide for the disambiguation carousel on the debug **Sets** surface. For full debug prerequisites (manifest download, Bungie OAuth sign-in, inventory sync, owned-catalog chain, production route rules) see **`DEBUG.md`** — do not duplicate that here. Contract details live in [`contracts/`](./contracts/); data shapes in [`data-model.md`](./data-model.md).

## Prerequisites

- Manifest downloaded and entity stores built (includes `weapons`, `weapon-perks`, `set-bonuses`). See `DEBUG.md`.
- Signed in via Bungie OAuth and **inventory synced** (owned scope). See `DEBUG.md`.
- Test inventory that includes **an armor piece owned in ≥3 copies** and **a weapon owned in ≥3 copies** (the spec examples: multiple First Ascent Hoods, multiple Gunburn SMGs).
- `npm run dev` running; navigate to `/debug/sets`.

## Commands

```bash
npm run test            # unit/integration (vitest)
npm run gate            # typecheck + lint + test + build (checkpoint bar)
```

## Scenario A — Armor: disambiguate by Tier, stats, and set bonus (US1, US2, US3, US5)

1. On `/debug/sets`, create or pick an **Armor** set and choose a slot (e.g. Helmet).
2. Search owned armor and **select the item owned in multiple copies** (e.g. First Ascent Hood).
   - **Expected**: the picker fetches instances (`instancesHref`) and renders **all owned copies in a carousel**, one card per copy — no cap (FR-001, FR-021).
3. Step through the carousel cards.
   - **Expected** per card: copy identity (power, location/character), all six **Armor 3.0 stats** + total, the **Tier** label (e.g. `~Tier 5`, `Exotic`, or `Tier unavailable`), and the **Set Bonus** with both **2-piece and 4-piece** effect text (or "no set bonus"). (US2 / FR-005..FR-009)
4. **Remove** two copies you don't want.
   - **Expected**: they disappear from the carousel; your inventory is unchanged (FR-015, FR-016). A **reset** control restores them (FR-017).
5. **Select** one copy and **Attach** to the slot.
   - **Expected**: the set item is saved with that copy's **`instanceId`** (FR-012). Attaching a different copy yields a different saved reference. Occupied-slot **replace confirmation** still applies (FR-019).

## Scenario B — Weapon: disambiguate by perks and choose the roll (US1, US2, US3, US4)

1. Pick a **Weapon** set + slot; select the weapon owned in multiple copies (e.g. Gunburn).
   - **Expected**: carousel of copies; each card lists **all perks on that copy** (every socket/column), unresolved plugs shown by hash (US2 / FR-003, FR-004).
2. Select one copy, then open **perk selection**.
   - **Expected**: each socket offers **all plug options that copy can hold** (equipped + swappable alternatives) from `GET /api/catalog/weapons/perk-options?itemHash=…`; the equipped option is marked (FR-013). Not the full manifest roll pool.
3. Choose a non-equipped alternative in one column and **Attach**.
   - **Expected**: the set item records the **selected perks** (`selectedPerks`) plus the `instanceId`. With no explicit change, equipped perks are recorded by default (FR-013).

## Edge cases to verify

- Item owned in exactly one copy → single-card carousel, still selectable (spec edge case).
- Never-synced / unsigned → existing sync prompt / auth error (no empty carousel) (FR-018).
- Armor copy with `statsIncomplete` → Tier shows **unavailable**; stats flagged incomplete (FR-008, FR-009).
- Armor with no set membership (exotic/standalone) → **no set bonus** indicator (FR-009).
- Weapon with a socket that has no alternatives → that socket shows only the equipped perk.
- Remove all candidates → empty state with reset/re-search (FR-018).

## Automated coverage (expected)

| Area | Test location |
|------|---------------|
| Tier derivation bands + exotic/unavailable | `src/data/rules/armorTiers.test.ts` |
| Set-bonus-by-itemHash map/lookup | `src/lib/inventory/instances/armorSetBonus.test.ts` |
| Armor projection adds `tier`/`setBonus`; weapon unaffected | `src/lib/inventory/instances/projectInstance.test.ts` |
| Weapon perk options resolution + degradation | `src/lib/catalog/weaponPerkOptions.test.ts` |
| Perk-options route shape/errors | `src/app/api/catalog/weapons/perk-options/route.test.ts` |
| `set_items.instance_id` migration | `src/lib/db/schema.test.ts` |
| `setItemInputSchema` accepts `instanceId`; `upsertSetItem` persists it; default equipped perks | `src/lib/sets/*.test.ts` |
| Candidate session remove/reset/select reducer | `src/lib/inventory/instances/candidateSession.test.ts` |

## Docs

Update **`DEBUG.md`** in the same change (carousel disambiguation flow, `perk-options` endpoint, prerequisites, edge-case table) and bump its **Last reviewed** date, per the `debug-docs` rule.
