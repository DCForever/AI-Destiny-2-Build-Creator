# Research: 042-create-build-pickers

## 1. Collapse search when selected

- **Decision**: In `ManifestSearchPicker`, when `!multi && selected`, render only selected hotspot + Clear; hide TextField, Search/Browse button, error, and result lists.
- **Rationale**: Matches product ask and mockup; single place fixes Create + Edit.
- **Alternatives**: Per-panel custom chrome — rejected (duplication).

## 2. Super scoping

- **Decision**: Pass full subclass scope via existing `buildSubclassSearchParams` / `resolveSubclassScope` (classType + element + subclass + kind=super). Wire CreateBuildPanel and BuildEditPanel to supply classType (and element via helper) in addition to subclass.
- **Rationale**: Debug path already correct; create only sent subclass.
- **Alternatives**: Client-side filter only — rejected (wrong results still fetched).

## 3. Exotic class scope

- **Decision**: Keep existing `classType` prop on exotic picker (already correct).
- **Rationale**: API + tests already enforce class filter.

## 4. Exotic group/sort

- **Decision**: New `groupAndSortExoticArmorSearchResults` mirroring mod groups; slot order Helmet → Gauntlets → Chest → Legs → ClassItem; sort `compareDisplayName` within group; sticky headers in picker.
- **Rationale**: Records already expose `slot`; UI currently ignores it.
- **Alternatives**: Server-side sort only — rejected (grouping is presentation; client groups mods today).

## 5. Synergy chips

- **Decision**: After exotic results load, one authenticated batch reverse-lookup for `kind=exotic_armor` + many `itemHash`es; map chips with `formatSynergyTypeDesignation`. Soft-fail on 401/error.
- **Rationale**: Avoid N× by-target calls on browse (limit 50).
- **Alternatives**: Enrich inside `/api/manifest/search` — rejected (auth + user library coupling on public-ish manifest route).

## 6. Batch API shape

- **Decision**: Extend `GET /api/user/synergies/by-target` to accept repeated `itemHash` (or `itemHashes`) when `kind=exotic_armor|weapon`; response `{ byItemHash: Record<string, SynergySummary[]>, ... }` or `{ synergiesByTarget: [...] }`. Single-hash path remains backward compatible.
- **Rationale**: Minimal surface; catalog already uses single-hash.
