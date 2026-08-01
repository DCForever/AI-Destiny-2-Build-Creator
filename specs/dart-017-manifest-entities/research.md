# Research: DART-017 Manifest Entities

## Product sources

| Area | TS location |
| ---- | ----------- |
| Store shapes | `src/lib/manifest/types/records.ts`, `stores.ts` |
| Entity cache | `src/lib/manifest/entityCache.ts` |
| Extractors | `src/lib/manifest/extractors/*` |
| Resolver | `src/lib/manifest/itemResolver.ts` |
| Perk validator | `src/lib/manifest/perkValidator.ts` |
| Hard adapters | `src/lib/builds/assertSubclassKit.ts`, `assertModEnergy.ts` |
| Paths | `packages/storage` StorageRoot (Dart) vs `cachePaths.ts` |
| Fixtures | `src/lib/manifest/__fixtures__/rawTables.ts` |

## Decisions

### R1 — Package name and placement

**Decision**: `packages/manifest` / pub name `destiny2_manifest`.  
**Rationale**: Parallel to product `src/lib/manifest`; separate from Drift `destiny2_db`.  
**Alternatives**: Inside storage (mixes path layout with extractors); inside domain (would break purity).

### R2 — MVP store set

**Decision**: weapons, exotic-armor, aspects, fragments, abilities, mods.  
**Rationale**: Roadmap “weapons, armor, subclass pieces, mods”; hard adapters need aspects + mods (+ weapons for perk check).  
**Note**: Full product STORE_NAMES includes more; DART-018/020 can expand. Rebuild writes only MVP stores; meta.counts keys = MVP only.

### R3 — Fuzzy search

**Decision**: Exact normalized match + simple substring contains ranking (no Fuse.js dependency).  
**Rationale**: Hard adapters use exact name/hash; Fuse is catalog/LLM polish.  
**Assumption**: Documented in spec A; catalog can upgrade later.

### R4 — Ability enrichment

**Decision**: `subclassAffinities` and `verbs` default to empty lists in abilities extractor.  
**Rationale**: Full enrichment depends on sandbox overrides; not required for hard constraints exit.

### R5 — Rebuild scope vs DART-018

**Decision**: Rebuild = extract + write entity JSON only; no Bungie download.  
**Rationale**: Roadmap splits refresh to DART-018.

### R6 — JSON field names

**Decision**: Serialize entity records with product camelCase keys (`searchName`, `fragmentCapacity`, `energyCost`, `perkColumns`, …).  
**Rationale**: Offline fixture parity and possible import of prebuilt Next entity caches later (DART-044/048 adjacent).
