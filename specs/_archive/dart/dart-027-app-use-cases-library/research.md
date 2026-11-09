# Research: DART-027 App Use Cases Library

**Date**: 2026-07-24

## Product references (behavioral)

| Area | TS source | Port scope this slice |
| ---- | --------- | --------------------- |
| Sets | `src/lib/sets/setService.ts` | create/list/update/delete + detail refs; skip enrich/manifest armor stats |
| Set items | `setItemService` / repo upsert | Persistence upsert + soft-remove only; no exotic/mod energy gates |
| Synergies | `src/lib/synergies/synergyService.ts` | CRUD + designation immutable; skip consolidate/merge/subtype vocab/manifest link validate |
| Attach | `src/lib/builds/attachmentService.ts` | prepareAttachments fashion max-1 + snapshot freeze |
| Replace-by-type | `src/lib/builds/replaceAttachmentByType.ts` | Full behavior (preserve other types, live attach) |

## Package placement

- **Decision**: `packages/app` / `destiny2_app`
- **Rationale**: Port decisions say “share … in-process use cases”; domain must stay pure; db stays Drift-only CRUD.

## Validation boundary

- **In**: domain enums (`SetType`, `AttachmentMode`, `SynergyLinkKind`), creatable synergy wires, empty-name, duplicate set name, RESTRICT set-in-use, fashion ≤1, designation immutability
- **Out**: hard kit gates, soft coverage, optimizer constraint object schema, full synergy link schema vs game data

## ID / time

Injectable `IdGenerator` + `NowClock` so tests use fixed timestamps and stable ids without a uuid package dependency.
