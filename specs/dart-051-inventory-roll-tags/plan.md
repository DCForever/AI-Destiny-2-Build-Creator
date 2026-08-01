# Implementation Plan: DART-051 Inventory Roll Tags

**Branch**: `dart-051-inventory-roll-tags` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-051-inventory-roll-tags/spec.md`

## Summary

Close **GAP-INV-02** by porting Next `computeRollTags` into pure Dart, wiring inventory normalize/`syncUserInventory` to emit full roll tags (crafted / champion / build samples) when perk name map + weapon meta are supplied, and connecting production hosts to build those maps from raw DestinyInventoryItemDefinition + OfflineCatalog weapon rows. Golden tests mirror `src/lib/inventory/rollTags.test.ts`. Soft never auto-applies; no CLIENT_SECRET.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_bungie` (+ new dep `destiny2_sandbox_data` for `getChampionCounterForFrame`); host OfflineCatalog / ManifestService for enrichment maps  

**Storage**: Drift `inventory_items.roll_tags` (existing JSON string array)  

**Testing**: `dart test packages/bungie` (roll_tags + sync_inventory); host tests if wiring assertions needed  

**Target Platform**: Multiplatform pure package + Windows/Jaspr production sync paths  

**Project Type**: Pure helper + sync wiring (no new UI chrome)  

**Performance Goals**: Build perk name map only for plug hashes present on inventory items; weapon meta only for itemHashes present  

**Constraints**: Pure Dart I/O; no CLIENT_SECRET; soft never auto-applies; do not implement DART-052+  

**Scale/Scope**: One pure module + sync API params + host builders + docs  

## Constitution Check

- I. Small Testable Increments: US1 pure → US2 sync → US3 hosts → US4 docs  
- II. Test-First: Golden rollTags tests first; sync fixtures with maps  
- III. Green Commit Checkpoints: bungie package green, then host wire  
- IV-V. Co-located package tests  

No complexity violations.

## Project Structure

### Documentation (this feature)

```text
specs/dart-051-inventory-roll-tags/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code (touched)

```text
packages/bungie/lib/src/inventory/roll_tags.dart          # NEW: computeRollTags
packages/bungie/lib/src/inventory/roll_tag_lookups.dart   # NEW: build maps from raw defs / catalog
packages/bungie/lib/src/sync/sync_inventory.dart          # wire normalize
packages/bungie/lib/src/sync/sync_freshness.dart          # pass-through params
packages/bungie/lib/destiny2_bungie.dart                  # exports
packages/bungie/pubspec.yaml                             # + destiny2_sandbox_data
packages/bungie/test/roll_tags_test.dart                  # golden fixtures
packages/bungie/test/sync_inventory_test.dart             # normalize emits tags
apps/windows_host/lib/settings/roll_tag_lookup_provider.dart  # NEW host builder
apps/windows_host/lib/settings/inventory_sync_controller.dart
apps/windows_host/lib/host_bootstrap.dart
apps/windows_host/lib/equip/equip_controller.dart
apps/web_host/lib/equip/... (equip controller / app wiring)
packages/README.md
docs/multiplatform-dart-feature-gaps.md
docs/multiplatform-dart-slice-roadmap.md  # finish only
```

**Structure Decision**: Keep pure rules in `destiny2_bungie` inventory module (sync-adjacent; depends on sandbox_data for champion frames). Avoid `destiny2_manifest` dependency on bungie — hosts inject maps built from OfflineCatalog / raw tables.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
