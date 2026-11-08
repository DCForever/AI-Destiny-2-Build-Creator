# Contract: Inventory Plug Resolution (004 addendum)

**Feature**: 004-full-plug-resolution  
**Base contract**: [003 inventory-instances-contract.md](../../003-owned-inventory-instances/contracts/inventory-instances-contract.md)  
**Version**: 1.0 (DTO unchanged; behavior extended)

## Scope

This addendum documents **resolution behavior** for `plugs[]` on instance list and detail responses. Endpoint paths, query parameters, auth, and JSON shape are unchanged from 003.

## ResolvedPlug (unchanged shape)

```json
{
  "hash": 1636108362,
  "name": "Precision Frame",
  "displayName": "Precision Frame",
  "resolved": true
}
```

Unresolved fallback (unchanged):

```json
{
  "hash": 9999999999,
  "name": null,
  "displayName": "9999999999",
  "resolved": false
}
```

## Resolution coverage (004)

When manifest is loaded (`Settings → Refresh manifest`), the server MUST resolve plug hashes to names for typical equipped sockets including:

| Category | Examples |
|----------|----------|
| Intrinsics / frames | Precision Frame, Aggressive Frame |
| Roll perks | Fluted Barrel, Heal Clip |
| Origin / enhanced traits | Burning Ambition, Forge's Kin |
| Weapon mods | Synergy, Forge's Kin (mod socket) |
| Armor mods | Any mod in `mods` store |
| Masterwork | Reload Speed, Range, etc. |
| Cosmetics | Default Shader, ornaments |
| Trackers | Kill Tracker |

Resolution uses merged entity stores plus manifest item definitions for hashes not in stores.

## Query search (`q`)

Matching is case-insensitive substring on `displayName` or `name` **after** resolution. Queries such as `q=Synergy` or `q=Precision` MUST return instances whose equipped plugs resolve to matching names (SC-003).

## Non-goals (unchanged API)

- No `socketType` field in v1
- No stat values, kill counts, or ornament preview URLs
- No plug list filtering (all stored hashes returned)

## Fixture references (manual QA)

Weapon fixture: **The Ringing Nail** — see [quickstart.md](../quickstart.md) for hash checklist and expected names.

## Error and empty states

Identical to 003. Resolution failure for individual plugs never changes HTTP status.
