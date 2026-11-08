# Quickstart: Catalog Universal Search

**Feature**: 027-catalog-universal-search  
**Date**: 2026-07-23

## Prerequisites

- Manifest + entity cache ready (Settings → Refresh manifest).
- `npm run dev`.
- Signed in + inventory sync for ownership/mutations.
- Contracts: [universal-search-contract.md](./contracts/universal-search-contract.md), [composition-actions-contract.md](./contracts/composition-actions-contract.md).

## Automated

```bash
npm test -- src/lib/catalog/universalSearch
npm test -- src/app/api/catalog/universal-search
npm run gate
```

## Manual US1 Search

1. Catalog → query `melee` (or known origin trait / artifact perk).
2. Mixed kinds with labels.
3. Nonsense query → no matches.
4. Whitespace → need-query guidance.

## Manual US2 Detail

Open hit → name/kind/description → back keeps query.

## Manual US3 Set

Weapon detail → Create/Add Set → legal slot → appears in Sets. Dual-exotic attempt blocked.

## Manual US4 Synergy

Perk/trait detail → Create/Add Synergy → link present; second add does not duplicate.

## Manual US5 Filters

Broad query → kind chip narrows list; over-narrow → filtered empty.

## Manifest not ready

Must not present as ordinary no-matches (503 / MANIFEST_NOT_READY).

## Exit

SC smoke OK; gate green; specialized Catalog facets still work.
