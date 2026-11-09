# Feature Specification: Batch list child queries
**Branch**: 040-batch-list-queries | **Created**: 2026-07-23 | **Status**: Active
**Input**: `specs/data-layer/improve/002-batch-list-child-queries.md`

## Objective
Eliminate 1+N child loads when listing builds, sets, and synergies by batching tags, synergy types, and links with `inArray`, grouping in memory, and preserving sort / empty-subtype semantics.

## Scope
**In**: `buildRepository`, `setRepository`, `synergyRepository` list paths and matching tests.
**Out**: `getBuildDetail` attachment expansion; `enrichSetItems`; schema migrations; pagination changes.

## Requirements
- FR-001 `listBuilds` and multi-row helpers that hydrate builds MUST batch-load `build_tags` and `build_synergy_types` in a constant number of queries per list.
- FR-002 `listSets` and `listSetsByTags` MUST batch-load `set_tags` for returned set ids.
- FR-003 `listSynergies` and `getSynergiesByIds` MUST batch-load `synergy_links` for returned synergy ids.
- FR-004 Build/set `tagIds` remain sorted ascending as today.
- FR-005 Build synergy type empty-string storage continues to expose `subType: null`.
- FR-006 Public repository return types and field shapes stay compatible.
- FR-007 Repository tests cover multi-parent lists with children and empty/single-row cases.

## Success
- SC-001 Listing N parents with children does not issue per-row child loader queries (batch helpers used).
- SC-002 Empty library and single-row lists return correct `[]` children.
- SC-003 `npm run test`, `typecheck`, and `lint` pass for touched surface.
