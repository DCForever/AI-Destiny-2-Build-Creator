# Quickstart: Synergy Refinement

**Feature**: 006-synergy-refinement  
**Purpose**: Manual validation on `/debug/synergies` and picker APIs  
**Operator guide**: [DEBUG.md](../../../DEBUG.md)

## Prerequisites

```bash
npm run dev
# http://localhost:3000
# Sign in
# Settings → Refresh manifest (required for pickers)
```

**Debug entry**: `/debug/synergies`, `/debug/catalog` (reverse lookup badges)

## Scenario 1: Auto-name + Verb synergy (US1)

1. Open `/debug/synergies`.
2. Select category **verb**, sub-type **Scorch** (from picker — not free text).
3. Link kind **weapon** → search catalog picker → **Skyburner's Oath**.
4. Confirm name preview: `Verb: Scorch — Skyburner's Oath` (read-only).
5. Create → JSON panel shows same name in response.

**Pass**: SC-001, SC-004.

## Scenario 2: Base melee + Element Kinetic (US2)

1. Category **melee**, sub-type **Base**, link a weapon.
2. Name: `Melee: Base — {weapon}`.
3. Category **element**, sub-type **Kinetic**, link same or different weapon.
4. Name: `Element: Kinetic — {weapon}`.
5. Confirm **Kinetic Weapon** and **Damage** are not in category list; **DPS** is.

**Pass**: SC-006.

## Scenario 3: Multi-synergy on one weapon (US3)

1. Create **DPS** synergy linked to weapon X.
2. Create **Verb: Void Breach** (or Scorch) synergy linked to same weapon X.
3. Reverse lookup: kind `weapon`, item hash for X → **both** synergies in JSON.
4. On `/debug/catalog`, select weapon X → synergy badges show **both**.

**Pass**: SC-007.

## Scenario 4: Catalog pickers only (US4)

For each link kind, confirm **no** text/hash input fields:

| Link kind | Picker source |
|-----------|---------------|
| weapon | weapons catalog search |
| weapon_perk | `/api/catalog/synergy-pickers/links?kind=weapon_perk&q=` |
| origin_trait | `kind=origin_trait` |
| armor_set_bonus | set → 2pc/4pc → bonus from picker rows |

Attempt create without selecting link → validation error.

**Pass**: SC-002.

## Scenario 5: Description preview (US5)

1. Select weapon link → description text visible before Create.
2. Switch to origin trait → description updates.
3. Select armor set bonus → bonus description visible.

**Pass**: SC-003.

## Scenario 6: Legacy migration

If legacy synergies exist with `type: damage` or `kinetic_weapon`:

1. Load in list — still visible.
2. Re-save (edit + save) → type becomes `dps` or `element` + subType `Kinetic`; name regenerated.

## API smoke (optional)

```bash
# Sub-types (signed-in session cookie required for user routes; catalog routes public)
curl "http://127.0.0.1:3000/api/catalog/synergy-pickers/subtypes?category=element"
curl "http://127.0.0.1:3000/api/catalog/synergy-pickers/links?kind=origin_trait&q=Cast"
```

## Gate

After implementation:

```bash
npm run gate
```

**Pass**: all tests green including new `generateSynergyName.test.ts`, `subTypeVocabularies.test.ts`, picker route tests.
