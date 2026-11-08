# Contracts: UI Lookups

## Standing rule (UI contract)

Controls that bind **game concept identity** MUST:

1. Present options from a fixed vocabulary or search results.
2. Commit a value only on explicit user selection (or clear).
3. Not write identity from free-typed keystrokes alone.

Prose controls (name, notes, playstyle, rationale) are exempt.

## Production create payload contract

`POST /api/user/builds` (existing) — client MUST send:

```json
{
  "className": "Titan" | "Hunter" | "Warlock",
  "subclass": { "name": "<from SUBCLASSES_BY_CLASS>", "...": "..." },
  "synergyTypes": [{ "type": "...", "subType": "..." }],
  "exoticArmorHash": <number|null>,
  "exoticArmorName": <string|null>,
  "pinnedSuper": <string|null>
}
```

- `subclass.name` MUST be a vocabulary member for `className`.
- `exoticArmorHash`/`exoticArmorName` either both unset/null or from the same exotic lookup pick.
- `pinnedSuper` null/empty or a name chosen from ability search for that subclass.

## Manifest search (reuse)

`GET /api/manifest/search`

| Use | Query params |
|-----|----------------|
| Exotic armor | `category=exotic-armor`, optional `classType`, `q` |
| Exotic weapon | `category=exotic-weapon`, `q` |
| Super / abilities | `category=abilities`, subclass + `kind=super` (via `buildSubclassSearchParams`) |
| Aspects / fragments | `category=aspects` / `fragments` with subclass scope |

Selection commits `{ hash?, name }` from `results[]`; query text alone MUST NOT become the stored value.

## Weapon type vocabulary (generator)

Static module exports ordered unique weapon type display names. Include/exclude preferences MUST be subsets of that list.

## Debug escape hatches

Raw hash / JSON overrides remain allowed only on labeled advanced debug panels; they are not the primary path and MUST NOT reappear on production create.
