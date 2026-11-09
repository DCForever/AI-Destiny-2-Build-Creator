# Contract: Synergy Refinement (006 addendum)

**Feature**: 006-synergy-refinement  
**Base contract**: [001 synergy-contract.md](../../001-build-sets-synergies/contracts/synergy-contract.md)  
**Version**: 1.1

## Scope

Extends synergy create/update/list/reverse-lookup with **sub-type**, **auto-generated names**, and **updated type enum**. Link kinds unchanged.

## SynergyType (updated)

```ts
type SynergyType =
  | 'verb' | 'melee' | 'grenade' | 'super' | 'element'
  | 'primary_weapon' | 'special_weapon' | 'heavy_weapon'
  | 'dps' | 'healing';

// Legacy read-only (migrate on PATCH/POST re-save):
// 'kinetic_weapon' | 'damage'
```

## SynergyInput (updated)

```ts
type SynergyInput = {
  name?: string;           // optional on create — server generates if omitted
  type: SynergyType;
  subType?: string | null; // required per category rules (see data-model.md)
  description?: string;
  links: SynergyLink[];
};
```

**Server behavior**:

1. Normalize legacy `type` on update (`kinetic_weapon` → `element` + `Kinetic`; `damage` → `dps`).
2. Validate `subType` against category rules → `INVALID_SYNERGY_SUBTYPE`.
3. Validate links → `INVALID_SYNERGY_LINK` (unchanged).
4. Set `name = generateSynergyName({ type, subType, linkDisplayName: links[0].displayName })` (primary link = first link; MVP single-link create).

## Auto-name patterns

| type | subType | Example name |
|------|---------|--------------|
| verb | Scorch | `Verb: Scorch — Skyburner's Oath` |
| melee | Base | `Melee: Base — Monte Carlo` |
| element | Kinetic | `Element: Kinetic — Monte Carlo` |
| dps | — | `DPS — Witherhoard` |

Em dash (` — `) separator between sub-type segment and link name.

## Many-to-many (unchanged, reinforced)

- One target MAY link to **multiple** synergies (FR-010).
- `GET /api/user/synergies/by-target` MUST return **all** matches (FR-011).
- Creating a synergy MUST NOT detach existing synergies on the same target.

## Base sub-type semantics

When `subType === "Base"` for `melee` | `grenade` | `super`:

- Synergy documents interaction with **any** ability of that kind in build/suggestion context.
- Auto-name uses literal `Base` in pattern.

## Validation codes (extended)

| Code | When |
|------|------|
| `INVALID_SYNERGY_SUBTYPE` | Missing/invalid subType for category |
| `INVALID_SYNERGY_TYPE` | Request uses removed creatable type |
| `INVALID_SYNERGY_LINK` | Unchanged from 001 |

## API (unchanged paths)

| Method | Path | Change |
|--------|------|--------|
| GET | `/api/user/synergies` | Response includes `subType`; `type` may be legacy until migrated |
| POST | `/api/user/synergies` | Accepts `subType`; auto-name |
| PATCH | `/api/user/synergies/:id` | Same |
| GET | `/api/user/synergies/by-target` | Unchanged query; returns all synergies |

## Debug UI requirements (FR-033)

- Category + sub-type pickers (no free-text sub-type).
- Read-only auto-generated name preview.
- Catalog link pickers only (see [catalog-picker-contract.md](./catalog-picker-contract.md)).
- Description panel for selected link target.

See [data-model.md](../data-model.md), [quickstart.md](../quickstart.md).
