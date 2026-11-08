# Plan: 040 Batch list child queries
## Summary
Add `inArray` batch loaders for child rows on list paths; map parents with in-memory grouping. Keep single-id getters on simple per-id loads (or shared batch of one). Preserve sorted tags and empty-subtype null exposure.

## Approach
1. **Builds** — `loadBuildTagsForIds` / `loadBuildSynergyTypesForIds` → `Map<id, children>`; `rowsToBuilds` used by `listBuilds`, `listBuildsByTags`, and other multi-row maps. `getBuild` keeps single-id loaders.
2. **Sets** — `loadTagsForSetIds` → map; `listSets` / `listSetsByTags` use it. `getSet` stays single-id.
3. **Synergies** — `listSynergyLinksForIds` → map; `listSynergies` / `getSynergiesByIds` (and callers via `getSynergiesByIds`) use it.
4. **Tests** — extend `setRepository.test.ts`; add `buildRepository.test.ts` and `synergyRepository.test.ts` multi-row assertions.

## Files
- `src/lib/db/repositories/buildRepository.ts`
- `src/lib/db/repositories/setRepository.ts`
- `src/lib/db/repositories/synergyRepository.ts`
- `src/lib/db/repositories/buildRepository.test.ts` (new)
- `src/lib/db/repositories/setRepository.test.ts`
- `src/lib/db/repositories/synergyRepository.test.ts` (new)
- `specs/data-layer/improve/002-batch-list-child-queries.md` (status DONE)

## Risks
- Empty `inArray` — guard when id list is empty.
- `listBuildsByTags` intersection must still return full tag arrays on matches, not only filter tags.
