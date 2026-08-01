# Research: DART-014 Drift Migrations

**Date**: 2026-07-24  
**Sources**: `src/lib/db/client.ts` (`runMigrations`, `ensure*`), DART-013 `packages/db`, Drift `MigrationStrategy`

## R1 — Product migration model

**Decision**: Port **idempotent ensure\*** behavior, not a 1:1 history of every product deploy.

**Rationale**: Product uses `CREATE TABLE IF NOT EXISTS` for a *current-ish* full DDL, then runs ensure functions that ADD COLUMN / CREATE TABLE / rebuild if missing. There is no SQLite `user_version` gate.

**Alternatives considered**:

| Option | Rejected because |
| ------ | ---------------- |
| Full Drift schema export per intermediate version | No stored intermediate schemas in repo; overkill for import prep |
| schemaVersion bump to 2 with empty onUpgrade | Schema columns unchanged from DART-013; false version churn |
| Ensure only in DART-048 | Roadmap exit criteria require strategy + empty→current + version table **now** |

## R2 — Product ensure* inventory

| Product function | Intent |
| ---------------- | ------ |
| `ensureSynergySubTypeColumn` | `synergies.sub_type TEXT` if missing |
| `ensureStatValuesColumn` | `inventory_items.stat_values TEXT` |
| `ensureGearTierColumn` | `inventory_items.gear_tier INTEGER` |
| `ensureSocketPlugsColumn` | `inventory_items.socket_plugs TEXT` |
| `ensureSetItemInstanceIdColumn` | `set_items.instance_id TEXT` |
| `ensureBuildsIdentityColumns` | exotic weapon/name, pinned_super; rebuild builds if exotic_armor_hash NOT NULL |
| `ensureVariantArtifactColumns` | artifact_hash/name; artifact_config DEFAULT '[]' |
| `ensureSoftStatTargetsColumn` | `builds.soft_stat_targets TEXT` |
| `ensureSetOptimizerColumns` | sets.optimizer_constraints, linked_mod_set_id |
| `ensureBuildSynergyTypesTable` | CREATE build_synergy_types; migrate drop build_synergies |

## R3 — Drift wiring

**Decision**:

- `schemaVersion = 1` (unchanged).
- `onCreate` → `createAll()`.
- `onUpgrade` → placeholder for future version bumps (document that ensure steps may also run from beforeOpen).
- `beforeOpen` → `foreign_keys = ON` + `applyEnsureUpgrades`.

**Rationale**: Heals partial DBs whose `user_version` is already 1 (common for hand-copied legacy files after import sets version) and mirrors product “always ensure on open.”

## R4 — Version table shape

**Decision**: Code-level catalog `migrationVersionTable` / `ensureStepCatalog` with:

- `driftSchemaVersionCurrent = 1`
- step id, product function name, target table, description

Spec `data-model.md` duplicates the table for humans.

## R5 — Test strategy for partial DBs

**Decision**: Use raw SQL via a temporary native connection **or** `AppDatabase` customStatement after opening without relying solely on createAll for the partial fixture. Practical approach:

1. Open `NativeDatabase.memory()`, disable Drift create if needed — actually Drift always runs migrations on first query.
2. Better: open with a custom `MigrationStrategy` test double, **or** create partial schema with sqlite3 package directly then open with AppDatabase.file on that path — but AppDatabase onCreate only runs when user_version is 0.

**Chosen approach**:

- **Empty→current**: standard `AppDatabase.memory()` (user_version 0 → onCreate createAll → beforeOpen ensures no-op).
- **Partial ensure**: Build DB with sqlite3 / Drift customStatement on a connection where we manually set schema and call `applyEnsureUpgrades` with a thin `EnsureUpgradeExecutor` abstracting `pragmaTableInfo` + `exec`, so tests do not fight Drift’s createAll.

## R6 — Soft / security

Soft never auto-applies. No secrets. No Node sidecar. Pure packages unchanged.
