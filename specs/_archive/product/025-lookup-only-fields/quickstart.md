# Quickstart: Lookup-Only Fields

## Prerequisites

- Signed-in session for production create and debug builds
- Manifest available for search endpoints (local app with synced/cached manifest)

## Automated

```bash
npm test -- src/data/weaponTypes.test.ts src/data/subclasses.test.ts
npm run gate
```

After implementation, also run any new helper tests co-located with create/build form helpers.

## Manual — User Story 1 (production create)

1. Open production builds UI → Create build.
2. Confirm subclass is a select/chips list (not a text box).
3. Switch Titan → Hunter → Warlock; subclass options change; no free typing.
4. Search/select an exotic armor; clear it.
5. With a subclass selected, search and pick a pinned super; confirm typing in search alone does not set pinned super until pick.
6. Add a synergy type and save; build detail shows selected concepts.

## Manual — User Story 2 (debug subclass form)

1. Open `/debug/builds` create (or edit).
2. Change ability search text without picking — stored ability unchanged.
3. Pick a search result — ability updates.
4. Add aspect/fragment only via pick; remove via chip/button.
5. Rationale still accepts free prose.

## Manual — User Story 3 (generator)

1. Open LLM generator form → Preferences.
2. Preferred exotic / weapon: search-then-pick (or clear).
3. Weapon types: multi-select from known list (no comma text field).
4. Playstyle/notes remain free text.
5. Preview/submit request shows only selected types and picked names.

## Expected outcomes

- No free-text identity fields for subclass, abilities, exotics, or weapon types on the three surfaces.
- Gate green after each story checkpoint.
