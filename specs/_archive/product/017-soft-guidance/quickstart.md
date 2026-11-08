# Quickstart: Soft Guidance & Coverage Indicators

**Feature**: 017-soft-guidance  
**Branch**: `017-soft-guidance`

## Setup

```bash
npx vitest run src/lib/builds/coverage src/lib/suggestions
npm run gate
```

## Validation

### V1 — Tiers (US1)

Fixtures: all links / some links / no links → `supported` / `weak` / `missing` on Fetch Coverage.

### V2 — Breakdown (US2)

Mixed synergy + partial set bonus + off-element weapon → rows for all three; **no** soft-stat rows.

### V3 — Suggest bias (US3)

Weak/missing synergy → suggest-sets top results prefer gap-closing sets; reasons mention gap close.

### V4 — Soft save (US4)

Non-default variant with missing coverage still saves; illegal exotic still hard-fails.

## Gate

```bash
npm run gate
```
