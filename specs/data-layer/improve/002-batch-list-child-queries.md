---
status: TODO
priority: P2
effort: M
risk: MED
category: perf
depends: []
planned_at: 799a9d6
issue: ""
---

# Batch child rows when listing builds, sets, and synergies

## Objective

Library list endpoints load each parent row then issue separate queries for tags, synergy types, or links (1+N). As users accumulate builds/sets/synergies, every Build library and Sets/Synergy list pays O(rows × children) SQLite round-trips. After this lands, list paths batch-load children with `inArray` (or equivalent) once per list and group in memory, preserving sort and empty-subtype semantics.

## Current context

- `src/lib/db/repositories/buildRepository.ts` — `listBuilds` / `rowToBuild` loads tags + synergy types per build.
- `src/lib/db/repositories/setRepository.ts` — `listSets` calls `loadTagsForSet` per set.
- `src/lib/db/repositories/synergyRepository.ts` — `listSynergies` / `getSynergiesByIds` call `listSynergyLinks` per synergy.
- Single-row getters (`getBuild`, `getSet`, `getSynergy`) may keep per-id loads or share helpers.
- Verification: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`.

Evidence:

```ts
// buildRepository.ts:58-84
function rowToBuild(db: AppDatabase, row: typeof builds.$inferSelect): BuildRecord {
  return {
    // ...
    tagIds: loadBuildTags(db, row.id),
    synergyTypes: loadBuildSynergyTypes(db, row.id),
    // ...
  };
}

export function listBuilds(db: AppDatabase, userId: number): BuildRecord[] {
  return db
    .select()
    .from(builds)
    .where(eq(builds.userId, userId))
    .all()
    .map((row) => rowToBuild(db, row));
}
```

```ts
// setRepository.ts:48-69
function loadTagsForSet(db: AppDatabase, setId: string): ConceptTagId[] { /* per set */ }

export function listSets(db: AppDatabase, userId: number, type?: SetType): SetRecord[] {
  const rows = /* select sets */;
  return rows.map((row) => rowToSet(row, loadTagsForSet(db, row.id)));
}
```

```ts
// synergyRepository.ts:87-96
export function listSynergies(...): SynergyWithLinks[] {
  const rows = /* select synergies */;
  return rows.map((row) => ({
    ...rowToSynergy(row),
    links: listSynergyLinks(db, row.id),
  }));
}
```

Conventions: Drizzle + better-sqlite3; repositories stay pure data access; services call repositories. Prefer `inArray` batch patterns already used in `listBuildsFiltered` / `getSynergiesByIds` parent selects.

## Detailed instructions

### Requirements

- R1: `listBuilds` (and filtered list helpers that map through `rowToBuild` for many rows) batch-load `build_tags` and `build_synergy_types` for all returned build ids in a constant number of queries (not per row).
- R2: `listSets` / `listSetsByTags` batch-load `set_tags` for all returned set ids.
- R3: `listSynergies` and `getSynergiesByIds` batch-load `synergy_links` for all returned synergy ids.
- R4: Tag id arrays remain sorted as today (builds/sets use sorted tag ids).
- R5: Synergy `subType` empty-string → null exposure semantics for builds’ `loadBuildSynergyTypes` remain unchanged.
- R6: Public repository return types and field shapes do not change; API JSON stays compatible.
- R7: Add or extend repository tests with multiple parents each having children, asserting correct grouping and query count where practical (or at least correctness of joined data).

### Acceptance criteria

- [ ] `npm run test` passes, including new/updated repository tests covering multi-row list with children
- [ ] `npm run typecheck` and `npm run lint` pass
- [ ] Manual or test assertion: listing N builds with tags does not call `loadBuildTags` N separate times (implementation uses batch helper)
- [ ] Spot-check: empty library and single-row library still return correct empty/`[]` children

### Scope boundaries

**In scope**

- `src/lib/db/repositories/buildRepository.ts`
- `src/lib/db/repositories/setRepository.ts`
- `src/lib/db/repositories/synergyRepository.ts`
- Matching `*.test.ts` files

**Out of scope**

- `getBuildDetail` / `resolveVariantEquipment` attachment expansion N+1 (separate concern)
- `enrichSetItems` per-item synergy lookups
- Changing pagination of inventory instances
- Schema migrations

### Risks and notes

- `listBuildsByTags` intersects tag ids iteratively today; batching children must not break intersection logic.
- UNIQUE empty-subtype storage for build synergy types must stay null-safe.
- Prefer shipping after or alongside the prod SQLite singleton improve prompt so list stress does not multiply handles; not a hard code dependency.