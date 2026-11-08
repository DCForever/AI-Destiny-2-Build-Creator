# Contract: Soft Stat Targets (Build)

## Write

`PATCH /api/user/builds/:id` accepts:
```json
{ "softStatTargets": { "Health": 100, "Weapons": 80 } }
```
- Omit or `{}` clears all (or use `null` to clear).
- Invalid stat name or value outside 1–200 → `400`.
- Not an identity field (no `identityAction`).

## Read

Build detail includes `softStatTargets: Partial<Record<ArmorStatName, number>>`.
