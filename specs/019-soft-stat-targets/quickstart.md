# Quickstart: Soft Stat Targets

**Feature**: 019-soft-stat-targets  
**Branch**: `019-soft-stat-targets`

## Setup

```bash
npx vitest run src/lib/builds/coverage src/lib/builds/softStat src/lib/builds/statEstimate
npm run gate
```

## Validation

### V1 — Targets
Set Health=100 on build via debug; reload; both variants see it.

### V2 — Warnings
Fetch Coverage with estimate below target → `softStats` row; save still OK.

### V3 — Nudges
Suggest-stat-targets lists nudges; accept merges; ignore leaves unchanged.

### V4 — Soft coexistence
Element mismatch + softStats both advisory; no identityAction for targets.

## Gate

```bash
npm run gate
```
