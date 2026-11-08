# Research: Build Identity & Default Completeness

**Feature**: 015-build-identity  
**Date**: 2026-07-10  
**Spec**: [spec.md](./spec.md)

Phase 0 decisions for implementation planning. All Technical Context unknowns resolved.

---

## 1. Optional exotic armor (DB + API)

**Decision**: Make `builds.exotic_armor_hash` and `exotic_armor_name` nullable. Zod create/update accept `null`/omit. Existing rows keep values. Pair-armor and exotic-claim helpers skip when hash is null.

**Rationale**: FR-005 / DBR-ID-004 require optional exotic armor. Current `.notNull()` + Zod `.positive()` force a hash. Null is the clearest “no identity exotic armor” signal.

**Alternatives considered**: Sentinel `0` (pollutes filters); separate boolean flag (redundant with null).

---

## 2. Build-shared vs variant-level exotic weapon

**Decision**: Add nullable `builds.exotic_weapon_hash` + `exotic_weapon_name`. Keep variant columns. When build columns are set → build-shared identity (resolve prefers build hash). When null → use variant-level weapon.

**Rationale**: DBR-ID-006 / FR-006 need both modes. Null-on-build = not shared mirrors optional exotic armor without an extra enum.

**Alternatives considered**: Move weapon only to build (breaks per-variant kits); boolean `shared` flag plus dual storage (two sources of truth); clear variant columns when sharing (destructive).

---

## 3. Build-pinned Super

**Decision**: Add nullable `builds.pinned_super` (string, same vocabulary as `subclass.super`). Kit remains in `builds.subclass` JSON. When `pinned_super` is set it is identity; when null, Super is not an identity field and default naming uses default variant / subclass Super per FR-012.

**Rationale**: Today Super only lives in build-level subclass blob (already shared). A pin column makes pinned vs unpinned explicit for confirm/fork without moving the whole kit to variants in this slice.

**Alternatives considered**: Treat `subclass.super` as always-pinned (no unpinned mode); move entire kit to variants (correct long-term, too large for this slice).

---

## 4. Full combat loadout vs ≥1-slot empty check

**Decision**: Replace `assertVariantNotEmpty` for **default** variants with `assertFullCombatLoadout`. Non-default variants may save with empty combat slots (no ≥1-slot requirement).

**Full combat loadout (composition)** after `resolveVariantEquipment`:

| Group | Required slots |
|-------|----------------|
| Weapons | `primary`, `special`, `heavy` |
| Armor | `helmet`, `arms`, `chest`, `legs`, `class_item` |
| Build | `className`; non-empty `subclass` kit |
| Mods | At least one Mod Set attached **or** armor/weapon items carrying `modHashes` (explicit check — mods are not keys on the equipment map today) |

Error shape: structured gaps list (e.g. `DEFAULT_VARIANT_INCOMPLETE` with `{ missingSlots: string[] }`).

**Rationale**: DBR-CMPL-001 / FR-010 supersede BR-SAVE-001. Current check only tests `Object.keys(equipment).length === 0`.

**Alternatives considered**: Keep ≥1-slot for non-defaults (stricter than domain); require full loadout on every variant (violates FR-011).

---

## 5. Confirm / fork API shape

**Decision**: Extend `PATCH /api/user/builds/:id` with `identityAction: "confirm" | "fork"` required when identity fields change. Omit for non-identity updates (tags, name-only, subclass non-pin fields). First attempt without action → `IDENTITY_CONFIRM_REQUIRED` with `{ identityFields: string[] }` (same two-step pattern as set `confirmReplace` / `SLOT_OCCUPIED`).

**Rationale**: Matches existing confirm UX; one route; debug resubmits same payload + flag.

**Alternatives considered**: Separate `POST .../fork` (clearer URLs, more surface); silent overwrite (violates FR-008).

---

## 6. Fork copy depth

**Decision**: Fork creates a new Build with new identity fields from the edit; copies **all variants** (preserve which is default); copies tags + subclass; clones attachments as **snapshots** via existing `cloneAttachmentsAsSnapshots`. Original build unchanged.

**Rationale**: Spec requires enough structure to continue editing; snapshot avoids live set drift across original and fork; reuses `variantService` duplicate path.

**Alternatives considered**: Default-only fork (loses multi-variant kits); preserve live attachment modes (shared set edits affect both).

---

## 7. Default naming + uniqueness

**Decision**: Pure helper `src/lib/builds/defaultBuildName.ts` called from `buildService` on create when name omitted/blank. Segments: Class, Element, Super (pinned or subclass/default), Exotic Armor, Exotic Weapon (build-shared or default variant), Synergies — omit missing. Enforce uniqueness per `(userId, className, name)` in `buildService` on create/rename; optional unique index later.

**Rationale**: DBR-NAME-001–004; service-owned domain rules stay testable without HTTP.

**Alternatives considered**: Client-only naming (bypassable); DB-only unique without service errors (weaker messages).

---

## 8. Debug UI scope

**Decision**: Minimal updates to `BuildsDebugPage.tsx`: optional exotic armor; build-shared weapon + pinned Super fields; identity PATCH confirm/fork buttons; optional blank name → server default; rename uniqueness errors. No production UI.

**Rationale**: Spec is debug-first (001 pattern); SC-002/SC-004 need a verification surface.

---

## 9. Tech stack (no unknowns)

| Area | Choice |
|------|--------|
| Language | TypeScript 5+, Next.js App Router |
| Storage | SQLite via better-sqlite3 + Drizzle (`src/lib/db`) |
| Validation | zod at route + service boundaries |
| Testing | vitest co-located `*.test.ts`; gate = `npm run gate` |
| Delivery | Debug Builds page + API contracts |

No remaining NEEDS CLARIFICATION.
