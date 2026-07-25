# Implementation Plan: DART-050 Inventory Vault Resolution

**Branch**: `dart-050-inventory-vault-resolution` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-050-inventory-vault-resolution/spec.md`

## Summary

Close **GAP-INV-01** by adding Next-parity `buildEquipmentBucketLookup` and wiring non-empty lookups into every production inventory sync path so vault/postmaster weapon/armor instances are stored in Drift with equipment buckets. Package docs and host tests stop treating empty lookup as production-OK (PROC-01/02). Document Owned→entity-store residual (GAP-INV-06 → DART-053). Optional combat weapon stats (GAP-INV-07).

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_bungie`, `destiny2_manifest`, `destiny2_db`; Flutter Windows host; Jaspr web host  

**Storage**: Drift inventory tables (existing); StorageRoot raw tables + entity JSON (existing)  

**Testing**: `dart test packages/bungie`; `flutter test` on windows_host / web_host as applicable  

**Target Platform**: Multiplatform port shells (Windows Flutter primary; Jaspr equip path)  

**Project Type**: Pure package + host wiring (no new UI chrome beyond existing sync)  

**Performance Goals**: Lookup only for transfer-container item hashes (or prebuilt catalog map); no full-table scan on every equip if map is cached  

**Constraints**: Pure Dart I/O; no CLIENT_SECRET; soft never auto-applies; do not implement DART-051+  

**Scale/Scope**: One resolution helper + 3 production call sites + docs/tests  

## Constitution Check

- I. Small Testable Increments: US1 library → US2 hosts → US3 docs; optional US4 stats  
- II. Test-First: Lookup unit tests + host vault fixture assertions before/with wiring  
- III. Green Commit Checkpoints: bungie package green, then host tests  
- IV-V. Co-located package tests; validation via resolve counts  

No complexity violations.

## Project Structure

### Documentation (this feature)

```text
specs/dart-050-inventory-vault-resolution/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code (touched)

```text
packages/bungie/lib/src/profile/
  equipment_bucket_lookup.dart   # NEW: buildEquipmentBucketLookup (+ slot fallback)
  inventory_parse.dart           # optional: parseWeaponStatValues
packages/bungie/lib/destiny2_bungie.dart  # export
packages/bungie/test/
  equipment_bucket_lookup_test.dart
  sync_inventory_test.dart       # assert resolvedFromTransfer
packages/manifest/lib/src/
  equipment_bucket_lookup_source.dart  # optional helper: raw table load + catalog map
apps/windows_host/lib/settings/inventory_sync_controller.dart
apps/windows_host/lib/equip/equip_controller.dart
apps/windows_host/lib/host_bootstrap.dart  # inject lookup provider if needed
apps/windows_host/test/inventory_sync_controller_test.dart
apps/web_host/lib/equip/equip_controller.dart
packages/README.md
docs/multiplatform-dart-feature-gaps.md  # GAP-INV-01 status
docs/multiplatform-dart-slice-roadmap.md # finish only
```

**Structure Decision**: Keep pure lookup in `destiny2_bungie` (uses existing bucket constants; no manifest dependency). Hosts obtain raw table via `destiny2_manifest` / OfflineCatalog and pass `Map<int,int>` into sync.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
