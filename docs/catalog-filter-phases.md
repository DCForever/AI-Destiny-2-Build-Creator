# Catalog filtering: Simple → Advanced (through Peggy)

Phased plan for mix-and-match **include/exclude** filtering, informed by DIM negation and Jira Simple/JQL dual mode. Synergy is a first-class dimension DIM does not have.

## Shared foundation (all phases)

```
Canonical filter model
  facets: { include: string[]; exclude: string[] }  // per dimension
  free-text (Fuse / substring)
  synergy (include/exclude ids + hash allow/deny when needed)
  exotic tri-state (include-only / exclude / off)

  filterCatalogClient(items, model)  // pure predicate
  zod schemas for persisted / API shapes (as needed)
```

| Rule | Semantics |
|------|-----------|
| Across dimensions | **AND** |
| Within **include** | **OR** |
| Any **exclude** match | Drop item |
| Free-text | Further AND |

Simple UI and (later) Advanced query both compile to this model.

---

## Phase Now — Simple Mode engine + chips

**Goal:** Ship include/exclude mix-and-match without a query language or new npm deps.

| Deliverable | Notes |
|-------------|--------|
| `FacetFilter` + helpers (`cycleFacetValue`, `facetChipState`, `matchesFacet`) | Pure TS in `filterCatalogClient` |
| Client filter: element, ammo, archetype, slot, class, exotic | Legacy `string[]` still = include-only |
| Synergy on same model | `synergies` facet and/or `itemHashesInclude` / `itemHashesExclude` |
| Free-text after facets | Existing query path |
| Catalog UI | Chip cycle **off → include → exclude → off**; clear visual for exclude |
| Tests | Vitest on shipped `filterCatalogClient` entry point |
| Deps | **None new** — keep Fuse + zod as-is |

**Out of scope for Now:** saved views, query string, Peggy, react-querybuilder.

---

## Phase Next — Serialize Simple ↔ thin query string

**Goal:** Optional Advanced text box that round-trips common Simple states.

| Deliverable | Notes |
|-------------|--------|
| Serializer: model → string | e.g. `element:Solar element:Arc ammo:-Special synergy:…` |
| Parser: string → model | Hand-rolled or light bootstrap (`search-query-parser` only if needed) |
| UI toggle Simple / Advanced | Advanced shows string; invalid → stay Advanced |
| zod | Validate parsed model |
| Tests | Round-trip fixtures for chip-expressible queries |

**Still not:** full boolean AST, `()`, `or` across dimensions, DIM `is:` / `stat:`.

---

## Phase Later — Peggy (DIM-like / beyond)

**Goal:** Own a real query language that grows without rewriting the predicate.

| Deliverable | Notes |
|-------------|--------|
| **Peggy** grammar | `and` / `or` / `not` / `-filter:` / `()` / quoted strings |
| Filter registry | Map names → facet ops (element, ammo, synergy, is:exotic, …) |
| Parse → canonical model (or evaluate AST against items) | Prefer compile-to-model where possible |
| Simple rehydrate | When query ⊆ chip-expressible, offer “Edit in Simple” |
| Extensibility | New keywords without UI rewrite |

**Beyond DIM (optional later still):** synergy operators, build-aware filters, saved library queries.

**Not in this phase:** react-querybuilder (visual AND/OR builder remains an alternative track if product prefers forms over text).

---

## Phase map (summary)

```
Now     → Facet engine + chip include/exclude + synergy composition + tests
Next    → Thin query string ↔ model + Simple/Advanced toggle
Later   → Peggy grammar + registry (DIM-like / grow beyond)
```

## Success for Phase Now

1. User can mix includes and excludes across dimensions (e.g. Solar|Arc, exclude Special).
2. Synergy include/exclude participates in the same AND composition (via facet and/or hash sets).
3. Catalog UI expresses include vs exclude on multi-value chips.
4. Unit tests drive `filterCatalogClient` with mix fixtures; typecheck passes.
