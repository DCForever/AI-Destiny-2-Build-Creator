# Research: DART-044 Jaspr Entity Bundles

**Date**: 2026-07-25

## Decisions

### R1 — Single-file prebuilt bundle document

**Decision**: Ship/load a single JSON document:

```json
{
  "manifestVersion": "prebuilt-mvp-1",
  "builtAt": "2026-07-25T00:00:00.000Z",
  "counts": { "weapons": N, "exotic-armor": N, ... },
  "stores": {
    "weapons": [ /* WeaponRecord JSON */ ],
    "exotic-armor": [ ... ],
    "aspects": [ ... ],
    "fragments": [ ... ],
    "abilities": [ ... ],
    "mods": [ ... ]
  }
}
```

**Rationale**: One fetch on web; mirrors meta + store stems from DART-017 without multi-request waterfall. Native multi-file `entities/<version>/<store>.json` remains for Windows refresh.

**Alternatives rejected**: Per-store fetches only (more host code); gzip custom container (premature).

### R2 — MemoryEntityCache + EntityCacheReader

**Decision**: Introduce `EntityCacheReader` (`getMeta`, `getStore`, `version`) implemented by `FileEntityCache` (IO) and `MemoryEntityCache` (maps from bundle). Catalog uses the reader abstraction.

**Rationale**: OfflineCatalog already injects cache; abstracting avoids dart:io on web catalog path.

### R3 — Static web asset distribution (this slice)

**Decision**: Fixture at `apps/web_host/web/entities/prebuilt/bundle.json`, loaded via same-origin GET. Injectable `EntityBundleFetcher` for tests.

**Rationale**: Decisions doc leaves CDN vs ship-in-app open; static asset satisfies exit criteria without product channel decision.

### R4 — No browser rebuild

**Decision**: Web bootstrap never calls `rebuildEntityCacheInIsolate` / raw table load. Isolate rebuild stubs throw `UnsupportedError` on non-IO platforms.

### R5 — Web-safe package imports

**Decision**: Conditional imports for file/HttpClient/Isolate-backed modules so `import package:destiny2_manifest/...` works from Jaspr web. Catalog + bundle modules stay pure.

## References

- D-WEB-DB in `docs/multiplatform-dart-port-decisions.md`
- DART-017 `FileEntityCache`, DART-020 `OfflineCatalog` / facets
- DART-043 web host shell + OPFS (entities independent of SQLite)
