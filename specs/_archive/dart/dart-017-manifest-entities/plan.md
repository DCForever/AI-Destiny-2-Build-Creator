# Implementation Plan: DART-017 Manifest Entities

**Branch**: `dart-017-manifest-entities` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-017-manifest-entities/spec.md`

## Summary

Add **`packages/manifest`** (`destiny2_manifest`): entity store reader + MVP extractors (weapons, exotic-armor, aspects, fragments, abilities, mods), offline StorageRoot-backed rebuild/read, item/perk resolve, and hard-constraint adapters that feed `destiny2_domain` pure evaluators. No network refresh (DART-018).

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: `destiny2_storage`, `destiny2_domain`, `path`, `test`; `dart:io` + `dart:convert` for JSON files  
**Storage**: Versioned entity JSON under StorageRoot `entities/<versionDir>/`  
**Testing**: `dart test packages/manifest`  
**Target Platform**: Pure Dart package (Windows host first; no Flutter)  
**Project Type**: Workspace library (P1 data / manifest)  
**Performance Goals**: Full package suite &lt; 60s  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; domain stays pure  
**Scale/Scope**: MVP stores only; hand-trimmed fixtures

## Constitution Check

- I. Small Testable Increments: US1 read, US2 extract, US3 rebuild, US4 resolve/adapters.
- II. Test-First: co-land tests with implementation.
- III. Green Commit Checkpoints: `dart test packages/manifest`.
- IV-V. Co-located tests under `packages/manifest/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-017-manifest-entities/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/manifest/
  pubspec.yaml
  lib/
    destiny2_manifest.dart
    src/
      normalize.dart
      types/records.dart
      types/stores.dart
      types/services.dart
      raw/raw_types.dart
      extractors/common.dart
      extractors/exotic_armor.dart
      extractors/weapons.dart
      extractors/aspects.dart
      extractors/fragments.dart
      extractors/abilities.dart
      extractors/mods.dart
      extractors/registry.dart
      entity_cache.dart
      item_resolver.dart
      perk_validator.dart
      adapters/hard_constraints_adapters.dart
      adapters/mod_energy.dart
  test/
    fixtures/raw_tables.dart
    extractors_test.dart
    entity_cache_test.dart
    item_resolver_test.dart
    hard_constraints_adapters_test.dart
```

## Implementation approach

1. Record types + store names for MVP stores (JSON-serializable maps).
2. Raw parse helpers + common projection (normalizeName, enum maps, sockets).
3. Six MVP extractors against fixture raw tables.
4. `FileEntityCache` using StorageRoot paths: getStore, getMeta, rebuild.
5. Exact-name ItemResolver + by-hash; StorePerkValidator for weapon perk + fragment capacity.
6. Adapters: resolveFragmentCapacity + evaluateSubclassKit; mod energy configs → evaluateModEnergy.
7. Tests + workspace/README wiring.

## Structure Decision

New **`destiny2_manifest`** package (not inside `destiny2_db`). Depends on storage for paths and domain for pure evaluators. Not pure — uses filesystem.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Separate package vs db | Entities are JSON files, not SQLite | Cramming into db confuses Drift lifecycle |
| Simplified ability enrichment | Verbs/affinities need sandbox tables | Empty lists still satisfy hard adapters |
