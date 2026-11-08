# Implementation Plan: DART-052 Inventory Socket Enrichment

**Branch**: `dart-052-inventory-socket-enrichment` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-052-inventory-socket-enrichment/spec.md`

## Summary

Close **GAP-INV-03** by porting Next `classifyWeaponSocket` + `buildStoredSocketPlugs` into pure Dart, wiring inventory normalize/`syncUserInventory` to persist weapon socket plugs with `columnKind`/`columnLabel` when weapon socket context is supplied, and connecting production hosts to build that context from raw DestinyInventoryItemDefinition. Parity tests mirror Next classify fixtures. Soft never auto-applies; no CLIENT_SECRET.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_bungie` (pure inventory helpers); host `BungieManifestService` for raw table load on Windows  

**Storage**: Drift `inventory_items.socket_plugs` (existing JSON object list)  

**Testing**: `dart test packages/bungie` (classify + buildStoredSocketPlugs + sync_inventory socket fixtures)  

**Target Platform**: Multiplatform pure package + Windows/Jaspr production sync paths  

**Project Type**: Pure helper + sync wiring (no new UI chrome)  

**Performance Goals**: Build plug category maps only for plug hashes on inventory weapons; cache context per itemHash during a sync pass  

**Constraints**: Pure Dart I/O; no CLIENT_SECRET; soft never auto-applies; do not implement DART-053+  

**Scale/Scope**: One pure inventory module + sync API params + host builders + docs  

## Constitution Check

- I. Small Testable Increments: US1 pure → US2 sync → US3 hosts → US4 docs  
- II. Test-First: Classify/build golden tests first; sync fixtures with context  
- III. Green Commit Checkpoints: bungie package green, then host wire  
- IV-V. Co-located package tests  

No complexity violations.

## Project Structure

### Documentation (this feature)

```text
specs/dart-052-inventory-socket-enrichment/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code (touched)

```text
packages/bungie/lib/src/inventory/classify_weapon_socket.dart   # NEW
packages/bungie/lib/src/inventory/build_stored_socket_plugs.dart # NEW
packages/bungie/lib/src/inventory/weapon_socket_context.dart     # NEW context + raw table builder
packages/bungie/lib/src/sync/sync_inventory.dart                # wire normalize
packages/bungie/lib/src/sync/sync_freshness.dart                # pass-through
packages/bungie/lib/destiny2_bungie.dart                        # exports
packages/bungie/test/classify_weapon_socket_test.dart           # golden
packages/bungie/test/build_stored_socket_plugs_test.dart        # build fixtures
packages/bungie/test/sync_inventory_test.dart                   # normalize emits kinds
apps/windows_host/lib/settings/weapon_socket_context_provider.dart  # NEW
apps/windows_host/lib/settings/inventory_sync_controller.dart
apps/windows_host/lib/host_bootstrap.dart
apps/windows_host/lib/equip/equip_controller.dart
apps/web_host/lib/equip/... (pass-through when builder available)
packages/README.md
docs/multiplatform-dart-feature-gaps.md
docs/multiplatform-dart-slice-roadmap.md  # finish only
```

**Structure Decision**: Keep pure rules in `destiny2_bungie` inventory module (sync-adjacent). Avoid bungie→manifest dependency — hosts inject context from raw tables via builder typedef, same pattern as DART-051 roll tags.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
