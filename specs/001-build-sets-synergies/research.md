# Research: Build Sets and Synergies

**Updated**: 2026-06-28 (Session clarifications integrated)

## Concept Tags (Controlled Vocabulary)

**Decision**: Sets and Builds carry **zero or more concept tags** from a system-defined vocabulary in `src/data/conceptTags.ts` (facets: activity, element, playstyle, role). Set **name** is user-defined and separate from tags. Tags are **not** free-form user text (FR-004, Session 2026-06-28).

**Storage**: Junction tables `set_tags(set_id, tag_id)` and `build_tags(build_id, tag_id)`. Tag ids validated via zod enum at API boundary (`INVALID_TAG`).

**Filter queries (AND semantics)**: When filtering by `[solar, melee]`, intersect set_ids per tag in junction table, then join parent entity scoped by userId (FR-031). Same for builds. UI shorthand `Solar · Melee` is two tags, not one compound value.

**Rationale**: Enables discovery when attaching sets to builds — user filters library for matching tag combinations without leaving attach flow (FR-032).

**Alternatives considered**:
- Free-form category string: rejected — user requires controlled Destiny concepts.
- Single category per set: rejected — user requires multi-select tags.
- OR-only filter: rejected — AND semantics match "Solar + Melee sets" intent.

## Set Type Model and Slot Cardinality

**Decision**: Keep **separate set types** (Weapon, Armor, Mod, Pair, Fashion). Each type enforces **0–1 item per slot within its domain**:
- Weapon: `primary` | `special` | `heavy`
- Armor: `helmet` | `arms` | `chest` | `legs` | `class_item`
- Pair: `exotic_weapon` | `exotic_armor`
- Mod: optional mod entries (encouraged, not required)
- Fashion: cosmetic references only

**Rationale**: Matches clarification B (2026-06-22). Preserves distinct CRUD and filtering per set type from the overhaul plan while constraining cardinality.

**Alternatives considered**:
- Unified eight-slot container: rejected — user chose separate types.
- Per-slot micro-sets: rejected — too granular for curation workflow.

## Occupied Slot Overwrite Within a Set

**Decision**: Adding to an occupied slot **replaces** the existing item after **user confirmation** (FR-027).

**Rationale**: Clarification A (2026-06-22). Standard inventory UX; avoids duplicate slot rows in DB.

**Alternatives considered**:
- Reject until manual remove: slower UX.
- Multiple candidates per slot: conflicts with 0–1 rule.

## Build vs Variant Model (Hybrid Exotics)

**Decision**:
- New **`builds`** entity: name, subclass/aspects (structured JSON aligned with `generatedBuildSchema.subclass`), **exotic armor** (manifest hash + name), user ownership.
- **`build_variants`**: `is_default`, name, optional **exotic weapon** per variant.
- Shared across variants: subclass, aspects, exotic armor, designated synergies.
- Per variant: attached sets, exotic weapon, resolved equipment projection.

**Rationale**: Clarifications 2026-06-22 (hybrid exotic C, variant save rules, default variant). Enables “same helmet, different exotic weapon + sets” variants (US6).

**Alternatives considered**:
- Flat loadout-per-variant: duplicates subclass/aspects; rejected.
- All exotics build-level: rejected — user wanted weapon flexibility per variant.

## Designated Synergies and Suggestion Weighting

**Decision**: Builds require **≥1 designated synergy** (junction `build_synergies`). When multiple are designated, **all contribute equally** to set/roll suggestions (no primary flag).

**Rationale**: Clarification C (2026-06-22). Suggestion engine merges concept tag matches from each synergy with equal weighting (union of criteria, averaged scoring or round-robin inclusion in LLM context).

**Alternatives considered**:
- Single synergy only: too restrictive.
- Primary + secondary: rejected by user.

## Pair Set Attachment Rules

**Decision**: On attach to a variant, Pair Set `exotic_armor` **must match** build-level exotic armor (hash equality). Mismatch → reject with error. Pair primarily supplies variant `exotic_weapon` (FR-028).

**Rationale**: Clarification A (2026-06-22). Keeps build-level armor authoritative; pairs remain useful for curated weapon+armor combos.

**Alternatives considered**:
- Block all pairs when build armor set: loses pair workflow.
- Pair defines build armor: conflicts with hybrid model.

## Cross-Set Slot Conflict Resolution on Variants

**Decision**: When resolving a variant's attached sets to equipment slots, compute a **slot map** across Weapon, Armor, and Pair contributions. If two sources claim the same logical slot (e.g., Weapon Set `primary` and Pair `exotic_weapon` when exotic is kinetic), **block save** until user detaches or changes a set (FR-026). Exotic weapon from variant or Pair occupies the weapon slot matching manifest bucket.

**Rationale**: Edge case from spec; prevents ambiguous compositions.

**Alternatives considered**:
- Last-wins precedence: opaque to users.
- Auto-merge: not specified.

## Snapshot vs Live Set Attachment

**Decision** (unchanged from 2026-06-17):
- **Live** (default): `variant_set_attachments` stores `set_id` only; resolve current `set_items` at read time.
- **Snapshot**: freeze `snapshot_configs` JSON (item hash + roll data per slot) at attach time.

**Rationale**: Supports stable variants (P6) while allowing live curation (P3).

## Suggestion Engine

**Decision** (refined):
- **Automatic**: rules on concept tags, exotic armor (build), exotic weapon (variant), subclass verbs; merge criteria from **all** designated synergies equally.
- **Explicit**: LLM goal input with manifest tool calls; fallback to rules.
- **Rolls**: extend existing roll-tag/meta logic with synergy union context.

**Rationale**: Clarifications C (2026-06-17 suggestions mode, 2026-06-22 equal synergy weight).

## Persistence Schema Summary

**Decision**: New tables — `sets`, `set_items`, `set_tags`, `synergies`, `build_synergies`, `builds`, `build_tags`, `build_variants`, `variant_set_attachments`. Existing `loadouts` table remains for current save flow; builds are parallel until integration story.

**Rationale**: Normalized model supports deletion guards, variant attachments, and slot queries without overloading loadout JSON blobs.

## Weapon Roll Data in SetItem

**Decision** (unchanged): `set_items` store `item_hash`, `slot`, `selected_perks` JSON, optional `masterwork_hash`. Soft-delete or history row preserves roll when item removed from active set (FR-019).

**Rationale**: User clarification on full roll storage and alternatives.

All NEEDS CLARIFICATION items from Technical Context are resolved. Ready for Phase 1 artifacts.
