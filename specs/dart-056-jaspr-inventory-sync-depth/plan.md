# Implementation Plan: DART-056 Jaspr Inventory Sync Depth

**Branch**: `dart-056-jaspr-inventory-sync-depth` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-056-jaspr-inventory-sync-depth/spec.md`

## Summary

Bring Jaspr web inventory **Settings sync** and **Catalog Owned** depth to Windows post-DART-050 resolution rules: vault/postmaster transfer resolve via catalog slot lookup, diagnostics retained, Owned join + instance projections for equip/DIM pins — closing **GAP-WEB-01** / **RB-02** and unblocking **RC-SYNC** web owned depth.

## Technical Context

**Language/Version**: Dart SDK ^3.10  

**Primary Dependencies**: `destiny2_bungie` (`syncUserInventory`, equipment bucket lookup), `destiny2_db` (inventory repos, instance projection), `destiny2_manifest` (owned catalog annotate/filter, OfflineCatalog), Jaspr web host

**Storage**: Existing Drift inventory tables via WASM/OPFS writer tab (DART-043); no schema change

**Testing**: `dart test` in `apps/web_host` (controller + page + catalog owned); reuse package vault resolution already green

**Target Platform**: Jaspr web host (Windows path unchanged)

**Project Type**: Monorepo multiplatform port slice

**Performance Goals**: Single full-replace sync; catalog annotate from in-memory inventory list

**Constraints**: Pure Dart I/O; no CLIENT_SECRET; soft never auto-applies; no Node sidecar; single-tab writer

**Scale/Scope**: Settings inventory card + Catalog owned filter + App wiring + docs

## Constitution Check

- I. Small Testable Increments: controller → Settings UI → Owned catalog → docs
- II. Test-First: vault fixture controller tests + Owned catalog tests with implementation
- III. Green Commit Checkpoints: after web_host tests green; after docs merge
- IV-V. Co-located tests under `apps/web_host/test/`

## Project Structure

### Documentation (this feature)

```text
specs/dart-056-jaspr-inventory-sync-depth/
├── plan.md
├── research.md
├── quickstart.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
apps/web_host/lib/
  settings/
    inventory_sync_controller.dart   # NEW — mirror Windows, WebOAuthSession
    inventory_sync_card.dart         # NEW — Jaspr Settings card
  catalog/
    owned_catalog_bridge.dart        # NEW — entity × inventory join
  equip/
    equipment_bucket_lookup_provider.dart  # reuse for Settings
    roll_tag_lookup_provider.dart          # reuse optional enrichment
  pages/
    settings_page.dart               # inject card + controller
    catalog_page.dart                # All|Owned + instances
  app.dart                           # construct + pass inventory sync
  main.client.dart                   # no secrets; profile already present
apps/web_host/test/
  inventory_sync_controller_test.dart
  inventory_sync_card_test.dart
  catalog_owned_page_test.dart
  settings_page_test.dart            # extend
docs/
  multiplatform-dart-feature-gaps.md
  multiplatform-dart-cutover-parity-checklist.md
  multiplatform-dart-slice-roadmap.md
```

## Implementation approach

1. **InventorySyncController (web)** — copy Windows controller semantics: `ensureUser`, `syncUserInventory` with lookup/roll-tag/socket builders, `lastDiagnostics`, phases; use `WebOAuthSession` + jaspr `ChangeNotifier`.
2. **InventorySyncCard** — Settings panel: Sync now, meta, diagnostics monospace block, signed-out gate.
3. **App wiring** — When writer DB + oauth + profileClient available, construct controller with `createWebEquipmentBucketLookupBuilder` from entityLoader.catalog; pass to Settings; keep equip builders aligned.
4. **OwnedCatalogBridge** — same as Windows: list inventory, annotate, browse with scope, instancesFor.
5. **CatalogPage** — All|Owned chips, owned badges, select row → instance list with instanceId (copy-friendly text).
6. **Tests** — vault resolve/fail; owned filter + instance id; Settings card smoke; no CLIENT_SECRET.
7. **Docs** — GAP-WEB-01 closed, RB-02 cleared, RC-SYNC update, roadmap done.

## Complexity Tracking

None — reuses packages; host-only depth parity.
