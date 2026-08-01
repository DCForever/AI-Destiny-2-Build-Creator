# Legacy Next.js `app.db` → StorageRoot import (DART-048)

**Status:** implemented  
**Updated:** 2026-07-25  
**Slice:** DART-048 `legacy-db-import`  
**Architecture:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) (D-IO pure Dart; StorageRoot app-support, not repo `.cache`)

## One migration path

| Step | Action |
| ---- | ------ |
| 1 | Locate the Next.js local SQLite file: repo **`.cache/app.db`** (or a copy of that file). |
| 2 | **Dry-run** against destination `StorageRoot.appDbPath` (Windows: path_provider application-support `app.db`). |
| 3 | Review row counts / warnings. Fix source path if `canApply` is false. |
| 4 | **Apply** (full **replace**). Existing target is copied to `app.db.bak-<UTC timestamp>` first. |
| 5 | Importer opens the new target once so **DART-014 ensure\*** heals late columns, then closes. |
| 6 | **Restart** the multiplatform host so the single DB connection binds the imported file. |
| 7 | Sign in again with **Public+PKCE** (Next session cookies are not imported). Refresh inventory/manifest as needed. |

Schema parity: Drift tables mirror product `src/lib/db`. Import is **file copy + ensure\***, not a Node sidecar or row-level ETL.

### Not in this path

- Merge of two libraries (replace only)
- Iron-session / confidential OAuth secrets (never shipped in Dart clients)
- Automatic entity/raw-manifest tree copy from Next `.cache` (re-run Windows manifest refresh)
- Jaspr web OPFS file-picker UI (desktop/Windows is primary; pure API is `dart:io`)

## APIs

### Pure Dart (`package:destiny2_db`)

```dart
const importer = LegacyDbImporter();

final plan = await importer.dryRun(
  sourcePath: r'F:\path\to\.cache\app.db',
  targetPath: storageRoot.appDbPath,
);
print(plan.summaryText);
if (!plan.canApply) { /* read plan.errors */ }

final result = await importer.apply(
  sourcePath: plan.sourcePath,
  targetPath: plan.targetPath,
  priorPlan: plan,
);
// result.backupPath, result.tableCountsAfter
```

**Dry-run rules (`canApply`):**

- Source exists and opens as SQLite
- Table `users` present
- At least one content table: `builds` | `sets` | `synergies` | `inventory_items`
- Source path ≠ target path

### Windows Settings UX

**Settings → Data migration → Legacy DB import**

1. Paste/type source path to `.cache/app.db`
2. **Dry-run** → plan summary
3. If target already exists, check the **confirm replace** box
4. **Apply import** → success text + restart guidance

### CLI

From the multiplatform worktree (native Dart):

```powershell
# Dry-run
dart run tool/legacy_db_import.dart --source path\to\.cache\app.db --target path\to\app_support\app.db

# Apply
dart run tool/legacy_db_import.dart --source path\to\.cache\app.db --target path\to\app_support\app.db --apply
```

## Soft / hard domain rules

Import moves **data only**. Soft guidance never auto-applies; hard DBR blocks are unchanged and re-evaluated when the user opens builds in the multiplatform shells.

## Related

- StorageRoot layout: `packages/storage` (DART-012)
- Ensure\* upgrades: `packages/db` `ensure_upgrades.dart` (DART-014)
- Roadmap row: [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md) DART-048
