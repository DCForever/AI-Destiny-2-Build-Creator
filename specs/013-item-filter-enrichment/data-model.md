# Data Model: Item Filter Enrichment

**Feature**: 013-item-filter-enrichment  
**Extends**: `AbilityRecord` in `src/lib/manifest/types/records.ts`; curated vocabularies in `src/data/synergyVerbs.ts` and `src/data/subclasses.meta.ts`

## Entities

### AbilityRecord (extended)

Persisted in the derived `abilities` entity store.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| hash | number | yes | Manifest item hash |
| name | string | yes | Display name |
| searchName | string | yes | Normalized lookup |
| icon | string \| null | yes | CDN path |
| description | string | yes | Manifest description |
| kind | AbilityKind | yes | `super` \| `grenade` \| `melee` \| `classAbility` \| `movement` |
| classType | DestinyClassName \| null | yes | Titan/Hunter/Warlock; `null` = shared / all classes |
| element | ElementName | yes | Kinetic \| Arc \| Solar \| Void \| Stasis \| Strand \| Prismatic |
| subclassAffinities | string[] | yes | Subclass display names from `SUBCLASS_METADATA` (e.g. `Dawnblade`, `Stormcaller`, `Prismatic Warlock`). Empty when unknown. |
| verbs | string[] | yes | Canonical curated verb names (e.g. `Cure`, `Jolt`). Empty when none known. |

**Validation rules**:

- `verbs` entries MUST resolve via `resolveVerbSubType` / known `SYNERGY_VERB_NAMES` (aliases normalized to canonical).
- `subclassAffinities` entries MUST be known subclass names from `SUBCLASS_METADATA` (or documented Prismatic variant names therein).
- Empty arrays are valid; MUST NOT invent values (FR-009).
- Duplicate affinities/verbs MUST be deduplicated.

**Canonical examples**:

| Ability | classType | element | subclassAffinities | verbs (min) |
|---------|-----------|---------|--------------------|-------------|
| Phoenix Dive | Warlock | Solar (or as derived) | Dawnblade, Prismatic Warlock | Cure |
| Chaos Reach | Warlock | Arc | Stormcaller | Jolt |

---

### Subclass Affinity Derivation (logical)

Not a persisted entity; extract-time projection.

| Input | Output |
|-------|--------|
| `plugCategoryIdentifier`, `classType`, `element` | Primary dedicated-subclass affinity via `SUBCLASS_METADATA` join |
| Shared category + element | Element-matched dedicated subclasses |
| Plug-set membership on subclass items | Additional affinities (esp. Prismatic) |
| Curated override map (hash → affinities) | Force-merge for FR-006 anchors when traversal incomplete |

**Filter semantics**: Positive `subclass` filter matches if **any** affinity equals the requested subclass (after normalize). Empty affinities → excluded from positive subclass filters.

---

### Effect Verb Tag (logical)

| Field | Type | Notes |
|-------|------|-------|
| name | string | Canonical `SYNERGY_VERBS[].name` |
| source | `'description' \| 'sandbox_perk' \| 'override'` | For tests/debug; optional on public DTO |

**Extraction rules**: Word-boundary match against whitelist; aliases normalized; overrides win / merge for known hashes.

---

### Advanced Filter Query

Logical query applied to ability search (AND across provided dimensions).

| Dimension | Param | Match rule |
|-----------|-------|------------|
| Text | `q` | Existing name/description search when present |
| Kind | `kind` | Equality on `AbilityRecord.kind` |
| Class | `classType` | Equality; `null` classType matches only when filter omitted or explicit shared policy |
| Element | `element` | Equality on `element` |
| Subclass | `subclass` | Membership in `subclassAffinities` |
| Verb | `verb` | Membership in `verbs` (canonical or alias-resolved) |

At least one of `q` or a structured filter MUST be present for a valid request.

---

### Ability Search Result DTO

| Field | Type | Notes |
|-------|------|-------|
| name | string | |
| hash | number | |
| icon | string \| null | |
| description | string | For informed selection |
| kind | AbilityKind | |
| classType | DestinyClassName \| null | |
| element | ElementName | |
| subclassAffinities | string[] | |
| verbs | string[] | |
| confidence | number | When text `q` used; structured-only may use 1.0 or omit ranking |

---

### Out of scope entities (v1)

- `AspectRecord` / `FragmentRecord` — no new subclass/verb fields this iteration.
- Weapon perks, mods, armor — unchanged.
