# Contract: Synergy Links and Associations

**Type**: Internal API + UI contract (P4)

**Business rules**: [../../business-rules.md](../../business-rules.md)

## Overview

A **Synergy** documents an interaction (Melee, Verb, Grenade, Void, etc.). **Synergy links** attach that synergy to manifest-backed game elements so users can say, for example, that the *Cast No Shadows* origin trait participates in a **Melee** synergy, or that *Eutechnology* set bonuses participate in a **Void** synergy.

**Rules**: BR-SYN-002, BR-SYN-005–008 — [FR-012](../spec.md#functional-requirements)

Association is **many-to-many**: one synergy → many targets (BR-SYN-006); one target → many synergies (BR-SYN-008).

## Synergy Link Kinds

```ts
type SynergyLinkKind =
  | 'weapon'           // whole weapon (item hash)
  | 'weapon_perk'      // specific perk plug on a weapon
  | 'origin_trait'     // weapon origin trait (e.g. Cast No Shadows)
  | 'armor_set_bonus'; // named armor set + piece count + bonus name

type SynergyLink = {
  kind: SynergyLinkKind;
  displayName: string; // denormalized for UI

  // kind === 'weapon'
  itemHash?: number;

  // kind === 'weapon_perk'
  perkHash?: number;
  parentItemHash?: number; // optional: perk on a specific weapon archetype

  // kind === 'origin_trait'
  originTraitName?: string; // e.g. "Cast No Shadows"
  originTraitHash?: number; // manifest hash when available

  // kind === 'armor_set_bonus'
  armorSetName?: string;    // e.g. "Eutechnology"
  bonusPieces?: 2 | 4;      // 2-piece or 4-piece threshold
  bonusName?: string;       // e.g. "Gift of the Ley Lines", "Techeun's Foresight"
  armorSetHash?: number;    // manifest set id when available
};
```

## Synergy Shape

```ts
type SynergyInput = {
  name: string;
  type: SynergyType; // melee, verb, grenade, void, …
  description?: string;
  links: SynergyLink[]; // zero or more association targets
};

type Synergy = SynergyInput & {
  id: string;
  userId: number;
  createdAt: string;
  updatedAt: string;
};
```

## Examples

| Synergy | Type | Link(s) |
|---------|------|---------|
| Melee — Cast No Shadows | `melee` | `{ kind: 'origin_trait', originTraitName: 'Cast No Shadows' }` |
| Void — Eutechnology | `verb` or element-void | `{ kind: 'armor_set_bonus', armorSetName: 'Eutechnology', bonusPieces: 2, bonusName: 'Gift of the Ley Lines' }`, `{ kind: 'armor_set_bonus', armorSetName: 'Eutechnology', bonusPieces: 4, bonusName: "Techeun's Foresight" }` |

One synergy MAY link to **multiple** targets (BR-SYN-006). One target MAY link to **multiple** synergies (BR-SYN-008).

| Target | Synergies (example) |
|--------|---------------------|
| Origin trait *Cast No Shadows* | Melee synergy, Verb synergy (both allowed) |
| *Eutechnology* 4pc bonus | Void synergy only, or Void + another if user links both |

## Validation

| Code | Rule ID | When | FR |
|------|---------|------|-----|
| `INVALID_SYNERGY_LINK` | BR-SYN-005 | Link kind missing required fields or manifest lookup fails | [FR-012](../spec.md#functional-requirements) |

**BR-SYN-005** validation by kind:
- `weapon`: `itemHash` required; must resolve in manifest weapons store.
- `weapon_perk`: `perkHash` required; must resolve in manifest perks/plugs.
- `origin_trait`: `originTraitName` or `originTraitHash` required; must resolve in manifest origin-trait data.
- `armor_set_bonus`: `armorSetName`, `bonusPieces`, `bonusName` required; resolve via `set-bonuses` store (see below).

## Manifest Resolution: `armor_set_bonus`

Links resolve against manifest store `set-bonuses` (`SetBonusRecord`):

```ts
// SetBonusRecord (manifest)
interface SetBonusRecord {
  hash: number;
  name: string;           // armor set name, e.g. "Eutechnology"
  perks: Array<{
    requiredCount: number; // 2 or 4 for piece thresholds
    name: string;         // bonus name, e.g. "Gift of the Ley Lines"
    description: string;
  }>;
}
```

**Resolution algorithm** (implement in `synergyService.validateLink`):

1. Find set where `SetBonusRecord.name` equals `armorSetName` (case-insensitive).
2. Find perk where `requiredCount === bonusPieces` AND `name` equals `bonusName`.
3. On match: persist `armorSetHash = SetBonusRecord.hash`.
4. On no match: reject with `INVALID_SYNERGY_LINK`.

**UI link picker**: search `set-bonuses` store → user picks set → picks 2pc or 4pc bonus from `perks[]` → auto-fills `bonusName` and `bonusPieces`.

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/user/synergies` | List synergies; filter by `type` |
| POST | `/api/user/synergies` | Create synergy with links |
| GET | `/api/user/synergies/:id` | Detail including links |
| PATCH | `/api/user/synergies/:id` | Update synergy and links |
| DELETE | `/api/user/synergies/:id` | Delete synergy |
| GET | `/api/user/synergies/by-target` | Reverse lookup: returns **all** synergies linked to target — `?kind=origin_trait&name=Cast+No+Shadows` (**BR-SYN-008**) |

## UI: SynergyEditor

**Rules**: BR-SYN-002, BR-SYN-004, BR-SYN-007, BR-SYN-008

- Synergy **type** picker (Melee, Grenade, Void, etc.).
- **Link picker** with tabs or facets by `SynergyLinkKind`:
  - Search weapons → add `weapon` link
  - Search perks → add `weapon_perk` link
  - Search origin traits → add `origin_trait` link
  - Search armor sets → select set + 2pc/4pc bonus → add `armor_set_bonus` link
- Multiple links per synergy; list with remove.
- When browsing catalog/inventory (**BR-SYN-004**), reverse lookup shows **all** linked synergies as badges (multiple per item allowed — **BR-SYN-008**).

## Suggestion Integration

When a build or set includes equipment matching any synergy link, **all** matching linked synergies are relevant suggestion context (**BR-SUG-004**, **BR-SYN-008**).

See [data-model.md](../data-model.md) and [business-rules.md](../../business-rules.md).
