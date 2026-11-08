# Research: DART-012 Storage Root

**Date**: 2026-07-24  
**Branch**: `dart-012-storage-root`

## Decisions

### R1 — Separate package, not domain

**Decision**: New workspace package `packages/storage` (`destiny2_storage`).  
**Rationale**: Domain purity (DART-011 graph guard) forbids path_provider/IO in pure packages. Storage is the first P1 IO-facing library.  
**Alternatives rejected**: Putting paths in `destiny2_domain` (violates P0 purity); ad-hoc strings in Drift package later (no single source of truth).

### R2 — Inject path_provider result; do not depend on path_provider in unit-test surface

**Decision**: `StorageRoot` is constructed from a `basePath` `String`. Windows hosts call `getApplicationSupportDirectory()` and pass `.path`. Package depends on `path` (+ `dart:io` only for optional ensure-directories).  
**Rationale**: Unit tests run with `dart test` without Flutter; matches “fake FS” exit criterion.  
**Alternatives rejected**: Runtime `path_provider` dependency in this package (forces flutter_test for trivial path tests).

### R3 — App-support root = path_provider directory (no repo `.cache`)

**Decision**: Production base is the application support directory from path_provider. Layout segments mirror product logical files **without** a `.cache` parent:

```text
<root>/app.db
<root>/current-version.json
<root>/manifest/<versionDir>/<table>.json
<root>/entities/<versionDir>/<store>.json
<root>/entities/<versionDir>/meta.json
<root>/entities/<versionDir>/perk-weapon-index.json
<root>/users/<membershipId>/preferences.json
```

**Rationale**: Port decisions Phase 1: “app-support path (not repo `.cache` CWD)”. Product `cachePaths.ts` uses `process.cwd()/.cache` — legacy Next only.  
**Alternatives rejected**: Nesting everything under `<support>/.cache` (confusing with Next); using temp/Documents.

### R4 — Version sanitization parity

**Decision**: Same rule as TS `versionToDirName`: replace `[^a-zA-Z0-9._-]+` with `_`.  
**Rationale**: Manifest version strings can contain unsafe path characters; keep extract/import paths predictable.

### R5 — Fake FS testing strategy

**Decision**: Primary tests assert pure path composition against a fixed base string (e.g. `/tmp/fake-support` or `C:\\fake\\support`). Optional test creates a real temp directory via `Directory.systemTemp` to exercise `ensureLayout` if implemented.  
**Rationale**: No Windows profile required; CI-friendly.

## Product reference

- `src/lib/manifest/cachePaths.ts` — logical segments and `versionToDirName`
- `docs/multiplatform-dart-port-decisions.md` — D-PATH Phase 1 app-support note

## Non-decisions (later)

- Actual Drift DB open (DART-013)
- Manifest refresh writers (DART-018)
- Legacy import mapping Next `.cache` → StorageRoot (DART-048)
