# Data Model: Soft Stat Targets

## SoftStatTargets (on `builds`)

JSON map keyed by `ArmorStatName`: Health | Melee | Grenade | Super | Class | Weapons.

| Rule | Detail |
|------|--------|
| Optional | Missing key = no target |
| Range | 1–200 inclusive when set |
| Scope | Build-level; all variants share |

## StatEstimate (derived)

Per-variant totals for the six stats + `incomplete: boolean`.

## SoftStatWarning (derived)

`{ stat, target, estimate, hint }` when `estimate < target`.

## StatNudge (derived)

`{ stat, suggested, reason, synergyId? }` from designated synergies.

## Migration

`ALTER TABLE builds ADD COLUMN soft_stat_targets TEXT` (nullable; treat null as `{}`).
