# Research: DART-015 Repos Library

**Date**: 2026-07-24

## R1 — Product repository surface

**Decision**: Port the **library** repository functions from:

| TS module | Dart target |
| --------- | ----------- |
| `src/lib/db/repositories/buildRepository.ts` | `build_repository.dart` |
| `src/lib/db/repositories/setRepository.ts` | `set_repository.dart` |
| `src/lib/sets/setItemService.ts` (persist only) | `set_item_repository.dart` |
| `src/lib/db/repositories/synergyRepository.ts` | `synergy_repository.dart` |
| `src/lib/db/repositories/variantRepository.ts` | `variant_repository.dart` |
| `src/lib/db/repositories/userRepository.ts` (minimal) | `user_repository.dart` |

**Rationale**: Roadmap names builds/sets/synergies/variants; product code is the behavioral source of truth for column mapping and RESTRICT usage via `findAttachmentsBySetId` + set delete.

**Alternatives**: HTTP-shaped repos (rejected — pure Dart in-process); domain-model-only (rejected — use cases DART-027 map later).

## R2 — Drift async style

**Decision**: Use Drift’s async API (`into`, `select`, `update`, `delete`, `transaction`) returning `Future`s. Callers `await`.

**Rationale**: Generated `AppDatabase` is async-first; matches DART-013 tests.

## R3 — RESTRICT handling

**Decision**: `deleteSetRecord` attempts delete; on SQLite foreign-key failure, rethrow a typed `SetInUseException` after optional `findAttachmentsBySetId` enrichment, **or** let the raw exception surface and document that callers should check attachments first. Prefer: check attachments first → if non-empty throw `SetInUseException(refs)` without attempting delete; if empty, delete (still relies on RESTRICT as backstop).

**Rationale**: Product service layer often pre-checks; schema still RESTRICT as hard guarantee (already tested in schema_test).

## R4 — IDs and clocks

**Decision**: Callers pass `id` and `now` (ISO-8601 strings) like product repos. Tests use fixed fixtures.

## R5 — Out of scope inventory

**Decision**: No `inventoryRepository` this slice (DART-016).

## R6 — Soft guidance

**Decision**: Repos store `soft_stat_targets` JSON only; never evaluate or auto-apply soft guidance.
