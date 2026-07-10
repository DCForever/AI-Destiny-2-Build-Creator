# Quickstart: Build Identity & Default Completeness

**Feature**: 015-build-identity  
**Branch**: `015-build-identity`  
**Updated**: 2026-07-10

## Prerequisites

- On branch `015-build-identity`
- Signed-in session for debug APIs
- Dev server: `npm run dev`
- Related: [data-model.md](./data-model.md), [contracts/](./contracts/)

## Setup

```bash
npx vitest run src/lib/builds src/app/api/user/builds
npm run gate
```

## Validation scenarios

### V1 — Identity on save (US1)

1. Open `/debug/builds` (or equivalent Builds debug page).
2. Create a build with ≥1 synergy, **no** exotic armor, optional build-shared exotic weapon and/or pinned Super.
3. **Expect**: save succeeds; detail shows nullable armor, shared weapon / pinned Super when set.
4. Create with zero synergies → **Expect**: `NO_SYNERGY`.
5. Change only tags → **Expect**: no confirm/fork required.

Automated: `buildService` / create route tests for optional armor, shared weapon, `NO_SYNERGY`, tags-not-identity.

### V2 — Default full loadout (US2)

1. Build with valid identity; attach incomplete sets to default (e.g. missing special).
2. Save/update default → **Expect**: `DEFAULT_VARIANT_INCOMPLETE` listing gaps.
3. Fill primary/special/heavy + five armor slots + subclass + mods presence → **Expect**: save OK.
4. Add non-default variant with empty slots → **Expect**: save OK.

Automated: `assertFullCombatLoadout` / `validateVariantSave` tests.

### V3 — Confirm / fork (US3)

1. Build with two variants; PATCH synergies without `identityAction` → **Expect**: `IDENTITY_CONFIRM_REQUIRED`.
2. Resubmit with `identityAction: "confirm"` → same build id, new synergies.
3. Repeat from a copy of prior state with `identityAction: "fork"` → new build id; original unchanged; fork has snapshot attachments.
4. PATCH tags only → no confirm.

Automated: PATCH route + fork service tests. Debug UI: Confirm / Fork buttons.

### V4 — Naming (US4)

1. Create with blank name → derived name includes present segments only (no `None`).
2. Rename two Warlock builds to the same name → `DUPLICATE_BUILD_NAME`.
3. Same name on Titan and Warlock → both OK.

Automated: `defaultBuildName` unit tests + uniqueness service tests.

## Gate checkpoint

Before each story commit:

```bash
npm run gate
```

## Quickstart walk (T036) — 2026-07-10

Debug UI at `/debug/builds` covers V1–V4:

| Scenario | Debug control |
|----------|----------------|
| V1 optional armor / shared weapon / pinned Super | Create form: Clear exotic armor, ExoticWeaponLookup, Pinned Super |
| V2 incomplete default | Attach incomplete set → amber “Default incomplete: missing …” |
| V3 confirm/fork | Save designations → Confirm in-place / Fork as new build |
| V4 blank name / uniqueness | Blank name on create; duplicate name surfaces via JSON panel (`DUPLICATE_BUILD_NAME`) |

Automated coverage: `npx vitest run src/lib/builds` (31 tests) + `npm run gate`.
