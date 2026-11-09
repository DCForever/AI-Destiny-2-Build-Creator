# Research: DART-013 Drift Schema

**Date**: 2026-07-24  
**Branch**: `dart-013-drift-schema`

## Decisions

### R1 — Separate `destiny2_db` package

**Decision**: New workspace package `packages/db` (`destiny2_db`) for Drift schema + open helpers.  
**Rationale**: Storage (DART-012) is path-only; domain stays pure; repos (DART-015+) will sit on top of this package.  
**Alternatives rejected**: Embedding Drift in `destiny2_storage` (mixes path layout with SQL); putting schema in domain (violates purity).

### R2 — Mirror product *current* columns, not ensure* history

**Decision**: Table definitions match `src/lib/db/schema.ts` + post-migration columns from `client.ts` ensure* helpers as a single schemaVersion **1**.  
**Rationale**: Exit criteria is clean create; multi-step upgrades and import-from-legacy are DART-014 / DART-048.  
**Alternatives rejected**: Porting every intermediate ALTER as separate Drift migrations in this slice.

### R3 — Drift + sqlite3 (no Flutter)

**Decision**: Use `drift` + `sqlite3` with `NativeDatabase.memory()` / `NativeDatabase(File(...))` for pure-Dart tests and desktop file DB.  
**Rationale**: Port decisions: pure Dart I/O; Flutter Windows host comes later (DART-019); Jaspr WASM is DART-043.  
**Alternatives rejected**: `drift_flutter` only; better-sqlite3 Node binding; temporary Node sidecar.

### R4 — Critical uniques (product intent)

| Constraint | Product source | Notes |
| ---------- | -------------- | ----- |
| `users.bungie_membership_id` UNIQUE | schema + CREATE TABLE | Single membership row per Bungie id |
| `inventory_items(user_id, instance_id)` UNIQUE | CREATE TABLE UNIQUE | Full-replace sync identity |
| `sets(user_id, type, name)` UNIQUE INDEX | `idx_sets_user_type_name` | Library name uniqueness per type |
| `set_tags(set_id, tag_id)` UNIQUE | CREATE TABLE UNIQUE | Tag attach |
| `build_tags(build_id, tag_id)` UNIQUE | CREATE TABLE UNIQUE | Tag attach |
| `build_synergy_types(build_id, type, sub_type)` UNIQUE | CREATE TABLE UNIQUE | Identity synergy types |
| `inventory_sync_meta.user_id` PK | CREATE TABLE | One meta row per user |

Supporting indexes (product):

| Index | Columns |
| ----- | ------- |
| `idx_inventory_user_hash` | `(user_id, item_hash)` |
| `idx_inventory_user_bucket` | `(user_id, bucket)` |
| `idx_inventory_user_location` | `(user_id, location)` |
| `idx_set_tags_tag` | `(tag_id, set_id)` |
| `idx_set_items_set` | `(set_id)` |
| `idx_synergy_links_synergy` | `(synergy_id)` |
| `idx_variant_attachments_set` | `(set_id)` |
| `idx_loadouts_user_updated` | `(user_id, updated_at)` |

**RESTRICT**: `variant_set_attachments.set_id` → `sets(id)` ON DELETE RESTRICT (product parity for attach semantics).

### R5 — PRAGMA policy on open

**Decision**: Enable `foreign_keys = ON` always. WAL may be set for file DBs later by host; tests use default journal for memory. Document only.  
**Rationale**: Product client sets `foreign_keys = ON` and `journal_mode = WAL` for on-disk; memory tests need FK more than WAL.

### R6 — Codegen

**Decision**: Drift annotation + `build_runner` / `drift_dev` generates `*.g.dart`. Commit generated sources so CI does not require a separate codegen step unless preferred.  
**Rationale**: Spec Kit implementer and CI friendliness; matches common Drift monorepo practice.

## Product reference

- `src/lib/db/schema.ts` — Drizzle table definitions
- `src/lib/db/client.ts` — CREATE TABLE + ensure* columns + indexes
- `src/lib/db/schema.test.ts` — PRAGMA smoke expectations
- `docs/multiplatform-dart-port-decisions.md` — Phase 1 Drift schema; pure Dart I/O

## Non-decisions (later)

- Versioned migrations / empty→current path (DART-014)
- Repository layer (DART-015/016)
- Host singleton open + StorageRoot wiring (DART-019)
- WASM/OPFS executor (DART-043)
