# Implementation Plan: DART-027 App Use Cases Library

**Branch**: `dart-027-app-use-cases-library` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-027-app-use-cases-library/spec.md`

## Summary

Add workspace package **`destiny2_app`** (`packages/app`) with in-process application use cases for **set/synergy library CRUD** and **variant set attach**. Use cases call DART-015 Drift repositories and pure **destiny2_domain** types/validators. Prove behavior with **in-memory Drift** unit tests. No HTTP, no Flutter UI, no hard build-save pipeline (DART-028).

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: `destiny2_db` (Drift repos), `destiny2_domain` (SetType, SynergyType, link kinds, library models), `test`  
**Storage**: SQLite via `AppDatabase` (memory for tests)  
**Testing**: `dart test packages/app`  
**Target Platform**: Pure Dart package (shared by Flutter Windows / later mobile / Jaspr)  
**Project Type**: Workspace application-layer library (P3 compose spine)  
**Performance Goals**: Full package suite &lt; 30s  
**Constraints**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; domain package stays pure  
**Scale/Scope**: ~1 new package, 3 use-case modules + mappers/errors + tests

## Constitution Check

- I. Small Testable Increments: US1 sets, US2 synergies, US3 attach.
- II. Test-First: co-land tests with implementation; green before merge.
- III. Green Commit Checkpoints: `dart test packages/app` (+ optional pure graph guard).
- IV-V. Co-located tests under `packages/app/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-027-app-use-cases-library/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/app/
  pubspec.yaml                    # destiny2_app
  lib/
    destiny2_app.dart             # barrel
    src/
      errors.dart                 # UseCaseException + codes
      clock_ids.dart              # now() + id generators
      mappers.dart                # records → domain models
      set_use_cases.dart
      synergy_use_cases.dart
      attachment_use_cases.dart
  test/
    set_use_cases_test.dart
    synergy_use_cases_test.dart
    attachment_use_cases_test.dart

# Workspace root
pubspec.yaml                      # add packages/app to workspace + analyze script
packages/README.md                # document package
```

## Implementation approach

1. Scaffold `packages/app` workspace member with deps on `destiny2_db` + `destiny2_domain`.
2. Errors + clock/id helpers (injectable for deterministic tests).
3. Mappers: SetRecord→GearSet, SynergyWithLinks→Synergy, AttachmentRecord→Attachment, SetItemRecord→SetItem.
4. Set use cases: list/get/create/update/delete + item upsert/soft-remove with ownership checks.
5. Synergy use cases: list/get/create/update/delete with creatable type + designation immutability + link kinds.
6. Attachment use cases: prepareAttachments (fashion ≤1, snapshot freeze), replaceAttachmentByType, list.
7. Tests per US1–US3; run `dart test packages/app`.
8. Update packages/README + workspace pubspec; merge to base.

## Structure Decision

New package **`destiny2_app`** (not inside db or domain) so UI shells share the same orchestration layer without pulling Drift into domain or bloating repos with product rules.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| New package vs putting use cases in `db` | Separation of persistence vs application policy | Repos would accumulate product rules; UI would call raw SQL APIs |
