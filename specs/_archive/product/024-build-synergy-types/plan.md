# Implementation Plan: Build Synergy Types

**Branch**: `024-build-synergy-types`

## Approach

1. Replace `build_synergies` with `build_synergy_types`; migrate existing rows.
2. API: `synergyTypes` replaces `synergyIds`; validate with existing subType rules.
3. `resolveDesignatedSynergies` as single choke point for coverage/suggestions/naming/stat nudges.
4. UI: Type/subType pickers on create and debug edit.
5. Tests: NO_SYNERGY, unmatched Type, bridge union, identity confirm.

## Key files

- `src/lib/db/schema.ts`, `src/lib/db/client.ts`, `buildRepository.ts`
- `src/lib/builds/schemas.ts`, `buildService.ts`, `resolveDesignatedSynergies.ts`
- `coverage.ts` / `coverageService.ts`, suggestion services, `defaultBuildName.ts`, `statNudges.ts`
- Create/debug build UI components
