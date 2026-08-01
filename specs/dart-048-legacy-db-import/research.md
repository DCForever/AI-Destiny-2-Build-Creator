# Research: DART-048 Legacy DB Import

**Date**: 2026-07-25

## Decisions

### R1 — File copy + ensure* (not row ETL)

**Decision**: Validate source SQLite, backup target, copy file to `StorageRoot.appDbPath`, open with `AppDatabase.file` so DART-014 `applyEnsureUpgrades` heals late columns.

**Rationale**: Drift schema intentionally mirrors `src/lib/db` (`schema_notes.dart`, client.ts CREATE TABLE). Row shapes are already compatible; ensure* was designed for “partial / import-shaped DBs”.

**Rejected**: Per-table INSERT SELECT transform — higher risk, no parity gain for v1.

### R2 — Replace mode only

**Decision**: Full replace of `app.db` with optional timestamped backup. No merge.

**Rationale**: Single-user local-first product; merge identity conflicts (same set names, PK collisions) need product policy not in this slice.

### R3 — Minimum product shape for canApply

**Decision**: Require table `users` **and** at least one of `builds`, `sets`, `synergies`, `inventory_items`.

**Rationale**: Empty greenfield Next DB still has `users` after first use; pure empty SQLite without product tables must not overwrite a good platform DB.

### R4 — Windows Settings primary UX; IO-native API

**Decision**: Implement importer with `dart:io` + conditional stub for web. Windows Settings card is the in-app surface. Web OPFS file-picker deferred.

**Rationale**: Next `.cache/app.db` is a desktop path; D-IO pure Dart; Jaspr already has single-writer OPFS complexity.

### R5 — Host restart after apply

**Decision**: After apply, status recommends restart. Live `AppServices.db` remains the pre-import connection until process restart (or future re-bootstrap).

**Rationale**: `AppServices.db` is a single lifetime connection (DART-019); mid-session swap is out of scope.

## Open product notes (not blocking)

- Entity/manifest cache copy from Next `.cache` remains optional; Windows manifest refresh rebuilds entities.
- Token migration: Next iron-session cookies are not portable to Public+PKCE shells.
