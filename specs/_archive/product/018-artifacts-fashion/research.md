# Research: Artifacts & Fashion

**Feature**: 018-artifacts-fashion  
**Date**: 2026-07-10

## R1 — Artifact count: 6 vs 7

**Decision**: Validate selected `artifactHash` against the current manifest **`artifacts` entity store** (fail closed if unknown). Do **not** hardcode `=== 6`. Treat DBR-ART-001 “six fixed” as “fixed permanent Artifacts 2.0 catalog”; live store / `ARTIFACT_GUIDANCE` currently lists **seven**.

**Rationale**: Manifest is source of truth (constitution V). Hardcoding 6 would reject valid Artifacts 2.0 entries.

**Alternatives rejected**: Hardcode 6 (breaks current catalog); hardcode 7 (same fragility).

## R2 — Artifact storage shape

**Decision**: Add to `build_variants`:
- `artifact_hash` INTEGER NULL  
- `artifact_name` TEXT NULL (denormalized display)  
- `artifact_config` TEXT NOT NULL DEFAULT `'[]'` — JSON array of selected unlock/perk hashes  

Switching artifact replaces config (clear to `[]` or require new config in same write).

**Rationale**: Exactly one artifact per variant; matches existing JSON column patterns (`selected_perks`, `snapshotConfigs`).

**Alternatives rejected**: Separate `variant_artifacts` table (overkill for 1:1).

## R3 — Fashion cosmetic slots

**Decision**: Introduce `FASHION_SLOTS` allowlist:
`shader_ornament`, `ghost`, `sparrow`, `ship`, `emblem`, `finisher`

Update `SLOTS_BY_SET_TYPE.fashion` to that list; fix `isSlotValidForSetType` so fashion slots validate true. Reject emotes/consumables by item-type / slot deny-list.

**Rationale**: Today `fashion: "cosmetic"` makes **all** fashion upserts fail — blocking DBR-FASH-002/003.

## R4 — One fashion attachment per variant

**Decision**: Enforce **at most one** active fashion set attachment in `prepareAttachments` (clear API error on duplicates).

**Rationale**: Spec edge case; keeps resolved fashion layer unambiguous for later equip.

## R5 — Resolved payload

**Decision**: Extend `getResolvedVariant` with:
```ts
artifact: { hash: number; name: string; config: number[] } | null
fashion: { setId: string; slots: Partial<Record<FashionSlot, { itemHash: number; itemName: string }>> } | null
```
Combat `equipment` unchanged; fashion still contributes **zero** combat claims.

**Rationale**: FR-007 / US3; bungie-equip/dim-export consume later without schema churn.

## R6 — Completeness / identity

**Decision**: Missing fashion never hard-blocks save. Missing artifact does **not** newly hard-block non-default saves in this slice. Artifact/fashion-only edits do **not** require `identityAction`.

**Rationale**: Spec US4; identity remains synergies/exotics/Super from 015.

## R7 — Debug surfaces

**Decision**:
- **Sets debug**: fashion slot picker + catalog/hash entry for cosmetic items  
- **Builds debug**: artifact select (from manifest list) + config; Resolve shows new fields  

No production UI.
