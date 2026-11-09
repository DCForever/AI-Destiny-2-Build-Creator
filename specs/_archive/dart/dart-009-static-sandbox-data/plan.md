# Implementation Plan: DART-009 Static Sandbox Data

**Branch**: `dart-009-static-sandbox-data` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-009-static-sandbox-data/spec.md`

## Summary

Add pure Dart package `packages/sandbox_data` (`destiny2_sandbox_data`) porting curated Destiny sandbox static tables from product `src/data/**` (stat benefits, synergy verbs, exotic ability requirements, armor archetypes, champion counters, etc.) with golden unit tests and a documented process for future sandbox patches.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace 3.11.x)  
**Primary Dependencies**: None at runtime (pure constants package)  
**Storage**: N/A (compile-time constants)  
**Testing**: `package:test` via `dart test packages/sandbox_data`  
**Target Platform**: Pure library (all hosts later)  
**Project Type**: Melos monorepo package  
**Performance Goals**: N/A (small static tables)  
**Constraints**: Zero IO/UI; pure Dart only; no Node sidecar; soft tables never auto-apply  
**Scale/Scope**: ~10–12 modules + one test suite + update doc

## Constitution Check

- I. Small Testable Increments: US1 core tables, US2 supporting tables, US3 docs.
- II. Test-First: Golden tests land with implementation; suite green before merge.
- III. Green Commit Checkpoints: `dart test` + analyze on sandbox_data (and domain still green).
- IV-V. Co-located tests under `packages/sandbox_data/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-009-static-sandbox-data/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md

docs/sandbox-data-update-process.md   # sandbox patch update process
```

### Source Code

```text
packages/sandbox_data/
├── pubspec.yaml
├── lib/
│   ├── destiny2_sandbox_data.dart
│   └── src/
│       ├── armor_stat_name.dart
│       ├── stat_benefits.dart
│       ├── synergy_elements.dart
│       ├── synergy_verbs.dart
│       ├── exotic_ability_requirements.dart
│       ├── armor_archetypes.dart
│       ├── champion_counters.dart
│       ├── activity_rules.dart
│       ├── ability_timings.dart
│       ├── weapon_types.dart
│       ├── concept_tags.dart
│       └── subclasses.dart
└── test/
    └── sandbox_data_test.dart

pubspec.yaml                          # workspace: + packages/sandbox_data
packages/README.md                    # document new package
```

## Implementation approach

1. Scaffold package + workspace member + barrel export.
2. Port ArmorStatName wire enum + stat benefits + computeBenefitsAt.
3. Port synergy elements/verbs + exotic ability requirements.
4. Port supporting rule tables (archetypes, champions, activity, timings, weapons, tags, subclasses).
5. Golden tests from TS vitest cases.
6. Write `docs/sandbox-data-update-process.md`; link from packages/README.
7. Analyze + test green; merge to `feature/multiplatform-dart`; update roadmap.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into meta pack / LLM digests | Explicit out of scope |
| ArmorStatName duplicate vs domain | Document; independent package this slice |
| Floating interpolation drift | Match TS Math / toFixed semantics |
| Empty exotic table confusion | Tests cover null/empty helpers |

## Complexity Tracking

None — static table port.
