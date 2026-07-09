# Quickstart: Item Filter Enrichment

**Feature**: 013-item-filter-enrichment  
**Branch**: `013-item-filter-enrichment`

## Prerequisites

- Repo on feature branch with manifest entity cache available (or extractable).
- Dev server: `npm run dev`
- Related docs: [data-model.md](./data-model.md), [contracts/ability-enrichment-search-contract.md](./contracts/ability-enrichment-search-contract.md)

## Setup

1. Ensure abilities store is rebuilt after extractor changes (project’s usual manifest extract / entity-cache refresh).
2. Run co-located tests:

```bash
npx vitest run src/lib/manifest/extractors/extractors2.test.ts src/app/api/manifest/search/route.test.ts
```

3. Full gate before commit checkpoints:

```bash
npm run gate
```

## Validation scenarios

### V1 — Record enrichment (US1)

Inspect extracted ability records (fixture or live cache) for:

| Ability | Expect |
|---------|--------|
| Phoenix Dive | `classType: Warlock`; affinities include Dawnblade + Prismatic Warlock; `verbs` includes Cure |
| Chaos Reach | `classType: Warlock`; affinities include Stormcaller; `element: Arc`; `verbs` includes Jolt |

Automated: extend `extractors2.test.ts` (and fixtures) to assert these fields.

### V2 — Structured filter without name (US2)

With server running:

```http
GET /api/manifest/search?category=abilities&classType=Warlock&verb=Cure&subclass=Dawnblade
GET /api/manifest/search?category=abilities&kind=super&subclass=Stormcaller&element=Arc&verb=Jolt
```

Expect Phoenix Dive and Chaos Reach respectively in under 30 seconds of manual verification (SC-002).

### V3 — Exclusivity (US3)

```http
GET /api/manifest/search?category=abilities&classType=Titan&verb=Cure
GET /api/manifest/search?category=abilities&subclass=Voidwalker&verb=Cure
GET /api/manifest/search?category=abilities&element=Solar&kind=super&subclass=Stormcaller
```

Expect empty or non-matching sets (no Phoenix Dive / Chaos Reach false inclusions).

### V4 — Text search still works (FR-010)

```http
GET /api/manifest/search?category=abilities&q=Chaos
```

Expect Chaos Reach still returned; enrichment fields present on the DTO.

## Done when

- [ ] Extractor tests cover FR-006 / FR-007 anchors
- [ ] Search route contract tests cover AND filters + empty negatives
- [ ] Manual V2 queries succeed without typing ability names
- [ ] `npm run gate` green
