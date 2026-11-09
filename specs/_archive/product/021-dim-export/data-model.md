# Data Model: DIM Export

## DimExportRequest

| Field | Type | Notes |
|-------|------|-------|
| jsonOnly | boolean? | Default false; when true, skip DimSync share |

## DimExportResponse

| Field | Type | Notes |
|-------|------|-------|
| loadout | DimLoadout | Always on 200 |
| shareUrl | string? | Present when share succeeded |

## DimLoadout (existing)

Reuse `src/lib/dim/dimLoadout.ts` types. Variant builder fills:

- `equipped` — combat pins (+ optional subclass hash)
- `unequipped` — fashion specified slots
- `parameters.mods` — collected mod hashes
- `parameters.statConstraints` — soft targets when set
- `notes` — artifact + subclass summary text

## No new DB tables

Uses builds, variants, attachments, inventory pins, soft_stat_targets.
