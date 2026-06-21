# Quickstart: Build Sets and Synergies

**Purpose**: End-to-end validation scenarios for the feature. Run these after implementation to confirm the spec (user stories, clarifications, FRs, SCs) is satisfied.

**Prerequisites** (from spec assumptions):
- `npm run dev`
- Manifest refreshed (`Settings > Refresh manifest` with BUNGIE_API_KEY)
- LLM configured (local or Grok)
- (Optional) Sign in + sync inventory for "my" items
- Existing build or loadout available for attachment tests

**Setup commands**:
```bash
npm run dev
# In browser: http://localhost:3000
# Refresh manifest if needed
```

## Scenario 1: P1 - Create, manage, delete Sets (core increment)
1. Navigate to Sets management (new UI or from build editor).
2. Create "Solar Weapons PVE" Weapon Set.
3. Add a specific weapon roll: choose base weapon + select perks (barrel, magazine, traits, masterwork, etc.).
4. Verify: appears in list with category + full roll data stored. The exact perks/barrels are preserved.
5. Remove ("delete") the weapon from the set: UI can still show what the previous roll was ("what was in that weapon").
6. Alternatives offered: system suggests other weapons with matching/similar perks.
7. Edit: change category or roll perks.
5. Attempt duplicate: create another "Solar Weapons PVE" Weapon Set → error (unique within category/type per clarif/FR-005).
6. Create a Fashion Set "My Transmog" (cosmetic only, per clarif A/FR-018).
7. Delete a non-attached set → succeeds, removed from lists.
8. Expected: <60s for create 3+ items (SC-001); fashion ignored in functional views.

## Scenario 2: P2 - Filter weapons and armor
1. Open weapons/armor browser (existing or extended).
2. Filter full catalog (no login) by type + "PVE".
3. Switch to "My Weapons" (after sync) + category filter.
4. Search by name.
5. Expected: instant results (SC-002), correct ownership distinction, metadata shown.

## Scenario 3: P3 - Attach Sets to Builds (live/snapshot + suggestions)
1. Open or create a build with exotic (e.g. Vex Mythoclast).
2. Attach "Melee:Ferropotent" Armor Set:
   - Choose "live reference" (default per clarif).
   - Choose "snapshot" for a Weapon Set (captures the exact perks/barrels at that moment).
3. Save build.
4. Edit the live Set (add item or change perks) → verify build updates (live).
5. Edit the snapshot Set (change perks) → build unchanged (frozen roll data preserved).
6. If a weapon is removed from the set later, the snapshot or set history can show the previous full roll, and alternatives can be suggested based on the stored perks.
6. View suggestions:
   - Auto: select subclass/exotic → contextual set suggestions appear.
   - Explicit: use "Suggest for Melee focused" or button → proposals (hybrid per clarif C).
7. Export/view build → attachments shown with mode indication (SC-003).
8. Expected: suggestions include relevant (SC-006 for rolls too).

## Scenario 4: P4 - Synergies CRUD + association
1. Create "Meleefire" Melee synergy, describe elements/weapons.
2. Filter by type "Grenade".
3. Associate with a set or items; view as tags/notes.
4. Delete.
5. Expected: surfaced in item/set views.

## Scenario 5: P5 + P6 - Rolls suggestions + variants
1. With set/synergy attached or selected, request roll suggestions (explicit or auto).
2. See 2+ relevant perks/weapons (manifest valid).
3. Duplicate build as variant, swap to different sets (use snapshots).
4. Filter builds by exotic → see variants with differences.
5. Expected: SC-004, SC-006; <5s locate (SC-002).

## Edge / Scale (from spec)
- Large set (50 items): create/attach/filter, no slowdown (SC-007 for 30 sets/20 synergies).
- Delete attached set: blocked, list of builds shown, must detach first (clarif).
- Manifest update: live sets reflect (or warn on deprecated); snapshot stable.
- Fashion Set attach: allowed for display but ignored in suggestions/synergies/composition.

## Success Validation
- All 6 user stories independently testable (per spec Independent Tests).
- 80% first-try success for set-based goal (observe in quickstart).
- Gate passes: `npm run gate`
- No implementation details in validation.

Run these in order after each story checkpoint. Link to data-model.md for entity shapes and contracts/ for UI payloads. See research.md for decisions on live/snapshot and suggestions. 

This proves the feature works end-to-end per the spec without needing full tasks implementation details.