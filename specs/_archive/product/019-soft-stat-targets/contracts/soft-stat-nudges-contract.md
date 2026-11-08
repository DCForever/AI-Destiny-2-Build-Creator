# Contract: Soft Stat Nudges

## Suggest

`GET /api/user/builds/:id/suggest-stat-targets` → `{ nudges: [{ stat, suggested, reason, synergyId? }] }`

## Accept

`PATCH /api/user/builds/:id` with `{ acceptStatNudges: true }` or explicit `softStatTargets` merge:
- For each nudge, set target to `max(existing, suggested)` unless user sends explicit map.
- Ignoring = no PATCH; targets unchanged.
