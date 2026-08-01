# Research: DART-016 Repos Inventory

**Date**: 2026-07-24

## R1 — Product repository surface

**Decision**: Port behavioral core of:

| TS module | Dart target |
| --------- | ----------- |
| `src/lib/db/repositories/inventoryRepository.ts` | `inventory_repository.dart` |
| `src/lib/bungie/syncInventory.ts` (`syncLocks` / `SyncInProgressError`) | `inventory_busy_lock.dart` (hook only; no network) |

**Rationale**: Roadmap exit names inventory repo + full-replace + busy lock. Product `upsertInventoryBatch` is the write contract; product mutex lives above Bungie sync — we expose the same **hook shape** at the repo layer so DART-024 can reuse without re-inventing.

**Alternatives**: Only DB transaction without lock (rejected — exit requires busy lock hook); lock table in SQLite (rejected — overkill for single-process hosts; product uses in-memory Map).

## R2 — Full-replace shape

**Decision**: One Drift `transaction` with **delete-all-for-user + batch insert** (full-replace), then sync meta + users timestamp:

1. Delete all `inventory_items` for `user_id`.
2. Batch-insert the new item list (composite unique still enforced on insert).
3. Read prior meta → `syncVersion = prior + 1` (or 1 if none).
4. Upsert `inventory_sync_meta` (`itemCount`, `syncVersion`, `lastFullSyncAt`).
5. Update `users.last_sync_at`.

**Rationale**: Exit requires batch insert in one transaction + full-replace semantics. Product uses per-row upsert + orphan delete for write amplification; Drift’s autoincrement PK makes composite-unique `ON CONFLICT` awkward. Delete+insert is equivalent for callers and simpler to prove atomic.

## R3 — Composite unique

**Decision**: Rely on existing Drift table uniqueKeys `{userId, instanceId}` from DART-013; use `InsertMode.insertOrReplace` or Drift `insertOnConflictUpdate` for upserts. Tests prove raw duplicate insert fails and replace updates in place.

## R4 — Busy lock semantics

**Decision**:

- Class `InventoryBusyLock` with `runExclusive<T>(int userId, Future<T> Function() body)`.
- If user already busy → throw `InventoryReplaceBusyException`.
- `isBusy(userId)` for UI hooks later.
- Default shared lock instance for convenience; injectable for tests.
- `replaceInventoryBatch` remains **lock-free** (pure transaction) so unit tests can call it directly; `replaceInventoryBatchExclusive` uses the lock.

**Rationale**: Separates transaction correctness from concurrency UX; matches product where lock wraps outer sync but DB write is pure.

## R5 — Out of scope network

**Decision**: No profile client, no OAuth, no entity cache enrichment. Callers supply fully formed `InventoryItemRecord` lists.

## R6 — Soft guidance

**Decision**: Inventory repos never evaluate or auto-apply soft guidance.
