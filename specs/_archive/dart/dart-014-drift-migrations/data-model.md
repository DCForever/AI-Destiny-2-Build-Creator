# Data Model: DART-014 Drift Migrations

## Drift schemaVersion

| Drift schemaVersion | Meaning |
| ------------------- | ------- |
| **1** | Current product column set (DART-013 create-all). Greenfield `onCreate` lands here. |

Future product columns → bump to 2+ with `onUpgrade` steps; append rows below.

## Ensure step catalog (logical version table)

| Step ID | Product source | Target | Change |
| ------- | -------------- | ------ | ------ |
| `synergy_sub_type` | `ensureSynergySubTypeColumn` | `synergies` | ADD `sub_type` TEXT if missing |
| `inventory_stat_values` | `ensureStatValuesColumn` | `inventory_items` | ADD `stat_values` TEXT if missing |
| `inventory_gear_tier` | `ensureGearTierColumn` | `inventory_items` | ADD `gear_tier` INTEGER if missing |
| `inventory_socket_plugs` | `ensureSocketPlugsColumn` | `inventory_items` | ADD `socket_plugs` TEXT if missing |
| `set_item_instance_id` | `ensureSetItemInstanceIdColumn` | `set_items` | ADD `instance_id` TEXT if missing |
| `builds_identity` | `ensureBuildsIdentityColumns` | `builds` | ADD exotic weapon/name, pinned_super; rebuild if `exotic_armor_hash` NOT NULL |
| `variant_artifact` | `ensureVariantArtifactColumns` | `build_variants` | ADD artifact_hash/name; ADD artifact_config DEFAULT `'[]'` |
| `builds_soft_stat_targets` | `ensureSoftStatTargetsColumn` | `builds` | ADD `soft_stat_targets` TEXT if missing |
| `sets_optimizer` | `ensureSetOptimizerColumns` | `sets` | ADD `optimizer_constraints`, `linked_mod_set_id` if missing |
| `build_synergy_types` | `ensureBuildSynergyTypesTable` | `build_synergy_types` (+ drop `build_synergies`) | CREATE table if missing; migrate legacy attach table |

## Runtime objects

### EnsureUpgradeExecutor

Minimal SQL surface for upgrades (implemented by `AppDatabase` wrappers or test doubles):

- `tableExists(name) → bool`
- `columnNames(table) → List<String>` (PRAGMA table_info)
- `columnNotNull(table, column) → bool?`
- `exec(sql)`

### applyEnsureUpgrades(executor)

Runs all catalog steps in stable order (same order as product `runMigrations` ensure block).

## Unchanged entities

Core tables remain as DART-013 (`tables.dart`). Migrations do not redefine entities; they only heal missing columns/tables for import readiness.
