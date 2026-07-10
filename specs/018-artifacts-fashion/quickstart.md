# Quickstart: Artifacts & Fashion

**Feature**: 018-artifacts-fashion  
**Branch**: `018-artifacts-fashion`

## Setup

```bash
npx vitest run src/lib/sets src/lib/builds
npm run gate
```

## Validation

### V1 — Artifact (US1)

On Builds debug: set artifact A + config on variant 1, artifact B on variant 2; reload; confirm independent storage.

### V2 — Fashion (US2)

On Sets debug: create fashion set; add ghost + finisher; attach to variant; confirm items persist. Confirm combat Resolve equipment ignores fashion.

### V3 — Resolved (US3)

Fetch Resolved: payload includes `artifact` and `fashion` (or nulls); omitted fashion slots absent.

### V4 — Soft / non-identity (US4)

Save non-default without fashion → OK. Change only artifact → no confirm/fork prompt.

## Gate

```bash
npm run gate
```
